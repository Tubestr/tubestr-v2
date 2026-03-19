import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/domain/models/remote_share_identity.dart';
import 'package:mytube/services/identity/identity_service.dart';
import 'package:mytube/services/mdk/mdk_service.dart';
import 'package:mytube/services/sync/sync_coordinator.dart';
import 'package:ndk/entities.dart';

import '../../test_support/service_fakes.dart';

class _FakeIdentityService extends IdentityService {
  _FakeIdentityService({required this.identity, required super.database})
    : super(secureStorage: const FlutterSecureStorage());

  final ParentIdentity? identity;

  @override
  Future<ParentIdentity?> loadIdentity() async => identity;
}

class _DelayedNostrService extends FakeNostrService {
  final Completer<void> connectCompleter = Completer<void>();

  @override
  Future<void> connect() => connectCompleter.future;
}

class _DelayedSubscribeNostrService extends FakeNostrService {
  final Completer<void> subscribeCompleter = Completer<void>();

  @override
  Future<NdkResponse> subscribe({
    required String subscriptionId,
    required Filter filter,
    List<String>? relays,
  }) async {
    subscriptionFilters[subscriptionId] = filter;
    final controller = StreamController<Nip01Event>.broadcast();
    subscriptionControllers[subscriptionId] = controller;
    await subscribeCompleter.future;
    return NdkResponse(subscriptionId, controller.stream);
  }
}

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-15T00:00:00Z',
  );
  final recentEventCreatedAt =
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  test(
    'buildFiltersForTesting scopes MLS traffic to tracked group h-tags',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: MdkService(),
      );

      final filters = coordinator.buildFiltersForTesting(
        parentPublicKeyHex: 'parent-pubkey',
        trackedGroupNostrIds: const {'group-a', 'group-b'},
      );

      expect(filters, hasLength(2));
      expect(filters.first.kinds, [MarmotKinds.giftWrap]);
      expect(filters.first.pTags, ['parent-pubkey']);
      expect(filters.last.kinds, [MarmotKinds.groupCommit]);
      expect(filters.last.tags?['#h'], containsAll(['group-a', 'group-b']));
    },
  );

  test(
    'projectProcessedMessage stores remote asset and share record for video share messages',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: MdkService(),
      );

      final result = await coordinator.projectProcessedMessage(
        const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'abcd1234',
          messageEventIdHex: 'rumor-event-1',
          wrapperEventIdHex: 'wrapper-event-1',
          pubkeyHex: 'sender-pubkey',
          kind: 4543,
          content:
              '{"t":"mytube/video_share","video_id":"video-1","child_profile_id":"child-1","child_display_name":"Emma","meta":{"title":"Backyard song","dur":12.5,"created_at":1710460800},"blob":{"hash":"blob-1","servers":["https://blossom.example"],"mime":"video/mp4","len":321,"orig_hash":"orig-1","nonce":"nonce-1","filename":"clip.mp4","scheme":"mip04-v2"},"thumb":{"hash":"thumb-1","servers":["https://blossom.example"],"mime":"image/jpeg","len":111,"orig_hash":"orig-thumb","nonce":"nonce-thumb","filename":"clip.jpg","scheme":"mip04-v2"},"media":{"alg":"mip04","epoch":"epoch-1"},"policy":{"version":2,"expires_at":null},"by":"sender-pubkey","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        ),
      );

      final remoteShareId = buildRemoteShareId(
        senderParentKey: 'sender-pubkey',
        mlsGroupId: 'abcd1234',
        videoId: 'video-1',
      );
      final asset = await database.getRemoteAssetByRemoteShareId(remoteShareId);
      final shares = await database.watchShareRecords().first;

      expect(result.projected, isTrue);
      expect(result.reason, 'projected:video_share');
      expect(asset, isNotNull);
      expect(asset!.blobHash, 'blob-1');
      expect(asset.epoch, 'epoch-1');
      expect(shares, hasLength(1));
      expect(shares.single.videoId, 'video-1');
      expect(shares.single.mlsGroupId, 'abcd1234');
      expect(shares.single.childDisplayName, 'Emma');
      expect(
        shares.single.receivedAt,
        DateTime.fromMillisecondsSinceEpoch(1710460800 * 1000),
      );
    },
  );

  test(
    'projectProcessedMessage stores likes for remote engagement updates',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: MdkService(),
      );

      final result = await coordinator.projectProcessedMessage(
        const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'abcd1234',
          messageEventIdHex: 'rumor-event-2',
          wrapperEventIdHex: 'wrapper-event-2',
          pubkeyHex: 'sender-pubkey',
          kind: 4546,
          content:
              '{"t":"mytube/like","video_id":"video-1","child_profile_id":"child-1","by":"sender-pubkey","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        ),
      );

      final likeCount = await database.watchLikeCountForVideo('video-1').first;
      final hasLike = await database
          .watchLikeForVideoByParentAndChild(
            videoId: 'video-1',
            childProfileId: 'child-1',
            parentPubkey: 'sender-pubkey',
          )
          .first;

      expect(result.projected, isTrue);
      expect(result.reason, 'projected:like');
      expect(likeCount, 1);
      expect(hasLike, isTrue);
    },
  );

  test(
    'projectProcessedMessage stores reactions for remote engagement updates',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: MdkService(),
      );

      final result = await coordinator.projectProcessedMessage(
        const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'abcd1234',
          messageEventIdHex: 'rumor-event-2b',
          wrapperEventIdHex: 'wrapper-event-2b',
          pubkeyHex: 'sender-pubkey',
          kind: 4548,
          content:
              '{"t":"mytube/reaction","video_id":"video-1","child_profile_id":"child-1","emoji":"🎉","by":"sender-pubkey","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        ),
      );

      final reactions = await database.watchReactionsForVideo('video-1').first;

      expect(result.projected, isTrue);
      expect(result.reason, 'projected:reaction');
      expect(reactions, hasLength(1));
      expect(reactions.single.emoji, '🎉');
    },
  );

  test(
    'projectProcessedMessage stores inbound reports for parent review',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: MdkService(),
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );

      final result = await coordinator.projectProcessedMessage(
        const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'abcd1234',
          messageEventIdHex: 'rumor-event-3',
          wrapperEventIdHex: 'wrapper-event-3',
          pubkeyHex: 'remote-parent',
          kind: 4547,
          content:
              '{"t":"mytube/report","report_id":"report-1","video_id":"video-1","subject_child_id":"child-1","blob_hash":"blob-1","reason":"inappropriate","note":"Needs a check-in","level":2,"recipient_type":"parents","reporter_child_id":"child-2","by":"remote-parent","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        ),
      );

      final reports = await database.watchReports().first;

      expect(result.projected, isTrue);
      expect(result.reason, 'projected:report');
      expect(reports, hasLength(1));
      expect(reports.single.id, 'report-1');
      expect(reports.single.isOutbound, isFalse);
      expect(reports.single.status, 'received');
      expect(reports.single.reason, 'inappropriate');
    },
  );

  test(
    'projectProcessedMessage purges cached media when a video is deleted',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.upsertRemoteShareProjection(
        videoId: 'video-1',
        mlsGroupId: 'abcd1234',
        senderParentKey: 'sender-pubkey',
        childProfileId: 'child-1',
        childDisplayName: 'Emma',
        blobHash: 'blob-1',
        thumbHash: 'thumb-1',
        epoch: 'epoch-1',
        mime: 'video/mp4',
        metadataJson: '{}',
        localMediaPath: '/tmp/video.mp4',
        localThumbPath: '/tmp/video.jpg',
        status: 'downloaded',
      );

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: MdkService(),
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );

      final result = await coordinator.projectProcessedMessage(
        const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'abcd1234',
          messageEventIdHex: 'rumor-event-4',
          wrapperEventIdHex: 'wrapper-event-4',
          pubkeyHex: 'sender-pubkey',
          kind: 4545,
          content:
              '{"t":"mytube/video_delete","video_id":"video-1","blob_hash":"blob-1","reason":"removed","by":"sender-pubkey","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        ),
      );

      final projection = await database.getRemoteShareProjectionByRemoteShareId(
        buildRemoteShareId(
          senderParentKey: 'sender-pubkey',
          mlsGroupId: 'abcd1234',
          videoId: 'video-1',
        ),
      );

      expect(result.projected, isTrue);
      expect(result.reason, 'projected:video_delete');
      expect(projection, isNotNull);
      expect(projection!.status, 'deleted');
      expect(projection.localMediaPath, isNull);
      expect(projection.localThumbPath, isNull);
    },
  );

  test(
    'refreshSubscriptions picks up newly joined groups for relay sync',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final mdk = FakeMdkService()..groupSummariesResult = const [];
      final nostr = FakeNostrService();
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: mdk,
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(coordinator.stop);

      await coordinator.start();

      final initialCommitFilters = nostr.subscriptionFilters.values
          .where(
            (filter) =>
                filter.kinds?.contains(MarmotKinds.groupCommit) ?? false,
          )
          .toList(growable: false);
      expect(initialCommitFilters, isEmpty);

      mdk.groupSummariesResult = const [
        MdkGroupSummary(
          mlsGroupIdHex: 'mls-group-1',
          nostrGroupIdHex: 'nostr-group-1',
          name: 'Family Space',
          description: 'Joined locally',
          memberCount: 2,
          adminPubkeysHex: ['parent-pubkey'],
        ),
      ];

      await coordinator.refreshSubscriptions();

      final diagnostics = coordinator.debugSnapshot();

      final refreshedCommitFilters = nostr.subscriptionFilters.values
          .where(
            (filter) =>
                filter.kinds?.contains(MarmotKinds.groupCommit) ?? false,
          )
          .toList(growable: false);
      expect(refreshedCommitFilters, hasLength(1));
      expect(refreshedCommitFilters.single.tags?['#h'], ['nostr-group-1']);
      expect(nostr.unsubscribedSubscriptionIds, isNotEmpty);
      expect(diagnostics.refreshGeneration, 2);
      expect(diagnostics.lastRefreshTrigger, SyncRefreshTrigger.manual.value);
      expect(diagnostics.activeSubscriptions, hasLength(2));
      expect(
        diagnostics.recentHistory.any(
          (entry) =>
              entry.category == 'subscription' &&
              entry.detail.contains('subscribed'),
        ),
        isTrue,
      );
    },
  );

  test(
    'refreshSubscriptions coalesces while a prior refresh is in flight',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final nostr = _DelayedNostrService();
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: FakeMdkService(),
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(() async {
        if (!nostr.connectCompleter.isCompleted) {
          nostr.connectCompleter.complete();
        }
        await coordinator.stop();
      });

      final startFuture = coordinator.start();
      await pumpEventQueue(times: 5);

      final refreshFuture = coordinator.refreshSubscriptions(
        trigger: SyncRefreshTrigger.groupChange,
      );
      await pumpEventQueue(times: 2);

      final midFlight = coordinator.debugSnapshot();
      expect(midFlight.refreshInFlight, isTrue);
      expect(midFlight.refreshGeneration, 1);
      expect(midFlight.coalescedRefreshRequestCount, 1);
      expect(
        midFlight.recentHistory.any(
          (entry) =>
              entry.category == 'refresh' &&
              entry.trigger == SyncRefreshTrigger.groupChange.value &&
              entry.detail.contains('coalesced'),
        ),
        isTrue,
      );

      nostr.connectCompleter.complete();
      await Future.wait<void>([startFuture, refreshFuture]);

      final completed = coordinator.debugSnapshot();
      expect(completed.refreshRequestCount, 2);
      expect(completed.coalescedRefreshRequestCount, 1);
      expect(completed.lastRefreshTrigger, SyncRefreshTrigger.startup.value);
    },
  );

  test(
    'stop clears active subscriptions and records lifecycle history',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final coordinator = SyncCoordinator(
        database: database,
        mdkService: FakeMdkService(),
        nostrService: FakeNostrService(),
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );

      await coordinator.start();
      expect(coordinator.debugSnapshot().activeSubscriptions, isNotEmpty);

      await coordinator.stop();

      final diagnostics = coordinator.debugSnapshot();
      expect(diagnostics.started, isFalse);
      expect(diagnostics.activeSubscriptions, isEmpty);
      expect(diagnostics.recentHistory.last.detail, contains('stopped'));
    },
  );

  test(
    'stop cleans up subscribe responses that arrive after shutdown',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final nostr = _DelayedSubscribeNostrService();
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: FakeMdkService(),
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(() async {
        if (!nostr.subscribeCompleter.isCompleted) {
          nostr.subscribeCompleter.complete();
        }
        await coordinator.stop();
      });

      final startFuture = coordinator.start();
      await pumpEventQueue(times: 5);

      await coordinator.stop();
      nostr.subscribeCompleter.complete();
      await startFuture;

      final diagnostics = coordinator.debugSnapshot();
      expect(diagnostics.started, isFalse);
      expect(diagnostics.activeSubscriptions, isEmpty);
      expect(nostr.unsubscribedSubscriptionIds, contains('mytube.family.sync.0'));
      expect(
        diagnostics.recentHistory.any(
          (entry) =>
              entry.category == 'subscription' &&
              entry.detail.contains('cleaned up late subscribe response'),
        ),
        isTrue,
      );
    },
  );

  test(
    'refreshSubscriptions records unsubscribe failures and keeps going',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final nostr = FakeNostrService();
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: FakeMdkService(),
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(coordinator.stop);

      await coordinator.start();
      nostr.unsubscribeFailures.add('mytube.family.sync.0');

      await coordinator.refreshSubscriptions();

      final diagnostics = coordinator.debugSnapshot();
      expect(diagnostics.unsubscribeFailureCount, 1);
      expect(
        diagnostics.recentHistory.any(
          (entry) => entry.detail.contains('unsubscribe failed'),
        ),
        isTrue,
      );
      expect(diagnostics.activeSubscriptions, isNotEmpty);
    },
  );

  test(
    'subscription stream errors are counted and redacted in debug dump',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final nostr = FakeNostrService();
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: FakeMdkService(),
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(coordinator.stop);
      final originalDebugPrint = debugPrint;
      final loggedMessages = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          loggedMessages.add(message);
        }
      };
      addTearDown(() {
        debugPrint = originalDebugPrint;
      });

      await coordinator.start();

      nostr.subscriptionControllers['mytube.family.sync.0']!.addError(
        StateError(
          '{"content":"signed-payload","sig":"deadbeef","nsec":"nsec1secret"}',
        ),
      );
      await pumpEventQueue(times: 2);

      final diagnostics = coordinator.debugSnapshot();
      final dump = coordinator.debugDescribeState();

      expect(diagnostics.subscriptionErrorCount, 1);
      expect(dump, contains('[redacted]'));
      expect(dump, isNot(contains('signed-payload')));
      expect(dump, isNot(contains('nsec1secret')));
      expect(loggedMessages.join('\n'), contains('[redacted]'));
      expect(loggedMessages.join('\n'), isNot(contains('signed-payload')));
      expect(loggedMessages.join('\n'), isNot(contains('nsec1secret')));
    },
  );

  test(
    'initial subscription replay respects h-tag filters and lookback window',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final mdk = FakeMdkService()
        ..groupSummariesResult = const [
          MdkGroupSummary(
            mlsGroupIdHex: 'mls-group-1',
            nostrGroupIdHex: 'nostr-group-1',
            name: 'Family Space',
            description: 'Joined locally',
            memberCount: 2,
            adminPubkeysHex: ['parent-pubkey'],
          ),
        ]
        ..processedMessage = const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'mls-group-1',
          messageEventIdHex: 'rumor-event-1',
          wrapperEventIdHex: 'wrapper-event-1',
          pubkeyHex: 'sender-pubkey',
          kind: 4543,
          content:
              '{"t":"mytube/video_share","video_id":"video-relay","child_profile_id":"child-1","child_display_name":"Emma","meta":{"title":"Relay Song","dur":12.5,"created_at":1710460800},"blob":{"hash":"blob-1","servers":["https://blossom.example"],"mime":"video/mp4","len":321,"orig_hash":"orig-1","nonce":"nonce-1","filename":"clip.mp4","scheme":"mip04-v2"},"thumb":{"hash":"thumb-1","servers":["https://blossom.example"],"mime":"image/jpeg","len":111,"orig_hash":"orig-thumb","nonce":"nonce-thumb","filename":"clip.jpg","scheme":"mip04-v2"},"media":{"alg":"mip04","epoch":"epoch-1"},"policy":{"version":2,"expires_at":null},"by":"sender-pubkey","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        );
      final nostr = FakeNostrService()
        ..queryEventsResult = [
          Nip01Event(
            id: 'wrong-group',
            pubKey: 'sender-pubkey',
            createdAt: recentEventCreatedAt,
            kind: MarmotKinds.groupCommit,
            tags: const [
              ['h', 'nostr-group-2'],
            ],
            content: '{"kind":445}',
            sig: 'sig-1',
          ),
          Nip01Event(
            id: 'too-old',
            pubKey: 'sender-pubkey',
            createdAt: recentEventCreatedAt - const Duration(days: 30).inSeconds,
            kind: MarmotKinds.groupCommit,
            tags: const [
              ['h', 'nostr-group-1'],
            ],
            content: '{"kind":445}',
            sig: 'sig-2',
          ),
        ];
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: mdk,
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(coordinator.stop);

      await coordinator.start();
      await pumpEventQueue(times: 2);

      final diagnostics = coordinator.debugSnapshot();
      expect(diagnostics.eventCount, 0);
      expect(diagnostics.projectedEventCount, 0);
      expect(
        await database.getRemoteShareProjectionByRemoteShareId(
          buildRemoteShareId(
            senderParentKey: 'sender-pubkey',
            mlsGroupId: 'mls-group-1',
            videoId: 'video-relay',
          ),
        ),
        isNull,
      );
    },
  );

  test(
    'start processes relay-delivered group events into Drift projections',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      final mdk = FakeMdkService()
        ..groupSummariesResult = const [
          MdkGroupSummary(
            mlsGroupIdHex: 'mls-group-1',
            nostrGroupIdHex: 'nostr-group-1',
            name: 'Family Space',
            description: 'Joined locally',
            memberCount: 2,
            adminPubkeysHex: ['parent-pubkey'],
          ),
        ]
        ..processedMessage = const MdkProcessedMessage(
          outcome: MdkMessageOutcome.applicationMessage,
          mlsGroupIdHex: 'mls-group-1',
          messageEventIdHex: 'rumor-event-1',
          wrapperEventIdHex: 'wrapper-event-1',
          pubkeyHex: 'sender-pubkey',
          kind: 4543,
          content:
              '{"t":"mytube/video_share","video_id":"video-relay","child_profile_id":"child-1","child_display_name":"Emma","meta":{"title":"Relay Song","dur":12.5,"created_at":1710460800},"blob":{"hash":"blob-1","servers":["https://blossom.example"],"mime":"video/mp4","len":321,"orig_hash":"orig-1","nonce":"nonce-1","filename":"clip.mp4","scheme":"mip04-v2"},"thumb":{"hash":"thumb-1","servers":["https://blossom.example"],"mime":"image/jpeg","len":111,"orig_hash":"orig-thumb","nonce":"nonce-thumb","filename":"clip.jpg","scheme":"mip04-v2"},"media":{"alg":"mip04","epoch":"epoch-1"},"policy":{"version":2,"expires_at":null},"by":"sender-pubkey","ts":1710460800}',
          createdAt: 1710460800,
          state: 'processed',
        );
      final nostr = FakeNostrService();
      final coordinator = SyncCoordinator(
        database: database,
        mdkService: mdk,
        nostrService: nostr,
        identityService: _FakeIdentityService(
          identity: identity,
          database: database,
        ),
      );
      addTearDown(coordinator.stop);

      await coordinator.start();

      final groupSubscriptionEntry = nostr.subscriptionFilters.entries
          .singleWhere(
            (entry) =>
                entry.value.kinds?.contains(MarmotKinds.groupCommit) ?? false,
          );
      final revisionFuture = coordinator.revisions.first;
      nostr.subscriptionControllers[groupSubscriptionEntry.key]!.add(
        Nip01Event(
          id: 'event-1',
          pubKey: 'sender-pubkey',
          createdAt: recentEventCreatedAt,
          kind: MarmotKinds.groupCommit,
          tags: const [
            ['h', 'nostr-group-1'],
          ],
          content: '{"kind":445}',
          sig: 'sig-1',
        ),
      );

      await revisionFuture;

      final projection = await database.getRemoteShareProjectionByRemoteShareId(
        buildRemoteShareId(
          senderParentKey: 'sender-pubkey',
          mlsGroupId: 'mls-group-1',
          videoId: 'video-relay',
        ),
      );
      expect(projection, isNotNull);
      expect(projection!.status, 'available');
      expect(projection.shareMessage?.meta.title, 'Relay Song');
    },
  );
}

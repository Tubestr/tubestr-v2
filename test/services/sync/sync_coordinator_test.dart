import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/parent_identity.dart';
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

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-15T00:00:00Z',
  );

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

      final asset = await database.getRemoteAssetByVideoId('video-1');
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
    },
  );

  test('projectProcessedMessage stores likes for remote engagement updates', () async {
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
  });

  test('projectProcessedMessage stores inbound reports for parent review', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final coordinator = SyncCoordinator(
      database: database,
      mdkService: MdkService(),
      identityService: _FakeIdentityService(identity: identity, database: database),
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
  });

  test('projectProcessedMessage purges cached media when a video is deleted', () async {
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
      identityService: _FakeIdentityService(identity: identity, database: database),
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

    final projection = await database.getRemoteShareProjectionByVideoId('video-1');

    expect(result.projected, isTrue);
    expect(result.reason, 'projected:video_delete');
    expect(projection, isNotNull);
    expect(projection!.status, 'deleted');
    expect(projection.localMediaPath, isNull);
    expect(projection.localThumbPath, isNull);
  });

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

      final refreshedCommitFilters = nostr.subscriptionFilters.values
          .where(
            (filter) =>
                filter.kinds?.contains(MarmotKinds.groupCommit) ?? false,
          )
          .toList(growable: false);
      expect(refreshedCommitFilters, hasLength(1));
      expect(refreshedCommitFilters.single.tags?['#h'], ['nostr-group-1']);
      expect(nostr.unsubscribedSubscriptionIds, isNotEmpty);
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
          createdAt: 1710460800,
          kind: MarmotKinds.groupCommit,
          tags: const [
            ['h', 'nostr-group-1'],
          ],
          content: '{"kind":445}',
          sig: 'sig-1',
        ),
      );

      await revisionFuture;

      final projection = await database
          .watchRemoteShareProjectionByVideoId('video-relay')
          .first;
      expect(projection, isNotNull);
      expect(projection!.status, 'available');
      expect(projection.shareMessage?.meta.title, 'Relay Song');
    },
  );
}

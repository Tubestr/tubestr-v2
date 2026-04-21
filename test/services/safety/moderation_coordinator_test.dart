import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/marmot/message_models.dart';
import 'package:mytube/domain/models/mute_list.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/domain/models/remote_share_identity.dart';
import 'package:mytube/services/connections/family_connection_service.dart';
import 'package:mytube/services/identity/user_list_sync_service.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:mytube/services/safety/moderation_coordinator.dart';
import 'package:mytube/services/share/video_lifecycle_coordinator.dart';

import '../../test_support/service_fakes.dart';

class _FakeFamilyConnectionService extends FamilyConnectionService {
  _FakeFamilyConnectionService()
    : super(mdkService: FakeMdkService(), nostrService: FakeNostrService());

  final List<String> clearedPubkeys = [];

  @override
  Future<void> clearPendingConnectionsFor(
    Iterable<String> memberPubkeysHex,
  ) async {
    clearedPubkeys.addAll(memberPubkeysHex);
  }
}

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub1parent',
    nsec: 'nsec1parent',
    createdAtIso: '2026-03-16T00:00:00Z',
  );

  late AppDatabase database;
  late FakeBlossomClient blossom;
  late FakeMdkService mdk;
  late FakeNostrService nostr;
  late ModerationCoordinator coordinator;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    blossom = FakeBlossomClient();
    mdk = FakeMdkService();
    nostr = FakeNostrService();
    coordinator = ModerationCoordinator(
      database: database,
      blossomClient: blossom,
      mdkService: mdk,
      nostrService: nostr,
      videoLifecycleCoordinator: VideoLifecycleCoordinator(
        mdkService: mdk,
        nostrService: nostr,
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'removeMember publishes commit and records moderation audit log',
    () async {
      await coordinator.removeMember(
        identity: identity,
        mlsGroupIdHex: 'group-123',
        memberPubkeyHex: 'other-parent',
        reason: 'Moderator action',
      );

      expect(mdk.lastRemovedMemberPubkeys, ['other-parent']);
      expect(nostr.lastPublishedEventJson, '{"id":"commit"}');

      final logs = await (database.select(
        database.moderationAuditLogs,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      expect(logs, hasLength(1));
      expect(logs.single.actionType, 'remove_member');
      expect(logs.single.subjectParentKey, 'other-parent');
    },
  );

  test(
    'deleteSharedVideo publishes lifecycle, purges cache, and records audit log',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('moderation-test');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final mediaFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync([1, 2, 3]);
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync([4, 5, 6]);

      final shareMessage = VideoShareMessage(
        videoId: 'video-1',
        childProfileId: 'child-1',
        childDisplayName: 'Sam',
        meta: const VideoMeta(
          title: 'Shared clip',
          durationSeconds: 12,
          createdAt: 1710460800,
        ),
        blob: const BlobDescriptor(
          hash: 'blob-123',
          servers: ['https://snapshot.example'],
          mime: 'video/mp4',
          length: 3,
        ),
        thumb: const BlobDescriptor(
          hash: 'thumb-123',
          servers: ['https://snapshot.example'],
          mime: 'image/jpeg',
          length: 3,
        ),
        media: const MediaDescriptor(algorithm: 'mip04', epoch: 'epoch-1'),
        policy: const PolicyDescriptor(version: 2),
        by: 'other-parent',
        ts: 1710460800,
      );

      final remoteShareId = await database.upsertRemoteShareProjection(
        videoId: 'video-1',
        mlsGroupId: 'group-123',
        senderParentKey: 'other-parent',
        childProfileId: 'child-1',
        childDisplayName: 'Sam',
        blobHash: 'blob-123',
        thumbHash: 'thumb-123',
        epoch: 'epoch-1',
        mime: 'video/mp4',
        metadataJson: shareMessage.encode(),
        localMediaPath: mediaFile.path,
        localThumbPath: thumbFile.path,
      );

      final projection = await database.getRemoteShareProjectionByRemoteShareId(
        remoteShareId,
      );
      expect(projection, isNotNull);

      await coordinator.deleteSharedVideo(
        identity: identity,
        projection: projection!,
        reason: 'Moderator action',
      );

      final updated = await database.getRemoteShareProjectionByRemoteShareId(
        buildRemoteShareId(
          senderParentKey: 'other-parent',
          mlsGroupId: 'group-123',
          videoId: 'video-1',
        ),
      );
      expect(updated?.status, 'deleted');
      expect(updated?.localMediaPath, isNull);
      expect(updated?.localThumbPath, isNull);
      expect(await mediaFile.exists(), isFalse);
      expect(await thumbFile.exists(), isFalse);
      expect(mdk.lastCreatedMessageKind, 4545);
      expect(blossom.reportedServers, ['https://snapshot.example']);
      expect(blossom.reportedEventJsons.single, contains('"kind":1984'));

      final logs = await (database.select(
        database.moderationAuditLogs,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      expect(logs, hasLength(1));
      expect(logs.single.actionType, 'delete_video');
      expect(logs.single.videoId, 'video-1');
    },
  );

  group('blockCreator', () {
    late OfflineActionStore offlineStore;
    late UserListSyncService syncService;
    late ModerationCoordinator coordinatorWithSync;

    setUp(() {
      offlineStore = OfflineActionStore(database: database);
      syncService = UserListSyncService(
        nostrService: nostr,
        offlineActionStore: offlineStore,
      );
      coordinatorWithSync = ModerationCoordinator(
        database: database,
        blossomClient: blossom,
        mdkService: mdk,
        nostrService: nostr,
        videoLifecycleCoordinator: VideoLifecycleCoordinator(
          mdkService: mdk,
          nostrService: nostr,
        ),
        userListSyncService: syncService,
      );
    });

    test('adds pubkey to mute list and publishes', () async {
      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'creator-aaa',
      );

      expect(nostr.publishedMuteListEntries, hasLength(1));
      expect(
        nostr.publishedMuteListEntries.single.single.pubkeyHex,
        'creator-aaa',
      );
      expect(nostr.savedMuteList?.entries.single.pubkeyHex, 'creator-aaa');

      final logs = await (database.select(
        database.moderationAuditLogs,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      expect(logs, hasLength(1));
      expect(logs.single.actionType, 'block_creator');
      expect(logs.single.subjectParentKey, 'creator-aaa');
    });

    test('normalizes pubkey to lowercase', () async {
      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'Creator-BBB',
      );

      expect(nostr.savedMuteList?.entries.single.pubkeyHex, 'creator-bbb');
    });

    test('is idempotent — second call does not re-publish', () async {
      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'creator-ccc',
      );
      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'creator-ccc',
      );

      expect(nostr.publishedMuteListEntries, hasLength(1));
      expect(nostr.savedMuteList?.entries, hasLength(1));
    });

    test('idempotency is case-insensitive', () async {
      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'creator-ddd',
      );
      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'CREATOR-DDD',
      );

      expect(nostr.publishedMuteListEntries, hasLength(1));
    });

    test('writes audit log even without userListSyncService', () async {
      await coordinator.blockCreator(
        identity: identity,
        pubkeyHex: 'creator-eee',
      );

      expect(nostr.publishedMuteListEntries, isEmpty);

      final logs = await (database.select(
        database.moderationAuditLogs,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      expect(logs, hasLength(1));
      expect(logs.single.actionType, 'block_creator');
    });

    test('appends to existing mute list without losing entries', () async {
      nostr.savedMuteList = const MuteList(
        entries: [MuteEntry(pubkeyHex: 'existing-creator')],
      );

      await coordinatorWithSync.blockCreator(
        identity: identity,
        pubkeyHex: 'new-creator',
      );

      expect(nostr.savedMuteList?.entries, hasLength(2));
    });
  });

  group('promoteMemberToAdmin', () {
    test('merges admin set and publishes commit', () async {
      mdk.groupMembersResult = ['parent-pubkey', 'other-parent'];

      await coordinator.promoteMemberToAdmin(
        identity: identity,
        mlsGroupIdHex: 'group-123',
        currentAdminPubkeysHex: ['parent-pubkey'],
        memberPubkeyHex: 'other-parent',
      );

      expect(mdk.lastUpdatedAdminsGroupId, 'group-123');
      expect(
        mdk.lastUpdatedAdminPubkeys,
        containsAll(['parent-pubkey', 'other-parent']),
      );
      expect(nostr.lastPublishedEventJson, '{"id":"admin-update"}');

      final logs = await (database.select(
        database.moderationAuditLogs,
      )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
      expect(logs, hasLength(1));
      expect(logs.single.actionType, 'promote_admin');
      expect(logs.single.subjectParentKey, 'other-parent');
    });

    test('normalizes pubkey to lowercase', () async {
      mdk.groupMembersResult = ['parent-pubkey', 'other-parent'];

      await coordinator.promoteMemberToAdmin(
        identity: identity,
        mlsGroupIdHex: 'group-123',
        currentAdminPubkeysHex: ['parent-pubkey'],
        memberPubkeyHex: 'OTHER-PARENT',
      );

      expect(mdk.lastUpdatedAdminPubkeys, contains('other-parent'));
    });
  });

  group('leaveGroup', () {
    test('as non-admin member skips selfDemote', () async {
      mdk.groupMembersResult = ['parent-pubkey', 'other-parent'];

      await coordinator.leaveGroup(
        identity: identity,
        mlsGroupIdHex: 'group-123',
        isAdmin: false,
      );

      expect(mdk.lastSelfDemoteGroupId, isNull);
      expect(mdk.lastLeaveGroupId, 'group-123');
      expect(nostr.publishedEventJsons, contains('{"id":"leave"}'));

      final leftIds = await database.getLeftFamilySpaceIds();
      expect(leftIds, contains('group-123'));
    });

    test('as admin with other members calls selfDemote then leave', () async {
      mdk.groupMembersResult = ['parent-pubkey', 'other-parent'];

      await coordinator.leaveGroup(
        identity: identity,
        mlsGroupIdHex: 'group-123',
        isAdmin: true,
      );

      expect(mdk.lastSelfDemoteGroupId, 'group-123');
      expect(mdk.lastLeaveGroupId, 'group-123');
      expect(
        nostr.publishedEventJsons,
        containsAll(['{"id":"demote"}', '{"id":"leave"}']),
      );
    });

    test('as solo admin abandons locally without network calls', () async {
      mdk.groupMembersResult = ['parent-pubkey'];

      await coordinator.leaveGroup(
        identity: identity,
        mlsGroupIdHex: 'group-solo',
        isAdmin: true,
      );

      expect(mdk.lastSelfDemoteGroupId, isNull);
      expect(mdk.lastLeaveGroupId, isNull);
      expect(nostr.publishedEventJsons, isEmpty);

      final leftIds = await database.getLeftFamilySpaceIds();
      expect(leftIds, contains('group-solo'));
    });

    test(
      'selfDemote last-admin error throws LastAdminCannotLeaveException',
      () async {
        mdk.groupMembersResult = ['parent-pubkey', 'other-parent'];
        mdk.throwOnSelfDemote = true;
        mdk.selfDemoteThrowMessage = 'last active admin';

        await expectLater(
          coordinator.leaveGroup(
            identity: identity,
            mlsGroupIdHex: 'group-123',
            isAdmin: true,
          ),
          throwsA(isA<LastAdminCannotLeaveException>()),
        );

        expect(mdk.lastLeaveGroupId, isNull);
      },
    );

    test('selfDemote unrelated error rethrows verbatim', () async {
      mdk.groupMembersResult = ['parent-pubkey', 'other-parent'];
      mdk.throwOnSelfDemote = true;
      mdk.selfDemoteThrowMessage = 'network timeout';

      await expectLater(
        coordinator.leaveGroup(
          identity: identity,
          mlsGroupIdHex: 'group-123',
          isAdmin: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('clears pending connections for other members', () async {
      mdk.groupMembersResult = [
        'parent-pubkey',
        'other-parent',
        'third-parent',
      ];
      final connectionService = _FakeFamilyConnectionService();
      final coordinatorWithConnection = ModerationCoordinator(
        database: database,
        blossomClient: blossom,
        mdkService: mdk,
        nostrService: nostr,
        videoLifecycleCoordinator: VideoLifecycleCoordinator(
          mdkService: mdk,
          nostrService: nostr,
        ),
        familyConnectionService: connectionService,
      );

      await coordinatorWithConnection.leaveGroup(
        identity: identity,
        mlsGroupIdHex: 'group-123',
        isAdmin: false,
      );

      expect(
        connectionService.clearedPubkeys,
        containsAll(['other-parent', 'third-parent']),
      );
    });
  });
}

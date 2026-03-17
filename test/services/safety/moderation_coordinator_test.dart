import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/marmot/message_models.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/domain/models/remote_share_identity.dart';
import 'package:mytube/services/safety/moderation_coordinator.dart';
import 'package:mytube/services/share/video_lifecycle_coordinator.dart';

import '../../test_support/service_fakes.dart';

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

  test('removeMember publishes commit and records moderation audit log', () async {
    await coordinator.removeMember(
      identity: identity,
      mlsGroupIdHex: 'group-123',
      memberPubkeyHex: 'other-parent',
      reason: 'Moderator action',
    );

    expect(mdk.lastRemovedMemberPubkeys, ['other-parent']);
    expect(nostr.lastPublishedEventJson, '{"id":"commit"}');

    final logs =
        await (database.select(database.moderationAuditLogs)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    expect(logs, hasLength(1));
    expect(logs.single.actionType, 'remove_member');
    expect(logs.single.subjectParentKey, 'other-parent');
  });

  test('deleteSharedVideo publishes lifecycle, purges cache, and records audit log', () async {
    final tempDir = await Directory.systemTemp.createTemp('moderation-test');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });
    final mediaFile = File('${tempDir.path}/clip.mp4')..writeAsBytesSync([1, 2, 3]);
    final thumbFile = File('${tempDir.path}/thumb.jpg')..writeAsBytesSync([4, 5, 6]);

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

    final logs =
        await (database.select(database.moderationAuditLogs)
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();
    expect(logs, hasLength(1));
    expect(logs.single.actionType, 'delete_video');
    expect(logs.single.videoId, 'video-1');
  });
}

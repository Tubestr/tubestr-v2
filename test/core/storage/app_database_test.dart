import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/remote_share_identity.dart';

void main() {
  test(
    'saveLocalVideo persists a captured clip with thumbnail metadata',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.upsertProfile(
        id: 'profile-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'assets/avatar.png',
      );

      await database.saveLocalVideo(
        videoId: 'video-1',
        profileId: 'profile-1',
        filePath: '/tmp/video.mp4',
        thumbPath: '/tmp/video.jpg',
        title: 'Backyard song',
        durationSeconds: 12.5,
        tags: const ['captured'],
      );

      final videos = await database.watchVideosForProfile('profile-1').first;

      expect(videos, hasLength(1));
      expect(videos.single.filePath, '/tmp/video.mp4');
      expect(videos.single.thumbPath, '/tmp/video.jpg');
      expect(videos.single.tags, contains('captured'));
      expect(videos.single.durationSeconds, 12.5);
    },
  );

  test('remote share cache helpers update local paths and status', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final remoteShareId = await database.upsertRemoteShareProjection(
      videoId: 'remote-1',
      mlsGroupId: 'group-1',
      senderParentKey: 'sender-1',
      childProfileId: 'child-1',
      childDisplayName: 'Emma',
      blobHash: 'blob-1',
      thumbHash: 'thumb-1',
      epoch: '1',
      mime: 'video/mp4',
      metadataJson: '{"t":"mytube/video_share"}',
    );

    await database.updateRemoteAssetCache(
      remoteShareId: remoteShareId,
      localMediaPath: '/tmp/remote.mp4',
      localThumbPath: '/tmp/remote.jpg',
    );
    await database.updateRemoteShareStatus(
      remoteShareId: remoteShareId,
      status: 'downloaded',
      downloadError: null,
    );

    final remoteAsset = await database.getRemoteAssetByRemoteShareId(remoteShareId);
    final shares = await database.watchShareRecords().first;

    expect(remoteAsset?.localMediaPath, '/tmp/remote.mp4');
    expect(remoteAsset?.localThumbPath, '/tmp/remote.jpg');
    expect(shares.single.status, 'downloaded');
    expect(shares.single.downloadError, isNull);
  });

  test('remote shares with the same video id stay isolated by scoped remoteShareId', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final firstRemoteShareId = await database.upsertRemoteShareProjection(
      videoId: 'shared-video',
      mlsGroupId: 'group-1',
      senderParentKey: 'sender-1',
      childProfileId: 'child-1',
      childDisplayName: 'Emma',
      blobHash: 'blob-1',
      thumbHash: 'thumb-1',
      epoch: '1',
      mime: 'video/mp4',
      metadataJson: '{"t":"mytube/video_share"}',
    );
    final secondRemoteShareId = await database.upsertRemoteShareProjection(
      videoId: 'shared-video',
      mlsGroupId: 'group-2',
      senderParentKey: 'sender-2',
      childProfileId: 'child-2',
      childDisplayName: 'Noah',
      blobHash: 'blob-2',
      thumbHash: 'thumb-2',
      epoch: '2',
      mime: 'video/mp4',
      metadataJson: '{"t":"mytube/video_share"}',
    );

    await database.updateRemoteAssetCache(
      remoteShareId: firstRemoteShareId,
      localMediaPath: '/tmp/one.mp4',
      localThumbPath: '/tmp/one.jpg',
    );
    await database.updateRemoteShareStatus(
      remoteShareId: firstRemoteShareId,
      status: 'downloaded',
    );

    final first = await database.getRemoteShareProjectionByRemoteShareId(
      firstRemoteShareId,
    );
    final second = await database.getRemoteShareProjectionByRemoteShareId(
      secondRemoteShareId,
    );
    final allRemoteShares = await database.watchRemoteShareProjections().first;

    expect(
      firstRemoteShareId,
      buildRemoteShareId(
        senderParentKey: 'sender-1',
        mlsGroupId: 'group-1',
        videoId: 'shared-video',
      ),
    );
    expect(secondRemoteShareId, isNot(firstRemoteShareId));
    expect(first?.status, 'downloaded');
    expect(first?.localMediaPath, '/tmp/one.mp4');
    expect(second?.status, 'available');
    expect(second?.localMediaPath, isNull);
    expect(allRemoteShares, hasLength(2));
  });

  test(
    'primary group helpers assign a group to profiles that do not have one',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.upsertProfile(
        id: 'profile-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'assets/avatar.png',
      );
      await database.upsertProfile(
        id: 'profile-2',
        name: 'Noah',
        theme: 'treehouse',
        avatarAsset: 'assets/avatar-2.png',
      );

      await database.setPrimaryGroupForProfile(
        profileId: 'profile-1',
        mlsGroupId: 'group-1',
      );
      await database.assignPrimaryGroupToProfilesIfMissing('group-1');

      expect(
        await database.getPrimaryGroupIdForProfile('profile-1'),
        'group-1',
      );
      expect(
        await database.getPrimaryGroupIdForProfile('profile-2'),
        'group-1',
      );
      expect(await database.getPrimaryGroupIdForAnyProfile(), 'group-1');
    },
  );
}

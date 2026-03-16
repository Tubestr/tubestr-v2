import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';

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

    await database.upsertRemoteShareProjection(
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
      videoId: 'remote-1',
      localMediaPath: '/tmp/remote.mp4',
      localThumbPath: '/tmp/remote.jpg',
    );
    await database.updateRemoteShareStatus(
      videoId: 'remote-1',
      status: 'downloaded',
      downloadError: null,
    );

    final remoteAsset = await database.getRemoteAssetByVideoId('remote-1');
    final shares = await database.watchShareRecords().first;

    expect(remoteAsset?.localMediaPath, '/tmp/remote.mp4');
    expect(remoteAsset?.localThumbPath, '/tmp/remote.jpg');
    expect(shares.single.status, 'downloaded');
    expect(shares.single.downloadError, isNull);
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

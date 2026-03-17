import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/engagement/playback_metrics_coordinator.dart';

void main() {
  late AppDatabase database;
  late PlaybackMetricsCoordinator coordinator;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    coordinator = PlaybackMetricsCoordinator(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'recordLocalPlayback updates local play, completion, and replay metrics',
    () async {
      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );
      await database.saveLocalVideo(
        videoId: 'video-1',
        profileId: 'child-1',
        filePath: '/tmp/video.mp4',
        thumbPath: '/tmp/video.jpg',
        title: 'Backyard',
      );

      await coordinator.recordLocalPlayback(
        videoId: 'video-1',
        completionRatio: 0.8,
        replayed: true,
      );

      final video = await database.getLocalVideoById('video-1');
      expect(video, isNotNull);
      expect(video!.playCount, 1);
      expect(video.completionRate, closeTo(0.8, 0.001));
      expect(video.replayRate, closeTo(1.0, 0.001));
    },
  );

  test('recordRemotePlayback stores remote metrics by share id', () async {
    final remoteShareId = await database.upsertRemoteShareProjection(
      videoId: 'remote-video',
      mlsGroupId: 'family-group',
      senderParentKey: 'parent-a',
      childProfileId: 'child-2',
      childDisplayName: 'Noah',
      blobHash: 'blob-1',
      thumbHash: 'thumb-1',
      epoch: 'epoch-1',
      mime: 'video/mp4',
      metadataJson: '{}',
    );

    await coordinator.recordRemotePlayback(
      remoteShareId: remoteShareId,
      videoId: 'remote-video',
      completionRatio: 0.6,
      replayed: false,
    );

    final metrics = await database
        .watchRemotePlaybackMetrics(remoteShareId)
        .first;
    expect(metrics, isNotNull);
    expect(metrics!.playCount, 1);
    expect(metrics.completionRate, closeTo(0.6, 0.001));
    expect(metrics.replayRate, closeTo(0.0, 0.001));
  });
}

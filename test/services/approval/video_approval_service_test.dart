import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/approval/content_scan_service.dart';
import 'package:mytube/services/approval/media_signal_extraction_service.dart';
import 'package:mytube/services/approval/video_approval_service.dart';

void main() {
  late AppDatabase database;
  late VideoApprovalService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = VideoApprovalService(
      database: database,
      scanService: const ContentScanService(),
      signalExtractionService: MediaSignalExtractionService(
        extractSignals: (video) async => MediaSignalExtractionResult(
          cvLabels: video.cvLabels,
          faceCount: video.faceCount,
          loudness: video.loudness,
        ),
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'scanAndClassifyVideo leaves new clips pending when approval is required',
    () async {
      await service.setApprovalRequired(true);
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
        title: 'Playground',
        tags: const ['captured'],
        approvalStatus: 'pending',
      );

      final scan = await service.scanAndClassifyVideo(videoId: 'video-1');
      final saved = await database.getLocalVideoById('video-1');

      expect(scan.needsReview, isFalse);
      expect(saved?.approvalStatus, 'pending');
      expect(saved?.scanResults, isNotNull);
      expect(saved?.scanCompletedAt, isNotNull);
    },
  );

  test(
    'scanAndClassifyVideo auto-approves safe clips when approval is disabled',
    () async {
      await service.setApprovalRequired(false);
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
        tags: const ['captured'],
        approvalStatus: 'pending',
      );

      await service.scanAndClassifyVideo(videoId: 'video-1');
      final saved = await database.getLocalVideoById('video-1');

      expect(saved?.approvalStatus, 'approved');
      expect(saved?.approvedAt, isNotNull);
    },
  );

  test(
    'scanAndClassifyVideo still leaves risky clips pending when approval is disabled',
    () async {
      await service.setApprovalRequired(false);
      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );
      await database.saveLocalVideo(
        videoId: 'video-2',
        profileId: 'child-1',
        filePath: '/tmp/video.mp4',
        thumbPath: '/tmp/video.jpg',
        title: 'Scary challenge',
        tags: const ['captured'],
        approvalStatus: 'pending',
      );

      final scan = await service.scanAndClassifyVideo(videoId: 'video-2');
      final saved = await database.getLocalVideoById('video-2');

      expect(scan.needsReview, isTrue);
      expect(saved?.approvalStatus, 'pending');
    },
  );

  test('scanAndClassifyVideo persists extracted media signals', () async {
    service = VideoApprovalService(
      database: database,
      scanService: const ContentScanService(),
      signalExtractionService: MediaSignalExtractionService(
        extractSignals: (_) async =>
            const MediaSignalExtractionResult(faceCount: 5, loudness: 0.9),
      ),
    );
    await service.setApprovalRequired(false);
    await database.upsertProfile(
      id: 'child-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'avatar.png',
    );
    await database.saveLocalVideo(
      videoId: 'video-3',
      profileId: 'child-1',
      filePath: '/tmp/video.mp4',
      thumbPath: '/tmp/video.jpg',
      title: 'Birthday',
      approvalStatus: 'pending',
    );

    final scan = await service.scanAndClassifyVideo(videoId: 'video-3');
    final saved = await database.getLocalVideoById('video-3');

    expect(scan.needsReview, isTrue);
    expect(saved?.faceCount, 5);
    expect(saved?.loudness, 0.9);
    expect(saved?.scanVersion, 1);
    expect(saved?.highestRiskCategory, 'intense_audio');
    expect(saved?.scanConfidence, isNotNull);
    expect(saved?.reviewReasons, isNotEmpty);
    expect(saved?.approvalStatus, 'pending');
  });
}

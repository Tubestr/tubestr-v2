import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/approval/content_scan_service.dart';
import 'package:mytube/services/approval/video_approval_service.dart';

void main() {
  late AppDatabase database;
  late VideoApprovalService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    service = VideoApprovalService(
      database: database,
      scanService: const ContentScanService(),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'scanAndClassifyVideo leaves new clips pending when approval is required',
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
}

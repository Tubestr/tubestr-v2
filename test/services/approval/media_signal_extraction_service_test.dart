import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/approval/media_signal_extraction_service.dart';

void main() {
  LocalVideo buildVideo() {
    return LocalVideo(
      id: 'video-1',
      profileId: 'child-1',
      filePath: '/tmp/video.mp4',
      thumbPath: '/tmp/thumb.jpg',
      title: 'Backyard drawing',
      durationSeconds: 24,
      createdAt: DateTime.utc(2026, 3, 19),
      lastPlayedAt: null,
      playCount: 0,
      completionRate: 0,
      replayRate: 0,
      liked: false,
      hidden: false,
      tags: const <String>['captured'],
      cvLabels: const <String>[],
      faceCount: 0,
      loudness: 0,
      reportedAt: null,
      reportReason: null,
      approvalStatus: 'pending',
      approvedAt: null,
      approvedByParentKey: null,
      scanVersion: 0,
      highestRiskCategory: null,
      scanConfidence: null,
      reviewReasons: const <String>[],
      scanResults: null,
      scanCompletedAt: null,
    );
  }

  test('extractSignals returns injected face and loudness values', () async {
    var called = false;
    final service = MediaSignalExtractionService(
      extractSignals: (video) async {
        called = true;
        expect(video.id, 'video-1');
        return const MediaSignalExtractionResult(faceCount: 4, loudness: 0.88);
      },
    );

    final result = await service.extractSignals(video: buildVideo());

    expect(called, isTrue);
    expect(result.faceCount, 4);
    expect(result.loudness, 0.88);
    expect(result.cvLabels, isEmpty);
  });
}

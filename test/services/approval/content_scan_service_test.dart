import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/services/approval/content_scan_service.dart';

void main() {
  const service = ContentScanService();

  LocalVideo buildVideo({
    required String title,
    List<String> tags = const <String>[],
    List<String> cvLabels = const <String>[],
    double loudness = 0.2,
    int faceCount = 1,
    double durationSeconds = 20,
  }) {
    return LocalVideo(
      id: 'video-1',
      profileId: 'child-1',
      filePath: '/tmp/video.mp4',
      thumbPath: '/tmp/thumb.jpg',
      title: title,
      durationSeconds: durationSeconds,
      createdAt: DateTime.utc(2026, 3, 17),
      lastPlayedAt: null,
      playCount: 0,
      completionRate: 0,
      replayRate: 0,
      liked: false,
      hidden: false,
      tags: tags,
      cvLabels: cvLabels,
      faceCount: faceCount,
      loudness: loudness,
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

  test('uses title and labels to mark sensitive clips for review', () {
    final scan = service.scanVideo(
      buildVideo(title: 'Scary challenge night', tags: const ['prank']),
    );

    expect(scan.riskLevel, 'medium');
    expect(scan.scanVersion, 1);
    expect(scan.highestRiskCategory, 'sensitive_topic');
    expect(scan.confidence, greaterThan(0.5));
    expect(scan.needsReview, isTrue);
    expect(
      scan.flags,
      containsAll(['review_label', 'attention_seeking_title']),
    );
    expect(scan.reviewReasons, isNotEmpty);
    expect(scan.summary, contains('Please check'));
  });

  test('keeps calm low-signal clips low risk', () {
    final scan = service.scanVideo(
      buildVideo(
        title: 'Backyard drawing',
        tags: const ['art'],
        cvLabels: const ['outside'],
      ),
    );

    expect(scan.riskLevel, 'low');
    expect(scan.highestRiskCategory, isNull);
    expect(scan.needsReview, isFalse);
    expect(scan.flags, isEmpty);
  });

  test('adds media-based review reasons for loud crowded long clips', () {
    final scan = service.scanVideo(
      buildVideo(
        title: 'Birthday party',
        loudness: 0.95,
        faceCount: 5,
        durationSeconds: 220,
      ),
    );

    expect(scan.riskLevel, 'high');
    expect(scan.highestRiskCategory, 'intense_audio');
    expect(scan.confidence, greaterThan(0.8));
    expect(
      scan.flags,
      containsAll(['very_loud_audio', 'crowded_frame', 'long_clip']),
    );
  });
}

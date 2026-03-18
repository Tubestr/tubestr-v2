import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/marmot/message_models.dart';

void main() {
  test('video share message encodes and decodes with typed payloads', () {
    const message = VideoShareMessage(
      videoId: 'video-123',
      childProfileId: 'child-123',
      childDisplayName: 'Emma',
      meta: VideoMeta(
        title: 'Backyard song',
        durationSeconds: 42.5,
        createdAt: 1710460800,
      ),
      blob: BlobDescriptor(
        hash: 'blob-hash',
        servers: ['https://blossom.tubestr.app'],
        mime: 'video/mp4',
        length: 4821504,
        originalHash: 'orig-video',
        nonce: 'nonce-video',
        filename: 'clip.mp4',
        schemeVersion: 'mip04-v2',
      ),
      thumb: BlobDescriptor(
        hash: 'thumb-hash',
        servers: ['https://blossom.tubestr.app'],
        mime: 'image/jpeg',
        length: 48215,
        originalHash: 'orig-thumb',
        nonce: 'nonce-thumb',
        filename: 'clip.jpg',
        schemeVersion: 'mip04-v2',
      ),
      media: MediaDescriptor(algorithm: 'mip04', epoch: 'epoch-value'),
      policy: PolicyDescriptor(version: 2, expiresAt: null),
      by: 'parent-pubkey',
      ts: 1710460800,
    );

    final encoded = message.encode();
    final decoded = VideoShareMessage.decode(encoded);

    expect(decoded.videoId, message.videoId);
    expect(decoded.childDisplayName, 'Emma');
    expect(decoded.meta.durationSeconds, 42.5);
    expect(decoded.blob.hash, 'blob-hash');
    expect(decoded.blob.originalHash, 'orig-video');
    expect(decoded.thumb.filename, 'clip.jpg');
    expect(decoded.media.algorithm, 'mip04');
    expect(decoded.policy.version, 2);
  });

  test('report message requires blob hash for moderation routing', () {
    final decoded = ReportMessage.fromJson({
      't': 'mytube/report',
      'report_id': 'report-1',
      'video_id': 'video-123',
      'subject_child_id': 'child-123',
      'blob_hash': 'blob-hash',
      'reason': 'inappropriate',
      'note': 'Need review',
      'level': 2,
      'recipient_type': 'parents',
      'reporter_child_id': 'child-456',
      'by': 'parent-pubkey',
      'ts': 1710460800,
    });

    expect(decoded.blobHash, 'blob-hash');
    expect(decoded.recipientType, 'parents');
    expect(decoded.reporterChildId, 'child-456');
  });

  test('video lifecycle rejects unknown message type', () {
    expect(
      () => VideoLifecycleMessage.fromJson({
        't': 'mytube/not_real',
        'video_id': 'video-123',
        'blob_hash': 'blob-hash',
        'by': 'parent-pubkey',
        'ts': 1710460800,
      }),
      throwsA(isA<MarmotMessageFormatException>()),
    );
  });
}

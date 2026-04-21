import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/offline_action.dart';
import 'package:mytube/domain/models/remote_share_projection.dart';
import 'package:mytube/domain/models/share_history_entry.dart';
import 'package:mytube/features/parent_zone/presentation/models/launch_diagnostics.dart';
import 'package:mytube/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test(
    'buildLaunchDiagnosticsSnapshot groups queued work and launch issues',
    () {
      final snapshot = buildLaunchDiagnosticsSnapshot(
        queuedActions: [
          OfflineAction(
            id: 'a1',
            type: OfflineActionType.shareVideo,
            payload: const {'video_id': 'video-1'},
            createdAt: DateTime(2026, 3, 19, 10),
          ),
          OfflineAction(
            id: 'a2',
            type: OfflineActionType.submitReport,
            payload: const {'video_id': 'video-2'},
            createdAt: DateTime(2026, 3, 19, 11),
          ),
          OfflineAction(
            id: 'a3',
            type: OfflineActionType.shareVideo,
            payload: const {'video_id': 'video-3'},
            createdAt: DateTime(2026, 3, 19, 12),
          ),
        ],
        shareHistory: [
          ShareHistoryEntry(
            id: 's1',
            videoId: 'video-1',
            title: 'Sent clip',
            childProfileId: 'child-1',
            childDisplayName: 'Emma',
            mlsGroupId: 'group-1',
            status: 'sent',
            createdAt: DateTime(2026, 3, 19, 9),
          ),
          ShareHistoryEntry(
            id: 's2',
            videoId: 'video-2',
            title: 'Queued clip',
            childProfileId: 'child-1',
            childDisplayName: 'Emma',
            mlsGroupId: 'group-1',
            status: 'queued',
            createdAt: DateTime(2026, 3, 19, 10),
            error: 'relay offline',
          ),
        ],
        reports: [
          Report(
            id: 'r1',
            videoId: 'video-1',
            subjectChildId: 'child-1',
            reason: 'unsafe',
            level: 3,
            recipientType: 'family',
            reporterParentKey: 'parent-1',
            status: 'queued_offline',
            isOutbound: true,
            createdAt: DateTime(2026, 3, 19, 13),
          ),
          Report(
            id: 'r2',
            videoId: 'video-2',
            subjectChildId: 'child-2',
            reason: 'delivered',
            level: 1,
            recipientType: 'local',
            reporterParentKey: 'parent-1',
            status: 'delivered',
            isOutbound: true,
            createdAt: DateTime(2026, 3, 19, 14),
          ),
        ],
        remoteShares: [
          RemoteShareProjection(
            remoteShareId: 'remote-1',
            videoId: 'video-r1',
            mlsGroupId: 'group-1',
            senderParentKey: 'parent-a',
            childProfileId: 'child-1',
            childDisplayName: 'Noah',
            status: 'failed',
            receivedAt: DateTime(2026, 3, 19, 15),
            downloadError: 'SocketException: timed out',
            blobHash: 'blob-1',
            thumbHash: 'thumb-1',
            epoch: '1',
            mime: 'video/mp4',
            metadataJson: null,
            localMediaPath: null,
            localThumbPath: null,
          ),
        ],
        l10n: l10n,
      );

      expect(snapshot.hasIssues, isTrue);
      expect(snapshot.totalIssueCount, 6);
      expect(snapshot.actionsByType, hasLength(2));
      expect(snapshot.actionsByType.first.label, 'Queued shares');
      expect(snapshot.actionsByType.first.count, 2);
      expect(snapshot.shareIssues.single.title, 'Queued clip');
      expect(snapshot.reportIssues.single.status, 'queued_offline');
      expect(snapshot.downloadIssues.single.remoteShareId, 'remote-1');
    },
  );

  test('status helpers return launch-friendly labels', () {
    expect(describeShareStatus('queued', l10n), 'Waiting for retry');
    expect(
      describeReportStatus('pending_blob_hash', l10n),
      'Waiting for encrypted media reference',
    );
    expect(
      summarizeDownloadError(
        'StateError: Downloaded video did not match expected video/mp4.',
        l10n,
      ),
      'Download failed because the saved copy did not pass verification.',
    );
    expect(
      summarizeDownloadError('SocketException: Network unreachable', l10n),
      'Download failed because the relay or media server was unreachable.',
    );
  });
}

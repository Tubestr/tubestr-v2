import '../../../../core/storage/app_database.dart';
import '../../../../domain/models/offline_action.dart';
import '../../../../domain/models/remote_share_projection.dart';
import '../../../../domain/models/share_history_entry.dart';

class LaunchDiagnosticsSnapshot {
  const LaunchDiagnosticsSnapshot({
    required this.queuedActions,
    required this.actionsByType,
    required this.shareIssues,
    required this.reportIssues,
    required this.downloadIssues,
  });

  final List<OfflineAction> queuedActions;
  final List<LaunchDiagnosticsCount> actionsByType;
  final List<ShareHistoryEntry> shareIssues;
  final List<Report> reportIssues;
  final List<RemoteShareProjection> downloadIssues;

  int get totalIssueCount =>
      queuedActions.length +
      shareIssues.length +
      reportIssues.length +
      downloadIssues.length;

  bool get hasIssues => totalIssueCount > 0;
}

class LaunchDiagnosticsCount {
  const LaunchDiagnosticsCount({required this.label, required this.count});

  final String label;
  final int count;
}

LaunchDiagnosticsSnapshot buildLaunchDiagnosticsSnapshot({
  required List<OfflineAction> queuedActions,
  required List<ShareHistoryEntry> shareHistory,
  required List<Report> reports,
  required List<RemoteShareProjection> remoteShares,
}) {
  final counts = <OfflineActionType, int>{};
  for (final action in queuedActions) {
    counts.update(action.type, (value) => value + 1, ifAbsent: () => 1);
  }

  final actionsByType =
      counts.entries
          .map(
            (entry) => LaunchDiagnosticsCount(
              label: describeOfflineActionType(entry.key),
              count: entry.value,
            ),
          )
          .toList(growable: false)
        ..sort((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare != 0) {
            return countCompare;
          }
          return a.label.compareTo(b.label);
        });

  final shareIssues = shareHistory
      .where((entry) => entry.status != 'sent')
      .take(5)
      .toList(growable: false);
  final reportIssues = reports
      .where((report) => report.isOutbound && report.status != 'delivered')
      .take(5)
      .toList(growable: false);
  final downloadIssues = remoteShares
      .where((share) => share.status == 'failed')
      .take(5)
      .toList(growable: false);

  return LaunchDiagnosticsSnapshot(
    queuedActions: queuedActions,
    actionsByType: actionsByType,
    shareIssues: shareIssues,
    reportIssues: reportIssues,
    downloadIssues: downloadIssues,
  );
}

String describeOfflineActionType(OfflineActionType type) {
  return switch (type) {
    OfflineActionType.shareVideo => 'Queued shares',
    OfflineActionType.sendLike => 'Queued likes',
    OfflineActionType.sendReaction => 'Queued reactions',
    OfflineActionType.submitReport => 'Queued reports',
    OfflineActionType.publishParentProfile => 'Queued profile updates',
  };
}

String describeShareStatus(String status) {
  return switch (status) {
    'sent' => 'Delivered',
    'queued' => 'Waiting for retry',
    _ => status,
  };
}

String describeReportStatus(String status) {
  return switch (status) {
    'delivered' => 'Delivered',
    'queued_safety' => 'Waiting on Safety HQ copy',
    'queued_offline' => 'Waiting for connection',
    'pending_blob_hash' => 'Waiting for encrypted media reference',
    'failed' => 'Delivery failed',
    _ => status,
  };
}

String summarizeDownloadError(String? error) {
  final lower = error?.trim().toLowerCase() ?? '';
  if (lower.isEmpty) {
    return 'Download failed. Retry when the connection is stable.';
  }
  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('timeout')) {
    return 'Download failed because the relay or media server was unreachable.';
  }
  if (lower.contains('decrypt') || lower.contains('mip-04')) {
    return 'Download failed while unlocking the encrypted video package.';
  }
  if (lower.contains('cache') || lower.contains('expected')) {
    return 'Download failed because the saved copy did not pass verification.';
  }
  if (lower.contains('metadata') || lower.contains('reference fields')) {
    return 'Download failed because the shared clip metadata was incomplete.';
  }
  return 'Download failed. Retry to fetch a fresh encrypted copy.';
}

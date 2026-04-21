import '../../../../core/storage/app_database.dart';
import '../../../../domain/models/offline_action.dart';
import '../../../../domain/models/remote_share_projection.dart';
import '../../../../domain/models/share_history_entry.dart';
import '../../../../l10n/app_localizations.dart';

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
  required AppLocalizations l10n,
}) {
  final counts = <OfflineActionType, int>{};
  for (final action in queuedActions) {
    counts.update(action.type, (value) => value + 1, ifAbsent: () => 1);
  }

  final actionsByType =
      counts.entries
          .map(
            (entry) => LaunchDiagnosticsCount(
              label: describeOfflineActionType(entry.key, l10n),
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

String describeOfflineActionType(
  OfflineActionType type,
  AppLocalizations l10n,
) {
  return switch (type) {
    OfflineActionType.shareVideo => l10n.launchQueuedShares,
    OfflineActionType.sendLike => l10n.launchQueuedLikes,
    OfflineActionType.sendReaction => l10n.launchQueuedReactions,
    OfflineActionType.submitReport => l10n.launchQueuedReports,
    OfflineActionType.publishParentProfile => l10n.launchQueuedProfileUpdates,
    OfflineActionType.publishRelayList => l10n.launchQueuedRelayUpdates,
    OfflineActionType.publishBlossomServerList =>
      l10n.launchQueuedMediaServerUpdates,
    OfflineActionType.publishMuteList => l10n.launchQueuedMuteUpdates,
  };
}

String describeShareStatus(String status, AppLocalizations l10n) {
  return switch (status) {
    'sent' => l10n.launchDelivered,
    'queued' => l10n.launchWaitingRetry,
    _ => status,
  };
}

String describeReportStatus(String status, AppLocalizations l10n) {
  return switch (status) {
    'delivered' => l10n.launchDelivered,
    'queued_safety' => l10n.launchWaitingSafety,
    'queued_offline' => l10n.launchWaitingConnection,
    'pending_blob_hash' => l10n.launchWaitingMediaReference,
    'failed' => l10n.launchDeliveryFailed,
    _ => status,
  };
}

String describeReportReason(String reason, AppLocalizations l10n) {
  return switch (reason) {
    'inappropriate' => l10n.reportReasonInappropriate,
    'harassment' => l10n.reportReasonHarassment,
    'unsafe' => l10n.reportReasonUnsafe,
    'illegal' => l10n.reportReasonIllegal,
    _ => reason,
  };
}

String summarizeDownloadError(String? error, AppLocalizations l10n) {
  final lower = error?.trim().toLowerCase() ?? '';
  if (lower.isEmpty) {
    return l10n.launchDownloadFailed;
  }
  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('timeout')) {
    return l10n.launchDownloadRelayFailed;
  }
  if (lower.contains('decrypt') || lower.contains('mip-04')) {
    return l10n.launchDownloadUnlockFailed;
  }
  if (lower.contains('cache') || lower.contains('expected')) {
    return l10n.launchDownloadVerifyFailed;
  }
  if (lower.contains('metadata') || lower.contains('reference fields')) {
    return l10n.launchDownloadMetadataFailed;
  }
  return l10n.launchDownloadGenericFailed;
}

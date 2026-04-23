import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/spacing.dart';
import '../models/launch_diagnostics.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../l10n/l10n.dart';

final _appPackageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

class ParentZoneDiagnosticsSection extends ConsumerWidget {
  const ParentZoneDiagnosticsSection({
    super.key,
    required this.onRefreshPanel,
    required this.onRefreshSubscriptions,
  });

  final VoidCallback onRefreshPanel;
  final Future<void> Function() onRefreshSubscriptions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    ref.watch(syncDiagnosticsRevisionProvider);
    final diagnostics = ref.read(syncCoordinatorProvider).debugSnapshot();
    final dump = ref.read(syncCoordinatorProvider).debugDescribeState();
    final queuedActions =
        ref.watch(offlineActionsProvider).valueOrNull ?? const [];
    final shareHistory =
        ref.watch(shareHistoryProvider).valueOrNull ?? const [];
    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final remoteShares =
        ref.watch(remoteSharesProvider).valueOrNull ?? const [];
    final packageInfoAsync = ref.watch(_appPackageInfoProvider);
    final launchSnapshot = buildLaunchDiagnosticsSnapshot(
      queuedActions: queuedActions,
      shareHistory: shareHistory,
      reports: reports,
      remoteShares: remoteShares,
      l10n: context.l10n,
    );
    final recentHistory = diagnostics.recentHistory.reversed
        .take(10)
        .toList(growable: false);
    final hasIssues =
        diagnostics.lastRefreshError != null ||
        diagnostics.subscriptionErrorCount > 0 ||
        diagnostics.unsubscribeFailureCount > 0 ||
        launchSnapshot.hasIssues;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? AppSpacing.md : AppSpacing.xl;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSpacing.md,
        hPad,
        AppSpacing.bottomSafe,
      ),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDiagnosticsCurrentState,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _InlineStatus(
                icon: diagnostics.refreshInFlight
                    ? Icons.sync_rounded
                    : hasIssues
                    ? Icons.warning_amber_rounded
                    : Icons.radar_rounded,
                color: diagnostics.refreshInFlight
                    ? palette.accent
                    : hasIssues
                    ? palette.warning
                    : palette.success,
                title: diagnostics.refreshInFlight
                    ? context.l10n.parentDiagnosticsRefreshInFlight
                    : context.l10n.parentDiagnosticsGeneration(
                        diagnostics.refreshGeneration,
                      ),
                detail: context.l10n.parentDiagnosticsRefreshTriggerDetail(
                  diagnostics.activeRefreshTrigger ??
                      diagnostics.lastRefreshTrigger ??
                      'manual',
                  diagnostics.activeSubscriptions.length,
                  diagnostics.trackedGroupNostrIds.length,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.parentDiagnosticsLastRefresh(
                  _formatTimestamp(context, diagnostics.lastRefreshCompletedAt),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.parentDiagnosticsStats(
                  diagnostics.refreshRequestCount,
                  diagnostics.coalescedRefreshRequestCount,
                  diagnostics.subscriptionErrorCount,
                  diagnostics.unsubscribeFailureCount,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              if (diagnostics.lastRefreshError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.parentDiagnosticsLastError(
                    '${diagnostics.lastRefreshError}',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  FilledButton(
                    onPressed: () async {
                      await HapticFeedback.selectionClick();
                      await onRefreshSubscriptions();
                    },
                    child: Text(
                      context.l10n.parentDiagnosticsRefreshSubscriptions,
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final copiedMessage =
                          context.l10n.parentDiagnosticsCopied;
                      await Clipboard.setData(ClipboardData(text: dump));
                      if (!context.mounted) {
                        return;
                      }
                      await HapticFeedback.lightImpact();
                      messenger.showSnackBar(
                        SnackBar(content: Text(copiedMessage)),
                      );
                    },
                    child: Text(context.l10n.parentDiagnosticsCopyDebugDump),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onRefreshPanel();
                    },
                    child: Text(context.l10n.parentDiagnosticsRefreshPage),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDiagnosticsAppBuild,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              packageInfoAsync.when(
                data: (packageInfo) => _InlineStatus(
                  icon: Icons.info_outline_rounded,
                  color: palette.accent,
                  title: _formatAppVersion(context, packageInfo),
                  detail: packageInfo.packageName.isEmpty
                      ? context.l10n.parentDiagnosticsPackageUnavailable
                      : packageInfo.packageName,
                ),
                loading: () => _InlineStatus(
                  icon: Icons.hourglass_empty_rounded,
                  color: palette.accent,
                  title: context.l10n.parentDiagnosticsReadingBuild,
                  detail: context.l10n.parentDiagnosticsVersionLoading,
                ),
                error: (_, _) => _InlineStatus(
                  icon: Icons.warning_amber_rounded,
                  color: palette.warning,
                  title: context.l10n.parentDiagnosticsBuildUnavailable,
                  detail: context.l10n.parentDiagnosticsBuildUnavailableDetail,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDiagnosticsLaunchTriage,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _InlineStatus(
                icon: launchSnapshot.hasIssues
                    ? Icons.error_outline_rounded
                    : Icons.task_alt_rounded,
                color: launchSnapshot.hasIssues
                    ? palette.warning
                    : palette.success,
                title: launchSnapshot.hasIssues
                    ? context.l10n.parentDiagnosticsLaunchIssuesNeedAttention(
                        launchSnapshot.totalIssueCount,
                      )
                    : context.l10n.parentDiagnosticsNoLaunchIssues,
                detail: launchSnapshot.hasIssues
                    ? context.l10n.parentDiagnosticsLaunchDetail(
                        launchSnapshot.queuedActions.length,
                        launchSnapshot.shareIssues.length,
                        launchSnapshot.reportIssues.length,
                        launchSnapshot.downloadIssues.length,
                      )
                    : context.l10n.parentDiagnosticsClear,
              ),
              if (launchSnapshot.actionsByType.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final count in launchSnapshot.actionsByType)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '${count.label}: ${count.count}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDiagnosticsActiveSubscriptions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (diagnostics.activeSubscriptions.isEmpty)
                Text(
                  context.l10n.parentDiagnosticsNoActiveSubscriptions,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final subscription in diagnostics.activeSubscriptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      subscription.describe(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDiagnosticsDeliveryIssues,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (!launchSnapshot.hasIssues)
                Text(
                  context.l10n.parentDiagnosticsNoRetriesWaiting,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else ...[
                if (launchSnapshot.shareIssues.isNotEmpty) ...[
                  Text(
                    context.l10n.parentDiagnosticsShares,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final entry in launchSnapshot.shareIssues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${entry.title} · ${describeShareStatus(entry.status, context.l10n)}${entry.error == null || entry.error!.isEmpty ? '' : ' · ${entry.error}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
                if (launchSnapshot.reportIssues.isNotEmpty) ...[
                  if (launchSnapshot.shareIssues.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.parentDiagnosticsReportsSection,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final report in launchSnapshot.reportIssues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${describeReportReason(report.reason, context.l10n)} · ${describeReportStatus(report.status, context.l10n)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
                if (launchSnapshot.downloadIssues.isNotEmpty) ...[
                  if (launchSnapshot.shareIssues.isNotEmpty ||
                      launchSnapshot.reportIssues.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.parentDiagnosticsRemoteDownloadsSection,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final share in launchSnapshot.downloadIssues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        '${share.title} · ${summarizeDownloadError(share.downloadError, context.l10n)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDiagnosticsRecentHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (recentHistory.isEmpty)
                Text(
                  context.l10n.parentDiagnosticsNoHistory,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final entry in recentHistory)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      entry.describe(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatTimestamp(BuildContext context, DateTime? value) {
  if (value == null) {
    return context.l10n.parentDiagnosticsNotCompleted;
  }
  return context.l10n.parentDiagnosticsCompleted('${value.toLocal()}');
}

String _formatAppVersion(BuildContext context, PackageInfo packageInfo) {
  final version = packageInfo.version.trim().isEmpty
      ? context.l10n.parentDiagnosticsUnknownVersion
      : packageInfo.version.trim();
  final buildNumber = packageInfo.buildNumber.trim().isEmpty
      ? context.l10n.parentDiagnosticsUnknownBuild
      : packageInfo.buildNumber.trim();
  return context.l10n.parentDiagnosticsVersionBuild(version, buildNumber);
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.xlAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.empty,
            height: AppIconSize.empty,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadii.mdAll,
            ),
            child: Icon(icon, color: color, size: AppIconSize.lg),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

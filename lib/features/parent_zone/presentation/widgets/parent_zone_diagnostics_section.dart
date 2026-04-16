import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/di/providers.dart';
import '../models/launch_diagnostics.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';

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
    final hPad = screenWidth < 600 ? 12.0 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current State',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
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
                    ? 'Refresh in flight'
                    : 'Generation ${diagnostics.refreshGeneration}',
                detail:
                    'Trigger ${diagnostics.activeRefreshTrigger ?? diagnostics.lastRefreshTrigger ?? 'manual'} · ${diagnostics.activeSubscriptions.length} active subscription(s) · ${diagnostics.trackedGroupNostrIds.length} tracked group(s)',
              ),
              const SizedBox(height: 12),
              Text(
                'Last refresh ${_formatTimestamp(diagnostics.lastRefreshCompletedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Requests ${diagnostics.refreshRequestCount} · Coalesced ${diagnostics.coalescedRefreshRequestCount} · Stream errors ${diagnostics.subscriptionErrorCount} · Unsubscribe failures ${diagnostics.unsubscribeFailureCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
              ),
              if (diagnostics.lastRefreshError != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last error: ${diagnostics.lastRefreshError}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.danger),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: () async {
                      await HapticFeedback.selectionClick();
                      await onRefreshSubscriptions();
                    },
                    child: const Text('Refresh subscriptions'),
                  ),
                  FilledButton.tonal(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await Clipboard.setData(ClipboardData(text: dump));
                      if (!context.mounted) {
                        return;
                      }
                      await HapticFeedback.lightImpact();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Copied relay sync diagnostics'),
                        ),
                      );
                    },
                    child: const Text('Copy debug dump'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onRefreshPanel();
                    },
                    child: const Text('Refresh page'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App Build', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              packageInfoAsync.when(
                data: (packageInfo) => _InlineStatus(
                  icon: Icons.info_outline_rounded,
                  color: palette.accent,
                  title: _formatAppVersion(packageInfo),
                  detail: packageInfo.packageName.isEmpty
                      ? 'Package identifier unavailable on this platform.'
                      : packageInfo.packageName,
                ),
                loading: () => _InlineStatus(
                  icon: Icons.hourglass_empty_rounded,
                  color: palette.accent,
                  title: 'Reading app build',
                  detail: 'Version and build number are loading.',
                ),
                error: (_, _) => _InlineStatus(
                  icon: Icons.warning_amber_rounded,
                  color: palette.warning,
                  title: 'App build unavailable',
                  detail:
                      'This platform did not return version and build metadata.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Launch Triage',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _InlineStatus(
                icon: launchSnapshot.hasIssues
                    ? Icons.error_outline_rounded
                    : Icons.task_alt_rounded,
                color: launchSnapshot.hasIssues
                    ? palette.warning
                    : palette.success,
                title: launchSnapshot.hasIssues
                    ? '${launchSnapshot.totalIssueCount} launch issue(s) need attention'
                    : 'No queued launch issues right now',
                detail: launchSnapshot.hasIssues
                    ? '${launchSnapshot.queuedActions.length} queued action(s) · ${launchSnapshot.shareIssues.length} share issue(s) · ${launchSnapshot.reportIssues.length} report issue(s) · ${launchSnapshot.downloadIssues.length} download issue(s)'
                    : 'Shares, reports, and remote downloads look clear from this device.',
              ),
              if (launchSnapshot.actionsByType.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final count in launchSnapshot.actionsByType)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${count.label}: ${count.count}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Subscriptions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (diagnostics.activeSubscriptions.isEmpty)
                Text(
                  'No relay subscriptions are active right now.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final subscription in diagnostics.activeSubscriptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      subscription.describe(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Issues',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (!launchSnapshot.hasIssues)
                Text(
                  'Nothing is waiting for retry from shares, reports, or remote downloads.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else ...[
                if (launchSnapshot.shareIssues.isNotEmpty) ...[
                  Text('Shares', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final entry in launchSnapshot.shareIssues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${entry.title} · ${describeShareStatus(entry.status)}${entry.error == null || entry.error!.isEmpty ? '' : ' · ${entry.error}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
                if (launchSnapshot.reportIssues.isNotEmpty) ...[
                  if (launchSnapshot.shareIssues.isNotEmpty)
                    const SizedBox(height: 8),
                  Text(
                    'Reports',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final report in launchSnapshot.reportIssues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${report.reason} · ${describeReportStatus(report.status)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
                if (launchSnapshot.downloadIssues.isNotEmpty) ...[
                  if (launchSnapshot.shareIssues.isNotEmpty ||
                      launchSnapshot.reportIssues.isNotEmpty)
                    const SizedBox(height: 8),
                  Text(
                    'Remote downloads',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final share in launchSnapshot.downloadIssues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${share.title} · ${summarizeDownloadError(share.downloadError)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent History',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (recentHistory.isEmpty)
                Text(
                  'No control-plane activity captured yet.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final entry in recentHistory)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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

String _formatTimestamp(DateTime? value) {
  if (value == null) {
    return 'has not completed yet';
  }
  return 'completed ${value.toLocal()}';
}

String _formatAppVersion(PackageInfo packageInfo) {
  final version = packageInfo.version.trim().isEmpty
      ? 'unknown version'
      : packageInfo.version.trim();
  final buildNumber = packageInfo.buildNumber.trim().isEmpty
      ? 'unknown build'
      : packageInfo.buildNumber.trim();
  return 'Version $version · Build $buildNumber';
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 4),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

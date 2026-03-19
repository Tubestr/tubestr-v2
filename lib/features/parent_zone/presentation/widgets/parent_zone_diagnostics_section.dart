import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';

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
    final palette = ref.watch(activeThemeProvider).palette;
    ref.watch(syncDiagnosticsRevisionProvider);
    final diagnostics = ref.read(syncCoordinatorProvider).debugSnapshot();
    final dump = ref.read(syncCoordinatorProvider).debugDescribeState();
    final recentHistory = diagnostics.recentHistory.reversed
        .take(10)
        .toList(growable: false);
    final hasIssues =
        diagnostics.lastRefreshError != null ||
        diagnostics.subscriptionErrorCount > 0 ||
        diagnostics.unsubscribeFailureCount > 0;

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
                      await Clipboard.setData(ClipboardData(text: dump));
                      if (!context.mounted) {
                        return;
                      }
                      await HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/share_history_entry.dart';
import '../models/launch_diagnostics.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n.dart';

class ParentZoneActivitySection extends ConsumerWidget {
  const ParentZoneActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final moderationLogs =
        ref.watch(moderationAuditLogsProvider).valueOrNull ?? const [];
    final shareHistory =
        ref.watch(shareHistoryProvider).valueOrNull ?? const [];
    final palette = ref.watch(activePaletteProvider);
    final inboundReports = reports
        .where((report) => !report.isOutbound)
        .toList(growable: false);
    final outboundReports = reports
        .where((report) => report.isOutbound)
        .toList(growable: false);

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
                context.l10n.parentActivityRecentShares,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              if (shareHistory.isEmpty)
                Text(
                  context.l10n.parentActivityEmpty,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final entry in shareHistory.take(5))
                  _ShareHistoryRow(entry: entry),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.parentActivityFamilyFeedback,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (inboundReports.isEmpty)
                      Text(
                        context.l10n.parentActivityNoIncoming,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      )
                    else
                      for (final report in inboundReports.take(4))
                        _InboundReportRow(report: report, palette: palette),
                  ],
                ),
              ),
              FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.parentActivityOutbound,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (outboundReports.isEmpty)
                      Text(
                        context.l10n.parentActivityNoReports,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      )
                    else
                      for (final report in outboundReports.take(5))
                        _OutboundReportRow(report: report, palette: palette),
                  ],
                ),
              ),
              FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.parentActivityModeration,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (moderationLogs.isEmpty)
                      Text(
                        context.l10n.parentActivityNoModeration,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      )
                    else
                      for (final log in moderationLogs.take(4))
                        _ModerationLogRow(log: log, palette: palette),
                  ],
                ),
              ),
            ];

            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              );
            }

            final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShareHistoryRow extends ConsumerWidget {
  const _ShareHistoryRow({required this.entry});

  final ShareHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(activePaletteProvider);
    final color = switch (entry.status) {
      'sent' => palette.success,
      'queued' => palette.warning,
      _ => palette.mutedInk,
    };
    final group = ref
        .watch(mdkGroupSummaryProvider(entry.mlsGroupId))
        .valueOrNull;
    final groupLabel = group?.name ?? 'Family connection';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.send_rounded, size: AppIconSize.md, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${entry.childDisplayName} · ${describeShareStatus(entry.status, context.l10n)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  groupLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                ),
                if (entry.error case final error? when error.isNotEmpty)
                  Text(
                    error,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.warning),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InboundReportRow extends StatelessWidget {
  const _InboundReportRow({required this.report, required this.palette});

  final Report report;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final destinationLabel = _reportDestinationLabel(
      report.recipientType,
      context.l10n,
    );
    final feelingEmoji = switch (report.level) {
      1 => '\u{1F615}',
      2 => '\u{1F628}',
      _ => '\u{1F620}',
    };
    final l10n = context.l10n;
    final helperText = switch (report.level) {
      1 => l10n.parentReportGentle,
      2 => l10n.parentReportConcern,
      _ => switch (report.recipientType) {
        'safety_hq' => l10n.parentReportSafetyHq,
        _ => l10n.parentReportFamily,
      },
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: palette.panel.withValues(alpha: 0.7),
          borderRadius: AppRadii.xlAll,
          border: Border.all(color: palette.panelBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feelingEmoji,
              style: const TextStyle(fontSize: AppIconSize.xl),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    describeReportReason(report.reason, l10n),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$destinationLabel · ${_formatTimestamp(report.createdAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutboundReportRow extends StatelessWidget {
  const _OutboundReportRow({required this.report, required this.palette});

  final Report report;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final destinationLabel = _reportDestinationLabel(
      report.recipientType,
      context.l10n,
    );
    final isLocal = report.recipientType == 'local';
    final isLocalParent = report.recipientType == 'local_parent';
    final statusColor = switch (report.status) {
      'delivered' when isLocal => palette.accentSecondary,
      'delivered' when isLocalParent => palette.warning,
      'delivered' => palette.success,
      'queued_safety' => palette.warning,
      'pending_blob_hash' => palette.warning,
      'failed' => palette.danger,
      _ => palette.mutedInk,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${describeReportReason(report.reason, context.l10n)} · ${context.l10n.reportLevelValue(report.level)} · $destinationLabel',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${describeReportStatus(report.status, context.l10n)} · ${_formatTimestamp(report.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _reportDestinationLabel(String recipientType, AppLocalizations l10n) {
  return switch (recipientType) {
    'local' => l10n.parentDestinationDeviceOnly,
    'local_parent' => l10n.parentDestinationParentOnly,
    'family' => l10n.parentDestinationBothFamilies,
    'group' => l10n.parentDestinationFamilyGroup,
    'parents' => l10n.parentDestinationParentHelpers,
    'safety_hq' => l10n.parentSafetyHq,
    _ => recipientType,
  };
}

String _formatTimestamp(DateTime value) => value.toLocal().toString();

class _ModerationLogRow extends StatelessWidget {
  const _ModerationLogRow({required this.log, required this.palette});

  final ModerationAuditLog log;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (log.actionType) {
      'remove_member' => l10n.parentAuditRemoveMember,
      'delete_video' => l10n.parentAuditDeleteVideo,
      _ => log.actionType,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  log.createdAt.toLocal().toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/share_history_entry.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';

class ParentZoneActivitySection extends ConsumerWidget {
  const ParentZoneActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final moderationLogs =
        ref.watch(moderationAuditLogsProvider).valueOrNull ?? const [];
    final shareHistory =
        ref.watch(shareHistoryProvider).valueOrNull ?? const [];
    final palette = ref.watch(activeThemeProvider).palette;
    final inboundReports = reports
        .where((report) => !report.isOutbound)
        .toList(growable: false);
    final outboundReports = reports
        .where((report) => report.isOutbound)
        .toList(growable: false);

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
                'Recent Shares',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (shareHistory.isEmpty)
                Text(
                  'When you share with another family, the latest deliveries will appear here.',
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
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Family Feedback',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (inboundReports.isEmpty)
                      Text(
                        'No incoming family feedback right now.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      )
                    else
                      for (final report in inboundReports.take(4))
                        _InboundReportRow(report: report),
                  ],
                ),
              ),
              FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feedback You Shared',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (outboundReports.isEmpty)
                      Text(
                        'No reports yet. If a child flags a video, you will see delivery status here.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      )
                    else
                      for (final report in outboundReports.take(5))
                        _OutboundReportRow(report: report),
                  ],
                ),
              ),
              FrostCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moderation Activity',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (moderationLogs.isEmpty)
                      Text(
                        'No moderation actions yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      )
                    else
                      for (final log in moderationLogs.take(4))
                        _ModerationLogRow(log: log),
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
                    if (i != cards.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            }

            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
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
    final color = switch (entry.status) {
      'sent' => Colors.green,
      'queued' => Colors.orange,
      _ => Colors.blueGrey,
    };
    final group = ref
        .watch(mdkGroupSummaryProvider(entry.mlsGroupId))
        .valueOrNull;
    final groupLabel = group?.name ?? 'Family connection';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.send_rounded, size: 18, color: color),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  '${entry.childDisplayName} · ${entry.status}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  groupLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                if (entry.error case final error? when error.isNotEmpty)
                  Text(
                    error,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade800,
                    ),
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
  const _InboundReportRow({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final feelingEmoji = switch (report.level) {
      1 => '\u{1F615}',
      2 => '\u{1F628}',
      _ => '\u{1F620}',
    };
    final helperText = switch (report.level) {
      1 => 'Another family shared gentle feedback.',
      2 => 'A parent-level concern needs a quick check-in.',
      _ => 'A serious concern was escalated to Safety HQ.',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(feelingEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.reason,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${report.recipientType} · ${report.createdAt.toLocal()}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
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
  const _OutboundReportRow({required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (report.status) {
      'delivered' => Colors.green,
      'queued_safety' => Colors.orange,
      'pending_blob_hash' => Colors.amber,
      'failed' => Colors.red,
      _ => Colors.blueGrey,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.reason} · level ${report.level}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${report.status} · ${report.createdAt.toLocal()}',
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

class _ModerationLogRow extends StatelessWidget {
  const _ModerationLogRow({required this.log});

  final ModerationAuditLog log;

  @override
  Widget build(BuildContext context) {
    final label = switch (log.actionType) {
      'remove_member' => 'Removed a family member',
      'delete_video' => 'Deleted shared video',
      _ => log.actionType,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gavel_rounded, size: 18),
          const SizedBox(width: 10),
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
                const SizedBox(height: 2),
                Text(
                  log.createdAt.toLocal().toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/share_history_entry.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../models/parent_zone_models.dart';

class ParentZoneOverviewSection extends ConsumerWidget {
  const ParentZoneOverviewSection({super.key, required this.onSelectSection});

  final ValueChanged<ParentZoneSection> onSelectSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final moderationLogs =
        ref.watch(moderationAuditLogsProvider).valueOrNull ?? const [];
    final pendingVideos =
        ref.watch(pendingApprovalVideosProvider).valueOrNull ?? const [];
    final queuedActions =
        ref.watch(offlineActionsProvider).valueOrNull ?? const [];
    final shareHistory =
        ref.watch(shareHistoryProvider).valueOrNull ?? const [];
    final safetyStatus = ref.watch(safetyHqStatusProvider).valueOrNull;
    final palette = ref.watch(activeThemeProvider).palette;
    final pendingReports = reports
        .where((report) => report.status != 'delivered')
        .length;
    final inboundReports = reports
        .where((report) => !report.isOutbound)
        .toList(growable: false);
    final outboundReports = reports
        .where((report) => report.isOutbound)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                icon: identity != null
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: identity != null ? palette.success : palette.warning,
                label: 'Parent key',
                value: identity != null ? 'Ready' : 'Not set',
              ),
              _SummaryRow(
                icon: Icons.people_rounded,
                color: palette.accent,
                label: 'Child profiles',
                value: '${profiles.length}',
              ),
              _SummaryRow(
                icon: safetyStatus?.isJoined == true
                    ? Icons.shield_rounded
                    : Icons.shield_outlined,
                color: safetyStatus?.isJoined == true
                    ? palette.success
                    : palette.warning,
                label: 'Safety HQ',
                value: safetyStatus?.label ?? 'Loading',
              ),
              _SummaryRow(
                icon: pendingVideos.isEmpty
                    ? Icons.verified_rounded
                    : Icons.pending_actions_rounded,
                color: pendingVideos.isEmpty
                    ? palette.success
                    : palette.warning,
                label: 'Approval queue',
                value: '${pendingVideos.length}',
              ),
              _SummaryRow(
                icon: pendingReports == 0
                    ? Icons.mark_email_read_rounded
                    : Icons.mark_email_unread_rounded,
                color: pendingReports == 0 ? palette.success : palette.warning,
                label: 'Pending reports',
                value: '$pendingReports',
              ),
              _SummaryRow(
                icon: queuedActions.isEmpty
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_off_rounded,
                color: queuedActions.isEmpty
                    ? palette.success
                    : palette.warning,
                label: 'Offline queue',
                value: '${queuedActions.length}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                  'When you share with another family, the history will show up here.',
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
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => onSelectSection(ParentZoneSection.family),
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Child'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        onSelectSection(ParentZoneSection.connections),
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('New Connection'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Let\'s Talk',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (inboundReports.isEmpty)
                Text(
                  'No incoming family feedback right now.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final report in inboundReports.take(4))
                  _InboundReportRow(report: report),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                  'No reports yet. If a child flags a video, you will see the delivery status here.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final report in outboundReports.take(5))
                  _OutboundReportRow(report: report),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                )
              else
                for (final log in moderationLogs.take(4))
                  _ModerationLogRow(log: log),
            ],
          ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      1 => '😕',
      2 => '😨',
      _ => '😠',
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

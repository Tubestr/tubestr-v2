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
    final groupSummaries =
        ref.watch(mdkGroupSummariesProvider).valueOrNull ?? const [];
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
    final attentionCount =
        pendingVideos.length + pendingReports + queuedActions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        _OverviewHero(
          palette: palette,
          attentionCount: attentionCount,
          childCount: profiles.length,
          familySpaceCount: groupSummaries.length,
          pendingVideos: pendingVideos.length,
          pendingReports: pendingReports,
          queuedActions: queuedActions.length,
          onOpenFamily: () => onSelectSection(ParentZoneSection.family),
          onOpenSettings: () => onSelectSection(ParentZoneSection.settings),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final familyHealth = FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Family Health',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _SummaryRow(
                    icon: identity != null
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: identity != null ? palette.success : palette.warning,
                    label: 'Parent account',
                    value: identity != null ? 'Ready' : 'Not set',
                  ),
                  _SummaryRow(
                    icon: Icons.people_rounded,
                    color: palette.accent,
                    label: 'Child profiles',
                    value: '${profiles.length}',
                  ),
                  _SummaryRow(
                    icon: Icons.link_rounded,
                    color:
                        groupSummaries.isEmpty ? palette.warning : palette.success,
                    label: 'Family spaces',
                    value: '${groupSummaries.length}',
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
                ],
              ),
            );

            final quickActions = FrostCard(
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
                        onPressed: () =>
                            onSelectSection(ParentZoneSection.family),
                        icon: const Icon(Icons.person_add_rounded, size: 18),
                        label: const Text('Add Child'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            onSelectSection(ParentZoneSection.connections),
                        icon: const Icon(Icons.link_rounded, size: 18),
                        label: const Text('Manage Connections'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            onSelectSection(ParentZoneSection.settings),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Open Settings'),
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: familyHealth),
                  const SizedBox(width: 12),
                  Expanded(flex: 5, child: quickActions),
                ],
              );
            }

            return Column(
              children: [
                familyHealth,
                const SizedBox(height: 12),
                quickActions,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
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

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.palette,
    required this.attentionCount,
    required this.childCount,
    required this.familySpaceCount,
    required this.pendingVideos,
    required this.pendingReports,
    required this.queuedActions,
    required this.onOpenFamily,
    required this.onOpenSettings,
  });

  final KidPalette palette;
  final int attentionCount;
  final int childCount;
  final int familySpaceCount;
  final int pendingVideos;
  final int pendingReports;
  final int queuedActions;
  final VoidCallback onOpenFamily;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Control Room', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          attentionCount == 0
              ? 'Everything looks steady. Review your family spaces or jump into settings when you need them.'
              : 'Start here with the decisions that need a parent now, then move into connection and safety health.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ControlMetric(
              label: 'Needs review',
              value: '$attentionCount',
              tone: attentionCount == 0 ? palette.success : palette.warning,
            ),
            _ControlMetric(
              label: 'Children',
              value: '$childCount',
              tone: palette.ink,
            ),
            _ControlMetric(
              label: 'Family spaces',
              value: '$familySpaceCount',
              tone: palette.accent,
            ),
          ],
        ),
      ],
    );

    final startHere = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start Here',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (attentionCount == 0)
            _AttentionRow(
              icon: Icons.verified_rounded,
              color: palette.success,
              title: 'Everything is clear',
              detail:
                  'No waiting approvals, pending reports, or offline retries right now.',
            )
          else ...[
            _AttentionRow(
              icon: pendingVideos == 0
                  ? Icons.verified_rounded
                  : Icons.pending_actions_rounded,
              color: pendingVideos == 0 ? palette.success : palette.warning,
              title: pendingVideos == 0
                  ? 'Approval queue is clear'
                  : '$pendingVideos clip(s) need review',
              detail: pendingVideos == 0
                  ? 'New kid clips can move ahead without a parent check right now.'
                  : 'Open Family to approve or reject new clips before they can be shared.',
              actionLabel: pendingVideos == 0 ? null : 'Open Family',
              onTap: pendingVideos == 0 ? null : onOpenFamily,
            ),
            _AttentionRow(
              icon: pendingReports == 0
                  ? Icons.mark_email_read_rounded
                  : Icons.mark_email_unread_rounded,
              color: pendingReports == 0 ? palette.success : palette.warning,
              title: pendingReports == 0
                  ? 'Reports are up to date'
                  : '$pendingReports report(s) still syncing',
              detail: pendingReports == 0
                  ? 'Family feedback and safety reports have finished sending.'
                  : 'Keep an eye on delivery and safety follow-up before leaving the control room.',
            ),
            _AttentionRow(
              icon: queuedActions == 0
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: queuedActions == 0 ? palette.success : palette.warning,
              title: queuedActions == 0
                  ? 'Connection health looks good'
                  : '$queuedActions action(s) are waiting offline',
              detail: queuedActions == 0
                  ? 'Shares, reports, and relay activity are connected.'
                  : 'Open Settings to retry queued work and reconnect relays if needed.',
              actionLabel: queuedActions == 0 ? null : 'Open Settings',
              onTap: queuedActions == 0 ? null : onOpenSettings,
            ),
          ],
        ],
      ),
    );

    return FrostCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: overview),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: startHere),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              overview,
              const SizedBox(height: 16),
              startHere,
            ],
          );
        },
      ),
    );
  }
}

class _ControlMetric extends StatelessWidget {
  const _ControlMetric({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
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
                const SizedBox(height: 3),
                Text(detail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(width: 10),
            OutlinedButton(onPressed: onTap, child: Text(actionLabel!)),
          ],
        ],
      ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  Text(helperText, style: Theme.of(context).textTheme.bodySmall),
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
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
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

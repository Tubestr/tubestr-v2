import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../models/parent_zone_models.dart';

class ParentZoneDashboardSection extends ConsumerWidget {
  const ParentZoneDashboardSection({
    super.key,
    required this.onSelectSection,
  });

  final ValueChanged<ParentZoneSection> onSelectSection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final reports = ref.watch(reportsProvider).valueOrNull ?? const [];
    final pendingVideos =
        ref.watch(pendingApprovalVideosProvider).valueOrNull ?? const [];
    final queuedActions =
        ref.watch(offlineActionsProvider).valueOrNull ?? const [];
    final groupSummaries =
        ref.watch(mdkGroupSummariesProvider).valueOrNull ?? const [];
    final safetyStatus = ref.watch(safetyHqStatusProvider).valueOrNull;
    final palette = ref.watch(activeThemeProvider).palette;
    final pendingReports = reports
        .where((report) => report.status != 'delivered')
        .length;
    final attentionCount =
        pendingVideos.length + pendingReports + queuedActions.length;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? 12.0 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 100),
      children: [
        _OverviewHero(
          palette: palette,
          attentionCount: attentionCount,
          childCount: profiles.length,
          familySpaceCount: groupSummaries.length,
          pendingVideos: pendingVideos.length,
          pendingReports: pendingReports,
          queuedActions: queuedActions.length,
          onOpenChildren: () =>
              onSelectSection(ParentZoneSection.children),
          onOpenNetwork: () =>
              onSelectSection(ParentZoneSection.network),
        ),
        const SizedBox(height: 16),
        FrostCard(
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
                color: identity != null
                    ? palette.success
                    : palette.warning,
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
                color: groupSummaries.isEmpty
                    ? palette.warning
                    : palette.success,
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
    required this.onOpenChildren,
    required this.onOpenNetwork,
  });

  final KidPalette palette;
  final int attentionCount;
  final int childCount;
  final int familySpaceCount;
  final int pendingVideos;
  final int pendingReports;
  final int queuedActions;
  final VoidCallback onOpenChildren;
  final VoidCallback onOpenNetwork;

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
                  : 'Open Children to approve or reject new clips before they can be shared.',
              actionLabel: pendingVideos == 0 ? null : 'Open Children',
              onTap: pendingVideos == 0 ? null : onOpenChildren,
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
                  : 'Open Network to retry queued work and reconnect relays if needed.',
              actionLabel: queuedActions == 0 ? null : 'Open Network',
              onTap: queuedActions == 0 ? null : onOpenNetwork,
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
            children: [overview, const SizedBox(height: 16), startHere],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tone,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
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
                if (actionLabel != null && onTap != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onTap!();
                    },
                    child: Text(actionLabel!),
                  ),
                ],
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

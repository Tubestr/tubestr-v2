import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../models/parent_zone_models.dart';
import '../../../../l10n/l10n.dart';

class ParentZoneDashboardSection extends ConsumerWidget {
  const ParentZoneDashboardSection({super.key, required this.onSelectSection});

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
    final palette = ref.watch(activePaletteProvider);
    final pendingReports = reports
        .where((report) => report.status != 'delivered')
        .length;
    final attentionCount =
        pendingVideos.length + pendingReports + queuedActions.length;
    final safetyHqName = AppConstants.safetyHqGroupName.toLowerCase();
    final nonSafetyFamilySpaces = groupSummaries
        .where((group) => group.name.trim().toLowerCase() != safetyHqName)
        .length;
    final needsFamilySpace = nonSafetyFamilySpaces == 0;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? 12.0 : 20.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        hPad,
        AppSpacing.md,
        hPad,
        AppSpacing.bottomSafe,
      ),
      children: [
        _StartHereCard(
          palette: palette,
          attentionCount: attentionCount,
          pendingVideos: pendingVideos.length,
          pendingReports: pendingReports,
          queuedActions: queuedActions.length,
          needsFamilySpace: needsFamilySpace,
          onOpenChildren: () => onSelectSection(ParentZoneSection.children),
          onOpenNetwork: () => onSelectSection(ParentZoneSection.network),
          onOpenFamilySpaces: () =>
              onSelectSection(ParentZoneSection.familySpaces),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ControlRoomCard(
          palette: palette,
          attentionCount: attentionCount,
          childCount: profiles.length,
          familySpaceCount: groupSummaries.length,
          needsFamilySpace: needsFamilySpace,
        ),
        const SizedBox(height: AppSpacing.lg),
        FrostCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.parentDashboardFamilyHealth,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              _SummaryRow(
                icon: identity != null
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                color: identity != null ? palette.success : palette.warning,
                label: context.l10n.onboardingParentAccount,
                value: identity != null
                    ? context.l10n.parentDashboardReady
                    : context.l10n.parentDashboardNotSet,
              ),
              _SummaryRow(
                icon: Icons.people_rounded,
                color: palette.accent,
                label: context.l10n.onboardingChildProfiles,
                value: '${profiles.length}',
              ),
              _SummaryRow(
                icon: Icons.link_rounded,
                color: groupSummaries.isEmpty
                    ? palette.warning
                    : palette.success,
                label: context.l10n.parentDashboardFamilySpaces,
                value: '${groupSummaries.length}',
              ),
              _SummaryRow(
                icon: safetyStatus?.isJoined == true
                    ? Icons.shield_rounded
                    : Icons.shield_outlined,
                color: safetyStatus?.isJoined == true
                    ? palette.success
                    : palette.warning,
                label: context.l10n.parentSafetyHq,
                value:
                    safetyStatus?.label ?? context.l10n.parentDashboardLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StartHereCard extends StatelessWidget {
  const _StartHereCard({
    required this.palette,
    required this.attentionCount,
    required this.pendingVideos,
    required this.pendingReports,
    required this.queuedActions,
    required this.needsFamilySpace,
    required this.onOpenChildren,
    required this.onOpenNetwork,
    required this.onOpenFamilySpaces,
  });

  final KidPalette palette;
  final int attentionCount;
  final int pendingVideos;
  final int pendingReports;
  final int queuedActions;
  final bool needsFamilySpace;
  final VoidCallback onOpenChildren;
  final VoidCallback onOpenNetwork;
  final VoidCallback onOpenFamilySpaces;

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.parentStartHere,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (needsFamilySpace)
            _AttentionRow(
              icon: Icons.group_add_rounded,
              color: palette.warning,
              title: context.l10n.parentDashboardJoinCreate,
              detail: context.l10n.parentDashboardNoFamilySpaceDetail,
              actionLabel: context.l10n.parentDashboardOpenFamilySpaces,
              onTap: onOpenFamilySpaces,
            ),
          if (attentionCount == 0 && !needsFamilySpace)
            _AttentionRow(
              icon: Icons.verified_rounded,
              color: palette.success,
              title: context.l10n.parentDashboardClear,
              detail: context.l10n.parentDashboardAllClearDetail,
            )
          else if (attentionCount > 0) ...[
            _AttentionRow(
              icon: pendingVideos == 0
                  ? Icons.verified_rounded
                  : Icons.pending_actions_rounded,
              color: pendingVideos == 0 ? palette.success : palette.warning,
              title: pendingVideos == 0
                  ? context.l10n.parentDashboardApprovalsClear
                  : context.l10n.parentDashboardClipsNeedReview(pendingVideos),
              detail: pendingVideos == 0
                  ? context.l10n.parentDashboardApprovalsClearDetail
                  : context.l10n.parentDashboardApprovalsPendingDetail,
              actionLabel: pendingVideos == 0
                  ? null
                  : context.l10n.parentDashboardOpenChildren,
              onTap: pendingVideos == 0 ? null : onOpenChildren,
            ),
            _AttentionRow(
              icon: pendingReports == 0
                  ? Icons.mark_email_read_rounded
                  : Icons.mark_email_unread_rounded,
              color: pendingReports == 0 ? palette.success : palette.warning,
              title: pendingReports == 0
                  ? context.l10n.parentDashboardReportsUpToDate
                  : context.l10n.parentDashboardReportsNeedAttention(
                      pendingReports,
                    ),
              detail: pendingReports == 0
                  ? context.l10n.parentDashboardReportsUpToDateDetail
                  : context.l10n.parentDashboardReportsPendingDetail,
            ),
            _AttentionRow(
              icon: queuedActions == 0
                  ? Icons.cloud_done_rounded
                  : Icons.cloud_off_rounded,
              color: queuedActions == 0 ? palette.success : palette.warning,
              title: queuedActions == 0
                  ? context.l10n.parentDashboardConnectionHealthy
                  : context.l10n.parentDashboardActionsWaiting(queuedActions),
              detail: queuedActions == 0
                  ? context.l10n.parentDashboardConnectionHealthyDetail
                  : context.l10n.parentDashboardConnectionPendingDetail,
              actionLabel: queuedActions == 0
                  ? null
                  : context.l10n.parentDashboardOpenNetwork,
              onTap: queuedActions == 0 ? null : onOpenNetwork,
            ),
          ],
        ],
      ),
    );
  }
}

class _ControlRoomCard extends StatelessWidget {
  const _ControlRoomCard({
    required this.palette,
    required this.attentionCount,
    required this.childCount,
    required this.familySpaceCount,
    required this.needsFamilySpace,
  });

  final KidPalette palette;
  final int attentionCount;
  final int childCount;
  final int familySpaceCount;
  final bool needsFamilySpace;

  @override
  Widget build(BuildContext context) {
    return FrostCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.parentControlRoom,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            needsFamilySpace
                ? context.l10n.parentDashboardControlRoomFirstStep
                : attentionCount == 0
                ? context.l10n.parentDashboardControlRoomSteady
                : context.l10n.parentDashboardControlRoomExplainer,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _ControlMetric(
                label: context.l10n.parentDashboardNeedsReview,
                value: '$attentionCount',
                tone: attentionCount == 0 ? palette.success : palette.warning,
              ),
              _ControlMetric(
                label: context.l10n.parentSectionChildren,
                value: '$childCount',
                tone: palette.ink,
              ),
              _ControlMetric(
                label: context.l10n.parentDashboardFamilySpaces,
                value: '$familySpaceCount',
                tone: palette.accent,
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: AppRadii.lgAll,
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
          const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadii.mdAll,
            ),
            child: Icon(icon, size: AppIconSize.lg, color: color),
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
                if (actionLabel != null && onTap != null) ...[
                  const SizedBox(height: AppSpacing.sm),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: color),
          const SizedBox(width: AppSpacing.md),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

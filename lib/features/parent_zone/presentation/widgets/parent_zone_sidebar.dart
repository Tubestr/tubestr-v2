import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../models/parent_zone_models.dart';
import '../../../../l10n/app_localizations_x.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared_ui/motion/app_motion.dart';

class ParentZoneSidebar extends StatelessWidget {
  const ParentZoneSidebar({
    super.key,
    required this.palette,
    required this.parentLabel,
    required this.accountHint,
    required this.selected,
    required this.onSelect,
  });

  final KidPalette palette;
  final String parentLabel;
  final String accountHint;
  final ParentZoneSection selected;
  final ValueChanged<ParentZoneSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final headerColor = Color.alphaBlend(
      palette.accent.withValues(alpha: 0.06),
      palette.panel,
    );
    return Material(
      color: palette.backgroundTop,
      elevation: 12,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              MediaQuery.of(context).padding.top + AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: headerColor,
              border: Border(bottom: BorderSide(color: palette.panelBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.ink.withValues(alpha: 0.08),
                    borderRadius: AppRadii.lgAll,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: AppIconSize.xl,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.parentZoneTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: palette.ink,
                    fontSize: AppTextSize.title,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  parentLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  accountHint,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: palette.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (final section in ParentZoneSection.values)
                  _NavItem(
                    section: section,
                    isActive: section == selected,
                    palette: palette,
                    onTap: () => onSelect(section),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: Text(
              '${AppConstants.appName} v2.0',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: palette.mutedInk),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.isActive,
    required this.palette,
    required this.onTap,
  });

  final ParentZoneSection section;
  final bool isActive;
  final KidPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.stateChange),
        curve: AppMotion.easeOutQuint,
        child: Material(
          color: isActive
              ? palette.ink.withValues(alpha: 0.08)
              : palette.panel.withValues(alpha: 0),
          borderRadius: AppRadii.lgAll,
          child: InkWell(
            borderRadius: AppRadii.lgAll,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: AppMotion.duration(
                      context,
                      AppMotion.stateChange,
                    ),
                    curve: AppMotion.easeOutQuint,
                    scale: isActive ? 1.05 : 1,
                    child: Icon(
                      section.icon,
                      size: AppIconSize.lg,
                      color: isActive ? palette.ink : palette.mutedInk,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  AnimatedDefaultTextStyle(
                    duration: AppMotion.duration(
                      context,
                      AppMotion.stateChange,
                    ),
                    curve: AppMotion.easeOutQuint,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: palette.ink,
                    ),
                    child: Text(context.l10n.parentZoneSectionLabel(section)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

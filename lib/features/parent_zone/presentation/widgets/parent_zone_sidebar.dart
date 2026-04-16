import 'package:flutter/material.dart';

import '../../../../core/constants.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../models/parent_zone_models.dart';

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
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              20,
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 24,
                    color: palette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Parent Zone',
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  parentLabel,
                  style: TextStyle(
                    color: palette.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  accountHint,
                  style: TextStyle(
                    color: palette.mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              '${AppConstants.appName} v2.0',
              style: TextStyle(fontSize: 12, color: palette.mutedInk),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Material(
          color: isActive
              ? palette.ink.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: isActive ? 1.05 : 1,
                    child: Icon(
                      section.icon,
                      size: 20,
                      color: isActive ? palette.ink : palette.mutedInk,
                    ),
                  ),
                  const SizedBox(width: 14),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: palette.ink,
                    ),
                    child: Text(section.label),
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

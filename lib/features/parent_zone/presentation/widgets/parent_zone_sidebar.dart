import 'package:flutter/material.dart';

import '../../../../core/theme/theme_descriptor.dart';
import '../models/parent_zone_models.dart';

class ParentZoneSidebar extends StatelessWidget {
  const ParentZoneSidebar({
    super.key,
    required this.palette,
    required this.parentNpub,
    required this.selected,
    required this.onSelect,
  });

  final KidPalette palette;
  final String parentNpub;
  final ParentZoneSection selected;
  final ValueChanged<ParentZoneSection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
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
              gradient: LinearGradient(
                colors: [palette.accent, palette.accentSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_rounded, size: 32, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Parent Zone',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (parentNpub.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    parentNpub.length > 20
                        ? '${parentNpub.substring(0, 20)}…'
                        : parentNpub,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
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
              'Nook v2.0',
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive
            ? palette.accent.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  section.icon,
                  size: 20,
                  color: isActive ? palette.accent : palette.mutedInk,
                ),
                const SizedBox(width: 14),
                Text(
                  section.label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? palette.accent : palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

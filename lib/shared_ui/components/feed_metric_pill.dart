import 'package:flutter/material.dart';

import '../../core/theme/radii.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/theme_descriptor.dart';

/// Small pill used in feed tiles to surface metrics like like counts or
/// emoji reaction counts.
class FeedMetricPill extends StatelessWidget {
  const FeedMetricPill({
    super.key,
    required this.palette,
    required this.label,
    this.icon,
    this.iconColor,
  });

  final KidPalette palette;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: palette.surfaceSubtle,
        borderRadius: AppRadii.pillAll,
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppIconSize.xs,
              color: iconColor ?? palette.accent,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

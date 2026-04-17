import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: iconColor ?? palette.accent),
            const SizedBox(width: 4),
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

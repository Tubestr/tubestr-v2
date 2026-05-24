import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';

class FrostedCircleButton extends StatelessWidget {
  const FrostedCircleButton({
    super.key,
    required this.palette,
    required this.child,
    this.onTap,
  });

  final KidPalette palette;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadii.xxlAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.mediaSurface,
              shape: BoxShape.circle,
              border: Border.all(color: palette.mediaBorder),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class FrostedPillButton extends StatelessWidget {
  const FrostedPillButton({
    super.key,
    required this.palette,
    required this.icon,
    required this.label,
    this.onTap,
    this.accentGradient,
  });

  final KidPalette palette;
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Gradient? accentGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadii.xxlAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: accentGradient,
              color: accentGradient == null ? palette.mediaSurface : null,
              borderRadius: AppRadii.xxlAll,
              border: Border.all(color: palette.mediaBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: palette.mediaInk,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTextSize.body,
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

// ── Side Toolbar ────────────────────────────────────────────────────────

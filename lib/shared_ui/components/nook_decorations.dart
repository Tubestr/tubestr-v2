import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/theme_descriptor.dart';

/// Themed background with animated breathing blobs.
/// Meant to fill the area behind content via Stack.
class NookAppBackground extends StatefulWidget {
  const NookAppBackground({super.key, required this.palette});

  final KidPalette palette;

  @override
  State<NookAppBackground> createState() => _NookAppBackgroundState();
}

class _NookAppBackgroundState extends State<NookAppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.backgroundTop, p.backgroundBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SizedBox.expand(
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -40,
                    child: Transform.scale(
                      scale: 1.0 + 0.08 * sin(t * pi * 2),
                      child: _RadialBlob(color: p.accent, size: 260),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -50,
                    child: Transform.scale(
                      scale: 1.0 + 0.1 * sin(t * pi * 2 + 1.5),
                      child: _RadialBlob(color: p.accentSecondary, size: 300),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.sizeOf(context).height * 0.4,
                    left: MediaQuery.sizeOf(context).width * 0.25,
                    child: Transform.scale(
                      scale: 1.0 + 0.06 * cos(t * pi * 2 + 0.8),
                      child: _RadialBlob(color: p.accent, size: 200),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadialBlob extends StatelessWidget {
  const _RadialBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps a child with a soft glow shadow (accent-coloured halo).
class GlowBox extends StatelessWidget {
  const GlowBox({
    super.key,
    required this.child,
    required this.color,
    this.blurRadius = 20,
  });

  final Widget child;
  final Color color;
  final double blurRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: blurRadius,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: blurRadius * 2,
            spreadRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}

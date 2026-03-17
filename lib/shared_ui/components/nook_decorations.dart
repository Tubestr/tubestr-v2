import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/theme_descriptor.dart';

/// Themed background with per-personality animated blobs.
/// Meant to fill the area behind content via Stack.
class NookAppBackground extends StatefulWidget {
  const NookAppBackground({
    super.key,
    required this.palette,
    required this.theme,
  });

  final KidPalette palette;
  final ThemeDescriptor theme;

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
      duration: _durationForTheme(widget.theme),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(NookAppBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _anim.duration = _durationForTheme(widget.theme);
      _anim.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  static Duration _durationForTheme(ThemeDescriptor theme) => switch (theme) {
        ThemeDescriptor.campfire => const Duration(seconds: 6),
        ThemeDescriptor.treehouse => const Duration(seconds: 10),
        ThemeDescriptor.blanketFort => const Duration(seconds: 18),
        // Starlight uses a short base cycle; individual blobs phase-offset from it.
        ThemeDescriptor.starlight => const Duration(seconds: 4),
      };

  List<Widget> _buildBlobs(double t, Size size) {
    final p = widget.palette;
    return switch (widget.theme) {
      ThemeDescriptor.campfire => _campfireBlobs(t, size, p),
      ThemeDescriptor.treehouse => _treehouseBlobs(t, size, p),
      ThemeDescriptor.blanketFort => _blanketFortBlobs(t, size, p),
      ThemeDescriptor.starlight => _starlightBlobs(t, size, p),
    };
  }

  // ---------------------------------------------------------------------------
  // Campfire — asymmetric flicker using two overlapping sine waves
  // ---------------------------------------------------------------------------
  List<Widget> _campfireBlobs(double t, Size size, KidPalette p) {
    // Flicker = primary sine + weaker higher-frequency sine at a phase offset.
    double flicker(double phase) {
      return 1.0 +
          0.10 * sin(t * pi * 2 + phase) +
          0.05 * sin(t * pi * 5.3 + phase + 1.1);
    }

    // Opacity also flickers slightly.
    double opacity(double phase) {
      return 0.08 + 0.06 * sin(t * pi * 3.7 + phase).abs();
    }

    return [
      // Top-left warm blob
      Positioned(
        top: -80,
        left: -60,
        child: Transform.scale(
          scale: flicker(0.0),
          child: _RadialBlob(
            color: p.accent.withValues(alpha: opacity(0.0)),
            size: 300,
          ),
        ),
      ),
      // Bottom-right secondary warmth
      Positioned(
        bottom: -60,
        right: -50,
        child: Transform.scale(
          scale: flicker(2.1),
          child: _RadialBlob(
            color: p.accentSecondary.withValues(alpha: opacity(2.1)),
            size: 260,
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Treehouse — gentle pendulum sway + subtle rotation
  // ---------------------------------------------------------------------------
  List<Widget> _treehouseBlobs(double t, Size size, KidPalette p) {
    // Horizontal displacement: ±30 px
    final swayX = 30.0 * sin(t * pi * 2);
    // Rotation: ±0.04 rad (~2.3°)
    final rotation = 0.04 * sin(t * pi * 2);

    return [
      // Center-left — accent (brown)
      Positioned(
        top: size.height * 0.25,
        left: size.width * 0.05,
        child: Transform.translate(
          offset: Offset(swayX, 0),
          child: Transform.rotate(
            angle: rotation,
            child: _RadialBlob(color: p.accent, size: 280),
          ),
        ),
      ),
      // Center-right — secondary (green), counter-sway for visual depth
      Positioned(
        top: size.height * 0.35,
        right: size.width * 0.05,
        child: Transform.translate(
          offset: Offset(-swayX, 0),
          child: Transform.rotate(
            angle: -rotation,
            child: _RadialBlob(color: p.accentSecondary, size: 320),
          ),
        ),
      ),
      // Small top leaf accent
      Positioned(
        top: -40,
        left: size.width * 0.40,
        child: Transform.translate(
          offset: Offset(swayX * 0.5, 0),
          child: Transform.rotate(
            angle: rotation * 1.5,
            child: _RadialBlob(color: p.accentSecondary, size: 160),
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Blanket Fort — slow, large, very soft breath
  // ---------------------------------------------------------------------------
  List<Widget> _blanketFortBlobs(double t, Size size, KidPalette p) {
    final breathe = 1.0 + 0.06 * sin(t * pi * 2);
    final breatheB = 1.0 + 0.05 * cos(t * pi * 2 + 0.7);

    return [
      // Large centered primary
      Positioned(
        top: size.height * 0.15,
        left: size.width * 0.10,
        child: Transform.scale(
          scale: breathe,
          child: _RadialBlob(
            color: p.accent.withValues(alpha: 0.08),
            size: 420,
          ),
        ),
      ),
      // Overlapping secondary — slightly offset, counter-phase
      Positioned(
        top: size.height * 0.30,
        left: size.width * 0.20,
        child: Transform.scale(
          scale: breatheB,
          child: _RadialBlob(
            color: p.accentSecondary.withValues(alpha: 0.07),
            size: 380,
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Starlight — 6 small blobs with staggered independent twinkle phases
  // ---------------------------------------------------------------------------
  List<Widget> _starlightBlobs(double t, Size size, KidPalette p) {
    // Each blob has a fixed screen position and a phase offset so they
    // twinkle independently. t loops 0→1 over 4 s (the controller duration).
    // Opacity pulses between near-zero and a peak; scale breathes gently.

    const configs = [
      // (left%, top%, phase, colorIsAccent, sizePx)
      (0.05, 0.08, 0.0, true, 140.0),
      (0.65, 0.04, 0.67, false, 110.0),
      (0.30, 0.22, 1.34, true, 90.0),
      (0.80, 0.45, 2.01, false, 130.0),
      (0.15, 0.60, 2.68, true, 100.0),
      (0.55, 0.75, 3.35, false, 120.0),
    ];

    return [
      for (final (lx, ty, phase, isAccent, sz) in configs)
        Positioned(
          left: size.width * lx,
          top: size.height * ty,
          child: Builder(builder: (context) {
            final angle = (t * pi * 2 + phase) % (pi * 2);
            final opacityVal = 0.03 + 0.11 * ((sin(angle) + 1) / 2);
            final scaleVal = 1.0 + 0.12 * sin(angle);
            final color = isAccent ? p.accent : p.accentSecondary;
            return Transform.scale(
              scale: scaleVal,
              child: _RadialBlob(
                color: color.withValues(alpha: opacityVal),
                size: sz,
              ),
            );
          }),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          final size = MediaQuery.sizeOf(context);
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.backgroundTop, p.backgroundBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SizedBox.expand(
              child: Stack(children: _buildBlobs(t, size)),
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
              color,
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

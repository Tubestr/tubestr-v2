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
      return 0.12 + 0.08 * sin(t * pi * 3.7 + phase).abs();
    }

    final driftX = 18.0 * sin(t * pi * 2.2);
    final driftY = 12.0 * cos(t * pi * 1.7);

    return [
      // Top-left warm blob
      Positioned(
        top: -90 + driftY,
        left: -72 + driftX,
        child: Transform.translate(
          offset: Offset(driftX * 0.5, driftY),
          child: Transform.scale(
            scale: flicker(0.0),
            child: _RadialBlob(
              color: p.accent.withValues(alpha: opacity(0.0)),
              size: 340,
            ),
          ),
        ),
      ),
      // Bottom-right secondary warmth
      Positioned(
        bottom: -70 - driftY,
        right: -58 - driftX,
        child: Transform.translate(
          offset: Offset(-driftX * 0.55, -driftY * 0.8),
          child: Transform.scale(
            scale: flicker(2.1),
            child: _RadialBlob(
              color: p.accentSecondary.withValues(alpha: opacity(2.1)),
              size: 300,
            ),
          ),
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Treehouse — gentle pendulum sway + subtle rotation
  // ---------------------------------------------------------------------------
  List<Widget> _treehouseBlobs(double t, Size size, KidPalette p) {
    final swayX = 46.0 * sin(t * pi * 2);
    final swayY = 16.0 * cos(t * pi * 2);
    final rotation = 0.06 * sin(t * pi * 2);

    return [
      // Center-left — accent (brown)
      Positioned(
        top: size.height * 0.25,
        left: size.width * 0.05,
        child: Transform.translate(
          offset: Offset(swayX, swayY),
          child: Transform.rotate(
            angle: rotation,
            child: _RadialBlob(
              color: p.accent.withValues(alpha: 0.20),
              size: 320,
            ),
          ),
        ),
      ),
      // Center-right — secondary (green), counter-sway for visual depth
      Positioned(
        top: size.height * 0.35,
        right: size.width * 0.05,
        child: Transform.translate(
          offset: Offset(-swayX, -swayY * 0.8),
          child: Transform.rotate(
            angle: -rotation,
            child: _RadialBlob(
              color: p.accentSecondary.withValues(alpha: 0.18),
              size: 360,
            ),
          ),
        ),
      ),
      // Small top leaf accent
      Positioned(
        top: -40,
        left: size.width * 0.40,
        child: Transform.translate(
          offset: Offset(swayX * 0.6, swayY * 0.4),
          child: Transform.rotate(
            angle: rotation * 1.5,
            child: _RadialBlob(
              color: p.accentSecondary.withValues(alpha: 0.16),
              size: 190,
            ),
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
    final driftX = 20.0 * sin(t * pi * 1.4);
    final driftY = 12.0 * cos(t * pi * 1.1);

    return [
      // Large centered primary
      Positioned(
        top: size.height * 0.14 + driftY,
        left: size.width * 0.08 + driftX,
        child: Transform.scale(
          scale: breathe,
          child: _RadialBlob(
            color: p.accent.withValues(alpha: 0.12),
            size: 470,
          ),
        ),
      ),
      // Overlapping secondary — slightly offset, counter-phase
      Positioned(
        top: size.height * 0.28 - driftY,
        left: size.width * 0.18 - driftX * 0.6,
        child: Transform.scale(
          scale: breatheB,
          child: _RadialBlob(
            color: p.accentSecondary.withValues(alpha: 0.10),
            size: 420,
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
          child: Builder(
            builder: (context) {
              final angle = (t * pi * 2 + phase) % (pi * 2);
              final opacityVal = 0.06 + 0.18 * ((sin(angle) + 1) / 2);
              final scaleVal = 0.96 + 0.18 * ((sin(angle) + 1) / 2);
              final drift = 8.0 * cos(angle);
              final color = isAccent ? p.accent : p.accentSecondary;
              return Transform.translate(
                offset: Offset(drift * 0.5, -drift),
                child: Transform.scale(
                  scale: scaleVal,
                  child: _RadialBlob(
                    color: color.withValues(alpha: opacityVal),
                    size: sz,
                  ),
                ),
              );
            },
          ),
        ),
    ];
  }

  List<Widget> _ambientWashes(double t, Size size, KidPalette p) {
    final longestSide = max(size.width, size.height);
    final driftX = 24.0 * sin(t * pi * 2);
    final driftY = 20.0 * cos(t * pi * 1.6);

    return [
      Positioned(
        top: -longestSide * 0.24 + driftY,
        left: -longestSide * 0.28 + driftX,
        child: _RadialBlob(
          color: p.accent.withValues(alpha: 0.08),
          size: longestSide * 0.88,
        ),
      ),
      Positioned(
        bottom: -longestSide * 0.30 - driftY,
        right: -longestSide * 0.18 - driftX * 0.7,
        child: _RadialBlob(
          color: p.accentSecondary.withValues(alpha: 0.07),
          size: longestSide * 0.78,
        ),
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
              child: Stack(
                children: [
                  ..._ambientWashes(t, size, p),
                  ..._buildBlobs(t, size),
                  ..._floatingDecorations(t, size, p),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Floating decorations — themed shapes that drift gently (ported from v1)
  // ---------------------------------------------------------------------------
  List<Widget> _floatingDecorations(double t, Size size, KidPalette p) {
    // 8 decorations with deterministic positions and independent phase offsets.
    // Each uses sin/cos at different frequencies to appear independent.
    const count = 8;
    final List<Widget> result = [];

    for (int i = 0; i < count; i++) {
      final seed = i * 137.0 + 42.0;
      final baseX = (sin(seed) * 0.5 + 0.5) * size.width;
      final baseY = (cos(seed * 1.3) * 0.5 + 0.5) * size.height;
      final phase = i * 0.78;
      final durationFactor = 1.0 + (i % 3) * 0.35;

      // Float: gentle drift using unique frequency per decoration
      final floatX = 20.0 * sin(t * pi * 2.0 / durationFactor + phase);
      final floatY = 28.0 * cos(t * pi * 2.0 / durationFactor + phase + 1.0);

      // Scale pulse: 0.85 – 1.15
      final scaleVal = 1.0 + 0.15 * sin(t * pi * 4.0 / durationFactor + phase);

      // Rotation: slow spin
      final rotation = (t * pi * 2.0 / durationFactor + phase * 2.0) %
          (pi * 2);

      // Size varies by index
      final decoSize = 20.0 + (i % 4) * 12.0;

      result.add(
        Positioned(
          left: baseX + floatX - decoSize / 2,
          top: baseY + floatY - decoSize / 2,
          child: Transform.rotate(
            angle: i.isEven ? rotation : -rotation,
            child: Transform.scale(
              scale: scaleVal,
              child: _themedDecoration(i, decoSize, p),
            ),
          ),
        ),
      );
    }

    return result;
  }

  Widget _themedDecoration(int index, double size, KidPalette p) {
    const opacity = 0.38;
    return switch (widget.theme) {
      ThemeDescriptor.campfire => index % 3 == 0
          ? Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.accent.withValues(alpha: opacity),
                    p.accentSecondary.withValues(alpha: opacity * 0.3),
                  ],
                ),
              ),
            )
          : Icon(
              Icons.auto_awesome,
              size: size * 0.8,
              color: p.accentSecondary.withValues(alpha: opacity),
            ),
      ThemeDescriptor.treehouse => index % 3 == 0
          ? Icon(
              Icons.eco_rounded,
              size: size,
              color: p.accentSecondary.withValues(alpha: opacity),
            )
          : index % 3 == 1
              ? Container(
                  width: size * 0.6,
                  height: size * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.accent.withValues(alpha: opacity),
                  ),
                )
              : Icon(
                  Icons.park_rounded,
                  size: size * 0.8,
                  color: p.accent.withValues(alpha: opacity),
                ),
      ThemeDescriptor.blanketFort => index % 3 == 0
          ? Icon(
              Icons.favorite_rounded,
              size: size * 0.8,
              color: p.accentSecondary.withValues(alpha: opacity),
            )
          : index % 3 == 1
              ? Icon(
                  Icons.star_rounded,
                  size: size * 0.7,
                  color: p.accent.withValues(alpha: opacity),
                )
              : Container(
                  width: size * 1.2,
                  height: size * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.3),
                    color: p.accent.withValues(alpha: opacity * 0.6),
                  ),
                ),
      ThemeDescriptor.starlight => index % 4 == 0
          ? Icon(
              Icons.star_rounded,
              size: size,
              color: p.accentSecondary.withValues(alpha: opacity),
            )
          : index % 4 == 1
              ? Icon(
                  Icons.nightlight_round,
                  size: size * 0.9,
                  color: p.accent.withValues(alpha: opacity * 0.8),
                )
              : index % 4 == 2
                  ? Icon(
                      Icons.auto_awesome,
                      size: size * 0.7,
                      color: p.accentSecondary.withValues(alpha: opacity),
                    )
                  : Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            p.accentSecondary.withValues(alpha: opacity),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
    };
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
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
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

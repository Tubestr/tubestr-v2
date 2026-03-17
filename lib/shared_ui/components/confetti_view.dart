import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

class ConfettiView extends StatefulWidget {
  const ConfettiView({
    super.key,
    required this.play,
    this.colors = const [
      Color(0xFFFF8A65),
      Color(0xFFFFD54F),
      Color(0xFF4DD0E1),
      Color(0xFF81C784),
      Color(0xFFBA68C8),
    ],
  });

  final bool play;
  final List<Color> colors;

  @override
  State<ConfettiView> createState() => _ConfettiViewState();
}

class _ConfettiViewState extends State<ConfettiView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.play) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ConfettiView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.value == 0 && !widget.play) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            painter: _ConfettiPainter(
              progress: Curves.easeOut.transform(_controller.value),
              colors: widget.colors,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final pieceCount = 48;
    for (var index = 0; index < pieceCount; index++) {
      final seed = index + 1;
      final startX = (size.width * ((seed * 37) % 100) / 100).clamp(
        16.0,
        size.width - 16,
      );
      final drift = (((seed * 17) % 24) - 12) * progress * 3;
      final startY = -24.0 - (seed % 8) * 12.0;
      final endY = size.height * 0.72 + (seed % 10) * 10.0;
      final y = lerpDouble(startY, endY, progress)!;
      final rotation = progress * math.pi * ((seed % 5) + 1);
      final width = 8.0 + (seed % 4) * 2.0;
      final height = 10.0 + (seed % 3) * 3.0;
      final color = colors[index % colors.length].withValues(
        alpha: (1 - progress * 0.35).clamp(0.0, 1.0),
      );
      final paint = Paint()..color = color;

      canvas.save();
      canvas.translate(startX + drift, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors;
  }
}

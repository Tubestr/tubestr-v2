import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/editor/ar_filter_renderer.dart';

class ArFilterOverlayPainter extends CustomPainter {
  const ArFilterOverlayPainter({required this.commands});

  final List<ArFilterDrawCommand> commands;

  @override
  void paint(Canvas canvas, Size size) {
    for (final command in commands) {
      canvas.save();
      canvas.translate(command.position.dx, command.position.dy);
      canvas.rotate(command.rotationRadians);
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: command.size.width,
        height: command.size.height,
      );
      final paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(255, 255, 255, command.opacity);
      canvas.drawImageRect(
        command.image,
        Rect.fromLTWH(
          0,
          0,
          command.image.width.toDouble(),
          command.image.height.toDouble(),
        ),
        dst,
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ArFilterOverlayPainter oldDelegate) {
    return !listEquals(commands, oldDelegate.commands);
  }
}

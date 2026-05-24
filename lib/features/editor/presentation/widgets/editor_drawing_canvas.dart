import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../domain/models/editor_session.dart';

class EditorDrawingCanvas extends StatefulWidget {
  const EditorDrawingCanvas({
    super.key,
    required this.strokes,
    required this.activeTool,
    required this.colorValue,
    required this.width,
    required this.onStrokeCompleted,
  });

  final List<EditorStroke> strokes;
  final EditorDrawTool activeTool;
  final int colorValue;
  final double width;
  final ValueChanged<EditorStroke> onStrokeCompleted;

  @override
  State<EditorDrawingCanvas> createState() => _EditorDrawingCanvasState();
}

class _EditorDrawingCanvasState extends State<EditorDrawingCanvas> {
  EditorStroke? _draftStroke;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _startStroke(details.localPosition, size),
          onPanUpdate: (details) => _appendPoint(details.localPosition, size),
          onPanEnd: (_) => _completeStroke(),
          onPanCancel: _completeStroke,
          child: CustomPaint(
            painter: EditorDrawingPainter(
              strokes: [...widget.strokes, ?_draftStroke],
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  void _startStroke(Offset localPosition, Size size) {
    final point = _normalizePoint(localPosition, size);
    setState(() {
      _draftStroke = EditorStroke(
        id: 'stroke:${DateTime.now().microsecondsSinceEpoch}',
        tool: widget.activeTool,
        colorValue: widget.colorValue,
        width: widget.width,
        points: [point],
      );
    });
  }

  void _appendPoint(Offset localPosition, Size size) {
    final draft = _draftStroke;
    if (draft == null) return;
    final point = _normalizePoint(localPosition, size);
    setState(() {
      _draftStroke = draft.copyWith(points: [...draft.points, point]);
    });
  }

  void _completeStroke() {
    final draft = _draftStroke;
    if (draft == null) return;
    setState(() => _draftStroke = null);
    if (draft.points.isNotEmpty) {
      widget.onStrokeCompleted(draft);
    }
  }

  Offset _normalizePoint(Offset point, Size size) {
    final width = size.width <= 0 ? 1.0 : size.width;
    final height = size.height <= 0 ? 1.0 : size.height;
    return Offset(
      (point.dx / width).clamp(0.0, 1.0),
      (point.dy / height).clamp(0.0, 1.0),
    );
  }
}

class EditorDrawingPainter extends CustomPainter {
  const EditorDrawingPainter({required this.strokes});

  final List<EditorStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty || size.isEmpty) return;

    // Eraser strokes use BlendMode.clear within this isolated layer so they
    // subtract only from the annotation pixels, never from the video below.
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final stroke in strokes) {
      _paintStroke(canvas, size, stroke);
    }
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Size size, EditorStroke stroke) {
    if (stroke.points.isEmpty) return;
    final paint = Paint()
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = stroke.tool != EditorDrawTool.pencil
      ..blendMode = stroke.tool == EditorDrawTool.eraser
          ? BlendMode.clear
          : BlendMode.srcOver
      ..color = _strokeColor(stroke);

    final points = stroke.points
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    if (points.length == 1) {
      canvas.drawCircle(
        points.single,
        stroke.width / 2,
        paint..style = PaintingStyle.fill,
      );
      return;
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  Color _strokeColor(EditorStroke stroke) {
    if (stroke.tool == EditorDrawTool.eraser) {
      return const Color(0xFFFFFFFF);
    }
    final color = Color(stroke.colorValue);
    if (stroke.tool == EditorDrawTool.marker) {
      return color.withValues(alpha: 0.5);
    }
    return color;
  }

  @override
  bool shouldRepaint(covariant EditorDrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}

Future<Uint8List?> renderEditorDrawingPng({
  required List<EditorStroke> strokes,
  required Size size,
}) async {
  if (strokes.isEmpty || size.isEmpty) return null;
  final width = size.width.round().clamp(1, 4096);
  final height = size.height.round().clamp(1, 4096);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );
  EditorDrawingPainter(
    strokes: strokes,
  ).paint(canvas, Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return pngBytes?.buffer.asUint8List();
}

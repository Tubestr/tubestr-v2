import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/models/ar_face_result.dart';
import 'ar_filter_catalog.dart';

@immutable
class ArPreviewGeometry {
  const ArPreviewGeometry({
    required this.imageSize,
    required this.viewportSize,
    this.isMirrored = false,
  });

  final Size imageSize;
  final Size viewportSize;
  final bool isMirrored;

  Offset mapNormalizedPoint(Offset normalizedPoint) {
    final imageAspectRatio = imageSize.width / math.max(imageSize.height, 1);
    final viewportAspectRatio =
        viewportSize.width / math.max(viewportSize.height, 1);
    final Size fittedSize;
    if (viewportAspectRatio > imageAspectRatio) {
      fittedSize = Size(
        viewportSize.width,
        viewportSize.width / imageAspectRatio,
      );
    } else {
      fittedSize = Size(
        viewportSize.height * imageAspectRatio,
        viewportSize.height,
      );
    }
    final origin = Offset(
      (viewportSize.width - fittedSize.width) / 2,
      (viewportSize.height - fittedSize.height) / 2,
    );
    final x = isMirrored ? 1 - normalizedPoint.dx : normalizedPoint.dx;
    return Offset(
      origin.dx + x * fittedSize.width,
      origin.dy + normalizedPoint.dy * fittedSize.height,
    );
  }
}

@immutable
class ArFilterDrawCommand {
  const ArFilterDrawCommand({
    required this.image,
    required this.position,
    required this.size,
    required this.rotationRadians,
    this.opacity = 1,
  });

  final ui.Image image;
  final Offset position;
  final Size size;
  final double rotationRadians;
  final double opacity;
}

class ArFilterRenderer {
  const ArFilterRenderer();

  List<ArFilterDrawCommand> computeDrawCommands({
    required ArFaceResult face,
    required ArFilterAsset filter,
    required ArPreviewGeometry geometry,
  }) {
    final faceWidth = _faceWidth(face: face, geometry: geometry);
    if (faceWidth <= 0) {
      return const <ArFilterDrawCommand>[];
    }

    final rollRadians = (face.headEulerZ ?? 0) * math.pi / 180;
    final commands = <ArFilterDrawCommand>[];
    for (final part in filter.parts) {
      final anchor = _anchorPosition(
        face: face,
        anchor: part.anchor,
        geometry: geometry,
      );
      if (anchor == null) {
        continue;
      }

      final offset = _rotateOffset(part.offset * faceWidth, rollRadians);
      final width = faceWidth * part.widthScale;
      final aspectRatio = part.image.height / math.max(part.image.width, 1);
      commands.add(
        ArFilterDrawCommand(
          image: part.image,
          position: anchor + offset,
          size: Size(width, width * aspectRatio),
          rotationRadians: rollRadians + part.rotationDegrees * math.pi / 180,
          opacity: part.opacity,
        ),
      );
    }
    return commands;
  }

  double _faceWidth({
    required ArFaceResult face,
    required ArPreviewGeometry geometry,
  }) {
    final leftEye = face.leftEye;
    final rightEye = face.rightEye;
    if (leftEye != null && rightEye != null) {
      final leftPx = geometry.mapNormalizedPoint(leftEye);
      final rightPx = geometry.mapNormalizedPoint(rightEye);
      return (rightPx - leftPx).distance * 2.45;
    }
    final boxLeft = face.boundingBox.left / math.max(face.imageSize.width, 1);
    final boxRight = face.boundingBox.right / math.max(face.imageSize.width, 1);
    final boxTop = face.boundingBox.top / math.max(face.imageSize.height, 1);
    final boxBottom =
        face.boundingBox.bottom / math.max(face.imageSize.height, 1);
    final topLeft = geometry.mapNormalizedPoint(Offset(boxLeft, boxTop));
    final bottomRight = geometry.mapNormalizedPoint(
      Offset(boxRight, boxBottom),
    );
    return (bottomRight.dx - topLeft.dx).abs();
  }

  Offset? _anchorPosition({
    required ArFaceResult face,
    required ArFilterAnchor anchor,
    required ArPreviewGeometry geometry,
  }) {
    Offset? normalized;
    switch (anchor) {
      case ArFilterAnchor.eyesBridge:
        normalized = _midpoint(face.leftEye, face.rightEye);
      case ArFilterAnchor.forehead:
        normalized =
            face.foreheadCenter ??
            _offsetFrom(face.leftEye, face.rightEye, dy: -0.12);
      case ArFilterAnchor.noseTip:
        normalized = face.noseTip;
      case ArFilterAnchor.mouthCenter:
        normalized = _midpoint(face.leftMouth, face.rightMouth);
      case ArFilterAnchor.leftEye:
        normalized = face.leftEye;
      case ArFilterAnchor.rightEye:
        normalized = face.rightEye;
    }
    return normalized == null ? null : geometry.mapNormalizedPoint(normalized);
  }

  Offset? _midpoint(Offset? a, Offset? b) {
    if (a == null || b == null) {
      return null;
    }
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
  }

  Offset? _offsetFrom(Offset? a, Offset? b, {required double dy}) {
    final center = _midpoint(a, b);
    if (center == null) {
      return null;
    }
    return center + Offset(0, dy);
  }

  Offset _rotateOffset(Offset offset, double radians) {
    if (radians == 0) {
      return offset;
    }
    final sin = math.sin(radians);
    final cos = math.cos(radians);
    return Offset(
      offset.dx * cos - offset.dy * sin,
      offset.dx * sin + offset.dy * cos,
    );
  }
}

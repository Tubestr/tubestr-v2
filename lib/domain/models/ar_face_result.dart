import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

@immutable
class ArFaceResult {
  const ArFaceResult({
    required this.boundingBox,
    required this.landmarks,
    required this.score,
    required this.imageSize,
    this.trackingId,
    this.headEulerY,
    this.headEulerZ,
  });

  final FaceMeshBox boundingBox;
  final List<FaceMeshLandmark> landmarks;
  final double score;
  final Size imageSize;
  final int? trackingId;
  final double? headEulerY;
  final double? headEulerZ;

  Offset? landmarkOffset(int index) {
    if (index < 0 || index >= landmarks.length) {
      return null;
    }
    final point = landmarks[index];
    return Offset(point.x, point.y);
  }

  Offset? get leftEye => landmarkOffset(33);
  Offset? get rightEye => landmarkOffset(263);
  Offset? get noseTip => landmarkOffset(1);
  Offset? get leftMouth => landmarkOffset(61);
  Offset? get rightMouth => landmarkOffset(291);
  Offset? get foreheadCenter => landmarkOffset(10);
  Offset? get chinBottom => landmarkOffset(152);
}

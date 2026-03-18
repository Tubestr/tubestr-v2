import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_video/ffprobe_kit.dart';
import 'package:flutter/services.dart';

/// Lightweight metadata about a video file obtained via ffprobe.
class VideoProbeResult {
  const VideoProbeResult({
    required this.encodedSize,
    required this.rotationDegrees,
  });

  final ui.Size encodedSize;
  final int rotationDegrees;

  /// Returns the size after accounting for rotation metadata.
  /// Portrait videos captured in landscape sensors report 90° or 270°
  /// rotation — this swaps width/height so callers get display dimensions.
  ui.Size get displaySize {
    final normalized = ((rotationDegrees % 360) + 360) % 360;
    if (normalized == 90 || normalized == 270) {
      return ui.Size(encodedSize.height, encodedSize.width);
    }
    return encodedSize;
  }

  double get displayAspectRatio => displaySize.width / displaySize.height;
}

/// Probes a video file for its encoded dimensions and rotation metadata.
Future<VideoProbeResult?> probeVideoFile(String path) async {
  try {
    final session = await FFprobeKit.getMediaInformation(path);
    final info = session.getMediaInformation();
    if (info == null) return null;

    for (final stream in info.getStreams()) {
      if (stream.getType() != 'video') continue;
      final width = stream.getWidth();
      final height = stream.getHeight();
      if (width == null || height == null || width <= 0 || height <= 0) {
        continue;
      }
      return VideoProbeResult(
        encodedSize: ui.Size(width.toDouble(), height.toDouble()),
        rotationDegrees: _parseRotationDegrees(stream),
      );
    }
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
  return null;
}

int _parseRotationDegrees(dynamic stream) {
  final directRotation = int.tryParse(
    '${stream.getProperty('rotation') ?? ''}',
  );
  if (directRotation != null) return directRotation;

  final tags = stream.getTags();
  if (tags is Map) {
    final tagRotation = int.tryParse(
      '${tags['rotate'] ?? tags['rotation'] ?? ''}',
    );
    if (tagRotation != null) return tagRotation;
  }

  final sideData = stream.getProperty('side_data_list');
  if (sideData is List) {
    for (final entry in sideData) {
      if (entry is Map) {
        final sideRotation = int.tryParse('${entry['rotation'] ?? ''}');
        if (sideRotation != null) return sideRotation;
      }
    }
  }

  return 0;
}

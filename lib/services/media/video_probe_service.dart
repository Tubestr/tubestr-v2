import 'dart:convert';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_video/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/services.dart';

/// Lightweight metadata about a video file obtained via ffprobe.
class VideoProbeResult {
  const VideoProbeResult({
    required this.encodedSize,
    required this.rotationDegrees,
    this.reportedDisplayAspectRatio,
    this.hasAudio = false,
    this.rawVideoStreamProperties,
  });

  final ui.Size encodedSize;
  final int rotationDegrees;
  final double? reportedDisplayAspectRatio;
  final bool hasAudio;
  final Map<String, dynamic>? rawVideoStreamProperties;

  /// Returns the size after accounting for rotation metadata.
  /// Portrait videos captured in landscape sensors report 90° or 270°
  /// rotation — this swaps width/height so callers get display dimensions.
  ui.Size get displaySize {
    final aspectRatio = reportedDisplayAspectRatio;
    if (aspectRatio != null && aspectRatio > 0) {
      final longestSide = encodedSize.width > encodedSize.height
          ? encodedSize.width
          : encodedSize.height;
      if (aspectRatio >= 1) {
        return ui.Size(longestSide, longestSide / aspectRatio);
      }
      return ui.Size(longestSide * aspectRatio, longestSide);
    }

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
    final session = await FFprobeKit.executeWithArguments(
      _probeArguments(path),
    );
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      return null;
    }
    final output = await session.getOutput();
    if (output == null || output.trim().isEmpty) {
      return null;
    }
    return parseVideoProbeJson(output);
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  } on FormatException {
    return null;
  }
}

VideoProbeResult? parseVideoProbeJson(String jsonOutput) {
  final decoded = jsonDecode(jsonOutput);
  if (decoded is! Map) {
    return null;
  }
  final streams = decoded['streams'];
  if (streams is! List) {
    return null;
  }

  var hasAudio = false;
  Map<String, dynamic>? videoStream;
  for (final stream in streams) {
    if (stream is! Map) {
      continue;
    }
    final normalized = Map<String, dynamic>.from(stream);
    final codecType = '${normalized['codec_type'] ?? ''}';
    if (codecType == 'audio') {
      hasAudio = true;
    } else if (codecType == 'video' && videoStream == null) {
      videoStream = normalized;
    }
  }
  if (videoStream == null) {
    return null;
  }

  final width = _parseInt(videoStream['width']);
  final height = _parseInt(videoStream['height']);
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }

  return VideoProbeResult(
    encodedSize: ui.Size(width.toDouble(), height.toDouble()),
    rotationDegrees: _parseRotationDegrees(videoStream),
    reportedDisplayAspectRatio: _parseDisplayAspectRatio(videoStream),
    hasAudio: hasAudio,
    rawVideoStreamProperties: videoStream,
  );
}

List<String> _probeArguments(String path) {
  return <String>[
    '-v',
    'error',
    '-hide_banner',
    '-print_format',
    'json',
    '-show_entries',
    'stream=index,codec_type,width,height,display_aspect_ratio,sample_aspect_ratio:stream_tags=rotate,rotation:stream_side_data=rotation,displaymatrix,side_data_type',
    '-show_streams',
    '-i',
    path,
  ];
}

int _parseRotationDegrees(Map<String, dynamic> stream) {
  final directRotation = _parseInt(stream['rotation']);
  if (directRotation != null) return directRotation;

  final tags = stream['tags'];
  if (tags is Map) {
    final tagRotation =
        _parseInt(tags['rotate']) ?? _parseInt(tags['rotation']);
    if (tagRotation != null) return tagRotation;
  }

  final sideData = stream['side_data_list'];
  if (sideData is List) {
    for (final entry in sideData) {
      if (entry is Map) {
        final sideRotation = _parseInt(entry['rotation']);
        if (sideRotation != null) return sideRotation;
      }
    }
  }

  return 0;
}

double? _parseDisplayAspectRatio(Map<String, dynamic> stream) {
  final rawAspectRatio = stream['display_aspect_ratio'];
  if (rawAspectRatio is! String || rawAspectRatio.isEmpty) {
    return null;
  }

  final parts = rawAspectRatio.split(':');
  if (parts.length == 2) {
    final width = double.tryParse(parts.first);
    final height = double.tryParse(parts.last);
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
  }

  final parsed = double.tryParse(rawAspectRatio);
  if (parsed != null && parsed > 0) {
    return parsed;
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value == null) {
    return null;
  }
  return int.tryParse('$value');
}

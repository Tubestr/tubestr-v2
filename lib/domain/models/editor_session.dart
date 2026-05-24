import 'dart:ui';

import 'package:flutter/foundation.dart';

enum EditorTool { trim, effects, overlays, audio, text, draw }

enum EditorOverlayType { sticker, text }

enum EditorDrawTool { pencil, marker, eraser }

@immutable
class StickerTransform {
  const StickerTransform({
    this.position = const Offset(0.5, 0.5),
    this.scale = 1,
    this.rotationDegrees = 0,
  });

  final Offset position;
  final double scale;
  final double rotationDegrees;

  StickerTransform copyWith({
    Offset? position,
    double? scale,
    double? rotationDegrees,
  }) {
    return StickerTransform(
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }
}

@immutable
class EditorTrimRange {
  const EditorTrimRange({required this.start, required this.end});

  final Duration start;
  final Duration end;

  Duration get duration => end - start;

  EditorTrimRange copyWith({Duration? start, Duration? end}) {
    return EditorTrimRange(start: start ?? this.start, end: end ?? this.end);
  }
}

@immutable
class EditorOverlayItem {
  const EditorOverlayItem({
    required this.id,
    required this.type,
    this.stickerId,
    this.stickerAssetPath,
    this.text,
    this.fontFamily,
    this.textColorValue,
    this.textSize = 40,
    this.transform = const StickerTransform(),
  });

  final String id;
  final EditorOverlayType type;
  final String? stickerId;
  final String? stickerAssetPath;
  final String? text;
  final String? fontFamily;
  final int? textColorValue;
  final double textSize;
  final StickerTransform transform;

  EditorOverlayItem copyWith({
    String? id,
    EditorOverlayType? type,
    String? stickerId,
    String? stickerAssetPath,
    String? text,
    String? fontFamily,
    int? textColorValue,
    double? textSize,
    StickerTransform? transform,
  }) {
    return EditorOverlayItem(
      id: id ?? this.id,
      type: type ?? this.type,
      stickerId: stickerId ?? this.stickerId,
      stickerAssetPath: stickerAssetPath ?? this.stickerAssetPath,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      textColorValue: textColorValue ?? this.textColorValue,
      textSize: textSize ?? this.textSize,
      transform: transform ?? this.transform,
    );
  }
}

@immutable
class EditorAudioSelection {
  const EditorAudioSelection({
    required this.trackId,
    required this.assetPath,
    this.startOffset = Duration.zero,
    this.volume = 0.75,
  });

  final String trackId;
  final String assetPath;
  final Duration startOffset;
  final double volume;

  EditorAudioSelection copyWith({
    String? trackId,
    String? assetPath,
    Duration? startOffset,
    double? volume,
  }) {
    return EditorAudioSelection(
      trackId: trackId ?? this.trackId,
      assetPath: assetPath ?? this.assetPath,
      startOffset: startOffset ?? this.startOffset,
      volume: volume ?? this.volume,
    );
  }
}

@immutable
class EditorStroke {
  const EditorStroke({
    required this.id,
    required this.tool,
    required this.colorValue,
    required this.width,
    required this.points,
  });

  final String id;
  final EditorDrawTool tool;
  final int colorValue;
  final double width;
  final List<Offset> points;

  EditorStroke copyWith({
    String? id,
    EditorDrawTool? tool,
    int? colorValue,
    double? width,
    List<Offset>? points,
  }) {
    return EditorStroke(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      colorValue: colorValue ?? this.colorValue,
      width: width ?? this.width,
      points: points ?? this.points,
    );
  }
}

@immutable
class EditorAdjustments {
  const EditorAdjustments({
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.sharpness = 0,
    this.vignette = 0,
  });

  final double brightness;
  final double contrast;
  final double saturation;
  final double sharpness;
  final double vignette;

  EditorAdjustments copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? sharpness,
    double? vignette,
  }) {
    return EditorAdjustments(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      sharpness: sharpness ?? this.sharpness,
      vignette: vignette ?? this.vignette,
    );
  }
}

@immutable
class EditorSession {
  const EditorSession({
    required this.videoId,
    required this.sourcePath,
    required this.videoDuration,
    required this.trimRange,
    this.filterPresetId = 'none',
    this.playbackSpeed = 1.0,
    this.adjustments = const EditorAdjustments(),
    this.overlays = const <EditorOverlayItem>[],
    this.strokes = const <EditorStroke>[],
    this.audioSelection,
  });

  final String videoId;
  final String sourcePath;
  final Duration videoDuration;
  final EditorTrimRange trimRange;
  final String filterPresetId;
  final double playbackSpeed;
  final EditorAdjustments adjustments;
  final List<EditorOverlayItem> overlays;
  final List<EditorStroke> strokes;
  final EditorAudioSelection? audioSelection;

  static double clampPlaybackSpeed(double value) {
    return value.clamp(0.25, 4.0).toDouble();
  }

  EditorSession copyWith({
    String? videoId,
    String? sourcePath,
    Duration? videoDuration,
    EditorTrimRange? trimRange,
    String? filterPresetId,
    double? playbackSpeed,
    EditorAdjustments? adjustments,
    List<EditorOverlayItem>? overlays,
    List<EditorStroke>? strokes,
    EditorAudioSelection? audioSelection,
    bool clearAudioSelection = false,
  }) {
    return EditorSession(
      videoId: videoId ?? this.videoId,
      sourcePath: sourcePath ?? this.sourcePath,
      videoDuration: videoDuration ?? this.videoDuration,
      trimRange: trimRange ?? this.trimRange,
      filterPresetId: filterPresetId ?? this.filterPresetId,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      adjustments: adjustments ?? this.adjustments,
      overlays: overlays ?? this.overlays,
      strokes: strokes ?? this.strokes,
      audioSelection: clearAudioSelection
          ? null
          : (audioSelection ?? this.audioSelection),
    );
  }
}

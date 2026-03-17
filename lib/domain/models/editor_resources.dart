import 'package:flutter/foundation.dart';

@immutable
class EditorStickerAsset {
  const EditorStickerAsset({
    required this.id,
    required this.assetPath,
    required this.label,
    this.isUserCreated = false,
  });

  final String id;
  final String assetPath;
  final String label;
  final bool isUserCreated;
}

@immutable
class EditorMusicTrackAsset {
  const EditorMusicTrackAsset({
    required this.id,
    required this.assetPath,
    required this.label,
  });

  final String id;
  final String assetPath;
  final String label;
}

@immutable
class EditorLutAsset {
  const EditorLutAsset({
    required this.id,
    required this.assetPath,
    required this.label,
  });

  final String id;
  final String assetPath;
  final String label;
}

enum EditorFilterEngine { none, lut3d, eq }

@immutable
class EditorFilterPreset {
  const EditorFilterPreset({
    required this.id,
    required this.label,
    required this.engine,
    this.lutAssetId,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
  });

  final String id;
  final String label;
  final EditorFilterEngine engine;
  final String? lutAssetId;
  final double brightness;
  final double contrast;
  final double saturation;
}

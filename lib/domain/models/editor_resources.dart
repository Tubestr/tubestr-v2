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
    required this.label,
    this.assetPath = '',
    this.creator,
    this.license,
    this.licenseUrl,
    this.sourceUrl,
    this.categories = const <String>[],
    this.attribution,
    this.blossomHash,
    this.byteLength,
    this.mimeType = 'audio/mpeg',
    this.blossomServers = const <String>[],
  });

  final String id;
  final String assetPath;
  final String label;
  final String? creator;
  final String? license;
  final String? licenseUrl;
  final String? sourceUrl;
  final List<String> categories;
  final String? attribution;
  final String? blossomHash;
  final int? byteLength;
  final String mimeType;
  final List<String> blossomServers;

  bool get isBundledAsset => assetPath.startsWith('assets/');
  bool get isCachedFile => assetPath.isNotEmpty && !isBundledAsset;
  bool get isBlossomBacked => blossomHash != null && blossomHash!.isNotEmpty;
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

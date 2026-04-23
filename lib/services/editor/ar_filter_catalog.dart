import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum ArFilterAnchor {
  eyesBridge,
  forehead,
  noseTip,
  mouthCenter,
  leftEye,
  rightEye,
}

typedef ArFilterAssetLoader =
    Future<ArFilterAsset?> Function(String? id, {AssetBundle? assetBundle});

@immutable
class ArFilterDefinition {
  const ArFilterDefinition({
    required this.id,
    required this.label,
    required this.parts,
    this.category = 'featured',
    this.description,
    this.thumbnailPath,
    this.sourceName,
    this.sourceUrl,
    this.license,
    this.licenseUrl,
    this.attribution,
  });

  final String id;
  final String label;
  final List<ArFilterPartDefinition> parts;
  final String category;
  final String? description;
  final String? thumbnailPath;
  final String? sourceName;
  final String? sourceUrl;
  final String? license;
  final String? licenseUrl;
  final String? attribution;

  bool get isDownloadable => parts.any((part) => part.isDownloadable);

  ArFilterDefinition copyWith({
    String? id,
    String? label,
    List<ArFilterPartDefinition>? parts,
    String? category,
    String? description,
    String? thumbnailPath,
    String? sourceName,
    String? sourceUrl,
    String? license,
    String? licenseUrl,
    String? attribution,
  }) {
    return ArFilterDefinition(
      id: id ?? this.id,
      label: label ?? this.label,
      parts: parts ?? this.parts,
      category: category ?? this.category,
      description: description ?? this.description,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      sourceName: sourceName ?? this.sourceName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      license: license ?? this.license,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      attribution: attribution ?? this.attribution,
    );
  }

  factory ArFilterDefinition.fromJson(Map<String, Object?> json) {
    final rawParts = json['parts'];
    return ArFilterDefinition(
      id: (json['id'] as String?)?.trim() ?? '',
      label: (json['label'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : 'featured',
      description: (json['description'] as String?)?.trim(),
      thumbnailPath: (json['thumbnailPath'] as String?)?.trim(),
      sourceName: (json['sourceName'] as String?)?.trim(),
      sourceUrl: (json['sourceUrl'] as String?)?.trim(),
      license: (json['license'] as String?)?.trim(),
      licenseUrl: (json['licenseUrl'] as String?)?.trim(),
      attribution: (json['attribution'] as String?)?.trim(),
      parts: rawParts is List
          ? rawParts
                .whereType<Map<String, Object?>>()
                .map(ArFilterPartDefinition.fromJson)
                .toList(growable: false)
          : const <ArFilterPartDefinition>[],
    );
  }
}

@immutable
class ArFilterPartDefinition {
  const ArFilterPartDefinition({
    required this.assetPath,
    required this.anchor,
    required this.widthScale,
    this.offset = Offset.zero,
    this.rotationDegrees = 0,
    this.opacity = 1,
    this.blossomHash,
    this.byteLength,
    this.blossomServers = const <String>[],
    this.mimeType = 'image/png',
  });

  final String assetPath;
  final ArFilterAnchor anchor;

  /// Width relative to the detected face width.
  final double widthScale;

  /// Offset relative to the detected face width.
  final Offset offset;
  final double rotationDegrees;
  final double opacity;
  final String? blossomHash;
  final int? byteLength;
  final List<String> blossomServers;
  final String mimeType;

  bool get isDownloadable => blossomHash != null && blossomHash!.isNotEmpty;

  ArFilterPartDefinition copyWith({
    String? assetPath,
    ArFilterAnchor? anchor,
    double? widthScale,
    Offset? offset,
    double? rotationDegrees,
    double? opacity,
    String? blossomHash,
    int? byteLength,
    List<String>? blossomServers,
    String? mimeType,
  }) {
    return ArFilterPartDefinition(
      assetPath: assetPath ?? this.assetPath,
      anchor: anchor ?? this.anchor,
      widthScale: widthScale ?? this.widthScale,
      offset: offset ?? this.offset,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      opacity: opacity ?? this.opacity,
      blossomHash: blossomHash ?? this.blossomHash,
      byteLength: byteLength ?? this.byteLength,
      blossomServers: blossomServers ?? this.blossomServers,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  factory ArFilterPartDefinition.fromJson(Map<String, Object?> json) {
    return ArFilterPartDefinition(
      assetPath: (json['assetPath'] as String?)?.trim() ?? '',
      anchor: _anchorFromJson(json['anchor']),
      widthScale: _doubleFromJson(json['widthScale'], fallback: 1),
      offset: Offset(
        _doubleFromJson(json['offsetX'], fallback: 0),
        _doubleFromJson(json['offsetY'], fallback: 0),
      ),
      rotationDegrees: _doubleFromJson(json['rotationDegrees'], fallback: 0),
      opacity: _doubleFromJson(json['opacity'], fallback: 1),
      blossomHash: (json['blossomHash'] as String?)?.trim(),
      byteLength: _intFromJson(json['byteLength']),
      blossomServers: json['blossomServers'] is List
          ? (json['blossomServers'] as List)
                .whereType<String>()
                .map((server) => server.trim())
                .where((server) => server.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      mimeType: (json['mimeType'] as String?)?.trim().isNotEmpty == true
          ? (json['mimeType'] as String).trim()
          : 'image/png',
    );
  }
}

@immutable
class ArFilterAsset {
  const ArFilterAsset({
    required this.id,
    required this.label,
    required this.parts,
  });

  final String id;
  final String label;
  final List<ArFilterPart> parts;

  void dispose() {
    for (final part in parts) {
      part.image.dispose();
    }
  }
}

@immutable
class ArFilterPart {
  const ArFilterPart({
    required this.image,
    required this.anchor,
    required this.widthScale,
    this.offset = Offset.zero,
    this.rotationDegrees = 0,
    this.opacity = 1,
  });

  final ui.Image image;
  final ArFilterAnchor anchor;
  final double widthScale;
  final Offset offset;
  final double rotationDegrees;
  final double opacity;
}

class ArFilterCatalog {
  const ArFilterCatalog._();

  static const noneId = 'none';
  static const tagPrefix = 'ar_filter:';
  static const trackTagPrefix = 'ar_track:';

  static const builtInFilters = <ArFilterDefinition>[];

  static ArFilterDefinition? byId(String? id) {
    if (id == null || id == noneId) {
      return null;
    }
    for (final filter in builtInFilters) {
      if (filter.id == id) {
        return filter;
      }
    }
    return null;
  }

  static String tagFor(String id) => '$tagPrefix$id';

  static String trackTagFor(String path) => '$trackTagPrefix$path';

  static String? idFromTags(List<String> tags) {
    for (final tag in tags) {
      if (!tag.startsWith(tagPrefix)) {
        continue;
      }
      final id = tag.substring(tagPrefix.length);
      if (id.trim().isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  static String? trackPathFromTags(List<String> tags) {
    for (final tag in tags) {
      if (tag.startsWith(trackTagPrefix)) {
        final path = tag.substring(trackTagPrefix.length).trim();
        return path.isEmpty ? null : path;
      }
    }
    return null;
  }

  static Future<ArFilterAsset?> load(
    String? id, {
    AssetBundle? assetBundle,
  }) async {
    final definition = byId(id);
    if (definition == null) {
      return null;
    }
    return loadDefinition(definition, assetBundle: assetBundle);
  }

  static Future<ArFilterAsset> loadDefinition(
    ArFilterDefinition definition, {
    AssetBundle? assetBundle,
  }) async {
    final bundle = assetBundle ?? rootBundle;
    final parts = <ArFilterPart>[];
    for (final part in definition.parts) {
      final image = await _decodeImage(
        await _loadBytes(part.assetPath, bundle),
      );
      parts.add(
        ArFilterPart(
          image: image,
          anchor: part.anchor,
          widthScale: part.widthScale,
          offset: part.offset,
          rotationDegrees: part.rotationDegrees,
          opacity: part.opacity,
        ),
      );
    }
    return ArFilterAsset(
      id: definition.id,
      label: definition.label,
      parts: parts,
    );
  }

  static Future<Uint8List> _loadBytes(String path, AssetBundle bundle) async {
    if (_isAssetPath(path)) {
      final data = await bundle.load(path);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    }
    return File(path).readAsBytes();
  }

  static bool _isAssetPath(String path) {
    return path.startsWith('assets/');
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

ArFilterAnchor _anchorFromJson(Object? value) {
  if (value is String) {
    for (final anchor in ArFilterAnchor.values) {
      if (anchor.name == value) {
        return anchor;
      }
    }
  }
  return ArFilterAnchor.forehead;
}

double _doubleFromJson(Object? value, {required double fallback}) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

int? _intFromJson(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

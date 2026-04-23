import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../blossom/blossom_client.dart';
import 'ar_filter_catalog.dart';
import 'generated_ar_filter_catalog.dart';

class ArFilterLibraryService {
  ArFilterLibraryService({
    required BlossomClient blossomClient,
    Future<Directory> Function()? supportDirectoryProvider,
    List<ArFilterDefinition> extraFilters = const <ArFilterDefinition>[],
  }) : _blossomClient = blossomClient,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory,
       _extraFilters = extraFilters;

  final BlossomClient _blossomClient;
  final Future<Directory> Function() _supportDirectoryProvider;
  final List<ArFilterDefinition> _extraFilters;

  List<ArFilterDefinition> availableFilters() {
    return <ArFilterDefinition>[
      ...ArFilterCatalog.builtInFilters,
      ...GeneratedArFilterCatalog.communityFilters,
      ..._extraFilters,
    ];
  }

  ArFilterDefinition? definitionFor(String? id) {
    if (id == null || id == ArFilterCatalog.noneId) {
      return null;
    }
    for (final filter in availableFilters()) {
      if (filter.id == id) {
        return filter;
      }
    }
    return null;
  }

  Future<Set<String>> cachedFilterIds(List<ArFilterDefinition> filters) async {
    final cached = <String>{};
    for (final filter in filters) {
      if (await isFilterCached(filter)) {
        cached.add(filter.id);
      }
    }
    return cached;
  }

  Future<bool> isFilterCached(ArFilterDefinition filter) async {
    if (!filter.isDownloadable) {
      return true;
    }
    for (final part in filter.parts) {
      if (!part.isDownloadable) {
        continue;
      }
      final file = await _cacheFileForPart(filter, part);
      if (!await _isValidCachedFile(file, part)) {
        return false;
      }
    }
    return true;
  }

  Future<ArFilterDefinition> ensureFilterAvailable(String id) async {
    final filter = definitionFor(id);
    if (filter == null) {
      throw StateError('Unknown AR filter: $id.');
    }
    if (!filter.isDownloadable) {
      return filter;
    }

    final parts = <ArFilterPartDefinition>[];
    for (final part in filter.parts) {
      if (!part.isDownloadable) {
        parts.add(part);
        continue;
      }

      final target = await _cacheFileForPart(filter, part);
      if (!await _isValidCachedFile(target, part)) {
        final hash = part.blossomHash;
        if (hash == null || hash.isEmpty) {
          throw StateError(
            'AR filter ${filter.id} has no downloadable source.',
          );
        }
        final bytes = await _blossomClient.downloadBlob(
          hash: hash,
          servers: part.blossomServers.isEmpty
              ? AppConstants.defaultBlossomServers
              : part.blossomServers,
        );
        _verifyBytes(bytes, filter, part);
        await target.writeAsBytes(bytes, flush: true);
      }
      parts.add(part.copyWith(assetPath: target.path));
    }

    return filter.copyWith(parts: parts);
  }

  Future<ArFilterAsset?> loadFilter(
    String? id, {
    AssetBundle? assetBundle,
  }) async {
    if (id == null || id == ArFilterCatalog.noneId) {
      return null;
    }
    final filter = await ensureFilterAvailable(id);
    return ArFilterCatalog.loadDefinition(filter, assetBundle: assetBundle);
  }

  Future<File> _cacheFileForPart(
    ArFilterDefinition filter,
    ArFilterPartDefinition part,
  ) async {
    final root = await _supportDirectoryProvider();
    final directory = Directory(
      p.join(root.path, 'editor_ar_filters', filter.id),
    );
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    final hash = part.blossomHash ?? p.basenameWithoutExtension(part.assetPath);
    return File(p.join(directory.path, '$hash${_extensionForPart(part)}'));
  }

  Future<bool> _isValidCachedFile(
    File file,
    ArFilterPartDefinition part,
  ) async {
    if (!await file.exists()) {
      return false;
    }
    final expectedLength = part.byteLength;
    if (expectedLength != null && await file.length() != expectedLength) {
      return false;
    }
    final hash = part.blossomHash;
    if (hash == null || hash.isEmpty) {
      return true;
    }
    final digest = sha256.convert(await file.readAsBytes()).toString();
    return digest == hash;
  }

  void _verifyBytes(
    List<int> bytes,
    ArFilterDefinition filter,
    ArFilterPartDefinition part,
  ) {
    final expectedLength = part.byteLength;
    if (expectedLength != null && bytes.length != expectedLength) {
      throw StateError(
        'Downloaded AR filter length mismatch for ${filter.id}: '
        '${bytes.length} != $expectedLength.',
      );
    }
    final hash = part.blossomHash;
    if (hash != null && hash.isNotEmpty) {
      final digest = sha256.convert(bytes).toString();
      if (digest != hash) {
        throw StateError(
          'Downloaded AR filter hash mismatch for ${filter.id}.',
        );
      }
    }
  }

  String _extensionForPart(ArFilterPartDefinition part) {
    final existing = p.extension(part.assetPath);
    if (existing.isNotEmpty) {
      return existing;
    }
    return switch (part.mimeType) {
      'image/webp' => '.webp',
      'image/jpeg' => '.jpg',
      _ => '.png',
    };
  }
}

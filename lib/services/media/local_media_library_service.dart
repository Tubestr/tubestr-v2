import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalMediaLibraryService {
  LocalMediaLibraryService({
    Future<Directory> Function()? documentsDirectoryProvider,
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _documentsDirectoryProvider;
  final Future<Directory> Function() _supportDirectoryProvider;

  String? _cachedDocumentsPath;

  /// Resolves a stored absolute path to the current container path.
  ///
  /// On iOS the app container UUID changes on each update, so a path like
  /// `/var/mobile/Containers/Data/Application/OLD-UUID/Documents/videos/x.mp4`
  /// must be remapped to the current container. This extracts the relative
  /// portion after `Documents/` and re-prefixes with the live documents dir.
  Future<String> resolveLocalPath(String storedPath) async {
    if (storedPath.isEmpty) return storedPath;

    // If the file already exists at the stored path, no fixup needed.
    if (File(storedPath).existsSync()) return storedPath;

    // Extract relative portion after "Documents/"
    const marker = 'Documents/';
    final idx = storedPath.indexOf(marker);
    if (idx < 0) return storedPath;

    final relativePart = storedPath.substring(idx + marker.length);
    _cachedDocumentsPath ??=
        (await _documentsDirectoryProvider()).path;
    return p.join(_cachedDocumentsPath!, relativePart);
  }

  Future<Directory> ensureVideosDirectory() async {
    final documents = await _documentsDirectoryProvider();
    final directory = Directory(p.join(documents.path, 'videos'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> ensureThumbnailsDirectory() async {
    final documents = await _documentsDirectoryProvider();
    final directory = Directory(p.join(documents.path, 'thumbnails'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> ensureEditorStagingDirectory() async {
    final support = await _supportDirectoryProvider();
    final directory = Directory(p.join(support.path, 'editor_staging'));
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> createManagedVideoPath({
    String prefix = 'video',
    String extension = '.mp4',
  }) async {
    final videosDir = await ensureVideosDirectory();
    final normalizedExtension = extension.isEmpty
        ? '.mp4'
        : extension.toLowerCase();
    return p.join(
      videosDir.path,
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}$normalizedExtension',
    );
  }
}

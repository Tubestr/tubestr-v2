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

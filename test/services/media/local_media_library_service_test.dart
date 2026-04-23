import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/media/local_media_library_service.dart';

void main() {
  test(
    'cleanupEditorStagingDirectory removes stale staging children',
    () async {
      final tempRoot = await Directory.systemTemp.createTemp(
        'local-media-library-test',
      );
      addTearDown(() async {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      });

      final documentsDir = Directory('${tempRoot.path}/documents')
        ..createSync(recursive: true);
      final supportDir = Directory('${tempRoot.path}/support')
        ..createSync(recursive: true);
      final service = LocalMediaLibraryService(
        documentsDirectoryProvider: () async => documentsDir,
        supportDirectoryProvider: () async => supportDir,
      );
      final stagingDir = await service.ensureEditorStagingDirectory();
      final stale = Directory('${stagingDir.path}/ar_filter_old')
        ..createSync(recursive: true);
      final staleFrame = File('${stale.path}/filter_00000.png')
        ..writeAsStringSync('png');
      final fresh = Directory('${stagingDir.path}/ar_filter_fresh')
        ..createSync(recursive: true);
      final freshFrame = File('${fresh.path}/filter_00000.png')
        ..writeAsStringSync('png');

      final now = DateTime.utc(2026, 4, 21, 12);
      await staleFrame.setLastModified(now.subtract(const Duration(days: 3)));
      await freshFrame.setLastModified(now.subtract(const Duration(hours: 2)));

      await service.cleanupEditorStagingDirectory(
        maxAge: const Duration(days: 1),
        now: now,
      );

      expect(stale.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
    },
  );
}

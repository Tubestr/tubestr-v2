import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/editor_resources.dart';

class EditorStickerLibrary {
  EditorStickerLibrary({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<List<EditorStickerAsset>> listUserStickers({
    required String profileId,
  }) async {
    final dir = await _profileStickerDirectory(profileId);
    if (!await dir.exists()) {
      return const <EditorStickerAsset>[];
    }

    final files = await dir
        .list()
        .where(
          (entity) =>
              entity is File && entity.path.toLowerCase().endsWith('.png'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));

    return files
        .map(
          (file) => EditorStickerAsset(
            id: p.basenameWithoutExtension(file.path),
            assetPath: file.path,
            label: 'My Sticker',
            isUserCreated: true,
          ),
        )
        .toList(growable: false);
  }

  Future<EditorStickerAsset> saveStickerPng({
    required String profileId,
    required List<int> pngBytes,
  }) async {
    final dir = await _profileStickerDirectory(profileId);
    await dir.create(recursive: true);
    final id = _uuid.v4();
    final file = File(p.join(dir.path, '$id.png'));
    await file.writeAsBytes(pngBytes, flush: true);
    return EditorStickerAsset(
      id: id,
      assetPath: file.path,
      label: 'My Sticker',
      isUserCreated: true,
    );
  }

  Future<void> deleteSticker({
    required String profileId,
    required String stickerPath,
  }) async {
    final dir = await _profileStickerDirectory(profileId);
    if (!await dir.exists()) {
      return;
    }
    final file = File(stickerPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _profileStickerDirectory(String profileId) async {
    final root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'editor_stickers', profileId));
  }
}

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../domain/models/editor_resources.dart';
import '../blossom/blossom_client.dart';

class EditorAudioLibraryService {
  EditorAudioLibraryService({
    required BlossomClient blossomClient,
    Future<Directory> Function()? supportDirectoryProvider,
  }) : _blossomClient = blossomClient,
       _supportDirectoryProvider =
           supportDirectoryProvider ?? getApplicationSupportDirectory;

  final BlossomClient _blossomClient;
  final Future<Directory> Function() _supportDirectoryProvider;

  Future<String> ensureTrackAvailable(EditorMusicTrackAsset track) async {
    if (track.isBundledAsset) {
      return track.assetPath;
    }
    if (track.isCachedFile && await File(track.assetPath).exists()) {
      return track.assetPath;
    }

    final hash = track.blossomHash;
    if (hash == null || hash.isEmpty) {
      throw StateError('Audio track ${track.id} has no downloadable source.');
    }

    final target = await _cacheFileForHash(hash);
    if (await _isValidCachedFile(target, track)) {
      return target.path;
    }

    final bytes = await _blossomClient.downloadBlob(
      hash: hash,
      servers: track.blossomServers.isEmpty
          ? AppConstants.defaultBlossomServers
          : track.blossomServers,
    );
    _verifyBytes(bytes, track);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  Future<bool> isTrackCached(EditorMusicTrackAsset track) async {
    if (track.isBundledAsset) {
      return true;
    }
    if (track.isCachedFile) {
      return File(track.assetPath).exists();
    }
    final hash = track.blossomHash;
    if (hash == null || hash.isEmpty) {
      return false;
    }
    return _isValidCachedFile(await _cacheFileForHash(hash), track);
  }

  Future<Set<String>> cachedTrackIds(List<EditorMusicTrackAsset> tracks) async {
    final cached = <String>{};
    for (final track in tracks) {
      if (await isTrackCached(track)) {
        cached.add(track.id);
      }
    }
    return cached;
  }

  Future<File> _cacheFileForHash(String hash) async {
    final root = await _supportDirectoryProvider();
    final directory = Directory(p.join(root.path, 'editor_audio'));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return File(p.join(directory.path, '$hash.mp3'));
  }

  Future<bool> _isValidCachedFile(
    File file,
    EditorMusicTrackAsset track,
  ) async {
    if (!await file.exists()) {
      return false;
    }
    final expectedLength = track.byteLength;
    if (expectedLength != null && await file.length() != expectedLength) {
      return false;
    }
    final hash = track.blossomHash;
    if (hash == null || hash.isEmpty) {
      return true;
    }
    final digest = sha256.convert(await file.readAsBytes()).toString();
    return digest == hash;
  }

  void _verifyBytes(List<int> bytes, EditorMusicTrackAsset track) {
    final expectedLength = track.byteLength;
    if (expectedLength != null && bytes.length != expectedLength) {
      throw StateError(
        'Downloaded audio length mismatch for ${track.id}: '
        '${bytes.length} != $expectedLength.',
      );
    }
    final hash = track.blossomHash;
    if (hash != null && hash.isNotEmpty) {
      final digest = sha256.convert(bytes).toString();
      if (digest != hash) {
        throw StateError('Downloaded audio hash mismatch for ${track.id}.');
      }
    }
  }
}

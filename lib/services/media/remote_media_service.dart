import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/storage/app_database.dart';
import '../../domain/models/remote_share_projection.dart';
import '../blossom/blossom_client.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';

class DownloadedBlob {
  const DownloadedBlob({
    required this.bytes,
    required this.server,
  });

  final List<int> bytes;
  final String server;
}

class RemoteMediaService {
  RemoteMediaService({
    required AppDatabase database,
    required BlossomClient blossomClient,
    required MdkService mdkService,
    required NostrService nostrService,
    Future<Directory> Function()? supportDirectoryProvider,
  })  : _database = database,
        _blossomClient = blossomClient,
        _mdkService = mdkService,
        _nostrService = nostrService,
        _supportDirectoryProvider =
            supportDirectoryProvider ?? getApplicationSupportDirectory;

  final AppDatabase _database;
  final BlossomClient _blossomClient;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final Future<Directory> Function() _supportDirectoryProvider;

  Future<bool> hasValidCachedVideo(RemoteShareProjection share) async {
    final path = share.localMediaPath;
    if (path == null || path.isEmpty) {
      return false;
    }
    return _hasValidCachedFile(path: path, mimeType: share.mime ?? 'video/mp4');
  }

  Future<bool> hasValidCachedThumbnail(RemoteShareProjection share) async {
    final message = share.shareMessage;
    final thumbMime = message?.thumb.mime ?? 'image/jpeg';
    final path = share.localThumbPath;
    if (path == null || path.isEmpty) {
      return false;
    }
    return _hasValidCachedFile(path: path, mimeType: thumbMime);
  }

  Future<String> ensureVideoAvailable(
    RemoteShareProjection share, {
    bool forceRedownload = false,
  }) async {
    if (!forceRedownload && await hasValidCachedVideo(share)) {
      return share.localMediaPath!;
    }
    if (share.localMediaPath != null && share.localMediaPath!.isNotEmpty) {
      await _deleteIfPresent(share.localMediaPath!);
      await _database.clearRemoteMediaCachePath(
        remoteShareId: share.remoteShareId,
      );
    }
    return downloadVideo(share);
  }

  Future<String?> prefetchThumbnail(RemoteShareProjection share) async {
    if (await hasValidCachedThumbnail(share)) {
      return share.localThumbPath;
    }
    if (share.localThumbPath != null && share.localThumbPath!.isNotEmpty) {
      await _deleteIfPresent(share.localThumbPath!);
      await _database.clearRemoteThumbCachePath(
        remoteShareId: share.remoteShareId,
      );
    }

    final message = share.shareMessage;
    final thumb = message?.thumb;
    if (message == null || thumb == null) {
      return null;
    }
    if (thumb.originalHash == null ||
        thumb.nonce == null ||
        thumb.filename == null ||
        thumb.schemeVersion == null) {
      return null;
    }

    try {
      await _mdkService.ensureInitialized();
      final encrypted = await _downloadWithFallback(
        hash: thumb.hash,
        preferredServers: thumb.servers,
        senderPublicKeyHex: share.senderParentKey,
      );
      final decrypted = await _mdkService.decryptMedia(
        mlsGroupIdHex: share.mlsGroupId,
        encryptedBytes: encrypted.bytes,
        originalHashHex: thumb.originalHash!,
        mimeType: thumb.mime,
        filename: thumb.filename!,
        nonceHex: thumb.nonce!,
        schemeVersion: thumb.schemeVersion!,
        url: '${encrypted.server}/${thumb.hash}',
      );
      final target = await _cacheFile(
        folder: 'thumbs',
        remoteShareId: share.remoteShareId,
        extension: _extensionForMime(thumb.mime, fallback: '.jpg'),
      );
      await target.writeAsBytes(decrypted, flush: true);
      await _verifyCachedFile(
        path: target.path,
        mimeType: thumb.mime,
        label: 'thumbnail',
      );
      await _database.updateRemoteAssetCache(
        remoteShareId: share.remoteShareId,
        localThumbPath: target.path,
      );
      return target.path;
    } catch (_) {
      return null;
    }
  }

  Future<String> downloadVideo(RemoteShareProjection share) async {
    final message = share.shareMessage;
    final blob = message?.blob;
    if (message == null || blob == null) {
      throw StateError('Share payload is missing media metadata.');
    }
    if (blob.originalHash == null ||
        blob.nonce == null ||
        blob.filename == null ||
        blob.schemeVersion == null) {
      throw StateError('Share payload is missing MIP-04 reference fields.');
    }

    await _database.updateRemoteShareStatus(
      remoteShareId: share.remoteShareId,
      status: 'downloading',
      downloadError: null,
    );

    try {
      await _mdkService.ensureInitialized();
      final encrypted = await _downloadWithFallback(
        hash: blob.hash,
        preferredServers: blob.servers,
        senderPublicKeyHex: share.senderParentKey,
      );
      final decrypted = await _mdkService.decryptMedia(
        mlsGroupIdHex: share.mlsGroupId,
        encryptedBytes: encrypted.bytes,
        originalHashHex: blob.originalHash!,
        mimeType: blob.mime,
        filename: blob.filename!,
        nonceHex: blob.nonce!,
        schemeVersion: blob.schemeVersion!,
        url: '${encrypted.server}/${blob.hash}',
      );

      final mediaTarget = await _cacheFile(
        folder: 'videos',
        remoteShareId: share.remoteShareId,
        extension: _extensionForMime(blob.mime, fallback: '.bin'),
      );
      await mediaTarget.writeAsBytes(decrypted, flush: true);
      await _verifyCachedFile(
        path: mediaTarget.path,
        mimeType: blob.mime,
        label: 'video',
      );

      final thumbPath = await prefetchThumbnail(share);
      await _database.updateRemoteAssetCache(
        remoteShareId: share.remoteShareId,
        localMediaPath: mediaTarget.path,
        localThumbPath: thumbPath ?? share.localThumbPath,
      );
      await _database.updateRemoteShareStatus(
        remoteShareId: share.remoteShareId,
        status: 'downloaded',
        downloadError: null,
      );
      return mediaTarget.path;
    } catch (error) {
      await _database.updateRemoteShareStatus(
        remoteShareId: share.remoteShareId,
        status: 'failed',
        downloadError: '$error',
      );
      rethrow;
    }
  }

  Future<File> _cacheFile({
    required String folder,
    required String remoteShareId,
    required String extension,
  }) async {
    final root = await _supportDirectoryProvider();
    final dir = Directory(p.join(root.path, 'remote_cache', folder));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, '$remoteShareId$extension'));
  }

  String _extensionForMime(String mimeType, {required String fallback}) {
    final lower = mimeType.toLowerCase();
    if (lower == 'video/mp4') {
      return '.mp4';
    }
    if (lower == 'image/jpeg') {
      return '.jpg';
    }
    if (lower == 'image/png') {
      return '.png';
    }
    return fallback;
  }

  Future<DownloadedBlob> _downloadWithFallback({
    required String hash,
    required List<String> preferredServers,
    required String senderPublicKeyHex,
  }) async {
    try {
      return await _downloadFromServers(hash: hash, servers: preferredServers);
    } catch (_) {
      final fallbackServers = await _nostrService.fetchBlossomServerList(
        publicKeyHex: senderPublicKeyHex,
      );
      final retryServers = fallbackServers
          .where((server) => !preferredServers.contains(server))
          .toList(growable: false);
      if (retryServers.isEmpty) {
        rethrow;
      }
      return _downloadFromServers(hash: hash, servers: retryServers);
    }
  }

  Future<DownloadedBlob> _downloadFromServers({
    required String hash,
    required List<String> servers,
  }) async {
    Object? lastError;
    for (final server in servers) {
      try {
        final bytes = await _blossomClient.downloadBlob(
          hash: hash,
          servers: [server],
        );
        return DownloadedBlob(bytes: bytes, server: server);
      } catch (error) {
        lastError = error;
      }
    }

    throw lastError ?? StateError('Unable to download blob $hash');
  }

  Future<void> _deleteIfPresent(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _verifyCachedFile({
    required String path,
    required String mimeType,
    required String label,
  }) async {
    final valid = await _hasValidCachedFile(path: path, mimeType: mimeType);
    if (!valid) {
      await _deleteIfPresent(path);
      throw StateError('Downloaded $label did not match expected $mimeType.');
    }
  }

  Future<bool> _hasValidCachedFile({
    required String path,
    required String mimeType,
  }) async {
    final file = File(path);
    if (!await file.exists()) {
      return false;
    }
    final length = await file.length();
    if (length <= 0) {
      return false;
    }
    final header = await _readHeaderBytes(file, maxBytes: 16);
    final lowerMime = mimeType.toLowerCase();
    if (lowerMime == 'video/mp4') {
      return header.length >= 8 &&
          header[4] == 0x66 &&
          header[5] == 0x74 &&
          header[6] == 0x79 &&
          header[7] == 0x70;
    }
    if (lowerMime == 'image/jpeg') {
      return header.length >= 3 &&
          header[0] == 0xFF &&
          header[1] == 0xD8 &&
          header[2] == 0xFF;
    }
    if (lowerMime == 'image/png') {
      const pngHeader = <int>[0x89, 0x50, 0x4E, 0x47];
      return header.length >= pngHeader.length &&
          pngHeader.asMap().entries.every(
            (entry) => header[entry.key] == entry.value,
          );
    }
    return true;
  }

  Future<List<int>> _readHeaderBytes(File file, {required int maxBytes}) async {
    final stream = file.openRead(0, maxBytes);
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
      if (chunks.length >= maxBytes) {
        break;
      }
    }
    return chunks;
  }
}

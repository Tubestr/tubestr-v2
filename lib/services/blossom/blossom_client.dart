import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class UploadedBlob {
  const UploadedBlob({
    required this.hash,
    required this.length,
    required this.server,
  });

  final String hash;
  final int length;
  final String server;
}

class BlossomClient {
  BlossomClient(this._dio);

  final Dio _dio;

  Future<List<String>> loadServerList({
    Future<String?> Function(String key)? readSetting,
  }) async {
    if (readSetting == null) {
      return const [];
    }
    final raw = await readSetting('blossom_server_list');
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    return raw
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<UploadedBlob> uploadEncryptedBlob({
    required String server,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final hash = sha256.convert(bytes).toString();

    await _dio.put<void>(
      '$server/$hash',
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {'content-type': mimeType},
      ),
    );

    return UploadedBlob(hash: hash, length: bytes.length, server: server);
  }

  Future<List<int>> downloadBlob({
    required String hash,
    required List<String> servers,
  }) async {
    Object? lastError;
    for (final server in servers) {
      final normalized = server.endsWith('/') ? server.substring(0, server.length - 1) : server;
      try {
        final response = await _dio.get<List<int>>(
          '$normalized/$hash',
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );
        final bytes = response.data;
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Unable to download blob $hash: ${lastError ?? 'no servers configured'}');
  }

  Future<void> reportBlob({
    required String server,
    required String eventJson,
  }) async {
    final normalized = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    await _dio.put<void>(
      '$normalized/report',
      data: eventJson,
      options: Options(
        headers: {'content-type': 'application/json'},
      ),
    );
  }
}

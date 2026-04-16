import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

class BlossomUploadAuth {
  const BlossomUploadAuth({required this.authorizationHeaderValue});

  final String authorizationHeaderValue;
}

typedef BlossomUploadAuthForServer =
    Future<BlossomUploadAuth?> Function(String server);

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

class BlossomUploadException implements Exception {
  const BlossomUploadException({
    required this.server,
    required this.statusCode,
    required this.message,
  });

  final String server;
  final int? statusCode;
  final String message;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' ($statusCode)';
    return 'Blossom upload failed$status for $server: $message';
  }
}

class MirroredUploadedBlob {
  const MirroredUploadedBlob({
    required this.hash,
    required this.length,
    required this.primaryServer,
    required this.servers,
  });

  final String hash;
  final int length;
  final String primaryServer;
  final List<String> servers;
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
    BlossomUploadAuth? auth,
  }) async {
    final hash = sha256.convert(bytes).toString();
    final normalized = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    final headers = <String, Object>{
      'content-type': mimeType,
      'content-length': bytes.length,
      'x-content-type': mimeType,
      'x-content-length': '${bytes.length}',
      'x-sha-256': hash,
      if (auth != null) 'authorization': auth.authorizationHeaderValue,
    };

    try {
      if (auth != null) {
        await _checkUploadAccepted(
          server: normalized,
          hash: hash,
          length: bytes.length,
          mimeType: mimeType,
          auth: auth,
        );
      }
      await _dio.put<void>(
        '$normalized/upload',
        data: bytes,
        options: Options(headers: headers),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode != 404) {
        throw _uploadException(server: server, error: error);
      }
      await _dio.put<void>(
        '$normalized/$hash',
        data: bytes,
        options: Options(
          headers: {
            'content-type': mimeType,
            'content-length': bytes.length,
            if (auth != null) 'authorization': auth.authorizationHeaderValue,
          },
        ),
      );
    }

    return UploadedBlob(hash: hash, length: bytes.length, server: server);
  }

  Future<void> _checkUploadAccepted({
    required String server,
    required String hash,
    required int length,
    required String mimeType,
    required BlossomUploadAuth auth,
  }) async {
    try {
      final response = await _dio.head<void>(
        '$server/upload',
        options: Options(
          validateStatus: (_) => true,
          headers: {
            'authorization': auth.authorizationHeaderValue,
            'x-content-type': mimeType,
            'x-content-length': '$length',
            'x-sha-256': hash,
          },
        ),
      );
      final statusCode = response.statusCode;
      if (statusCode == null || (statusCode >= 200 && statusCode < 300)) {
        return;
      }
      if (statusCode == 404 || statusCode == 405) {
        return;
      }
      final reason = _responseReason(response);
      throw BlossomUploadException(
        server: server,
        statusCode: statusCode,
        message: reason.isEmpty ? 'Upload rejected before sending.' : reason,
      );
    } on DioException catch (error) {
      throw _uploadException(server: server, error: error);
    }
  }

  Future<MirroredUploadedBlob> uploadEncryptedBlobWithMirrors({
    required List<String> servers,
    required List<int> bytes,
    required String mimeType,
    BlossomUploadAuth? auth,
    BlossomUploadAuthForServer? authForServer,
  }) async {
    final normalizedServers = servers
        .map((server) => server.trim())
        .where((server) => server.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalizedServers.isEmpty) {
      throw const FormatException('At least one Blossom server is required.');
    }

    UploadedBlob? primaryUpload;
    final successfulServers = <String>[];
    Object? lastError;
    for (final server in normalizedServers) {
      try {
        final serverAuth = authForServer == null
            ? auth
            : await authForServer(server);
        final upload = await uploadEncryptedBlob(
          server: server,
          bytes: bytes,
          mimeType: mimeType,
          auth: serverAuth,
        );
        primaryUpload ??= upload;
        successfulServers.add(upload.server);
      } catch (error) {
        lastError = error;
      }
    }

    if (primaryUpload == null) {
      throw StateError(
        'Unable to upload blob to any configured Blossom server: '
        '${lastError ?? 'no servers configured'}',
      );
    }

    return MirroredUploadedBlob(
      hash: primaryUpload.hash,
      length: primaryUpload.length,
      primaryServer: primaryUpload.server,
      servers: successfulServers,
    );
  }

  Future<List<int>> downloadBlob({
    required String hash,
    required List<String> servers,
  }) async {
    Object? lastError;
    for (final server in servers) {
      final normalized = server.endsWith('/')
          ? server.substring(0, server.length - 1)
          : server;
      try {
        final response = await _dio.get<List<int>>(
          '$normalized/$hash',
          options: Options(responseType: ResponseType.bytes),
        );
        final bytes = response.data;
        if (bytes != null && bytes.isNotEmpty) {
          return bytes;
        }
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError(
      'Unable to download blob $hash: ${lastError ?? 'no servers configured'}',
    );
  }

  BlossomUploadException _uploadException({
    required String server,
    required DioException error,
  }) {
    final response = error.response;
    final reason = response == null ? error.message : _responseReason(response);
    return BlossomUploadException(
      server: server,
      statusCode: response?.statusCode,
      message: reason?.isNotEmpty == true ? reason! : error.toString(),
    );
  }

  String _responseReason(Response<dynamic> response) {
    final headerReason = response.headers.value('x-reason');
    if (headerReason != null && headerReason.trim().isNotEmpty) {
      return headerReason.trim();
    }
    final body = response.data;
    if (body == null) {
      return '';
    }
    if (body is String) {
      return body.trim();
    }
    return body.toString();
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
      options: Options(headers: {'content-type': 'application/json'}),
    );
  }

  Future<void> deleteBlob({
    required String server,
    required String hash,
    BlossomUploadAuth? auth,
  }) async {
    final normalized = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    await _dio.delete<void>(
      '$normalized/$hash',
      options: Options(
        headers: {
          if (auth != null) 'authorization': auth.authorizationHeaderValue,
        },
      ),
    );
  }
}

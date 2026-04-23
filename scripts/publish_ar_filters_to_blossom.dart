import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ndk/data_layer/models/nip_01_event_model.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_01_utils.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart' as bip340;
import 'package:ndk/shared/nips/nip01/helpers.dart';

const _defaultServer = 'https://blossom.tubestr.app';
const _defaultOutput = 'lib/services/editor/generated_ar_filter_catalog.dart';
const _sampleManifest = 'build/ar_filters/publish_manifest.json';

Future<void> main(List<String> args) async {
  final manifestArg = _argValue(args, '--manifest');
  final generateOnly = args.contains('--generate-only');
  if (manifestArg == null || manifestArg.trim().isEmpty) {
    stderr.writeln(
      'Usage: dart run scripts/publish_ar_filters_to_blossom.dart '
      '--manifest $_sampleManifest [--server $_defaultServer]',
    );
    stderr.writeln(
      'Create it from curated source assets by running '
      '`python3 scripts/import_ar_filter_assets.py` first.',
    );
    exitCode = 64;
    return;
  }

  final nsec = Platform.environment['AR_FILTER_PUBLISH_NSEC'];
  if (!generateOnly && (nsec == null || nsec.trim().isEmpty)) {
    stderr.writeln(
      'Set AR_FILTER_PUBLISH_NSEC to an nsec or 64-character private key.',
    );
    exitCode = 64;
    return;
  }

  final manifestFile = File(manifestArg);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing AR filter manifest: ${manifestFile.path}');
    stderr.writeln(
      'Run `python3 scripts/import_ar_filter_assets.py` to create it, or pass '
      'a publish manifest to --manifest.',
    );
    exitCode = 66;
    return;
  }

  final server = _argValue(args, '--server') ?? _defaultServer;
  final outputFile = File(_argValue(args, '--out') ?? _defaultOutput);
  final privateKeyHex = generateOnly ? null : _decodePrivateKeyHex(nsec!);
  final publicKeyHex = privateKeyHex == null
      ? null
      : bip340.Bip340.getPublicKey(privateKeyHex);
  final filters = (jsonDecode(await manifestFile.readAsString()) as List)
      .cast<Map<String, Object?>>();
  final manifestDir = manifestFile.parent;

  final publishedFilters = <Map<String, Object?>>[];
  var uploaded = 0;
  var skipped = 0;

  for (final filter in filters) {
    final label = (filter['label'] as String?) ?? filter['id'] as String;
    final parts = (filter['parts'] as List).cast<Map<String, Object?>>();
    final publishedParts = <Map<String, Object?>>[];

    for (final part in parts) {
      final rawPath = part['path'] as String? ?? part['assetPath'] as String?;
      if (rawPath == null || rawPath.trim().isEmpty) {
        throw StateError('Filter $label has a part without a path.');
      }
      final file = File(rawPath).isAbsolute
          ? File(rawPath)
          : File('${manifestDir.path}/$rawPath');
      if (!file.existsSync()) {
        throw StateError('Missing AR asset for $label: ${file.path}');
      }

      final bytes = await file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final mimeType = _mimeTypeForPath(file.path);
      if (generateOnly) {
        skipped += 1;
      } else if (await _blobExists(server: server, hash: hash)) {
        skipped += 1;
      } else {
        final auth = _createUploadAuth(
          privateKeyHex: privateKeyHex!,
          publicKeyHex: publicKeyHex!,
          server: server,
          hashHex: hash,
        );
        await _uploadBlob(
          server: server,
          hash: hash,
          bytes: bytes,
          mimeType: mimeType,
          authHeader: auth,
        );
        uploaded += 1;
      }

      publishedParts.add(
        {
          ...part,
          'assetPath': file.uri.pathSegments.last,
          'blossomHash': hash,
          'byteLength': bytes.length,
          'mimeType': mimeType,
          'blossomServers': [server],
        }..remove('path'),
      );
    }

    publishedFilters.add({...filter, 'parts': publishedParts});
    stdout.writeln('ready    $label');
  }

  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(_buildGeneratedDart(publishedFilters));
  stdout.writeln(
    '${generateOnly ? 'Prepared' : 'Published'} $uploaded AR asset(s), '
    'skipped $skipped existing. '
    'Wrote ${outputFile.path}.',
  );
}

String _buildGeneratedDart(List<Map<String, Object?>> filters) {
  final buffer = StringBuffer()
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln()
    ..writeln("import 'ar_filter_catalog.dart';")
    ..writeln()
    ..writeln('class GeneratedArFilterCatalog {')
    ..writeln('  const GeneratedArFilterCatalog._();')
    ..writeln()
    ..writeln('  static const communityFilters = <ArFilterDefinition>[');

  for (final filter in filters) {
    buffer
      ..writeln('    ArFilterDefinition(')
      ..writeln("      id: ${_quoted(filter['id'])},")
      ..writeln("      label: ${_quoted(filter['label'])},")
      ..writeln(
        "      category: ${_quoted(filter['category'] ?? 'featured')},",
      );
    if (filter['description'] != null) {
      buffer.writeln("      description: ${_quoted(filter['description'])},");
    }
    for (final field in const [
      'thumbnailPath',
      'sourceName',
      'sourceUrl',
      'license',
      'licenseUrl',
      'attribution',
    ]) {
      final value = filter[field];
      if (value is String && value.trim().isNotEmpty) {
        buffer.writeln("      $field: ${_quoted(value)},");
      }
    }
    buffer.writeln('      parts: <ArFilterPartDefinition>[');
    for (final part in (filter['parts'] as List).cast<Map<String, Object?>>()) {
      buffer
        ..writeln('        ArFilterPartDefinition(')
        ..writeln("          assetPath: ${_quoted(part['assetPath'])},")
        ..writeln(
          '          anchor: ArFilterAnchor.${_validatedAnchor(part['anchor'])},',
        )
        ..writeln('          widthScale: ${part['widthScale']},')
        ..writeln(
          '          offset: Offset(${part['offsetX'] ?? 0}, ${part['offsetY'] ?? 0}),',
        )
        ..writeln('          rotationDegrees: ${part['rotationDegrees'] ?? 0},')
        ..writeln('          opacity: ${part['opacity'] ?? 1},')
        ..writeln("          blossomHash: ${_quoted(part['blossomHash'])},")
        ..writeln('          byteLength: ${part['byteLength']},')
        ..writeln("          mimeType: ${_quoted(part['mimeType'])},")
        ..writeln('          blossomServers: <String>[')
        ..writeln(
          "            ${_quoted((part['blossomServers'] as List).first)},",
        )
        ..writeln('          ],')
        ..writeln('        ),');
    }
    buffer
      ..writeln('      ],')
      ..writeln('    ),');
  }

  buffer
    ..writeln('  ];')
    ..writeln('}');
  return buffer.toString();
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index == args.length - 1) {
    return null;
  }
  return args[index + 1];
}

String _quoted(Object? value) {
  // jsonEncode handles \" \\ \n etc. but not Dart's $ interpolation — escape
  // it so generated catalog code doesn't accidentally interpolate variables.
  return jsonEncode(value?.toString() ?? '').replaceAll(r'$', r'\$');
}

const _arFilterAnchorNames = <String>{
  'eyesBridge',
  'forehead',
  'noseTip',
  'mouthCenter',
  'leftEye',
  'rightEye',
};

String _validatedAnchor(Object? raw) {
  final name = raw?.toString() ?? '';
  if (!_arFilterAnchorNames.contains(name)) {
    throw StateError(
      'Unknown AR filter anchor: "$name". Expected one of $_arFilterAnchorNames.',
    );
  }
  return name;
}

String _mimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'image/png';
}

String _decodePrivateKeyHex(String rawInput) {
  final normalized = rawInput
      .trim()
      .replaceFirst(RegExp(r'^nostr:', caseSensitive: false), '')
      .replaceAll(RegExp(r'\s+'), '');
  if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(normalized)) {
    return normalized.toLowerCase();
  }

  final decoded = Helpers.decodeBech32(normalized.toLowerCase());
  final privateKeyHex = decoded.first;
  final hrp = decoded.length > 1 ? decoded[1] : '';
  if (hrp == 'nsec' && RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(privateKeyHex)) {
    return privateKeyHex.toLowerCase();
  }
  throw const FormatException('Expected an nsec or 64-character private key.');
}

String _createUploadAuth({
  required String privateKeyHex,
  required String publicKeyHex,
  required String server,
  required String hashHex,
}) {
  final normalized = _normalizeServer(server);
  final host = Uri.parse(normalized).host.toLowerCase();
  final uploadUrl = '$normalized/upload';
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final createdAt = now - const Duration(minutes: 5).inSeconds;
  final expiresAt = now + const Duration(minutes: 10).inSeconds;
  final event = Nip01Event(
    pubKey: publicKeyHex,
    createdAt: createdAt,
    kind: 24242,
    content: 'Authorize Blossom upload',
    tags: [
      ['t', 'upload'],
      ['x', hashHex],
      ['server', host],
      ['u', uploadUrl],
      ['method', 'PUT'],
      ['expiration', '$expiresAt'],
    ],
  );
  final signed = Nip01Utils.signWithPrivateKey(
    event: event,
    privateKey: privateKeyHex,
  );
  final eventJson = Nip01EventModel.fromEntity(signed).toJsonString();
  final encoded = base64Url.encode(utf8.encode(eventJson)).replaceAll('=', '');
  return 'Nostr $encoded';
}

Future<bool> _blobExists({required String server, required String hash}) async {
  final client = HttpClient();
  try {
    final request = await client.headUrl(
      Uri.parse('${_normalizeServer(server)}/$hash'),
    );
    final response = await request.close();
    return response.statusCode == HttpStatus.ok;
  } finally {
    client.close(force: true);
  }
}

Future<void> _uploadBlob({
  required String server,
  required String hash,
  required List<int> bytes,
  required String mimeType,
  required String authHeader,
}) async {
  final client = HttpClient();
  try {
    final request = await client.putUrl(
      Uri.parse('${_normalizeServer(server)}/upload'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, authHeader);
    request.headers.set(HttpHeaders.contentTypeHeader, mimeType);
    request.headers.set(HttpHeaders.contentLengthHeader, bytes.length);
    request.headers.set('x-content-type', mimeType);
    request.headers.set('x-content-length', '${bytes.length}');
    request.headers.set('x-sha-256', hash);
    request.add(bytes);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await utf8.decodeStream(response);
      throw HttpException(
        'Blossom upload failed (${response.statusCode}): $body',
      );
    }
  } finally {
    client.close(force: true);
  }
}

String _normalizeServer(String server) {
  final trimmed = server.trim();
  return trimmed.endsWith('/')
      ? trimmed.substring(0, trimmed.length - 1)
      : trimmed;
}

import 'dart:convert';
import 'dart:io';

import 'package:ndk/data_layer/models/nip_01_event_model.dart';
import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/domain_layer/entities/nip_01_utils.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart' as bip340;
import 'package:ndk/shared/nips/nip01/helpers.dart';

const _defaultServer = 'https://blossom.tubestr.app';
const _manifestPath = 'build/editor_music/publish_manifest.json';

Future<void> main(List<String> args) async {
  final server = _argValue(args, '--server') ?? _defaultServer;
  final nsec = Platform.environment['EDITOR_AUDIO_PUBLISH_NSEC'];
  if (nsec == null || nsec.trim().isEmpty) {
    stderr.writeln(
      'Set EDITOR_AUDIO_PUBLISH_NSEC to an nsec or 64-character private key.',
    );
    exitCode = 64;
    return;
  }

  final manifestFile = File(_argValue(args, '--manifest') ?? _manifestPath);
  if (!manifestFile.existsSync()) {
    stderr.writeln('Missing publish manifest: ${manifestFile.path}');
    stderr.writeln('Run `python3 scripts/import_editor_music.py` first.');
    exitCode = 66;
    return;
  }

  final privateKeyHex = _decodePrivateKeyHex(nsec);
  final publicKeyHex = bip340.Bip340.getPublicKey(privateKeyHex);
  final tracks = (jsonDecode(await manifestFile.readAsString()) as List)
      .cast<Map<String, Object?>>();

  var uploaded = 0;
  var skipped = 0;
  for (final track in tracks) {
    final hash = track['blossom_hash'] as String;
    final path = track['staged_path'] as String;
    final label = track['label'] as String;
    final file = File(path);
    if (!file.existsSync()) {
      throw StateError('Missing staged audio for $label: $path');
    }

    if (await _blobExists(server: server, hash: hash)) {
      stdout.writeln('ready    $label');
      skipped += 1;
      continue;
    }

    final bytes = await file.readAsBytes();
    final auth = _createUploadAuth(
      privateKeyHex: privateKeyHex,
      publicKeyHex: publicKeyHex,
      server: server,
      hashHex: hash,
    );
    await _uploadBlob(
      server: server,
      hash: hash,
      bytes: bytes,
      authHeader: auth,
    );
    stdout.writeln('uploaded $label');
    uploaded += 1;
  }

  stdout.writeln('Published $uploaded track(s), skipped $skipped existing.');
}

String? _argValue(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index == args.length - 1) {
    return null;
  }
  return args[index + 1];
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
  required String authHeader,
}) async {
  final client = HttpClient();
  try {
    final request = await client.putUrl(
      Uri.parse('${_normalizeServer(server)}/upload'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, authHeader);
    request.headers.set(HttpHeaders.contentTypeHeader, 'audio/mpeg');
    request.headers.set(HttpHeaders.contentLengthHeader, bytes.length);
    request.headers.set('x-content-type', 'audio/mpeg');
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

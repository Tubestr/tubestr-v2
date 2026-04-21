import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/editor_resources.dart';
import 'package:mytube/services/editor/editor_audio_library_service.dart';

import '../../test_support/service_fakes.dart';

void main() {
  late Directory tempDir;
  late FakeBlossomClient blossom;
  late EditorAudioLibraryService service;

  String sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('audio-lib-test-');
    blossom = FakeBlossomClient(unavailableServer: 'unused');
    service = EditorAudioLibraryService(
      blossomClient: blossom,
      supportDirectoryProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('bundled asset returns assetPath without downloading', () async {
    const track = EditorMusicTrackAsset(
      id: 'bundled-track',
      label: 'Bundled Track',
      assetPath: 'assets/editor/music/track_01.mp3',
    );

    final result = await service.ensureTrackAvailable(track);

    expect(result, 'assets/editor/music/track_01.mp3');
    expect(blossom.downloadedHashes, isEmpty);
  });

  test('valid cache hit skips download', () async {
    final bytes = [1, 2, 3, 4, 5];
    final hash = sha256Hex(bytes);

    final cacheDir = Directory('${tempDir.path}/editor_audio');
    await cacheDir.create(recursive: true);
    final cacheFile = File('${cacheDir.path}/$hash.mp3');
    await cacheFile.writeAsBytes(bytes);

    final track = EditorMusicTrackAsset(
      id: 'cached-track',
      label: 'Cached Track',
      blossomHash: hash,
      byteLength: 5,
    );

    final result = await service.ensureTrackAvailable(track);

    expect(result, endsWith('$hash.mp3'));
    expect(blossom.downloadedHashes, isEmpty);
  });

  test('cold cache triggers download and write', () async {
    final bytes = [10, 20, 30];
    final hash = sha256Hex(bytes);
    blossom.downloadResult = bytes;

    final track = EditorMusicTrackAsset(
      id: 'download-track',
      label: 'Download Track',
      blossomHash: hash,
      byteLength: 3,
      blossomServers: const ['https://blossom.example'],
    );

    final result = await service.ensureTrackAvailable(track);

    expect(blossom.downloadedHashes, [hash]);
    expect(result, endsWith('$hash.mp3'));
    expect(await File(result).exists(), isTrue);
    expect(await File(result).readAsBytes(), bytes);
  });

  test('stale cache (wrong length) re-downloads', () async {
    final bytes = [10, 20, 30];
    final hash = sha256Hex(bytes);
    blossom.downloadResult = bytes;

    final cacheDir = Directory('${tempDir.path}/editor_audio');
    await cacheDir.create(recursive: true);
    final cacheFile = File('${cacheDir.path}/$hash.mp3');
    await cacheFile.writeAsBytes([0, 0]);

    final track = EditorMusicTrackAsset(
      id: 'stale-track',
      label: 'Stale Track',
      blossomHash: hash,
      byteLength: 3,
      blossomServers: const ['https://blossom.example'],
    );

    final result = await service.ensureTrackAvailable(track);

    expect(blossom.downloadedHashes, [hash]);
    expect(await File(result).readAsBytes(), bytes);
  });

  test('hash mismatch throws StateError', () async {
    final wrongBytes = [0xFF, 0xFF, 0xFF];
    final expectedHash = sha256Hex([10, 20, 30]);
    blossom.downloadResult = wrongBytes;

    final track = EditorMusicTrackAsset(
      id: 'bad-hash-track',
      label: 'Bad Hash Track',
      blossomHash: expectedHash,
      blossomServers: const ['https://blossom.example'],
    );

    await expectLater(
      service.ensureTrackAvailable(track),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('hash mismatch'),
        ),
      ),
    );
  });

  test('length mismatch throws StateError', () async {
    final bytes = [1, 2, 3, 4, 5];
    blossom.downloadResult = bytes;

    final track = EditorMusicTrackAsset(
      id: 'bad-length-track',
      label: 'Bad Length Track',
      blossomHash: sha256Hex(bytes),
      byteLength: 3,
      blossomServers: const ['https://blossom.example'],
    );

    await expectLater(
      service.ensureTrackAvailable(track),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('length mismatch'),
        ),
      ),
    );
  });

  test('isTrackCached returns true for bundled', () async {
    const track = EditorMusicTrackAsset(
      id: 'bundled',
      label: 'Bundled',
      assetPath: 'assets/editor/music/track.mp3',
    );

    expect(await service.isTrackCached(track), isTrue);
  });

  test('isTrackCached returns false when file absent', () async {
    final track = EditorMusicTrackAsset(
      id: 'missing',
      label: 'Missing',
      blossomHash: sha256Hex([1, 2, 3]),
    );

    expect(await service.isTrackCached(track), isFalse);
  });

  test('cachedTrackIds returns correct subset', () async {
    final bytes = [1, 2, 3];
    final hash = sha256Hex(bytes);

    final cacheDir = Directory('${tempDir.path}/editor_audio');
    await cacheDir.create(recursive: true);
    await File('${cacheDir.path}/$hash.mp3').writeAsBytes(bytes);

    const trackA = EditorMusicTrackAsset(
      id: 'bundled',
      label: 'Bundled',
      assetPath: 'assets/editor/music/track.mp3',
    );
    final trackB = EditorMusicTrackAsset(
      id: 'cached',
      label: 'Cached',
      blossomHash: hash,
      byteLength: 3,
    );
    final trackC = EditorMusicTrackAsset(
      id: 'missing',
      label: 'Missing',
      blossomHash: sha256Hex([9, 9, 9]),
    );

    final cached = await service.cachedTrackIds([trackA, trackB, trackC]);

    expect(cached, containsAll(['bundled', 'cached']));
    expect(cached, isNot(contains('missing')));
  });

  test('track with no hash and no assetPath throws', () async {
    const track = EditorMusicTrackAsset(id: 'no-source', label: 'No Source');

    await expectLater(
      service.ensureTrackAvailable(track),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('no downloadable source'),
        ),
      ),
    );
  });
}

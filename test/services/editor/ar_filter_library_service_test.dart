import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/blossom/blossom_client.dart';
import 'package:mytube/services/editor/ar_filter_catalog.dart';
import 'package:mytube/services/editor/ar_filter_library_service.dart';

class _FakeBlossomClient extends BlossomClient {
  _FakeBlossomClient(this.bytes) : super(Dio());

  final List<int> bytes;
  int downloads = 0;

  @override
  Future<List<int>> downloadBlob({
    required String hash,
    required List<String> servers,
  }) async {
    downloads += 1;
    return bytes;
  }
}

void main() {
  test('downloads, verifies, and caches remote AR filter parts', () async {
    final tempRoot = await Directory.systemTemp.createTemp('ar-filter-cache-');
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    final bytes = <int>[1, 2, 3, 4];
    final hash = sha256.convert(bytes).toString();
    final blossom = _FakeBlossomClient(bytes);
    final service = ArFilterLibraryService(
      blossomClient: blossom,
      supportDirectoryProvider: () async => tempRoot,
      extraFilters: [
        ArFilterDefinition(
          id: 'remote-crown',
          label: 'Remote Crown',
          parts: [
            ArFilterPartDefinition(
              assetPath: 'remote-crown.png',
              anchor: ArFilterAnchor.forehead,
              widthScale: 1.0,
              offset: Offset.zero,
              blossomHash: hash,
              byteLength: bytes.length,
              blossomServers: const ['https://blossom.example'],
            ),
          ],
        ),
      ],
    );

    expect(
      await service.cachedFilterIds(service.availableFilters()),
      isNot(contains('remote-crown')),
    );

    final local = await service.ensureFilterAvailable('remote-crown');

    expect(blossom.downloads, 1);
    expect(local.parts.single.assetPath, endsWith('$hash.png'));
    expect(await File(local.parts.single.assetPath).readAsBytes(), bytes);
    expect(
      await service.cachedFilterIds(service.availableFilters()),
      contains('remote-crown'),
    );

    await service.ensureFilterAvailable('remote-crown');
    expect(blossom.downloads, 1);
  });
}

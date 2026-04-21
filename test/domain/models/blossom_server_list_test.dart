import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/blossom_server_list.dart';

void main() {
  group('BlossomServerList serialization', () {
    test('encode/decode round-trips servers and updatedAt', () {
      final list = BlossomServerList(
        servers: const ['https://blossom1.example', 'https://blossom2.example'],
        updatedAt: DateTime.utc(2026, 4, 15, 12, 0, 0),
      );
      final decoded = BlossomServerList.decode(list.encode());

      expect(decoded.servers, hasLength(2));
      expect(decoded.servers[0], 'https://blossom1.example');
      expect(decoded.servers[1], 'https://blossom2.example');
      expect(decoded.updatedAt, DateTime.utc(2026, 4, 15, 12, 0, 0));
    });

    test('decode handles legacy plain-array format', () {
      final list = BlossomServerList.decode(
        '["https://blossom1.example","https://blossom2.example"]',
      );

      expect(list.servers, hasLength(2));
      expect(list.servers[0], 'https://blossom1.example');
      expect(list.servers[1], 'https://blossom2.example');
      expect(list.updatedAt, isNull);
    });

    test('decode filters out empty/whitespace-only URLs', () {
      final list = BlossomServerList.decode(
        '["https://blossom.example","","  "]',
      );

      expect(list.servers, hasLength(1));
      expect(list.servers.single, 'https://blossom.example');
    });

    test('fromJson drops empty servers', () {
      final list = BlossomServerList.decode(
        '{"servers":["https://blossom.example",""]}',
      );
      expect(list.servers, hasLength(1));
      expect(list.servers.single, 'https://blossom.example');
    });

    test('decode returns empty list on non-object/non-array JSON', () {
      expect(BlossomServerList.decode('42').servers, isEmpty);
      expect(BlossomServerList.decode('"string"').servers, isEmpty);
      expect(BlossomServerList.decode('null').servers, isEmpty);
    });

    test('fromJson handles missing servers key', () {
      final list = BlossomServerList.decode('{"updated_at":null}');
      expect(list.servers, isEmpty);
    });

    test('toJson includes servers and updated_at', () {
      final list = BlossomServerList(
        servers: const ['https://blossom.example'],
        updatedAt: DateTime.utc(2026, 4, 15),
      );
      final json = list.toJson();

      expect(json['servers'], ['https://blossom.example']);
      expect(json['updated_at'], '2026-04-15T00:00:00.000Z');
    });
  });
}

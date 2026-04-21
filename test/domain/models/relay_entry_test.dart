import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/relay_entry.dart';

void main() {
  group('RelayMarker.fromCode', () {
    test("'r' returns RelayMarker.read", () {
      expect(RelayMarker.fromCode('r'), RelayMarker.read);
    });

    test("'read' returns RelayMarker.read", () {
      expect(RelayMarker.fromCode('read'), RelayMarker.read);
    });

    test("'w' returns RelayMarker.write", () {
      expect(RelayMarker.fromCode('w'), RelayMarker.write);
    });

    test("'write' returns RelayMarker.write", () {
      expect(RelayMarker.fromCode('write'), RelayMarker.write);
    });

    test('null returns RelayMarker.readWrite', () {
      expect(RelayMarker.fromCode(null), RelayMarker.readWrite);
    });

    test('empty string returns RelayMarker.readWrite', () {
      expect(RelayMarker.fromCode(''), RelayMarker.readWrite);
    });

    test('unknown value returns RelayMarker.readWrite', () {
      expect(RelayMarker.fromCode('xyz'), RelayMarker.readWrite);
      expect(RelayMarker.fromCode('rw'), RelayMarker.readWrite);
    });
  });

  group('RelayEntry serialization', () {
    test('toJson includes url and marker code', () {
      const entry = RelayEntry(
        url: 'wss://relay.example',
        marker: RelayMarker.read,
      );
      final json = entry.toJson();

      expect(json['url'], 'wss://relay.example');
      expect(json['marker'], 'r');
    });

    test('fromJson round-trips correctly', () {
      const original = RelayEntry(
        url: 'wss://relay.example',
        marker: RelayMarker.write,
      );
      final roundTripped = RelayEntry.fromJson(original.toJson());

      expect(roundTripped.url, original.url);
      expect(roundTripped.marker, original.marker);
    });

    test('fromJson defaults to readWrite when marker missing', () {
      final entry = RelayEntry.fromJson({'url': 'wss://relay.example'});
      expect(entry.marker, RelayMarker.readWrite);
    });

    test('fromJson handles empty url gracefully', () {
      final entry = RelayEntry.fromJson(<String, dynamic>{});
      expect(entry.url, '');
      expect(entry.marker, RelayMarker.readWrite);
    });
  });

  group('RelayList serialization', () {
    test('encode/decode round-trips entries and updatedAt', () {
      final list = RelayList(
        entries: const [
          RelayEntry(url: 'wss://relay1.example', marker: RelayMarker.read),
          RelayEntry(url: 'wss://relay2.example', marker: RelayMarker.write),
        ],
        updatedAt: DateTime.utc(2026, 4, 15, 12, 0, 0),
      );
      final decoded = RelayList.decode(list.encode());

      expect(decoded.entries, hasLength(2));
      expect(decoded.entries[0].url, 'wss://relay1.example');
      expect(decoded.entries[0].marker, RelayMarker.read);
      expect(decoded.entries[1].url, 'wss://relay2.example');
      expect(decoded.entries[1].marker, RelayMarker.write);
      expect(decoded.updatedAt, DateTime.utc(2026, 4, 15, 12, 0, 0));
    });

    test('decode handles legacy plain-array format', () {
      final list = RelayList.decode(
        '["wss://relay1.example","wss://relay2.example"]',
      );

      expect(list.entries, hasLength(2));
      expect(list.entries[0].url, 'wss://relay1.example');
      expect(list.entries[0].marker, RelayMarker.readWrite);
      expect(list.entries[1].url, 'wss://relay2.example');
      expect(list.updatedAt, isNull);
    });

    test('decode filters out empty URLs from legacy array', () {
      final list = RelayList.decode('["wss://relay.example","","  "]');

      expect(list.entries, hasLength(1));
      expect(list.entries.single.url, 'wss://relay.example');
    });

    test('fromJson drops entries with empty url', () {
      final list = RelayList.decode(
        '{"entries":[{"url":"wss://relay.example"},{"url":""}]}',
      );
      expect(list.entries, hasLength(1));
      expect(list.entries.single.url, 'wss://relay.example');
    });

    test('decode returns empty RelayList on non-object/non-array JSON', () {
      expect(RelayList.decode('42').entries, isEmpty);
      expect(RelayList.decode('"string"').entries, isEmpty);
      expect(RelayList.decode('null').entries, isEmpty);
    });
  });

  group('RelayList.urls', () {
    test('returns list of all relay URLs', () {
      const list = RelayList(
        entries: [
          RelayEntry(url: 'wss://relay1.example'),
          RelayEntry(url: 'wss://relay2.example'),
        ],
      );
      expect(list.urls, ['wss://relay1.example', 'wss://relay2.example']);
    });
  });
}

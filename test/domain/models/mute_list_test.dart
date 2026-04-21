import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/mute_list.dart';

void main() {
  group('MuteEntry serialization', () {
    test('toJson includes all fields when set', () {
      final entry = MuteEntry(
        pubkeyHex: 'abc123',
        reason: 'spam',
        addedAt: DateTime.utc(2026, 4, 15, 12, 0, 0),
      );
      final json = entry.toJson();

      expect(json['pubkey_hex'], 'abc123');
      expect(json['reason'], 'spam');
      expect(json['added_at'], '2026-04-15T12:00:00.000Z');
    });

    test('toJson omits optional fields when absent', () {
      const entry = MuteEntry(pubkeyHex: 'abc123');
      final json = entry.toJson();

      expect(json.keys, contains('pubkey_hex'));
      expect(json.containsKey('reason'), isFalse);
      expect(json.containsKey('added_at'), isFalse);
    });

    test('fromJson round-trips all fields', () {
      final original = MuteEntry(
        pubkeyHex: 'abc123',
        reason: 'harassment',
        addedAt: DateTime.utc(2026, 4, 15, 12, 0, 0),
      );
      final roundTripped = MuteEntry.fromJson(original.toJson());

      expect(roundTripped.pubkeyHex, original.pubkeyHex);
      expect(roundTripped.reason, original.reason);
      expect(roundTripped.addedAt, original.addedAt);
    });

    test('fromJson trims whitespace from pubkeyHex', () {
      final entry = MuteEntry.fromJson({'pubkey_hex': '  abc123  '});
      expect(entry.pubkeyHex, 'abc123');
    });

    test('fromJson handles missing fields gracefully', () {
      final entry = MuteEntry.fromJson(<String, dynamic>{});
      expect(entry.pubkeyHex, '');
      expect(entry.reason, isNull);
      expect(entry.addedAt, isNull);
    });

    test('fromJson handles null added_at gracefully', () {
      final entry = MuteEntry.fromJson({
        'pubkey_hex': 'abc123',
        'added_at': null,
      });
      expect(entry.pubkeyHex, 'abc123');
      expect(entry.addedAt, isNull);
    });

    test('fromJson handles malformed added_at gracefully', () {
      final entry = MuteEntry.fromJson({
        'pubkey_hex': 'abc123',
        'added_at': 'not-a-date',
      });
      expect(entry.addedAt, isNull);
    });
  });

  group('MuteList serialization', () {
    test('encode/decode round-trips entries and updatedAt', () {
      final list = MuteList(
        entries: [
          const MuteEntry(pubkeyHex: 'abc123', reason: 'spam'),
          const MuteEntry(pubkeyHex: 'def456'),
        ],
        updatedAt: DateTime.utc(2026, 4, 15, 12, 0, 0),
      );
      final decoded = MuteList.decode(list.encode());

      expect(decoded.entries, hasLength(2));
      expect(decoded.entries[0].pubkeyHex, 'abc123');
      expect(decoded.entries[0].reason, 'spam');
      expect(decoded.entries[1].pubkeyHex, 'def456');
      expect(decoded.updatedAt, DateTime.utc(2026, 4, 15, 12, 0, 0));
    });

    test('decode drops entries with empty pubkeyHex', () {
      final list = MuteList.decode(
        '{"entries":[{"pubkey_hex":"abc123"},{"pubkey_hex":""}]}',
      );
      expect(list.entries, hasLength(1));
      expect(list.entries.single.pubkeyHex, 'abc123');
    });

    test('decode returns empty list when entries key missing', () {
      final list = MuteList.decode('{"updated_at":null}');
      expect(list.entries, isEmpty);
    });

    test('decode returns empty MuteList on non-object JSON', () {
      expect(MuteList.decode('[]').entries, isEmpty);
      expect(MuteList.decode('42').entries, isEmpty);
      expect(MuteList.decode('"string"').entries, isEmpty);
    });
  });

  group('MuteList.contains', () {
    test('returns true for exact match', () {
      const list = MuteList(entries: [MuteEntry(pubkeyHex: 'abc123')]);
      expect(list.contains('abc123'), isTrue);
    });

    test('is case-insensitive for caller input', () {
      const list = MuteList(entries: [MuteEntry(pubkeyHex: 'abc123')]);
      expect(list.contains('ABC123'), isTrue);
    });

    test('is case-insensitive for stored entry', () {
      const list = MuteList(entries: [MuteEntry(pubkeyHex: 'ABC123')]);
      expect(list.contains('abc123'), isTrue);
    });

    test('returns false when pubkey is absent', () {
      const list = MuteList(entries: [MuteEntry(pubkeyHex: 'abc123')]);
      expect(list.contains('xyz789'), isFalse);
    });

    test('returns false on empty list', () {
      const list = MuteList(entries: <MuteEntry>[]);
      expect(list.contains('abc123'), isFalse);
    });
  });

  group('MuteList.pubkeyHexes', () {
    test('returns list of all pubkey hexes', () {
      const list = MuteList(
        entries: [
          MuteEntry(pubkeyHex: 'abc123'),
          MuteEntry(pubkeyHex: 'def456'),
        ],
      );
      expect(list.pubkeyHexes, ['abc123', 'def456']);
    });
  });
}

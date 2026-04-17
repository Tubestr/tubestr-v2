import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/nostr/outbox_relay_resolver.dart';
import 'package:ndk/entities.dart';

import '../../test_support/service_fakes.dart';

Nip01Event _relayListEvent({
  required String pubKey,
  required List<List<String>> tags,
  int createdAt = 1_800_000_000,
}) {
  return Nip01Event(
    pubKey: pubKey,
    kind: 10002,
    tags: tags,
    content: '',
    createdAt: createdAt,
  );
}

void main() {
  late FakeNostrService nostr;

  setUp(() {
    nostr = FakeNostrService();
    nostr.relayList = const ['wss://local.a', 'wss://local.b'];
  });

  group('readRelaysFor', () {
    test('returns write+readWrite relays from the author', () async {
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.one'],
          ['r', 'wss://alice.read', 'read'],
          ['r', 'wss://alice.write', 'write'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr);

      final relays = await resolver.readRelaysFor('alice');

      expect(relays, ['wss://alice.one', 'wss://alice.write']);
    });

    test('returns empty when fetch fails or no event', () async {
      nostr.fetchedRelayListEvent = null;
      final resolver = OutboxRelayResolver(nostrService: nostr);
      expect(await resolver.readRelaysFor('ghost'), isEmpty);
    });
  });

  group('writeRelaysFor', () {
    test('returns read+readWrite relays (where recipient listens)', () async {
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'bob',
        tags: const [
          ['r', 'wss://bob.one'],
          ['r', 'wss://bob.read', 'read'],
          ['r', 'wss://bob.write', 'write'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr);

      final relays = await resolver.writeRelaysFor('bob');

      expect(relays, ['wss://bob.one', 'wss://bob.read']);
    });
  });

  group('union semantics', () {
    test('unionForRead merges local with author write relays', () async {
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.write', 'write'],
          ['r', 'wss://alice.both'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr);

      final relays = await resolver.unionForRead('alice');

      expect(relays, [
        'wss://local.a',
        'wss://local.b',
        'wss://alice.write',
        'wss://alice.both',
      ]);
    });

    test('degenerates to local when recipient has no kind-10002', () async {
      nostr.fetchedRelayListEvent = null;
      final resolver = OutboxRelayResolver(nostrService: nostr);

      expect(await resolver.unionForWrite('ghost'), [
        'wss://local.a',
        'wss://local.b',
      ]);
    });

    test('caps the union at unionCap, keeping local first', () async {
      nostr.relayList = const [
        'wss://local.a',
        'wss://local.b',
        'wss://local.c',
      ];
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.one'],
          ['r', 'wss://alice.two'],
          ['r', 'wss://alice.three'],
          ['r', 'wss://alice.four'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr, unionCap: 5);

      final relays = await resolver.unionForRead('alice');

      expect(relays.length, 5);
      expect(relays.sublist(0, 3), [
        'wss://local.a',
        'wss://local.b',
        'wss://local.c',
      ]);
    });

    test('dedupes overlap between local and remote', () async {
      nostr.relayList = const ['wss://shared', 'wss://local.only'];
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://shared'],
          ['r', 'wss://alice.only'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr);

      final relays = await resolver.unionForRead('alice');

      expect(relays, ['wss://shared', 'wss://local.only', 'wss://alice.only']);
    });
  });

  group('cache behavior', () {
    test('does not re-fetch within TTL', () async {
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.one'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr);

      await resolver.readRelaysFor('alice');
      // Simulate the remote fetch returning nothing on the second call.
      nostr.fetchedRelayListEvent = null;

      // Still returns the cached entries.
      expect(await resolver.readRelaysFor('alice'), ['wss://alice.one']);
    });

    test('re-fetches after TTL expiry', () async {
      var current = DateTime.utc(2026, 1, 1, 12);
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.old'],
        ],
      );
      final resolver = OutboxRelayResolver(
        nostrService: nostr,
        ttl: const Duration(minutes: 30),
        now: () => current,
      );

      expect(await resolver.readRelaysFor('alice'), ['wss://alice.old']);

      current = current.add(const Duration(hours: 1));
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.new'],
        ],
      );

      expect(await resolver.readRelaysFor('alice'), ['wss://alice.new']);
    });

    test('observe seeds the cache without a fetch', () async {
      final resolver = OutboxRelayResolver(nostrService: nostr);
      resolver.observe(
        _relayListEvent(
          pubKey: 'alice',
          tags: const [
            ['r', 'wss://alice.seen'],
          ],
        ),
      );
      // Any subsequent fetch attempt would return null; observe should prevent it.
      nostr.fetchedRelayListEvent = null;
      expect(await resolver.readRelaysFor('alice'), ['wss://alice.seen']);
    });

    test('observe ignores non-kind-10002 events', () async {
      final resolver = OutboxRelayResolver(nostrService: nostr);
      resolver.observe(
        Nip01Event(
          pubKey: 'alice',
          kind: 0,
          tags: const [
            ['r', 'wss://alice.wrong'],
          ],
          content: '',
        ),
      );
      // Cache wasn't seeded -> falls back to the fetch path (null -> empty).
      nostr.fetchedRelayListEvent = null;
      expect(await resolver.readRelaysFor('alice'), isEmpty);
    });

    test('invalidate forces a re-fetch', () async {
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.one'],
        ],
      );
      final resolver = OutboxRelayResolver(nostrService: nostr);
      await resolver.readRelaysFor('alice');

      resolver.invalidate('alice');
      nostr.fetchedRelayListEvent = _relayListEvent(
        pubKey: 'alice',
        tags: const [
          ['r', 'wss://alice.fresh'],
        ],
      );

      expect(await resolver.readRelaysFor('alice'), ['wss://alice.fresh']);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/constants.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/blossom_server_list.dart';
import 'package:mytube/domain/models/mute_list.dart';
import 'package:mytube/domain/models/offline_action.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/domain/models/relay_entry.dart';
import 'package:mytube/services/identity/user_list_sync_service.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:drift/native.dart';
import 'package:ndk/entities.dart';

import '../../test_support/service_fakes.dart';

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub-parent',
    nsec: 'nsec-parent',
    createdAtIso: '2026-03-15T00:00:00.000Z',
  );

  late AppDatabase database;
  late OfflineActionStore offlineStore;
  late FakeNostrService nostr;
  late UserListSyncService service;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    offlineStore = OfflineActionStore(database: database);
    nostr = FakeNostrService();
    service = UserListSyncService(
      nostrService: nostr,
      offlineActionStore: offlineStore,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('hydrateFromRelays — relay list', () {
    test('imports remote when local has no updatedAt', () async {
      nostr.savedRelayListFull = const RelayList(entries: <RelayEntry>[]);
      nostr.fetchedRelayListEvent = Nip01Event(
        pubKey: identity.publicKeyHex,
        kind: MarmotKinds.relayList,
        tags: const [
          ['r', 'wss://remote.one'],
          ['r', 'wss://remote.two', 'read'],
          ['r', 'wss://remote.three', 'write'],
        ],
        content: '',
        createdAt: 1_800_000_000,
      );

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.savedRelayListFull, isNotNull);
      final saved = nostr.savedRelayListFull!;
      expect(saved.entries.map((e) => e.url), [
        'wss://remote.one',
        'wss://remote.two',
        'wss://remote.three',
      ]);
      expect(saved.entries.map((e) => e.marker), [
        RelayMarker.readWrite,
        RelayMarker.read,
        RelayMarker.write,
      ]);
      expect(saved.updatedAt?.millisecondsSinceEpoch, 1_800_000_000 * 1000);
    });

    test('keeps local when local is newer', () async {
      final localTime = DateTime.utc(2026, 4, 1);
      nostr.savedRelayListFull = RelayList(
        entries: const [RelayEntry(url: 'wss://local.one')],
        updatedAt: localTime,
      );
      nostr.fetchedRelayListEvent = Nip01Event(
        pubKey: identity.publicKeyHex,
        kind: MarmotKinds.relayList,
        tags: const [
          ['r', 'wss://remote.one'],
        ],
        content: '',
        createdAt:
            localTime
                .subtract(const Duration(days: 1))
                .millisecondsSinceEpoch ~/
            1000,
      );

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.savedRelayListFull?.entries.first.url, 'wss://local.one');
    });

    test(
      'publishes local defaults when no remote event and no updatedAt',
      () async {
        // savedRelayListFull null → loadRelayListFull defaults to relayList
        // which is ['wss://relay.example']
        nostr.fetchedRelayListEvent = null;

        await service.hydrateFromRelays(identity: identity);

        expect(nostr.publishedRelayListEntries, hasLength(1));
        // After publish, savedRelayListFull is set with updatedAt.
        expect(nostr.savedRelayListFull?.updatedAt, isNotNull);
      },
    );

    test('does not republish when local already has updatedAt', () async {
      nostr.savedRelayListFull = RelayList(
        entries: const [RelayEntry(url: 'wss://local.one')],
        updatedAt: DateTime.utc(2026, 4, 1),
      );
      nostr.fetchedRelayListEvent = null;

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.publishedRelayListEntries, isEmpty);
    });
  });

  group('saveAndPublishRelayList', () {
    test('saves locally and publishes on success', () async {
      final entries = const [
        RelayEntry(url: 'wss://one'),
        RelayEntry(url: 'wss://two', marker: RelayMarker.write),
      ];

      await service.saveAndPublishRelayList(
        identity: identity,
        entries: entries,
      );

      expect(nostr.savedRelayListFull?.entries, entries);
      expect(nostr.savedRelayListFull?.updatedAt, isNotNull);
      expect(nostr.publishedRelayListEntries, hasLength(1));
      expect(await offlineStore.load(), isEmpty);
    });

    test('queues offline action when publish fails', () async {
      nostr.throwOnPublishRelayList = true;
      final entries = const [RelayEntry(url: 'wss://one')];

      await expectLater(
        service.saveAndPublishRelayList(identity: identity, entries: entries),
        throwsA(isA<StateError>()),
      );

      expect(nostr.savedRelayListFull?.entries, entries);
      final queued = await offlineStore.load();
      expect(queued, hasLength(1));
      expect(queued.first.type, OfflineActionType.publishRelayList);
    });
  });

  group('saveAndPublishBlossomServerList', () {
    test('saves locally and publishes on success', () async {
      await service.saveAndPublishBlossomServerList(
        identity: identity,
        servers: const ['https://blossom.one'],
      );

      expect(nostr.savedBlossomServerListFull?.servers, [
        'https://blossom.one',
      ]);
      expect(nostr.publishedBlossomServerLists, [
        const ['https://blossom.one'],
      ]);
      expect(await offlineStore.load(), isEmpty);
    });

    test('queues offline action when publish fails', () async {
      nostr.throwOnPublishBlossomServerList = true;

      await expectLater(
        service.saveAndPublishBlossomServerList(
          identity: identity,
          servers: const ['https://blossom.one'],
        ),
        throwsA(isA<StateError>()),
      );

      expect(nostr.savedBlossomServerListFull?.servers, [
        'https://blossom.one',
      ]);
      final queued = await offlineStore.load();
      expect(queued, hasLength(1));
      expect(queued.first.type, OfflineActionType.publishBlossomServerList);
    });
  });

  group('hydrateFromRelays — Blossom list', () {
    test('imports remote when local has no updatedAt', () async {
      nostr.savedBlossomServerListFull = const BlossomServerList(
        servers: <String>[],
      );
      nostr.fetchedBlossomServerListEvent = Nip01Event(
        pubKey: identity.publicKeyHex,
        kind: MarmotKinds.blossomServers,
        tags: const [
          ['server', 'https://blossom.remote'],
        ],
        content: '',
        createdAt: 1_800_000_000,
      );

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.savedBlossomServerListFull?.servers, [
        'https://blossom.remote',
      ]);
    });

    test(
      'publishes local defaults when no remote event and no updatedAt',
      () async {
        nostr.fetchedBlossomServerListEvent = null;

        await service.hydrateFromRelays(identity: identity);

        expect(nostr.publishedBlossomServerLists, hasLength(1));
        expect(nostr.savedBlossomServerListFull?.updatedAt, isNotNull);
      },
    );
  });

  group('hydrateFromRelays — mute list', () {
    test('imports remote when local has no updatedAt', () async {
      nostr.fetchedMuteListEvent = Nip01Event(
        pubKey: identity.publicKeyHex,
        kind: MarmotKinds.muteList,
        tags: const <List<String>>[],
        content: 'ciphertext',
        createdAt: 1_800_000_000,
      );
      nostr.parsedMuteListResult = MuteList(
        entries: const [MuteEntry(pubkeyHex: 'blocked-creator')],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          1_800_000_000 * 1000,
          isUtc: true,
        ),
      );

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.savedMuteList?.entries.map((e) => e.pubkeyHex), [
        'blocked-creator',
      ]);
    });

    test('skips when no remote event exists', () async {
      nostr.fetchedMuteListEvent = null;

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.savedMuteList, isNull);
    });

    test('keeps local when local is newer than remote', () async {
      final localTime = DateTime.utc(2026, 4, 1);
      nostr.savedMuteList = MuteList(
        entries: const [MuteEntry(pubkeyHex: 'local-mute')],
        updatedAt: localTime,
      );
      nostr.fetchedMuteListEvent = Nip01Event(
        pubKey: identity.publicKeyHex,
        kind: MarmotKinds.muteList,
        tags: const <List<String>>[],
        content: 'ciphertext',
        createdAt: 1_700_000_000, // older
      );
      nostr.parsedMuteListResult = MuteList(
        entries: const [MuteEntry(pubkeyHex: 'remote-mute')],
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          1_700_000_000 * 1000,
          isUtc: true,
        ),
      );

      await service.hydrateFromRelays(identity: identity);

      expect(nostr.savedMuteList?.entries.single.pubkeyHex, 'local-mute');
    });
  });

  group('saveAndPublishMuteList', () {
    test('persists locally and publishes', () async {
      await service.saveAndPublishMuteList(
        identity: identity,
        entries: const [MuteEntry(pubkeyHex: 'creator-1')],
      );

      expect(nostr.publishedMuteListEntries, hasLength(1));
      expect(nostr.publishedMuteListEntries.single.map((e) => e.pubkeyHex), [
        'creator-1',
      ]);
      expect(nostr.savedMuteList?.entries.single.pubkeyHex, 'creator-1');
    });

    test('queues offline when publish fails, keeps local state', () async {
      nostr.throwOnPublishMuteList = true;

      await expectLater(
        service.saveAndPublishMuteList(
          identity: identity,
          entries: const [MuteEntry(pubkeyHex: 'creator-2')],
        ),
        throwsA(isA<StateError>()),
      );

      expect(nostr.savedMuteList?.entries.single.pubkeyHex, 'creator-2');
      final queued = await offlineStore.load();
      expect(queued, hasLength(1));
      expect(queued.first.type, OfflineActionType.publishMuteList);
    });
  });

  group('replayMuteListPublish', () {
    test('publishes entries from valid payload', () async {
      final payload = <String, dynamic>{
        'entries_json': '[{"pubkey_hex":"creator-1","reason":"spam"}]',
      };

      await service.replayMuteListPublish(identity: identity, payload: payload);

      expect(nostr.publishedMuteListEntries, hasLength(1));
      expect(
        nostr.publishedMuteListEntries.single.single.pubkeyHex,
        'creator-1',
      );
    });

    test('silently returns when entries_json absent', () async {
      await service.replayMuteListPublish(
        identity: identity,
        payload: <String, dynamic>{},
      );

      expect(nostr.publishedMuteListEntries, isEmpty);
    });

    test('silently returns when entries_json empty', () async {
      await service.replayMuteListPublish(
        identity: identity,
        payload: <String, dynamic>{'entries_json': ''},
      );

      expect(nostr.publishedMuteListEntries, isEmpty);
    });

    test('silently returns when entries_json is empty array', () async {
      await service.replayMuteListPublish(
        identity: identity,
        payload: <String, dynamic>{'entries_json': '[]'},
      );

      expect(nostr.publishedMuteListEntries, isEmpty);
    });

    test('does not re-queue on failure', () async {
      nostr.throwOnPublishMuteList = true;
      final payload = <String, dynamic>{
        'entries_json': '[{"pubkey_hex":"creator-1"}]',
      };

      await expectLater(
        service.replayMuteListPublish(identity: identity, payload: payload),
        throwsA(isA<StateError>()),
      );

      final queued = await offlineStore.load();
      expect(queued, isEmpty);
    });
  });
}

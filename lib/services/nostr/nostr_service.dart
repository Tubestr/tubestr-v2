import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/blossom_server_list.dart';
import '../../domain/models/mute_list.dart';
import '../../domain/models/parent_identity.dart';
import '../../domain/models/relay_entry.dart';

class PublishEventResult {
  const PublishEventResult({required this.eventId, required this.createdAt});

  final String eventId;
  final DateTime createdAt;
}

abstract class NostrService {
  Future<List<String>> loadRelayList();
  Future<void> saveRelayList(List<String> relays);
  Future<RelayList> loadRelayListFull();
  Future<void> saveRelayListFull(RelayList list);
  Future<List<String>> loadBlossomServerList();
  Future<void> saveBlossomServerList(List<String> servers);
  Future<BlossomServerList> loadBlossomServerListFull();
  Future<void> saveBlossomServerListFull(BlossomServerList list);
  Future<void> connect();
  Future<void> publishParentProfile({
    required ParentIdentity identity,
    required String displayName,
  });
  Future<String> publishKeyPackageEvent({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
    List<String>? relays,
  });
  Future<String> createSignedKeyPackageEventJson({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
  });
  Future<String> createSignedEventJson({
    required ParentIdentity identity,
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  });
  Future<String> publishSignedEventJson({
    required ParentIdentity identity,
    required String eventJson,
    List<String>? relays,
  });
  Future<PublishEventResult> publishRelayList({
    required ParentIdentity identity,
    required List<RelayEntry> entries,
    List<String>? relays,
  });
  Future<Nip01Event?> fetchRelayListEvent({
    required String publicKeyHex,
    List<String>? relays,
  });
  Future<PublishEventResult> publishBlossomServerList({
    required ParentIdentity identity,
    required List<String> servers,
    List<String>? relays,
  });
  Future<List<String>> fetchBlossomServerList({
    required String publicKeyHex,
    List<String>? relays,
  });
  Future<Nip01Event?> fetchBlossomServerListEvent({
    required String publicKeyHex,
    List<String>? relays,
  });
  Future<MuteList> loadMuteList();
  Future<void> saveMuteList(MuteList list);
  Future<PublishEventResult> publishMuteList({
    required ParentIdentity identity,
    required List<MuteEntry> entries,
    List<String>? relays,
  });
  Future<Nip01Event?> fetchMuteListEvent({
    required String publicKeyHex,
    List<String>? relays,
  });
  Future<MuteList> parseMuteListEventFor({
    required ParentIdentity identity,
    required Nip01Event event,
  });
  Future<NdkResponse> subscribe({
    required String subscriptionId,
    required Filter filter,
    List<String>? relays,
  });
  Future<List<Nip01Event>> queryEvents({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  });
  Future<void> unsubscribe(String subscriptionId);
  Future<String> publishGiftWrappedRumor({
    required ParentIdentity identity,
    required String rumorEventJson,
    required String recipientPublicKeyHex,
    List<String>? relays,
  });
  Future<String?> unwrapGiftWrapRumorJson({
    required ParentIdentity identity,
    required Nip01Event giftWrapEvent,
  });

  /// Parses a kind-10002 event into a [RelayList] per NIP-65.
  static RelayList parseRelayListEvent(Nip01Event event) {
    final entries = <RelayEntry>[];
    final seen = <String>{};
    for (final tag in event.tags) {
      if (tag.isEmpty || tag.first != 'r' || tag.length < 2) {
        continue;
      }
      final url = tag[1].trim();
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      final marker = tag.length > 2 ? tag[2].trim() : '';
      entries.add(RelayEntry(url: url, marker: RelayMarker.fromCode(marker)));
    }
    return RelayList(
      entries: entries,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        event.createdAt * 1000,
        isUtc: true,
      ),
    );
  }

  /// Parses a kind-10063 event into a [BlossomServerList].
  static BlossomServerList parseBlossomServerListEvent(Nip01Event event) {
    final servers = <String>[];
    final seen = <String>{};
    for (final tag in event.tags) {
      if (tag.isEmpty || tag.first != 'server' || tag.length < 2) {
        continue;
      }
      final url = tag[1].trim();
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      servers.add(url);
    }
    return BlossomServerList(
      servers: servers,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        event.createdAt * 1000,
        isUtc: true,
      ),
    );
  }
}

class NdkNostrService implements NostrService {
  NdkNostrService(this._database) : _ndk = Ndk.emptyBootstrapRelaysConfig();

  final AppDatabase _database;
  final Ndk _ndk;

  @override
  Future<List<String>> loadRelayList() async {
    final list = await loadRelayListFull();
    if (list.entries.isEmpty) {
      return AppConstants.defaultRelays;
    }
    return list.urls;
  }

  @override
  Future<RelayList> loadRelayListFull() async {
    final raw = await _database.getSetting(AppConstants.relayListSettingKey);
    if (raw == null || raw.isEmpty) {
      return const RelayList(entries: <RelayEntry>[]);
    }
    try {
      return RelayList.decode(raw);
    } catch (_) {
      return const RelayList(entries: <RelayEntry>[]);
    }
  }

  @override
  Future<void> saveRelayList(List<String> relays) async {
    final normalized = _normalizeUrls(relays);
    final existing = await loadRelayListFull();
    final byUrl = <String, RelayEntry>{
      for (final entry in existing.entries) entry.url: entry,
    };
    final entries = normalized
        .map(
          (url) =>
              byUrl[url] ?? RelayEntry(url: url, marker: RelayMarker.readWrite),
        )
        .toList(growable: false);
    await saveRelayListFull(
      RelayList(entries: entries, updatedAt: existing.updatedAt),
    );
  }

  @override
  Future<void> saveRelayListFull(RelayList list) {
    final normalized = <RelayEntry>[];
    final seen = <String>{};
    for (final entry in list.entries) {
      final url = entry.url.trim();
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      normalized.add(entry.copyWith(url: url));
    }
    return _database.putSetting(
      AppConstants.relayListSettingKey,
      RelayList(entries: normalized, updatedAt: list.updatedAt).encode(),
    );
  }

  @override
  Future<List<String>> loadBlossomServerList() async {
    final list = await loadBlossomServerListFull();
    if (list.servers.isEmpty) {
      return AppConstants.defaultBlossomServers;
    }
    return list.servers;
  }

  @override
  Future<BlossomServerList> loadBlossomServerListFull() async {
    final raw = await _database.getSetting(
      AppConstants.blossomServerListSettingKey,
    );
    if (raw == null || raw.isEmpty) {
      return const BlossomServerList(servers: <String>[]);
    }
    try {
      return BlossomServerList.decode(raw);
    } catch (_) {
      return const BlossomServerList(servers: <String>[]);
    }
  }

  @override
  Future<void> saveBlossomServerList(List<String> servers) async {
    final normalized = _normalizeUrls(servers);
    final existing = await loadBlossomServerListFull();
    await saveBlossomServerListFull(
      BlossomServerList(servers: normalized, updatedAt: existing.updatedAt),
    );
  }

  @override
  Future<void> saveBlossomServerListFull(BlossomServerList list) {
    final normalized = _normalizeUrls(list.servers);
    return _database.putSetting(
      AppConstants.blossomServerListSettingKey,
      BlossomServerList(
        servers: normalized,
        updatedAt: list.updatedAt,
      ).encode(),
    );
  }

  @override
  Future<MuteList> loadMuteList() async {
    final raw = await _database.getSetting(AppConstants.muteListSettingKey);
    if (raw == null || raw.isEmpty) {
      return const MuteList(entries: <MuteEntry>[]);
    }
    try {
      return MuteList.decode(raw);
    } catch (_) {
      return const MuteList(entries: <MuteEntry>[]);
    }
  }

  @override
  Future<void> saveMuteList(MuteList list) {
    final seen = <String>{};
    final normalized = <MuteEntry>[];
    for (final entry in list.entries) {
      final pubkey = entry.pubkeyHex.trim().toLowerCase();
      if (pubkey.isEmpty || !seen.add(pubkey)) {
        continue;
      }
      normalized.add(entry.copyWith(pubkeyHex: pubkey));
    }
    return _database.putSetting(
      AppConstants.muteListSettingKey,
      MuteList(entries: normalized, updatedAt: list.updatedAt).encode(),
    );
  }

  @override
  Future<PublishEventResult> publishMuteList({
    required ParentIdentity identity,
    required List<MuteEntry> entries,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final signer = _ndk.accounts.getLoggedAccount()?.signer;
    if (signer == null) {
      throw StateError('Cannot publish mute list without a signer');
    }
    final publishRelays = relays ?? await loadRelayList();
    await _connectRelays(publishRelays);

    // Private payload: JSON array of ["p", pubkey] tags, NIP-44 self-encrypted.
    final privateTags = entries
        .map((e) => <String>['p', e.pubkeyHex.toLowerCase()])
        .toList(growable: false);
    final ciphertext = await signer.encryptNip44(
      plaintext: jsonEncode(privateTags),
      recipientPubKey: identity.publicKeyHex,
    );
    if (ciphertext == null) {
      throw StateError('Mute list NIP-44 encryption returned null');
    }

    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: MarmotKinds.muteList,
      tags: const <List<String>>[],
      content: ciphertext,
      createdAt: createdAt,
    );
    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    final results = await response.broadcastDoneFuture;
    _throwIfNoRelayAccepted('mute list', results);
    return PublishEventResult(
      eventId: response.publishEvent.id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAt * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  Future<Nip01Event?> fetchMuteListEvent({
    required String publicKeyHex,
    List<String>? relays,
  }) async {
    final events = await queryEvents(
      filter: Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.muteList],
        limit: 1,
      ),
      relays: relays,
      timeout: const Duration(seconds: 3),
    );
    if (events.isEmpty) {
      return null;
    }
    return events.first;
  }

  @override
  Future<MuteList> parseMuteListEventFor({
    required ParentIdentity identity,
    required Nip01Event event,
  }) async {
    final entries = <MuteEntry>[];
    final seen = <String>{};

    void addPubkey(String pubkeyHex) {
      final normalized = pubkeyHex.trim().toLowerCase();
      if (normalized.isEmpty || !seen.add(normalized)) {
        return;
      }
      entries.add(MuteEntry(pubkeyHex: normalized));
    }

    // Public p tags (legacy / foreign clients).
    for (final tag in event.tags) {
      if (tag.length >= 2 && tag.first == 'p') {
        addPubkey(tag[1]);
      }
    }

    // Private content: NIP-44-encrypted JSON array of tags.
    if (event.content.isNotEmpty) {
      _ensureLoggedIn(identity);
      final signer = _ndk.accounts.getLoggedAccount()?.signer;
      if (signer != null) {
        try {
          final plaintext = await signer.decryptNip44(
            ciphertext: event.content,
            senderPubKey: identity.publicKeyHex,
          );
          if (plaintext != null && plaintext.isNotEmpty) {
            final decoded = jsonDecode(plaintext);
            if (decoded is List) {
              for (final tag in decoded) {
                if (tag is List &&
                    tag.length >= 2 &&
                    tag.first.toString() == 'p') {
                  addPubkey(tag[1].toString());
                }
              }
            }
          }
        } catch (_) {
          // Decrypt failure (foreign NIP-04 or corrupt) — public tags stand.
        }
      }
    }

    return MuteList(
      entries: entries,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        event.createdAt * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  Future<void> connect() async {
    final relays = await loadRelayList();
    await _connectRelays(relays);
  }

  Future<void> _connectRelays(List<String> relays) async {
    final failures = <String>[];
    await Future.wait(
      relays.map((relay) async {
        try {
          await _ndk.relays.connectRelay(
            dirtyUrl: relay,
            connectionSource: ConnectionSource.explicit,
          );
        } catch (_) {
          failures.add(relay);
        }
      }),
    );
    if (failures.length == relays.length && relays.isNotEmpty) {
      throw StateError(
        'Failed to connect to any relay: ${failures.join(', ')}',
      );
    }
  }

  void _throwIfNoRelayAccepted(
    String eventName,
    List<RelayBroadcastResponse> results,
  ) {
    if (results.any((result) => result.broadcastSuccessful)) {
      return;
    }
    final failedRelays = results
        .map((result) {
          final message = result.msg.trim();
          if (message.isEmpty) {
            return result.relayUrl;
          }
          return '${result.relayUrl} ($message)';
        })
        .toList(growable: false);
    throw StateError(
      'Failed to publish $eventName to any relay: ${failedRelays.join(', ')}',
    );
  }

  @override
  Future<void> publishParentProfile({
    required ParentIdentity identity,
    required String displayName,
  }) async {
    _ensureLoggedIn(identity);
    final relays = await loadRelayList();
    await connect();
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: 0,
      tags: const [],
      content: jsonEncode(<String, String>{
        'name': displayName,
        'display_name': displayName,
        'about': 'Parent account for Tubestr',
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: relays,
      timeout: const Duration(seconds: 2),
    );
    final results = await response.broadcastDoneFuture;
    final succeeded = results.any((result) => result.broadcastSuccessful);
    if (!succeeded) {
      final failedRelays = results
          .map((result) => result.relayUrl)
          .toList(growable: false);
      throw StateError(
        'Failed to publish parent profile to any relay: ${failedRelays.join(', ')}',
      );
    }
  }

  @override
  Future<String> publishKeyPackageEvent({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final publishRelays = relays ?? await loadRelayList();
    await _connectRelays(publishRelays);

    final tags = _decodeTags(tagsJson);
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: MarmotKinds.keyPackage,
      tags: tags,
      content: content,
    );

    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    final results = await response.broadcastDoneFuture;
    _throwIfNoRelayAccepted('key package', results);
    return response.publishEvent.id;
  }

  @override
  Future<String> createSignedKeyPackageEventJson({
    required ParentIdentity identity,
    required String content,
    required String tagsJson,
  }) async {
    _ensureLoggedIn(identity);
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: MarmotKinds.keyPackage,
      tags: _decodeTags(tagsJson),
      content: content,
    );
    final signed = await _ndk.accounts.sign(event);
    return Nip01EventModel.fromEntity(signed).toJsonString();
  }

  @override
  Future<String> createSignedEventJson({
    required ParentIdentity identity,
    required int kind,
    required List<List<String>> tags,
    required String content,
    int? createdAt,
  }) async {
    _ensureLoggedIn(identity);
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: kind,
      tags: tags,
      content: content,
    );
    final signed = await _ndk.accounts.sign(event);
    return Nip01EventModel.fromEntity(signed).toJsonString();
  }

  @override
  Future<String> publishSignedEventJson({
    required ParentIdentity identity,
    required String eventJson,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final publishRelays = relays ?? await loadRelayList();
    await _connectRelays(publishRelays);

    final event = Nip01EventModel.fromJson(
      jsonDecode(eventJson) as Map<String, dynamic>,
    );
    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    final results = await response.broadcastDoneFuture;
    _throwIfNoRelayAccepted('signed event', results);
    return response.publishEvent.id;
  }

  @override
  Future<PublishEventResult> publishRelayList({
    required ParentIdentity identity,
    required List<RelayEntry> entries,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final normalized = <RelayEntry>[];
    final seen = <String>{};
    for (final entry in entries) {
      final url = entry.url.trim();
      if (url.isEmpty || !seen.add(url)) {
        continue;
      }
      normalized.add(entry.copyWith(url: url));
    }
    if (normalized.isEmpty) {
      throw const FormatException('At least one relay is required');
    }
    final publishRelays =
        relays ?? await _publishRelayUrls(normalized.map((e) => e.url));
    await _connectRelays(publishRelays);

    final tags = normalized
        .map((entry) {
          switch (entry.marker) {
            case RelayMarker.readWrite:
              return <String>['r', entry.url];
            case RelayMarker.read:
              return <String>['r', entry.url, 'read'];
            case RelayMarker.write:
              return <String>['r', entry.url, 'write'];
          }
        })
        .toList(growable: false);

    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: MarmotKinds.relayList,
      tags: tags,
      content: '',
      createdAt: createdAt,
    );
    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    final results = await response.broadcastDoneFuture;
    _throwIfNoRelayAccepted('relay list', results);
    return PublishEventResult(
      eventId: response.publishEvent.id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAt * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  Future<Nip01Event?> fetchRelayListEvent({
    required String publicKeyHex,
    List<String>? relays,
  }) async {
    final events = await queryEvents(
      filter: Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.relayList],
        limit: 1,
      ),
      relays: relays,
      timeout: const Duration(seconds: 3),
    );
    if (events.isEmpty) {
      return null;
    }
    return events.first;
  }

  @override
  Future<PublishEventResult> publishBlossomServerList({
    required ParentIdentity identity,
    required List<String> servers,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final activeServers = _normalizeUrls(servers);
    if (activeServers.isEmpty) {
      throw const FormatException('At least one Blossom server is required');
    }
    final publishRelays = relays ?? await loadRelayList();
    await _connectRelays(publishRelays);

    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: MarmotKinds.blossomServers,
      tags: activeServers
          .map((server) => <String>['server', server])
          .toList(growable: false),
      content: '',
      createdAt: createdAt,
    );

    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    final results = await response.broadcastDoneFuture;
    _throwIfNoRelayAccepted('Blossom server list', results);
    return PublishEventResult(
      eventId: response.publishEvent.id,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAt * 1000,
        isUtc: true,
      ),
    );
  }

  @override
  Future<Nip01Event?> fetchBlossomServerListEvent({
    required String publicKeyHex,
    List<String>? relays,
  }) async {
    final explicitRelays = relays ?? await loadRelayList();
    final events = await queryEvents(
      filter: Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.blossomServers],
        limit: 1,
      ),
      relays: explicitRelays,
      timeout: const Duration(seconds: 3),
    );
    if (events.isEmpty) {
      return null;
    }
    return events.first;
  }

  /// Choose a relay set to broadcast to for a self-published relay list.
  /// Prefer the list being published; fall back to the previously-saved list,
  /// then to defaults. This matters during onboarding when no relays have
  /// been persisted yet.
  Future<List<String>> _publishRelayUrls(Iterable<String> candidates) async {
    final fromCandidates = candidates
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (fromCandidates.isNotEmpty) {
      return fromCandidates;
    }
    final saved = await loadRelayList();
    if (saved.isNotEmpty) {
      return saved;
    }
    return AppConstants.defaultRelays;
  }

  @override
  Future<List<String>> fetchBlossomServerList({
    required String publicKeyHex,
    List<String>? relays,
  }) async {
    final explicitRelays = relays ?? await loadRelayList();
    await connect();
    final events = await queryEvents(
      filter: Filter(
        authors: [publicKeyHex],
        kinds: [MarmotKinds.blossomServers],
        limit: 1,
      ),
      relays: explicitRelays,
      timeout: const Duration(seconds: 3),
    );
    if (events.isEmpty) {
      return const [];
    }
    return _extractBlossomServers(events.first);
  }

  @override
  Future<NdkResponse> subscribe({
    required String subscriptionId,
    required Filter filter,
    List<String>? relays,
  }) async {
    final explicitRelays = relays ?? await loadRelayList();
    await connect();
    return _ndk.requests.subscription(
      id: subscriptionId,
      filter: filter,
      explicitRelays: explicitRelays,
      cacheRead: false,
      cacheWrite: false,
    );
  }

  @override
  Future<List<Nip01Event>> queryEvents({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  }) async {
    final explicitRelays = relays ?? await loadRelayList();
    await connect();
    final response = _ndk.requests.query(
      filter: filter,
      explicitRelays: explicitRelays,
      cacheRead: false,
      cacheWrite: false,
      timeout: timeout,
    );
    return response.future;
  }

  @override
  Future<void> unsubscribe(String subscriptionId) {
    return _ndk.requests.closeSubscription(subscriptionId);
  }

  @override
  Future<String> publishGiftWrappedRumor({
    required ParentIdentity identity,
    required String rumorEventJson,
    required String recipientPublicKeyHex,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final publishRelays = relays ?? await loadRelayList();
    await connect();

    final rumor = Nip01EventModel.fromJson(
      jsonDecode(rumorEventJson) as Map<String, dynamic>,
    );
    final giftWrap = await _ndk.giftWrap.toGiftWrap(
      rumor: rumor,
      recipientPubkey: recipientPublicKeyHex,
    );

    final response = _ndk.broadcast.broadcast(
      nostrEvent: Nip01EventModel.fromEntity(giftWrap),
      specificRelays: publishRelays,
    );
    await response.broadcastDoneFuture;
    return response.publishEvent.id;
  }

  @override
  Future<String?> unwrapGiftWrapRumorJson({
    required ParentIdentity identity,
    required Nip01Event giftWrapEvent,
  }) async {
    _ensureLoggedIn(identity);
    final rumor = await _ndk.giftWrap.fromGiftWrap(giftWrap: giftWrapEvent);
    return Nip01EventModel.fromEntity(rumor).toJsonString();
  }

  void _ensureLoggedIn(ParentIdentity identity) {
    if (!_ndk.accounts.hasAccount(identity.publicKeyHex)) {
      _ndk.accounts.loginPrivateKey(
        pubkey: identity.publicKeyHex,
        privkey: identity.privateKeyHex,
      );
    } else {
      _ndk.accounts.switchAccount(pubkey: identity.publicKeyHex);
    }
  }

  List<List<String>> _decodeTags(String tagsJson) {
    final decoded = jsonDecode(tagsJson);
    if (decoded is! List) {
      throw const FormatException('Invalid Nostr tag payload');
    }

    return decoded
        .map<List<String>>((item) {
          if (item is! List) {
            throw const FormatException('Invalid Nostr tag entry');
          }
          return item.map((value) => value.toString()).toList(growable: false);
        })
        .toList(growable: false);
  }

  List<String> _extractBlossomServers(Nip01Event event) {
    return _normalizeUrls(
      event.tags
          .where((tag) => tag.isNotEmpty && tag.first == 'server')
          .map((tag) => tag.length > 1 ? tag[1] : '')
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
    );
  }

  List<String> _normalizeUrls(List<String> urls) {
    return urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}

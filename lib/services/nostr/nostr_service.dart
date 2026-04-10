import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/parent_identity.dart';

abstract class NostrService {
  Future<List<String>> loadRelayList();
  Future<void> saveRelayList(List<String> relays);
  Future<List<String>> loadBlossomServerList();
  Future<void> saveBlossomServerList(List<String> servers);
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
  Future<String> publishBlossomServerList({
    required ParentIdentity identity,
    List<String>? servers,
    List<String>? relays,
  });
  Future<List<String>> fetchBlossomServerList({
    required String publicKeyHex,
    List<String>? relays,
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
}

class NdkNostrService implements NostrService {
  NdkNostrService(this._database) : _ndk = Ndk.emptyBootstrapRelaysConfig();

  final AppDatabase _database;
  final Ndk _ndk;

  @override
  Future<List<String>> loadRelayList() async {
    final raw = await _database.getSetting(AppConstants.relayListSettingKey);
    if (raw == null || raw.isEmpty) {
      return AppConstants.defaultRelays;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return AppConstants.defaultRelays;
    }
    return decoded.map((item) => item.toString()).toList(growable: false);
  }

  @override
  Future<void> saveRelayList(List<String> relays) {
    final normalized = _normalizeUrls(relays);
    return _database.putSetting(
      AppConstants.relayListSettingKey,
      jsonEncode(normalized),
    );
  }

  @override
  Future<List<String>> loadBlossomServerList() async {
    final raw = await _database.getSetting(
      AppConstants.blossomServerListSettingKey,
    );
    if (raw == null || raw.isEmpty) {
      return AppConstants.defaultBlossomServers;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return AppConstants.defaultBlossomServers;
    }
    final servers = decoded
        .map((item) => item.toString())
        .toList(growable: false);
    return servers.isEmpty ? AppConstants.defaultBlossomServers : servers;
  }

  @override
  Future<void> saveBlossomServerList(List<String> servers) {
    final normalized = _normalizeUrls(servers);
    return _database.putSetting(
      AppConstants.blossomServerListSettingKey,
      jsonEncode(
        normalized.isEmpty ? AppConstants.defaultBlossomServers : normalized,
      ),
    );
  }

  @override
  Future<void> connect() async {
    final relays = await loadRelayList();
    await Future.wait(
      relays.map(
        (relay) => _ndk.relays.connectRelay(
          dirtyUrl: relay,
          connectionSource: ConnectionSource.explicit,
        ),
      ),
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
    await connect();

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
    await response.broadcastDoneFuture;
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
    await connect();

    final event = Nip01EventModel.fromJson(
      jsonDecode(eventJson) as Map<String, dynamic>,
    );
    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    await response.broadcastDoneFuture;
    return response.publishEvent.id;
  }

  @override
  Future<String> publishBlossomServerList({
    required ParentIdentity identity,
    List<String>? servers,
    List<String>? relays,
  }) async {
    _ensureLoggedIn(identity);
    final publishRelays = relays ?? await loadRelayList();
    final activeServers = _normalizeUrls(
      servers ?? await loadBlossomServerList(),
    );
    if (activeServers.isEmpty) {
      throw const FormatException('At least one Blossom server is required');
    }

    await saveBlossomServerList(activeServers);
    await connect();

    final event = Nip01Event(
      pubKey: identity.publicKeyHex,
      kind: MarmotKinds.blossomServers,
      tags: activeServers
          .map((server) => <String>['server', server])
          .toList(growable: false),
      content: '',
    );

    final response = _ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: publishRelays,
    );
    await response.broadcastDoneFuture;
    return response.publishEvent.id;
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

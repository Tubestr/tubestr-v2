import 'dart:convert';

import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../domain/models/blossom_server_list.dart';
import '../../domain/models/mute_list.dart';
import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../../domain/models/relay_entry.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';

/// Coordinates fetch, publish, and local caching of kind-10002 (NIP-65 relay
/// list), kind-10063 (Blossom server list), and kind-10000 (NIP-51 mute list)
/// events.
class UserListSyncService {
  UserListSyncService({
    required NostrService nostrService,
    required OfflineActionStore offlineActionStore,
  }) : _nostrService = nostrService,
       _offlineActionStore = offlineActionStore;

  final NostrService _nostrService;
  final OfflineActionStore _offlineActionStore;

  Future<RelayList> loadRelayList() {
    return _nostrService.loadRelayListFull();
  }

  Future<BlossomServerList> loadBlossomServerList() {
    return _nostrService.loadBlossomServerListFull();
  }

  Future<MuteList> loadMuteList() {
    return _nostrService.loadMuteList();
  }

  /// Fetches the published relay list, Blossom server list, and mute list
  /// for [identity] and reconciles them with local state. Publishes local
  /// defaults if no remote event exists yet.
  Future<void> hydrateFromRelays({required ParentIdentity identity}) async {
    await _hydrateRelayList(identity);
    await _hydrateBlossomList(identity);
    await _hydrateMuteList(identity);
  }

  Future<void> _hydrateRelayList(ParentIdentity identity) async {
    final local = await _nostrService.loadRelayListFull();
    final bootstrapRelays = local.entries.isNotEmpty
        ? local.urls
        : AppConstants.defaultRelays;

    Nip01Event? remoteEvent;
    try {
      remoteEvent = await _nostrService.fetchRelayListEvent(
        publicKeyHex: identity.publicKeyHex,
        relays: bootstrapRelays,
      );
    } catch (_) {
      return;
    }

    if (remoteEvent != null) {
      final remote = NostrService.parseRelayListEvent(remoteEvent);
      if (remote.entries.isEmpty) {
        return;
      }
      final localUpdated = local.updatedAt;
      if (localUpdated == null ||
          (remote.updatedAt != null &&
              remote.updatedAt!.isAfter(localUpdated))) {
        await _nostrService.saveRelayListFull(remote);
      }
      return;
    }

    // No remote event — if we have local content that's never been published,
    // seed the relays now. Covers the new-user case where defaults have been
    // accepted but never pushed, and legacy installs missing updatedAt.
    if (local.updatedAt == null) {
      final seedEntries = local.entries.isEmpty
          ? AppConstants.defaultRelays
                .map((url) => RelayEntry(url: url))
                .toList(growable: false)
          : local.entries;
      await _publishRelayList(
        identity: identity,
        entries: seedEntries,
        queueOnFailure: false,
      );
    }
  }

  Future<void> _hydrateMuteList(ParentIdentity identity) async {
    final local = await _nostrService.loadMuteList();

    Nip01Event? remoteEvent;
    try {
      remoteEvent = await _nostrService.fetchMuteListEvent(
        publicKeyHex: identity.publicKeyHex,
      );
    } catch (_) {
      return;
    }

    if (remoteEvent == null) {
      return;
    }
    final MuteList remote;
    try {
      remote = await _nostrService.parseMuteListEventFor(
        identity: identity,
        event: remoteEvent,
      );
    } catch (_) {
      return;
    }
    if (remote.entries.isEmpty) {
      return;
    }
    final localUpdated = local.updatedAt;
    if (localUpdated == null ||
        (remote.updatedAt != null && remote.updatedAt!.isAfter(localUpdated))) {
      await _nostrService.saveMuteList(remote);
    }
  }

  Future<void> _hydrateBlossomList(ParentIdentity identity) async {
    final local = await _nostrService.loadBlossomServerListFull();

    Nip01Event? remoteEvent;
    try {
      remoteEvent = await _nostrService.fetchBlossomServerListEvent(
        publicKeyHex: identity.publicKeyHex,
      );
    } catch (_) {
      return;
    }

    if (remoteEvent != null) {
      final remote = NostrService.parseBlossomServerListEvent(remoteEvent);
      if (remote.servers.isEmpty) {
        return;
      }
      final localUpdated = local.updatedAt;
      if (localUpdated == null ||
          (remote.updatedAt != null &&
              remote.updatedAt!.isAfter(localUpdated))) {
        await _nostrService.saveBlossomServerListFull(remote);
      }
      return;
    }

    if (local.updatedAt == null) {
      final seedServers = local.servers.isEmpty
          ? AppConstants.defaultBlossomServers
          : local.servers;
      await _publishBlossomServerList(
        identity: identity,
        servers: seedServers,
        queueOnFailure: false,
      );
    }
  }

  /// Saves [entries] locally and publishes a fresh kind-10002 event.
  /// If publishing fails, the publish is queued for later retry; local state
  /// is still updated.
  Future<void> saveAndPublishRelayList({
    required ParentIdentity identity,
    required List<RelayEntry> entries,
  }) async {
    final now = DateTime.now().toUtc();
    await _nostrService.saveRelayListFull(
      RelayList(entries: entries, updatedAt: now),
    );
    await _publishRelayList(
      identity: identity,
      entries: entries,
      queueOnFailure: true,
    );
  }

  /// Saves [servers] locally and publishes a fresh kind-10063 event.
  /// If publishing fails, the publish is queued for later retry; local state
  /// is still updated.
  Future<void> saveAndPublishBlossomServerList({
    required ParentIdentity identity,
    required List<String> servers,
  }) async {
    final now = DateTime.now().toUtc();
    await _nostrService.saveBlossomServerListFull(
      BlossomServerList(servers: servers, updatedAt: now),
    );
    await _publishBlossomServerList(
      identity: identity,
      servers: servers,
      queueOnFailure: true,
    );
  }

  /// Saves [entries] locally and publishes a fresh kind-10000 mute list.
  /// If publishing fails, the publish is queued for later retry; local state
  /// is still updated.
  Future<void> saveAndPublishMuteList({
    required ParentIdentity identity,
    required List<MuteEntry> entries,
  }) async {
    final now = DateTime.now().toUtc();
    await _nostrService.saveMuteList(
      MuteList(entries: entries, updatedAt: now),
    );
    await _publishMuteList(
      identity: identity,
      entries: entries,
      queueOnFailure: true,
    );
  }

  Future<void> _publishMuteList({
    required ParentIdentity identity,
    required List<MuteEntry> entries,
    required bool queueOnFailure,
  }) async {
    try {
      final result = await _nostrService.publishMuteList(
        identity: identity,
        entries: entries,
      );
      await _nostrService.saveMuteList(
        MuteList(entries: entries, updatedAt: result.createdAt),
      );
    } catch (_) {
      if (queueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.publishMuteList,
          payload: <String, dynamic>{
            'entries_json': jsonEncode(
              entries.map((entry) => entry.toJson()).toList(),
            ),
          },
        );
      }
      rethrow;
    }
  }

  Future<void> replayMuteListPublish({
    required ParentIdentity identity,
    required Map<String, dynamic> payload,
  }) async {
    final entriesRaw = payload['entries_json']?.toString() ?? '';
    if (entriesRaw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(entriesRaw);
    if (decoded is! List) {
      return;
    }
    final entries = decoded
        .whereType<Map>()
        .map((raw) => MuteEntry.fromJson(Map<String, dynamic>.from(raw)))
        .where((entry) => entry.pubkeyHex.isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      return;
    }
    await _publishMuteList(
      identity: identity,
      entries: entries,
      queueOnFailure: false,
    );
  }

  Future<void> _publishRelayList({
    required ParentIdentity identity,
    required List<RelayEntry> entries,
    required bool queueOnFailure,
  }) async {
    try {
      final result = await _nostrService.publishRelayList(
        identity: identity,
        entries: entries,
      );
      await _nostrService.saveRelayListFull(
        RelayList(entries: entries, updatedAt: result.createdAt),
      );
    } catch (_) {
      if (queueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.publishRelayList,
          payload: <String, dynamic>{
            'entries_json': jsonEncode(
              entries.map((entry) => entry.toJson()).toList(),
            ),
          },
        );
      }
      rethrow;
    }
  }

  Future<void> _publishBlossomServerList({
    required ParentIdentity identity,
    required List<String> servers,
    required bool queueOnFailure,
  }) async {
    try {
      final result = await _nostrService.publishBlossomServerList(
        identity: identity,
        servers: servers,
      );
      await _nostrService.saveBlossomServerListFull(
        BlossomServerList(servers: servers, updatedAt: result.createdAt),
      );
    } catch (_) {
      if (queueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.publishBlossomServerList,
          payload: <String, dynamic>{'servers': servers},
        );
      }
      rethrow;
    }
  }

  /// Replays a queued relay-list publish. Does not touch the local cache on
  /// success beyond what [_publishRelayList] already does (which sets
  /// updatedAt to the event's createdAt).
  Future<void> replayRelayListPublish({
    required ParentIdentity identity,
    required Map<String, dynamic> payload,
  }) async {
    final entriesRaw = payload['entries_json']?.toString() ?? '';
    if (entriesRaw.isEmpty) {
      return;
    }
    final decoded = jsonDecode(entriesRaw);
    if (decoded is! List) {
      return;
    }
    final entries = decoded
        .whereType<Map>()
        .map((raw) => RelayEntry.fromJson(Map<String, dynamic>.from(raw)))
        .where((entry) => entry.url.isNotEmpty)
        .toList(growable: false);
    if (entries.isEmpty) {
      return;
    }
    await _publishRelayList(
      identity: identity,
      entries: entries,
      queueOnFailure: false,
    );
  }

  Future<void> replayBlossomServerListPublish({
    required ParentIdentity identity,
    required Map<String, dynamic> payload,
  }) async {
    final rawServers = payload['servers'];
    final servers = rawServers is List
        ? rawServers
              .map((item) => item.toString().trim())
              .where((url) => url.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    if (servers.isEmpty) {
      return;
    }
    await _publishBlossomServerList(
      identity: identity,
      servers: servers,
      queueOnFailure: false,
    );
  }
}

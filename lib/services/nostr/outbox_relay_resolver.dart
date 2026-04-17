import 'package:ndk/entities.dart';

import '../../domain/models/relay_entry.dart';
import 'nostr_service.dart';

/// NIP-65 outbox-model relay resolver.
///
/// Caches other users' kind-10002 lists and produces union relay sets for
/// reads and writes. "Union" semantics are intentional: if a pubkey has no
/// published kind-10002 (or fetch fails), the union degenerates to the local
/// relay pool, so callers never regress past today's behavior.
class OutboxRelayResolver {
  OutboxRelayResolver({
    required NostrService nostrService,
    Duration ttl = const Duration(hours: 1),
    int maxEntries = 256,
    int unionCap = 8,
    DateTime Function()? now,
  }) : _nostrService = nostrService,
       _ttl = ttl,
       _maxEntries = maxEntries,
       _unionCap = unionCap,
       _now = now ?? DateTime.now;

  final NostrService _nostrService;
  final Duration _ttl;
  final int _maxEntries;
  final int _unionCap;
  final DateTime Function() _now;

  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  /// Returns the pubkey's write relays — where they publish — which is where
  /// we should query to READ their events.
  Future<List<String>> readRelaysFor(String pubkeyHex) async {
    final entries = await _entriesFor(pubkeyHex);
    return _filterByMarker(entries, wantsWrite: true);
  }

  /// Returns the pubkey's read relays — where they listen — which is where
  /// we should publish events addressed to them.
  Future<List<String>> writeRelaysFor(String pubkeyHex) async {
    final entries = await _entriesFor(pubkeyHex);
    return _filterByMarker(entries, wantsWrite: false);
  }

  /// Local ∪ authorWriteRelays, capped at [_unionCap]. Local relays are kept
  /// first so the guaranteed-reachable pool is never dropped by truncation.
  Future<List<String>> unionForRead(String pubkeyHex) async {
    final local = await _nostrService.loadRelayList();
    final remote = await readRelaysFor(pubkeyHex);
    return _capUnion(local, remote);
  }

  /// Local ∪ recipientReadRelays, capped at [_unionCap].
  Future<List<String>> unionForWrite(String pubkeyHex) async {
    final local = await _nostrService.loadRelayList();
    final remote = await writeRelaysFor(pubkeyHex);
    return _capUnion(local, remote);
  }

  /// Seeds the cache from a kind-10002 event observed elsewhere (subscription,
  /// query, etc.). Ignores non-kind-10002 events. Silently overwrites older
  /// cached entries.
  void observe(Nip01Event event) {
    if (event.kind != 10002) {
      return;
    }
    final entries = _parseEntries(event);
    _store(event.pubKey, entries);
  }

  /// Drops a pubkey from the cache. Mainly useful in tests or when we know
  /// the remote list has changed.
  void invalidate(String pubkeyHex) {
    _cache.remove(pubkeyHex);
  }

  Future<List<RelayEntry>> _entriesFor(String pubkeyHex) async {
    final cached = _cache[pubkeyHex];
    if (cached != null && !_isExpired(cached)) {
      return cached.entries;
    }

    Nip01Event? event;
    try {
      event = await _nostrService.fetchRelayListEvent(publicKeyHex: pubkeyHex);
    } catch (_) {
      event = null;
    }

    final entries = event == null ? const <RelayEntry>[] : _parseEntries(event);
    _store(pubkeyHex, entries);
    return entries;
  }

  List<RelayEntry> _parseEntries(Nip01Event event) {
    final list = NostrService.parseRelayListEvent(event);
    return list.entries;
  }

  void _store(String pubkeyHex, List<RelayEntry> entries) {
    if (_cache.length >= _maxEntries && !_cache.containsKey(pubkeyHex)) {
      // Evict the oldest entry. Cheap enough at 256 keys; if this becomes hot,
      // swap in an LRU.
      String? oldestKey;
      DateTime? oldestAt;
      for (final entry in _cache.entries) {
        if (oldestAt == null || entry.value.fetchedAt.isBefore(oldestAt)) {
          oldestAt = entry.value.fetchedAt;
          oldestKey = entry.key;
        }
      }
      if (oldestKey != null) {
        _cache.remove(oldestKey);
      }
    }
    _cache[pubkeyHex] = _CacheEntry(entries: entries, fetchedAt: _now());
  }

  bool _isExpired(_CacheEntry entry) {
    return _now().difference(entry.fetchedAt) > _ttl;
  }

  List<String> _filterByMarker(
    List<RelayEntry> entries, {
    required bool wantsWrite,
  }) {
    final result = <String>[];
    final seen = <String>{};
    for (final entry in entries) {
      final includes = wantsWrite
          ? entry.marker != RelayMarker.read
          : entry.marker != RelayMarker.write;
      if (!includes) {
        continue;
      }
      if (seen.add(entry.url)) {
        result.add(entry.url);
      }
    }
    return result;
  }

  List<String> _capUnion(List<String> local, List<String> remote) {
    final seen = <String>{};
    final out = <String>[];
    for (final url in local) {
      if (seen.add(url)) {
        out.add(url);
        if (out.length >= _unionCap) {
          return out;
        }
      }
    }
    for (final url in remote) {
      if (seen.add(url)) {
        out.add(url);
        if (out.length >= _unionCap) {
          return out;
        }
      }
    }
    return out;
  }
}

class _CacheEntry {
  _CacheEntry({required this.entries, required this.fetchedAt});

  final List<RelayEntry> entries;
  final DateTime fetchedAt;
}

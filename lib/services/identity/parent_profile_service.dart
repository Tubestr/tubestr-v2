import 'dart:convert';

import 'package:ndk/entities.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../../domain/models/parent_profile.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';

class ParentProfileService {
  const ParentProfileService({
    required AppDatabase database,
    required NostrService nostrService,
    required OfflineActionStore offlineActionStore,
  }) : _database = database,
       _nostrService = nostrService,
       _offlineActionStore = offlineActionStore;

  final AppDatabase _database;
  final NostrService _nostrService;
  final OfflineActionStore _offlineActionStore;

  Future<String?> loadLocalDisplayName() {
    return _database.getSetting(AppConstants.parentDisplayNameSettingKey);
  }

  Future<void> saveLocalDisplayName(String displayName) {
    return _database.putSetting(
      AppConstants.parentDisplayNameSettingKey,
      displayName.trim(),
    );
  }

  Future<ParentProfile> publishLocalProfile({
    required ParentIdentity identity,
    required String displayName,
    bool allowQueueOnFailure = true,
  }) async {
    final normalized = displayName.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Display name is required.');
    }
    await saveLocalDisplayName(normalized);
    await _cacheProfile(
      ParentProfile(
        publicKeyHex: identity.publicKeyHex,
        displayName: normalized,
        about: 'Parent account for Tubestr',
        updatedAt: DateTime.now(),
      ),
    );
    try {
      await _nostrService.publishParentProfile(
        identity: identity,
        displayName: normalized,
      );
    } catch (error) {
      if (allowQueueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.publishParentProfile,
          payload: <String, dynamic>{'display_name': normalized},
        );
      }
      rethrow;
    }
    return ParentProfile(
      publicKeyHex: identity.publicKeyHex,
      displayName: normalized,
      about: 'Parent account for Tubestr',
      updatedAt: DateTime.now(),
    );
  }

  Future<ParentProfile?> resolveProfile({
    required String publicKeyHex,
    ParentIdentity? localIdentity,
    bool refresh = false,
  }) async {
    if (!refresh) {
      final cached = await _loadCachedProfile(publicKeyHex);
      if (cached != null) {
        return cached;
      }
    }

    if (localIdentity != null && localIdentity.publicKeyHex == publicKeyHex) {
      final displayName = await loadLocalDisplayName();
      if (displayName != null && displayName.isNotEmpty) {
        final profile = ParentProfile(
          publicKeyHex: publicKeyHex,
          displayName: displayName,
          about: 'Parent account for Tubestr',
          updatedAt: DateTime.now(),
        );
        await _cacheProfile(profile);
        return profile;
      }
    }

    final events = await _nostrService.queryEvents(
      filter: Filter(authors: [publicKeyHex], kinds: const [0], limit: 1),
      timeout: const Duration(seconds: 2),
    );
    if (events.isEmpty) {
      return null;
    }
    final event = events.first;
    final content = jsonDecode(event.content) as Map<String, dynamic>;
    final displayName =
        content['display_name']?.toString() ??
        content['displayName']?.toString() ??
        content['name']?.toString();
    if (displayName == null || displayName.isEmpty) {
      return null;
    }
    final profile = ParentProfile(
      publicKeyHex: publicKeyHex,
      displayName: displayName,
      about: content['about']?.toString(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(event.createdAt * 1000),
    );
    await _cacheProfile(profile);
    return profile;
  }

  Future<Map<String, ParentProfile>> resolveProfiles({
    required Iterable<String> publicKeysHex,
    ParentIdentity? localIdentity,
    bool refresh = false,
  }) async {
    final result = <String, ParentProfile>{};
    for (final pubkey in publicKeysHex.toSet()) {
      final profile = await resolveProfile(
        publicKeyHex: pubkey,
        localIdentity: localIdentity,
        refresh: refresh,
      );
      if (profile != null) {
        result[pubkey] = profile;
      }
    }
    return result;
  }

  Future<void> primeKnownProfiles({
    required Iterable<String> publicKeysHex,
    ParentIdentity? localIdentity,
  }) async {
    await resolveProfiles(
      publicKeysHex: publicKeysHex,
      localIdentity: localIdentity,
      refresh: false,
    );
  }

  Future<ParentProfile?> _loadCachedProfile(String publicKeyHex) async {
    final raw = await _database.getSetting(
      '${AppConstants.parentProfileCachePrefix}$publicKeyHex',
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return ParentProfile.decode(raw);
  }

  Future<void> _cacheProfile(ParentProfile profile) {
    return _database.putSetting(
      '${AppConstants.parentProfileCachePrefix}${profile.publicKeyHex}',
      profile.encode(),
    );
  }
}

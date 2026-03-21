import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';

class SafetyHqBootstrap {
  const SafetyHqBootstrap({
    required this.servicePublicKeyHex,
    required this.signedKeyPackageEventJson,
    required this.keyPackageEventId,
    required this.relays,
    required this.version,
    required this.generatedAt,
  });

  final String servicePublicKeyHex;
  final String signedKeyPackageEventJson;
  final String keyPackageEventId;
  final List<String> relays;
  final String version;
  final DateTime? generatedAt;
}

class SafetyHqStatus {
  const SafetyHqStatus({
    required this.isQueued,
    required this.isJoined,
    required this.groupId,
    required this.lastSyncAt,
    required this.servicePublicKeyHex,
  });

  final bool isQueued;
  final bool isJoined;
  final String? groupId;
  final DateTime? lastSyncAt;
  final String? servicePublicKeyHex;

  bool get isProvisioning =>
      !isJoined &&
      groupId != null &&
      groupId!.isNotEmpty &&
      servicePublicKeyHex != null &&
      servicePublicKeyHex!.isNotEmpty;

  String get label {
    if (isJoined) {
      return 'Provisioned';
    }
    if (isProvisioning) {
      return 'Connecting';
    }
    if (isQueued) {
      return 'Queued';
    }
    return 'Not configured';
  }

  String get detail {
    if (isJoined) {
      return 'Safety HQ is provisioned and ready to receive higher-risk family alerts.';
    }
    if (isProvisioning) {
      return 'Tubestr has already sent the setup welcome. This turns ready once the moderation service joins the group over the relay network.';
    }
    if (isQueued) {
      return 'Safety HQ setup is queued and will start as soon as this device can reach the moderation relays.';
    }
    return 'Set up Safety HQ to keep a separate copy of higher-risk family alerts in Tubestr moderation.';
  }
}

class SafetyHqService {
  SafetyHqService({
    required AppDatabase database,
    required MdkService mdkService,
    required NostrService nostrService,
    required Dio dio,
    String? apiBaseUrl,
  }) : _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _dio = dio,
       _apiBaseUrl = apiBaseUrl ?? defaultApiBaseUrl;

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'TUBESTR_API_URL',
    defaultValue: 'https://api.tubestr.app',
  );

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final Dio _dio;
  final String _apiBaseUrl;

  Future<SafetyHqStatus> loadStatus() async {
    final queued =
        await _database.getSetting(AppConstants.safetyJoinQueuedKey) == 'true';
    final joined =
        await _database.getSetting(AppConstants.safetyJoinedKey) == 'true';
    final groupId = await _database.getSetting(
      AppConstants.safetyGroupIdSettingKey,
    );
    final servicePublicKeyHex = await _database.getSetting(
      AppConstants.safetyServicePubkeySettingKey,
    );
    final lastSyncRaw = await _database.getSetting(
      AppConstants.safetyLastSyncAtSettingKey,
    );
    final lastSyncAt = lastSyncRaw == null || lastSyncRaw.isEmpty
        ? null
        : DateTime.tryParse(lastSyncRaw);

    return SafetyHqStatus(
      isQueued: queued,
      isJoined: joined,
      groupId: groupId,
      lastSyncAt: lastSyncAt,
      servicePublicKeyHex: servicePublicKeyHex,
    );
  }

  Future<SafetyHqBootstrap> fetchBootstrap() async {
    final baseUrl = _apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw const FormatException(
        'This build is missing the Tubestr Safety HQ API URL.',
      );
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '$baseUrl/v1/safety-hq/bootstrap',
    );
    final data = response.data ?? const <String, dynamic>{};
    final servicePublicKeyHex =
        data['service_public_key_hex']?.toString().trim() ?? '';
    final signedKeyPackageEventJson =
        data['signed_key_package_event_json']?.toString().trim() ?? '';
    final keyPackageEventId =
        data['key_package_event_id']?.toString().trim() ?? '';
    final rawRelays = data['relays'];
    final relays = rawRelays is List
        ? rawRelays
              .map((relay) => relay.toString().trim())
              .where((relay) => relay.isNotEmpty)
              .toList(growable: false)
        : const <String>[];
    final version = data['version']?.toString().trim() ?? '';
    final generatedAtRaw = data['generated_at']?.toString().trim();

    if (servicePublicKeyHex.isEmpty ||
        signedKeyPackageEventJson.isEmpty ||
        keyPackageEventId.isEmpty ||
        relays.isEmpty) {
      throw const FormatException(
        'Tubestr Safety HQ bootstrap data is incomplete.',
      );
    }

    return SafetyHqBootstrap(
      servicePublicKeyHex: servicePublicKeyHex,
      signedKeyPackageEventJson: signedKeyPackageEventJson,
      keyPackageEventId: keyPackageEventId,
      relays: relays,
      version: version,
      generatedAt: generatedAtRaw == null || generatedAtRaw.isEmpty
          ? null
          : DateTime.tryParse(generatedAtRaw),
    );
  }

  Future<MdkGroupSummary?> ensureProvisioned({
    required ParentIdentity identity,
  }) async {
    final status = await refreshEnrollment();
    if (status.isJoined) {
      return null;
    }
    if (!status.isQueued && !status.isProvisioning) {
      return null;
    }
    if (status.isProvisioning) {
      final existingGroupId = status.groupId?.trim() ?? '';
      if (existingGroupId.isNotEmpty) {
        final existing = await _findGroupSummary(existingGroupId);
        if (existing != null) {
          return existing;
        }
      }
    }

    final bootstrap = await fetchBootstrap();
    final relays = await _loadProvisioningRelays(bootstrap.relays);
    final result = await _mdkService.createGroupWithWelcomes(
      creatorPublicKeyHex: identity.publicKeyHex,
      name: AppConstants.safetyHqGroupName,
      description: 'Backend-backed moderation inbox for Tubestr reports.',
      relays: relays,
      memberKeyPackageEventJsons: [bootstrap.signedKeyPackageEventJson],
    );

    for (final rumorJson in result.welcomeRumorJsons) {
      await _nostrService.publishGiftWrappedRumor(
        identity: identity,
        rumorEventJson: rumorJson,
        recipientPublicKeyHex: bootstrap.servicePublicKeyHex,
        relays: relays,
      );
    }

    await _markPendingEnrollment(
      groupId: result.group.mlsGroupIdHex,
      servicePublicKeyHex: bootstrap.servicePublicKeyHex,
      relays: relays,
    );
    return result.group;
  }

  Future<void> queueJoin() async {
    final status = await loadStatus();
    await _database.putSetting(
      AppConstants.safetyJoinQueuedKey,
      status.isProvisioning ? 'false' : 'true',
    );
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
  }

  Future<SafetyHqStatus> refreshEnrollment() async {
    final status = await loadStatus();
    if (status.isJoined) {
      return status;
    }

    final groupId = status.groupId?.trim() ?? '';
    final servicePublicKeyHex = status.servicePublicKeyHex?.trim() ?? '';
    if (groupId.isEmpty || servicePublicKeyHex.isEmpty) {
      return status;
    }
    final normalizedServicePubkey = servicePublicKeyHex.toLowerCase();

    try {
      final members = await _mdkService.getGroupMembers(mlsGroupIdHex: groupId);
      final joined = members.any(
        (member) => member.trim().toLowerCase() == normalizedServicePubkey,
      );
      if (joined) {
        await acknowledgeBackendEnrollment(
          groupId: groupId,
          servicePublicKeyHex: servicePublicKeyHex,
        );
      }
    } catch (_) {
      // Sync can lag behind UI refreshes; keep the current provisioning state.
    }

    return loadStatus();
  }

  Future<void> acknowledgeBackendEnrollment({
    required String groupId,
    required String servicePublicKeyHex,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'false');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'true');
    await _database.putSetting(AppConstants.safetyGroupIdSettingKey, groupId);
    await _database.putSetting(
      AppConstants.safetyServicePubkeySettingKey,
      servicePublicKeyHex,
    );
    await _database.putSetting(AppConstants.safetyLastSyncAtSettingKey, nowIso);
  }

  Future<List<String>> loadProvisionedRelays() async {
    final raw = await _database.getSetting(
      AppConstants.safetyRelayListSettingKey,
    );
    if (raw == null || raw.isEmpty) {
      return const <String>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <String>[];
    }
    return decoded
        .map((relay) => relay.toString().trim())
        .where((relay) => relay.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> saveProvisionedRelays(List<String> relays) {
    final normalized = relays
        .map((relay) => relay.trim())
        .where((relay) => relay.isNotEmpty)
        .toList(growable: false);
    return _database.putSetting(
      AppConstants.safetyRelayListSettingKey,
      jsonEncode(normalized),
    );
  }

  Future<List<String>> _loadProvisioningRelays(
    List<String> bootstrapRelays,
  ) async {
    final localRelays = await _nostrService.loadRelayList();
    final merged = <String>[];
    for (final relay in [...localRelays, ...bootstrapRelays]) {
      final normalized = relay.trim();
      if (normalized.isEmpty || merged.contains(normalized)) {
        continue;
      }
      merged.add(normalized);
    }
    return merged;
  }

  Future<MdkGroupSummary?> _findGroupSummary(String groupId) async {
    final groups = await _mdkService.getGroupSummaries();
    for (final group in groups) {
      if (group.mlsGroupIdHex == groupId) {
        return group;
      }
    }
    return null;
  }

  Future<void> _markPendingEnrollment({
    required String groupId,
    required String servicePublicKeyHex,
    required List<String> relays,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'false');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
    await _database.putSetting(AppConstants.safetyGroupIdSettingKey, groupId);
    await _database.putSetting(
      AppConstants.safetyServicePubkeySettingKey,
      servicePublicKeyHex,
    );
    await _database.putSetting(AppConstants.safetyLastSyncAtSettingKey, nowIso);
    await saveProvisionedRelays(relays);
  }
}

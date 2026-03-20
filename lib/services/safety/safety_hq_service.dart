import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import 'safety_hq_backend_client.dart';

class SafetyHqStatus {
  const SafetyHqStatus({
    required this.isQueued,
    required this.isJoined,
    required this.needsRetry,
    required this.groupId,
    required this.lastSyncAt,
    required this.lastError,
    required this.servicePublicKeyHex,
  });

  final bool isQueued;
  final bool isJoined;
  final bool needsRetry;
  final String? groupId;
  final DateTime? lastSyncAt;
  final String? lastError;
  final String servicePublicKeyHex;

  String get label {
    if (isJoined) {
      return 'Provisioned';
    }
    if (needsRetry) {
      return 'Needs retry';
    }
    if (isQueued) {
      return 'Queued';
    }
    return 'Not configured';
  }
}

class SafetyHqService {
  SafetyHqService({
    required AppDatabase database,
    required MdkService mdkService,
    required NostrService nostrService,
    required SafetyHqBackendClient backendClient,
  }) : _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _backendClient = backendClient;

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final SafetyHqBackendClient _backendClient;

  Future<SafetyHqStatus> loadStatus() async {
    final queued =
        await _database.getSetting(AppConstants.safetyJoinQueuedKey) == 'true';
    final joinedSetting =
        await _database.getSetting(AppConstants.safetyJoinedKey) == 'true';
    final groupId = await _database.getSetting(
      AppConstants.safetyGroupIdSettingKey,
    );
    final lastSyncRaw = await _database.getSetting(
      AppConstants.safetyLastSyncAtSettingKey,
    );
    final lastSyncAt = lastSyncRaw == null || lastSyncRaw.isEmpty
        ? null
        : DateTime.tryParse(lastSyncRaw);
    final lastError = await _database.getSetting(
      AppConstants.safetyLastErrorSettingKey,
    );
    final persistedServicePublicKey = await _database.getSetting(
      AppConstants.safetyServicePublicKeySettingKey,
    );
    final normalizedServicePublicKey = persistedServicePublicKey
        ?.trim()
        .toLowerCase();
    final normalizedLastError = lastError?.trim();
    final servicePublicKeyHex =
        normalizedServicePublicKey != null &&
            normalizedServicePublicKey.isNotEmpty
        ? normalizedServicePublicKey
        : AppConstants.safetyHqServicePublicKeyHex;
    final verifiedJoined = await _groupIncludesService(
      groupId: groupId,
      servicePublicKeyHex: servicePublicKeyHex,
    );
    final needsRetry =
        !verifiedJoined &&
        (joinedSetting ||
            (normalizedLastError != null && normalizedLastError.isNotEmpty) ||
            ((groupId?.isNotEmpty ?? false) && !queued));

    return SafetyHqStatus(
      isQueued: queued,
      isJoined: verifiedJoined,
      needsRetry: needsRetry,
      groupId: groupId,
      lastSyncAt: lastSyncAt,
      lastError: normalizedLastError == null || normalizedLastError.isEmpty
          ? null
          : normalizedLastError,
      servicePublicKeyHex: servicePublicKeyHex,
    );
  }

  Future<String?> loadProvisionedGroupId() async {
    final status = await loadStatus();
    if (!status.isJoined) {
      return null;
    }
    final groupId = status.groupId?.trim();
    return groupId == null || groupId.isEmpty ? null : groupId;
  }

  Future<MdkGroupSummary?> ensureProvisioned({
    required ParentIdentity identity,
  }) async {
    final status = await loadStatus();
    if (status.isJoined && status.groupId?.isNotEmpty == true) {
      return null;
    }

    await _markProvisioning();

    try {
      final bootstrap = await _backendClient.fetchBootstrap();
      final servicePublicKeyHex = _validatedBootstrapServicePublicKey(
        bootstrap.servicePublicKeyHex,
      );
      await _database.putSetting(
        AppConstants.safetyServicePublicKeySettingKey,
        servicePublicKeyHex,
      );

      final existing = await _findExistingProvisionedGroup(
        expectedServicePublicKeyHex: servicePublicKeyHex,
      );
      if (existing != null) {
        await _markJoined(
          groupId: existing.mlsGroupIdHex,
          servicePublicKeyHex: servicePublicKeyHex,
        );
        return existing;
      }

      final relays = bootstrap.relays.isEmpty
          ? await _nostrService.loadRelayList()
          : bootstrap.relays;
      final result = await _mdkService.createGroupWithWelcomes(
        creatorPublicKeyHex: identity.publicKeyHex,
        name: AppConstants.safetyHqGroupName,
        description:
            'Platform moderation inbox for higher-risk MyTube reports.',
        relays: relays,
        memberKeyPackageEventJsons: [bootstrap.signedKeyPackageEventJson],
      );
      for (final rumorJson in result.welcomeRumorJsons) {
        await _nostrService.publishGiftWrappedRumor(
          identity: identity,
          rumorEventJson: rumorJson,
          recipientPublicKeyHex: servicePublicKeyHex,
          relays: relays,
        );
      }
      await _markJoined(
        groupId: result.group.mlsGroupIdHex,
        servicePublicKeyHex: servicePublicKeyHex,
      );
      return result.group;
    } catch (error) {
      await _markFailed(error.toString());
      rethrow;
    }
  }

  Future<void> queueJoin() async {
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
    await _database.putSetting(AppConstants.safetyLastErrorSettingKey, '');
  }

  Future<MdkGroupSummary?> _findExistingProvisionedGroup({
    required String expectedServicePublicKeyHex,
  }) async {
    final groups = await _mdkService.getGroupSummaries();
    final storedGroupId = await _database.getSetting(
      AppConstants.safetyGroupIdSettingKey,
    );

    final candidates = <MdkGroupSummary>[
      if (storedGroupId != null && storedGroupId.isNotEmpty)
        ...groups.where((group) => group.mlsGroupIdHex == storedGroupId),
      ...groups.where(
        (group) => group.name.trim() == AppConstants.safetyHqGroupName,
      ),
    ];

    final seenGroupIds = <String>{};
    for (final group in candidates) {
      if (!seenGroupIds.add(group.mlsGroupIdHex)) {
        continue;
      }
      final includesService = await _groupIncludesService(
        groupId: group.mlsGroupIdHex,
        servicePublicKeyHex: expectedServicePublicKeyHex,
      );
      if (includesService) {
        return group;
      }
    }

    return null;
  }

  Future<bool> _groupIncludesService({
    required String? groupId,
    required String servicePublicKeyHex,
  }) async {
    final normalizedGroupId = groupId?.trim();
    if (normalizedGroupId == null || normalizedGroupId.isEmpty) {
      return false;
    }
    try {
      final members = await _mdkService.getGroupMembers(
        mlsGroupIdHex: normalizedGroupId,
      );
      return members.any(
        (member) => member.trim().toLowerCase() == servicePublicKeyHex,
      );
    } catch (_) {
      return false;
    }
  }

  String _validatedBootstrapServicePublicKey(String rawPublicKeyHex) {
    final normalized = rawPublicKeyHex.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw const FormatException(
        'Safety HQ bootstrap did not include a service public key.',
      );
    }
    if (normalized != AppConstants.safetyHqServicePublicKeyHex) {
      throw StateError(
        'Safety HQ bootstrap returned an unexpected service key: $normalized',
      );
    }
    return normalized;
  }

  Future<void> _markProvisioning() async {
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
    await _database.putSetting(AppConstants.safetyLastErrorSettingKey, '');
  }

  Future<void> _markJoined({
    required String groupId,
    required String servicePublicKeyHex,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'false');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'true');
    await _database.putSetting(AppConstants.safetyGroupIdSettingKey, groupId);
    await _database.putSetting(AppConstants.safetyLastSyncAtSettingKey, nowIso);
    await _database.putSetting(AppConstants.safetyLastErrorSettingKey, '');
    await _database.putSetting(
      AppConstants.safetyServicePublicKeySettingKey,
      servicePublicKeyHex,
    );
  }

  Future<void> _markFailed(String error) async {
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
    await _database.putSetting(
      AppConstants.safetyLastErrorSettingKey,
      error.trim(),
    );
  }
}

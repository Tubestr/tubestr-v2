import 'dart:convert';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';

class SafetyHqStatus {
  const SafetyHqStatus({
    required this.isQueued,
    required this.isJoined,
    required this.groupId,
    required this.lastSyncAt,
  });

  final bool isQueued;
  final bool isJoined;
  final String? groupId;
  final DateTime? lastSyncAt;

  bool get usesLocalPlaceholder =>
      !isQueued && !isJoined && groupId != null && groupId!.isNotEmpty;

  String get label {
    if (isJoined) {
      return 'Provisioned';
    }
    if (usesLocalPlaceholder) {
      return 'Awaiting backend ack';
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
    if (usesLocalPlaceholder) {
      return 'A local Safety HQ group exists, but reports stay queued until the backend acknowledges enrollment.';
    }
    if (isQueued) {
      return 'Safety HQ setup is queued. Finish provisioning before expecting a separate Safety HQ copy for higher-risk reports.';
    }
    return 'Set up Safety HQ to keep a separate copy of higher-risk family alerts while backend moderation enrollment is still being built.';
  }
}

class SafetyHqService {
  SafetyHqService({
    required AppDatabase database,
    required MdkService mdkService,
    required NostrService nostrService,
  }) : _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService;

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService _nostrService;

  Future<SafetyHqStatus> loadStatus() async {
    final queued =
        await _database.getSetting(AppConstants.safetyJoinQueuedKey) == 'true';
    final joined =
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

    return SafetyHqStatus(
      isQueued: queued,
      isJoined: joined,
      groupId: groupId,
      lastSyncAt: lastSyncAt,
    );
  }

  Future<MdkGroupSummary?> ensureProvisioned({
    required ParentIdentity identity,
  }) async {
    final groups = await _mdkService.getGroupSummaries();
    final existing = groups.where(
      (group) => group.name.trim() == AppConstants.safetyHqGroupName,
    );
    if (existing.isNotEmpty) {
      final group = existing.first;
      await _markPendingEnrollment(group.mlsGroupIdHex);
      return group;
    }

    final status = await loadStatus();
    if (!status.isQueued &&
        status.groupId != null &&
        status.groupId!.isNotEmpty) {
      return null;
    }

    final relays = await _nostrService.loadRelayList();
    final group = await _mdkService.createGroup(
      creatorPublicKeyHex: identity.publicKeyHex,
      name: AppConstants.safetyHqGroupName,
      description: 'App-managed moderation inbox for Tubestr reports.',
      relays: relays,
    );
    await _markPendingEnrollment(group.mlsGroupIdHex);
    return group;
  }

  Future<void> queueJoin() async {
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
  }

  Future<void> acknowledgeBackendEnrollment({required String groupId}) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'false');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'true');
    await _database.putSetting(AppConstants.safetyGroupIdSettingKey, groupId);
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

  Future<void> _markPendingEnrollment(String groupId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'false');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
    await _database.putSetting(AppConstants.safetyGroupIdSettingKey, groupId);
    await _database.putSetting(AppConstants.safetyLastSyncAtSettingKey, nowIso);
  }
}

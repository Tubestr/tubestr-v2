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

  String get label {
    if (isJoined) {
      return 'Joined';
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
      await _markJoined(group.mlsGroupIdHex);
      return group;
    }

    final status = await loadStatus();
    if (!status.isQueued && status.isJoined) {
      return null;
    }

    final relays = await _nostrService.loadRelayList();
    final group = await _mdkService.createGroup(
      creatorPublicKeyHex: identity.publicKeyHex,
      name: AppConstants.safetyHqGroupName,
      description: 'App-managed moderation inbox for MyTube reports.',
      relays: relays,
    );
    await _markJoined(group.mlsGroupIdHex);
    return group;
  }

  Future<void> queueJoin() async {
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'true');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'false');
  }

  Future<void> _markJoined(String groupId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _database.putSetting(AppConstants.safetyJoinQueuedKey, 'false');
    await _database.putSetting(AppConstants.safetyJoinedKey, 'true');
    await _database.putSetting(AppConstants.safetyGroupIdSettingKey, groupId);
    await _database.putSetting(AppConstants.safetyLastSyncAtSettingKey, nowIso);
  }
}

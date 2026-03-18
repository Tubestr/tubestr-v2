import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/share_history_entry.dart';

class ShareHistoryService {
  ShareHistoryService({required AppDatabase database, Uuid? uuid})
    : _database = database,
      _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  Future<List<ShareHistoryEntry>> load() async {
    final raw = await _database.getSetting(AppConstants.shareHistorySettingKey);
    if (raw == null || raw.isEmpty) {
      return const <ShareHistoryEntry>[];
    }
    return ShareHistoryEntry.decodeList(raw);
  }

  Stream<List<ShareHistoryEntry>> watch() {
    return _database.watchSetting(AppConstants.shareHistorySettingKey).map((
      raw,
    ) {
      if (raw == null || raw.isEmpty) {
        return const <ShareHistoryEntry>[];
      }
      return ShareHistoryEntry.decodeList(raw);
    });
  }

  Future<void> recordSent({
    required String videoId,
    required String title,
    required String childProfileId,
    required String childDisplayName,
    required String mlsGroupId,
    required String eventId,
  }) {
    return _append(
      ShareHistoryEntry(
        id: _uuid.v4(),
        videoId: videoId,
        title: title,
        childProfileId: childProfileId,
        childDisplayName: childDisplayName,
        mlsGroupId: mlsGroupId,
        status: 'sent',
        createdAt: DateTime.now(),
        eventId: eventId,
      ),
    );
  }

  Future<void> recordQueued({
    required String videoId,
    required String title,
    required String childProfileId,
    required String childDisplayName,
    required String mlsGroupId,
    required String error,
  }) {
    return _append(
      ShareHistoryEntry(
        id: _uuid.v4(),
        videoId: videoId,
        title: title,
        childProfileId: childProfileId,
        childDisplayName: childDisplayName,
        mlsGroupId: mlsGroupId,
        status: 'queued',
        createdAt: DateTime.now(),
        error: error,
      ),
    );
  }

  Future<void> _append(ShareHistoryEntry entry) async {
    final current = await load();
    final updated = <ShareHistoryEntry>[entry, ...current].take(50).toList();
    await _database.putSetting(
      AppConstants.shareHistorySettingKey,
      ShareHistoryEntry.encodeList(updated),
    );
  }
}

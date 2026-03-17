import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/offline_action.dart';

class OfflineActionStore {
  OfflineActionStore({required AppDatabase database, Uuid? uuid})
    : _database = database,
      _uuid = uuid ?? const Uuid();

  final AppDatabase _database;
  final Uuid _uuid;

  Future<List<OfflineAction>> load() async {
    final raw = await _database.getSetting(
      AppConstants.offlineActionQueueSettingKey,
    );
    if (raw == null || raw.isEmpty) {
      return const <OfflineAction>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <OfflineAction>[];
    }
    return decoded
        .map((item) => OfflineAction.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Stream<List<OfflineAction>> watch() {
    return _database
        .watchSetting(AppConstants.offlineActionQueueSettingKey)
        .map((raw) {
          if (raw == null || raw.isEmpty) {
            return const <OfflineAction>[];
          }
          final decoded = jsonDecode(raw);
          if (decoded is! List) {
            return const <OfflineAction>[];
          }
          return decoded
              .map(
                (item) => OfflineAction.fromJson(item as Map<String, dynamic>),
              )
              .toList(growable: false);
        });
  }

  Future<OfflineAction> enqueue({
    required OfflineActionType type,
    required Map<String, dynamic> payload,
  }) async {
    final actions = await load();
    final action = OfflineAction(
      id: _uuid.v4(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );
    await _save(<OfflineAction>[...actions, action]);
    return action;
  }

  Future<void> remove(String actionId) async {
    final actions = await load();
    await _save(
      actions.where((action) => action.id != actionId).toList(growable: false),
    );
  }

  Future<void> markFailed({
    required String actionId,
    required Object error,
  }) async {
    final actions = await load();
    await _save(
      actions
          .map((action) {
            if (action.id != actionId) {
              return action;
            }
            return action.copyWith(
              attemptCount: action.attemptCount + 1,
              lastAttemptAt: DateTime.now(),
              lastError: '$error',
            );
          })
          .toList(growable: false),
    );
  }

  Future<void> markSucceeded(String actionId) => remove(actionId);

  Future<void> _save(List<OfflineAction> actions) {
    return _database.putSetting(
      AppConstants.offlineActionQueueSettingKey,
      jsonEncode(actions.map((action) => action.toJson()).toList()),
    );
  }
}

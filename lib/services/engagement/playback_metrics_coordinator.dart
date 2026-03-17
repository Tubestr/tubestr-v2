import '../../core/storage/app_database.dart';

class PlaybackMetricsCoordinator {
  PlaybackMetricsCoordinator({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  Future<void> recordLocalPlayback({
    required String videoId,
    required double completionRatio,
    required bool replayed,
  }) {
    return _database.recordLocalPlaybackSession(
      videoId: videoId,
      completionRatio: completionRatio,
      replayed: replayed,
    );
  }

  Future<void> recordRemotePlayback({
    required String remoteShareId,
    required String videoId,
    required double completionRatio,
    required bool replayed,
  }) {
    return _database.recordRemotePlaybackSession(
      remoteShareId: remoteShareId,
      videoId: videoId,
      completionRatio: completionRatio,
      replayed: replayed,
    );
  }
}

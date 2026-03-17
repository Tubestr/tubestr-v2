import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/models/content_scan_summary.dart';
import 'content_scan_service.dart';

class VideoApprovalService {
  VideoApprovalService({
    required AppDatabase database,
    required ContentScanService scanService,
  }) : _database = database,
       _scanService = scanService;

  final AppDatabase _database;
  final ContentScanService _scanService;

  Future<bool> isApprovalRequired() async {
    final raw = await _database.getSetting(
      AppConstants.approvalRequiredSettingKey,
    );
    if (raw == null || raw.isEmpty) {
      return false;
    }
    return raw == 'true';
  }

  Future<void> setApprovalRequired(bool value) {
    return _database.putSetting(
      AppConstants.approvalRequiredSettingKey,
      value ? 'true' : 'false',
    );
  }

  Future<ContentScanSummary> scanAndClassifyVideo({
    required String videoId,
  }) async {
    final video = await _database.getLocalVideoById(videoId);
    if (video == null) {
      throw StateError('Video not found: $videoId');
    }
    final scan = _scanService.scanVideo(video);
    final approvalRequired = await isApprovalRequired();
    final nextApprovalStatus = approvalRequired || scan.needsReview
        ? 'pending'
        : 'approved';
    await _database.updateLocalVideoModeration(
      videoId: videoId,
      approvalStatus: nextApprovalStatus,
      approvedAt: nextApprovalStatus == 'approved' ? DateTime.now() : null,
      approvedByParentKey: null,
      scanResults: scan.encode(),
      scanCompletedAt: DateTime.now(),
      clearApproval: nextApprovalStatus != 'approved',
    );
    return scan;
  }

  Future<void> approveVideo({
    required String videoId,
    required String parentPublicKeyHex,
  }) {
    return _database.updateLocalVideoModeration(
      videoId: videoId,
      approvalStatus: 'approved',
      approvedAt: DateTime.now(),
      approvedByParentKey: parentPublicKeyHex,
    );
  }

  Future<void> rejectVideo({
    required String videoId,
    required String parentPublicKeyHex,
  }) {
    return _database.updateLocalVideoModeration(
      videoId: videoId,
      approvalStatus: 'rejected',
      approvedAt: DateTime.now(),
      approvedByParentKey: parentPublicKeyHex,
    );
  }

  Future<List<LocalVideo>> loadPendingApprovalVideos() async {
    return (await _database.watchPendingApprovalVideos().first).toList(
      growable: false,
    );
  }
}

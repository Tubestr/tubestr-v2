import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/storage/app_database.dart';
import '../../domain/marmot/message_models.dart';
import '../../domain/models/offline_action.dart';
import '../../domain/models/parent_identity.dart';
import '../mdk/mdk_service.dart';
import '../nostr/nostr_service.dart';
import '../offline/offline_action_store.dart';

class ReportSubmissionResult {
  const ReportSubmissionResult({
    required this.reportId,
    required this.status,
    required this.familyPublished,
    required this.safetyPublished,
    required this.safetyQueued,
  });

  final String reportId;
  final String status;
  final bool familyPublished;
  final bool safetyPublished;
  final bool safetyQueued;
}

class ReportCoordinator {
  ReportCoordinator({
    required AppDatabase database,
    required MdkService mdkService,
    required NostrService nostrService,
    required OfflineActionStore offlineActionStore,
  }) : _database = database,
       _mdkService = mdkService,
       _nostrService = nostrService,
       _offlineActionStore = offlineActionStore;

  final AppDatabase _database;
  final MdkService _mdkService;
  final NostrService _nostrService;
  final OfflineActionStore _offlineActionStore;
  final Uuid _uuid = const Uuid();

  Future<void> fileReport({
    required String videoId,
    required String subjectChildId,
    required String reporterParentKey,
    String? blobHash,
    String? reporterChildId,
    required String reason,
    String? note,
    int level = 1,
    String recipientType = 'group',
  }) async {
    await _insertReport(
      reportId: _uuid.v4(),
      videoId: videoId,
      subjectChildId: subjectChildId,
      reporterParentKey: reporterParentKey,
      blobHash: blobHash,
      reporterChildId: reporterChildId,
      reason: reason,
      note: note,
      level: level,
      recipientType: recipientType,
    );
  }

  Future<ReportSubmissionResult> submitReport({
    required ParentIdentity identity,
    required String videoId,
    required String subjectChildId,
    String? blobHash,
    String? reporterChildId,
    required String reason,
    String? note,
    int level = 1,
    String recipientType = 'group',
    bool allowQueueOnFailure = true,
  }) async {
    final reportId = _uuid.v4();
    final createdAt = DateTime.now();
    await _insertReport(
      reportId: reportId,
      videoId: videoId,
      subjectChildId: subjectChildId,
      reporterParentKey: identity.publicKeyHex,
      blobHash: blobHash,
      reporterChildId: reporterChildId,
      reason: reason,
      note: note,
      level: level,
      recipientType: recipientType,
      createdAt: createdAt,
    );

    final effectiveBlobHash = blobHash?.trim();
    if (effectiveBlobHash == null || effectiveBlobHash.isEmpty) {
      await _updateReportStatus(
        reportId: reportId,
        status: 'pending_blob_hash',
      );
      return ReportSubmissionResult(
        reportId: reportId,
        status: 'pending_blob_hash',
        familyPublished: false,
        safetyPublished: false,
        safetyQueued: false,
      );
    }

    var familyPublished = false;
    var safetyPublished = false;
    var safetyQueued = false;

    try {
      final relays = await _nostrService.loadRelayList();
      final familyGroupId =
          await _database.getPrimaryGroupIdForProfile(subjectChildId) ??
          await _database.getPrimaryGroupIdForAnyProfile();
      if (familyGroupId != null && familyGroupId.isNotEmpty) {
        await _publishReportToGroup(
          identity: identity,
          mlsGroupIdHex: familyGroupId,
          reportId: reportId,
          videoId: videoId,
          subjectChildId: subjectChildId,
          blobHash: effectiveBlobHash,
          reporterChildId: reporterChildId,
          reason: reason,
          note: note,
          level: level,
          recipientType: recipientType,
          relays: relays,
          createdAt: createdAt,
        );
        familyPublished = true;
      }

      if (level >= 2) {
        final safetyJoined =
            await _database.getSetting(AppConstants.safetyJoinedKey) == 'true';
        final safetyGroupId = await _database.getSetting(
          AppConstants.safetyGroupIdSettingKey,
        );
        if (safetyJoined && safetyGroupId != null && safetyGroupId.isNotEmpty) {
          await _publishReportToGroup(
            identity: identity,
            mlsGroupIdHex: safetyGroupId,
            reportId: reportId,
            videoId: videoId,
            subjectChildId: subjectChildId,
            blobHash: effectiveBlobHash,
            reporterChildId: reporterChildId,
            reason: reason,
            note: note,
            level: level,
            recipientType: 'safety_hq',
            relays: relays,
            createdAt: createdAt,
          );
          safetyPublished = true;
        } else {
          safetyQueued = true;
        }
      }

      final status = safetyQueued
          ? 'queued_safety'
          : familyPublished || safetyPublished
          ? 'delivered'
          : 'pending';
      await _updateReportStatus(
        reportId: reportId,
        status: status,
        deliveredAt: familyPublished || safetyPublished ? DateTime.now() : null,
      );
      return ReportSubmissionResult(
        reportId: reportId,
        status: status,
        familyPublished: familyPublished,
        safetyPublished: safetyPublished,
        safetyQueued: safetyQueued,
      );
    } catch (error) {
      if (allowQueueOnFailure) {
        await _offlineActionStore.enqueue(
          type: OfflineActionType.submitReport,
          payload: <String, dynamic>{
            'video_id': videoId,
            'subject_child_id': subjectChildId,
            'blob_hash': blobHash,
            'reporter_child_id': reporterChildId,
            'reason': reason,
            'note': note,
            'level': level,
            'recipient_type': recipientType,
          },
        );
        await _updateReportStatus(reportId: reportId, status: 'queued_offline');
        throw StateError('Report queued for retry: $error');
      }
      await _updateReportStatus(reportId: reportId, status: 'failed');
      rethrow;
    }
  }

  Future<int> flushQueuedSafetyReports({
    required ParentIdentity identity,
  }) async {
    final safetyJoined =
        await _database.getSetting(AppConstants.safetyJoinedKey) == 'true';
    final safetyGroupId = await _database.getSetting(
      AppConstants.safetyGroupIdSettingKey,
    );
    if (!safetyJoined || safetyGroupId == null || safetyGroupId.isEmpty) {
      return 0;
    }

    final queuedReports = await (_database.select(
      _database.reports,
    )..where((tbl) => tbl.status.equals('queued_safety'))).get();
    if (queuedReports.isEmpty) {
      return 0;
    }

    final relays = await _nostrService.loadRelayList();
    var deliveredCount = 0;
    for (final report in queuedReports) {
      final blobHash = report.blobHash?.trim();
      if (blobHash == null || blobHash.isEmpty) {
        continue;
      }
      await _publishReportToGroup(
        identity: identity,
        mlsGroupIdHex: safetyGroupId,
        reportId: report.id,
        videoId: report.videoId,
        subjectChildId: report.subjectChildId,
        blobHash: blobHash,
        reporterChildId: report.reporterChildId,
        reason: report.reason,
        note: report.note,
        level: report.level,
        recipientType: 'safety_hq',
        relays: relays,
        createdAt: report.createdAt,
      );
      await _updateReportStatus(
        reportId: report.id,
        status: 'delivered',
        deliveredAt: DateTime.now(),
      );
      deliveredCount += 1;
    }
    return deliveredCount;
  }

  Future<void> _publishReportToGroup({
    required ParentIdentity identity,
    required String mlsGroupIdHex,
    required String reportId,
    required String videoId,
    required String subjectChildId,
    required String blobHash,
    required String? reporterChildId,
    required String reason,
    required String? note,
    required int level,
    required String recipientType,
    required List<String> relays,
    required DateTime createdAt,
  }) async {
    final payload = ReportMessage(
      reportId: reportId,
      videoId: videoId,
      subjectChildId: subjectChildId,
      blobHash: blobHash,
      reason: reason,
      note: note,
      level: level,
      recipientType: recipientType,
      reporterChildId: reporterChildId,
      by: identity.publicKeyHex,
      ts: createdAt.millisecondsSinceEpoch ~/ 1000,
    );

    final createdMessage = await _mdkService.createApplicationMessage(
      mlsGroupIdHex: mlsGroupIdHex,
      senderPublicKeyHex: identity.publicKeyHex,
      kind: MarmotKinds.report,
      content: jsonEncode(payload.toJson()),
      createdAt: createdAt.millisecondsSinceEpoch ~/ 1000,
    );
    await _nostrService.publishSignedEventJson(
      identity: identity,
      eventJson: createdMessage.wrapperEventJson,
      relays: relays,
    );
  }

  Future<void> _insertReport({
    required String reportId,
    required String videoId,
    required String subjectChildId,
    required String reporterParentKey,
    required String? blobHash,
    required String? reporterChildId,
    required String reason,
    required String? note,
    required int level,
    required String recipientType,
    DateTime? createdAt,
  }) {
    return _database
        .into(_database.reports)
        .insert(
          ReportsCompanion.insert(
            id: reportId,
            videoId: videoId,
            subjectChildId: subjectChildId,
            blobHash: Value(blobHash),
            reason: reason,
            note: Value(note),
            level: Value(level),
            recipientType: Value(recipientType),
            reporterChildId: Value(reporterChildId),
            reporterParentKey: reporterParentKey,
            createdAt: createdAt ?? DateTime.now(),
          ),
        );
  }

  Future<void> _updateReportStatus({
    required String reportId,
    required String status,
    DateTime? deliveredAt,
  }) {
    return (_database.update(
      _database.reports,
    )..where((tbl) => tbl.id.equals(reportId))).write(
      ReportsCompanion(
        status: Value(status),
        deliveredAt: deliveredAt == null
            ? const Value.absent()
            : Value(deliveredAt),
      ),
    );
  }
}

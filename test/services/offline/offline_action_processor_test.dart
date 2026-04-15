import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/offline_action.dart';
import 'package:mytube/domain/models/parent_identity.dart';
import 'package:mytube/services/approval/content_scan_service.dart';
import 'package:mytube/services/approval/media_signal_extraction_service.dart';
import 'package:mytube/services/approval/video_approval_service.dart';
import 'package:mytube/services/engagement/like_coordinator.dart';
import 'package:mytube/services/engagement/reaction_coordinator.dart';
import 'package:mytube/services/identity/parent_profile_service.dart';
import 'package:mytube/services/offline/offline_action_processor.dart';
import 'package:mytube/services/offline/offline_action_store.dart';
import 'package:mytube/services/safety/report_coordinator.dart';
import 'package:mytube/services/safety/safety_hq_service.dart';
import 'package:mytube/services/share/managed_video_upload_service.dart';
import 'package:mytube/services/share/share_history_service.dart';
import 'package:mytube/services/share/video_share_coordinator.dart';

import '../../test_support/service_fakes.dart';

void main() {
  const identity = ParentIdentity(
    publicKeyHex: 'parent-pubkey',
    privateKeyHex: 'parent-privkey',
    npub: 'npub-parent',
    nsec: 'nsec-parent',
    createdAtIso: '2026-03-15T00:00:00.000Z',
  );

  test(
    'flush processes queued share, like, reaction, local report, and profile actions',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);

      await database.upsertProfile(
        id: 'child-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'avatar.png',
      );
      await database.setPrimaryGroupForProfile(
        profileId: 'child-1',
        mlsGroupId: 'family-group',
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'offline-actions-test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });
      final videoFile = File('${tempDir.path}/clip.mp4')
        ..writeAsBytesSync(List<int>.from('video-bytes'.codeUnits));
      final thumbFile = File('${tempDir.path}/thumb.jpg')
        ..writeAsBytesSync(List<int>.from('thumb-bytes'.codeUnits));

      await database.saveLocalVideo(
        videoId: 'video-1',
        profileId: 'child-1',
        filePath: videoFile.path,
        thumbPath: thumbFile.path,
        title: 'Backyard',
        approvalStatus: 'approved',
      );

      final store = OfflineActionStore(database: database);
      final nostr = FakeNostrService()
        ..blossomServers = const ['https://blossom.example'];
      final mdk = FakeMdkService();
      final blossom = FakeBlossomClient(unavailableServer: 'unused');
      final profileService = ParentProfileService(
        database: database,
        nostrService: nostr,
        offlineActionStore: store,
      );
      final processor = OfflineActionProcessor(
        store: store,
        identityService: FakeIdentityService(
          identity: identity,
          database: database,
        ),
        parentProfileService: profileService,
        videoShareCoordinator: VideoShareCoordinator(
          database: database,
          videoApprovalService: VideoApprovalService(
            database: database,
            scanService: const ContentScanService(),
            signalExtractionService: MediaSignalExtractionService(
              extractSignals: (video) async => MediaSignalExtractionResult(
                cvLabels: video.cvLabels,
                faceCount: video.faceCount,
                loudness: video.loudness,
              ),
            ),
          ),
          blossomClient: blossom,
          mdkService: mdk,
          nostrService: nostr,
          offlineActionStore: store,
          shareHistoryService: ShareHistoryService(database: database),
          managedVideoUploadService: ManagedVideoUploadService(
            database: database,
          ),
        ),
        likeCoordinator: LikeCoordinator(
          database: database,
          mdkService: mdk,
          nostrService: nostr,
          offlineActionStore: store,
        ),
        reactionCoordinator: ReactionCoordinator(
          database: database,
          mdkService: mdk,
          nostrService: nostr,
          offlineActionStore: store,
        ),
        reportCoordinator: ReportCoordinator(
          database: database,
          mdkService: mdk,
          nostrService: nostr,
          offlineActionStore: store,
          safetyHqService: SafetyHqService(
            database: database,
            mdkService: mdk,
            nostrService: nostr,
            dio: Dio(),
          ),
        ),
      );

      await store.enqueue(
        type: OfflineActionType.publishParentProfile,
        payload: const <String, dynamic>{'display_name': 'Lee & Emma'},
      );
      await store.enqueue(
        type: OfflineActionType.shareVideo,
        payload: const <String, dynamic>{
          'video_id': 'video-1',
          'profile_id': 'child-1',
          'child_display_name': 'Emma',
          'mls_group_id': 'family-group',
        },
      );
      await store.enqueue(
        type: OfflineActionType.sendLike,
        payload: const <String, dynamic>{
          'video_id': 'remote-1',
          'child_profile_id': 'child-1',
          'mls_group_id': 'family-group',
        },
      );
      await store.enqueue(
        type: OfflineActionType.sendReaction,
        payload: const <String, dynamic>{
          'video_id': 'remote-1',
          'child_profile_id': 'child-1',
          'mls_group_id': 'family-group',
          'emoji': '🎉',
        },
      );
      await store.enqueue(
        type: OfflineActionType.submitReport,
        payload: const <String, dynamic>{
          'video_id': 'remote-1',
          'subject_child_id': 'child-1',
          'blob_hash': 'blob-1',
          'reporter_child_id': 'child-1',
          'reason': 'unsafe',
          'level': 1,
          'recipient_type': 'group',
        },
      );

      final flushed = await processor.flush();
      final remaining = await store.load();
      final report = await (database.select(
        database.reports,
      )..where((tbl) => tbl.videoId.equals('remote-1'))).getSingle();

      expect(flushed, 5);
      expect(remaining, isEmpty);
      expect(nostr.lastPublishedDisplayName, 'Lee & Emma');
      expect(nostr.publishedEventJsons, hasLength(4));
      expect(report.status, 'delivered');
      expect(report.level, 1);
      expect(report.recipientType, 'group');
    },
  );
}

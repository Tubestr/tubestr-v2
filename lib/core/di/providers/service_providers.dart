import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/account/child_profile_deletion_service.dart';
import '../../../services/auth/parent_auth_service.dart';
import '../../../services/account/parent_account_deletion_service.dart';
import '../../../services/app_reset_service.dart';
import '../../../services/blossom/blossom_client.dart';
import '../../../services/approval/content_scan_service.dart';
import '../../../services/approval/media_signal_extraction_service.dart';
import '../../../services/approval/video_approval_service.dart';
import '../../../services/connections/family_connection_service.dart';
import '../../../services/editor/editor_audio_library_service.dart';
import '../../../services/editor/editor_export_service.dart';
import '../../../services/engagement/beta_funnel_service.dart';
import '../../../services/engagement/like_coordinator.dart';
import '../../../services/engagement/playback_metrics_coordinator.dart';
import '../../../services/engagement/reaction_coordinator.dart';
import '../../../services/identity/identity_service.dart';
import '../../../services/identity/parent_profile_service.dart';
import '../../../services/mdk/mdk_service.dart';
import '../../../services/media/remote_media_service.dart';
import '../../../services/media/local_media_library_service.dart';
import '../../../services/nostr/nostr_service.dart';
import '../../../services/offline/offline_action_processor.dart';
import '../../../services/offline/offline_action_store.dart';
import '../../../services/safety/moderation_coordinator.dart';
import '../../../services/safety/report_coordinator.dart';
import '../../../services/safety/safety_hq_service.dart';
import '../../../services/share/managed_video_upload_service.dart';
import '../../../services/share/share_history_service.dart';
import '../../../services/share/video_lifecycle_coordinator.dart';
import '../../../services/share/video_share_coordinator.dart';
import '../../../services/sync/sync_coordinator.dart';
import '../../router/deep_link_service.dart';
import 'foundation_providers.dart';

final identityServiceProvider = Provider<IdentityService>((ref) {
  return IdentityService(
    secureStorage: ref.watch(secureStorageProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final betaFunnelServiceProvider = Provider<BetaFunnelService>((ref) {
  return BetaFunnelService(
    dio: ref.watch(dioProvider),
    nostrService: ref.watch(nostrServiceProvider),
    identityService: ref.watch(identityServiceProvider),
    database: ref.watch(appDatabaseProvider),
  );
});

final editorExportServiceProvider = Provider<EditorExportService>((ref) {
  return EditorExportService(
    database: ref.watch(appDatabaseProvider),
    thumbnailService: ref.watch(thumbnailServiceProvider),
    videoApprovalService: ref.watch(videoApprovalServiceProvider),
    localMediaLibraryService: ref.watch(localMediaLibraryServiceProvider),
  );
});

final parentAuthServiceProvider = Provider<ParentAuthService>((ref) {
  return ParentAuthService(ref.watch(secureStorageProvider));
});

final parentAccountDeletionServiceProvider =
    Provider<ParentAccountDeletionService>((ref) {
      return ParentAccountDeletionService(
        dio: ref.watch(dioProvider),
        nostrService: ref.watch(nostrServiceProvider),
      );
    });

final appResetServiceProvider = Provider<AppResetService>((ref) {
  return AppResetService(
    database: ref.watch(appDatabaseProvider),
    identityService: ref.watch(identityServiceProvider),
    parentAuthService: ref.watch(parentAuthServiceProvider),
    mdkService: ref.watch(mdkServiceProvider),
  );
});

final contentScanServiceProvider = Provider(
  (ref) => const ContentScanService(),
);

final mediaSignalExtractionServiceProvider = Provider(
  (ref) => MediaSignalExtractionService(),
);

final blossomClientProvider = Provider<BlossomClient>((ref) {
  return BlossomClient(ref.watch(dioProvider));
});

final editorAudioLibraryServiceProvider = Provider<EditorAudioLibraryService>((
  ref,
) {
  return EditorAudioLibraryService(
    blossomClient: ref.watch(blossomClientProvider),
  );
});

final nostrServiceProvider = Provider<NostrService>((ref) {
  return NdkNostrService(ref.watch(appDatabaseProvider));
});

final mdkServiceProvider = Provider((ref) => MdkService());

final parentProfileServiceProvider = Provider((ref) {
  return ParentProfileService(
    database: ref.watch(appDatabaseProvider),
    nostrService: ref.watch(nostrServiceProvider),
    offlineActionStore: ref.watch(offlineActionStoreProvider),
  );
});

final videoApprovalServiceProvider = Provider((ref) {
  return VideoApprovalService(
    database: ref.watch(appDatabaseProvider),
    scanService: ref.watch(contentScanServiceProvider),
    signalExtractionService: ref.watch(mediaSignalExtractionServiceProvider),
  );
});

final offlineActionStoreProvider = Provider((ref) {
  return OfflineActionStore(database: ref.watch(appDatabaseProvider));
});

final familyConnectionServiceProvider = Provider((ref) {
  return FamilyConnectionService(
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    database: ref.watch(appDatabaseProvider),
    loadLocalDisplayName: ref
        .watch(parentProfileServiceProvider)
        .loadLocalDisplayName,
  );
});

final remoteMediaServiceProvider = Provider<RemoteMediaService>((ref) {
  return RemoteMediaService(
    database: ref.watch(appDatabaseProvider),
    blossomClient: ref.watch(blossomClientProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
  );
});

final localMediaLibraryServiceProvider = Provider<LocalMediaLibraryService>((
  ref,
) {
  return LocalMediaLibraryService();
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    identityService: ref.watch(identityServiceProvider),
    remoteMediaService: ref.watch(remoteMediaServiceProvider),
    parentProfileService: ref.watch(parentProfileServiceProvider),
  );
  ref.onDispose(() {
    unawaited(coordinator.stop());
  });
  return coordinator;
});

final syncRevisionProvider = StreamProvider<int>((ref) {
  return ref.watch(syncCoordinatorProvider).revisions;
});

final syncDiagnosticsRevisionProvider = StreamProvider<int>((ref) {
  return ref.watch(syncCoordinatorProvider).diagnosticsRevisions;
});

final videoShareCoordinatorProvider = Provider((ref) {
  return VideoShareCoordinator(
    database: ref.watch(appDatabaseProvider),
    videoApprovalService: ref.watch(videoApprovalServiceProvider),
    blossomClient: ref.watch(blossomClientProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    offlineActionStore: ref.watch(offlineActionStoreProvider),
    shareHistoryService: ref.watch(shareHistoryServiceProvider),
    managedVideoUploadService: ref.watch(managedVideoUploadServiceProvider),
    onFirstPrivateShareSent:
        ({required sharedGroupCount, required queuedGroupCount}) {
          return ref
              .read(betaFunnelServiceProvider)
              .trackFirstPrivateShareSent(
                sharedGroupCount: sharedGroupCount,
                queuedGroupCount: queuedGroupCount,
              );
        },
  );
});

final shareHistoryServiceProvider = Provider((ref) {
  return ShareHistoryService(database: ref.watch(appDatabaseProvider));
});

final managedVideoUploadServiceProvider = Provider((ref) {
  return ManagedVideoUploadService(database: ref.watch(appDatabaseProvider));
});

final childProfileDeletionServiceProvider = Provider((ref) {
  return ChildProfileDeletionService(
    database: ref.watch(appDatabaseProvider),
    blossomClient: ref.watch(blossomClientProvider),
    nostrService: ref.watch(nostrServiceProvider),
    shareHistoryService: ref.watch(shareHistoryServiceProvider),
    managedVideoUploadService: ref.watch(managedVideoUploadServiceProvider),
  );
});

final videoLifecycleCoordinatorProvider = Provider((ref) {
  return VideoLifecycleCoordinator(
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
  );
});

final likeCoordinatorProvider = Provider((ref) {
  return LikeCoordinator(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    offlineActionStore: ref.watch(offlineActionStoreProvider),
  );
});

final reactionCoordinatorProvider = Provider((ref) {
  return ReactionCoordinator(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    offlineActionStore: ref.watch(offlineActionStoreProvider),
  );
});

final playbackMetricsCoordinatorProvider = Provider((ref) {
  return PlaybackMetricsCoordinator(database: ref.watch(appDatabaseProvider));
});

final reportCoordinatorProvider = Provider((ref) {
  return ReportCoordinator(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    offlineActionStore: ref.watch(offlineActionStoreProvider),
    safetyHqService: ref.watch(safetyHqServiceProvider),
  );
});

final moderationCoordinatorProvider = Provider((ref) {
  return ModerationCoordinator(
    database: ref.watch(appDatabaseProvider),
    blossomClient: ref.watch(blossomClientProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    videoLifecycleCoordinator: ref.watch(videoLifecycleCoordinatorProvider),
  );
});

final safetyHqServiceProvider = Provider((ref) {
  return SafetyHqService(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    dio: ref.watch(dioProvider),
  );
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return AppLinksDeepLinkService();
});

final offlineActionProcessorProvider = Provider((ref) {
  return OfflineActionProcessor(
    store: ref.watch(offlineActionStoreProvider),
    identityService: ref.watch(identityServiceProvider),
    parentProfileService: ref.watch(parentProfileServiceProvider),
    videoShareCoordinator: ref.watch(videoShareCoordinatorProvider),
    likeCoordinator: ref.watch(likeCoordinatorProvider),
    reactionCoordinator: ref.watch(reactionCoordinatorProvider),
    reportCoordinator: ref.watch(reportCoordinatorProvider),
  );
});

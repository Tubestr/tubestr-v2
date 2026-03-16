import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/auth/parent_auth_service.dart';
import '../../../services/blossom/blossom_client.dart';
import '../../../services/connections/family_connection_service.dart';
import '../../../services/engagement/like_coordinator.dart';
import '../../../services/identity/identity_service.dart';
import '../../../services/mdk/mdk_service.dart';
import '../../../services/media/remote_media_service.dart';
import '../../../services/nostr/nostr_service.dart';
import '../../../services/safety/moderation_coordinator.dart';
import '../../../services/safety/report_coordinator.dart';
import '../../../services/safety/safety_hq_service.dart';
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

final parentAuthServiceProvider = Provider<ParentAuthService>((ref) {
  return ParentAuthService(ref.watch(secureStorageProvider));
});

final blossomClientProvider = Provider<BlossomClient>((ref) {
  return BlossomClient(ref.watch(dioProvider));
});

final nostrServiceProvider = Provider<NostrService>((ref) {
  return NdkNostrService(ref.watch(appDatabaseProvider));
});

final mdkServiceProvider = Provider((ref) => MdkService());

final familyConnectionServiceProvider = Provider((ref) {
  return FamilyConnectionService(
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
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

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
    identityService: ref.watch(identityServiceProvider),
    remoteMediaService: ref.watch(remoteMediaServiceProvider),
  );
  ref.onDispose(() {
    unawaited(coordinator.stop());
  });
  return coordinator;
});

final syncRevisionProvider = StreamProvider<int>((ref) {
  return ref.watch(syncCoordinatorProvider).revisions;
});

final videoShareCoordinatorProvider = Provider((ref) {
  return VideoShareCoordinator(
    blossomClient: ref.watch(blossomClientProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
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
  );
});

final reportCoordinatorProvider = Provider((ref) {
  return ReportCoordinator(
    database: ref.watch(appDatabaseProvider),
    mdkService: ref.watch(mdkServiceProvider),
    nostrService: ref.watch(nostrServiceProvider),
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
  );
});

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return AppLinksDeepLinkService();
});

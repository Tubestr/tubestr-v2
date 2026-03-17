import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/parent_identity.dart';
import '../../../domain/models/parent_profile.dart';
import '../../../domain/models/ranking_engine.dart';
import '../../../domain/models/ranking_state.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../services/mdk/mdk_service.dart';
import '../../theme/theme_descriptor.dart';
import 'foundation_providers.dart';
import 'service_providers.dart';

final parentIdentityProvider = FutureProvider<ParentIdentity?>((ref) {
  return ref.watch(identityServiceProvider).loadIdentity();
});

final parentDisplayNameProvider = FutureProvider<String?>((ref) {
  return ref.watch(parentProfileServiceProvider).loadLocalDisplayName();
});

final profilesProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchProfiles();
});

final pendingApprovalVideosProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchPendingApprovalVideos();
});

final shareRecordsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchShareRecords();
});

final remoteSharesProvider = StreamProvider<List<RemoteShareProjection>>((ref) {
  return ref.watch(appDatabaseProvider).watchRemoteShareProjections();
});

final remoteShareByIdProvider =
    StreamProvider.family<RemoteShareProjection?, String>((ref, remoteShareId) {
      return ref
          .watch(appDatabaseProvider)
          .watchRemoteShareProjectionByRemoteShareId(remoteShareId);
    });

final reportsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchReports();
});

final moderationAuditLogsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchModerationAuditLogs();
});

final offlineActionsProvider = StreamProvider((ref) {
  return ref.watch(offlineActionStoreProvider).watch();
});

final shareHistoryProvider = StreamProvider((ref) {
  return ref.watch(shareHistoryServiceProvider).watch();
});

final mdkGroupSummariesProvider = FutureProvider<List<MdkGroupSummary>>((
  ref,
) async {
  ref.watch(syncRevisionProvider);
  return ref.watch(mdkServiceProvider).getGroupSummaries();
});

final mdkGroupSummaryProvider = FutureProvider.family<MdkGroupSummary?, String>(
  (ref, mlsGroupIdHex) async {
    final groups = await ref.watch(mdkGroupSummariesProvider.future);
    return groups.firstWhereOrNull(
      (group) => group.mlsGroupIdHex == mlsGroupIdHex,
    );
  },
);

final resolvedParentProfileProvider =
    FutureProvider.family<ParentProfile?, String>((ref, publicKeyHex) async {
      final identity = await ref.watch(parentIdentityProvider.future);
      return ref
          .watch(parentProfileServiceProvider)
          .resolveProfile(publicKeyHex: publicKeyHex, localIdentity: identity);
    });

final videoLikeCountProvider = StreamProvider.family<int, String>((
  ref,
  videoId,
) {
  return ref.watch(appDatabaseProvider).watchLikeCountForVideo(videoId);
});

final remoteLikeForSelectedViewerProvider = StreamProvider.family<bool, String>(
  (ref, videoId) {
    final selectedProfileId = ref.watch(selectedProfileIdProvider);
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    if (selectedProfileId == null || identity == null) {
      return Stream<bool>.value(false);
    }
    return ref
        .watch(appDatabaseProvider)
        .watchLikeForVideoByParentAndChild(
          videoId: videoId,
          childProfileId: selectedProfileId,
          parentPubkey: identity.publicKeyHex,
        );
  },
);

final safetyHqStatusProvider = FutureProvider((ref) {
  return ref.watch(safetyHqServiceProvider).loadStatus();
});

final pendingDeepLinkProvider = StateProvider<Uri?>((ref) => null);

final appShellTabIndexProvider = StateProvider<int>((ref) => 0);

final selectedProfileIdProvider = StateProvider<String?>((ref) => null);

final activeThemeProvider = Provider<ThemeDescriptor>((ref) {
  final profilesState = ref.watch(profilesProvider);
  final selectedId = ref.watch(selectedProfileIdProvider);

  return profilesState.maybeWhen(
    data: (profiles) {
      if (profiles.isEmpty) {
        return ThemeDescriptor.campfire;
      }
      final selected =
          profiles.firstWhereOrNull((profile) => profile.id == selectedId) ??
          profiles.first;
      return ThemeDescriptorX.fromStorage(selected.theme);
    },
    orElse: () => ThemeDescriptor.campfire,
  );
});

final videosForSelectedProfileProvider = StreamProvider((ref) {
  final profileId = ref.watch(selectedProfileIdProvider);
  return ref.watch(appDatabaseProvider).watchVideosForProfile(profileId);
});

final rankingResultProvider = Provider<RankingResult?>((ref) {
  final videos = ref.watch(videosForSelectedProfileProvider).valueOrNull;
  if (videos == null) {
    return null;
  }
  return const RankingEngine().rank(
    videos: videos,
    rankingState: const RankingState(),
  );
});

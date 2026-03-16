import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/parent_identity.dart';
import '../../../domain/models/ranking_engine.dart';
import '../../../domain/models/ranking_state.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../theme/theme_descriptor.dart';
import 'foundation_providers.dart';
import 'service_providers.dart';

final parentIdentityProvider = FutureProvider<ParentIdentity?>((ref) {
  return ref.watch(identityServiceProvider).loadIdentity();
});

final profilesProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchProfiles();
});

final shareRecordsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchShareRecords();
});

final remoteSharesProvider = StreamProvider<List<RemoteShareProjection>>((ref) {
  return ref.watch(appDatabaseProvider).watchRemoteShareProjections();
});

final remoteShareByVideoIdProvider =
    StreamProvider.family<RemoteShareProjection?, String>((ref, videoId) {
      return ref
          .watch(appDatabaseProvider)
          .watchRemoteShareProjectionByVideoId(videoId);
    });

final reportsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchReports();
});

final moderationAuditLogsProvider = StreamProvider((ref) {
  return ref.watch(appDatabaseProvider).watchModerationAuditLogs();
});

final videoLikeCountProvider = StreamProvider.family<int, String>((
  ref,
  videoId,
) {
  return ref.watch(appDatabaseProvider).watchLikeCountForVideo(videoId);
});

final remoteLikeForSelectedViewerProvider =
    StreamProvider.family<bool, String>((ref, videoId) {
      final selectedProfileId = ref.watch(selectedProfileIdProvider);
      final identity = ref.watch(parentIdentityProvider).valueOrNull;
      if (selectedProfileId == null || identity == null) {
        return Stream<bool>.value(false);
      }
      return ref.watch(appDatabaseProvider).watchLikeForVideoByParentAndChild(
        videoId: videoId,
        childProfileId: selectedProfileId,
        parentPubkey: identity.publicKeyHex,
      );
    });

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

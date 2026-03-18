import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../domain/models/parent_identity.dart';
import '../../../domain/models/remote_share_projection.dart';

@immutable
class PlayerRouteArgs {
  const PlayerRouteArgs({this.videoId, this.remoteShareId});

  final String? videoId;
  final String? remoteShareId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PlayerRouteArgs &&
            runtimeType == other.runtimeType &&
            videoId == other.videoId &&
            remoteShareId == other.remoteShareId;
  }

  @override
  int get hashCode => Object.hash(videoId, remoteShareId);
}

class PlayerRouteState {
  PlayerRouteState({
    required this.video,
    required this.remoteShare,
    required this.videoProfile,
    required this.identity,
    required this.selectedProfileId,
    required this.mediaPath,
    required this.remoteThumbFile,
    required this.hasRemoteThumb,
    required this.title,
    required this.subtitle,
    required this.remoteLikeCount,
    required this.remoteLikedByViewer,
  });

  final LocalVideo? video;
  final RemoteShareProjection? remoteShare;
  final Profile? videoProfile;
  final ParentIdentity? identity;
  final String? selectedProfileId;
  final String? mediaPath;
  final File? remoteThumbFile;
  final bool hasRemoteThumb;
  final String title;
  final String subtitle;
  final int remoteLikeCount;
  final bool remoteLikedByViewer;

  bool get isLiked => video?.liked ?? remoteLikedByViewer;
}

final playerRouteStateProvider =
    Provider.family<PlayerRouteState, PlayerRouteArgs>((ref, args) {
      final videos =
          ref.watch(videosForSelectedProfileProvider).valueOrNull ?? const [];
      final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
      final identity = ref.watch(parentIdentityProvider).valueOrNull;
      final selectedProfileId = ref.watch(selectedProfileIdProvider);
      final remoteShare = args.remoteShareId == null
          ? null
          : ref.watch(remoteShareByIdProvider(args.remoteShareId!)).valueOrNull;
      // Try the profile-filtered list first; fall back to a direct DB lookup
      // so newly-saved videos are found even if the stream hasn't re-emitted.
      final video = args.videoId == null
          ? null
          : videos.firstWhereOrNull((item) => item.id == args.videoId) ??
              ref.watch(localVideoByIdProvider(args.videoId!)).valueOrNull;
      final videoProfile = video == null
          ? null
          : profiles.firstWhereOrNull(
              (profile) => profile.id == video.profileId,
            );

      final mediaPath = switch ((
        video?.filePath,
        remoteShare?.localMediaPath,
      )) {
        (final String path?, _) when path.isNotEmpty => path,
        (_, final String path?) when path.isNotEmpty => path,
        _ => null,
      };

      final remoteThumbPath = remoteShare?.localThumbPath;
      final remoteThumbFile =
          remoteThumbPath != null && remoteThumbPath.isNotEmpty
          ? File(remoteThumbPath)
          : null;
      final hasRemoteThumb = remoteThumbFile?.existsSync() == true;

      final senderProfile = remoteShare == null
          ? null
          : ref
                .watch(
                  resolvedParentProfileProvider(remoteShare.senderParentKey),
                )
                .valueOrNull;
      final remoteLikeCount = remoteShare == null
          ? 0
          : ref
                    .watch(videoLikeCountProvider(remoteShare.videoId))
                    .valueOrNull ??
                0;
      final remoteLikedByViewer = remoteShare == null
          ? false
          : ref
                    .watch(
                      remoteLikeForSelectedViewerProvider(remoteShare.videoId),
                    )
                    .valueOrNull ??
                false;

      final title =
          video?.title ?? remoteShare?.shareMessage?.meta.title ?? 'Video';
      final subtitle = video != null
          ? video.tags.join(' · ')
          : remoteShare == null
          ? ''
          : '${senderProfile?.displayName ?? remoteShare.displayName} · ${remoteShare.displayName} · ${remoteShare.status}';

      return PlayerRouteState(
        video: video,
        remoteShare: remoteShare,
        videoProfile: videoProfile,
        identity: identity,
        selectedProfileId: selectedProfileId,
        mediaPath: mediaPath,
        remoteThumbFile: remoteThumbFile,
        hasRemoteThumb: hasRemoteThumb,
        title: title,
        subtitle: subtitle,
        remoteLikeCount: remoteLikeCount,
        remoteLikedByViewer: remoteLikedByViewer,
      );
    });

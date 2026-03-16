import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/parent_identity.dart';
import '../../../domain/models/remote_share_projection.dart';
import '../../../shared_ui/reporting/feeling_report_sheet.dart';

/// Full-screen video player matching v1 PlayerView design.
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  late final Player _player;
  late final VideoController _videoController;
  String? _openedPath;
  bool _isDownloadingRemote = false;
  bool _isSharingLocal = false;
  bool _isSendingLike = false;

  // Controls visibility
  bool _showControls = true;
  Timer? _hideTimer;

  // Player state
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _player = Player();
    _videoController = VideoController(_player);
    _player.stream.playing.listen((v) {
      if (mounted) setState(() => _playing = v);
    });
    _player.stream.position.listen((v) {
      if (mounted) setState(() => _position = v);
    });
    _player.stream.duration.listen((v) {
      if (mounted) setState(() => _duration = v);
    });
    _resetHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _syncMedia(String? path) {
    if (path == _openedPath) return;
    _openedPath = path;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (path == null || path.isEmpty) {
        await _player.stop();
        return;
      }
      await _player.open(Media(path));
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetHideTimer();
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _playing) setState(() => _showControls = false);
    });
  }

  void _togglePlay() {
    _player.playOrPause();
    _resetHideTimer();
  }

  void _seekTo(double value) {
    if (_duration.inMilliseconds > 0) {
      _player.seek(
        Duration(milliseconds: (value * _duration.inMilliseconds).round()),
      );
    }
    _resetHideTimer();
  }

  void _rewind() {
    _player.seek(Duration.zero);
    _resetHideTimer();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final videos =
        ref.watch(videosForSelectedProfileProvider).valueOrNull ?? const [];
    final remoteShare = ref
        .watch(remoteShareByVideoIdProvider(widget.videoId))
        .valueOrNull;
    final profiles = ref.watch(profilesProvider).valueOrNull ?? const [];
    final video = videos.firstWhereOrNull((v) => v.id == widget.videoId);
    final palette = ref.watch(activeThemeProvider).palette;
    final identity = ref.watch(parentIdentityProvider).valueOrNull;
    final selectedProfileId = ref.watch(selectedProfileIdProvider);
    final videoProfile = video == null
        ? null
        : profiles.firstWhereOrNull((profile) => profile.id == video.profileId);

    final filePath = video?.filePath;
    final remotePath = remoteShare?.localMediaPath;
    final mediaPath = switch ((filePath, remotePath)) {
      (final String path?, _) when path.isNotEmpty => path,
      (_, final String path?) when path.isNotEmpty => path,
      _ => null,
    };
    _syncMedia(mediaPath);
    final remoteMessage = remoteShare?.shareMessage;
    final remoteThumbPath = remoteShare?.localThumbPath;
    final remoteThumbFile =
        remoteThumbPath != null && remoteThumbPath.isNotEmpty
        ? File(remoteThumbPath)
        : null;
    final hasRemoteThumb = remoteThumbFile?.existsSync() == true;
    final title = video?.title ?? remoteMessage?.meta.title ?? 'Video';
    final subtitle = video != null
        ? video.tags.join(' · ')
        : remoteShare == null
        ? ''
        : '${remoteShare.displayName} · ${remoteShare.status}';
    final remoteLikeCount =
        ref.watch(videoLikeCountProvider(widget.videoId)).valueOrNull ?? 0;
    final remoteLikedByViewer =
        ref.watch(remoteLikeForSelectedViewerProvider(widget.videoId))
            .valueOrNull ??
        false;
    final isLiked = video?.liked ?? remoteLikedByViewer;

    final scrubValue = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF140F19),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Radial accent glow behind video
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 600,
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        palette.accent.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Video player
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.2),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: mediaPath != null
                        ? Video(controller: _videoController)
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              if (hasRemoteThumb)
                                Image.file(remoteThumbFile!, fit: BoxFit.cover)
                              else
                                const ColoredBox(color: Color(0x22FFFFFF)),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.18),
                                      Colors.black.withValues(alpha: 0.48),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      remoteShare == null
                                          ? Icons.play_circle_outline_rounded
                                          : Icons.cloud_download_rounded,
                                      size: 72,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      remoteShare == null
                                          ? 'Video unavailable'
                                          : 'Shared video is not downloaded yet',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (remoteShare != null) ...[
                                      const SizedBox(height: 16),
                                      FilledButton.icon(
                                        onPressed: _isDownloadingRemote
                                            ? null
                                            : () => _downloadRemoteShare(
                                                remoteShare,
                                              ),
                                        icon: _isDownloadingRemote
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.download_rounded,
                                              ),
                                        label: Text(
                                          _isDownloadingRemote
                                              ? 'Downloading...'
                                              : 'Download Now',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            // Paused overlay
            if (!_playing && mediaPath != null)
              Center(
                child: GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [palette.accent, palette.accentSecondary],
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Top bar (auto-hides)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      // Close
                      _CircleBtn(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      // Report
                      _CircleBtn(
                        icon: _isSharingLocal
                            ? Icons.hourglass_top_rounded
                            : Icons.ios_share_rounded,
                        onTap:
                            video == null ||
                                videoProfile == null ||
                                identity == null
                            ? null
                            : () => _shareLocalVideo(
                                localVideo: video,
                                childDisplayName: videoProfile.name,
                                identity: identity,
                              ),
                      ),
                      const SizedBox(width: 8),
                      _CircleBtn(
                        icon: Icons.flag_outlined,
                        onTap:
                            identity == null || selectedProfileId == null
                            ? null
                            : () async {
                                final targetVideoId =
                                    video?.id ?? remoteShare?.videoId;
                                if (targetVideoId == null) {
                                  return;
                                }
                                await showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (sheetContext) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom: MediaQuery.of(
                                          sheetContext,
                                        ).viewInsets.bottom,
                                      ),
                                      child: FeelingReportSheet(
                                        onSubmit: (submission) async {
                                          final result = await ref
                                              .read(reportCoordinatorProvider)
                                              .submitReport(
                                                identity: identity,
                                                videoId: targetVideoId,
                                                subjectChildId:
                                                    selectedProfileId,
                                                blobHash: remoteShare?.blobHash,
                                                reporterChildId:
                                                    selectedProfileId,
                                                reason: submission.reason,
                                                note: submission.note,
                                                level: submission.level,
                                                recipientType:
                                                    submission.recipientType,
                                              );
                                          ref.invalidate(reportsProvider);
                                          if (!context.mounted) {
                                            return;
                                          }
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                result.status == 'delivered'
                                                    ? 'Report delivered'
                                                    : 'Report saved (${result.status})',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom panel (auto-hides)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.white.withValues(alpha: 0.08),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 2,
                                    ),
                                    if (subtitle.isNotEmpty)
                                      Text(
                                        subtitle,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Like button
                              GestureDetector(
                                onTap: () async {
                                  if (video != null) {
                                    await ref
                                        .read(likeCoordinatorProvider)
                                        .setLocalVideoLiked(
                                          videoId: video.id,
                                          liked: !video.liked,
                                        );
                                    return;
                                  }
                                  if (remoteShare == null ||
                                      identity == null ||
                                      selectedProfileId == null ||
                                      remoteLikedByViewer ||
                                      _isSendingLike) {
                                    return;
                                  }
                                  setState(() => _isSendingLike = true);
                                  try {
                                    await ref
                                        .read(likeCoordinatorProvider)
                                        .sendRemoteLike(
                                          identity: identity,
                                          videoId: remoteShare.videoId,
                                          childProfileId: selectedProfileId,
                                          mlsGroupIdHex: remoteShare.mlsGroupId,
                                        );
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSendingLike = false);
                                    }
                                  }
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      isLiked
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      size: 32,
                                      color: isLiked
                                          ? const Color(0xFFFF6B7A)
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                    if (remoteShare != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '$remoteLikeCount',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.72,
                                            ),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Scrubber
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              activeTrackColor: palette.accent,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              thumbColor: Colors.white,
                              overlayColor: palette.accent.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            child: Slider(
                              value: scrubValue,
                              onChanged: _seekTo,
                            ),
                          ),

                          // Time labels
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Playback controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: _rewind,
                                icon: const Icon(
                                  Icons.skip_previous_rounded,
                                  size: 32,
                                ),
                                color: Colors.white,
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _togglePlay,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        palette.accent,
                                        palette.accentSecondary,
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    _playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 36,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.skip_next_rounded,
                                  size: 32,
                                ),
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadRemoteShare(RemoteShareProjection remoteShare) async {
    setState(() => _isDownloadingRemote = true);
    try {
      await ref.read(remoteMediaServiceProvider).downloadVideo(remoteShare);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Shared video downloaded')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isDownloadingRemote = false);
      }
    }
  }

  Future<void> _shareLocalVideo({
    required LocalVideo localVideo,
    required String childDisplayName,
    required ParentIdentity identity,
  }) async {
    if (_isSharingLocal) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSharingLocal = true);
    try {
      final primaryGroupId = await ref
          .read(appDatabaseProvider)
          .getPrimaryGroupIdForProfile(localVideo.profileId);
      final fallbackGroup =
          (await ref.read(mdkServiceProvider).getGroupSummaries()).firstOrNull;
      final targetGroupId = primaryGroupId ?? fallbackGroup?.mlsGroupIdHex;
      if (targetGroupId == null || targetGroupId.isEmpty) {
        throw StateError(
          'Create or join a family connection in Parent Zone first.',
        );
      }

      final event = await ref
          .read(videoShareCoordinatorProvider)
          .createUploadedShareMessage(
            identity: identity,
            localVideo: localVideo,
            childDisplayName: childDisplayName,
            mlsGroupIdHex: targetGroupId,
          );
      final relays = await ref.read(nostrServiceProvider).loadRelayList();
      await ref
          .read(videoShareCoordinatorProvider)
          .publishSignedGroupMessage(
            identity: identity,
            signedEventJson: event.wrapperEventJson,
            relays: relays,
          );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Shared "${localVideo.title}" with your family'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _isSharingLocal = false);
      }
    }
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            color: Colors.white.withValues(alpha: 0.12),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
import '../../../domain/models/video_playback_metrics.dart';
import '../../../domain/models/video_reaction_summary.dart';
import '../../../services/media/video_probe_service.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../../shared_ui/reporting/feeling_report_sheet.dart';
import 'player_route_state.dart';

/// Full-screen video player matching v1 PlayerView design.
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key, this.videoId, this.remoteShareId})
    : assert(videoId != null || remoteShareId != null);

  final String? videoId;
  final String? remoteShareId;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  late final Player _player;
  late final VideoController _videoController;
  late final PlayerRouteArgs _routeArgs;
  late final ProviderSubscription<PlayerRouteState> _routeStateSubscription;
  final List<StreamSubscription<Object?>> _playerSubscriptions = [];
  String? _openedPath;
  bool _isDownloadingRemote = false;
  bool _isRepairingRemoteCache = false;
  bool _isSharingLocal = false;
  bool _isSendingLike = false;
  bool _isSendingReaction = false;
  int? _videoWidth;
  int? _videoHeight;
  double? _probeDisplayAspectRatio;
  String? _lastRemoteValidationId;

  // Controls visibility
  bool _showControls = true;
  bool _sheetExpanded = false;
  Timer? _hideTimer;

  // Player state
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _peakPosition = Duration.zero;
  Duration _lastObservedPosition = Duration.zero;
  bool _replayDetected = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _routeArgs = PlayerRouteArgs(
      videoId: widget.videoId,
      remoteShareId: widget.remoteShareId,
    );
    _player = Player();
    _videoController = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        enableHardwareAcceleration: !(Platform.isAndroid && !kReleaseMode),
      ),
    );
    _playerSubscriptions.add(
      _player.stream.playing.listen((v) {
        if (mounted) setState(() => _playing = v);
        if (v) {
          _resetHideTimer();
        }
      }),
    );
    _playerSubscriptions.add(
      _player.stream.position.listen((v) {
        if (v + const Duration(seconds: 3) < _lastObservedPosition &&
            _peakPosition > const Duration(seconds: 3)) {
          _replayDetected = true;
        }
        if (v > _peakPosition) {
          _peakPosition = v;
        }
        _lastObservedPosition = v;
        if (mounted) setState(() => _position = v);
      }),
    );
    _playerSubscriptions.add(
      _player.stream.duration.listen((v) {
        if (mounted) setState(() => _duration = v);
      }),
    );
    _playerSubscriptions.add(
      _player.stream.width.listen((v) {
        if (mounted) setState(() => _videoWidth = v);
      }),
    );
    _playerSubscriptions.add(
      _player.stream.height.listen((v) {
        if (mounted) setState(() => _videoHeight = v);
      }),
    );
    _routeStateSubscription = ref.listenManual<PlayerRouteState>(
      playerRouteStateProvider(_routeArgs),
      (previous, next) {
        _syncMedia(next.mediaPath);
        unawaited(_ensureRemoteMediaReady(next.remoteShare));
      },
      fireImmediately: true,
    );
    _resetHideTimer();
  }

  // Cache the last route state so we can record metrics in dispose without
  // calling ref.read (which throws after the widget is unmounted).
  PlayerRouteState? _lastRouteState;

  @override
  void dispose() {
    final lastState = _lastRouteState;
    if (lastState != null) {
      unawaited(_recordPlaybackSessionIfNeeded(lastState));
    }
    _hideTimer?.cancel();
    _routeStateSubscription.close();
    for (final subscription in _playerSubscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _syncMedia(String? path) {
    if (path == _openedPath) return;
    _openedPath = path;
    _peakPosition = Duration.zero;
    _lastObservedPosition = Duration.zero;
    _replayDetected = false;
    _probeDisplayAspectRatio = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (path == null || path.isEmpty) {
        await _player.stop();
        return;
      }
      // Use ffprobe to get the true display dimensions (accounting for
      // rotation metadata). This is the source of truth — media_kit's
      // stream.width/height behaviour varies across backends.
      final probe = await probeVideoFile(path);
      if (probe != null && mounted) {
        setState(() => _probeDisplayAspectRatio = probe.displayAspectRatio);
      }
      if (!mounted) return;
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
    HapticFeedback.selectionClick();
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

  double _resolvedAspectRatio() {
    final width = _videoWidth;
    final height = _videoHeight;
    if (width != null && height != null && width > 0 && height > 0) {
      // media_kit (mpv backend on desktop, native on mobile) may or may not
      // account for rotation in stream.width/height. Use the probe result
      // as the source of truth when available — it always gives us the
      // correct display dimensions regardless of backend.
      if (_probeDisplayAspectRatio != null) {
        return _probeDisplayAspectRatio!;
      }
      return width / height;
    }
    // Probe result available before stream dimensions arrive
    if (_probeDisplayAspectRatio != null) {
      return _probeDisplayAspectRatio!;
    }
    return 9 / 16;
  }

  Future<void> _ensureRemoteMediaReady(
    RemoteShareProjection? remoteShare,
  ) async {
    if (remoteShare == null || _isRepairingRemoteCache) {
      return;
    }
    if (remoteShare.status == 'downloading' ||
        remoteShare.status == 'deleted') {
      return;
    }
    final marker =
        '${remoteShare.remoteShareId}:${remoteShare.localMediaPath ?? ''}:${remoteShare.status}';
    if (_lastRemoteValidationId == marker) {
      return;
    }
    _lastRemoteValidationId = marker;
    final shouldRepair =
        remoteShare.localMediaPath != null &&
        remoteShare.localMediaPath!.isNotEmpty &&
        !await ref
            .read(remoteMediaServiceProvider)
            .hasValidCachedVideo(remoteShare);
    if (!shouldRepair || !mounted) {
      return;
    }
    setState(() => _isRepairingRemoteCache = true);
    try {
      await ref
          .read(remoteMediaServiceProvider)
          .ensureVideoAvailable(remoteShare);
    } catch (_) {
      // Leave the projection in a failed state; UI already exposes download.
    } finally {
      if (mounted) {
        setState(() => _isRepairingRemoteCache = false);
      }
    }
  }

  double _resolvedPlaybackDurationSeconds(PlayerRouteState routeState) {
    if (_duration.inMilliseconds > 0) {
      return _duration.inMilliseconds / 1000;
    }
    final localDuration = routeState.video?.durationSeconds;
    if (localDuration != null && localDuration > 0) {
      return localDuration;
    }
    final remoteDuration =
        routeState.remoteShare?.shareMessage?.meta.durationSeconds;
    if (remoteDuration != null && remoteDuration > 0) {
      return remoteDuration;
    }
    return 0;
  }

  Future<void> _recordPlaybackSessionIfNeeded(
    PlayerRouteState routeState,
  ) async {
    final peakSeconds = _peakPosition.inMilliseconds / 1000;
    if (peakSeconds < 2) {
      return;
    }

    final totalDurationSeconds = _resolvedPlaybackDurationSeconds(routeState);
    if (totalDurationSeconds <= 0) {
      return;
    }

    final completionRatio = (peakSeconds / totalDurationSeconds).clamp(
      0.0,
      1.0,
    );
    final localVideo = routeState.video;
    if (localVideo != null) {
      await ref
          .read(playbackMetricsCoordinatorProvider)
          .recordLocalPlayback(
            videoId: localVideo.id,
            completionRatio: completionRatio,
            replayed: _replayDetected,
          );
      return;
    }

    final remoteProjection = routeState.remoteShare;
    if (remoteProjection != null) {
      await ref
          .read(playbackMetricsCoordinatorProvider)
          .recordRemotePlayback(
            remoteShareId: remoteProjection.remoteShareId,
            videoId: remoteProjection.videoId,
            completionRatio: completionRatio,
            replayed: _replayDetected,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeState = ref.watch(playerRouteStateProvider(_routeArgs));
    final palette = ref.watch(activeThemeProvider).palette;
    final mediaQuery = MediaQuery.of(context);
    final isWide = mediaQuery.size.width >= 900;
    final maxPlayerWidth = isWide ? 860.0 : mediaQuery.size.width - 28;
    _lastRouteState = routeState;
    final video = routeState.video;
    final remoteShare = routeState.remoteShare;
    final identity = routeState.identity;
    final selectedProfileId = routeState.selectedProfileId;
    final videoProfile = routeState.videoProfile;
    final mediaPath = routeState.mediaPath;
    final remoteThumbFile = routeState.remoteThumbFile;
    final hasRemoteThumb = routeState.hasRemoteThumb;
    final title = routeState.title;
    final subtitle = routeState.subtitle;
    final remoteLikeCount = routeState.remoteLikeCount;
    final remoteLikedByViewer = routeState.remoteLikedByViewer;
    final isLiked = routeState.isLiked;
    final engagementVideoId = remoteShare?.videoId ?? video?.id;
    final likes = engagementVideoId == null
        ? const <Like>[]
        : ref.watch(videoLikesProvider(engagementVideoId)).valueOrNull ??
              const <Like>[];
    final reactionSummaries = engagementVideoId == null
        ? const <VideoReactionSummary>[]
        : ref.watch(videoReactionSummariesProvider(engagementVideoId));
    final viewerReactions = remoteShare == null || engagementVideoId == null
        ? const <String>[]
        : ref
                  .watch(
                    remoteReactionsForSelectedViewerProvider(engagementVideoId),
                  )
                  .valueOrNull ??
              const <String>[];
    final remotePlaybackMetrics = remoteShare == null
        ? null
        : ref
              .watch(remotePlaybackMetricsProvider(remoteShare.remoteShareId))
              .valueOrNull;
    final playbackMetrics = remoteShare == null
        ? VideoPlaybackMetrics(
            playCount: video?.playCount ?? 0,
            completionRate: video?.completionRate ?? 0,
            replayRate: video?.replayRate ?? 0,
          )
        : VideoPlaybackMetrics(
            playCount: remotePlaybackMetrics?.playCount ?? 0,
            completionRate: remotePlaybackMetrics?.completionRate ?? 0,
            replayRate: remotePlaybackMetrics?.replayRate ?? 0,
          );

    final scrubValue = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final statusTitle = _playerStatusTitle(remoteShare: remoteShare);
    final statusDetail = _playerStatusDetail(remoteShare: remoteShare);
    final stateChangeDuration = AppMotion.duration(
      context,
      AppMotion.stateChange,
    );
    final showPlayerSheet =
        mediaPath != null && (remoteShare == null || remoteShare.isDownloaded);
    final playerBottomInset = showPlayerSheet ? 120.0 : 28.0;

    return Scaffold(
      backgroundColor: palette.backgroundBottom,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.backgroundTop, palette.backgroundBottom],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -40,
              child: _BackdropBlob(
                color: palette.accent.withValues(alpha: 0.18),
                size: isWide ? 280 : 220,
              ),
            ),
            Positioned(
              bottom: 150,
              left: -60,
              child: _BackdropBlob(
                color: palette.accentSecondary.withValues(alpha: 0.16),
                size: isWide ? 320 : 240,
              ),
            ),

            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  14,
                  mediaQuery.padding.top + 72,
                  14,
                  mediaQuery.padding.bottom + playerBottomInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxPlayerWidth),
                  child: AspectRatio(
                    aspectRatio: _resolvedAspectRatio(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.panel.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: palette.panelBorder),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(alpha: 0.12),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: mediaPath != null
                            ? Video(controller: _videoController)
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (hasRemoteThumb)
                                    MediaThumbnailFrame(
                                      file: remoteThumbFile!,
                                      borderRadius: BorderRadius.circular(26),
                                      padding: const EdgeInsets.all(12),
                                    )
                                  else
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            palette.accent.withValues(
                                              alpha: 0.12,
                                            ),
                                            palette.accentSecondary.withValues(
                                              alpha: 0.10,
                                            ),
                                            palette.panel.withValues(
                                              alpha: 0.92,
                                            ),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          palette.ink.withValues(alpha: 0.06),
                                          palette.ink.withValues(alpha: 0.24),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 340,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              remoteShare == null
                                                  ? Icons
                                                        .play_circle_outline_rounded
                                                  : Icons
                                                        .cloud_download_rounded,
                                              size: 72,
                                              color: palette.accent,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              statusTitle,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              statusDetail,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: palette.mutedInk,
                                                fontSize: 14,
                                                height: 1.35,
                                              ),
                                            ),
                                            if (remoteShare != null) ...[
                                              const SizedBox(height: 16),
                                              FilledButton.icon(
                                                onPressed: _isDownloadingRemote
                                                    ? null
                                                    : () =>
                                                          _downloadRemoteShare(
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
                                                      : remoteShare.status ==
                                                            'failed'
                                                      ? 'Repair Download'
                                                      : 'Download Now',
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Paused overlay
            if (!_playing && mediaPath != null)
              Center(
                child: TweenAnimationBuilder<double>(
                  duration: AppMotion.duration(context, AppMotion.layoutChange),
                  curve: AppMotion.easeOutQuint,
                  tween: Tween(begin: 0.92, end: 1),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [palette.accent, palette.accentSecondary],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: palette.accent.withValues(alpha: 0.26),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: stateChangeDuration,
              child: IgnorePointer(
                ignoring: !_showControls,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                    child: Row(
                      children: [
                        _PlayerChromeButton(
                          icon: Icons.close_rounded,
                          palette: palette,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _SharePillButton(
                          isBusy: _isSharingLocal,
                          palette: palette,
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
                        _PlayerChromeButton(
                          icon: Icons.flag_outlined,
                          palette: palette,
                          onTap: identity == null || selectedProfileId == null
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
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            try {
                                              final result = await ref
                                                  .read(
                                                    reportCoordinatorProvider,
                                                  )
                                                  .submitReport(
                                                    identity: identity,
                                                    videoId: targetVideoId,
                                                    subjectChildId:
                                                        selectedProfileId,
                                                    blobHash:
                                                        remoteShare?.blobHash,
                                                    reporterChildId:
                                                        selectedProfileId,
                                                    reason: submission.reason,
                                                    note: submission.note,
                                                    level: submission.level,
                                                    recipientType: submission
                                                        .recipientType,
                                                  );
                                              ref.invalidate(reportsProvider);
                                              ref.invalidate(
                                                offlineActionsProvider,
                                              );
                                              if (!context.mounted) {
                                                return;
                                              }
                                              await HapticFeedback.mediumImpact();
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    result.status == 'delivered'
                                                        ? 'Report delivered'
                                                        : 'Report saved (${result.status})',
                                                  ),
                                                ),
                                              );
                                            } catch (error) {
                                              ref.invalidate(reportsProvider);
                                              ref.invalidate(
                                                offlineActionsProvider,
                                              );
                                              if (!context.mounted) {
                                                return;
                                              }
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    _reportErrorMessage(error),
                                                  ),
                                                ),
                                              );
                                            }
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
            ),

            if (showPlayerSheet)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: stateChangeDuration,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: GestureDetector(
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity == null) return;
                        if (details.primaryVelocity! < -200) {
                          setState(() => _sheetExpanded = true);
                        } else if (details.primaryVelocity! > 200) {
                          setState(() => _sheetExpanded = false);
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          12,
                          0,
                          12,
                          mediaQuery.padding.bottom + 10,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isWide ? 520 : double.infinity,
                            ),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: AppMotion.easeOutQuart,
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: palette.panel.withValues(alpha: 0.98),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: palette.panelBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: palette.ink.withValues(alpha: 0.10),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Drag handle
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _sheetExpanded = !_sheetExpanded,
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Center(
                                          child: Container(
                                            width: 36,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: palette.panelBorder,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ── Collapsed: compact transport bar ──
                                    SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 7,
                                        ),
                                        activeTrackColor: palette.accent,
                                        inactiveTrackColor: palette.panelBorder
                                            .withValues(alpha: 0.7),
                                        thumbColor: Colors.white,
                                        overlayColor: palette.accent.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                      child: Slider(
                                        value: scrubValue,
                                        onChanged: _seekTo,
                                      ),
                                    ),

                                    Row(
                                      children: [
                                        // Time
                                        Text(
                                          _formatDuration(_position),
                                          style: TextStyle(
                                            color: palette.mutedInk,
                                            fontSize: 12,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),

                                        // Compact play controls
                                        IconButton(
                                          onPressed: _rewind,
                                          icon: const Icon(
                                            Icons.skip_previous_rounded,
                                            size: 26,
                                          ),
                                          color: palette.ink,
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: _togglePlay,
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  palette.accent,
                                                  palette.accentSecondary,
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: palette.accent
                                                      .withValues(alpha: 0.22),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _playing
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              size: 28,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () {},
                                          icon: const Icon(
                                            Icons.skip_next_rounded,
                                            size: 26,
                                          ),
                                          color: palette.panelBorder,
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                        ),

                                        const Spacer(),

                                        // Time remaining
                                        Text(
                                          _formatDuration(_duration),
                                          style: TextStyle(
                                            color: palette.mutedInk,
                                            fontSize: 12,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ── Expanded: title, like, metrics ──
                                    if (_sheetExpanded)
                                      Flexible(
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                      const SizedBox(height: 14),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: palette.accent
                                                        .withValues(alpha: 0.10),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    remoteShare == null
                                                        ? 'My clip'
                                                        : 'Family share',
                                                    style: TextStyle(
                                                      color: palette.accent,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  title,
                                                  style: TextStyle(
                                                    color: palette.ink,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (subtitle.isNotEmpty)
                                                  Text(
                                                    subtitle,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: palette.mutedInk,
                                                      fontSize: 13,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () async {
                                              if (video != null) {
                                                await HapticFeedback
                                                    .selectionClick();
                                                await ref
                                                    .read(
                                                      likeCoordinatorProvider,
                                                    )
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
                                              setState(
                                                () => _isSendingLike = true,
                                              );
                                              try {
                                                await ref
                                                    .read(
                                                      likeCoordinatorProvider,
                                                    )
                                                    .sendRemoteLike(
                                                      identity: identity,
                                                      videoId:
                                                          remoteShare.videoId,
                                                      childProfileId:
                                                          selectedProfileId,
                                                      mlsGroupIdHex:
                                                          remoteShare
                                                              .mlsGroupId,
                                                    );
                                                ref.invalidate(
                                                  offlineActionsProvider,
                                                );
                                                await HapticFeedback
                                                    .selectionClick();
                                              } catch (error) {
                                                ref.invalidate(
                                                  offlineActionsProvider,
                                                );
                                                if (!mounted) {
                                                  return;
                                                }
                                                final messenger =
                                                    ScaffoldMessenger.of(
                                                      this.context,
                                                    );
                                                messenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      _likeErrorMessage(error),
                                                    ),
                                                  ),
                                                );
                                              } finally {
                                                if (mounted) {
                                                  setState(
                                                    () =>
                                                        _isSendingLike = false,
                                                  );
                                                }
                                              }
                                            },
                                            child: AnimatedScale(
                                              duration: stateChangeDuration,
                                              curve: AppMotion.easeOutQuint,
                                              scale: isLiked ? 1.05 : 1.0,
                                              child: AnimatedContainer(
                                                duration: stateChangeDuration,
                                                curve: AppMotion.easeOutQuint,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isLiked
                                                      ? const Color(0xFFFFE4E8)
                                                      : Colors.white.withValues(
                                                          alpha: 0.78,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: isLiked
                                                        ? const Color(
                                                            0xFFFFC7D0,
                                                          )
                                                        : palette.panelBorder,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(
                                                      isLiked
                                                          ? Icons
                                                                .favorite_rounded
                                                          : Icons
                                                                .favorite_border_rounded,
                                                      size: 28,
                                                      color: isLiked
                                                          ? const Color(
                                                              0xFFFF6B7A,
                                                            )
                                                          : palette.mutedInk,
                                                    ),
                                                    if (remoteShare != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 4),
                                                        child: Text(
                                                          '$remoteLikeCount',
                                                          style: TextStyle(
                                                            color: palette.ink,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      _PlaybackMetricRow(
                                        palette: palette,
                                        metrics: playbackMetrics,
                                        isRemote: remoteShare != null,
                                      ),
                                      if (remoteShare != null) ...[
                                        const SizedBox(height: 14),
                                        _PlaybackLikeSummary(
                                          likes: likes,
                                          likeCount: remoteLikeCount,
                                          palette: palette,
                                        ),
                                        const SizedBox(height: 14),
                                        _ReactionSection(
                                          palette: palette,
                                          reactions: reactionSummaries,
                                          selectedEmojis: viewerReactions,
                                          isSendingReaction:
                                              _isSendingReaction,
                                          onSelect: (emoji) async {
                                            if (identity == null ||
                                                selectedProfileId == null ||
                                                _isSendingReaction ||
                                                viewerReactions
                                                    .contains(emoji)) {
                                              return;
                                            }
                                            setState(
                                              () =>
                                                  _isSendingReaction = true,
                                            );
                                            try {
                                              await ref
                                                  .read(
                                                    reactionCoordinatorProvider,
                                                  )
                                                  .sendRemoteReaction(
                                                    identity: identity,
                                                    videoId:
                                                        remoteShare.videoId,
                                                    childProfileId:
                                                        selectedProfileId,
                                                    mlsGroupIdHex:
                                                        remoteShare
                                                            .mlsGroupId,
                                                    emoji: emoji,
                                                  );
                                              ref.invalidate(
                                                offlineActionsProvider,
                                              );
                                              await HapticFeedback
                                                  .selectionClick();
                                            } catch (error) {
                                              ref.invalidate(
                                                offlineActionsProvider,
                                              );
                                              if (!mounted) {
                                                return;
                                              }
                                              ScaffoldMessenger.of(
                                                this.context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    _reactionErrorMessage(
                                                      error,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () =>
                                                      _isSendingReaction =
                                                          false,
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isDownloadingRemote = true);
    try {
      await ref.read(remoteMediaServiceProvider).downloadVideo(remoteShare);
      if (!mounted) {
        return;
      }
      await HapticFeedback.lightImpact();
      messenger.showSnackBar(
        const SnackBar(content: Text('Shared video downloaded')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_downloadErrorMessage(error))));
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
      final dispatchResult = await ref
          .read(videoShareCoordinatorProvider)
          .shareLocalVideoToEligibleGroups(
            identity: identity,
            videoId: localVideo.id,
            profileId: localVideo.profileId,
            childDisplayName: childDisplayName,
          );
      ref.invalidate(offlineActionsProvider);
      ref.invalidate(shareHistoryProvider);
      if (!mounted) {
        return;
      }
      await HapticFeedback.mediumImpact();
      final message = switch ((
        dispatchResult.sharedGroupCount,
        dispatchResult.queuedGroupCount,
      )) {
        (0, final queued) when queued > 0 =>
          'Queued "${localVideo.title}" for $queued family space${queued == 1 ? '' : 's'}',
        (final shared, 0) when shared > 0 =>
          'Shared "${localVideo.title}" with $shared family space${shared == 1 ? '' : 's'}',
        (final shared, final queued) =>
          'Shared to $shared family space${shared == 1 ? '' : 's'}, queued $queued more',
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      ref.invalidate(offlineActionsProvider);
      ref.invalidate(shareHistoryProvider);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_shareErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingLocal = false);
      }
    }
  }

  String _playerStatusTitle({required RemoteShareProjection? remoteShare}) {
    if (remoteShare == null) {
      return 'This video isn\'t here yet';
    }
    if (_isRepairingRemoteCache) {
      return 'Getting your video ready';
    }
    if (remoteShare.status == 'failed') {
      return 'Let\'s try that download again';
    }
    return 'Family video ready to watch';
  }

  String _playerStatusDetail({required RemoteShareProjection? remoteShare}) {
    if (remoteShare == null) {
      return 'This clip is still getting ready on this device.';
    }
    if (_isRepairingRemoteCache) {
      return 'Checking the saved copy so playback stays smooth and safe.';
    }
    if (remoteShare.status == 'failed') {
      return 'The earlier download didn\'t finish cleanly. Repair it to watch this family clip.';
    }
    return 'Download this family clip and press play when it is ready.';
  }

  String _downloadErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('timeout')) {
      return 'We couldn\'t download that clip right now. Check your connection and try again.';
    }
    if (message.contains('decrypt') || message.contains('cache')) {
      return 'The saved copy needs another pass. Try the download again in a moment.';
    }
    return 'We couldn\'t download that clip yet. Please try again.';
  }

  String _shareErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('approval')) {
      return 'This clip still needs a parent review before it can be shared.';
    }
    if (message.contains('group') || message.contains('family')) {
      return 'Connect with a family space first, then try sharing again.';
    }
    return 'We couldn\'t share that clip yet. It\'s still saved safely here.';
  }

  String _reportErrorMessage(Object error) {
    return 'We couldn\'t send that report just yet. Your note is still on this device, so please try again.';
  }

  String _likeErrorMessage(Object error) {
    return 'That like didn\'t go through yet. Please try again in a moment.';
  }

  String _reactionErrorMessage(Object error) {
    return 'That reaction didn\'t go through yet. Please try again in a moment.';
  }
}

class _PlayerChromeButton extends StatelessWidget {
  const _PlayerChromeButton({
    required this.icon,
    required this.palette,
    this.onTap,
  });

  final IconData icon;
  final KidPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? Colors.white.withValues(alpha: 0.82)
          : Colors.white.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: enabled ? palette.ink : palette.mutedInk,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _SharePillButton extends StatelessWidget {
  const _SharePillButton({
    required this.isBusy,
    required this.palette,
    this.onTap,
  });

  final bool isBusy;
  final KidPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !isBusy;
    return Material(
      color: enabled
          ? Colors.white.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBusy ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
                color: enabled ? palette.ink : palette.mutedInk,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isBusy ? 'Sharing' : 'Share',
                style: TextStyle(
                  color: enabled ? palette.ink : palette.mutedInk,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackMetricRow extends StatelessWidget {
  const _PlaybackMetricRow({
    required this.palette,
    required this.metrics,
    required this.isRemote,
  });

  final KidPalette palette;
  final VideoPlaybackMetrics metrics;
  final bool isRemote;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      '${metrics.playCount} ${metrics.playCount == 1 ? 'Play' : 'Plays'}',
      '${(metrics.completionRate * 100).round()}% Completion',
      '${(metrics.replayRate * 100).round()}% Replays',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRemote ? 'Watching so far on this device' : 'Watching so far',
          style: TextStyle(
            color: palette.mutedInk,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in chips)
              _MetricChip(palette: palette, label: label),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.palette, required this.label});

  final KidPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.accent, palette.accentSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PlaybackLikeSummary extends ConsumerWidget {
  const _PlaybackLikeSummary({
    required this.likes,
    required this.likeCount,
    required this.palette,
  });

  final List<Like> likes;
  final int likeCount;
  final KidPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uniqueLikes = <String, Like>{};
    for (final like in likes) {
      uniqueLikes.putIfAbsent(like.parentPubkey, () => like);
    }
    final visibleLikes = uniqueLikes.values.take(8).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          likeCount == 0
              ? 'No likes yet'
              : '$likeCount ${likeCount == 1 ? 'Like' : 'Likes'}',
          style: TextStyle(
            color: palette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (visibleLikes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final like in visibleLikes)
                _NameChip(
                  palette: palette,
                  label:
                      ref
                          .watch(
                            resolvedParentProfileProvider(like.parentPubkey),
                          )
                          .valueOrNull
                          ?.displayName ??
                      'A family',
                ),
              if (likeCount > visibleLikes.length)
                _NameChip(
                  palette: palette,
                  label: '+${likeCount - visibleLikes.length} more',
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReactionSection extends StatelessWidget {
  const _ReactionSection({
    required this.palette,
    required this.reactions,
    required this.selectedEmojis,
    required this.isSendingReaction,
    required this.onSelect,
  });

  final KidPalette palette;
  final List<VideoReactionSummary> reactions;
  final List<String> selectedEmojis;
  final bool isSendingReaction;
  final ValueChanged<String> onSelect;

  static const _emojiChoices = <String>['😂', '😮', '🎉', '🔥'];

  @override
  Widget build(BuildContext context) {
    final reactionCounts = <String, int>{
      for (final reaction in reactions) reaction.emoji: reaction.count,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reactions',
          style: TextStyle(
            color: palette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final emoji in _emojiChoices)
              _ReactionChip(
                palette: palette,
                emoji: emoji,
                count: reactionCounts[emoji] ?? 0,
                isSelected: selectedEmojis.contains(emoji),
                isDisabled: isSendingReaction,
                onTap: () => onSelect(emoji),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.palette,
    required this.emoji,
    required this.count,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final KidPalette palette;
  final String emoji;
  final int count;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: isDisabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? palette.accent.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? palette.accent : palette.panelBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 17)),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: palette.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip({required this.palette, required this.label});

  final KidPalette palette;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.panelBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  const _BackdropBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

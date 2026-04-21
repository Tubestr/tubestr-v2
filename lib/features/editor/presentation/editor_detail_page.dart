import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
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
import '../domain/editor_source.dart';
import '../../../domain/models/content_scan_summary.dart';
import '../../../domain/models/editor_resources.dart';
import '../../../services/editor/editor_audio_library_service.dart';
import '../../../domain/models/editor_session.dart';
import '../../../services/editor/editor_audio_preview_service.dart';
import '../../../services/editor/editor_export_service.dart';
import '../../../services/editor/editor_resource_catalog.dart';
import '../../../services/editor/editor_sticker_library.dart';
import '../../../services/media/video_probe_service.dart';
import '../../../shared_ui/components/kid_scaffold.dart';
import '../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../player/presentation/player_page.dart';
import '../domain/editor_preview_style.dart';
import '../domain/editor_trim_utils.dart';
import 'selfie_sticker_capture_page.dart';
import '../../../l10n/l10n.dart';

class EditorDetailPage extends ConsumerStatefulWidget {
  const EditorDetailPage({super.key, required this.source});

  /// Convenience constructor that wraps a [LocalVideo] in an [EditorSource].
  EditorDetailPage.fromVideo({super.key, required LocalVideo video})
    : source = EditorSource.fromLocalVideo(video);

  final EditorSource source;

  @override
  ConsumerState<EditorDetailPage> createState() => _EditorDetailPageState();
}

class _EditorDetailPageState extends ConsumerState<EditorDetailPage>
    with TickerProviderStateMixin {
  static const _textColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFFFD54F),
    Color(0xFFFF8A80),
    Color(0xFF80D8FF),
    Color(0xFFA7FFEB),
    Color(0xFFE1BEE7),
  ];

  static final _fontFamilies = <String>['Fredoka', 'Baloo', 'Bubblegum Sans'];

  late final Player _player;
  late final VideoController _videoController;
  late final EditorAudioPreviewService _audioPreviewService;
  late final EditorAudioLibraryService _audioLibraryService;
  late final EditorStickerLibrary _stickerLibrary;
  late final AnimationController _overlayAnimController;
  late final Animation<Offset> _overlaySlide;
  late final Animation<double> _overlayFade;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<VideoParams>? _videoParamsSubscription;
  late EditorSession _session;
  double _gestureStartScale = 1;
  double _gestureStartRotation = 0;
  Offset _gestureStartPosition = const Offset(0.5, 0.5);
  Offset? _gestureStartFocalPoint;
  String? _selectedOverlayId;
  String? _previewingTrackId;
  Duration _previewPosition = Duration.zero;
  bool _previewPlaying = false;
  EditorTool? _activeTool;
  bool _isExporting = false;
  bool _loopSeekInFlight = false;
  List<EditorStickerAsset> _userStickers = const [];
  Set<String> _cachedAudioTrackIds = const {};
  final Set<String> _downloadingAudioTrackIds = {};
  int? _videoWidth;
  int? _videoHeight;
  double? _probeDisplayAspectRatio;
  VideoParams _videoParams = const VideoParams();

  @override
  void initState() {
    super.initState();
    _player = Player();
    _videoController = VideoController(_player);
    _audioPreviewService = EditorAudioPreviewService();
    _audioLibraryService = ref.read(editorAudioLibraryServiceProvider);
    _stickerLibrary = EditorStickerLibrary();
    _overlayAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _overlaySlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _overlayAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _overlayFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _overlayAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    final rawDuration = Duration(
      milliseconds: (widget.source.durationSeconds * 1000).round(),
    );
    final normalizedTrim = normalizeEditorTrim(
      rawVideoDuration: rawDuration,
      rawTrimRange: EditorTrimRange(
        start: Duration.zero,
        end: rawDuration > Duration.zero
            ? rawDuration
            : const Duration(seconds: 30),
      ),
    );
    _session = EditorSession(
      videoId: widget.source.id,
      sourcePath: widget.source.filePath,
      videoDuration: normalizedTrim.videoDuration,
      trimRange: normalizedTrim.trimRange,
    );
    _playingSubscription = _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _previewPlaying = playing);
    });
    _positionSubscription = _player.stream.position.listen(
      _handlePreviewPosition,
    );
    _player.stream.width.listen((value) {
      if (!mounted) {
        return;
      }
      if (value != null && value > 0) {
        setState(() => _videoWidth = value);
      }
    });
    _player.stream.height.listen((value) {
      if (!mounted) {
        return;
      }
      if (value != null && value > 0) {
        setState(() => _videoHeight = value);
      }
    });
    _videoParamsSubscription = _player.stream.videoParams.listen((value) {
      if (!mounted) {
        return;
      }
      if (_hasUsableVideoParams(value)) {
        setState(() => _videoParams = value);
      }
    });
    _probeAndOpen();
    unawaited(_loadUserStickers());
    unawaited(_refreshAudioCacheState());
  }

  @override
  void dispose() {
    _overlayAnimController.dispose();
    unawaited(_audioPreviewService.dispose());
    unawaited(_playingSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_videoParamsSubscription?.cancel());
    _player.dispose();
    super.dispose();
  }

  void _setActiveTool(EditorTool? tool) {
    setState(() {
      if (_activeTool == tool) {
        _activeTool = null;
        _overlayAnimController.reverse();
      } else {
        final wasNull = _activeTool == null;
        _activeTool = tool;
        if (wasNull) {
          _overlayAnimController.forward(from: 0);
        }
      }
    });
  }

  void _dismissToolOverlay() {
    if (_activeTool != null) {
      setState(() => _activeTool = null);
      _overlayAnimController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(activePaletteProvider);
    final isTrimActive = _activeTool == EditorTool.trim;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = KidLayoutSpec.fromWidth(constraints.maxWidth);
            final isCompactLandscape =
                !layout.isTablet &&
                constraints.maxWidth > constraints.maxHeight;
            final edgeInset = layout.isTablet ? 24.0 : 12.0;
            final sidebarWidth = layout.isTablet ? 72.0 : 64.0;
            final sidebarRight = layout.isTablet ? 20.0 : 12.0;
            final overlayMaxWidth = layout.isTablet ? 680.0 : double.infinity;
            final timelineMaxWidth = layout.isTablet ? 800.0 : double.infinity;
            final timelineHeight = isTrimActive ? 96.0 : 54.0;
            final overlayBottom = isTrimActive ? 104.0 : 62.0;
            final toolbarTop = isCompactLandscape ? edgeInset + 58.0 : 0.0;
            final toolbarBottom = isCompactLandscape
                ? timelineHeight + 10.0
                : 0.0;

            return Stack(
              children: [
                // Full-screen video preview
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _dismissToolOverlay,
                    child: _PreviewPane(
                      palette: palette,
                      videoController: _videoController,
                      session: _session,
                      videoAspectRatio: _resolvedVideoAspectRatio(),
                      selectedOverlayId: _selectedOverlayId,
                      isPlaying: _previewPlaying,
                      onTogglePlayback: _togglePreviewPlayback,
                      onOverlaySelected: (overlayId) {
                        setState(() => _selectedOverlayId = overlayId);
                      },
                      onOverlayScaleStart: _handleStickerScaleStart,
                      onOverlayScaleUpdate: (details, size, overlay) {
                        _handleStickerScaleUpdate(details, size, overlay);
                      },
                      onOverlayDeleted: _removeOverlay,
                    ),
                  ),
                ),

                // Timeline bar (always visible at bottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: timelineMaxWidth),
                      child: _TimelineBar(
                        palette: palette,
                        thumbPath: widget.source.thumbPath,
                        session: _session,
                        isTrimActive: isTrimActive,
                        previewPosition: _previewPosition,
                        onTrimChanged: _updateTrimRange,
                      ),
                    ),
                  ),
                ),

                // Right side toolbar
                Positioned(
                  right: sidebarRight,
                  top: toolbarTop,
                  bottom: toolbarBottom,
                  child: _SideToolbar(
                    palette: palette,
                    activeTool: _activeTool,
                    onToolTap: _setActiveTool,
                    isTablet: layout.isTablet,
                    isCompact: isCompactLandscape,
                  ),
                ),

                // Contextual tool overlay (above timeline)
                if (_activeTool != null && _activeTool != EditorTool.trim)
                  Positioned(
                    left: edgeInset,
                    right: sidebarRight + sidebarWidth,
                    bottom: overlayBottom,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: overlayMaxWidth),
                        child: SlideTransition(
                          position: _overlaySlide,
                          child: FadeTransition(
                            opacity: _overlayFade,
                            child: _ActiveToolOverlay(
                              palette: palette,
                              activeTool: _activeTool!,
                              session: _session,
                              isTablet: layout.isTablet,
                              onFilterChanged: (filterId) {
                                setState(() {
                                  _session = _session.copyWith(
                                    filterPresetId: filterId,
                                  );
                                });
                              },
                              onAdjustmentsChanged: (adjustments) {
                                setState(() {
                                  _session = _session.copyWith(
                                    adjustments: adjustments,
                                  );
                                });
                              },
                              onStickerSelected: _selectSticker,
                              onOpenSelfieStickerCapture:
                                  _openSelfieStickerCapture,
                              userStickers: _userStickers,
                              onDeleteUserSticker: _deleteUserSticker,
                              onMusicSelected: _selectMusicTrack,
                              onMusicRemoved: _removeMusicTrack,
                              onMusicVolumeChanged: _updateMusicVolume,
                              onMusicPreviewToggled: _toggleMusicPreview,
                              previewingTrackId: _previewingTrackId,
                              cachedAudioTrackIds: _cachedAudioTrackIds,
                              downloadingAudioTrackIds:
                                  _downloadingAudioTrackIds,
                              selectedOverlayId: _selectedOverlayId,
                              onAddTextOverlay: _addTextOverlay,
                              onTextChanged: _updateTextOverlay,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Minimal header
                Positioned(
                  top: edgeInset,
                  left: edgeInset,
                  right: edgeInset,
                  child: _MinimalHeader(
                    palette: palette,
                    isExporting: _isExporting,
                    onExport: _exportEdit,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Business logic (unchanged) ──────────────────────────────────────

  void _updateTrimRange(RangeValues values) {
    final totalMs = math.max(_session.videoDuration.inMilliseconds, 1);
    final minGapMs = totalMs < 250 ? 1 : 250;
    final maxStartMs = math.max(totalMs - minGapMs, 0);
    final startMs = (values.start * totalMs).round().clamp(0, maxStartMs);
    final endMs = (values.end * totalMs).round().clamp(
      startMs + minGapMs,
      totalMs,
    );
    setState(() {
      _session = _session.copyWith(
        trimRange: EditorTrimRange(
          start: Duration(milliseconds: startMs),
          end: Duration(milliseconds: endMs),
        ),
      );
    });
    unawaited(_seekPreviewToTrimStart());
  }

  Future<void> _seekPreviewToTrimStart() async {
    await _player.seek(_session.trimRange.start);
    if (!mounted) return;
    setState(() => _previewPosition = _session.trimRange.start);
  }

  void _handlePreviewPosition(Duration position) {
    if (mounted) {
      setState(() => _previewPosition = position);
    }
    if (!_previewPlaying ||
        _loopSeekInFlight ||
        _session.trimRange.duration <= const Duration(milliseconds: 300)) {
      return;
    }
    final trimEnd = _session.trimRange.end;
    if (position >= trimEnd - const Duration(milliseconds: 40)) {
      _loopSeekInFlight = true;
      unawaited(() async {
        try {
          await _player.seek(_session.trimRange.start);
          await _player.play();
        } finally {
          _loopSeekInFlight = false;
        }
      }());
    }
  }

  Future<void> _togglePreviewPlayback() async {
    final trimRange = _session.trimRange;
    if (_previewPosition >= trimRange.end) {
      await _player.seek(trimRange.start);
    }
    await _player.playOrPause();
  }

  void _selectSticker(String stickerId, String assetPath) {
    final sticker = EditorOverlayItem(
      id: 'sticker:$stickerId:${DateTime.now().microsecondsSinceEpoch}',
      type: EditorOverlayType.sticker,
      stickerId: stickerId,
      stickerAssetPath: assetPath,
      transform: const StickerTransform(position: Offset(0.5, 0.35)),
    );
    final overlays = [..._session.overlays, sticker];
    setState(() {
      _selectedOverlayId = sticker.id;
      _session = _session.copyWith(overlays: overlays);
    });
  }

  void _removeOverlay(String overlayId) {
    setState(() {
      _session = _session.copyWith(
        overlays: _session.overlays
            .where((overlay) => overlay.id != overlayId)
            .toList(growable: false),
      );
      if (_selectedOverlayId == overlayId) {
        _selectedOverlayId = null;
      }
    });
  }

  Future<void> _selectMusicTrack(EditorMusicTrackAsset track) async {
    try {
      final playablePath = await _ensureAudioTrackAvailable(track);
      if (!mounted) return;
      setState(() {
        _session = _session.copyWith(
          audioSelection: EditorAudioSelection(
            trackId: track.id,
            assetPath: playablePath,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      _showAudioError(track, error);
    }
  }

  void _removeMusicTrack() {
    unawaited(_audioPreviewService.stop());
    setState(() {
      _previewingTrackId = null;
      _session = _session.copyWith(clearAudioSelection: true);
    });
  }

  void _updateMusicVolume(double volume) {
    final selection = _session.audioSelection;
    if (selection == null) return;
    unawaited(_audioPreviewService.updateVolume(volume));
    setState(() {
      _session = _session.copyWith(
        audioSelection: selection.copyWith(volume: volume),
      );
    });
  }

  Future<void> _toggleMusicPreview(EditorMusicTrackAsset track) async {
    final audioSelection = _session.audioSelection;
    final volume = audioSelection?.trackId == track.id
        ? audioSelection!.volume
        : 0.75;
    try {
      final playablePath = await _ensureAudioTrackAvailable(track);
      final isPlaying = await _audioPreviewService.togglePreview(
        assetPath: playablePath,
        volume: volume,
      );
      if (!mounted) return;
      setState(() {
        _previewingTrackId = isPlaying ? track.id : null;
      });
    } catch (error) {
      if (!mounted) return;
      _showAudioError(track, error);
    }
  }

  Future<String> _ensureAudioTrackAvailable(EditorMusicTrackAsset track) async {
    if (_downloadingAudioTrackIds.contains(track.id)) {
      throw StateError('${track.label} is still downloading.');
    }

    setState(() {
      _downloadingAudioTrackIds.add(track.id);
    });
    try {
      final path = await _audioLibraryService.ensureTrackAvailable(track);
      if (mounted) {
        setState(() {
          _cachedAudioTrackIds = {..._cachedAudioTrackIds, track.id};
        });
      }
      return path;
    } finally {
      if (mounted) {
        setState(() {
          _downloadingAudioTrackIds.remove(track.id);
        });
      }
    }
  }

  Future<void> _refreshAudioCacheState() async {
    final cached = await _audioLibraryService.cachedTrackIds(
      EditorResourceCatalog.builtInMusicTracks,
    );
    if (!mounted) return;
    setState(() => _cachedAudioTrackIds = cached);
  }

  void _showAudioError(EditorMusicTrackAsset track, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.editorLoadTrackFailed(track.label)),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _exportEdit() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      await _audioPreviewService.stop();
      await _player.pause();
      if (!mounted) return;
      final preferredDisplaySize = _preferredDisplaySize();
      final preferredRotationDegrees = _preferredRotationDegrees();
      final result = await ref
          .read(editorExportServiceProvider)
          .export(
            session: _session,
            profileId: widget.source.profileId,
            title: context.l10n.editorRemixTitle(widget.source.title),
            preferredDisplaySize: preferredDisplaySize,
            preferredRotationDegrees: preferredRotationDegrees,
          );
      if (!mounted) return;
      ref.invalidate(videosForSelectedProfileProvider);
      final exportedVideo = await ref
          .read(appDatabaseProvider)
          .getLocalVideoById(result.videoId);
      if (!mounted) {
        return;
      }
      await HapticFeedback.mediumImpact();
      await _showExportCompleteSheet(
        result: result,
        exportedVideo: exportedVideo,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_exportErrorMessage(error)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        await _player.open(Media(widget.source.filePath), play: false);
        await _seekPreviewToTrimStart();
      }
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _loadUserStickers() async {
    final stickers = await _stickerLibrary.listUserStickers(
      profileId: widget.source.profileId,
    );
    if (!mounted) return;
    setState(() => _userStickers = stickers);
  }

  Future<void> _openSelfieStickerCapture() async {
    HapticFeedback.selectionClick();
    final createdSticker = await Navigator.of(context).push<EditorStickerAsset>(
      AppMotion.modalRoute(
        context: context,
        builder: (_) => SelfieStickerCapturePage(
          profileId: widget.source.profileId,
          palette: ref.read(activePaletteProvider),
          stickerLibrary: _stickerLibrary,
        ),
        fullscreenDialog: true,
      ),
    );
    if (createdSticker == null || !mounted) return;
    await _loadUserStickers();
    _selectSticker(createdSticker.id, createdSticker.assetPath);
  }

  Future<void> _deleteUserSticker(EditorStickerAsset sticker) async {
    if (!sticker.isUserCreated) return;
    await _stickerLibrary.deleteSticker(
      profileId: widget.source.profileId,
      stickerPath: sticker.assetPath,
    );
    if (!mounted) return;
    final placed = _session.overlays
        .where(
          (overlay) =>
              overlay.type == EditorOverlayType.sticker &&
              overlay.stickerAssetPath == sticker.assetPath,
        )
        .map((overlay) => overlay.id)
        .toList(growable: false);
    for (final id in placed) {
      _removeOverlay(id);
    }
    await _loadUserStickers();
  }

  Future<void> _showExportCompleteSheet({
    required EditorExportResult result,
    required LocalVideo? exportedVideo,
  }) async {
    final scan = _parseScanSummary(exportedVideo?.scanResults);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final palette = ref.read(activePaletteProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF15111C),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: palette.accent.withValues(alpha: 0.18),
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: palette.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.editorRemixSavedTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.warning == null
                          ? context.l10n.editorExportSaved
                          : context.l10n.editorExportWarning(result.warning!),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    if (scan != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              scan.needsReview
                                  ? Icons.shield_outlined
                                  : Icons.verified_rounded,
                              color: scan.needsReview
                                  ? Colors.amber.shade300
                                  : palette.success,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                scan.summary,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: exportedVideo == null
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(sheetContext).pop();
                                  Navigator.of(context).push(
                                    AppMotion.modalRoute(
                                      context: context,
                                      builder: (_) =>
                                          PlayerPage(videoId: exportedVideo.id),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          label: Text(context.l10n.actionWatch),
                        ),
                        FilledButton.icon(
                          onPressed:
                              exportedVideo == null || scan?.needsReview == true
                              ? null
                              : () async {
                                  Navigator.of(sheetContext).pop();
                                  await _shareExportedVideo(exportedVideo);
                                },
                          icon: const Icon(Icons.ios_share_rounded),
                          label: Text(
                            scan?.needsReview == true
                                ? context.l10n.editorReviewFirst
                                : context.l10n.actionShare,
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(context.l10n.editorActionKeepEditing),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ContentScanSummary? _parseScanSummary(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      return ContentScanSummary.decode(encoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareExportedVideo(LocalVideo video) async {
    final identity = ref.read(parentIdentityProvider).valueOrNull;
    final profiles = ref.read(profilesProvider).valueOrNull ?? const [];
    final profile = profiles.firstWhereOrNull(
      (item) => item.id == video.profileId,
    );
    if (identity == null || profile == null) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(videoShareCoordinatorProvider)
          .queueShareToEligibleGroups(
            identity: identity,
            videoId: video.id,
            profileId: profile.id,
            childDisplayName: profile.name,
          );
      unawaited(
        ref.read(offlineActionProcessorProvider).flush().catchError((_) => 0),
      );
      if (!mounted) {
        return;
      }
      final count = result.queuedGroupCount;
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.editorSharing(count))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_shareErrorMessage(error))),
      );
    }
  }

  String _exportErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('ffmpeg') || message.contains('export')) {
      return context.l10n.editorExportSaveFailed;
    }
    return context.l10n.editorExportGenericFailed;
  }

  String _shareErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('approval')) {
      return context.l10n.editorShareNeedsReview;
    }
    if (_looksLikeShareUploadError(message)) {
      return context.l10n.editorShareUploadFailed;
    }
    if (message.contains('group') || message.contains('family')) {
      return context.l10n.editorShareConnectFamily;
    }
    return context.l10n.editorShareFailed;
  }

  bool _looksLikeShareUploadError(String message) {
    return message.contains('blossom') ||
        message.contains('upload') ||
        message.contains('auth event') ||
        message.contains('created_at') ||
        message.contains('future') ||
        message.contains('socket') ||
        message.contains('media server');
  }

  void _addTextOverlay() {
    final overlay = EditorOverlayItem(
      id: 'text:${DateTime.now().microsecondsSinceEpoch}',
      type: EditorOverlayType.text,
      text: '',
      fontFamily: _EditorDetailPageState._fontFamilies.first,
      textColorValue: _EditorDetailPageState._textColors.first.toARGB32(),
      textSize: 44,
      transform: const StickerTransform(position: Offset(0.5, 0.5)),
    );
    setState(() {
      _session = _session.copyWith(overlays: [..._session.overlays, overlay]);
      _selectedOverlayId = overlay.id;
    });
  }

  void _updateTextOverlay({
    required String overlayId,
    String? text,
    String? fontFamily,
    Color? color,
    double? textSize,
  }) {
    final overlays = _session.overlays
        .map(
          (item) => item.id == overlayId
              ? item.copyWith(
                  text: text ?? item.text,
                  fontFamily: fontFamily ?? item.fontFamily,
                  textColorValue: color?.toARGB32() ?? item.textColorValue,
                  textSize: textSize ?? item.textSize,
                )
              : item,
        )
        .toList(growable: false);
    setState(() {
      _session = _session.copyWith(overlays: overlays);
    });
  }

  void _handleStickerScaleStart(
    ScaleStartDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  ) {
    _gestureStartScale = overlay.transform.scale;
    _gestureStartRotation = overlay.transform.rotationDegrees;
    _gestureStartPosition = overlay.transform.position;
    _gestureStartFocalPoint = details.focalPoint;
  }

  void _handleStickerScaleUpdate(
    ScaleUpdateDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  ) {
    if (previewSize.width == 0 || previewSize.height == 0) return;
    final startFocalPoint = _gestureStartFocalPoint ?? details.focalPoint;
    final normalizedDx =
        (details.focalPoint.dx - startFocalPoint.dx) / previewSize.width;
    final normalizedDy =
        (details.focalPoint.dy - startFocalPoint.dy) / previewSize.height;
    final nextPosition = Offset(
      (_gestureStartPosition.dx + normalizedDx).clamp(0.1, 0.9),
      (_gestureStartPosition.dy + normalizedDy).clamp(0.1, 0.9),
    );
    final nextScale = (_gestureStartScale * details.scale).clamp(0.5, 2.2);
    final nextRotation =
        _gestureStartRotation + (details.rotation * 180 / math.pi);
    final overlays = _session.overlays
        .map(
          (item) => item.id == overlay.id
              ? item.copyWith(
                  transform: overlay.transform.copyWith(
                    position: nextPosition,
                    scale: nextScale,
                    rotationDegrees: nextRotation,
                  ),
                )
              : item,
        )
        .toList(growable: false);
    setState(() {
      _session = _session.copyWith(overlays: overlays);
    });
  }

  Future<void> _probeAndOpen() async {
    final probe = await probeVideoFile(widget.source.filePath);
    if (probe != null && mounted) {
      setState(() => _probeDisplayAspectRatio = probe.displayAspectRatio);
    }
    if (!mounted) return;
    _player.open(Media(widget.source.filePath));
  }

  double _resolvedVideoAspectRatio() {
    final videoParamsAspectRatio = _videoParamsDisplayAspectRatio();
    if (videoParamsAspectRatio != null && videoParamsAspectRatio > 0) {
      return videoParamsAspectRatio;
    }
    if (_probeDisplayAspectRatio != null) {
      return _probeDisplayAspectRatio!;
    }
    final width = _videoWidth;
    final height = _videoHeight;
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
    return 9 / 16;
  }

  bool _hasUsableVideoParams(VideoParams value) {
    final hasDimensions =
        (value.w != null && value.w! > 0 && value.h != null && value.h! > 0) ||
        (value.dw != null &&
            value.dw! > 0 &&
            value.dh != null &&
            value.dh! > 0);
    final hasRotation = value.rotate != null;
    final hasAspect = value.aspect != null && value.aspect! > 0;
    return hasDimensions || hasRotation || hasAspect;
  }

  ui.Size _orientedSize({
    required double width,
    required double height,
    required int rotationDegrees,
  }) {
    final normalizedRotation = ((rotationDegrees % 360) + 360) % 360;
    if (normalizedRotation == 90 || normalizedRotation == 270) {
      return ui.Size(height, width);
    }
    return ui.Size(width, height);
  }

  ui.Size? _preferredDisplaySize() {
    final rotation = _preferredRotationDegrees();
    final w = _videoParams.w;
    final h = _videoParams.h;
    if (w != null && h != null && w > 0 && h > 0) {
      return _orientedSize(
        width: w.toDouble(),
        height: h.toDouble(),
        rotationDegrees: rotation,
      );
    }

    if (_videoWidth != null &&
        _videoHeight != null &&
        _videoWidth! > 0 &&
        _videoHeight! > 0) {
      return ui.Size(_videoWidth!.toDouble(), _videoHeight!.toDouble());
    }

    final dw = _videoParams.dw;
    final dh = _videoParams.dh;
    if (dw != null && dh != null && dw > 0 && dh > 0) {
      return _orientedSize(
        width: dw.toDouble(),
        height: dh.toDouble(),
        rotationDegrees: rotation,
      );
    }

    return null;
  }

  int _preferredRotationDegrees() {
    return _videoParams.rotate ?? 0;
  }

  double? _videoParamsDisplayAspectRatio() {
    final preferredDisplaySize = _preferredDisplaySize();
    if (preferredDisplaySize != null &&
        preferredDisplaySize.width > 0 &&
        preferredDisplaySize.height > 0) {
      return preferredDisplaySize.width / preferredDisplaySize.height;
    }
    return _videoParams.aspect;
  }
}

// ── Minimal Header ──────────────────────────────────────────────────────

class _MinimalHeader extends StatelessWidget {
  const _MinimalHeader({
    required this.palette,
    required this.isExporting,
    required this.onExport,
  });

  final KidPalette palette;
  final bool isExporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FrostedCircleButton(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const Spacer(),
        _FrostedPillButton(
          onTap: isExporting ? null : onExport,
          accentGradient: LinearGradient(
            colors: [
              palette.accent.withValues(alpha: 0.7),
              palette.accentSecondary.withValues(alpha: 0.7),
            ],
          ),
          icon: isExporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.file_upload_outlined,
                  color: Colors.white,
                  size: 20,
                ),
          label: isExporting
              ? context.l10n.editorActionExporting
              : context.l10n.editorActionExport,
        ),
      ],
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _FrostedPillButton extends StatelessWidget {
  const _FrostedPillButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.accentGradient,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Gradient? accentGradient;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              gradient: accentGradient,
              color: accentGradient == null
                  ? Colors.black.withValues(alpha: 0.35)
                  : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Side Toolbar ────────────────────────────────────────────────────────

class _SideToolbar extends StatelessWidget {
  const _SideToolbar({
    required this.palette,
    required this.activeTool,
    required this.onToolTap,
    this.isTablet = false,
    this.isCompact = false,
  });

  final KidPalette palette;
  final EditorTool? activeTool;
  final ValueChanged<EditorTool?> onToolTap;
  final bool isTablet;
  final bool isCompact;

  static const _tools = EditorTool.values;

  @override
  Widget build(BuildContext context) {
    final spacing = isCompact ? 2.0 : (isTablet ? 10.0 : 6.0);
    final toolbar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _tools.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          _SideToolButton(
            palette: palette,
            tool: _tools[i],
            isActive: activeTool == _tools[i],
            onTap: () => onToolTap(_tools[i]),
            isTablet: isTablet,
            isCompact: isCompact,
          ),
        ],
      ],
    );

    if (!isCompact) {
      return Center(child: toolbar);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: toolbar),
          ),
        );
      },
    );
  }
}

class _SideToolButton extends StatelessWidget {
  const _SideToolButton({
    required this.palette,
    required this.tool,
    required this.isActive,
    required this.onTap,
    this.isTablet = false,
    this.isCompact = false,
  });

  final KidPalette palette;
  final EditorTool tool;
  final bool isActive;
  final VoidCallback onTap;
  final bool isTablet;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final btnSize = isCompact ? 44.0 : (isTablet ? 60.0 : 52.0);
    final iconSize = isCompact ? 22.0 : (isTablet ? 28.0 : 24.0);
    final labelSize = isTablet ? 11.0 : 10.0;
    final label = _labelFor(tool, context);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(btnSize / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: btnSize,
                      height: btnSize,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  palette.accent,
                                  palette.accentSecondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive
                            ? null
                            : Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _iconFor(tool),
                        color: Colors.white,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
                    fontSize: labelSize,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    shadows: const [
                      Shadow(blurRadius: 6, color: Colors.black54),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(EditorTool tool) {
    return switch (tool) {
      EditorTool.trim => Icons.content_cut_rounded,
      EditorTool.effects => Icons.auto_awesome_rounded,
      EditorTool.overlays => Icons.face_retouching_natural,
      EditorTool.audio => Icons.music_note_rounded,
      EditorTool.text => Icons.text_fields_rounded,
    };
  }

  static String _labelFor(EditorTool tool, BuildContext context) {
    return switch (tool) {
      EditorTool.trim => context.l10n.editorToolTrim,
      EditorTool.effects => context.l10n.editorToolEffects,
      EditorTool.overlays => context.l10n.editorToolStickers,
      EditorTool.audio => context.l10n.editorToolAudio,
      EditorTool.text => context.l10n.editorToolText,
    };
  }
}

// ── Timeline Bar ────────────────────────────────────────────────────────

class _TimelineBar extends StatelessWidget {
  const _TimelineBar({
    required this.palette,
    required this.thumbPath,
    required this.session,
    required this.isTrimActive,
    required this.previewPosition,
    required this.onTrimChanged,
  });

  final KidPalette palette;
  final String? thumbPath;
  final EditorSession session;
  final bool isTrimActive;
  final Duration previewPosition;
  final ValueChanged<RangeValues> onTrimChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedTrim = normalizeEditorTrim(
      rawVideoDuration: session.videoDuration,
      rawTrimRange: session.trimRange,
    );
    final progressFraction = session.videoDuration.inMilliseconds > 0
        ? (previewPosition.inMilliseconds /
                  session.videoDuration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: isTrimActive ? 96 : 54,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: Column(
              children: [
                if (isTrimActive) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(normalizedTrim.trimRange.start),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.l10n.editorTrimKeepDuration(
                              _formatDuration(
                                normalizedTrim.trimRange.duration,
                              ),
                            ),
                            style: TextStyle(
                              color: palette.accentSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(normalizedTrim.trimRange.end),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        activeTrackColor: palette.accent,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: Colors.white,
                        overlayColor: palette.accent.withValues(alpha: 0.2),
                      ),
                      child: RangeSlider(
                        values: normalizedTrim.sliderValues,
                        min: 0,
                        max: 1,
                        onChanged: onTrimChanged,
                      ),
                    ),
                  ),
                ],
                if (!isTrimActive)
                  Expanded(
                    child: _TimelineStripContent(
                      thumbPath: thumbPath,
                      palette: palette,
                      progressFraction: progressFraction,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _TimelineStripContent extends StatelessWidget {
  const _TimelineStripContent({
    required this.thumbPath,
    required this.palette,
    required this.progressFraction,
  });

  final String? thumbPath;
  final KidPalette palette;
  final double progressFraction;

  @override
  Widget build(BuildContext context) {
    final thumbFile = thumbPath == null || thumbPath!.isEmpty
        ? null
        : File(thumbPath!);
    final hasThumb = thumbFile?.existsSync() == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: List.generate(8, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 7 ? 0 : 3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          height: 36,
                          child: hasThumb
                              ? MediaThumbnailFrame(
                                  file: thumbFile!,
                                  borderRadius: BorderRadius.circular(6),
                                  background: const LinearGradient(
                                    colors: [
                                      Color(0xFF16111D),
                                      Color(0xFF0C0A11),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(2),
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        palette.accent.withValues(alpha: 0.25),
                                        palette.accentSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 8 + (progressFraction * (constraints.maxWidth - 16)),
              top: 4,
              bottom: 4,
              child: Container(
                width: 2.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Active Tool Overlay ─────────────────────────────────────────────────

class _ActiveToolOverlay extends StatelessWidget {
  const _ActiveToolOverlay({
    required this.palette,
    required this.activeTool,
    required this.session,
    required this.onFilterChanged,
    required this.onAdjustmentsChanged,
    required this.onStickerSelected,
    required this.onOpenSelfieStickerCapture,
    required this.userStickers,
    required this.onDeleteUserSticker,
    required this.onMusicSelected,
    required this.onMusicRemoved,
    required this.onMusicVolumeChanged,
    required this.onMusicPreviewToggled,
    required this.previewingTrackId,
    required this.cachedAudioTrackIds,
    required this.downloadingAudioTrackIds,
    required this.selectedOverlayId,
    required this.onAddTextOverlay,
    required this.onTextChanged,
    this.isTablet = false,
  });

  final KidPalette palette;
  final EditorTool activeTool;
  final EditorSession session;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<EditorAdjustments> onAdjustmentsChanged;
  final void Function(String stickerId, String assetPath) onStickerSelected;
  final Future<void> Function() onOpenSelfieStickerCapture;
  final List<EditorStickerAsset> userStickers;
  final Future<void> Function(EditorStickerAsset sticker) onDeleteUserSticker;
  final Future<void> Function(EditorMusicTrackAsset track) onMusicSelected;
  final VoidCallback onMusicRemoved;
  final ValueChanged<double> onMusicVolumeChanged;
  final Future<void> Function(EditorMusicTrackAsset track)
  onMusicPreviewToggled;
  final String? previewingTrackId;
  final Set<String> cachedAudioTrackIds;
  final Set<String> downloadingAudioTrackIds;
  final String? selectedOverlayId;
  final VoidCallback onAddTextOverlay;
  final void Function({
    required String overlayId,
    String? text,
    String? fontFamily,
    Color? color,
    double? textSize,
  })
  onTextChanged;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                activeTool == EditorTool.overlays ||
                    activeTool == EditorTool.audio
                ? (isTablet ? 360 : 310)
                : (isTablet ? 260 : 210),
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildToolContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildToolContent() {
    return switch (activeTool) {
      EditorTool.trim => const SizedBox.shrink(),
      EditorTool.effects => _CompactEffectsTool(
        key: const ValueKey('effects'),
        palette: palette,
        session: session,
        onFilterChanged: onFilterChanged,
        onAdjustmentsChanged: onAdjustmentsChanged,
      ),
      EditorTool.overlays => _CompactOverlayTool(
        key: const ValueKey('overlays'),
        palette: palette,
        session: session,
        onStickerSelected: onStickerSelected,
        onOpenSelfieStickerCapture: onOpenSelfieStickerCapture,
        userStickers: userStickers,
        onDeleteUserSticker: onDeleteUserSticker,
      ),
      EditorTool.audio => _CompactAudioTool(
        key: const ValueKey('audio'),
        palette: palette,
        session: session,
        onMusicSelected: onMusicSelected,
        onMusicRemoved: onMusicRemoved,
        onMusicVolumeChanged: onMusicVolumeChanged,
        onMusicPreviewToggled: onMusicPreviewToggled,
        previewingTrackId: previewingTrackId,
        cachedTrackIds: cachedAudioTrackIds,
        downloadingTrackIds: downloadingAudioTrackIds,
      ),
      EditorTool.text => _CompactTextTool(
        key: const ValueKey('text'),
        palette: palette,
        session: session,
        selectedOverlayId: selectedOverlayId,
        onAddTextOverlay: onAddTextOverlay,
        onTextChanged: onTextChanged,
      ),
    };
  }
}

// ── Compact Effects Tool ────────────────────────────────────────────────

class _CompactEffectsTool extends StatelessWidget {
  const _CompactEffectsTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onFilterChanged,
    required this.onAdjustmentsChanged,
  });

  final KidPalette palette;
  final EditorSession session;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<EditorAdjustments> onAdjustmentsChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final preset = EditorResourceCatalog.filterPresets[index];
                  final selected = session.filterPresetId == preset.id;
                  return GestureDetector(
                    onTap: () => onFilterChanged(preset.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: [
                                  palette.accent,
                                  palette.accentSecondary,
                                ],
                              )
                            : null,
                        color: selected
                            ? null
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _localizedFilterPresetLabel(preset.id, context),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: EditorResourceCatalog.filterPresets.length,
              ),
            ),
            const SizedBox(height: 10),
            _CompactSlider(
              label: context.l10n.editorBrightness,
              value: session.adjustments.brightness,
              min: -1,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(brightness: v),
              ),
            ),
            _CompactSlider(
              label: context.l10n.editorContrast,
              value: session.adjustments.contrast,
              min: 0.5,
              max: 1.8,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(contrast: v),
              ),
            ),
            _CompactSlider(
              label: context.l10n.editorSaturation,
              value: session.adjustments.saturation,
              min: 0,
              max: 2,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(saturation: v),
              ),
            ),
            _CompactSlider(
              label: context.l10n.editorSharpness,
              value: session.adjustments.sharpness,
              min: 0,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(sharpness: v),
              ),
            ),
            _CompactSlider(
              label: context.l10n.editorVignette,
              value: session.adjustments.vignette,
              min: 0,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(vignette: v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactSlider extends StatelessWidget {
  const _CompactSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                thumbColor: Colors.white,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact Overlay (Stickers) Tool ─────────────────────────────────────

class _CompactOverlayTool extends StatefulWidget {
  const _CompactOverlayTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onStickerSelected,
    required this.onOpenSelfieStickerCapture,
    required this.userStickers,
    required this.onDeleteUserSticker,
  });

  final KidPalette palette;
  final EditorSession session;
  final void Function(String stickerId, String assetPath) onStickerSelected;
  final Future<void> Function() onOpenSelfieStickerCapture;
  final List<EditorStickerAsset> userStickers;
  final Future<void> Function(EditorStickerAsset sticker) onDeleteUserSticker;

  @override
  State<_CompactOverlayTool> createState() => _CompactOverlayToolState();
}

class _CompactOverlayToolState extends State<_CompactOverlayTool> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = _StickerCategory.all.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stickerItems = [
      for (final sticker in widget.userStickers)
        _StickerPickerItem(sticker: sticker, isUserSticker: true),
      for (final sticker in EditorResourceCatalog.builtInStickerAssets)
        _StickerPickerItem(sticker: sticker, isUserSticker: false),
    ];
    final categories = _StickerCategory.visibleFor(
      hasUserStickers: widget.userStickers.isNotEmpty,
    );
    final selectedCategory = categories.firstWhere(
      (category) => category.id == _categoryId,
      orElse: () => _StickerCategory.all,
    );
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredStickers = stickerItems
        .where((item) {
          if (!selectedCategory.matches(item)) return false;
          if (normalizedQuery.isEmpty) return true;
          final label = item.sticker.label.toLowerCase();
          final id = item.sticker.id.toLowerCase().replaceAll('_', ' ');
          return label.contains(normalizedQuery) ||
              id.contains(normalizedQuery);
        })
        .toList(growable: false);
    final visibleItems = [
      _StickerPickerEntry.selfie,
      for (final item in filteredStickers) _StickerPickerEntry.sticker(item),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StickerToolHeader(
            controller: _searchController,
            onQueryChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategory.id;
                return _StickerCategoryChip(
                  palette: widget.palette,
                  label: category.localizedLabel(context),
                  isSelected: isSelected,
                  onTap: () => setState(() => _categoryId = category.id),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: visibleItems.length == 1
                ? _StickerEmptyState(query: _query)
                : GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 64,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) {
                      final entry = visibleItems[index];
                      if (entry.isSelfie) {
                        return _StickerTile(
                          palette: widget.palette,
                          onTap: widget.onOpenSelfieStickerCapture,
                          child: Icon(
                            Icons.photo_camera_front_rounded,
                            color: widget.palette.accentSecondary,
                            size: 26,
                          ),
                        );
                      }

                      final item = entry.item!;
                      final sticker = item.sticker;
                      final isBundled = sticker.assetPath.startsWith('assets/');
                      return _StickerTile(
                        palette: widget.palette,
                        onTap: () => widget.onStickerSelected(
                          sticker.id,
                          sticker.assetPath,
                        ),
                        onLongPress: item.isUserSticker
                            ? () => widget.onDeleteUserSticker(sticker)
                            : null,
                        child: isBundled
                            ? Image.asset(
                                sticker.assetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    const _StickerLoadErrorIcon(),
                              )
                            : Image.file(
                                File(sticker.assetPath),
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) =>
                                    const _StickerLoadErrorIcon(),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StickerToolHeader extends StatelessWidget {
  const _StickerToolHeader({
    required this.controller,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.editorSearchStickers,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.55),
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.65),
                    size: 18,
                  ),
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
          ),
        ),
      ),
    );
  }
}

class _StickerCategoryChip extends StatelessWidget {
  const _StickerCategoryChip({
    required this.palette,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final KidPalette palette;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? palette.accentSecondary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isSelected ? 1 : 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({
    required this.palette,
    required this.onTap,
    required this.child,
    this.onLongPress,
  });

  final KidPalette palette;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }
}

class _StickerLoadErrorIcon extends StatelessWidget {
  const _StickerLoadErrorIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white.withValues(alpha: 0.45),
      size: 24,
    );
  }
}

class _StickerEmptyState extends StatelessWidget {
  const _StickerEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        query.trim().isEmpty
            ? context.l10n.editorNoStickersHereYet
            : context.l10n.editorNoMatchingStickers,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StickerPickerItem {
  const _StickerPickerItem({
    required this.sticker,
    required this.isUserSticker,
  });

  final EditorStickerAsset sticker;
  final bool isUserSticker;
}

class _StickerPickerEntry {
  const _StickerPickerEntry._({required this.isSelfie, this.item});

  const _StickerPickerEntry.sticker(_StickerPickerItem item)
    : this._(isSelfie: false, item: item);

  static const selfie = _StickerPickerEntry._(isSelfie: true);

  final bool isSelfie;
  final _StickerPickerItem? item;
}

class _StickerCategory {
  const _StickerCategory({
    required this.id,
    required this.label,
    required this.matches,
  });

  final String id;
  final String label;
  final bool Function(_StickerPickerItem item) matches;

  static const all = _StickerCategory(
    id: 'all',
    label: 'All',
    matches: _matchAll,
  );

  static const _user = _StickerCategory(
    id: 'yours',
    label: 'Yours',
    matches: _matchUser,
  );

  static const _originals = _StickerCategory(
    id: 'originals',
    label: 'Originals',
    matches: _matchOriginal,
  );

  static const _faces = _StickerCategory(
    id: 'faces',
    label: 'Faces',
    matches: _matchFaces,
  );

  static const _hearts = _StickerCategory(
    id: 'hearts',
    label: 'Hearts',
    matches: _matchHearts,
  );

  static const _party = _StickerCategory(
    id: 'party',
    label: 'Party',
    matches: _matchParty,
  );

  static const _animals = _StickerCategory(
    id: 'animals',
    label: 'Animals',
    matches: _matchAnimals,
  );

  static const _food = _StickerCategory(
    id: 'food',
    label: 'Food',
    matches: _matchFood,
  );

  static const _sports = _StickerCategory(
    id: 'sports',
    label: 'Sports',
    matches: _matchSports,
  );

  static const _objects = _StickerCategory(
    id: 'objects',
    label: 'Objects',
    matches: _matchObjects,
  );

  static const _travel = _StickerCategory(
    id: 'travel',
    label: 'Travel',
    matches: _matchTravel,
  );

  static List<_StickerCategory> visibleFor({required bool hasUserStickers}) {
    return [
      all,
      if (hasUserStickers) _user,
      _originals,
      _faces,
      _hearts,
      _party,
      _animals,
      _food,
      _sports,
      _objects,
      _travel,
    ];
  }

  String localizedLabel(BuildContext context) => switch (id) {
    'all' => context.l10n.editorCategoryAll,
    'yours' => context.l10n.editorCategoryYours,
    'originals' => context.l10n.editorCategoryOriginals,
    'faces' => context.l10n.editorCategoryFaces,
    'hearts' => context.l10n.editorCategoryHearts,
    'party' => context.l10n.editorCategoryParty,
    'animals' => context.l10n.editorCategoryAnimals,
    'food' => context.l10n.editorCategoryFood,
    'sports' => context.l10n.editorCategorySports,
    'objects' => context.l10n.editorCategoryObjects,
    'travel' => context.l10n.editorCategoryTravel,
    _ => label,
  };
}

bool _matchAll(_StickerPickerItem item) => true;

bool _matchUser(_StickerPickerItem item) => item.isUserSticker;

bool _matchOriginal(_StickerPickerItem item) {
  return !item.isUserSticker && !item.sticker.id.startsWith('fluent_emoji_');
}

bool _matchFaces(_StickerPickerItem item) {
  final label = item.sticker.label.toLowerCase();
  return label.contains('face') ||
      label.contains('alien') ||
      label.contains('clown') ||
      label.contains('ghost') ||
      label.contains('robot');
}

bool _matchHearts(_StickerPickerItem item) {
  final label = item.sticker.label.toLowerCase();
  return label.contains('heart');
}

bool _matchParty(_StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'party',
    'confetti',
    'balloon',
    'gift',
    'birthday',
    'sparkle',
    'star',
    'rainbow',
    'fire',
    'hundred',
    'collision',
    'dizzy',
    'trophy',
    'medal',
  });
}

bool _matchAnimals(_StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'dog',
    'cat',
    'mouse',
    'hamster',
    'rabbit',
    'fox',
    'bear',
    'panda',
    'koala',
    'tiger',
    'lion',
    'cow',
    'pig',
    'frog',
    'monkey',
    'chicken',
    'penguin',
    'bird',
    'unicorn',
    'butterfly',
    'beetle',
    'turtle',
    'octopus',
    'dolphin',
    'whale',
    'fish',
    'shark',
    'snail',
  });
}

bool _matchFood(_StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'pizza',
    'hamburger',
    'fries',
    'hot dog',
    'taco',
    'burrito',
    'popcorn',
    'doughnut',
    'cookie',
    'candy',
    'lollipop',
    'ice cream',
    'cupcake',
    'watermelon',
    'strawberry',
    'banana',
    'apple',
    'grapes',
    'cherries',
  });
}

bool _matchSports(_StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'soccer',
    'basketball',
    'baseball',
    'softball',
    'tennis',
    'volleyball',
    'disc',
    'kite',
    'yo-yo',
  });
}

bool _matchObjects(_StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'game',
    'joystick',
    'palette',
    'music',
    'microphone',
    'headphone',
    'guitar',
    'drum',
    'trumpet',
    'violin',
    'camera',
    'movie',
    'clapper',
    'television',
    'laptop',
    'bulb',
    'magnet',
    'gem',
    'crown',
    'ring',
    'sunglasses',
    'wand',
  });
}

bool _matchTravel(_StickerPickerItem item) {
  return _labelMatchesAny(item, const {
    'rocket',
    'saucer',
    'airplane',
    'bicycle',
    'skate',
  });
}

bool _labelMatchesAny(_StickerPickerItem item, Set<String> terms) {
  final label = item.sticker.label.toLowerCase();
  return terms.any(label.contains);
}

// ── Compact Audio Tool ──────────────────────────────────────────────────

class _CompactAudioTool extends StatefulWidget {
  const _CompactAudioTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onMusicSelected,
    required this.onMusicRemoved,
    required this.onMusicVolumeChanged,
    required this.onMusicPreviewToggled,
    required this.previewingTrackId,
    required this.cachedTrackIds,
    required this.downloadingTrackIds,
  });

  final KidPalette palette;
  final EditorSession session;
  final Future<void> Function(EditorMusicTrackAsset track) onMusicSelected;
  final VoidCallback onMusicRemoved;
  final ValueChanged<double> onMusicVolumeChanged;
  final Future<void> Function(EditorMusicTrackAsset track)
  onMusicPreviewToggled;
  final String? previewingTrackId;
  final Set<String> cachedTrackIds;
  final Set<String> downloadingTrackIds;

  @override
  State<_CompactAudioTool> createState() => _CompactAudioToolState();
}

class _CompactAudioToolState extends State<_CompactAudioTool> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = _AudioCategory.all.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selection = widget.session.audioSelection;
    final categories = _AudioCategory.visibleFor(
      tracks: EditorResourceCatalog.builtInMusicTracks,
      cachedTrackIds: widget.cachedTrackIds,
    );
    final selectedCategory = categories.firstWhere(
      (category) => category.id == _categoryId,
      orElse: () => _AudioCategory.all,
    );
    final normalizedQuery = _query.trim().toLowerCase();
    final tracks = EditorResourceCatalog.builtInMusicTracks
        .where((track) {
          if (!selectedCategory.matches(track, widget.cachedTrackIds)) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          final searchable = [
            track.label,
            track.creator ?? '',
            track.id.replaceAll('_', ' '),
            ...track.categories,
          ].join(' ').toLowerCase();
          return searchable.contains(normalizedQuery);
        })
        .toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AudioToolHeader(
            controller: _searchController,
            onQueryChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategory.id;
                return _StickerCategoryChip(
                  palette: widget.palette,
                  label: category.localizedLabel(context),
                  isSelected: isSelected,
                  onTap: () => setState(() => _categoryId = category.id),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: tracks.isEmpty
                ? _AudioEmptyState(query: _query)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: tracks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return _AudioTrackRow(
                        palette: widget.palette,
                        track: track,
                        isSelected: selection?.trackId == track.id,
                        isPreviewing: widget.previewingTrackId == track.id,
                        isCached: widget.cachedTrackIds.contains(track.id),
                        isDownloading: widget.downloadingTrackIds.contains(
                          track.id,
                        ),
                        onSelected: () =>
                            unawaited(widget.onMusicSelected(track)),
                        onPreview: () =>
                            unawaited(widget.onMusicPreviewToggled(track)),
                      );
                    },
                  ),
          ),
          if (selection != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      activeTrackColor: widget.palette.accentSecondary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: selection.volume,
                      onChanged: widget.onMusicVolumeChanged,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onMusicRemoved,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.actionRemove,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioToolHeader extends StatelessWidget {
  const _AudioToolHeader({
    required this.controller,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onQueryChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: context.l10n.editorSearchMusic,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.55),
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.65),
                    size: 18,
                  ),
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
          ),
        ),
      ),
    );
  }
}

class _AudioTrackRow extends StatelessWidget {
  const _AudioTrackRow({
    required this.palette,
    required this.track,
    required this.isSelected,
    required this.isPreviewing,
    required this.isCached,
    required this.isDownloading,
    required this.onSelected,
    required this.onPreview,
  });

  final KidPalette palette;
  final EditorMusicTrackAsset track;
  final bool isSelected;
  final bool isPreviewing;
  final bool isCached;
  final bool isDownloading;
  final VoidCallback onSelected;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final creator = track.creator;
    final status = track.isBlossomBacked && !isCached
        ? context.l10n.editorMusicDownload
        : (track.license ?? context.l10n.editorMusicReady);

    return GestureDetector(
      onTap: isDownloading ? null : onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [palette.accent, palette.accentSecondary],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: isDownloading ? null : onPreview,
              child: Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: isSelected ? 0.16 : 0.2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: isDownloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isPreviewing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (creator != null && creator.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      creator,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: 86),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDownloading ? context.l10n.editorMusicLoading : status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _AudioEmptyState extends StatelessWidget {
  const _AudioEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        query.trim().isEmpty
            ? context.l10n.editorNoMusicHereYet
            : context.l10n.editorNoMatchingMusic,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AudioCategory {
  const _AudioCategory({
    required this.id,
    required this.label,
    required this.matches,
  });

  final String id;
  final String label;
  final bool Function(EditorMusicTrackAsset track, Set<String> cachedTrackIds)
  matches;

  static const all = _AudioCategory(
    id: 'all',
    label: 'All',
    matches: _matchAllAudio,
  );

  static const downloaded = _AudioCategory(
    id: 'downloaded',
    label: 'Ready',
    matches: _matchDownloadedAudio,
  );

  static const happy = _AudioCategory(
    id: 'happy',
    label: 'Happy',
    matches: _matchHappyAudio,
  );

  static const energy = _AudioCategory(
    id: 'energy',
    label: 'Energy',
    matches: _matchEnergyAudio,
  );

  static const chill = _AudioCategory(
    id: 'chill',
    label: 'Chill',
    matches: _matchChillAudio,
  );

  static const chiptune = _AudioCategory(
    id: 'chiptune',
    label: 'Chiptune',
    matches: _matchChiptuneAudio,
  );

  static const dramatic = _AudioCategory(
    id: 'dramatic',
    label: 'Dramatic',
    matches: _matchDramaticAudio,
  );

  static const loops = _AudioCategory(
    id: 'loops',
    label: 'Loops',
    matches: _matchLoopsAudio,
  );

  static List<_AudioCategory> visibleFor({
    required List<EditorMusicTrackAsset> tracks,
    required Set<String> cachedTrackIds,
  }) {
    final base = <_AudioCategory>[
      all,
      downloaded,
      happy,
      energy,
      chill,
      chiptune,
      dramatic,
      loops,
    ];
    return base
        .where(
          (category) =>
              category == all ||
              tracks.any((track) => category.matches(track, cachedTrackIds)),
        )
        .toList(growable: false);
  }

  String localizedLabel(BuildContext context) => switch (id) {
    'all' => context.l10n.editorCategoryAll,
    'downloaded' => context.l10n.editorMusicReady,
    'happy' => context.l10n.editorMusicHappy,
    'energy' => context.l10n.editorMusicEnergy,
    'chill' => context.l10n.editorMusicChill,
    'chiptune' => context.l10n.editorMusicChiptune,
    'dramatic' => context.l10n.editorMusicDramatic,
    'loops' => context.l10n.editorMusicLoops,
    _ => label,
  };
}

String _localizedFilterPresetLabel(String presetId, BuildContext context) =>
    switch (presetId) {
      'none' => context.l10n.editorFilterNone,
      'vivid' => context.l10n.editorFilterVivid,
      'matte' => context.l10n.editorFilterMatte,
      'fade' => context.l10n.editorFilterFade,
      'warm' => context.l10n.editorFilterWarm,
      'cool' => context.l10n.editorFilterCool,
      'noir' => context.l10n.editorFilterNoir,
      _ => presetId,
    };

bool _matchAllAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return true;
}

bool _matchDownloadedAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return cachedTrackIds.contains(track.id);
}

bool _matchHappyAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return track.categories.contains('happy');
}

bool _matchEnergyAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return track.categories.contains('energy');
}

bool _matchChillAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return track.categories.contains('chill');
}

bool _matchChiptuneAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return track.categories.contains('chiptune');
}

bool _matchDramaticAudio(
  EditorMusicTrackAsset track,
  Set<String> cachedTrackIds,
) {
  return track.categories.contains('dramatic');
}

bool _matchLoopsAudio(EditorMusicTrackAsset track, Set<String> cachedTrackIds) {
  return track.categories.contains('loops');
}

// ── Compact Text Tool ───────────────────────────────────────────────────

class _CompactTextTool extends StatefulWidget {
  const _CompactTextTool({
    super.key,
    required this.palette,
    required this.session,
    required this.selectedOverlayId,
    required this.onAddTextOverlay,
    required this.onTextChanged,
  });

  final KidPalette palette;
  final EditorSession session;
  final String? selectedOverlayId;
  final VoidCallback onAddTextOverlay;
  final void Function({
    required String overlayId,
    String? text,
    String? fontFamily,
    Color? color,
    double? textSize,
  })
  onTextChanged;

  @override
  State<_CompactTextTool> createState() => _CompactTextToolState();
}

class _CompactTextToolState extends State<_CompactTextTool> {
  final TextEditingController _controller = TextEditingController();
  String? _syncedOverlayId;

  EditorOverlayItem? get _selectedText {
    final id = widget.selectedOverlayId;
    if (id == null) return null;
    return widget.session.overlays
        .where((item) => item.id == id && item.type == EditorOverlayType.text)
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _syncController(_selectedText);
  }

  @override
  void didUpdateWidget(covariant _CompactTextTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_selectedText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncController(EditorOverlayItem? overlay) {
    if (overlay == null) {
      if (_syncedOverlayId != null) {
        _controller.text = '';
        _syncedOverlayId = null;
      }
      return;
    }
    final incoming = overlay.text ?? '';
    if (_syncedOverlayId != overlay.id || _controller.text != incoming) {
      _controller.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
      _syncedOverlayId = overlay.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedText;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: selected == null
                      ? Text(
                          context.l10n.editorTapText,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.editorTypeSomething,
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.08),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) => widget.onTextChanged(
                            overlayId: selected.id,
                            text: value,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                _AddTextButton(
                  palette: widget.palette,
                  onTap: widget.onAddTextOverlay,
                ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final family
                        in _EditorDetailPageState._fontFamilies) ...[
                      GestureDetector(
                        onTap: () => widget.onTextChanged(
                          overlayId: selected.id,
                          fontFamily: family,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected.fontFamily == family
                                ? LinearGradient(
                                    colors: [
                                      widget.palette.accent,
                                      widget.palette.accentSecondary,
                                    ],
                                  )
                                : null,
                            color: selected.fontFamily == family
                                ? null
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Aa',
                            style: TextStyle(
                              fontFamily: family,
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const SizedBox(width: 4),
                    for (final color in _EditorDetailPageState._textColors) ...[
                      GestureDetector(
                        onTap: () => widget.onTextChanged(
                          overlayId: selected.id,
                          color: color,
                        ),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected.textColorValue == color.toARGB32()
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Size',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        activeTrackColor: Colors.white70,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: Colors.white,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: selected.textSize.clamp(24, 96),
                        min: 24,
                        max: 96,
                        onChanged: (value) => widget.onTextChanged(
                          overlayId: selected.id,
                          textSize: value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddTextButton extends StatelessWidget {
  const _AddTextButton({required this.palette, required this.onTap});

  final KidPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.accent, palette.accentSecondary],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              context.l10n.editorAddText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Preview Pane ────────────────────────────────────────────────────────

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({
    required this.palette,
    required this.videoController,
    required this.session,
    required this.videoAspectRatio,
    required this.selectedOverlayId,
    required this.isPlaying,
    required this.onTogglePlayback,
    required this.onOverlaySelected,
    required this.onOverlayScaleStart,
    required this.onOverlayScaleUpdate,
    required this.onOverlayDeleted,
  });

  final KidPalette palette;
  final VideoController videoController;
  final EditorSession session;
  final double videoAspectRatio;
  final String? selectedOverlayId;
  final bool isPlaying;
  final Future<void> Function() onTogglePlayback;
  final ValueChanged<String?> onOverlaySelected;
  final void Function(
    ScaleStartDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  )
  onOverlayScaleStart;
  final void Function(
    ScaleUpdateDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  )
  onOverlayScaleUpdate;
  final ValueChanged<String> onOverlayDeleted;

  @override
  Widget build(BuildContext context) {
    final previewFile = File(session.sourcePath);
    final hasPreviewFile = previewFile.existsSync();
    final textOverlays = session.overlays
        .where((overlay) => overlay.type == EditorOverlayType.text)
        .toList(growable: false);
    final stickerOverlays = session.overlays
        .where((overlay) => overlay.type == EditorOverlayType.sticker)
        .toList(growable: false);
    final previewStyle = buildEditorPreviewStyle(session);

    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, viewport) {
          final previewSize = _fitSizeWithin(
            viewport.biggest,
            videoAspectRatio,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      palette.accent.withValues(alpha: 0.15),
                      Colors.black,
                    ],
                    radius: 1.2,
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: previewSize.width,
                  height: previewSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPreviewFile)
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            previewStyle.colorMatrix,
                          ),
                          child: Video(controller: videoController),
                        )
                      else
                        const ColoredBox(color: Colors.black12),
                      if (previewStyle.tintColor case final tint?)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tint.withValues(
                                alpha: previewStyle.tintOpacity,
                              ),
                            ),
                          ),
                        ),
                      if (previewStyle.vignetteStrength > 0)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(
                                    alpha: 0.28 * previewStyle.vignetteStrength,
                                  ),
                                ],
                                stops: const [0.1, 0.64, 1],
                                radius:
                                    0.96 +
                                    (previewStyle.vignetteStrength * 0.2),
                              ),
                            ),
                          ),
                        ),
                      Stack(
                        children: [
                          for (final overlay in stickerOverlays)
                            _StickerOverlay(
                              overlay: overlay,
                              previewSize: previewSize,
                              selected: overlay.id == selectedOverlayId,
                              onTap: () => onOverlaySelected(overlay.id),
                              onScaleStart: (details) {
                                onOverlaySelected(overlay.id);
                                onOverlayScaleStart(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onScaleUpdate: (details) {
                                onOverlayScaleUpdate(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onDelete: () => onOverlayDeleted(overlay.id),
                            ),
                          for (final overlay in textOverlays)
                            _TextOverlay(
                              overlay: overlay,
                              previewSize: previewSize,
                              selected: overlay.id == selectedOverlayId,
                              onTap: () => onOverlaySelected(overlay.id),
                              onScaleStart: (details) {
                                onOverlaySelected(overlay.id);
                                onOverlayScaleStart(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onScaleUpdate: (details) {
                                onOverlayScaleUpdate(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onDelete: () => onOverlayDeleted(overlay.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => unawaited(onTogglePlayback()),
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Size _fitSizeWithin(Size viewport, double aspectRatio) {
  if (viewport.width <= 0 || viewport.height <= 0 || aspectRatio <= 0) {
    return viewport;
  }
  final viewportAspect = viewport.width / viewport.height;
  if (viewportAspect > aspectRatio) {
    final height = viewport.height;
    return ui.Size(height * aspectRatio, height);
  }
  final width = viewport.width;
  return ui.Size(width, width / aspectRatio);
}

// ── Sticker Overlay ─────────────────────────────────────────────────────

class _StickerOverlay extends StatelessWidget {
  const _StickerOverlay({
    required this.overlay,
    required this.previewSize,
    required this.selected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onDelete,
  });

  final EditorOverlayItem overlay;
  final Size previewSize;
  final bool selected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final VoidCallback onDelete;

  static const _touchPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final transform = overlay.transform;
    final stickerSize = 92 * transform.scale;
    final stickerPath = overlay.stickerAssetPath!;
    final isBundledAsset = stickerPath.startsWith('assets/');
    return Positioned(
      left:
          (transform.position.dx * previewSize.width) -
          (stickerSize / 2) -
          _touchPadding,
      top:
          (transform.position.dy * previewSize.height) -
          (stickerSize / 2) -
          _touchPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: Padding(
          padding: const EdgeInsets.all(_touchPadding),
          child: Transform.rotate(
            angle: transform.rotationDegrees * math.pi / 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: stickerSize,
                  height: stickerSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: selected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: isBundledAsset
                        ? Image.asset(stickerPath, fit: BoxFit.contain)
                        : Image.file(File(stickerPath), fit: BoxFit.contain),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: _OverlayDeleteBadge(onTap: onDelete),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Text Overlay ────────────────────────────────────────────────────────

class _TextOverlay extends StatelessWidget {
  const _TextOverlay({
    required this.overlay,
    required this.previewSize,
    required this.selected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onDelete,
  });

  final EditorOverlayItem overlay;
  final Size previewSize;
  final bool selected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final VoidCallback onDelete;

  static const _touchPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final text = overlay.text;
    if (text == null || text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final transform = overlay.transform;
    return Positioned(
      left: transform.position.dx * previewSize.width,
      top: transform.position.dy * previewSize.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          child: Padding(
            padding: const EdgeInsets.all(_touchPadding),
            child: Transform.rotate(
              angle: transform.rotationDegrees * math.pi / 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: selected
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 2),
                          )
                        : null,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: overlay.fontFamily,
                        fontSize: overlay.textSize * transform.scale,
                        fontWeight: FontWeight.w800,
                        color: overlay.textColorValue == null
                            ? Colors.white
                            : Color(overlay.textColorValue!),
                        shadows: const [
                          Shadow(
                            blurRadius: 12,
                            color: Colors.black54,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: _OverlayDeleteBadge(onTap: onDelete),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overlay Delete Badge ────────────────────────────────────────────────

class _OverlayDeleteBadge extends StatelessWidget {
  const _OverlayDeleteBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
      ),
    );
  }
}

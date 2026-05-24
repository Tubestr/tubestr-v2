import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/di/providers.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/content_scan_summary.dart';
import '../../../domain/models/editor_resources.dart';
import '../../../domain/models/editor_session.dart';
import '../../../l10n/l10n.dart';
import '../../../services/editor/editor_audio_library_service.dart';
import '../../../services/editor/editor_audio_preview_service.dart';
import '../../../services/editor/editor_export_service.dart';
import '../../../services/editor/editor_resource_catalog.dart';
import '../../../services/editor/editor_sticker_library.dart';
import '../../../services/media/video_probe_service.dart';
import '../../../shared_ui/components/kid_scaffold.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../player/presentation/player_page.dart';
import '../domain/editor_source.dart';
import '../domain/editor_trim_utils.dart';
import 'selfie_sticker_capture_page.dart';
import 'widgets/editor_active_tool_overlay.dart';
import 'widgets/editor_drawing_canvas.dart';
import 'widgets/editor_minimal_header.dart';
import 'widgets/editor_preview_pane.dart';
import 'widgets/editor_side_toolbar.dart';
import 'widgets/editor_text_constants.dart';
import 'widgets/editor_timeline_bar.dart';
import 'widgets/tools/editor_drawing_tool.dart';

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
  EditorDrawTool _activeDrawTool = EditorDrawTool.pencil;
  int _drawColorValue = const Color(0xFFFFFFFF).toARGB32();
  double _drawWidth = 6;
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
                    child: PreviewPane(
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
                      drawingCanvas: _activeTool == EditorTool.draw
                          ? EditorDrawingCanvas(
                              strokes: _session.strokes,
                              activeTool: _activeDrawTool,
                              colorValue: _drawColorValue,
                              width: _drawWidth,
                              onStrokeCompleted: _addStroke,
                            )
                          : null,
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
                      child: TimelineBar(
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
                  child: SideToolbar(
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
                            child: ActiveToolOverlay(
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
                              onPlaybackSpeedChanged: _updatePlaybackSpeed,
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
                              activeDrawTool: _activeDrawTool,
                              drawColorValue: _drawColorValue,
                              drawWidth: _drawWidth,
                              onDrawToolChanged: _setDrawTool,
                              onDrawColorChanged: _setDrawColor,
                              onDrawWidthChanged: _setDrawWidth,
                              onDrawUndo: _undoStroke,
                              onDrawClear: _clearStrokes,
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
                  child: MinimalHeader(
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

  Future<void> _applyPlaybackSpeed() async {
    await _player.setRate(_session.playbackSpeed);
  }

  void _updatePlaybackSpeed(double speed) {
    final clampedSpeed = EditorSession.clampPlaybackSpeed(speed);
    setState(() {
      _session = _session.copyWith(playbackSpeed: clampedSpeed);
    });
    unawaited(_applyPlaybackSpeed());
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

  void _addStroke(EditorStroke stroke) {
    setState(() {
      _session = _session.copyWith(strokes: [..._session.strokes, stroke]);
    });
  }

  void _undoStroke() {
    if (_session.strokes.isEmpty) return;
    setState(() {
      _session = _session.copyWith(
        strokes: _session.strokes.take(_session.strokes.length - 1).toList(),
      );
    });
  }

  void _clearStrokes() {
    if (_session.strokes.isEmpty) return;
    setState(() {
      _session = _session.copyWith(strokes: const <EditorStroke>[]);
    });
  }

  void _setDrawTool(EditorDrawTool tool) {
    setState(() => _activeDrawTool = tool);
  }

  void _setDrawColor(int colorValue) {
    setState(() => _drawColorValue = colorValue);
  }

  void _setDrawWidth(double width) {
    setState(() => _drawWidth = width.clamp(2, 24));
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
        backgroundColor: ref.read(activePaletteProvider).danger,
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
          backgroundColor: ref.read(activePaletteProvider).danger,
        ),
      );
    } finally {
      if (mounted) {
        await _player.open(Media(widget.source.filePath), play: false);
        await _applyPlaybackSpeed();
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.mediaSurfaceStrong,
                borderRadius: AppRadii.cardAll,
                border: Border.all(color: palette.mediaBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
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
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            context.l10n.editorRemixSavedTitle,
                            style: TextStyle(
                              color: palette.mediaInk,
                              fontSize: AppTextSize.title,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      result.warning == null
                          ? context.l10n.editorExportSaved
                          : context.l10n.editorExportWarning(result.warning!),
                      style: TextStyle(color: palette.mediaMutedInk),
                    ),
                    if (scan != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: palette.mediaSurfaceSubtle,
                          borderRadius: AppRadii.lgAll,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              scan.needsReview
                                  ? Icons.shield_outlined
                                  : Icons.verified_rounded,
                              color: scan.needsReview
                                  ? palette.warning
                                  : palette.success,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                scan.summary,
                                style: TextStyle(color: palette.mediaMutedInk),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
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
      fontFamily: editorTextToolFontFamilies.first,
      textColorValue: editorTextToolColors.first.toARGB32(),
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
    await _player.open(Media(widget.source.filePath));
    await _applyPlaybackSpeed();
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

@visibleForTesting
Widget buildEditorDetailPageSideToolbarForTest({
  required KidPalette palette,
  required EditorTool? activeTool,
  required ValueChanged<EditorTool?> onToolTap,
  bool isTablet = false,
  bool isCompact = false,
}) {
  return SideToolbar(
    palette: palette,
    activeTool: activeTool,
    onToolTap: onToolTap,
    isTablet: isTablet,
    isCompact: isCompact,
  );
}

@visibleForTesting
Widget buildEditorDetailPageTimelineBarForTest({
  required KidPalette palette,
  required String? thumbPath,
  required EditorSession session,
  required bool isTrimActive,
  required Duration previewPosition,
  required ValueChanged<RangeValues> onTrimChanged,
}) {
  return TimelineBar(
    palette: palette,
    thumbPath: thumbPath,
    session: session,
    isTrimActive: isTrimActive,
    previewPosition: previewPosition,
    onTrimChanged: onTrimChanged,
  );
}

@visibleForTesting
Widget buildEditorDetailPageActiveToolOverlayForTest({
  required KidPalette palette,
  required EditorTool activeTool,
  required EditorSession session,
  required ValueChanged<String> onFilterChanged,
  required ValueChanged<EditorAdjustments> onAdjustmentsChanged,
  ValueChanged<double>? onPlaybackSpeedChanged,
  required void Function(String stickerId, String assetPath) onStickerSelected,
  required Future<void> Function() onOpenSelfieStickerCapture,
  required List<EditorStickerAsset> userStickers,
  required Future<void> Function(EditorStickerAsset sticker)
  onDeleteUserSticker,
  required Future<void> Function(EditorMusicTrackAsset track) onMusicSelected,
  required VoidCallback onMusicRemoved,
  required ValueChanged<double> onMusicVolumeChanged,
  required Future<void> Function(EditorMusicTrackAsset track)
  onMusicPreviewToggled,
  required String? previewingTrackId,
  required Set<String> cachedAudioTrackIds,
  required Set<String> downloadingAudioTrackIds,
  required String? selectedOverlayId,
  required VoidCallback onAddTextOverlay,
  required void Function({
    required String overlayId,
    String? text,
    String? fontFamily,
    Color? color,
    double? textSize,
  })
  onTextChanged,
  EditorDrawTool activeDrawTool = EditorDrawTool.pencil,
  int drawColorValue = 0xFFFFFFFF,
  double drawWidth = 6,
  ValueChanged<EditorDrawTool>? onDrawToolChanged,
  ValueChanged<int>? onDrawColorChanged,
  ValueChanged<double>? onDrawWidthChanged,
  VoidCallback? onDrawUndo,
  VoidCallback? onDrawClear,
  bool isTablet = false,
}) {
  return ActiveToolOverlay(
    palette: palette,
    activeTool: activeTool,
    session: session,
    onFilterChanged: onFilterChanged,
    onAdjustmentsChanged: onAdjustmentsChanged,
    onPlaybackSpeedChanged: onPlaybackSpeedChanged ?? (_) {},
    onStickerSelected: onStickerSelected,
    onOpenSelfieStickerCapture: onOpenSelfieStickerCapture,
    userStickers: userStickers,
    onDeleteUserSticker: onDeleteUserSticker,
    onMusicSelected: onMusicSelected,
    onMusicRemoved: onMusicRemoved,
    onMusicVolumeChanged: onMusicVolumeChanged,
    onMusicPreviewToggled: onMusicPreviewToggled,
    previewingTrackId: previewingTrackId,
    cachedAudioTrackIds: cachedAudioTrackIds,
    downloadingAudioTrackIds: downloadingAudioTrackIds,
    selectedOverlayId: selectedOverlayId,
    onAddTextOverlay: onAddTextOverlay,
    onTextChanged: onTextChanged,
    activeDrawTool: activeDrawTool,
    drawColorValue: drawColorValue,
    drawWidth: drawWidth,
    onDrawToolChanged: onDrawToolChanged ?? (_) {},
    onDrawColorChanged: onDrawColorChanged ?? (_) {},
    onDrawWidthChanged: onDrawWidthChanged ?? (_) {},
    onDrawUndo: onDrawUndo ?? () {},
    onDrawClear: onDrawClear ?? () {},
    isTablet: isTablet,
  );
}

@visibleForTesting
Widget buildEditorDrawingToolForTest({
  required KidPalette palette,
  required EditorDrawTool activeDrawTool,
  required int drawColorValue,
  required double drawWidth,
  required bool canUndo,
  required bool canClear,
  required ValueChanged<EditorDrawTool> onDrawToolChanged,
  required ValueChanged<int> onDrawColorChanged,
  required ValueChanged<double> onDrawWidthChanged,
  required VoidCallback onDrawUndo,
  required VoidCallback onDrawClear,
}) {
  return CompactDrawingTool(
    palette: palette,
    activeTool: activeDrawTool,
    colorValue: drawColorValue,
    width: drawWidth,
    canUndo: canUndo,
    canClear: canClear,
    onToolChanged: onDrawToolChanged,
    onColorChanged: onDrawColorChanged,
    onWidthChanged: onDrawWidthChanged,
    onUndo: onDrawUndo,
    onClear: onDrawClear,
  );
}

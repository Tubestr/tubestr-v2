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
import '../../../domain/models/content_scan_summary.dart';
import '../../../domain/models/editor_resources.dart';
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

class EditorDetailPage extends ConsumerStatefulWidget {
  const EditorDetailPage({super.key, required this.video});

  final LocalVideo video;

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
      milliseconds: (widget.video.durationSeconds * 1000).round(),
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
      videoId: widget.video.id,
      sourcePath: widget.video.filePath,
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
    final palette = ref.watch(activeThemeProvider).palette;
    final isTrimActive = _activeTool == EditorTool.trim;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = KidLayoutSpec.fromWidth(constraints.maxWidth);
            final edgeInset = layout.isTablet ? 24.0 : 12.0;
            final sidebarWidth = layout.isTablet ? 72.0 : 64.0;
            final sidebarRight = layout.isTablet ? 20.0 : 12.0;
            final overlayMaxWidth = layout.isTablet ? 680.0 : double.infinity;
            final timelineMaxWidth = layout.isTablet ? 800.0 : double.infinity;
            final overlayBottom = isTrimActive ? 104.0 : 62.0;

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
                      onStickerScaleStart: _handleStickerScaleStart,
                      onStickerScaleUpdate: (details, size, overlay) {
                        _handleStickerScaleUpdate(details, size, overlay);
                      },
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
                        thumbPath: widget.video.thumbPath,
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
                  top: 0,
                  bottom: 0,
                  child: _SideToolbar(
                    palette: palette,
                    activeTool: _activeTool,
                    onToolTap: _setActiveTool,
                    isTablet: layout.isTablet,
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
                              onStickerRemoved: _removeSticker,
                              onOpenSelfieStickerCapture:
                                  _openSelfieStickerCapture,
                              userStickers: _userStickers,
                              onDeleteUserSticker: _deleteUserSticker,
                              onMusicSelected: _selectMusicTrack,
                              onMusicRemoved: _removeMusicTrack,
                              onMusicVolumeChanged: _updateMusicVolume,
                              onMusicPreviewToggled: _toggleMusicPreview,
                              previewingTrackId: _previewingTrackId,
                              onTextChanged: _updateTextOverlay,
                              onTextRemoved: _removeTextOverlay,
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
                  right: sidebarRight + sidebarWidth,
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
      transform: const StickerTransform(),
    );
    final overlays = [..._session.overlays, sticker];
    setState(() {
      _selectedOverlayId = sticker.id;
      _session = _session.copyWith(overlays: overlays);
    });
  }

  void _removeSticker() {
    final selectedOverlayId = _selectedOverlayId;
    setState(() {
      final nextOverlays = selectedOverlayId == null
          ? _session.overlays
          : _session.overlays
                .where((overlay) => overlay.id != selectedOverlayId)
                .toList(growable: false);
      _selectedOverlayId = null;
      _session = _session.copyWith(overlays: nextOverlays);
    });
  }

  void _selectMusicTrack(String trackId, String assetPath) {
    setState(() {
      _session = _session.copyWith(
        audioSelection: EditorAudioSelection(
          trackId: trackId,
          assetPath: assetPath,
        ),
      );
    });
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

  Future<void> _toggleMusicPreview(String trackId, String assetPath) async {
    final audioSelection = _session.audioSelection;
    final volume = audioSelection?.trackId == trackId
        ? audioSelection!.volume
        : 0.75;
    final isPlaying = await _audioPreviewService.togglePreview(
      assetPath: assetPath,
      volume: volume,
    );
    if (!mounted) return;
    setState(() {
      _previewingTrackId = isPlaying ? trackId : null;
    });
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
            profileId: widget.video.profileId,
            title: '${widget.video.title} Remix',
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
        await _player.open(Media(widget.video.filePath), play: false);
        await _seekPreviewToTrimStart();
      }
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _loadUserStickers() async {
    final stickers = await _stickerLibrary.listUserStickers(
      profileId: widget.video.profileId,
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
          profileId: widget.video.profileId,
          palette: ref.read(activeThemeProvider).palette,
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
      profileId: widget.video.profileId,
      stickerPath: sticker.assetPath,
    );
    if (!mounted) return;
    final currentStickerPath = _session.overlays
        .where((overlay) => overlay.type == EditorOverlayType.sticker)
        .map((overlay) => overlay.stickerAssetPath)
        .firstOrNull;
    if (currentStickerPath == sticker.assetPath) {
      _removeSticker();
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
        final palette = ref.read(activeThemeProvider).palette;
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
                        const Expanded(
                          child: Text(
                            'Remix saved',
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
                          ? 'Your remix is in the library and ready for the next step.'
                          : '${result.warning} The remix is still saved and ready to keep going.',
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
                          label: const Text('Watch'),
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
                                ? 'Review first'
                                : 'Share',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Keep editing later'),
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
    try {
      final result = await ref
          .read(videoShareCoordinatorProvider)
          .shareLocalVideoToEligibleGroups(
            identity: identity,
            videoId: video.id,
            profileId: profile.id,
            childDisplayName: profile.name,
          );
      if (!mounted) {
        return;
      }
      final shared = result.sharedGroupCount;
      final queued = result.queuedGroupCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            queued == 0
                ? 'Shared with $shared family space${shared == 1 ? '' : 's'}'
                : 'Shared to $shared family space${shared == 1 ? '' : 's'}, queued $queued more',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_shareErrorMessage(error))));
    }
  }

  String _exportErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('ffmpeg') || message.contains('export')) {
      return 'We couldn\'t finish saving that remix yet. Try again in a moment.';
    }
    return 'We couldn\'t save that remix yet. Your edit choices are still here.';
  }

  String _shareErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('approval')) {
      return 'This remix still needs a parent review before it can be shared.';
    }
    if (message.contains('group') || message.contains('family')) {
      return 'Connect with a family space first, then try sharing this remix again.';
    }
    return 'We couldn\'t share that remix yet. It\'s still saved safely in your library.';
  }

  void _updateTextOverlay({
    required String text,
    required String fontFamily,
    required Color color,
    required double textSize,
    required EditorTextPosition position,
  }) {
    final existingIndex = _session.overlays.indexWhere(
      (overlay) => overlay.type == EditorOverlayType.text,
    );
    final overlay = EditorOverlayItem(
      id: 'text:primary',
      type: EditorOverlayType.text,
      text: text,
      fontFamily: fontFamily,
      textColorValue: color.toARGB32(),
      textSize: textSize,
      textPosition: position,
    );
    final overlays = [..._session.overlays];
    if (text.trim().isEmpty) {
      overlays.removeWhere((item) => item.type == EditorOverlayType.text);
    } else if (existingIndex == -1) {
      overlays.add(overlay);
    } else {
      overlays[existingIndex] = overlay;
    }
    setState(() {
      _session = _session.copyWith(overlays: overlays);
    });
  }

  void _removeTextOverlay() {
    setState(() {
      _session = _session.copyWith(
        overlays: _session.overlays
            .where((overlay) => overlay.type != EditorOverlayType.text)
            .toList(growable: false),
      );
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
    final probe = await probeVideoFile(widget.video.filePath);
    if (probe != null && mounted) {
      setState(() => _probeDisplayAspectRatio = probe.displayAspectRatio);
    }
    if (!mounted) return;
    _player.open(Media(widget.video.filePath));
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
          label: isExporting ? 'Exporting' : 'Export',
        ),
      ],
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({
    required this.child,
    this.onTap,
    this.accentGradient,
  });

  final Widget child;
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: accentGradient,
              color: accentGradient == null
                  ? Colors.black.withValues(alpha: 0.35)
                  : null,
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
  });

  final KidPalette palette;
  final EditorTool? activeTool;
  final ValueChanged<EditorTool?> onToolTap;
  final bool isTablet;

  static const _tools = EditorTool.values;

  @override
  Widget build(BuildContext context) {
    final spacing = isTablet ? 10.0 : 6.0;
    return Center(
      child: Column(
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
            ),
          ],
        ],
      ),
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
  });

  final KidPalette palette;
  final EditorTool tool;
  final bool isActive;
  final VoidCallback onTap;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final btnSize = isTablet ? 60.0 : 52.0;
    final iconSize = isTablet ? 28.0 : 24.0;
    final labelSize = isTablet ? 11.0 : 10.0;

    return GestureDetector(
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
                            colors: [palette.accent, palette.accentSecondary],
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
          const SizedBox(height: 5),
          Text(
            _labelFor(tool),
            style: TextStyle(
              color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
              fontSize: labelSize,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
            ),
          ),
        ],
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

  static String _labelFor(EditorTool tool) {
    return switch (tool) {
      EditorTool.trim => 'Trim',
      EditorTool.effects => 'Effects',
      EditorTool.overlays => 'Stickers',
      EditorTool.audio => 'Audio',
      EditorTool.text => 'Text',
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
                            'Keep: ${_formatDuration(normalizedTrim.trimRange.duration)}',
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
    required this.onStickerRemoved,
    required this.onOpenSelfieStickerCapture,
    required this.userStickers,
    required this.onDeleteUserSticker,
    required this.onMusicSelected,
    required this.onMusicRemoved,
    required this.onMusicVolumeChanged,
    required this.onMusicPreviewToggled,
    required this.previewingTrackId,
    required this.onTextChanged,
    required this.onTextRemoved,
    this.isTablet = false,
  });

  final KidPalette palette;
  final EditorTool activeTool;
  final EditorSession session;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<EditorAdjustments> onAdjustmentsChanged;
  final void Function(String stickerId, String assetPath) onStickerSelected;
  final VoidCallback onStickerRemoved;
  final Future<void> Function() onOpenSelfieStickerCapture;
  final List<EditorStickerAsset> userStickers;
  final Future<void> Function(EditorStickerAsset sticker) onDeleteUserSticker;
  final void Function(String trackId, String assetPath) onMusicSelected;
  final VoidCallback onMusicRemoved;
  final ValueChanged<double> onMusicVolumeChanged;
  final void Function(String trackId, String assetPath) onMusicPreviewToggled;
  final String? previewingTrackId;
  final void Function({
    required String text,
    required String fontFamily,
    required Color color,
    required double textSize,
    required EditorTextPosition position,
  })
  onTextChanged;
  final VoidCallback onTextRemoved;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(maxHeight: isTablet ? 260 : 210),
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
        onStickerRemoved: onStickerRemoved,
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
      ),
      EditorTool.text => _CompactTextTool(
        key: const ValueKey('text'),
        palette: palette,
        session: session,
        onTextChanged: onTextChanged,
        onTextRemoved: onTextRemoved,
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
                        preset.label,
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
              label: 'Brightness',
              value: session.adjustments.brightness,
              min: -1,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(brightness: v),
              ),
            ),
            _CompactSlider(
              label: 'Contrast',
              value: session.adjustments.contrast,
              min: 0.5,
              max: 1.8,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(contrast: v),
              ),
            ),
            _CompactSlider(
              label: 'Saturation',
              value: session.adjustments.saturation,
              min: 0,
              max: 2,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(saturation: v),
              ),
            ),
            _CompactSlider(
              label: 'Sharpness',
              value: session.adjustments.sharpness,
              min: 0,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(sharpness: v),
              ),
            ),
            _CompactSlider(
              label: 'Vignette',
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

class _CompactOverlayTool extends StatelessWidget {
  const _CompactOverlayTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onStickerSelected,
    required this.onStickerRemoved,
    required this.onOpenSelfieStickerCapture,
    required this.userStickers,
    required this.onDeleteUserSticker,
  });

  final KidPalette palette;
  final EditorSession session;
  final void Function(String stickerId, String assetPath) onStickerSelected;
  final VoidCallback onStickerRemoved;
  final Future<void> Function() onOpenSelfieStickerCapture;
  final List<EditorStickerAsset> userStickers;
  final Future<void> Function(EditorStickerAsset sticker) onDeleteUserSticker;

  @override
  Widget build(BuildContext context) {
    final hasSticker = session.overlays.any(
      (overlay) => overlay.type == EditorOverlayType.sticker,
    );
    final allStickers = [
      ...userStickers,
      ...EditorResourceCatalog.builtInStickerAssets,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasSticker)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onStickerRemoved,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 1 + allStickers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: onOpenSelfieStickerCapture,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: palette.accent.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.photo_camera_front_rounded,
                        color: palette.accentSecondary,
                        size: 26,
                      ),
                    ),
                  );
                }
                final stickerIndex = index - 1;
                final sticker = allStickers[stickerIndex];
                final isUserSticker = stickerIndex < userStickers.length;
                final isBundled = sticker.assetPath.startsWith('assets/');

                return GestureDetector(
                  onTap: () => onStickerSelected(sticker.id, sticker.assetPath),
                  onLongPress: isUserSticker
                      ? () => onDeleteUserSticker(sticker)
                      : null,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: isBundled
                        ? Image.asset(sticker.assetPath, fit: BoxFit.contain)
                        : Image.file(
                            File(sticker.assetPath),
                            fit: BoxFit.contain,
                          ),
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

// ── Compact Audio Tool ──────────────────────────────────────────────────

class _CompactAudioTool extends StatelessWidget {
  const _CompactAudioTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onMusicSelected,
    required this.onMusicRemoved,
    required this.onMusicVolumeChanged,
    required this.onMusicPreviewToggled,
    required this.previewingTrackId,
  });

  final KidPalette palette;
  final EditorSession session;
  final void Function(String trackId, String assetPath) onMusicSelected;
  final VoidCallback onMusicRemoved;
  final ValueChanged<double> onMusicVolumeChanged;
  final void Function(String trackId, String assetPath) onMusicPreviewToggled;
  final String? previewingTrackId;

  @override
  Widget build(BuildContext context) {
    final selection = session.audioSelection;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: EditorResourceCatalog.builtInMusicTracks.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final track = EditorResourceCatalog.builtInMusicTracks[index];
                  final isSelected = selection?.trackId == track.id;
                  final isPreviewing = previewingTrackId == track.id;

                  return GestureDetector(
                    onTap: () => onMusicSelected(track.id, track.assetPath),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  palette.accent,
                                  palette.accentSecondary,
                                ],
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => onMusicPreviewToggled(
                              track.id,
                              track.assetPath,
                            ),
                            child: Icon(
                              isPreviewing
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            track.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ),
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
                        activeTrackColor: palette.accentSecondary,
                        inactiveTrackColor: Colors.white.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: Colors.white,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                      ),
                      child: Slider(
                        value: selection.volume,
                        onChanged: onMusicVolumeChanged,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onMusicRemoved,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Remove',
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
      ),
    );
  }
}

// ── Compact Text Tool ───────────────────────────────────────────────────

class _CompactTextTool extends StatefulWidget {
  const _CompactTextTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onTextChanged,
    required this.onTextRemoved,
  });

  final KidPalette palette;
  final EditorSession session;
  final void Function({
    required String text,
    required String fontFamily,
    required Color color,
    required double textSize,
    required EditorTextPosition position,
  })
  onTextChanged;
  final VoidCallback onTextRemoved;

  @override
  State<_CompactTextTool> createState() => _CompactTextToolState();
}

class _CompactTextToolState extends State<_CompactTextTool> {
  late final TextEditingController _controller;
  late String _fontFamily;
  late Color _color;
  late double _textSize;
  late EditorTextPosition _position;

  @override
  void initState() {
    super.initState();
    final overlay = widget.session.overlays
        .where((item) => item.type == EditorOverlayType.text)
        .firstOrNull;
    _controller = TextEditingController(text: overlay?.text ?? '');
    _fontFamily =
        overlay?.fontFamily ?? _EditorDetailPageState._fontFamilies.first;
    _color = overlay?.textColorValue == null
        ? _EditorDetailPageState._textColors.first
        : Color(overlay!.textColorValue!);
    _textSize = overlay?.textSize ?? 44;
    _position = overlay?.textPosition ?? EditorTextPosition.center;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _CompactTextTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    final overlay = widget.session.overlays
        .where((item) => item.type == EditorOverlayType.text)
        .firstOrNull;
    if (overlay != null && _controller.text != overlay.text) {
      _controller.text = overlay.text ?? '';
    }
  }

  void _emit() {
    widget.onTextChanged(
      text: _controller.text,
      fontFamily: _fontFamily,
      color: _color,
      textSize: _textSize,
      position: _position,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

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
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type something...',
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
                    onChanged: (_) => _emit(),
                  ),
                ),
                if (hasText) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _controller.clear();
                      widget.onTextRemoved();
                      setState(() {});
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final family
                      in _EditorDetailPageState._fontFamilies) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => _fontFamily = family);
                        _emit();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: _fontFamily == family
                              ? LinearGradient(
                                  colors: [
                                    widget.palette.accent,
                                    widget.palette.accentSecondary,
                                  ],
                                )
                              : null,
                          color: _fontFamily == family
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
                      onTap: () {
                        setState(() => _color = color);
                        _emit();
                      },
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _color == color
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
                for (final pos in EditorTextPosition.values) ...[
                  GestureDetector(
                    onTap: () {
                      setState(() => _position = pos);
                      _emit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _position == pos
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pos.name[0].toUpperCase() + pos.name.substring(1),
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: _position == pos ? 1.0 : 0.6,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Spacer(),
                const Text(
                  'Size',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                SizedBox(
                  width: 80,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      activeTrackColor: Colors.white70,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: _textSize,
                      min: 24,
                      max: 96,
                      onChanged: (value) {
                        setState(() => _textSize = value);
                        _emit();
                      },
                    ),
                  ),
                ),
              ],
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
    required this.onStickerScaleStart,
    required this.onStickerScaleUpdate,
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
  onStickerScaleStart;
  final void Function(
    ScaleUpdateDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  )
  onStickerScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final previewFile = File(session.sourcePath);
    final hasPreviewFile = previewFile.existsSync();
    final textOverlay = session.overlays
        .where((overlay) => overlay.type == EditorOverlayType.text)
        .firstOrNull;
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
                                onStickerScaleStart(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onScaleUpdate: (details) {
                                onStickerScaleUpdate(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                            ),
                          if (textOverlay case final overlay?)
                            _TextOverlay(
                              overlay: overlay,
                              selected: overlay.id == selectedOverlayId,
                              onTap: () => onOverlaySelected(overlay.id),
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
  });

  final EditorOverlayItem overlay;
  final Size previewSize;
  final bool selected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;

  @override
  Widget build(BuildContext context) {
    final transform = overlay.transform;
    final stickerSize = 92 * transform.scale;
    final stickerPath = overlay.stickerAssetPath!;
    final isBundledAsset = stickerPath.startsWith('assets/');
    return Positioned(
      left: (transform.position.dx * previewSize.width) - (stickerSize / 2),
      top: (transform.position.dy * previewSize.height) - (stickerSize / 2),
      child: GestureDetector(
        onTap: onTap,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: Transform.rotate(
          angle: transform.rotationDegrees * math.pi / 180,
          child: Container(
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
        ),
      ),
    );
  }
}

// ── Text Overlay ────────────────────────────────────────────────────────

class _TextOverlay extends StatelessWidget {
  const _TextOverlay({
    required this.overlay,
    required this.selected,
    required this.onTap,
  });

  final EditorOverlayItem overlay;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = overlay.text;
    if (text == null || text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final alignment = switch (overlay.textPosition) {
      EditorTextPosition.top => Alignment.topCenter,
      EditorTextPosition.center => Alignment.center,
      EditorTextPosition.bottom => Alignment.bottomCenter,
    };
    return Align(
      alignment: alignment,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              fontSize: overlay.textSize,
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
      ),
    );
  }
}

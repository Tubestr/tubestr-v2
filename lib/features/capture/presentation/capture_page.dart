import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../services/media/video_probe_service.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/ar_face_result.dart';
import '../../../domain/models/content_scan_summary.dart';
import '../../../services/editor/ar_face_detection_service.dart';
import '../../../services/editor/ar_face_track_service.dart';
import '../../../services/editor/ar_filter_catalog.dart';
import '../../../services/editor/ar_filter_library_service.dart';
import '../../../services/editor/ar_filter_renderer.dart';
import '../../../shared_ui/components/fill_camera_preview.dart';
import '../../../shared_ui/components/ar_filter_overlay_painter.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../editor/presentation/editor_detail_page.dart';
import '../../player/presentation/player_page.dart';
import '../../../l10n/l10n.dart';

/// Capture tab content — full-screen camera with floating controls.
class CaptureContent extends ConsumerStatefulWidget {
  const CaptureContent({super.key});

  @override
  ConsumerState<CaptureContent> createState() => _CaptureContentState();
}

class _CaptureContentState extends ConsumerState<CaptureContent>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isRecording = false;
  bool _isSaving = false;
  bool _showSavedBanner = false;
  bool _isRunningQuickShare = false;
  String? _errorMessage;
  String? _noticeMessage;
  _CaptureWorkflowState? _workflowState;
  LocalVideo? _lastSavedVideo;
  final Uuid _uuid = const Uuid();
  final ArFilterRenderer _arFilterRenderer = const ArFilterRenderer();
  ArFilterLibraryService get _arFilterLibraryService =>
      ref.read(arFilterLibraryServiceProvider);

  ArFaceDetectionService? _arService;
  String? _activeArFilterId;
  ArFilterAsset? _activeArFilterAsset;
  final ValueNotifier<List<ArFaceResult>> _arFacesNotifier =
      ValueNotifier<List<ArFaceResult>>(const <ArFaceResult>[]);
  final _LiveArFaceSmoother _arFaceSmoother = _LiveArFaceSmoother();
  bool _isArStreaming = false;
  bool _isArFrameDetectionInFlight = false;
  int _arStreamGeneration = 0;
  int _recordingArFrameLogCount = 0;
  int _arCameraFrameCount = 0;
  int _arDetectionCompletedCount = 0;
  int _arDetectionDroppedFrameCount = 0;
  int _lastArPerfLogMs = 0;
  Timer? _arStreamRetryTimer;
  final ValueNotifier<ui.Image?> _recordingPreviewFrameNotifier =
      ValueNotifier<ui.Image?>(null);
  bool _isBuildingRecordingPreviewFrame = false;
  int _lastRecordingPreviewFrameMs = 0;
  bool _cameraPausedForRoute = false;
  bool _isArFilterPickerOpen = false;
  DateTime? _recordingStartedAt;
  Timer? _arTrackSampleTimer;
  ArFaceResult? _latestTrackedArFace;
  final List<ArFaceTrackSample> _arTrackSamples = <ArFaceTrackSample>[];
  Set<String> _cachedArFilterIds = const {};
  final Set<String> _downloadingArFilterIds = {};

  // Recording timer
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Zoom
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  double? _recordingPreviewAspectRatio;
  bool _cameraInitStarted = false;
  bool _cameraDisposeStarted = false;
  bool _recordsAudio = true;
  bool get _shouldShowRecordingFramePreview => true;

  static const Duration _cameraOpenTimeout = Duration(seconds: 12);
  static const Duration _cameraDisposeTimeout = Duration(seconds: 2);
  static const Duration _arTrackSampleInterval = Duration(milliseconds: 67);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshArFilterLibraryState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _stopArTrackSampler(recordFinalSample: false);
    _arStreamRetryTimer?.cancel();
    _arStreamGeneration++;
    _recordingPreviewFrameNotifier.value?.dispose();
    _recordingPreviewFrameNotifier.dispose();
    _arFacesNotifier.dispose();
    _activeArFilterAsset?.dispose();
    unawaited(_arService?.dispose());
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActiveTab = ref.read(appShellTabIndexProvider) == 1;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_isRecording && !_isSaving) {
        unawaited(_stopRecording());
        return;
      }
      final controller = _controller;
      if (controller == null) {
        return;
      }
      _controller = null;
      _currentZoom = 1.0;
      _recordingPreviewAspectRatio = null;
      _recordsAudio = true;
      _cameraDisposeStarted = false;
      _isArStreaming = false;
      _arStreamRetryTimer?.cancel();
      _clearRecordingPreviewFrame();
      _recordingStartedAt = null;
      _latestTrackedArFace = null;
      _arTrackSamples.clear();
      _clearArFaces();
      _arStreamGeneration++;
      unawaited(_disposeController(controller));
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (!isActiveTab || _isRecording || _cameraInitStarted) {
        return;
      }
      if (_cameras.isEmpty) {
        unawaited(_initCameras());
      } else {
        unawaited(_initCamera(_cameras[_cameraIndex]));
      }
    }
  }

  Future<void> _initCameras() async {
    if (_cameraInitStarted) {
      return;
    }
    _cameraInitStarted = true;
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initCamera(_cameras.first, markStarted: false);
      } else if (mounted) {
        setState(() {
          _noticeMessage = null;
          _errorMessage = context.l10n.captureNoCamera;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _noticeMessage = null;
          _errorMessage = _cameraErrorMessage(e);
        });
      }
    } finally {
      _cameraInitStarted = false;
    }
  }

  Future<void> _initCamera(
    CameraDescription desc, {
    bool markStarted = true,
  }) async {
    if (_isRecording) return;
    if (markStarted) {
      if (_cameraInitStarted) {
        return;
      }
      _cameraInitStarted = true;
    }
    final previousController = _controller;
    if (previousController != null) {
      await _stopArStream(clearFaces: true);
      _controller = null;
      if (mounted) {
        setState(() {});
      }
      await _disposeController(previousController);
    }
    try {
      final opened = await _openCamera(desc);
      if (!mounted) {
        await _disposeController(opened.controller);
        return;
      }
      setState(() {
        _controller = opened.controller;
        _currentZoom = 1.0;
        _recordingPreviewAspectRatio = null;
        _clearRecordingPreviewFrame();
        _recordsAudio = opened.recordsAudio;
        _errorMessage = null;
        _noticeMessage = opened.recordsAudio
            ? null
            : context.l10n.captureMicrophoneNoticeOff;
        _cameraDisposeStarted = false;
      });
      if (_activeArFilterAsset != null) {
        unawaited(_startArStream());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _controller = null;
          _recordingPreviewAspectRatio = null;
          _clearRecordingPreviewFrame();
          _noticeMessage = null;
          _errorMessage = _cameraErrorMessage(e);
        });
      }
      return;
    } finally {
      if (markStarted) {
        _cameraInitStarted = false;
      }
    }
  }

  Future<_OpenedCamera> _openCamera(CameraDescription desc) async {
    try {
      final controller = await _createCameraController(desc, enableAudio: true);
      return _OpenedCamera(controller: controller, recordsAudio: true);
    } catch (error) {
      if (!_shouldRetryWithoutAudio(error)) {
        rethrow;
      }
      final controller = await _createCameraController(
        desc,
        enableAudio: false,
      );
      return _OpenedCamera(controller: controller, recordsAudio: false);
    }
  }

  Future<CameraController> _createCameraController(
    CameraDescription desc, {
    required bool enableAudio,
  }) async {
    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: enableAudio,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    try {
      await controller.initialize().timeout(_cameraOpenTimeout);
      return controller;
    } catch (_) {
      await _disposeController(controller);
      rethrow;
    }
  }

  Future<void> _disposeController(CameraController controller) async {
    try {
      await controller.dispose().timeout(_cameraDisposeTimeout);
    } catch (_) {
      // Best effort; cleanup should not keep the camera UI stuck.
    }
  }

  Future<void> _pauseCameraForRoute() async {
    _cameraPausedForRoute = true;
    _arStreamRetryTimer?.cancel();
    _arStreamRetryTimer = null;
    final controller = _controller;
    if (controller == null) {
      if (mounted) {
        setState(() {});
      }
      return;
    }
    await _stopArStream(clearFaces: true);
    if (!mounted || _controller != controller) {
      return;
    }
    setState(() {
      _controller = null;
      _currentZoom = 1.0;
      _recordingPreviewAspectRatio = null;
      _clearRecordingPreviewFrame();
      _recordsAudio = true;
      _noticeMessage = null;
      _isArStreaming = false;
    });
    await _disposeController(controller);
  }

  void _resumeCameraAfterRoute() {
    if (!mounted) {
      return;
    }
    _cameraPausedForRoute = false;
    setState(() {});
    if (ref.read(appShellTabIndexProvider) != 1 ||
        _isRecording ||
        _cameraInitStarted ||
        _controller != null) {
      return;
    }
    if (_cameras.isEmpty) {
      unawaited(_initCameras());
    } else {
      unawaited(_initCamera(_cameras[_cameraIndex]));
    }
  }

  void _flipCamera() {
    if (_cameras.length < 2 || _isRecording || _cameraInitStarted) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    unawaited(_initCamera(_cameras[_cameraIndex]));
  }

  void _retryOpeningCamera() {
    if (_cameraInitStarted) {
      return;
    }
    setState(() {
      _errorMessage = null;
      _noticeMessage = null;
    });
    if (_cameras.isEmpty) {
      unawaited(_initCameras());
    } else {
      unawaited(_initCamera(_cameras[_cameraIndex]));
    }
  }

  Future<void> _toggleTorch() async {
    final ctrl = _controller;
    if (ctrl == null) return;
    final mode = ctrl.value.flashMode == FlashMode.torch
        ? FlashMode.off
        : FlashMode.torch;
    await ctrl.setFlashMode(mode);
    if (mounted) setState(() {});
  }

  Future<void> _toggleRecording() async {
    if (_isSaving) return;

    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isRecording) return;
    try {
      final shouldTrackArDuringRecording =
          _activeArFilterAsset != null && ctrl.supportsImageStreaming();
      _logCameraState(
        'record_start_before_pin',
        ctrl,
        shouldTrackArDuringRecording: shouldTrackArDuringRecording,
      );
      setState(() {
        _recordingPreviewAspectRatio =
            FillCameraPreview.effectivePreviewAspectRatioFor(ctrl.value);
      });
      _logCameraState(
        'record_start_after_pin',
        ctrl,
        shouldTrackArDuringRecording: shouldTrackArDuringRecording,
      );
      if (shouldTrackArDuringRecording) {
        await _stopArStream(clearFaces: false);
      }
      await ctrl.lockCaptureOrientation();
      _logCameraState(
        'record_start_after_lock',
        ctrl,
        shouldTrackArDuringRecording: shouldTrackArDuringRecording,
      );
      _recordingArFrameLogCount = 0;
      _resetArPerfCounters();
      _recordingStartedAt = null;
      _latestTrackedArFace = null;
      _arTrackSamples.clear();
      await ctrl.startVideoRecording(
        onAvailable: shouldTrackArDuringRecording ? _onArFrame : null,
      );
      _recordingStartedAt = DateTime.now();
      _logCameraState(
        'record_start_after_start',
        ctrl,
        shouldTrackArDuringRecording: shouldTrackArDuringRecording,
      );
      if (!mounted) return;
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
      setState(() {
        _isRecording = true;
        _isArStreaming = shouldTrackArDuringRecording;
        _errorMessage = null;
      });
      _startArTrackSampler();
      await HapticFeedback.lightImpact();
    } catch (error) {
      try {
        await ctrl.unlockCaptureOrientation();
      } catch (_) {
        // Ignore unlock failures while surfacing the real start error.
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _recordingPreviewAspectRatio = null;
        _clearRecordingPreviewFrame();
        _recordingStartedAt = null;
        _latestTrackedArFace = null;
        _arTrackSamples.clear();
        _errorMessage = _cameraErrorMessage(error);
      });
      if (_activeArFilterAsset != null) {
        unawaited(_startArStream());
      }
    }
  }

  Future<void> _stopRecording() async {
    final ctrl = _controller;
    if (ctrl == null || !_isRecording || _isSaving) return;

    _recordingTimer?.cancel();
    setState(() => _isSaving = true);

    final profiles = ref.read(profilesProvider).valueOrNull ?? const [];
    final selectedId = ref.read(selectedProfileIdProvider);
    final activeProfile =
        profiles.firstWhereOrNull((pr) => pr.id == selectedId) ??
        profiles.firstOrNull;

    if (activeProfile == null) {
      _stopArTrackSampler(recordFinalSample: true);
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _recordingPreviewAspectRatio = null;
        _clearRecordingPreviewFrame();
        _latestTrackedArFace = null;
        _arTrackSamples.clear();
        _noticeMessage = null;
        _errorMessage = context.l10n.captureChooseChild;
      });
      return;
    }

    // Ensure selectedProfileIdProvider matches the profile we're saving with
    if (selectedId != activeProfile.id) {
      ref.read(selectedProfileIdProvider.notifier).state = activeProfile.id;
    }

    try {
      final recording = await ctrl.stopVideoRecording();
      _stopArTrackSampler(recordFinalSample: true);
      _maybeLogArPerf(force: true);
      _logCameraState('record_stop_after_stop', ctrl);
      await ctrl.unlockCaptureOrientation();
      _logCameraState('record_stop_after_unlock', ctrl);
      final savedPath = await _persistRecording(recording);
      final videoId = _uuid.v4();
      final arTrackPath = await _persistArTrack(videoId);
      final thumbPath = await ref
          .read(thumbnailServiceProvider)
          .createVideoThumbnail(videoPath: savedPath);
      final ts = DateTime.now();
      final capturedSeconds = _recordingSeconds > 0
          ? _recordingSeconds.toDouble()
          : 1.0;
      if (mounted) {
        setState(() {
          _workflowState = _CaptureWorkflowState(
            stage: _CaptureWorkflowStage.processing,
            headline: context.l10n.captureFinishingClipTitle,
            detail: context.l10n.captureFinishingClipDetail,
          );
        });
      }
      final probe = await probeVideoFile(savedPath);
      final videoAspectRatio = probe?.displayAspectRatio;
      await ref
          .read(appDatabaseProvider)
          .saveLocalVideo(
            videoId: videoId,
            profileId: activeProfile.id,
            filePath: savedPath,
            thumbPath: thumbPath ?? '',
            title:
                'Clip ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
            durationSeconds: capturedSeconds,
            tags: [
              'captured',
              if (_activeArFilterId != null)
                ArFilterCatalog.tagFor(_activeArFilterId!),
              if (arTrackPath != null) ArFilterCatalog.trackTagFor(arTrackPath),
            ],
            approvalStatus: 'pending',
            aspectRatio: videoAspectRatio,
          );
      if (mounted) {
        setState(() {
          _workflowState = _CaptureWorkflowState(
            stage: _CaptureWorkflowStage.scanning,
            headline: context.l10n.captureCheckingClip,
            detail: context.l10n.captureSafetyScanDetail,
          );
        });
      }
      final scan = await ref
          .read(videoApprovalServiceProvider)
          .scanAndClassifyVideo(videoId: videoId);
      ref.invalidate(videosForSelectedProfileProvider);
      final savedVideo = await ref
          .read(appDatabaseProvider)
          .getLocalVideoById(videoId);

      if (!mounted) return;
      _arStreamGeneration++;
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _isArStreaming = false;
        _recordingPreviewAspectRatio = null;
        _clearRecordingPreviewFrame();
        _recordingStartedAt = null;
        _latestTrackedArFace = null;
        _arTrackSamples.clear();
        _showSavedBanner = true;
        _lastSavedVideo = savedVideo;
        _workflowState = _buildFinishedWorkflowState(scan);
      });
      await HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _showSavedBanner = false);
      });
    } catch (e) {
      try {
        await ctrl.unlockCaptureOrientation();
      } catch (_) {
        // Best effort; orientation unlock should not mask the real error.
      }
      if (!mounted) return;
      _arStreamGeneration++;
      _stopArTrackSampler(recordFinalSample: true);
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _isArStreaming = false;
        _recordingPreviewAspectRatio = null;
        _clearRecordingPreviewFrame();
        _recordingStartedAt = null;
        _latestTrackedArFace = null;
        _arTrackSamples.clear();
        _noticeMessage = null;
        _errorMessage = _cameraErrorMessage(e);
      });
      if (_activeArFilterAsset != null) {
        unawaited(_startArStream());
      }
    }
  }

  Future<String> _persistRecording(XFile recording) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'videos'));
    await folder.create(recursive: true);
    final ext = p.extension(recording.path).isEmpty
        ? '.mp4'
        : p.extension(recording.path);
    final dest = p.join(folder.path, '${_uuid.v4()}$ext');
    final src = File(recording.path);
    await src.copy(dest);
    if (await src.exists()) await src.delete();
    return dest;
  }

  Future<String?> _persistArTrack(String videoId) async {
    if (_activeArFilterId == null || _arTrackSamples.isEmpty) {
      return null;
    }
    final root = await getApplicationSupportDirectory();
    final path = p.join(root.path, 'ar_tracks', '$videoId.json');
    try {
      await ArFaceTrackService.writeTrackFile(
        path: path,
        samples: _arTrackSamples,
      );
      if (kDebugMode) {
        final durationMs = _arTrackSamples.isEmpty
            ? 0
            : _arTrackSamples.last.timeMs - _arTrackSamples.first.timeMs;
        final sampleFps = durationMs <= 0
            ? 0.0
            : _arTrackSamples.length / (durationMs / 1000);
        debugPrint(
          'AR export: saved capture track ${_arTrackSamples.length} samples '
          'sampleFps=${sampleFps.toStringAsFixed(1)}',
        );
      }
      return path;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('AR export: failed to save capture track: $error');
      }
      return null;
    }
  }

  void _onScaleStart(ScaleStartDetails _) {
    _baseZoom = _currentZoom;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final ctrl = _controller;
    if (ctrl == null) return;
    final newZoom = (_baseZoom * details.scale).clamp(1.0, 5.0);
    ctrl.setZoomLevel(newZoom);
    setState(() => _currentZoom = newZoom);
  }

  Future<void> _refreshArFilterLibraryState() async {
    final filters = _arFilterLibraryService.availableFilters();
    final cached = await _arFilterLibraryService.cachedFilterIds(filters);
    if (!mounted) return;
    setState(() => _cachedArFilterIds = cached);
  }

  Future<void> _selectArFilter(String? filterId) async {
    if (_isRecording || _isSaving || _cameraInitStarted) {
      return;
    }
    await HapticFeedback.selectionClick();
    if (filterId == null || filterId == ArFilterCatalog.noneId) {
      final previous = _activeArFilterAsset;
      await _stopArStream(clearFaces: true);
      previous?.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _activeArFilterId = null;
        _activeArFilterAsset = null;
        _downloadingArFilterIds.clear();
      });
      return;
    }
    if (_downloadingArFilterIds.contains(filterId)) {
      return;
    }

    setState(() {
      _activeArFilterId = filterId;
      _clearArFaces();
      _noticeMessage = null;
      _downloadingArFilterIds.add(filterId);
    });

    ArFilterAsset? loaded;
    try {
      await _arFilterLibraryService.ensureFilterAvailable(filterId);
      loaded = await _arFilterLibraryService.loadFilter(filterId);
    } catch (error) {
      _logArDebug('AR filter load failed: $error');
    }
    if (!mounted || _activeArFilterId != filterId) {
      loaded?.dispose();
      if (mounted) {
        setState(() => _downloadingArFilterIds.remove(filterId));
      }
      return;
    }
    if (loaded == null) {
      setState(() {
        _activeArFilterId = null;
        _downloadingArFilterIds.remove(filterId);
        _noticeMessage = 'Face filter could not be loaded.';
      });
      return;
    }

    final previous = _activeArFilterAsset;
    setState(() {
      _activeArFilterAsset = loaded;
      _cachedArFilterIds = {..._cachedArFilterIds, filterId};
      _downloadingArFilterIds.remove(filterId);
    });
    previous?.dispose();
    await _startArStream();
  }

  Future<void> _openArFilterPicker() async {
    if (_isRecording ||
        _isSaving ||
        _cameraInitStarted ||
        _workflowState != null ||
        _isArFilterPickerOpen) {
      return;
    }
    await HapticFeedback.selectionClick();
    if (!mounted) {
      return;
    }
    final latestFilters = _arFilterLibraryService.availableFilters();
    setState(() => _isArFilterPickerOpen = true);
    final selectedFilterId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: mediaQuery.viewInsets.bottom + AppSpacing.md,
          ),
          child: _ArFilterPickerSheet(
            palette: ref.read(activePaletteProvider),
            selectedFilterId: _activeArFilterId,
            filters: latestFilters,
            cachedFilterIds: _cachedArFilterIds,
            downloadingFilterIds: _downloadingArFilterIds,
          ),
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() => _isArFilterPickerOpen = false);
    if (selectedFilterId == null) {
      return;
    }
    await _selectArFilter(
      selectedFilterId == ArFilterCatalog.noneId ? null : selectedFilterId,
    );
  }

  Future<void> _startArStream() async {
    final ctrl = _controller;
    if (_isArStreaming ||
        _isRecording ||
        _isSaving ||
        _activeArFilterAsset == null ||
        ctrl == null ||
        !ctrl.value.isInitialized) {
      return;
    }
    if (ctrl.value.isRecordingVideo) {
      _scheduleArStreamRetry();
      return;
    }
    final service = _arService ??= ArFaceDetectionService();
    try {
      await service.init();
      if (!mounted ||
          _controller != ctrl ||
          _activeArFilterAsset == null ||
          _isRecording ||
          _isSaving ||
          ctrl.value.isRecordingVideo) {
        return;
      }
      await ctrl.startImageStream(_onArFrame);
      if (!mounted) {
        return;
      }
      setState(() => _isArStreaming = true);
    } catch (error) {
      _logArDebug('AR stream start failed: $error');
      if (error is CameraException &&
          error.code == 'A video recording is already started.') {
        _scheduleArStreamRetry();
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isArStreaming = false;
        _clearArFaces();
        _noticeMessage = 'Face filter tracking is not available right now.';
      });
    }
  }

  Future<void> _stopArStream({required bool clearFaces}) async {
    final ctrl = _controller;
    final wasStreaming = _isArStreaming;
    _isArStreaming = false;
    _arStreamGeneration++;
    _arStreamRetryTimer?.cancel();
    _arStreamRetryTimer = null;
    if (clearFaces && mounted) {
      _clearArFaces();
    }
    if (ctrl == null || !wasStreaming) {
      return;
    }
    try {
      await ctrl.stopImageStream();
    } catch (error) {
      _logArDebug('AR stream stop failed: $error');
    }
  }

  void _scheduleArStreamRetry() {
    if (_activeArFilterAsset == null || _isSaving) {
      return;
    }
    _arStreamRetryTimer?.cancel();
    _arStreamRetryTimer = Timer(const Duration(milliseconds: 180), () {
      _arStreamRetryTimer = null;
      if (!mounted) {
        return;
      }
      unawaited(_startArStream());
    });
  }

  void _onArFrame(CameraImage image) {
    final service = _arService;
    final ctrl = _controller;
    if (service == null ||
        ctrl == null ||
        _activeArFilterAsset == null ||
        _cameras.isEmpty) {
      return;
    }
    if (_isRecording) {
      _arCameraFrameCount += 1;
      _maybeLogArPerf();
    }
    if (kDebugMode && _isRecording && _recordingArFrameLogCount < 5) {
      _recordingArFrameLogCount += 1;
      debugPrint(
        'CAPTURE_CAMERA recording_ar_frame '
        'count=$_recordingArFrameLogCount '
        'size=${image.width}x${image.height} '
        'formatGroup=${image.format.group.name} '
        'formatRaw=${image.format.raw} '
        'planes=${image.planes.length} '
        'generation=$_arStreamGeneration',
      );
    }
    if (_shouldShowRecordingFramePreview &&
        _isRecording &&
        _activeArFilterAsset != null) {
      _updateRecordingPreviewFrame(
        image: image,
        controller: ctrl,
        camera: _cameras[_cameraIndex],
      );
    }
    final generation = _arStreamGeneration;
    if (_isArFrameDetectionInFlight) {
      if (_isRecording) {
        _arDetectionDroppedFrameCount += 1;
      }
      return;
    }
    _isArFrameDetectionInFlight = true;
    unawaited(
      service
          .processCameraImage(
            image: image,
            controller: ctrl,
            camera: _cameras[_cameraIndex],
          )
          .then((faces) {
            if (!mounted ||
                faces == null ||
                generation != _arStreamGeneration ||
                _controller != ctrl) {
              return;
            }
            final smoothedFaces = _arFaceSmoother.smooth(faces);
            _latestTrackedArFace = smoothedFaces.firstOrNull;
            if (_isRecording) {
              _arDetectionCompletedCount += 1;
            }
            _arFacesNotifier.value = smoothedFaces;
          })
          .whenComplete(() => _isArFrameDetectionInFlight = false),
    );
  }

  void _startArTrackSampler() {
    _arTrackSampleTimer?.cancel();
    if (_activeArFilterAsset == null) {
      return;
    }
    _recordLatestArTrackSample();
    _arTrackSampleTimer = Timer.periodic(
      _arTrackSampleInterval,
      (_) => _recordLatestArTrackSample(),
    );
  }

  void _stopArTrackSampler({required bool recordFinalSample}) {
    _arTrackSampleTimer?.cancel();
    _arTrackSampleTimer = null;
    if (recordFinalSample) {
      _recordLatestArTrackSample();
    }
  }

  void _recordLatestArTrackSample() {
    final startedAt = _recordingStartedAt;
    final face = _latestTrackedArFace;
    if (!_isRecording || startedAt == null || face == null) {
      return;
    }
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    if (_arTrackSamples.isNotEmpty &&
        elapsedMs - _arTrackSamples.last.timeMs <
            _arTrackSampleInterval.inMilliseconds - 10) {
      return;
    }
    _arTrackSamples.add(ArFaceTrackSample(timeMs: elapsedMs, face: face));
  }

  void _resetArPerfCounters() {
    _arCameraFrameCount = 0;
    _arDetectionCompletedCount = 0;
    _arDetectionDroppedFrameCount = 0;
    _lastArPerfLogMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _maybeLogArPerf({bool force = false}) {
    if (!kDebugMode) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!force && now - _lastArPerfLogMs < 3000) {
      return;
    }
    final elapsedSeconds = ((now - _lastArPerfLogMs) / 1000).clamp(0.001, 999);
    debugPrint(
      'CAPTURE_CAMERA ar_perf '
      'recording=$_isRecording '
      'cameraFps=${(_arCameraFrameCount / elapsedSeconds).toStringAsFixed(1)} '
      'detectFps=${(_arDetectionCompletedCount / elapsedSeconds).toStringAsFixed(1)} '
      'dropped=$_arDetectionDroppedFrameCount '
      'samples=${_arTrackSamples.length}',
    );
    _arCameraFrameCount = 0;
    _arDetectionCompletedCount = 0;
    _arDetectionDroppedFrameCount = 0;
    _lastArPerfLogMs = now;
  }

  void _clearRecordingPreviewFrame() {
    _lastRecordingPreviewFrameMs = 0;
    _isBuildingRecordingPreviewFrame = false;
    final previous = _recordingPreviewFrameNotifier.value;
    _recordingPreviewFrameNotifier.value = null;
    previous?.dispose();
  }

  void _clearArFaces() {
    _arFaceSmoother.reset();
    _latestTrackedArFace = null;
    _arFacesNotifier.value = const <ArFaceResult>[];
  }

  void _updateRecordingPreviewFrame({
    required CameraImage image,
    required CameraController controller,
    required CameraDescription camera,
  }) {
    if (_isBuildingRecordingPreviewFrame || !Platform.isAndroid) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastRecordingPreviewFrameMs < 66) {
      return;
    }
    _lastRecordingPreviewFrameMs = now;
    final rotationDegrees = _androidRotationDegrees(
      controller: controller,
      camera: camera,
    );
    if (rotationDegrees == null) {
      return;
    }
    final isMirrored = camera.lensDirection == CameraLensDirection.front;
    final frameGeneration = _arStreamGeneration;
    _isBuildingRecordingPreviewFrame = true;
    unawaited(
      _buildRecordingPreviewImage(
            image: image,
            rotationDegrees: rotationDegrees,
            isMirrored: isMirrored,
          )
          .then((frame) {
            if (!mounted ||
                frame == null ||
                frameGeneration != _arStreamGeneration ||
                !_isRecording ||
                _controller != controller) {
              frame?.dispose();
              return;
            }
            final previous = _recordingPreviewFrameNotifier.value;
            _recordingPreviewFrameNotifier.value = frame;
            if (previous != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                previous.dispose();
              });
            }
          })
          .whenComplete(() => _isBuildingRecordingPreviewFrame = false),
    );
  }

  int? _androidRotationDegrees({
    required CameraController controller,
    required CameraDescription camera,
  }) {
    const deviceOrientationDegrees = {
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    final deviceDegrees =
        deviceOrientationDegrees[controller.value.deviceOrientation];
    if (deviceDegrees == null) {
      return null;
    }
    if (camera.lensDirection == CameraLensDirection.front) {
      return (camera.sensorOrientation + deviceDegrees) % 360;
    }
    return (camera.sensorOrientation - deviceDegrees + 360) % 360;
  }

  Future<ui.Image?> _buildRecordingPreviewImage({
    required CameraImage image,
    required int rotationDegrees,
    required bool isMirrored,
  }) async {
    if (image.planes.length == 1) {
      return _buildRecordingPreviewImageFromNv21(
        image: image,
        rotationDegrees: rotationDegrees,
        isMirrored: isMirrored,
      );
    }
    if (image.planes.length < 3) {
      return null;
    }
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    final rawWidth = image.width;
    final rawHeight = image.height;
    const scale = 2;
    final normalizedRotation = rotationDegrees % 360;
    final rotatesSideways =
        normalizedRotation == 90 || normalizedRotation == 270;
    final outWidth = (rotatesSideways ? rawHeight : rawWidth) ~/ scale;
    final outHeight = (rotatesSideways ? rawWidth : rawHeight) ~/ scale;
    if (outWidth <= 0 || outHeight <= 0) {
      return null;
    }

    final rgba = Uint8List(outWidth * outHeight * 4);
    var dst = 0;
    for (var y = 0; y < outHeight; y++) {
      for (var x = 0; x < outWidth; x++) {
        final displayX = isMirrored ? outWidth - 1 - x : x;
        final source = _recordingPreviewSourcePixel(
          displayX: displayX,
          displayY: y,
          rawWidth: rawWidth,
          rawHeight: rawHeight,
          scale: scale,
          rotationDegrees: normalizedRotation,
        );
        if (source == null) {
          return null;
        }
        final sourceX = source.$1;
        final sourceY = source.$2;
        final yIndex = sourceY * yPlane.bytesPerRow + sourceX * yPixelStride;
        final uvX = sourceX >> 1;
        final uvY = sourceY >> 1;
        final uIndex = uvY * uPlane.bytesPerRow + uvX * uPixelStride;
        final vIndex = uvY * vPlane.bytesPerRow + uvX * vPixelStride;
        if (yIndex >= yPlane.bytes.length ||
            uIndex >= uPlane.bytes.length ||
            vIndex >= vPlane.bytes.length) {
          return null;
        }
        final luma = yPlane.bytes[yIndex];
        final chromaU = uPlane.bytes[uIndex] - 128;
        final chromaV = vPlane.bytes[vIndex] - 128;
        final red = (luma + ((1436 * chromaV) >> 10)).clamp(0, 255);
        final green = (luma - ((352 * chromaU + 731 * chromaV) >> 10)).clamp(
          0,
          255,
        );
        final blue = (luma + ((1814 * chromaU) >> 10)).clamp(0, 255);
        rgba[dst++] = red.toInt();
        rgba[dst++] = green.toInt();
        rgba[dst++] = blue.toInt();
        rgba[dst++] = 255;
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      outWidth,
      outHeight,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<ui.Image?> _buildRecordingPreviewImageFromNv21({
    required CameraImage image,
    required int rotationDegrees,
    required bool isMirrored,
  }) async {
    final plane = image.planes.first;
    final rawWidth = image.width;
    final rawHeight = image.height;
    const scale = 2;
    final normalizedRotation = rotationDegrees % 360;
    final rotatesSideways =
        normalizedRotation == 90 || normalizedRotation == 270;
    final outWidth = (rotatesSideways ? rawHeight : rawWidth) ~/ scale;
    final outHeight = (rotatesSideways ? rawWidth : rawHeight) ~/ scale;
    if (outWidth <= 0 || outHeight <= 0) {
      return null;
    }

    final yRowStride = plane.bytesPerRow > 0 ? plane.bytesPerRow : rawWidth;
    final ySize = yRowStride * rawHeight;
    if (plane.bytes.length < ySize) {
      return null;
    }
    final vuRowStride = yRowStride;
    final vuOffset = ySize;
    final rgba = Uint8List(outWidth * outHeight * 4);
    var dst = 0;
    for (var y = 0; y < outHeight; y++) {
      for (var x = 0; x < outWidth; x++) {
        final displayX = isMirrored ? outWidth - 1 - x : x;
        final source = _recordingPreviewSourcePixel(
          displayX: displayX,
          displayY: y,
          rawWidth: rawWidth,
          rawHeight: rawHeight,
          scale: scale,
          rotationDegrees: normalizedRotation,
        );
        if (source == null) {
          return null;
        }
        final sourceX = source.$1;
        final sourceY = source.$2;
        final yIndex = sourceY * yRowStride + sourceX;
        final uvX = sourceX >> 1;
        final uvY = sourceY >> 1;
        final vuIndex = vuOffset + uvY * vuRowStride + uvX * 2;
        if (yIndex >= plane.bytes.length || vuIndex + 1 >= plane.bytes.length) {
          return null;
        }
        final luma = plane.bytes[yIndex];
        final chromaV = plane.bytes[vuIndex] - 128;
        final chromaU = plane.bytes[vuIndex + 1] - 128;
        final red = (luma + ((1436 * chromaV) >> 10)).clamp(0, 255);
        final green = (luma - ((352 * chromaU + 731 * chromaV) >> 10)).clamp(
          0,
          255,
        );
        final blue = (luma + ((1814 * chromaU) >> 10)).clamp(0, 255);
        rgba[dst++] = red.toInt();
        rgba[dst++] = green.toInt();
        rgba[dst++] = blue.toInt();
        rgba[dst++] = 255;
      }
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      outWidth,
      outHeight,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  (int, int)? _recordingPreviewSourcePixel({
    required int displayX,
    required int displayY,
    required int rawWidth,
    required int rawHeight,
    required int scale,
    required int rotationDegrees,
  }) {
    final scaledX = displayX * scale;
    final scaledY = displayY * scale;
    final (sourceX, sourceY) = switch (rotationDegrees) {
      0 => (scaledX, scaledY),
      90 => (scaledY, rawHeight - 1 - scaledX),
      180 => (rawWidth - 1 - scaledX, rawHeight - 1 - scaledY),
      270 => (rawWidth - 1 - scaledY, scaledX),
      _ => (scaledX, scaledY),
    };
    if (sourceX < 0 ||
        sourceX >= rawWidth ||
        sourceY < 0 ||
        sourceY >= rawHeight) {
      return null;
    }
    return (sourceX, sourceY);
  }

  void _logCameraState(
    String event,
    CameraController controller, {
    bool? shouldTrackArDuringRecording,
  }) {
    if (!kDebugMode) {
      return;
    }
    final value = controller.value;
    final previewSize = value.previewSize;
    debugPrint(
      'CAPTURE_CAMERA $event '
      'recording=${value.isRecordingVideo} '
      'streaming=${value.isStreamingImages} '
      'previewSize=${previewSize?.width.toStringAsFixed(0)}x${previewSize?.height.toStringAsFixed(0)} '
      'rawAspect=${value.aspectRatio.toStringAsFixed(4)} '
      'effectiveAspect=${FillCameraPreview.effectivePreviewAspectRatioFor(value).toStringAsFixed(4)} '
      'pinned=${_recordingPreviewAspectRatio?.toStringAsFixed(4) ?? 'none'} '
      'device=${value.deviceOrientation.name} '
      'locked=${value.lockedCaptureOrientation?.name ?? 'none'} '
      'recordingOrientation=${value.recordingOrientation?.name ?? 'none'} '
      'previewPause=${value.previewPauseOrientation?.name ?? 'none'} '
      'arFilter=${_activeArFilterId ?? 'none'} '
      'arStreaming=$_isArStreaming '
      'trackDuringRecording=${shouldTrackArDuringRecording ?? 'unknown'}',
    );
  }

  void _logArDebug(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(appShellTabIndexProvider);
    if (activeTab == 1 &&
        !_cameraPausedForRoute &&
        !_cameraInitStarted &&
        !_cameraDisposeStarted &&
        _controller == null &&
        _workflowState == null &&
        _errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (_cameras.isEmpty) {
            unawaited(_initCameras());
          } else {
            unawaited(_initCamera(_cameras[_cameraIndex]));
          }
        }
      });
    }
    if (activeTab != 1 &&
        _isRecording &&
        !_isSaving &&
        !_cameraDisposeStarted) {
      _cameraDisposeStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !_isRecording || _isSaving) {
          if (mounted) {
            setState(() {
              _cameraDisposeStarted = false;
            });
          }
          return;
        }
        await _stopRecording();
        if (!mounted) {
          return;
        }
        setState(() {
          _cameraDisposeStarted = false;
        });
      });
    }
    if (activeTab != 1 &&
        _controller != null &&
        !_isRecording &&
        !_isSaving &&
        !_cameraDisposeStarted) {
      _cameraDisposeStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final controller = _controller;
        if (!mounted || controller == null || _isRecording) {
          _cameraDisposeStarted = false;
          return;
        }
        await _stopArStream(clearFaces: true);
        if (!mounted || _controller != controller) {
          _cameraDisposeStarted = false;
          return;
        }
        setState(() {
          _controller = null;
          _currentZoom = 1.0;
          _recordingPreviewAspectRatio = null;
          _clearRecordingPreviewFrame();
          _recordsAudio = true;
          _noticeMessage = null;
        });
        await _disposeController(controller);
        if (!mounted) {
          return;
        }
        setState(() {
          _cameraDisposeStarted = false;
        });
      });
    }
    final palette = ref.watch(activePaletteProvider);
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final ctrl = _controller;
    final isReady = ctrl != null && ctrl.value.isInitialized;
    final isTorch = ctrl?.value.flashMode == FlashMode.torch;
    final stateChangeDuration = AppMotion.duration(
      context,
      AppMotion.stateChange,
    );

    return Stack(
      children: [
        // Camera preview (fills entire screen)
        if (isReady)
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: FillCameraPreview(
                controller: ctrl,
                previewAspectRatio: _recordingPreviewAspectRatio,
                debugLabel: 'capture',
              ),
            ),
          )
        else
          Positioned.fill(
            child: ColoredBox(
              color: palette.mediaScrim,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_errorMessage == null)
                          CircularProgressIndicator(
                            color: palette.mediaSubtleInk,
                          )
                        else
                          Icon(
                            Icons.videocam_off_rounded,
                            color: palette.mediaMutedInk,
                            size: AppIconSize.empty,
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          _errorMessage == null
                              ? context.l10n.captureOpeningCamera
                              : context.l10n.captureCameraNeedsAttention,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.mediaInk,
                            fontSize: AppTextSize.title,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage ??
                              context.l10n.captureGettingReadyDetail,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: palette.mediaMutedInk,
                            fontSize: AppTextSize.body,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.xl),
                          OutlinedButton(
                            onPressed: _retryOpeningCamera,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: palette.mediaInk,
                              side: BorderSide(
                                color: palette.mediaBorderStrong,
                              ),
                            ),
                            child: Text(context.l10n.actionTryAgain),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        if (_shouldShowRecordingFramePreview &&
            isReady &&
            _isRecording &&
            _activeArFilterAsset != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<ui.Image?>(
                valueListenable: _recordingPreviewFrameNotifier,
                builder: (context, frame, _) {
                  if (frame == null) {
                    return const ColoredBox(color: Colors.black);
                  }
                  return _RecordingFramePreview(image: frame);
                },
              ),
            ),
          ),

        if (isReady && _activeArFilterAsset != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<List<ArFaceResult>>(
                valueListenable: _arFacesNotifier,
                builder: (context, faces, _) {
                  if (faces.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _ArFilterPreviewOverlay(
                    faces: faces,
                    filter: _activeArFilterAsset!,
                    renderer: _arFilterRenderer,
                    isMirrored:
                        _cameras.isNotEmpty &&
                        _cameras[_cameraIndex].lensDirection ==
                            CameraLensDirection.front,
                  );
                },
              ),
            ),
          ),

        // Header overlay
        Positioned(
          top: topPad + AppSpacing.md,
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          child: Row(
            children: [
              // Zoom badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: palette.mediaSurface,
                  borderRadius: AppRadii.lgAll,
                ),
                child: Text(
                  '${_currentZoom.toStringAsFixed(1)}x',
                  style: TextStyle(
                    color: palette.mediaInk,
                    fontSize: AppTextSize.label,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!_recordsAudio) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.mediaSurface,
                    borderRadius: AppRadii.lgAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic_off_rounded,
                        color: palette.mediaInk,
                        size: AppIconSize.xs,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        context.l10n.captureMicSilent,
                        style: TextStyle(
                          color: palette.mediaInk,
                          fontSize: AppTextSize.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // Torch toggle
              _CaptureCircleBtn(
                icon: isTorch
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                palette: palette,
                onTap: _toggleTorch,
              ),
              const SizedBox(width: AppSpacing.md),
              // Camera flip
              _CaptureCircleBtn(
                icon: Icons.cameraswitch_rounded,
                palette: palette,
                onTap: _flipCamera,
              ),
            ],
          ),
        ),

        if (isReady && !_isSaving && _workflowState == null)
          Positioned(
            right: AppSpacing.lg,
            bottom: bottomPad + 170,
            child: _CaptureArFilterButton(
              palette: palette,
              enabled: !_isRecording,
              isSelected: _activeArFilterId != null,
              isOpen: _isArFilterPickerOpen,
              onTap: _openArFilterPicker,
            ),
          ),

        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPad + 80, // above tab bar
          child: Column(
            children: [
              // Recording indicator
              if (_isRecording)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: palette.mediaSurfaceStrong,
                    borderRadius: AppRadii.xlAll,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.danger,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: palette.mediaInk,
                          fontSize: AppTextSize.bodyLarge,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

              // Record button
              GestureDetector(
                onTap: isReady ? _toggleRecording : null,
                child: AnimatedScale(
                  duration: stateChangeDuration,
                  curve: AppMotion.easeOutQuint,
                  scale: _isSaving
                      ? 0.94
                      : _isRecording
                      ? 1.04
                      : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.mediaInk, width: 6),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AnimatedContainer(
                      duration: stateChangeDuration,
                      curve: AppMotion.easeOutQuint,
                      decoration: BoxDecoration(
                        color: palette.danger,
                        borderRadius: BorderRadius.circular(
                          _isRecording ? AppRadii.sm : AppRadii.card,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Saved banner (slides from top)
        AnimatedPositioned(
          duration: AppMotion.duration(context, AppMotion.layoutChange),
          curve: AppMotion.easeOutQuint,
          top: _showSavedBanner ? topPad + 60 : -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: palette.surfaceStrong,
                borderRadius: AppRadii.xxlAll,
                boxShadow: [
                  BoxShadow(color: palette.inkSubtle, blurRadius: 12),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: palette.success,
                    size: AppIconSize.lg,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.l10n.captureVideoSaved,
                    style: TextStyle(
                      color: palette.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Error / notice banner
        if (_errorMessage != null || _noticeMessage != null)
          Positioned(
            top: topPad + 60,
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            child: GestureDetector(
              onTap: () {
                if (_errorMessage != null) {
                  _retryOpeningCamera();
                } else {
                  setState(() => _noticeMessage = null);
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: palette.mediaSurfaceStrong,
                      borderRadius: AppRadii.xlAll,
                      border: Border.all(
                        color: _errorMessage != null
                            ? palette.dangerVibrant
                            : palette.accentSecondaryVibrant,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            _errorMessage != null
                                ? Icons.info_outline_rounded
                                : Icons.mic_off_rounded,
                            color: _errorMessage != null
                                ? palette.danger
                                : palette.accentSecondary,
                            size: AppIconSize.md,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            _errorMessage ?? _noticeMessage!,
                            style: TextStyle(
                              color: palette.mediaInk,
                              fontSize: AppTextSize.label,
                              height: 1.3,
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

        // Saving / scan overlay
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: palette.mediaScrim,
              child: Center(
                child: _CaptureWorkflowOverlay(
                  palette: palette,
                  state:
                      _workflowState ??
                      _CaptureWorkflowState(
                        stage: _CaptureWorkflowStage.preparing,
                        headline: context.l10n.capturePreparingCamera,
                        detail: context.l10n.captureGettingReadyShort,
                      ),
                ),
              ),
            ),
          ),

        if (_workflowState != null && !_isSaving && _lastSavedVideo != null)
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: bottomPad + 90,
            child: _CaptureNextStepCard(
              palette: palette,
              state: _workflowState!,
              video: _lastSavedVideo!,
              isQuickSharing: _isRunningQuickShare,
              onDismiss: () {
                setState(() {
                  _workflowState = null;
                  _lastSavedVideo = null;
                });
                if (_activeArFilterAsset != null) {
                  unawaited(_startArStream());
                }
              },
              onOpenPlayer: () {
                final video = _lastSavedVideo;
                if (video == null) {
                  return;
                }
                HapticFeedback.selectionClick();
                unawaited(_openSavedVideoPlayer(video));
              },
              onOpenEditor: () {
                final video = _lastSavedVideo;
                if (video == null) {
                  return;
                }
                HapticFeedback.selectionClick();
                unawaited(_openSavedVideoEditor(video));
              },
              onShareNow: _shareLastSavedVideo,
            ),
          ),
      ],
    );
  }

  _CaptureWorkflowState _buildFinishedWorkflowState(ContentScanSummary scan) {
    final l10n = context.l10n;
    if (scan.needsReview) {
      return _CaptureWorkflowState(
        stage: _CaptureWorkflowStage.complete,
        headline: l10n.captureSavedNeedsReview,
        detail: scan.summary,
        canShare: false,
      );
    }
    return _CaptureWorkflowState(
      stage: _CaptureWorkflowStage.complete,
      headline: l10n.captureClipReady,
      detail: l10n.captureReadyDetail,
      canShare: true,
    );
  }

  Future<void> _openSavedVideoPlayer(LocalVideo video) async {
    await _pauseCameraForRoute();
    if (!mounted) {
      return;
    }
    try {
      await Navigator.of(context).push(
        AppMotion.modalRoute(
          context: context,
          builder: (_) => PlayerPage(videoId: video.id),
        ),
      );
    } finally {
      _resumeCameraAfterRoute();
    }
  }

  Future<void> _openSavedVideoEditor(LocalVideo video) async {
    await _pauseCameraForRoute();
    if (!mounted) {
      return;
    }
    try {
      await Navigator.of(context).push(
        AppMotion.modalRoute(
          context: context,
          builder: (_) => EditorDetailPage.fromVideo(
            video: video,
            initialArFilterId: _activeArFilterId,
          ),
        ),
      );
    } finally {
      _resumeCameraAfterRoute();
    }
  }

  Future<void> _shareLastSavedVideo() async {
    final video = _lastSavedVideo;
    if (video == null || _isRunningQuickShare) {
      return;
    }

    final identity = ref.read(parentIdentityProvider).valueOrNull;
    final profile = (ref.read(profilesProvider).valueOrNull ?? const [])
        .firstWhereOrNull((item) => item.id == video.profileId);
    if (identity == null || profile == null) {
      setState(() {
        _errorMessage = context.l10n.captureFinishSetupShareThisClip;
      });
      return;
    }

    setState(() => _isRunningQuickShare = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
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
      await HapticFeedback.mediumImpact();
      final count = result.queuedGroupCount;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.captureSharing(video.title, count))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(_shareErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isRunningQuickShare = false);
      }
    }
  }

  bool _shouldRetryWithoutAudio(Object error) {
    return error is TimeoutException || _isAudioAccessError(error);
  }

  bool _isAudioAccessError(Object error) {
    final code = _cameraErrorCode(error)?.toLowerCase();
    if (code != null && code.startsWith('audioaccess')) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return (message.contains('audio') || message.contains('microphone')) &&
        (message.contains('access') ||
            message.contains('permission') ||
            message.contains('denied') ||
            message.contains('restricted'));
  }

  bool _isCameraAccessError(Object error) {
    final code = _cameraErrorCode(error)?.toLowerCase();
    if (code != null && code.startsWith('cameraaccess')) {
      return true;
    }
    final message = error.toString().toLowerCase();
    return message.contains('camera') &&
        (message.contains('access') ||
            message.contains('permission') ||
            message.contains('denied') ||
            message.contains('restricted'));
  }

  String? _cameraErrorCode(Object error) {
    if (error is CameraException) {
      return error.code;
    }
    if (error is PlatformException) {
      return error.code;
    }
    return null;
  }

  String _cameraErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (error is TimeoutException) {
      return context.l10n.captureCameraTimeout;
    }
    if (_isCameraAccessError(error)) {
      return context.l10n.captureCameraDenied;
    }
    if (_isAudioAccessError(error)) {
      return context.l10n.captureMicrophoneDenied;
    }
    if (message.contains('access') || message.contains('permission')) {
      return context.l10n.captureCameraStillDenied;
    }
    if (message.contains('camera') && message.contains('in use')) {
      return context.l10n.captureCameraBusy;
    }
    if (message.contains('profile')) {
      return context.l10n.captureChooseChild;
    }
    return context.l10n.captureCameraStartFailed;
  }

  String _shareErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('parent') || message.contains('identity')) {
      return context.l10n.captureFinishSetupShare;
    }
    if (message.contains('approval')) {
      return context.l10n.captureNeedsParentReview;
    }
    if (_looksLikeShareUploadError(message)) {
      return context.l10n.playerShareUploadFailed;
    }
    if (message.contains('group') || message.contains('family')) {
      return context.l10n.captureConnectFamilyShare;
    }
    return context.l10n.captureShareFailed;
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
}

class _OpenedCamera {
  const _OpenedCamera({required this.controller, required this.recordsAudio});

  final CameraController controller;
  final bool recordsAudio;
}

enum _CaptureWorkflowStage { preparing, processing, scanning, complete }

class _CaptureWorkflowState {
  const _CaptureWorkflowState({
    required this.stage,
    required this.headline,
    required this.detail,
    this.canShare = false,
  });

  final _CaptureWorkflowStage stage;
  final String headline;
  final String detail;
  final bool canShare;
}

class _CaptureWorkflowOverlay extends StatelessWidget {
  const _CaptureWorkflowOverlay({required this.palette, required this.state});

  final KidPalette palette;
  final _CaptureWorkflowState state;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppMotion.reduceMotion(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.mediaSurfaceStrong,
          borderRadius: AppRadii.cardAll,
          border: Border.all(color: palette.mediaBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                child: Icon(
                  _iconForStage(state.stage),
                  key: ValueKey(state.stage),
                  size: AppIconSize.display,
                  color: palette.mediaInk,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                child: Text(
                  state.headline,
                  key: ValueKey(state.headline),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.mediaInk,
                    fontSize: AppTextSize.title,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                child: Text(
                  state.detail,
                  key: ValueKey(state.detail),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: palette.mediaMutedInk,
                    fontSize: AppTextSize.body,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _CaptureWorkflowStage.values
                    .map(
                      (stage) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: AnimatedContainer(
                          duration: AppMotion.duration(
                            context,
                            AppMotion.stateChange,
                          ),
                          curve: AppMotion.easeOutQuint,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: _isStageComplete(stage)
                                ? palette.mediaSurfaceSubtle
                                : Colors.transparent,
                            borderRadius: AppRadii.lgAll,
                            border: Border.all(
                              color: _isStageComplete(stage)
                                  ? palette.mediaBorder
                                  : palette.mediaSurfaceSubtle,
                            ),
                          ),
                          child: AnimatedScale(
                            duration: AppMotion.duration(
                              context,
                              AppMotion.instantFeedback,
                            ),
                            scale: state.stage == stage && !reducedMotion
                                ? 1.08
                                : 1,
                            child: Icon(
                              _iconForStage(stage),
                              size: AppIconSize.md,
                              color: _isStageComplete(stage)
                                  ? palette.mediaInk
                                  : palette.mediaSubtleInk,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForStage(_CaptureWorkflowStage stage) {
    return switch (stage) {
      _CaptureWorkflowStage.preparing => Icons.settings_rounded,
      _CaptureWorkflowStage.processing => Icons.auto_fix_high_rounded,
      _CaptureWorkflowStage.scanning => Icons.shield_outlined,
      _CaptureWorkflowStage.complete => Icons.check_circle_rounded,
    };
  }

  bool _isStageComplete(_CaptureWorkflowStage stage) {
    return stage.index <= state.stage.index;
  }
}

class _CaptureNextStepCard extends StatelessWidget {
  const _CaptureNextStepCard({
    required this.palette,
    required this.state,
    required this.video,
    required this.isQuickSharing,
    required this.onDismiss,
    required this.onOpenPlayer,
    required this.onOpenEditor,
    required this.onShareNow,
  });

  final KidPalette palette;
  final _CaptureWorkflowState state;
  final LocalVideo video;
  final bool isQuickSharing;
  final VoidCallback onDismiss;
  final VoidCallback onOpenPlayer;
  final VoidCallback onOpenEditor;
  final Future<void> Function() onShareNow;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.layoutChange);
    final offset = AppMotion.offset(context, const Offset(0, 18));
    return TweenAnimationBuilder<double>(
      key: ValueKey('${video.id}:${state.headline}'),
      duration: duration,
      curve: AppMotion.easeOutQuint,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(offset.dx * (1 - value), offset.dy * (1 - value)),
            child: child,
          ),
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: AppMotion.duration(
                          context,
                          AppMotion.stateChange,
                        ),
                        curve: AppMotion.easeOutQuint,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.accentMuted,
                        ),
                        child: Icon(
                          state.canShare
                              ? Icons.check_circle_rounded
                              : Icons.shield_outlined,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.headline,
                              style: TextStyle(
                                color: palette.mediaInk,
                                fontWeight: FontWeight.w800,
                                fontSize: AppTextSize.bodyLarge,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              state.detail,
                              style: TextStyle(
                                color: palette.mediaMutedInk,
                                fontSize: AppTextSize.label,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onDismiss,
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.mediaMutedInk,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onOpenPlayer,
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(context.l10n.actionWatch),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onOpenEditor,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(context.l10n.actionEdit),
                      ),
                      FilledButton.icon(
                        onPressed: state.canShare && !isQuickSharing
                            ? () => unawaited(onShareNow())
                            : null,
                        icon: isQuickSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded),
                        label: Text(
                          state.canShare
                              ? context.l10n.captureShareNow
                              : context.l10n.editorReviewFirst,
                        ),
                      ),
                    ],
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

class _RecordingFramePreview extends StatelessWidget {
  const _RecordingFramePreview({required this.image});

  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: image.width.toDouble(),
          height: image.height.toDouble(),
          child: RawImage(image: image, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

class _ArFilterPreviewOverlay extends StatelessWidget {
  const _ArFilterPreviewOverlay({
    required this.faces,
    required this.filter,
    required this.renderer,
    required this.isMirrored,
  });

  final List<ArFaceResult> faces;
  final ArFilterAsset filter;
  final ArFilterRenderer renderer;
  final bool isMirrored;

  @override
  Widget build(BuildContext context) {
    if (faces.isEmpty) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = constraints.biggest;
        if (viewportSize.isEmpty) {
          return const SizedBox.shrink();
        }
        final face = faces.first;
        final commands = renderer.computeDrawCommands(
          face: face,
          filter: filter,
          geometry: ArPreviewGeometry(
            imageSize: face.imageSize,
            viewportSize: viewportSize,
            isMirrored: isMirrored,
          ),
        );
        return RepaintBoundary(
          child: CustomPaint(
            painter: ArFilterOverlayPainter(commands: commands),
            size: viewportSize,
          ),
        );
      },
    );
  }
}

class _CaptureArFilterButton extends StatelessWidget {
  const _CaptureArFilterButton({
    required this.palette,
    required this.enabled,
    required this.isSelected,
    required this.isOpen,
    required this.onTap,
  });

  final KidPalette palette;
  final bool enabled;
  final bool isSelected;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Face filters',
      child: Opacity(
        opacity: enabled ? 1 : 0.52,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedScale(
            scale: isOpen ? 0.96 : 1,
            duration: AppMotion.duration(context, AppMotion.stateChange),
            curve: AppMotion.easeOutQuint,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [palette.accent, palette.accentSecondary],
                      )
                    : null,
                color: isSelected ? null : palette.mediaSurfaceStrong,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? palette.mediaBorderStrong
                      : palette.mediaBorder,
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.face_retouching_natural_rounded,
                    color: palette.mediaInk,
                    size: AppIconSize.lg,
                  ),
                  if (isSelected)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: palette.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: palette.mediaSurfaceStrong,
                            width: 1.5,
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
    );
  }
}

class _ArFilterPickerSheet extends StatefulWidget {
  const _ArFilterPickerSheet({
    required this.palette,
    required this.selectedFilterId,
    required this.filters,
    required this.cachedFilterIds,
    required this.downloadingFilterIds,
  });

  final KidPalette palette;
  final String? selectedFilterId;
  final List<ArFilterDefinition> filters;
  final Set<String> cachedFilterIds;
  final Set<String> downloadingFilterIds;

  @override
  State<_ArFilterPickerSheet> createState() => _ArFilterPickerSheetState();
}

class _ArFilterPickerSheetState extends State<_ArFilterPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _categoryId = _ArFilterCategory.all.id;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _ArFilterCategory.visibleFor(
      filters: widget.filters,
      cachedFilterIds: widget.cachedFilterIds,
    );
    final selectedCategory = categories.firstWhere(
      (category) => category.id == _categoryId,
      orElse: () => _ArFilterCategory.all,
    );
    final normalizedQuery = _query.trim().toLowerCase();
    final filters = widget.filters
        .where((filter) {
          if (!selectedCategory.matches(filter, widget.cachedFilterIds)) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          final searchable = [
            filter.label,
            filter.id.replaceAll('-', ' '),
            filter.category,
            filter.description ?? '',
            filter.sourceName ?? '',
          ].join(' ').toLowerCase();
          return searchable.contains(normalizedQuery);
        })
        .toList(growable: false);

    return ClipRRect(
      borderRadius: AppRadii.xlAll,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.68,
          ),
          decoration: BoxDecoration(
            color: widget.palette.mediaSurfaceStrong,
            borderRadius: AppRadii.xlAll,
            border: Border.all(color: widget.palette.mediaBorder),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: widget.palette.mediaBorderStrong,
                  borderRadius: AppRadii.xlAll,
                ),
              ),
              _ArFilterSearchField(
                palette: widget.palette,
                controller: _searchController,
                onQueryChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _ArFilterCategoryChip(
                      palette: widget.palette,
                      label: category.localizedLabel(context),
                      isSelected: category.id == selectedCategory.id,
                      onTap: () => setState(() => _categoryId = category.id),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: filters.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _ArFilterPickerRow(
                        palette: widget.palette,
                        label: 'None',
                        status: widget.selectedFilterId == null
                            ? 'Selected'
                            : 'Ready',
                        icon: Icons.block_rounded,
                        isSelected: widget.selectedFilterId == null,
                        isDownloading: false,
                        onTap: () =>
                            Navigator.of(context).pop(ArFilterCatalog.noneId),
                      );
                    }
                    final filter = filters[index - 1];
                    final isCached = widget.cachedFilterIds.contains(filter.id);
                    final isDownloading = widget.downloadingFilterIds.contains(
                      filter.id,
                    );
                    return _ArFilterPickerRow(
                      palette: widget.palette,
                      label: filter.label,
                      status: isDownloading
                          ? context.l10n.editorMusicLoading
                          : isCached
                          ? context.l10n.editorMusicReady
                          : context.l10n.editorMusicDownload,
                      icon: isCached
                          ? _iconForArFilter(filter)
                          : Icons.download_rounded,
                      isSelected: widget.selectedFilterId == filter.id,
                      isDownloading: isDownloading,
                      onTap: isDownloading
                          ? null
                          : () => Navigator.of(context).pop(filter.id),
                    );
                  },
                ),
              ),
              if (filters.isEmpty && normalizedQuery.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No matching filters',
                  style: TextStyle(
                    color: widget.palette.mediaSubtleInk,
                    fontSize: AppTextSize.label,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArFilterSearchField extends StatelessWidget {
  const _ArFilterSearchField({
    required this.palette,
    required this.controller,
    required this.onQueryChanged,
  });

  final KidPalette palette;
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
        style: TextStyle(
          color: palette.mediaInk,
          fontSize: AppTextSize.body,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search filters',
          hintStyle: TextStyle(
            color: palette.mediaSubtleInk,
            fontSize: AppTextSize.body,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: palette.mediaSubtleInk,
            size: AppIconSize.lg,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.close_rounded,
                    color: palette.mediaMutedInk,
                    size: AppIconSize.md,
                  ),
                  onPressed: () {
                    controller.clear();
                    onQueryChanged('');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          filled: true,
          fillColor: palette.mediaSurfaceSubtle,
          border: OutlineInputBorder(
            borderRadius: AppRadii.smAll,
            borderSide: BorderSide(color: palette.mediaBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.smAll,
            borderSide: BorderSide(color: palette.mediaBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.smAll,
            borderSide: BorderSide(color: palette.mediaBorderStrong),
          ),
        ),
      ),
    );
  }
}

class _ArFilterCategoryChip extends StatelessWidget {
  const _ArFilterCategoryChip({
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? palette.accent.withValues(alpha: 0.28)
              : palette.mediaSurfaceSubtle,
          borderRadius: AppRadii.xlAll,
          border: Border.all(
            color: isSelected ? palette.accentSecondary : palette.mediaBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: palette.mediaInk,
            fontSize: AppTextSize.label,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ArFilterPickerRow extends StatelessWidget {
  const _ArFilterPickerRow({
    required this.palette,
    required this.label,
    required this.status,
    required this.icon,
    required this.isSelected,
    required this.isDownloading,
    required this.onTap,
  });

  final KidPalette palette;
  final String label;
  final String status;
  final IconData icon;
  final bool isSelected;
  final bool isDownloading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [palette.accent, palette.accentSecondary],
                )
              : null,
          color: isSelected ? null : palette.mediaSurfaceSubtle,
          borderRadius: AppRadii.smAll,
          border: Border.all(
            color: isSelected ? palette.mediaBorderStrong : palette.mediaBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: palette.mediaSurface,
                borderRadius: AppRadii.smAll,
              ),
              child: isDownloading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: palette.mediaInk,
                      ),
                    )
                  : Icon(icon, color: palette.mediaInk, size: AppIconSize.lg),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.mediaInk,
                  fontSize: AppTextSize.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(maxWidth: 92),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: palette.mediaSurface,
                borderRadius: AppRadii.smAll,
              ),
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: palette.mediaMutedInk,
                  fontSize: AppTextSize.micro,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.check_rounded,
                color: palette.mediaInk,
                size: AppIconSize.sm,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArFilterCategory {
  const _ArFilterCategory({
    required this.id,
    required this.label,
    required this.matches,
  });

  final String id;
  final String label;
  final bool Function(ArFilterDefinition filter, Set<String> cachedFilterIds)
  matches;

  static const all = _ArFilterCategory(
    id: 'all',
    label: 'All',
    matches: _matchAllArFilters,
  );

  static const ready = _ArFilterCategory(
    id: 'ready',
    label: 'Ready',
    matches: _matchReadyArFilters,
  );

  static const featured = _ArFilterCategory(
    id: 'featured',
    label: 'Featured',
    matches: _matchFeaturedArFilters,
  );

  static const headwear = _ArFilterCategory(
    id: 'headwear',
    label: 'Headwear',
    matches: _matchHeadwearArFilters,
  );

  static const face = _ArFilterCategory(
    id: 'face',
    label: 'Face',
    matches: _matchFaceArFilters,
  );

  static const effects = _ArFilterCategory(
    id: 'effects',
    label: 'Effects',
    matches: _matchEffectsArFilters,
  );

  static List<_ArFilterCategory> visibleFor({
    required List<ArFilterDefinition> filters,
    required Set<String> cachedFilterIds,
  }) {
    final base = <_ArFilterCategory>[
      all,
      ready,
      featured,
      headwear,
      face,
      effects,
    ];
    return base
        .where(
          (category) =>
              category == all ||
              filters.any(
                (filter) => category.matches(filter, cachedFilterIds),
              ),
        )
        .toList(growable: false);
  }

  String localizedLabel(BuildContext context) => switch (id) {
    'all' => context.l10n.editorCategoryAll,
    'ready' => context.l10n.editorMusicReady,
    _ => label,
  };
}

bool _matchAllArFilters(
  ArFilterDefinition filter,
  Set<String> cachedFilterIds,
) => true;

bool _matchReadyArFilters(
  ArFilterDefinition filter,
  Set<String> cachedFilterIds,
) => cachedFilterIds.contains(filter.id);

bool _matchFeaturedArFilters(
  ArFilterDefinition filter,
  Set<String> cachedFilterIds,
) => filter.category == 'featured';

bool _matchHeadwearArFilters(
  ArFilterDefinition filter,
  Set<String> cachedFilterIds,
) => filter.category == 'headwear';

bool _matchFaceArFilters(
  ArFilterDefinition filter,
  Set<String> cachedFilterIds,
) => filter.category == 'face';

bool _matchEffectsArFilters(
  ArFilterDefinition filter,
  Set<String> cachedFilterIds,
) {
  return filter.category == 'effects' ||
      filter.category == 'sparkles' ||
      filter.category == 'magic';
}

IconData _iconForArFilter(ArFilterDefinition filter) {
  return switch (filter.category) {
    'headwear' => Icons.workspace_premium_rounded,
    'face' => Icons.face_retouching_natural_rounded,
    'effects' || 'sparkles' || 'magic' => Icons.auto_awesome_rounded,
    _ => Icons.face_retouching_natural_rounded,
  };
}

class _CaptureCircleBtn extends StatelessWidget {
  const _CaptureCircleBtn({
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final KidPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.mediaSurface,
        ),
        child: Icon(icon, color: palette.mediaInk, size: AppIconSize.xl),
      ),
    );
  }
}

class _LiveArFaceSmoother {
  static const _anchorLandmarks = <int>{1, 10, 33, 61, 152, 263, 291};
  static const _stillAlpha = 0.48;
  static const _fastAlpha = 0.88;
  static const _jumpThreshold = 0.045;
  static const _fastSpeed = 0.72;

  ArFaceResult? _previous;
  int? _previousAtMs;
  double _smoothedSpeed = 0;

  void reset() {
    _previous = null;
    _previousAtMs = null;
    _smoothedSpeed = 0;
  }

  List<ArFaceResult> smooth(List<ArFaceResult> faces) {
    if (faces.isEmpty) {
      reset();
      return const <ArFaceResult>[];
    }

    final current = faces.first;
    final previous = _previous;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (previous == null ||
        previous.landmarks.length != current.landmarks.length ||
        previous.imageSize != current.imageSize ||
        (previous.trackingId != null &&
            current.trackingId != null &&
            previous.trackingId != current.trackingId)) {
      _previous = current;
      _previousAtMs = nowMs;
      _smoothedSpeed = 0;
      return faces;
    }

    final previousCenter = previous.noseTip ?? previous.foreheadCenter;
    final currentCenter = current.noseTip ?? current.foreheadCenter;
    final jump = previousCenter == null || currentCenter == null
        ? 0.0
        : (currentCenter - previousCenter).distance;
    final dtSeconds = ((nowMs - (_previousAtMs ?? nowMs)).clamp(1, 500) / 1000);
    final speed = jump / dtSeconds;
    _smoothedSpeed = _smoothedSpeed * 0.65 + speed * 0.35;
    final speedT = (_smoothedSpeed / _fastSpeed).clamp(0.0, 1.0);
    final adaptiveAlpha =
        _stillAlpha + (_fastAlpha - _stillAlpha) * speedT.toDouble();
    final scorePenalty = current.score < 0.58 ? 0.08 : 0.0;
    final alpha = jump > _jumpThreshold
        ? _fastAlpha
        : (adaptiveAlpha - scorePenalty)
              .clamp(_stillAlpha, _fastAlpha)
              .toDouble();
    final smoothed = _smoothFace(
      previous: previous,
      current: current,
      alpha: alpha,
    );
    _previous = smoothed;
    _previousAtMs = nowMs;
    return <ArFaceResult>[smoothed, ...faces.skip(1)];
  }

  ArFaceResult _smoothFace({
    required ArFaceResult previous,
    required ArFaceResult current,
    required double alpha,
  }) {
    final landmarks = List<FaceMeshLandmark>.of(current.landmarks);
    for (final index in _anchorLandmarks) {
      if (index >= current.landmarks.length ||
          index >= previous.landmarks.length) {
        continue;
      }
      landmarks[index] = _lerpLandmark(
        previous.landmarks[index],
        current.landmarks[index],
        alpha,
      );
    }

    return ArFaceResult(
      boundingBox: _lerpBox(previous.boundingBox, current.boundingBox, alpha),
      landmarks: landmarks,
      score: current.score,
      imageSize: current.imageSize,
      trackingId: current.trackingId,
      headEulerY: _lerpNullable(previous.headEulerY, current.headEulerY, alpha),
      headEulerZ: _lerpNullable(previous.headEulerZ, current.headEulerZ, alpha),
    );
  }

  FaceMeshLandmark _lerpLandmark(
    FaceMeshLandmark previous,
    FaceMeshLandmark current,
    double alpha,
  ) {
    return FaceMeshLandmark(
      x: _lerp(previous.x, current.x, alpha),
      y: _lerp(previous.y, current.y, alpha),
      z: _lerp(previous.z, current.z, alpha),
    );
  }

  FaceMeshBox _lerpBox(
    FaceMeshBox previous,
    FaceMeshBox current,
    double alpha,
  ) {
    return FaceMeshBox(
      left: _lerp(previous.left, current.left, alpha),
      top: _lerp(previous.top, current.top, alpha),
      right: _lerp(previous.right, current.right, alpha),
      bottom: _lerp(previous.bottom, current.bottom, alpha),
    );
  }

  double? _lerpNullable(double? previous, double? current, double alpha) {
    if (previous == null || current == null) {
      return current;
    }
    return _lerp(previous, current, alpha);
  }

  double _lerp(double previous, double current, double alpha) {
    return previous + (current - previous) * alpha;
  }
}

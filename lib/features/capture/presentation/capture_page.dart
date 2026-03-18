import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/providers.dart';
import '../../../services/media/video_probe_service.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/theme/theme_descriptor.dart';
import '../../../domain/models/content_scan_summary.dart';
import '../../../shared_ui/components/fill_camera_preview.dart';
import '../../../shared_ui/motion/app_motion.dart';
import '../../editor/presentation/editor_detail_page.dart';
import '../../player/presentation/player_page.dart';

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
  _CaptureWorkflowState? _workflowState;
  LocalVideo? _lastSavedVideo;
  final Uuid _uuid = const Uuid();

  // Recording timer
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Zoom
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;
  bool _cameraInitStarted = false;
  bool _cameraDisposeStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isActiveTab = ref.read(appShellTabIndexProvider) == 1;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _controller;
      if (controller == null) {
        return;
      }
      _controller = null;
      _currentZoom = 1.0;
      _cameraDisposeStarted = false;
      unawaited(controller.dispose());
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
        await _initCamera(_cameras.first);
      } else if (mounted) {
        setState(
          () => _errorMessage =
              'We couldn\'t find a camera on this device right now.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _cameraErrorMessage(e));
    } finally {
      _cameraInitStarted = false;
    }
  }

  Future<void> _initCamera(CameraDescription desc) async {
    if (_isRecording) return;
    await _controller?.dispose();
    final ctrl = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await ctrl.initialize();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _cameraErrorMessage(e));
      return;
    }
    if (!mounted) {
      await ctrl.dispose();
      return;
    }
    setState(() {
      _controller = ctrl;
      _currentZoom = 1.0;
      _errorMessage = null;
      _cameraDisposeStarted = false;
    });
  }

  void _flipCamera() {
    if (_cameras.length < 2 || _isRecording) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _initCamera(_cameras[_cameraIndex]);
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
      await ctrl.lockCaptureOrientation();
      await ctrl.startVideoRecording();
      if (!mounted) return;
      _recordingSeconds = 0;
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds++);
      });
      setState(() {
        _isRecording = true;
        _errorMessage = null;
      });
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
      setState(() => _errorMessage = _cameraErrorMessage(error));
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
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _errorMessage = 'Choose a child profile before recording a clip.';
      });
      return;
    }

    try {
      final recording = await ctrl.stopVideoRecording();
      await ctrl.unlockCaptureOrientation();
      final savedPath = await _persistRecording(recording);
      final videoId = _uuid.v4();
      final thumbPath = await ref
          .read(thumbnailServiceProvider)
          .createVideoThumbnail(videoPath: savedPath);
      final ts = DateTime.now();
      final capturedSeconds = _recordingSeconds > 0
          ? _recordingSeconds.toDouble()
          : 1.0;
      if (mounted) {
        setState(() {
          _workflowState = const _CaptureWorkflowState(
            stage: _CaptureWorkflowStage.processing,
            headline: 'Finishing your clip',
            detail: 'Preparing the video and thumbnail for your library.',
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
            tags: const ['captured'],
            approvalStatus: 'pending',
            aspectRatio: videoAspectRatio,
          );
      if (mounted) {
        setState(() {
          _workflowState = const _CaptureWorkflowState(
            stage: _CaptureWorkflowStage.scanning,
            headline: 'Checking your clip',
            detail: 'Running an on-device safety scan before sharing.',
          );
        });
      }
      final scan = await ref
          .read(videoApprovalServiceProvider)
          .scanAndClassifyVideo(videoId: videoId);
      final savedVideo = await ref
          .read(appDatabaseProvider)
          .getLocalVideoById(videoId);

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isSaving = false;
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
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _errorMessage = _cameraErrorMessage(e);
      });
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

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(appShellTabIndexProvider);
    if (activeTab == 1 && !_cameraInitStarted && _controller == null) {
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
        _controller != null &&
        !_isRecording &&
        !_cameraDisposeStarted) {
      _cameraDisposeStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final controller = _controller;
        if (!mounted || controller == null || _isRecording) {
          _cameraDisposeStarted = false;
          return;
        }
        await controller.dispose();
        if (!mounted) {
          return;
        }
        setState(() {
          _controller = null;
          _currentZoom = 1.0;
          _cameraDisposeStarted = false;
        });
      });
    }
    final palette = ref.watch(activeThemeProvider).palette;
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
              child: FillCameraPreview(controller: ctrl),
            ),
          )
        else
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white38),
                        const SizedBox(height: 18),
                        Text(
                          _errorMessage == null
                              ? 'Opening camera'
                              : 'Camera needs attention',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ??
                              'Getting everything ready so you can record a new clip.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Header overlay
        Positioned(
          top: topPad + 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Zoom badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentZoom.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const Spacer(),
              // Torch toggle
              _CaptureCircleBtn(
                icon: isTorch
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                onTap: _toggleTorch,
              ),
              const SizedBox(width: 12),
              // Camera flip
              _CaptureCircleBtn(
                icon: Icons.cameraswitch_rounded,
                onTap: _flipCamera,
              ),
            ],
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
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(_recordingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordingSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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
                      border: Border.all(color: Colors.white, width: 6),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: AnimatedContainer(
                      duration: stateChangeDuration,
                      curve: AppMotion.easeOutQuint,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(
                          _isRecording ? 8 : 30,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: palette.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Video Saved!',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Error banner
        if (_errorMessage != null)
          Positioned(
            top: topPad + 60,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: () => setState(() => _errorMessage = null),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xCC4B2B2E),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x66F3B0A4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFFFD5C7),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
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
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: _CaptureWorkflowOverlay(
                  state:
                      _workflowState ??
                      const _CaptureWorkflowState(
                        stage: _CaptureWorkflowStage.preparing,
                        headline: 'Preparing camera',
                        detail: 'Getting everything ready.',
                      ),
                ),
              ),
            ),
          ),

        if (_workflowState != null && !_isSaving && _lastSavedVideo != null)
          Positioned(
            left: 16,
            right: 16,
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
              },
              onOpenPlayer: () {
                final video = _lastSavedVideo;
                if (video == null) {
                  return;
                }
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  AppMotion.modalRoute(
                    context: context,
                    builder: (_) => PlayerPage(videoId: video.id),
                  ),
                );
              },
              onOpenEditor: () {
                final video = _lastSavedVideo;
                if (video == null) {
                  return;
                }
                HapticFeedback.selectionClick();
                Navigator.of(context).push(
                  AppMotion.modalRoute(
                    context: context,
                    builder: (_) => EditorDetailPage(video: video),
                  ),
                );
              },
              onShareNow: _shareLastSavedVideo,
            ),
          ),
      ],
    );
  }

  _CaptureWorkflowState _buildFinishedWorkflowState(ContentScanSummary scan) {
    if (scan.needsReview) {
      return _CaptureWorkflowState(
        stage: _CaptureWorkflowStage.complete,
        headline: 'Saved, but needs a parent look',
        detail: scan.summary,
        canShare: false,
      );
    }
    return _CaptureWorkflowState(
      stage: _CaptureWorkflowStage.complete,
      headline: 'Clip ready',
      detail:
          'Your clip is saved, scanned, and ready to edit, watch, or share.',
      canShare: true,
    );
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
        _errorMessage = 'Finish parent setup before sharing this clip.';
      });
      return;
    }

    setState(() => _isRunningQuickShare = true);
    final messenger = ScaffoldMessenger.of(context);
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
      await HapticFeedback.mediumImpact();
      final shared = result.sharedGroupCount;
      final queued = result.queuedGroupCount;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            queued == 0
                ? 'Shared "${video.title}" with $shared family space${shared == 1 ? '' : 's'}'
                : 'Shared to $shared family space${shared == 1 ? '' : 's'}, queued $queued more',
          ),
        ),
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

  String _cameraErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('access') || message.contains('permission')) {
      return 'Camera or microphone access is still turned off. Allow access in Settings, then try again.';
    }
    if (message.contains('camera') && message.contains('in use')) {
      return 'The camera is busy right now. Close any other app using it and try again.';
    }
    if (message.contains('profile')) {
      return 'Choose a child profile before recording a clip.';
    }
    return 'We couldn\'t start the camera just yet. Give it another try.';
  }

  String _shareErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('parent') || message.contains('identity')) {
      return 'Finish parent setup before sharing clips with family.';
    }
    if (message.contains('approval')) {
      return 'This clip needs a parent review before it can be shared.';
    }
    if (message.contains('group') || message.contains('family')) {
      return 'Connect with a family space first, then you can share this clip.';
    }
    return 'We couldn\'t share that clip yet. It\'s still saved safely here.';
  }
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
  const _CaptureWorkflowOverlay({required this.state});

  final _CaptureWorkflowState state;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AppMotion.reduceMotion(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                child: Icon(
                  _iconForStage(state.stage),
                  key: ValueKey(state.stage),
                  size: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                child: Text(
                  state.headline,
                  key: ValueKey(state.headline),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.stateChange),
                child: Text(
                  state.detail,
                  key: ValueKey(state.detail),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _CaptureWorkflowStage.values
                    .map(
                      (stage) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: AnimatedContainer(
                          duration: AppMotion.duration(
                            context,
                            AppMotion.stateChange,
                          ),
                          curve: AppMotion.easeOutQuint,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isStageComplete(stage)
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isStageComplete(stage)
                                  ? Colors.white24
                                  : Colors.white10,
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
                              size: 18,
                              color: _isStageComplete(stage)
                                  ? Colors.white
                                  : Colors.white38,
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
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white24),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
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
                          color: palette.accent.withValues(alpha: 0.18),
                        ),
                        child: Icon(
                          state.canShare
                              ? Icons.check_circle_rounded
                              : Icons.shield_outlined,
                          color: palette.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.headline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.detail,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onDismiss,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: onOpenPlayer,
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: const Text('Watch'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onOpenEditor,
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: const Text('Edit'),
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
                          state.canShare ? 'Share now' : 'Review first',
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

class _CaptureCircleBtn extends StatelessWidget {
  const _CaptureCircleBtn({required this.icon, required this.onTap});

  final IconData icon;
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
          color: Colors.black.withValues(alpha: 0.4),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

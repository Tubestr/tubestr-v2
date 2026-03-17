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
import '../../../core/theme/theme_descriptor.dart';

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
  String? _errorMessage;
  final Uuid _uuid = const Uuid();

  // Recording timer
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Zoom
  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
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
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initCamera(_cameras.first);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '$e');
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
      if (mounted) setState(() => _errorMessage = '$e');
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
        _errorMessage = 'No profile selected';
      });
      return;
    }

    try {
      final recording = await ctrl.stopVideoRecording();
      final savedPath = await _persistRecording(recording);
      final videoId = _uuid.v4();
      final thumbPath = await ref
          .read(thumbnailServiceProvider)
          .createVideoThumbnail(videoPath: savedPath);
      final ts = DateTime.now();
      await ref
          .read(appDatabaseProvider)
          .saveLocalVideo(
            videoId: videoId,
            profileId: activeProfile.id,
            filePath: savedPath,
            thumbPath: thumbPath ?? '',
            title:
                'Clip ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
            tags: const ['captured'],
            approvalStatus: 'pending',
          );
      await ref
          .read(videoApprovalServiceProvider)
          .scanAndClassifyVideo(videoId: videoId);

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _showSavedBanner = true;
      });
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _showSavedBanner = false);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isSaving = false;
        _errorMessage = '$e';
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
    final palette = ref.watch(activeThemeProvider).palette;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final ctrl = _controller;
    final isReady = ctrl != null && ctrl.value.isInitialized;
    final isTorch = ctrl?.value.flashMode == FlashMode.torch;

    return Stack(
      children: [
        // Camera preview (fills entire screen)
        if (isReady)
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: CameraPreview(ctrl),
            ),
          )
        else
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white38),
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
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(
                        _isRecording ? 8 : 30,
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
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
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
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ),

        // Saving overlay
        if (_isSaving)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Saving clip\u2026',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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

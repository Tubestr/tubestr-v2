import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/theme_descriptor.dart';
import '../../../services/editor/editor_sticker_library.dart';
import '../../../services/editor/selfie_segmentation_service.dart';
import '../../../shared_ui/components/fill_camera_preview.dart';
import '../../../l10n/l10n.dart';

class SelfieStickerCapturePage extends StatefulWidget {
  const SelfieStickerCapturePage({
    super.key,
    required this.profileId,
    required this.palette,
    required this.stickerLibrary,
  });

  final String profileId;
  final KidPalette palette;
  final EditorStickerLibrary stickerLibrary;

  @override
  State<SelfieStickerCapturePage> createState() =>
      _SelfieStickerCapturePageState();
}

class _SelfieStickerCapturePageState extends State<SelfieStickerCapturePage>
    with WidgetsBindingObserver {
  final SelfieSegmentationService _segmentationService =
      SelfieSegmentationService();
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;
  Uint8List? _previewStickerPng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    unawaited(_segmentationService.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_previewStickerPng != null || _isProcessing) {
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _controller;
      if (controller == null) {
        return;
      }
      _controller = null;
      unawaited(controller.dispose());
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (state == AppLifecycleState.resumed) {
      if (_isInitializing) {
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
    try {
      _cameras = await availableCameras();
      final frontIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIndex == -1 ? 0 : frontIndex;
      if (_cameras.isNotEmpty) {
        await _initCamera(_cameras[_cameraIndex]);
      }
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = _cameraErrorMessage(error);
        });
      }
    }
  }

  Future<void> _initCamera(CameraDescription description) async {
    await _controller?.dispose();
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _errorMessage = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isProcessing) {
      return;
    }
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera(_cameras[_cameraIndex]);
  }

  Future<void> _captureAndSegment() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final photo = await controller.takePicture();
      final pngBytes = await _segmentationService.extractStickerPng(photo.path);
      if (pngBytes == null) {
        throw StateError('Could not lift the subject from that photo.');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _previewStickerPng = pngBytes;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _captureErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveSticker() async {
    final pngBytes = _previewStickerPng;
    if (pngBytes == null || _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final sticker = await widget.stickerLibrary.saveStickerPng(
        profileId: widget.profileId,
        pngBytes: pngBytes,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(sticker);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = _saveErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: _previewStickerPng != null
                  ? _StickerPreview(
                      pngBytes: _previewStickerPng!,
                      palette: widget.palette,
                    )
                  : isReady
                  ? FillCameraPreview(controller: controller)
                  : const ColoredBox(color: Colors.black),
            ),
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _CircleChromeButton(
                    icon: Icons.close_rounded,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (_previewStickerPng == null)
                    _CircleChromeButton(
                      icon: Icons.cameraswitch_rounded,
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ),
            if (_previewStickerPng == null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 42,
                child: Column(
                  children: [
                    Text(
                      context.l10n.editorStickerPhotoTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _isInitializing || _isProcessing
                          ? null
                          : _captureAndSegment,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.palette.accent,
                            width: 4,
                          ),
                        ),
                        child: const Center(
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Positioned(
                left: 24,
                right: 24,
                bottom: 42,
                child: Column(
                  children: [
                    Text(
                      context.l10n.editorStickerPreviewPrompt,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonal(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  setState(() {
                                    _previewStickerPng = null;
                                    _errorMessage = null;
                                  });
                                },
                          child: Text(context.l10n.editorActionRetake),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isProcessing ? null : _saveSticker,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.palette.accent,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(context.l10n.editorActionUseSticker),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              Positioned(
                left: 24,
                right: 24,
                top: 96,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isInitializing || _isProcessing)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _cameraErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('access') || message.contains('permission')) {
      return context.l10n.editorSelfieCameraDenied;
    }
    return context.l10n.editorSelfieCameraFailed;
  }

  String _captureErrorMessage(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('subject')) {
      return context.l10n.editorStickerLiftFailed;
    }
    return context.l10n.editorStickerCreateFailed;
  }

  String _saveErrorMessage(Object error) {
    return context.l10n.editorStickerSaveFailed;
  }
}

class _CircleChromeButton extends StatelessWidget {
  const _CircleChromeButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _StickerPreview extends StatelessWidget {
  const _StickerPreview({required this.pngBytes, required this.palette});

  final Uint8List pngBytes;
  final KidPalette palette;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                palette.accent.withValues(alpha: 0.24),
                palette.accentSecondary.withValues(alpha: 0.22),
                Colors.black,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        CustomPaint(painter: _CheckerPainter()),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Image.memory(pngBytes, fit: BoxFit.contain),
        ),
      ],
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 24.0;
    final light = Paint()..color = const Color(0x22FFFFFF);
    final dark = Paint()..color = const Color(0x12000000);

    for (var y = 0.0; y < size.height; y += tile) {
      for (var x = 0.0; x < size.width; x += tile) {
        final isLight = (((x / tile).floor() + (y / tile).floor()) % 2) == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tile, tile),
          isLight ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

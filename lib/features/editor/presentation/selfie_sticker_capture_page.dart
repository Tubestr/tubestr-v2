import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

import '../../../core/theme/theme_descriptor.dart';
import '../../../services/editor/editor_sticker_library.dart';

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

class _SelfieStickerCapturePageState extends State<SelfieStickerCapturePage> {
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
    _initCameras();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
          _errorMessage = '$error';
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
      final pngBytes = await _extractStickerPng(photo.path);
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
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<Uint8List?> _extractStickerPng(String path) async {
    final segmenter = SelfieSegmenter(mode: SegmenterMode.single);
    try {
      final inputImage = InputImage.fromFilePath(path);
      final mask = await segmenter.processImage(inputImage);
      if (mask == null) {
        return null;
      }

      final imageBytes = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final rgbaByteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rgbaByteData == null) {
        return null;
      }

      final sourceBytes = rgbaByteData.buffer.asUint8List();
      final outputBytes = Uint8List(sourceBytes.length);
      final width = image.width;
      final height = image.height;
      const threshold = 0.35;

      for (var y = 0; y < height; y += 1) {
        for (var x = 0; x < width; x += 1) {
          final sourcePixelIndex = (y * width + x) * 4;
          final maskX = (x / width * mask.width).floor().clamp(
            0,
            mask.width - 1,
          );
          final maskY = (y / height * mask.height).floor().clamp(
            0,
            mask.height - 1,
          );
          final maskConfidence = mask.confidences[maskY * mask.width + maskX];
          if (maskConfidence >= threshold) {
            outputBytes[sourcePixelIndex] = sourceBytes[sourcePixelIndex];
            outputBytes[sourcePixelIndex + 1] =
                sourceBytes[sourcePixelIndex + 1];
            outputBytes[sourcePixelIndex + 2] =
                sourceBytes[sourcePixelIndex + 2];
            outputBytes[sourcePixelIndex + 3] = (maskConfidence * 255)
                .round()
                .clamp(0, 255);
          } else {
            outputBytes[sourcePixelIndex] = 0;
            outputBytes[sourcePixelIndex + 1] = 0;
            outputBytes[sourcePixelIndex + 2] = 0;
            outputBytes[sourcePixelIndex + 3] = 0;
          }
        }
      }

      final stickerImage = await _imageFromRgba(
        outputBytes,
        width: width,
        height: height,
      );
      final pngByteData = await stickerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return pngByteData?.buffer.asUint8List();
    } finally {
      await segmenter.close();
    }
  }

  Future<ui.Image> _imageFromRgba(
    Uint8List bytes, {
    required int width,
    required int height,
  }) async {
    final codec = await ui.instantiateImageCodec(
      await _encodeRawRgbaToBmp(bytes, width: width, height: height),
    );
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List> _encodeRawRgbaToBmp(
    Uint8List rgbaBytes, {
    required int width,
    required int height,
  }) async {
    final buffer = BytesBuilder();
    final pixelDataSize = width * height * 4;
    final fileSize = 54 + pixelDataSize;

    void writeInt16(int value) {
      buffer.add([value & 0xFF, (value >> 8) & 0xFF]);
    }

    void writeInt32(int value) {
      buffer.add([
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ]);
    }

    buffer.add([0x42, 0x4D]);
    writeInt32(fileSize);
    writeInt16(0);
    writeInt16(0);
    writeInt32(54);

    writeInt32(40);
    writeInt32(width);
    writeInt32(-height);
    writeInt16(1);
    writeInt16(32);
    writeInt32(0);
    writeInt32(pixelDataSize);
    writeInt32(2835);
    writeInt32(2835);
    writeInt32(0);
    writeInt32(0);

    for (var i = 0; i < rgbaBytes.length; i += 4) {
      final r = rgbaBytes[i];
      final g = rgbaBytes[i + 1];
      final b = rgbaBytes[i + 2];
      final a = rgbaBytes[i + 3];
      buffer.add([b, g, r, a]);
    }

    return buffer.toBytes();
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
      setState(() => _errorMessage = '$error');
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
                  ? CameraPreview(controller)
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
                      'Take a photo to create a sticker',
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
                      'Looking good! Use it as a sticker?',
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
                          child: const Text('Retake'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _isProcessing ? null : _saveSticker,
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.palette.accent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Use Sticker'),
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

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../../l10n/l10n.dart';
import 'fill_camera_preview.dart';

class QrScannerSheet extends StatefulWidget {
  const QrScannerSheet({super.key, this.title, this.instructions});

  final String? title;
  final String? instructions;

  @override
  State<QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<QrScannerSheet>
    with WidgetsBindingObserver {
  static const Map<DeviceOrientation, int> _deviceOrientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraController? _controller;
  CameraDescription? _camera;
  BarcodeScanner? _scanner;
  bool _hasScanned = false;
  bool _isDetecting = false;
  bool _streaming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_teardown());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_hasScanned) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_stopStream());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_startStream());
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _errorMessage = context.l10n.qrNoCamera);
        }
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _scanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
      setState(() {
        _controller = controller;
        _camera = camera;
      });
      await _startStream();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = context.l10n.qrOpenCameraFailed('$error'));
    }
  }

  Future<void> _startStream() async {
    final controller = _controller;
    if (controller == null || _streaming || _hasScanned) return;
    try {
      await controller.startImageStream(_onCameraImage);
      _streaming = true;
    } catch (error) {
      debugPrint('QR camera stream start failed: $error');
    }
  }

  Future<void> _stopStream() async {
    final controller = _controller;
    if (controller == null || !_streaming) return;
    _streaming = false;
    try {
      await controller.stopImageStream();
    } catch (error) {
      debugPrint('QR camera stream stop failed: $error');
    }
  }

  Future<void> _teardown() async {
    await _stopStream();
    await _controller?.dispose();
    await _scanner?.close();
    _controller = null;
    _scanner = null;
  }

  void _onCameraImage(CameraImage image) {
    if (_hasScanned || _isDetecting) return;
    _isDetecting = true;
    _detect(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _detect(CameraImage image) async {
    final scanner = _scanner;
    final controller = _controller;
    final camera = _camera;
    if (scanner == null ||
        controller == null ||
        camera == null ||
        _hasScanned) {
      return;
    }
    final inputImage = _toInputImage(image, controller, camera);
    if (inputImage == null) return;
    try {
      final barcodes = await scanner.processImage(inputImage);
      for (final barcode in barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.isNotEmpty) {
          if (!mounted || _hasScanned) return;
          _hasScanned = true;
          unawaited(_stopStream());
          Navigator.of(context).pop(raw);
          return;
        }
      }
    } catch (error) {
      debugPrint('QR decode failed: $error');
    }
  }

  InputImage? _toInputImage(
    CameraImage image,
    CameraController controller,
    CameraDescription camera,
  ) {
    final InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    } else {
      final deviceDegrees =
          _deviceOrientationDegrees[controller.value.deviceOrientation];
      if (deviceDegrees == null) return null;
      final int compensated;
      if (camera.lensDirection == CameraLensDirection.front) {
        compensated = (camera.sensorOrientation + deviceDegrees) % 360;
      } else {
        compensated = (camera.sensorOrientation - deviceDegrees + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(compensated);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
    if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;
    if (image.planes.isEmpty) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final error = _errorMessage;
    final l10n = context.l10n;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              widget.title ?? l10n.scanQrTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: ColoredBox(
                    color: Colors.black,
                    child: error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                error,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : (controller == null ||
                              !controller.value.isInitialized)
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : FillCameraPreview(controller: controller),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.instructions ?? l10n.scanQrInstructions,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

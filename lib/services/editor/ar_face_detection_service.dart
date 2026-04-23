import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';

import '../../domain/models/ar_face_result.dart';

class ArFaceDetectionService {
  static const Map<DeviceOrientation, int> _deviceOrientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  FaceDetector? _detector;
  FaceMeshProcessor? _meshProcessor;
  Future<void>? _initFuture;
  bool _isProcessing = false;

  Future<void> init() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        enableTracking: true,
      ),
    );
    _meshProcessor = await FaceMeshProcessor.create(
      delegate: FaceMeshDelegate.xnnpack,
    );
  }

  Future<List<ArFaceResult>?> processCameraImage({
    required CameraImage image,
    required CameraController controller,
    required CameraDescription camera,
  }) async {
    if (_isProcessing) {
      return null;
    }
    _isProcessing = true;
    try {
      await init();
      final detector = _detector;
      final meshProcessor = _meshProcessor;
      if (detector == null || meshProcessor == null) {
        return const <ArFaceResult>[];
      }

      final rotationDegrees = _rotationDegrees(
        controller: controller,
        camera: camera,
      );
      if (rotationDegrees == null) {
        return const <ArFaceResult>[];
      }
      final rotation = InputImageRotationValue.fromRawValue(rotationDegrees);
      if (rotation == null) {
        return const <ArFaceResult>[];
      }

      final androidNv21Frame = Platform.isAndroid
          ? _buildAndroidNv21Frame(image)
          : null;
      if (Platform.isAndroid && androidNv21Frame == null) {
        return const <ArFaceResult>[];
      }

      final inputImage = _toInputImage(
        image: image,
        rotation: rotation,
        androidNv21Frame: androidNv21Frame,
      );
      if (inputImage == null) {
        return const <ArFaceResult>[];
      }

      final faces = await detector.processImage(inputImage);
      if (faces.isEmpty) {
        return const <ArFaceResult>[];
      }

      final results = <ArFaceResult>[];
      for (final face in faces.take(1)) {
        final mesh = _processMesh(
          meshProcessor: meshProcessor,
          image: image,
          face: face,
          rotation: rotation,
          rotationDegrees: rotationDegrees,
          androidNv21Frame: androidNv21Frame,
        );
        if (mesh == null || mesh.landmarks.isEmpty || mesh.score < 0.45) {
          continue;
        }
        final box = _clampedFaceMeshBox(
          face: face,
          image: image,
          rotation: rotation,
        );
        results.add(
          ArFaceResult(
            boundingBox: box,
            landmarks: mesh.landmarks,
            score: mesh.score,
            imageSize: Size(
              mesh.imageWidth.toDouble(),
              mesh.imageHeight.toDouble(),
            ),
            trackingId: face.trackingId,
            headEulerY: face.headEulerAngleY,
            headEulerZ: face.headEulerAngleZ,
          ),
        );
      }
      return results;
    } catch (error) {
      _log('AR face detection failed: $error');
      return const <ArFaceResult>[];
    } finally {
      _isProcessing = false;
    }
  }

  FaceMeshResult? _processMesh({
    required FaceMeshProcessor meshProcessor,
    required CameraImage image,
    required Face face,
    required InputImageRotation rotation,
    required int rotationDegrees,
    _AndroidNv21Frame? androidNv21Frame,
  }) {
    final box = _clampedFaceMeshBox(
      face: face,
      image: image,
      rotation: rotation,
    );
    if (box.width <= 0 || box.height <= 0) {
      return null;
    }
    if (Platform.isAndroid) {
      if (androidNv21Frame == null) {
        return null;
      }
      return meshProcessor.processNv21(
        FaceMeshNv21Image(
          yPlane: androidNv21Frame.yPlane,
          vuPlane: androidNv21Frame.vuPlane,
          width: androidNv21Frame.width,
          height: androidNv21Frame.height,
          yBytesPerRow: androidNv21Frame.yBytesPerRow,
          vuBytesPerRow: androidNv21Frame.vuBytesPerRow,
        ),
        box: box,
        boxScale: 1.2,
        boxMakeSquare: true,
        rotationDegrees: rotationDegrees,
      );
    }
    if (Platform.isIOS) {
      final bgra = _buildBgraImage(image);
      if (bgra == null) {
        return null;
      }
      return meshProcessor.process(
        bgra,
        box: box,
        boxScale: 1.2,
        boxMakeSquare: true,
        rotationDegrees: rotationDegrees,
      );
    }
    return null;
  }

  InputImage? _toInputImage({
    required CameraImage image,
    required InputImageRotation rotation,
    _AndroidNv21Frame? androidNv21Frame,
  }) {
    if (Platform.isAndroid) {
      if (androidNv21Frame == null) {
        return null;
      }
      return InputImage.fromBytes(
        bytes: androidNv21Frame.bytes,
        metadata: InputImageMetadata(
          size: Size(
            androidNv21Frame.width.toDouble(),
            androidNv21Frame.height.toDouble(),
          ),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: androidNv21Frame.yBytesPerRow,
        ),
      );
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        format != InputImageFormat.bgra8888 ||
        image.planes.isEmpty) {
      return null;
    }

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

  _AndroidNv21Frame? _buildAndroidNv21Frame(CameraImage image) {
    if (!Platform.isAndroid || image.planes.isEmpty) {
      return null;
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == InputImageFormat.nv21 || image.planes.length == 1) {
      return _buildNv21FrameFromNv21Planes(image);
    }
    if (format == InputImageFormat.yuv_420_888) {
      return _buildNv21FrameFromYuv420(image);
    }
    return null;
  }

  _AndroidNv21Frame? _buildNv21FrameFromNv21Planes(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvHeight = (height + 1) ~/ 2;
    final planes = image.planes;
    if (planes.length >= 2) {
      final yPlane = planes[0];
      final vuPlane = planes[1];
      final yLength = yPlane.bytesPerRow * height;
      final vuLength = vuPlane.bytesPerRow * uvHeight;
      if (yPlane.bytes.length < yLength || vuPlane.bytes.length < vuLength) {
        return null;
      }
      final bytes = Uint8List(yLength + vuLength);
      bytes.setRange(0, yLength, yPlane.bytes);
      bytes.setRange(yLength, yLength + vuLength, vuPlane.bytes);
      return _AndroidNv21Frame(
        bytes: bytes,
        yPlane: Uint8List.sublistView(bytes, 0, yLength),
        vuPlane: Uint8List.sublistView(bytes, yLength, yLength + vuLength),
        width: width,
        height: height,
        yBytesPerRow: yPlane.bytesPerRow,
        vuBytesPerRow: vuPlane.bytesPerRow,
      );
    }
    if (planes.length == 1) {
      final plane = planes.first;
      final rowStride = plane.bytesPerRow;
      final ySize = rowStride * height;
      final vuSize = rowStride * uvHeight;
      if (plane.bytes.length < ySize + vuSize) {
        return null;
      }
      final bytes = Uint8List.sublistView(plane.bytes, 0, ySize + vuSize);
      return _AndroidNv21Frame(
        bytes: bytes,
        yPlane: Uint8List.sublistView(bytes, 0, ySize),
        vuPlane: Uint8List.sublistView(bytes, ySize, ySize + vuSize),
        width: width,
        height: height,
        yBytesPerRow: rowStride,
        vuBytesPerRow: rowStride,
      );
    }
    return null;
  }

  _AndroidNv21Frame? _buildNv21FrameFromYuv420(CameraImage image) {
    if (image.planes.length < 3) {
      return null;
    }
    final width = image.width;
    final height = image.height;
    final uvWidth = (width + 1) ~/ 2;
    final uvHeight = (height + 1) ~/ 2;
    final vuBytesPerRow = uvWidth * 2;
    final ySize = width * height;
    final vuSize = vuBytesPerRow * uvHeight;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    final packedY = Uint8List(ySize);
    final packedVu = Uint8List(vuSize);

    for (var row = 0; row < height; row++) {
      final yRowStart = row * yPlane.bytesPerRow;
      for (var col = 0; col < width; col++) {
        final yIndex = yRowStart + (col * yPixelStride);
        if (yIndex >= yPlane.bytes.length) {
          return null;
        }
        packedY[row * width + col] = yPlane.bytes[yIndex];
      }
    }

    for (var row = 0; row < uvHeight; row++) {
      final uRowStart = row * uPlane.bytesPerRow;
      final vRowStart = row * vPlane.bytesPerRow;
      for (var col = 0; col < uvWidth; col++) {
        final uIndex = uRowStart + (col * uPixelStride);
        final vIndex = vRowStart + (col * vPixelStride);
        if (uIndex >= uPlane.bytes.length || vIndex >= vPlane.bytes.length) {
          return null;
        }
        final dst = row * vuBytesPerRow + (col * 2);
        packedVu[dst] = vPlane.bytes[vIndex];
        packedVu[dst + 1] = uPlane.bytes[uIndex];
      }
    }

    final bytes = Uint8List(ySize + vuSize);
    bytes.setRange(0, ySize, packedY);
    bytes.setRange(ySize, ySize + vuSize, packedVu);
    return _AndroidNv21Frame(
      bytes: bytes,
      yPlane: Uint8List.sublistView(bytes, 0, ySize),
      vuPlane: Uint8List.sublistView(bytes, ySize, ySize + vuSize),
      width: width,
      height: height,
      yBytesPerRow: width,
      vuBytesPerRow: vuBytesPerRow,
    );
  }

  FaceMeshImage? _buildBgraImage(CameraImage image) {
    if (!Platform.isIOS || image.planes.isEmpty) {
      return null;
    }
    final plane = image.planes.first;
    return FaceMeshImage(
      pixels: plane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
      pixelFormat: FaceMeshPixelFormat.bgra,
    );
  }

  FaceMeshBox _clampedFaceMeshBox({
    required Face face,
    required CameraImage image,
    required InputImageRotation rotation,
  }) {
    final adjustedSize = _adjustedImageSize(
      Size(image.width.toDouble(), image.height.toDouble()),
      rotation,
    );
    final bounds = face.boundingBox;
    final left = bounds.left.clamp(0.0, adjustedSize.width).toDouble();
    final top = bounds.top.clamp(0.0, adjustedSize.height).toDouble();
    final right = bounds.right.clamp(0.0, adjustedSize.width).toDouble();
    final bottom = bounds.bottom.clamp(0.0, adjustedSize.height).toDouble();
    return FaceMeshBox(left: left, top: top, right: right, bottom: bottom);
  }

  Size _adjustedImageSize(Size imageSize, InputImageRotation rotation) {
    if (rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg) {
      return Size(imageSize.height, imageSize.width);
    }
    return imageSize;
  }

  int? _rotationDegrees({
    required CameraController controller,
    required CameraDescription camera,
  }) {
    if (Platform.isIOS) {
      return camera.sensorOrientation;
    }
    final deviceDegrees =
        _deviceOrientationDegrees[controller.value.deviceOrientation];
    if (deviceDegrees == null) {
      return null;
    }
    if (camera.lensDirection == CameraLensDirection.front) {
      return (camera.sensorOrientation + deviceDegrees) % 360;
    }
    return (camera.sensorOrientation - deviceDegrees + 360) % 360;
  }

  Future<void> dispose() async {
    await _detector?.close();
    _meshProcessor?.close();
    _detector = null;
    _meshProcessor = null;
    _initFuture = null;
  }

  void _log(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint(message);
  }
}

class _AndroidNv21Frame {
  const _AndroidNv21Frame({
    required this.bytes,
    required this.yPlane,
    required this.vuPlane,
    required this.width,
    required this.height,
    required this.yBytesPerRow,
    required this.vuBytesPerRow,
  });

  final Uint8List bytes;
  final Uint8List yPlane;
  final Uint8List vuPlane;
  final int width;
  final int height;
  final int yBytesPerRow;
  final int vuBytesPerRow;
}

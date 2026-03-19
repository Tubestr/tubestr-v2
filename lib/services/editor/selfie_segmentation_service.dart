import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SelfieSegmentationService {
  SelfieSegmentationService({
    MethodChannel? methodChannel,
    SelfieSegmenter? segmenter,
    FaceDetector? faceDetector,
  }) : _methodChannel =
           methodChannel ??
           const MethodChannel('app.tubestr/selfie_subject_lifting'),
       _segmenter = segmenter ?? SelfieSegmenter(mode: SegmenterMode.single),
       _faceDetector =
           faceDetector ??
           FaceDetector(
             options: FaceDetectorOptions(
               performanceMode: FaceDetectorMode.accurate,
               enableContours: false,
               enableLandmarks: false,
               enableClassification: false,
               enableTracking: false,
             ),
           );

  final MethodChannel _methodChannel;
  final SelfieSegmenter _segmenter;
  final FaceDetector _faceDetector;

  Future<Uint8List?> extractStickerPng(String imagePath) async {
    if (Platform.isIOS) {
      final nativeResult = await _extractViaVision(imagePath);
      if (nativeResult != null) {
        return nativeResult;
      }
    }

    final croppedPath = await _createFaceCrop(imagePath);
    try {
      if (Platform.isIOS && croppedPath != null) {
        final nativeCropResult = await _extractViaVision(croppedPath);
        if (nativeCropResult != null) {
          return nativeCropResult;
        }
      }
      return await _extractViaMlKit(croppedPath ?? imagePath);
    } finally {
      if (croppedPath != null) {
        final croppedFile = File(croppedPath);
        if (await croppedFile.exists()) {
          await croppedFile.delete();
        }
      }
    }
  }

  Future<void> dispose() async {
    await _segmenter.close();
    await _faceDetector.close();
  }

  Future<Uint8List?> _extractViaVision(String imagePath) async {
    try {
      return await _methodChannel.invokeMethod<Uint8List>('extractStickerPng', {
        'imagePath': imagePath,
      });
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<Uint8List?> _extractViaMlKit(String imagePath) async {
    final mask = await _segmenter.processImage(
      InputImage.fromFilePath(imagePath),
    );
    if (mask == null) {
      return null;
    }

    final image = await _decodeImageFromFile(imagePath);
    final rgbaByteData = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rgbaByteData == null) {
      return null;
    }

    final sourceBytes = rgbaByteData.buffer.asUint8List();
    final outputBytes = Uint8List(sourceBytes.length);
    final confidences = mask.confidences;
    final width = image.width;
    final height = image.height;

    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        final sourcePixelIndex = (y * width + x) * 4;
        final confidence = _bilinearSample(
          confidences,
          mask.width,
          mask.height,
          x / math.max(1, width - 1),
          y / math.max(1, height - 1),
        );
        final alpha = _alphaForConfidence(confidence);
        if (alpha == 0) {
          continue;
        }

        outputBytes[sourcePixelIndex] = sourceBytes[sourcePixelIndex];
        outputBytes[sourcePixelIndex + 1] = sourceBytes[sourcePixelIndex + 1];
        outputBytes[sourcePixelIndex + 2] = sourceBytes[sourcePixelIndex + 2];
        outputBytes[sourcePixelIndex + 3] = alpha;
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
  }

  Future<String?> _createFaceCrop(String imagePath) async {
    try {
      final faces = await _faceDetector.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (faces.isEmpty) {
        return null;
      }

      final primaryFace = faces.reduce(
        (best, candidate) =>
            candidate.boundingBox.width * candidate.boundingBox.height >
                best.boundingBox.width * best.boundingBox.height
            ? candidate
            : best,
      );

      final image = await _decodeImageFromFile(imagePath);
      final cropRect = _expandedCropRect(
        primaryFace.boundingBox,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final croppedImage = await _cropImage(image, cropRect);
      final pngData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (pngData == null) {
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final cropPath = p.join(
        tempDir.path,
        'selfie_crop_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await File(
        cropPath,
      ).writeAsBytes(pngData.buffer.asUint8List(), flush: true);
      return cropPath;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  ui.Rect _expandedCropRect(
    ui.Rect faceBounds,
    double imageWidth,
    double imageHeight,
  ) {
    final cropWidth = faceBounds.width * 1.9;
    final cropHeight = faceBounds.height * 2.6;
    final centerX = faceBounds.center.dx;
    final centerY = faceBounds.top + (faceBounds.height * 0.8);

    final left = (centerX - (cropWidth / 2)).clamp(0.0, imageWidth);
    final top = (centerY - (cropHeight / 2)).clamp(0.0, imageHeight);
    final right = (centerX + (cropWidth / 2)).clamp(0.0, imageWidth);
    final bottom = (centerY + (cropHeight / 2)).clamp(0.0, imageHeight);

    return ui.Rect.fromLTRB(left, top, right, bottom);
  }

  Future<ui.Image> _cropImage(ui.Image image, ui.Rect cropRect) async {
    final cropWidth = cropRect.width.round().clamp(1, image.width);
    final cropHeight = cropRect.height.round().clamp(1, image.height);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      ui.Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
    );
    canvas.drawImageRect(
      image,
      cropRect,
      ui.Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    return picture.toImage(cropWidth, cropHeight);
  }

  Future<ui.Image> _decodeImageFromFile(String imagePath) async {
    final fileBytes = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(fileBytes);
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  Future<ui.Image> _imageFromRgba(
    Uint8List bytes, {
    required int width,
    required int height,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      try {
        final codec = await descriptor.instantiateCodec();
        try {
          final frame = await codec.getNextFrame();
          return frame.image;
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }

  double _bilinearSample(
    List<double> mask,
    int maskWidth,
    int maskHeight,
    double u,
    double v,
  ) {
    final x = u.clamp(0.0, 1.0) * (maskWidth - 1);
    final y = v.clamp(0.0, 1.0) * (maskHeight - 1);
    final x0 = x.floor().clamp(0, maskWidth - 1);
    final x1 = (x0 + 1).clamp(0, maskWidth - 1);
    final y0 = y.floor().clamp(0, maskHeight - 1);
    final y1 = (y0 + 1).clamp(0, maskHeight - 1);
    final fx = x - x0;
    final fy = y - y0;

    return (mask[(y0 * maskWidth) + x0] * (1 - fx) * (1 - fy)) +
        (mask[(y0 * maskWidth) + x1] * fx * (1 - fy)) +
        (mask[(y1 * maskWidth) + x0] * (1 - fx) * fy) +
        (mask[(y1 * maskWidth) + x1] * fx * fy);
  }

  int _alphaForConfidence(double confidence) {
    const low = 0.25;
    const high = 0.55;
    final normalized = ((confidence - low) / (high - low)).clamp(0.0, 1.0);
    return (normalized * 255).round().clamp(0, 255);
  }
}

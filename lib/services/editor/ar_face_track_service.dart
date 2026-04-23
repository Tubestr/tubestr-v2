import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mediapipe_face_mesh/mediapipe_face_mesh.dart';
import 'package:path/path.dart' as p;

import '../../domain/models/ar_face_result.dart';
import 'ar_filter_catalog.dart';
import 'ar_filter_renderer.dart';

class ArFilterSequence {
  const ArFilterSequence({
    required this.pattern,
    required this.frameRate,
    this.overlayOffset = ui.Offset.zero,
  });

  final String pattern;
  final int frameRate;
  final ui.Offset overlayOffset;
}

class ArFaceTrackSample {
  const ArFaceTrackSample({required this.timeMs, required this.face});

  final int timeMs;
  final ArFaceResult face;
}

class _RenderedArSequence {
  const _RenderedArSequence({
    required this.frameCount,
    required this.cropSize,
    required this.overlayOffset,
  });

  final int frameCount;
  final ui.Size cropSize;
  final ui.Offset overlayOffset;
}

class ArFaceTrackService {
  ArFaceTrackService({
    int keyframeFrameRate = defaultKeyframeFrameRate,
    int outputFrameRate = defaultOutputFrameRate,
    Duration maxDuration = const Duration(seconds: 60),
    ArFilterAssetLoader? loadFilterAsset,
  }) : _keyframeFrameRate = keyframeFrameRate,
       _outputFrameRate = outputFrameRate,
       _maxDuration = maxDuration,
       _loadFilterAsset = loadFilterAsset ?? ArFilterCatalog.load;

  static const defaultKeyframeFrameRate = 6;
  static const defaultOutputFrameRate = 20;
  static const _arAnchorLandmarks = <int>{1, 10, 33, 61, 152, 263, 291};

  final int _keyframeFrameRate;
  final int _outputFrameRate;
  final Duration _maxDuration;
  final ArFilterAssetLoader _loadFilterAsset;
  final ArFilterRenderer _renderer = const ArFilterRenderer();

  static ArFaceTrackSample? sampleAtPosition({
    required List<ArFaceTrackSample> samples,
    required Duration position,
  }) {
    return _sampleAtTimeMs(samples: samples, timeMs: position.inMilliseconds);
  }

  Future<ArFilterSequence?> buildFilterSequence({
    required String videoPath,
    required Duration trimStart,
    required Duration duration,
    required String filterId,
    required String outputDir,
    required ui.Size renderSize,
    required AssetBundle assetBundle,
    bool Function()? isCancelled,
  }) async {
    _throwIfCancelled(isCancelled);
    if (!Platform.isAndroid && !Platform.isIOS) {
      _log('unsupported platform for export tracking');
      return null;
    }
    if (duration <= Duration.zero || duration > _maxDuration) {
      _log(
        'skipping export tracking for duration ${duration.inMilliseconds}ms',
      );
      return null;
    }
    final filter = await _loadFilterAsset(filterId, assetBundle: assetBundle);
    if (filter == null) {
      _log('filter "$filterId" could not be loaded');
      return null;
    }
    try {
      _log(
        'building "$filterId" sequence at '
        '${renderSize.width.round()}x${renderSize.height.round()} '
        'keyframes=${_keyframeFrameRate}fps output=${_outputFrameRate}fps',
      );
      final root = Directory(outputDir);
      final keyframeDir = Directory(p.join(root.path, 'keyframes'));
      final sequenceDir = Directory(p.join(root.path, 'sequence'));
      await keyframeDir.create(recursive: true);
      await sequenceDir.create(recursive: true);

      final extracted = await _extractKeyframes(
        videoPath: videoPath,
        trimStart: trimStart,
        duration: duration,
        outputPattern: p.join(keyframeDir.path, 'key_%05d.png'),
        renderSize: renderSize,
      );
      _throwIfCancelled(isCancelled);
      if (!extracted) {
        _log('keyframe extraction failed');
        return null;
      }

      final keyframes = await _listPngs(keyframeDir);
      if (keyframes.isEmpty) {
        _log('keyframe extraction produced no PNGs');
        return null;
      }
      _log('extracted ${keyframes.length} keyframes');

      final tracks = await _detectFacesInKeyframes(
        keyframes: keyframes,
        renderSize: renderSize,
        isCancelled: isCancelled,
      );
      _throwIfCancelled(isCancelled);
      final resolvedTracks = _fillMissingTracks(tracks);
      if (resolvedTracks.every((track) => track == null)) {
        _log('no faces found in extracted keyframes');
        return null;
      }

      final rendered = await _renderSequence(
        tracks: resolvedTracks,
        filter: filter,
        duration: duration,
        renderSize: renderSize,
        outputDir: sequenceDir,
        isCancelled: isCancelled,
      );

      if (rendered == null) {
        _log('no drawable filter frames generated');
        return null;
      }
      _log(
        'rendered sequence to ${sequenceDir.path} '
        'crop=${rendered.cropSize.width.toInt()}x${rendered.cropSize.height.toInt()} '
        'offset=${rendered.overlayOffset.dx.toInt()},${rendered.overlayOffset.dy.toInt()} '
        'frames=${rendered.frameCount}',
      );
      return ArFilterSequence(
        pattern: p.join(sequenceDir.path, 'filter_%05d.png'),
        frameRate: _outputFrameRate,
        overlayOffset: rendered.overlayOffset,
      );
    } finally {
      filter.dispose();
    }
  }

  Future<ArFilterSequence?> buildFilterSequenceFromTrackFile({
    required String trackPath,
    required Duration trimStart,
    required Duration duration,
    required String filterId,
    required String outputDir,
    required ui.Size renderSize,
    required AssetBundle assetBundle,
    bool Function()? isCancelled,
  }) async {
    _throwIfCancelled(isCancelled);
    if (duration <= Duration.zero || duration > _maxDuration) {
      _log(
        'skipping sidecar export tracking for duration '
        '${duration.inMilliseconds}ms',
      );
      return null;
    }
    final samples = await readTrackFile(trackPath);
    if (samples.isEmpty) {
      _log('sidecar track has no samples: $trackPath');
      return null;
    }
    final filter = await _loadFilterAsset(filterId, assetBundle: assetBundle);
    if (filter == null) {
      _log('filter "$filterId" could not be loaded');
      return null;
    }
    try {
      final sequenceDir = Directory(p.join(outputDir, 'sidecar_sequence'));
      await sequenceDir.create(recursive: true);
      _log(
        'building "$filterId" sidecar sequence at '
        '${renderSize.width.round()}x${renderSize.height.round()} '
        'output=${_outputFrameRate}fps samples=${samples.length}',
      );
      final rendered = await _renderSequenceFromSamples(
        samples: samples,
        filter: filter,
        trimStart: trimStart,
        duration: duration,
        renderSize: renderSize,
        outputDir: sequenceDir,
        isCancelled: isCancelled,
      );
      if (rendered == null) {
        _log('no drawable sidecar filter frames generated');
        return null;
      }
      _log(
        'rendered sidecar sequence to ${sequenceDir.path} '
        'crop=${rendered.cropSize.width.toInt()}x${rendered.cropSize.height.toInt()} '
        'offset=${rendered.overlayOffset.dx.toInt()},${rendered.overlayOffset.dy.toInt()} '
        'frames=${rendered.frameCount}',
      );
      return ArFilterSequence(
        pattern: p.join(sequenceDir.path, 'filter_%05d.png'),
        frameRate: _outputFrameRate,
        overlayOffset: rendered.overlayOffset,
      );
    } finally {
      filter.dispose();
    }
  }

  static Future<void> writeTrackFile({
    required String path,
    required List<ArFaceTrackSample> samples,
  }) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final payload = <String, Object?>{
      'version': 1,
      'samples': samples.map(_sampleToJson).toList(growable: false),
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  static Future<List<ArFaceTrackSample>> readTrackFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return const <ArFaceTrackSample>[];
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, Object?>) {
      return const <ArFaceTrackSample>[];
    }
    final rawSamples = decoded['samples'];
    if (rawSamples is! List) {
      return const <ArFaceTrackSample>[];
    }
    final samples = <ArFaceTrackSample>[];
    for (final rawSample in rawSamples) {
      final sample = _sampleFromJson(rawSample);
      if (sample != null) {
        samples.add(sample);
      }
    }
    samples.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return samples;
  }

  Future<bool> _extractKeyframes({
    required String videoPath,
    required Duration trimStart,
    required Duration duration,
    required String outputPattern,
    required ui.Size renderSize,
  }) async {
    final args = <String>[
      '-y',
      '-ss',
      _secondsString(trimStart),
      '-t',
      _secondsString(duration),
      '-i',
      videoPath,
      '-vf',
      'fps=$_keyframeFrameRate,scale=${renderSize.width.round()}:${renderSize.height.round()}:flags=bilinear,setsar=1',
      outputPattern,
    ];
    final session = await FFmpegKit.executeWithArguments(args);
    final returnCode = await session.getReturnCode();
    final success = ReturnCode.isSuccess(returnCode);
    if (!success) {
      final logs = await session.getAllLogsAsString();
      _log('keyframe extraction logs: ${logs ?? '(no logs)'}');
    }
    return success;
  }

  Future<List<File>> _listPngs(Directory directory) async {
    if (!await directory.exists()) {
      return const <File>[];
    }
    final files = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.png'))
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  Future<List<ArFaceResult?>> _detectFacesInKeyframes({
    required List<File> keyframes,
    required ui.Size renderSize,
    bool Function()? isCancelled,
  }) async {
    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        enableTracking: false,
      ),
    );
    final meshProcessor = await FaceMeshProcessor.create(
      delegate: FaceMeshDelegate.xnnpack,
      enableRoiTracking: false,
    );
    try {
      final tracks = <ArFaceResult?>[];
      for (final keyframe in keyframes) {
        _throwIfCancelled(isCancelled);
        tracks.add(
          await _detectFaceInKeyframe(
            keyframe: keyframe,
            detector: detector,
            meshProcessor: meshProcessor,
            renderSize: renderSize,
          ),
        );
      }
      final detected = tracks.whereType<ArFaceResult>().length;
      _log('tracked faces in $detected/${keyframes.length} keyframes');
      return tracks;
    } finally {
      await detector.close();
      meshProcessor.close();
    }
  }

  Future<ArFaceResult?> _detectFaceInKeyframe({
    required File keyframe,
    required FaceDetector detector,
    required FaceMeshProcessor meshProcessor,
    required ui.Size renderSize,
  }) async {
    final faces = await detector.processImage(
      InputImage.fromFilePath(keyframe.path),
    );
    if (faces.isEmpty) {
      return null;
    }
    final face = faces.first;
    final fallback = _fallbackFaceFromMlKit(face, renderSize);
    final decoded = await _decodeRgbaImage(keyframe);
    if (decoded == null) {
      _log('could not decode ${p.basename(keyframe.path)}; using ML Kit box');
      return fallback;
    }
    final (:image, :pixels) = decoded;
    try {
      final box = _boxFromRect(face.boundingBox, renderSize);
      final mesh = meshProcessor.process(
        FaceMeshImage(
          pixels: pixels,
          width: image.width,
          height: image.height,
          pixelFormat: FaceMeshPixelFormat.rgba,
        ),
        box: box,
        boxScale: 1.2,
        boxMakeSquare: true,
      );
      if (mesh.landmarks.isEmpty || mesh.score < 0.45) {
        _log(
          'mesh score ${mesh.score.toStringAsFixed(2)} for '
          '${p.basename(keyframe.path)}; using ML Kit box',
        );
        return fallback;
      }
      return ArFaceResult(
        boundingBox: box,
        landmarks: mesh.landmarks,
        score: mesh.score,
        imageSize: ui.Size(
          mesh.imageWidth.toDouble(),
          mesh.imageHeight.toDouble(),
        ),
        headEulerY: face.headEulerAngleY,
        headEulerZ: face.headEulerAngleZ,
      );
    } catch (error) {
      _log(
        'mesh processing failed for ${p.basename(keyframe.path)}: $error; '
        'using ML Kit box',
      );
      return fallback;
    } finally {
      image.dispose();
    }
  }

  Future<({ui.Image image, Uint8List pixels})?> _decodeRgbaImage(
    File file,
  ) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) {
      image.dispose();
      return null;
    }
    return (
      image: image,
      pixels: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  FaceMeshBox _boxFromRect(Rect rect, ui.Size size) {
    return FaceMeshBox(
      left: rect.left.clamp(0.0, size.width).toDouble(),
      top: rect.top.clamp(0.0, size.height).toDouble(),
      right: rect.right.clamp(0.0, size.width).toDouble(),
      bottom: rect.bottom.clamp(0.0, size.height).toDouble(),
    );
  }

  ArFaceResult? _fallbackFaceFromMlKit(Face face, ui.Size imageSize) {
    final box = _boxFromRect(face.boundingBox, imageSize);
    if (box.width <= 1 || box.height <= 1) {
      return null;
    }

    Offset normalized(double x, double y) {
      return Offset(
        (x / math.max(imageSize.width, 1)).clamp(0.0, 1.0).toDouble(),
        (y / math.max(imageSize.height, 1)).clamp(0.0, 1.0).toDouble(),
      );
    }

    Offset landmarkOr(
      FaceLandmarkType type,
      double fallbackX,
      double fallbackY,
    ) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        return normalized(
          landmark.position.x.toDouble(),
          landmark.position.y.toDouble(),
        );
      }
      return normalized(fallbackX, fallbackY);
    }

    final left = box.left;
    final top = box.top;
    final width = box.width;
    final height = box.height;
    final center = normalized(box.centerX, box.centerY);
    final leftEye = landmarkOr(
      FaceLandmarkType.leftEye,
      left + width * 0.36,
      top + height * 0.42,
    );
    final rightEye = landmarkOr(
      FaceLandmarkType.rightEye,
      left + width * 0.64,
      top + height * 0.42,
    );
    final nose = landmarkOr(
      FaceLandmarkType.noseBase,
      box.centerX,
      top + height * 0.56,
    );
    final leftMouth = landmarkOr(
      FaceLandmarkType.leftMouth,
      left + width * 0.42,
      top + height * 0.71,
    );
    final rightMouth = landmarkOr(
      FaceLandmarkType.rightMouth,
      left + width * 0.58,
      top + height * 0.71,
    );

    final landmarks = List<FaceMeshLandmark>.generate(
      468,
      (_) => FaceMeshLandmark(x: center.dx, y: center.dy, z: 0),
    );
    void setLandmark(int index, Offset point) {
      landmarks[index] = FaceMeshLandmark(x: point.dx, y: point.dy, z: 0);
    }

    setLandmark(33, leftEye);
    setLandmark(263, rightEye);
    setLandmark(1, nose);
    setLandmark(61, leftMouth);
    setLandmark(291, rightMouth);
    setLandmark(10, normalized(box.centerX, top + height * 0.16));
    setLandmark(152, normalized(box.centerX, top + height * 0.96));

    return ArFaceResult(
      boundingBox: box,
      landmarks: landmarks,
      score: 0.35,
      imageSize: imageSize,
      trackingId: face.trackingId,
      headEulerY: face.headEulerAngleY,
      headEulerZ: face.headEulerAngleZ,
    );
  }

  List<ArFaceResult?> _fillMissingTracks(List<ArFaceResult?> tracks) {
    if (tracks.isEmpty) {
      return tracks;
    }
    final filled = List<ArFaceResult?>.from(tracks);
    ArFaceResult? last;
    for (var i = 0; i < filled.length; i += 1) {
      last = filled[i] ?? last;
      filled[i] = last;
    }
    ArFaceResult? next;
    for (var i = filled.length - 1; i >= 0; i -= 1) {
      next = filled[i] ?? next;
      filled[i] = filled[i] ?? next;
    }
    return filled;
  }

  Future<_RenderedArSequence?> _renderSequence({
    required List<ArFaceResult?> tracks,
    required ArFilterAsset filter,
    required Duration duration,
    required ui.Size renderSize,
    required Directory outputDir,
    bool Function()? isCancelled,
  }) async {
    final frameCount = math.max(
      1,
      (duration.inMilliseconds / 1000 * _outputFrameRate).ceil(),
    );
    final faces = <ArFaceResult?>[];
    for (var frameIndex = 0; frameIndex < frameCount; frameIndex += 1) {
      faces.add(_interpolateTrackFrame(tracks: tracks, frameIndex: frameIndex));
    }
    return _renderCroppedSequence(
      faces: faces,
      filter: filter,
      renderSize: renderSize,
      outputDir: outputDir,
      isCancelled: isCancelled,
    );
  }

  Future<_RenderedArSequence?> _renderSequenceFromSamples({
    required List<ArFaceTrackSample> samples,
    required ArFilterAsset filter,
    required Duration trimStart,
    required Duration duration,
    required ui.Size renderSize,
    required Directory outputDir,
    bool Function()? isCancelled,
  }) async {
    final frameCount = math.max(
      1,
      (duration.inMilliseconds / 1000 * _outputFrameRate).ceil(),
    );
    final faces = <ArFaceResult?>[];
    for (var frameIndex = 0; frameIndex < frameCount; frameIndex += 1) {
      final absoluteTimeMs =
          trimStart.inMilliseconds +
          (frameIndex / _outputFrameRate * 1000).round();
      final chosen = _sampleAtTimeMs(samples: samples, timeMs: absoluteTimeMs);
      faces.add(chosen?.face);
    }
    return _renderCroppedSequence(
      faces: faces,
      filter: filter,
      renderSize: renderSize,
      outputDir: outputDir,
      isCancelled: isCancelled,
    );
  }

  Future<_RenderedArSequence?> _renderCroppedSequence({
    required List<ArFaceResult?> faces,
    required ArFilterAsset filter,
    required ui.Size renderSize,
    required Directory outputDir,
    bool Function()? isCancelled,
  }) async {
    final commandsByFrame = <List<ArFilterDrawCommand>>[];
    Rect? unionBounds;
    for (final face in faces) {
      _throwIfCancelled(isCancelled);
      final commands = face == null
          ? const <ArFilterDrawCommand>[]
          : _renderer.computeDrawCommands(
              face: face,
              filter: filter,
              geometry: ArPreviewGeometry(
                imageSize: face.imageSize,
                viewportSize: renderSize,
              ),
            );
      commandsByFrame.add(commands);
      for (final command in commands) {
        final bounds = _commandBounds(command);
        unionBounds = unionBounds == null
            ? bounds
            : unionBounds.expandToInclude(bounds);
      }
    }
    if (unionBounds == null) {
      return null;
    }

    final cropRect = _cropRectFor(unionBounds, renderSize);
    final renderWatch = Stopwatch()..start();
    for (
      var frameIndex = 0;
      frameIndex < commandsByFrame.length;
      frameIndex += 1
    ) {
      _throwIfCancelled(isCancelled);
      final bytes = await _renderFrame(
        commands: commandsByFrame[frameIndex],
        cropRect: cropRect,
      );
      final file = File(
        p.join(
          outputDir.path,
          'filter_${frameIndex.toString().padLeft(5, '0')}.png',
        ),
      );
      await file.writeAsBytes(bytes);
    }
    renderWatch.stop();
    final seconds = math.max(renderWatch.elapsedMilliseconds / 1000, 0.001);
    _log(
      'encoded ${commandsByFrame.length} cropped overlay frames '
      'in ${renderWatch.elapsedMilliseconds}ms '
      'fps=${(commandsByFrame.length / seconds).toStringAsFixed(1)}',
    );
    return _RenderedArSequence(
      frameCount: commandsByFrame.length,
      cropSize: cropRect.size,
      overlayOffset: cropRect.topLeft,
    );
  }

  ArFaceResult? _interpolateTrackFrame({
    required List<ArFaceResult?> tracks,
    required int frameIndex,
  }) {
    if (tracks.isEmpty) {
      return null;
    }
    final position = frameIndex / _outputFrameRate * _keyframeFrameRate;
    final beforeIndex = position.floor().clamp(0, tracks.length - 1);
    final afterIndex = position.ceil().clamp(0, tracks.length - 1);
    final before = tracks[beforeIndex];
    final after = tracks[afterIndex];
    if (before == null) {
      return after;
    }
    if (after == null || beforeIndex == afterIndex) {
      return before;
    }
    return _interpolateFaces(
      before,
      after,
      (position - beforeIndex).clamp(0.0, 1.0).toDouble(),
    );
  }

  static ArFaceTrackSample? _sampleAtTimeMs({
    required List<ArFaceTrackSample> samples,
    required int timeMs,
  }) {
    if (samples.isEmpty) {
      return null;
    }
    var low = 0;
    var high = samples.length - 1;
    while (low <= high) {
      final mid = low + ((high - low) >> 1);
      final sampleMs = samples[mid].timeMs;
      if (sampleMs == timeMs) {
        return samples[mid];
      }
      if (sampleMs < timeMs) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (high < 0) {
      return samples.first;
    }
    if (low >= samples.length) {
      return samples.last;
    }
    final before = samples[high];
    final after = samples[low];
    final duration = after.timeMs - before.timeMs;
    if (duration <= 0) {
      return before;
    }
    return ArFaceTrackSample(
      timeMs: timeMs,
      face: _interpolateFaces(
        before.face,
        after.face,
        ((timeMs - before.timeMs) / duration).clamp(0.0, 1.0).toDouble(),
      ),
    );
  }

  static ArFaceResult _interpolateFaces(
    ArFaceResult before,
    ArFaceResult after,
    double t,
  ) {
    if (before.landmarks.length != after.landmarks.length ||
        before.imageSize != after.imageSize) {
      return t < 0.5 ? before : after;
    }

    double lerp(double a, double b) => a + (b - a) * t;
    double? lerpNullable(double? a, double? b) {
      if (a == null || b == null) {
        return t < 0.5 ? a : b;
      }
      return lerp(a, b);
    }

    return ArFaceResult(
      boundingBox: FaceMeshBox(
        left: lerp(before.boundingBox.left, after.boundingBox.left),
        top: lerp(before.boundingBox.top, after.boundingBox.top),
        right: lerp(before.boundingBox.right, after.boundingBox.right),
        bottom: lerp(before.boundingBox.bottom, after.boundingBox.bottom),
      ),
      landmarks: _interpolateAnchorLandmarks(
        before.landmarks,
        after.landmarks,
        t,
        lerp,
      ),
      score: lerp(before.score, after.score),
      imageSize: before.imageSize,
      trackingId: t < 0.5 ? before.trackingId : after.trackingId,
      headEulerY: lerpNullable(before.headEulerY, after.headEulerY),
      headEulerZ: lerpNullable(before.headEulerZ, after.headEulerZ),
    );
  }

  static List<FaceMeshLandmark> _interpolateAnchorLandmarks(
    List<FaceMeshLandmark> before,
    List<FaceMeshLandmark> after,
    double t,
    double Function(double a, double b) lerp,
  ) {
    final landmarks = List<FaceMeshLandmark>.of(t < 0.5 ? before : after);
    for (final index in _arAnchorLandmarks) {
      if (index >= before.length || index >= after.length) {
        continue;
      }
      final a = before[index];
      final b = after[index];
      landmarks[index] = FaceMeshLandmark(
        x: lerp(a.x, b.x),
        y: lerp(a.y, b.y),
        z: lerp(a.z, b.z),
      );
    }
    return landmarks;
  }

  Future<Uint8List> _renderFrame({
    required List<ArFilterDrawCommand> commands,
    required Rect cropRect,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
    );
    canvas.translate(-cropRect.left, -cropRect.top);
    _paintCommands(canvas, commands);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      cropRect.width.round(),
      cropRect.height.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes) ??
        Uint8List(0);
  }

  Rect _commandBounds(ArFilterDrawCommand command) {
    final halfWidth = command.size.width / 2;
    final halfHeight = command.size.height / 2;
    final corners =
        <Offset>[
          Offset(-halfWidth, -halfHeight),
          Offset(halfWidth, -halfHeight),
          Offset(halfWidth, halfHeight),
          Offset(-halfWidth, halfHeight),
        ].map(
          (corner) =>
              _rotateOffset(corner, command.rotationRadians) + command.position,
        );
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final corner in corners) {
      left = math.min(left, corner.dx);
      top = math.min(top, corner.dy);
      right = math.max(right, corner.dx);
      bottom = math.max(bottom, corner.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Rect _cropRectFor(Rect bounds, ui.Size renderSize) {
    final padded = bounds.inflate(8);
    final left = padded.left.floor().clamp(0, renderSize.width - 1).toDouble();
    final top = padded.top.floor().clamp(0, renderSize.height - 1).toDouble();
    final right = padded.right
        .ceil()
        .clamp(left + 1, renderSize.width)
        .toDouble();
    final bottom = padded.bottom
        .ceil()
        .clamp(top + 1, renderSize.height)
        .toDouble();
    return Rect.fromLTRB(left, top, right, bottom);
  }

  Offset _rotateOffset(Offset offset, double radians) {
    if (radians == 0) {
      return offset;
    }
    final sin = math.sin(radians);
    final cos = math.cos(radians);
    return Offset(
      offset.dx * cos - offset.dy * sin,
      offset.dx * sin + offset.dy * cos,
    );
  }

  void _paintCommands(Canvas canvas, List<ArFilterDrawCommand> commands) {
    for (final command in commands) {
      canvas.save();
      canvas.translate(command.position.dx, command.position.dy);
      canvas.rotate(command.rotationRadians);
      canvas.drawImageRect(
        command.image,
        Rect.fromLTWH(
          0,
          0,
          command.image.width.toDouble(),
          command.image.height.toDouble(),
        ),
        Rect.fromCenter(
          center: Offset.zero,
          width: command.size.width,
          height: command.size.height,
        ),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high
          ..color = Color.fromRGBO(255, 255, 255, command.opacity),
      );
      canvas.restore();
    }
  }

  String _secondsString(Duration duration) {
    return (duration.inMilliseconds / 1000).toStringAsFixed(3);
  }

  void _log(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('AR export: $message');
  }

  static void _throwIfCancelled(bool Function()? isCancelled) {
    if (isCancelled?.call() ?? false) {
      throw StateError('AR export cancelled');
    }
  }

  static Map<String, Object?> _sampleToJson(ArFaceTrackSample sample) {
    final face = sample.face;
    return <String, Object?>{
      'timeMs': sample.timeMs,
      'imageWidth': face.imageSize.width,
      'imageHeight': face.imageSize.height,
      'score': face.score,
      'trackingId': face.trackingId,
      'headEulerY': face.headEulerY,
      'headEulerZ': face.headEulerZ,
      'boundingBox': <String, Object?>{
        'left': face.boundingBox.left,
        'top': face.boundingBox.top,
        'right': face.boundingBox.right,
        'bottom': face.boundingBox.bottom,
      },
      'landmarks': face.landmarks
          .map(
            (landmark) => <String, Object?>{
              'x': landmark.x,
              'y': landmark.y,
              'z': landmark.z,
            },
          )
          .toList(growable: false),
    };
  }

  static ArFaceTrackSample? _sampleFromJson(Object? rawSample) {
    if (rawSample is! Map<String, Object?>) {
      return null;
    }
    final timeMs = (rawSample['timeMs'] as num?)?.round();
    final imageWidth = (rawSample['imageWidth'] as num?)?.toDouble();
    final imageHeight = (rawSample['imageHeight'] as num?)?.toDouble();
    final box = rawSample['boundingBox'];
    final rawLandmarks = rawSample['landmarks'];
    if (timeMs == null ||
        imageWidth == null ||
        imageHeight == null ||
        box is! Map<String, Object?> ||
        rawLandmarks is! List) {
      return null;
    }
    final left = (box['left'] as num?)?.toDouble();
    final top = (box['top'] as num?)?.toDouble();
    final right = (box['right'] as num?)?.toDouble();
    final bottom = (box['bottom'] as num?)?.toDouble();
    if (left == null || top == null || right == null || bottom == null) {
      return null;
    }
    final landmarks = <FaceMeshLandmark>[];
    for (final rawLandmark in rawLandmarks) {
      if (rawLandmark is! Map<String, Object?>) {
        continue;
      }
      final x = (rawLandmark['x'] as num?)?.toDouble();
      final y = (rawLandmark['y'] as num?)?.toDouble();
      final z = (rawLandmark['z'] as num?)?.toDouble() ?? 0;
      if (x == null || y == null) {
        continue;
      }
      landmarks.add(FaceMeshLandmark(x: x, y: y, z: z));
    }
    if (landmarks.isEmpty) {
      return null;
    }
    return ArFaceTrackSample(
      timeMs: timeMs,
      face: ArFaceResult(
        boundingBox: FaceMeshBox(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
        ),
        landmarks: landmarks,
        score: (rawSample['score'] as num?)?.toDouble() ?? 1,
        imageSize: ui.Size(imageWidth, imageHeight),
        trackingId: (rawSample['trackingId'] as num?)?.round(),
        headEulerY: (rawSample['headEulerY'] as num?)?.toDouble(),
        headEulerZ: (rawSample['headEulerZ'] as num?)?.toDouble(),
      ),
    );
  }
}

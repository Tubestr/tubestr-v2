import 'dart:io';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/storage/app_database.dart';

typedef ExtractMediaSignals =
    Future<MediaSignalExtractionResult> Function(LocalVideo video);

class MediaSignalExtractionResult {
  const MediaSignalExtractionResult({
    this.cvLabels = const <String>[],
    this.faceCount = 0,
    this.loudness = 0,
  });

  final List<String> cvLabels;
  final int faceCount;
  final double loudness;
}

class MediaSignalExtractionService {
  MediaSignalExtractionService({ExtractMediaSignals? extractSignals})
    : _extractSignals = extractSignals ?? _defaultExtractSignals;

  final ExtractMediaSignals _extractSignals;

  Future<MediaSignalExtractionResult> extractSignals({
    required LocalVideo video,
  }) {
    return _extractSignals(video);
  }
}

Future<MediaSignalExtractionResult> _defaultExtractSignals(
  LocalVideo video,
) async {
  final samplePaths = await _sampleFrames(video);
  try {
    final loudnessFuture = _measureVideoLoudness(video.filePath);
    final faceCountFuture = _countFacesInImages(samplePaths);
    final results = await Future.wait<Object>([
      loudnessFuture,
      faceCountFuture,
    ]);
    return MediaSignalExtractionResult(
      cvLabels: List<String>.from(video.cvLabels),
      loudness: results[0] as double,
      faceCount: results[1] as int,
    );
  } finally {
    await _cleanupSampleFrames(samplePaths);
  }
}

Future<List<String>> _sampleFrames(LocalVideo video) async {
  if (video.filePath.isEmpty || video.durationSeconds <= 0) {
    return const <String>[];
  }

  final tempRoot = await getTemporaryDirectory();
  final sampleDir = Directory(p.join(tempRoot.path, 'scan_frames', video.id));
  await sampleDir.create(recursive: true);

  final sampledPaths = <String>[];
  for (final timeMs in _buildSampleOffsets(video.durationSeconds)) {
    final path = await VideoThumbnail.thumbnailFile(
      video: video.filePath,
      thumbnailPath: sampleDir.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 480,
      quality: 75,
      timeMs: timeMs,
    );
    if (path != null && path.isNotEmpty) {
      sampledPaths.add(path);
    }
  }

  return sampledPaths.toSet().toList(growable: false);
}

List<int> _buildSampleOffsets(double durationSeconds) {
  final durationMs = math.max(1, (durationSeconds * 1000).round());
  final fractions = durationSeconds >= 30
      ? const <double>[0.15, 0.35, 0.5, 0.65, 0.85]
      : const <double>[0.2, 0.5, 0.8];
  return fractions
      .map((fraction) => (durationMs * fraction).round().clamp(0, durationMs))
      .toSet()
      .toList(growable: false)
    ..sort();
}

Future<int> _countFacesInImages(List<String> imagePaths) async {
  if (imagePaths.isEmpty ||
      kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return 0;
  }

  final detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableContours: false,
      enableClassification: false,
      enableTracking: false,
      enableLandmarks: false,
      minFaceSize: 0.1,
    ),
  );
  try {
    var maxFaces = 0;
    for (final path in imagePaths) {
      final faces = await detector.processImage(InputImage.fromFilePath(path));
      if (faces.length > maxFaces) {
        maxFaces = faces.length;
      }
    }
    return maxFaces;
  } on MissingPluginException {
    return 0;
  } on PlatformException {
    return 0;
  } finally {
    await detector.close();
  }
}

Future<double> _measureVideoLoudness(String path) async {
  if (path.isEmpty) {
    return 0;
  }

  try {
    final session = await FFmpegKit.executeWithArguments([
      '-i',
      path,
      '-af',
      'volumedetect',
      '-f',
      'null',
      '-',
    ]);
    final logs = await session.getAllLogsAsString();
    return _parseNormalizedLoudness(logs ?? '');
  } on MissingPluginException {
    return 0;
  } on PlatformException {
    return 0;
  }
}

double _parseNormalizedLoudness(String logs) {
  final match = RegExp(
    r'mean_volume:\s*(-?(?:\d+(?:\.\d+)?)|inf)\s*dB',
    caseSensitive: false,
  ).firstMatch(logs);
  if (match == null) {
    return 0;
  }

  final rawValue = match.group(1);
  if (rawValue == null || rawValue.toLowerCase() == 'inf') {
    return 0;
  }

  final decibels = double.tryParse(rawValue);
  if (decibels == null || !decibels.isFinite) {
    return 0;
  }

  return ((60 + decibels) / 60).clamp(0, 1);
}

Future<void> _cleanupSampleFrames(List<String> paths) async {
  final parentDirs = <String>{};
  for (final path in paths) {
    parentDirs.add(p.dirname(path));
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  for (final dirPath in parentDirs) {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      continue;
    }
    final remaining = await dir.list().take(1).toList();
    if (remaining.isEmpty) {
      await dir.delete();
    }
  }
}

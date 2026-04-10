import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter_new_video/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_video/return_code.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/storage/app_database.dart';
import '../../domain/models/editor_resources.dart';
import '../../domain/models/editor_session.dart';
import '../approval/video_approval_service.dart';
import '../media/local_media_library_service.dart';
import '../media/thumbnail_service.dart';
import '../media/video_probe_service.dart';
import 'editor_resource_catalog.dart';

typedef ExecuteFfmpegWithArguments =
    Future<FfmpegExecutionResult> Function(List<String> arguments);
typedef ProbeSourceMediaInfo = Future<SourceMediaInfo?> Function(String path);

class EditorExportException implements Exception {
  const EditorExportException(this.message);

  final String message;

  @override
  String toString() => 'EditorExportException: $message';
}

class EditorExportResult {
  const EditorExportResult({
    required this.videoId,
    required this.outputPath,
    required this.thumbnailPath,
    required this.arguments,
    this.usedFallback = false,
    this.warning,
  });

  final String videoId;
  final String outputPath;
  final String? thumbnailPath;
  final List<String> arguments;
  final bool usedFallback;
  final String? warning;
}

class FfmpegExecutionResult {
  const FfmpegExecutionResult({required this.success, this.logs});

  final bool success;
  final String? logs;
}

class SourceMediaInfo {
  const SourceMediaInfo({
    required this.size,
    required this.hasAudio,
    this.rotationDegrees = 0,
    this.displayAspectRatio,
  });

  final ui.Size size;
  final bool hasAudio;
  final int rotationDegrees;
  final double? displayAspectRatio;
}

class EditorExportPlan {
  const EditorExportPlan({
    required this.arguments,
    required this.outputPath,
    required this.renderSize,
  });

  final List<String> arguments;
  final String outputPath;
  final ui.Size renderSize;
}

class EditorExportService {
  EditorExportService({
    required AppDatabase database,
    required ThumbnailService thumbnailService,
    required VideoApprovalService videoApprovalService,
    required LocalMediaLibraryService localMediaLibraryService,
    AssetBundle? assetBundle,
    Uuid? uuid,
    ExecuteFfmpegWithArguments? executeFfmpeg,
    ProbeSourceMediaInfo? probeSourceMediaInfo,
  }) : _database = database,
       _thumbnailService = thumbnailService,
       _videoApprovalService = videoApprovalService,
       _localMediaLibraryService = localMediaLibraryService,
       _assetBundle = assetBundle ?? rootBundle,
       _uuid = uuid ?? const Uuid(),
       _executeFfmpeg = executeFfmpeg ?? _defaultExecuteFfmpeg,
       _probeSourceMediaInfo =
           probeSourceMediaInfo ?? _defaultProbeSourceMediaInfo;

  final AppDatabase _database;
  final ThumbnailService _thumbnailService;
  final VideoApprovalService _videoApprovalService;
  final LocalMediaLibraryService _localMediaLibraryService;
  final AssetBundle _assetBundle;
  final Uuid _uuid;
  final ExecuteFfmpegWithArguments _executeFfmpeg;
  final ProbeSourceMediaInfo _probeSourceMediaInfo;

  Future<EditorExportResult> export({
    required EditorSession session,
    required String profileId,
    required String title,
    ui.Size? preferredDisplaySize,
    int? preferredRotationDegrees,
  }) async {
    final stagingDir = await _localMediaLibraryService
        .ensureEditorStagingDirectory();

    final outputPath = await _localMediaLibraryService.createManagedVideoPath(
      prefix: 'edit',
      extension: '.mp4',
    );
    final sourceMediaInfo =
        await _probeSourceMediaInfo(session.sourcePath) ??
        const SourceMediaInfo(size: ui.Size(720, 1280), hasAudio: false);
    final effectiveSourceRotationDegrees =
        preferredRotationDegrees ?? sourceMediaInfo.rotationDegrees;
    final baseRenderSize = normalizeEditorRenderSize(
      preferredDisplaySize ?? _displayOrientedSize(sourceMediaInfo),
    );
    _logProbe(
      label: 'source',
      path: session.sourcePath,
      info: sourceMediaInfo,
      extra:
          'preferredDisplay=${preferredDisplaySize == null ? 'none' : '${preferredDisplaySize.width.toInt()}x${preferredDisplaySize.height.toInt()}'} '
          'preferredRotation=${preferredRotationDegrees ?? 'none'} '
          'baseRender=${baseRenderSize.width.toInt()}x${baseRenderSize.height.toInt()} '
          'trimStart=${session.trimRange.start.inMilliseconds}ms '
          'trimDuration=${session.trimRange.duration.inMilliseconds}ms',
    );
    final attempts = _buildExportAttempts(session);
    List<String>? appliedArguments;
    String? appliedOutputPath;
    String? warning;
    final diagnostics = <String>[];
    var exported = false;

    for (var i = 0; i < attempts.length; i += 1) {
      final attempt = attempts[i];
      final attemptOutputPath = i == 0
          ? outputPath
          : await _localMediaLibraryService.createManagedVideoPath(
              prefix: 'edit_fallback_$i',
              extension: '.mp4',
            );
      final stagedOverlayImagePath = await _stageOverlayImage(
        session: attempt.session,
        assetBundle: _assetBundle,
        stagingDir: stagingDir.path,
        videoSize: scaleEditorRenderSize(
          baseRenderSize,
          attempt.renderScale,
          maxDimension: attempt.maxDimensionOverride,
        ),
      );
      final renderSize = scaleEditorRenderSize(
        baseRenderSize,
        attempt.renderScale,
        maxDimension: attempt.maxDimensionOverride,
      );
      final plan = await buildEditorExportPlan(
        session: attempt.session,
        outputPath: attemptOutputPath,
        stagingDir: stagingDir.path,
        assetBundle: _assetBundle,
        renderSize: renderSize,
        stagedOverlayImagePath: stagedOverlayImagePath,
        sourceHasAudio: sourceMediaInfo.hasAudio,
        sourceEncodedSize: sourceMediaInfo.size,
        sourceRotationDegrees: effectiveSourceRotationDegrees,
        videoCodec: attempt.videoCodec,
      );
      final executionResult = await _executeFfmpeg(plan.arguments);
      appliedArguments = plan.arguments;
      if (executionResult.success) {
        exported = true;
        appliedOutputPath = attemptOutputPath;
        warning = attempt.warning;
        final outputMediaInfo = await _probeSourceMediaInfo(attemptOutputPath);
        if (outputMediaInfo != null) {
          _logProbe(
            label: 'output',
            path: attemptOutputPath,
            info: outputMediaInfo,
            extra:
                'attempt=${attempt.label} '
                'warning=${warning ?? 'none'}',
          );
        }
        break;
      }
      diagnostics.add(
        'Attempt ${i + 1} (${attempt.label}) failed.\n'
        'Args: ${plan.arguments.join(' ')}\n'
        'Logs:\n${executionResult.logs ?? '(no logs)'}',
      );
    }

    if (!exported || appliedArguments == null || appliedOutputPath == null) {
      final diagnosticsFile = File(
        p.join(
          stagingDir.path,
          'export_error_${DateTime.now().millisecondsSinceEpoch}.log',
        ),
      );
      await diagnosticsFile.writeAsString(
        diagnostics.join('\n\n'),
        flush: true,
      );
      throw EditorExportException(
        'FFmpeg export failed. Diagnostics saved to ${diagnosticsFile.path}',
      );
    }

    final thumbnailPath = await _thumbnailService.createVideoThumbnail(
      videoPath: appliedOutputPath,
    );
    final exportedVideoId = _uuid.v4();
    final exportAspectRatio = baseRenderSize.width / baseRenderSize.height;
    await _database.saveLocalVideo(
      videoId: exportedVideoId,
      profileId: profileId,
      filePath: appliedOutputPath,
      thumbPath: thumbnailPath ?? '',
      title: title,
      durationSeconds: session.trimRange.duration.inMilliseconds / 1000,
      tags: const ['edited', 'remix'],
      approvalStatus: 'pending',
      aspectRatio: exportAspectRatio,
    );
    await _videoApprovalService.scanAndClassifyVideo(videoId: exportedVideoId);

    return EditorExportResult(
      videoId: exportedVideoId,
      outputPath: appliedOutputPath,
      thumbnailPath: thumbnailPath,
      arguments: appliedArguments,
      usedFallback: warning != null,
      warning: warning,
    );
  }
}

void _logProbe({
  required String label,
  required String path,
  required SourceMediaInfo info,
  String? extra,
}) {
  // Hook retained for local diagnostics when needed.
}

class _ExportAttempt {
  const _ExportAttempt({
    required this.label,
    required this.session,
    required this.videoCodec,
    this.renderScale = 1,
    this.maxDimensionOverride,
    this.warning,
  });

  final String label;
  final EditorSession session;
  final String videoCodec;
  final double renderScale;
  final double? maxDimensionOverride;
  final String? warning;
}

Future<EditorExportPlan> buildEditorExportPlan({
  required EditorSession session,
  required String outputPath,
  required String stagingDir,
  required AssetBundle assetBundle,
  required ui.Size renderSize,
  String videoCodec = 'libx264',
  String? stagedOverlayImagePath,
  bool sourceHasAudio = false,
  ui.Size? sourceEncodedSize,
  int sourceRotationDegrees = 0,
}) async {
  final filterPreset = EditorResourceCatalog.filterPresetById(
    session.filterPresetId,
  );
  final audioSelection = session.audioSelection;

  final arguments = <String>[
    '-y',
    '-ss',
    _secondsString(session.trimRange.start),
    '-t',
    _secondsString(session.trimRange.duration),
    '-noautorotate',
    '-i',
    session.sourcePath,
  ];

  String? stagedAudioPath;
  if (audioSelection != null) {
    stagedAudioPath = await _stageAssetFile(
      assetBundle: assetBundle,
      assetPath: audioSelection.assetPath,
      stagingDir: stagingDir,
    );
    arguments.addAll(['-stream_loop', '-1', '-i', stagedAudioPath]);
  }

  if (stagedOverlayImagePath != null) {
    arguments.addAll(['-i', stagedOverlayImagePath]);
  }

  final videoFilter = await _buildVideoFilterGraph(
    session: session,
    filterPreset: filterPreset,
    assetBundle: assetBundle,
    stagingDir: stagingDir,
    renderSize: renderSize,
    sourceEncodedSize: sourceEncodedSize,
    sourceRotationDegrees: sourceRotationDegrees,
  );
  final needsFilterComplex =
      audioSelection != null || stagedOverlayImagePath != null;
  if (videoFilter != null && !needsFilterComplex) {
    arguments.addAll(['-vf', videoFilter]);
  }

  if (needsFilterComplex) {
    final filterComplexParts = <String>[];
    var videoOutputMap = '0:v:0';

    if (videoFilter != null) {
      filterComplexParts.add('[0:v]$videoFilter[vfiltered]');
      videoOutputMap = '[vfiltered]';
    }

    final overlayInputIndex = stagedOverlayImagePath == null
        ? null
        : (audioSelection != null ? 2 : 1);
    if (overlayInputIndex != null) {
      final baseVideoRef = videoOutputMap == '0:v:0' ? '[0:v]' : videoOutputMap;
      filterComplexParts.add(
        '$baseVideoRef[$overlayInputIndex:v]overlay=0:0:format=auto[vout]',
      );
      videoOutputMap = '[vout]';
    }

    String? audioOutputMap;
    if (audioSelection != null && stagedAudioPath != null) {
      final musicInputIndex = 1;
      if (sourceHasAudio) {
        filterComplexParts.add('[0:a]volume=1.000[original]');
        if (audioSelection.startOffset > Duration.zero) {
          final delayMs = audioSelection.startOffset.inMilliseconds;
          filterComplexParts.add(
            '[$musicInputIndex:a]volume=${audioSelection.volume.toStringAsFixed(3)},adelay=$delayMs|$delayMs[music]',
          );
        } else {
          filterComplexParts.add(
            '[$musicInputIndex:a]volume=${audioSelection.volume.toStringAsFixed(3)}[music]',
          );
        }
        filterComplexParts.add(
          '[original][music]amix=inputs=2:duration=first:dropout_transition=2[aout]',
        );
        audioOutputMap = '[aout]';
      } else {
        if (audioSelection.startOffset > Duration.zero) {
          final delayMs = audioSelection.startOffset.inMilliseconds;
          filterComplexParts.add(
            '[$musicInputIndex:a]volume=${audioSelection.volume.toStringAsFixed(3)},adelay=$delayMs|$delayMs[music]',
          );
        } else {
          filterComplexParts.add(
            '[$musicInputIndex:a]volume=${audioSelection.volume.toStringAsFixed(3)}[music]',
          );
        }
        audioOutputMap = '[music]';
      }

      arguments.addAll([
        '-filter_complex',
        filterComplexParts.join(';'),
        '-map',
        videoOutputMap,
        '-map',
        audioOutputMap,
        '-shortest',
      ]);
    } else {
      arguments.addAll([
        '-filter_complex',
        filterComplexParts.join(';'),
        '-map',
        videoOutputMap,
      ]);

      if (sourceHasAudio) {
        arguments.addAll(['-map', '0:a?', '-shortest']);
      }
    }
  } else if (sourceHasAudio) {
    arguments.addAll(['-map', '0:v:0', '-map', '0:a?', '-shortest']);
  }

  arguments.addAll(['-c:v', videoCodec]);
  if (videoCodec == 'libx264') {
    arguments.addAll([
      '-preset',
      'fast',
      '-crf',
      '20',
      '-maxrate',
      '10000k',
      '-bufsize',
      '20000k',
    ]);
  } else {
    arguments.addAll(['-q:v', '4']);
  }
  arguments.addAll([
    '-pix_fmt',
    'yuv420p',
    '-metadata:s:v:0',
    'rotate=0',
    '-c:a',
    'aac',
    '-movflags',
    '+faststart',
    outputPath,
  ]);

  return EditorExportPlan(
    arguments: arguments,
    outputPath: outputPath,
    renderSize: renderSize,
  );
}

List<_ExportAttempt> _buildExportAttempts(EditorSession session) {
  return <_ExportAttempt>[
    _ExportAttempt(label: 'full', session: session, videoCodec: 'libx264'),
    _ExportAttempt(
      label: 'smaller_full',
      session: session,
      videoCodec: 'libx264',
      renderScale: 0.8,
    ),
    _ExportAttempt(
      label: 'safe_res',
      session: session,
      videoCodec: 'libx264',
      maxDimensionOverride: 1280,
      warning: 'Saved remix at a smaller size for this device.',
    ),
    _ExportAttempt(
      label: 'safe_codec',
      session: session,
      videoCodec: 'mpeg4',
      maxDimensionOverride: 1280,
      warning: 'Saved remix with a compatibility export path on this device.',
    ),
  ];
}

ui.Size normalizeEditorRenderSize(ui.Size input, {double maxDimension = 1920}) {
  final width = input.width <= 0 ? 720.0 : input.width;
  final height = input.height <= 0 ? 1280.0 : input.height;
  final longestSide = math.max(width, height);
  if (longestSide <= maxDimension) {
    return ui.Size(_makeEven(width), _makeEven(height));
  }
  final scale = maxDimension / longestSide;
  return ui.Size(_makeEven(width * scale), _makeEven(height * scale));
}

ui.Size scaleEditorRenderSize(
  ui.Size input,
  double scale, {
  double? maxDimension,
}) {
  final normalizedScale = scale.clamp(0.5, 1.0);
  return normalizeEditorRenderSize(
    ui.Size(input.width * normalizedScale, input.height * normalizedScale),
    maxDimension: maxDimension ?? math.max(input.width, input.height),
  );
}

Future<String?> _stageOverlayImage({
  required EditorSession session,
  required AssetBundle assetBundle,
  required String stagingDir,
  required ui.Size videoSize,
}) async {
  if (session.overlays.isEmpty) {
    return null;
  }

  final width = videoSize.width.round().clamp(1, 2048);
  final height = videoSize.height.round().clamp(1, 2048);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
  );

  for (final overlay in session.overlays) {
    switch (overlay.type) {
      case EditorOverlayType.sticker:
        final assetPath = overlay.stickerAssetPath;
        if (assetPath == null || assetPath.isEmpty) {
          continue;
        }
        ui.Image? image;
        try {
          image = await _loadOverlayImage(
            assetBundle: assetBundle,
            assetPath: assetPath,
          );
        } catch (_) {
          image = null;
        }
        if (image == null) {
          continue;
        }
        final baseSize = math.min(width.toDouble(), height.toDouble()) * 0.18;
        final stickerWidth = baseSize * overlay.transform.scale;
        final stickerHeight =
            stickerWidth * (image.height / image.width).clamp(0.4, 2.4);
        final center = Offset(
          overlay.transform.position.dx * width,
          overlay.transform.position.dy * height,
        );
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(overlay.transform.rotationDegrees * math.pi / 180);
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromCenter(
            center: Offset.zero,
            width: stickerWidth,
            height: stickerHeight,
          ),
          Paint(),
        );
        canvas.restore();
        image.dispose();
      case EditorOverlayType.text:
        final text = overlay.text?.trim();
        if (text == null || text.isEmpty) {
          continue;
        }
        final fontScale = height / 720;
        final textPainter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: overlay.textColorValue == null
                  ? const ui.Color(0xFFFFFFFF)
                  : ui.Color(overlay.textColorValue!),
              fontFamily: overlay.fontFamily,
              fontSize: overlay.textSize * fontScale,
              fontWeight: FontWeight.w800,
              shadows: const [
                Shadow(
                  blurRadius: 18,
                  color: ui.Color(0x99000000),
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 3,
        )..layout(maxWidth: width * 0.82);

        final textX = (width - textPainter.width) / 2;
        final textY = switch (overlay.textPosition) {
          EditorTextPosition.top => height * 0.12,
          EditorTextPosition.center => (height - textPainter.height) / 2,
          EditorTextPosition.bottom => height * 0.78 - textPainter.height,
        };
        textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (pngBytes == null) {
    return null;
  }
  final overlayFile = File(
    p.join(stagingDir, 'overlay_${DateTime.now().millisecondsSinceEpoch}.png'),
  );
  await overlayFile.writeAsBytes(pngBytes.buffer.asUint8List(), flush: true);
  return overlayFile.path;
}

Future<String?> _buildVideoFilterGraph({
  required EditorSession session,
  required EditorFilterPreset? filterPreset,
  required AssetBundle assetBundle,
  required String stagingDir,
  required ui.Size renderSize,
  ui.Size? sourceEncodedSize,
  int sourceRotationDegrees = 0,
}) async {
  final filters = <String>[];

  final normalizedRotation = ((sourceRotationDegrees % 360) + 360) % 360;
  if (_shouldBakeRotation(
    encodedSize: sourceEncodedSize,
    renderSize: renderSize,
    rotationDegrees: normalizedRotation,
  )) {
    switch (normalizedRotation) {
      case 90:
        filters.add('transpose=1');
      case 180:
        filters.add('transpose=1,transpose=1');
      case 270:
        filters.add('transpose=2');
    }
  }

  filters.add(
    'scale=${renderSize.width.round()}:${renderSize.height.round()}:flags=lanczos',
  );
  filters.add('setsar=1');

  if (filterPreset != null && filterPreset.engine == EditorFilterEngine.lut3d) {
    final lutId = filterPreset.lutAssetId;
    if (lutId != null) {
      final lutAsset = EditorResourceCatalog.lutById(lutId);
      if (lutAsset != null) {
        final stagedLutPath = await _stageAssetFile(
          assetBundle: assetBundle,
          assetPath: lutAsset.assetPath,
          stagingDir: stagingDir,
        );
        filters.add("lut3d=file='${_escapeFilterPath(stagedLutPath)}'");
      }
    }
  }

  final brightness =
      (filterPreset?.brightness ?? 0) + session.adjustments.brightness;
  final contrast = (filterPreset?.contrast ?? 1) * session.adjustments.contrast;
  final saturation =
      (filterPreset?.saturation ?? 1) * session.adjustments.saturation;

  if (brightness != 0 || contrast != 1 || saturation != 1) {
    filters.add(
      'eq=brightness=${brightness.toStringAsFixed(3)}:contrast=${contrast.toStringAsFixed(3)}:saturation=${saturation.toStringAsFixed(3)}',
    );
  }

  if (session.adjustments.sharpness > 0) {
    final sharp = (1 + session.adjustments.sharpness * 4).toStringAsFixed(3);
    filters.add('unsharp=5:5:$sharp:5:5:0.0');
  }

  if (session.adjustments.vignette > 0) {
    final angle = (session.adjustments.vignette * 1.2).toStringAsFixed(3);
    filters.add('vignette=angle=$angle');
  }

  if (filters.isEmpty) {
    return null;
  }

  return filters.join(',');
}

Future<String> _stageAssetFile({
  required AssetBundle assetBundle,
  required String assetPath,
  required String stagingDir,
}) async {
  final bytes = await assetBundle.load(assetPath);
  final file = File(p.join(stagingDir, p.basename(assetPath)));
  await file.create(recursive: true);
  await file.writeAsBytes(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    flush: true,
  );
  return file.path;
}

Future<ui.Image?> _loadOverlayImage({
  required AssetBundle assetBundle,
  required String assetPath,
}) async {
  Uint8List bytes;
  if (assetPath.startsWith('assets/')) {
    final data = await assetBundle.load(assetPath);
    bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } else {
    bytes = await File(assetPath).readAsBytes();
  }

  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

double _makeEven(double value) {
  final rounded = value.round();
  if (rounded.isEven) {
    return rounded.toDouble().clamp(2, 4096);
  }
  return (rounded - 1).toDouble().clamp(2, 4096);
}

String _secondsString(Duration duration) {
  return (duration.inMilliseconds / 1000).toStringAsFixed(3);
}

String _escapeFilterPath(String path) {
  // Within FFmpeg single-quoted filter option values, all characters are
  // literal except the single-quote itself. To embed a literal single-quote,
  // end the quoted section, add an escaped quote, and restart quoting.
  return path.replaceAll("'", r"'\''");
}

Future<FfmpegExecutionResult> _defaultExecuteFfmpeg(
  List<String> arguments,
) async {
  try {
    final session = await FFmpegKit.executeWithArguments(arguments);
    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();
    return FfmpegExecutionResult(
      success: ReturnCode.isSuccess(returnCode),
      logs: logs,
    );
  } on MissingPluginException catch (error) {
    return FfmpegExecutionResult(
      success: false,
      logs: 'FFmpeg is unavailable in this build: $error',
    );
  } on PlatformException catch (error) {
    return FfmpegExecutionResult(
      success: false,
      logs: 'FFmpeg failed to start: ${error.message ?? error.code}',
    );
  }
}

Future<SourceMediaInfo?> _defaultProbeSourceMediaInfo(String path) async {
  final probe = await probeVideoFile(path);
  if (probe == null) {
    return null;
  }
  return SourceMediaInfo(
    size: probe.encodedSize,
    hasAudio: probe.hasAudio,
    rotationDegrees: probe.rotationDegrees,
    displayAspectRatio: probe.reportedDisplayAspectRatio,
  );
}

ui.Size _displayOrientedSize(SourceMediaInfo info) {
  final aspectRatio = info.displayAspectRatio;
  if (aspectRatio != null && aspectRatio > 0) {
    return _sizeForAspectRatio(
      encodedSize: info.size,
      displayAspectRatio: aspectRatio,
    );
  }
  final normalizedRotation = ((info.rotationDegrees % 360) + 360) % 360;
  if (normalizedRotation == 90 || normalizedRotation == 270) {
    return ui.Size(info.size.height, info.size.width);
  }
  return info.size;
}

bool _shouldBakeRotation({
  required ui.Size? encodedSize,
  required ui.Size renderSize,
  required int rotationDegrees,
}) {
  if (rotationDegrees == 0) {
    return false;
  }
  if (rotationDegrees == 180) {
    return true;
  }
  if (rotationDegrees != 90 && rotationDegrees != 270) {
    return false;
  }
  if (encodedSize == null) {
    return true;
  }

  final encodedOrientation = _orientationForSize(encodedSize);
  final renderOrientation = _orientationForSize(renderSize);
  if (encodedOrientation == _VideoOrientation.square ||
      renderOrientation == _VideoOrientation.square) {
    return true;
  }
  return encodedOrientation != renderOrientation;
}

ui.Size _sizeForAspectRatio({
  required ui.Size encodedSize,
  required double displayAspectRatio,
}) {
  final normalizedAspectRatio = displayAspectRatio.abs();
  if (normalizedAspectRatio <= 0) {
    return encodedSize;
  }

  final longestSide = math.max(encodedSize.width, encodedSize.height);
  if (normalizedAspectRatio >= 1) {
    return ui.Size(longestSide, longestSide / normalizedAspectRatio);
  }
  return ui.Size(longestSide * normalizedAspectRatio, longestSide);
}

_VideoOrientation _orientationForSize(ui.Size size) {
  if ((size.width - size.height).abs() < 0.5) {
    return _VideoOrientation.square;
  }
  return size.width > size.height
      ? _VideoOrientation.landscape
      : _VideoOrientation.portrait;
}

enum _VideoOrientation { portrait, landscape, square }

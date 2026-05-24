import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/storage/app_database.dart';
import 'package:mytube/domain/models/content_scan_summary.dart';
import 'package:mytube/domain/models/editor_session.dart';
import 'package:mytube/services/approval/content_scan_service.dart';
import 'package:mytube/services/approval/media_signal_extraction_service.dart';
import 'package:mytube/services/approval/video_approval_service.dart';
import 'package:mytube/services/editor/editor_export_service.dart';
import 'package:mytube/services/media/local_media_library_service.dart';
import 'package:mytube/services/media/thumbnail_service.dart';

class _FakeThumbnailService extends ThumbnailService {
  @override
  Future<String?> createVideoThumbnail({required String videoPath}) async {
    return '$videoPath.jpg';
  }
}

class _FakeVideoApprovalService extends VideoApprovalService {
  _FakeVideoApprovalService({required super.database})
    : super(
        scanService: const ContentScanService(),
        signalExtractionService: MediaSignalExtractionService(
          extractSignals: (video) async => MediaSignalExtractionResult(
            cvLabels: const [],
            faceCount: 0,
            loudness: 0,
          ),
        ),
      );

  @override
  Future<ContentScanSummary> scanAndClassifyVideo({
    required String videoId,
  }) async {
    return const ContentScanSummary(
      scanVersion: 1,
      riskLevel: 'low',
      highestRiskCategory: null,
      confidence: 0,
      reviewReasons: [],
      flags: [],
      labels: [],
      needsReview: false,
      summary: 'clear',
    );
  }
}

class _FakeAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    return ByteData.sublistView(Uint8List.fromList(const [1, 2, 3, 4]));
  }
}

void main() {
  test(
    'buildEditorExportPlan creates trim, lut, and soundtrack arguments',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 12),
          trimRange: EditorTrimRange(
            start: Duration(seconds: 2),
            end: Duration(seconds: 8),
          ),
          filterPresetId: 'warm',
          audioSelection: EditorAudioSelection(
            trackId: 'track_01',
            assetPath: 'assets/editor/music/track_01.mp3',
            volume: 0.5,
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(
        plan.arguments,
        containsAllInOrder(['-ss', '2.000', '-t', '6.000', '-noautorotate']),
      );
      expect(plan.arguments, contains('/tmp/input.mp4'));
      expect(plan.arguments, contains('/tmp/output.mp4'));
      expect(
        plan.arguments,
        containsAllInOrder(['-metadata:s:v:0', 'rotate=0']),
      );
      expect(
        plan.arguments.where((value) => value.contains('lut3d=file=')).single,
        contains('vintage.cube'),
      );
      expect(
        plan.arguments.where((value) => value.contains('setsar=1')).single,
        contains('setsar=1'),
      );
      expect(
        plan.arguments
            .where((value) => value.contains('[1:a]volume=0.500'))
            .single,
        contains('[music]'),
      );
      expect(
        plan.arguments,
        containsAllInOrder(['-map', '[music]', '-shortest']),
      );
      expect(
        plan.arguments,
        containsAllInOrder([
          '-c:v',
          'libx264',
          '-preset',
          'fast',
          '-crf',
          '22',
          '-maxrate',
          '8000k',
          '-bufsize',
          '16000k',
        ]),
      );
    },
  );

  test('buildEditorExportPlan lowers bitrate for long exports', () async {
    final plan = await buildEditorExportPlan(
      session: const EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/input.mp4',
        videoDuration: Duration(minutes: 3),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(minutes: 3),
        ),
      ),
      outputPath: '/tmp/output.mp4',
      stagingDir: '/tmp/editor-staging',
      assetBundle: _FakeAssetBundle(),
      renderSize: const ui.Size(720, 1280),
      sourceRotationDegrees: 0,
    );

    expect(
      plan.arguments,
      containsAllInOrder(['-maxrate', '4002k', '-bufsize', '8004k']),
    );
  });

  test(
    'buildEditorExportPlan uses named eq parameters for eq presets',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 8),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 8),
          ),
          filterPresetId: 'vivid',
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(
        plan.arguments
            .where((value) => value.contains('eq=brightness='))
            .single,
        allOf(contains('contrast='), contains('saturation=')),
      );
    },
  );

  test(
    'buildEditorExportPlan omits soundtrack graph when no music is selected',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(plan.arguments, isNot(contains('-filter_complex')));
      expect(plan.arguments, isNot(contains('-stream_loop')));
    },
  );

  test(
    'buildEditorExportPlan leaves neutral playback speed unfiltered',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
          playbackSpeed: 1.0,
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        sourceHasAudio: true,
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(plan.arguments.join(' '), isNot(contains('setpts=')));
      expect(plan.arguments.join(' '), isNot(contains('atempo=')));
    },
  );

  for (final entry in <(double, String, String)>[
    (2.0, 'setpts=PTS/2.0', 'atempo=2.0'),
    (0.5, 'setpts=PTS/0.5', 'atempo=0.5'),
    (4.0, 'setpts=PTS/4.0', 'atempo=2.0,atempo=2.0'),
    (0.25, 'setpts=PTS/0.25', 'atempo=0.5,atempo=0.5'),
  ]) {
    test(
      'buildEditorExportPlan applies ${entry.$1}x playback speed filters',
      () async {
        final plan = await buildEditorExportPlan(
          session: EditorSession(
            videoId: 'video-1',
            sourcePath: '/tmp/input.mp4',
            videoDuration: const Duration(seconds: 10),
            trimRange: const EditorTrimRange(
              start: Duration.zero,
              end: Duration(seconds: 10),
            ),
            playbackSpeed: entry.$1,
          ),
          outputPath: '/tmp/output.mp4',
          stagingDir: '/tmp/editor-staging',
          assetBundle: _FakeAssetBundle(),
          sourceHasAudio: true,
          renderSize: const ui.Size(720, 1280),
          sourceRotationDegrees: 0,
        );

        final filterComplex =
            plan.arguments[plan.arguments.indexOf('-filter_complex') + 1];
        expect(filterComplex, contains(entry.$2));
        expect(filterComplex, contains('[0:a]${entry.$3}[aout]'));
      },
    );
  }

  test(
    'buildEditorExportPlan adds overlay compositing when a staged overlay exists',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        stagedOverlayImagePath: '/tmp/overlay.png',
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(plan.arguments, contains('/tmp/overlay.png'));
      expect(
        plan.arguments
            .where((value) => value.contains('overlay=0:0:format=auto'))
            .single,
        contains('[1:v]'),
      );
      expect(plan.arguments, containsAllInOrder(['-map', '[vout]']));
    },
  );

  test(
    'buildEditorExportPlan omits drawing input when strokes are empty',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(plan.arguments.where((value) => value == '-i'), hasLength(1));
      expect(plan.arguments.join(' '), isNot(contains('overlay=0:0')));
    },
  );

  test(
    'buildEditorExportPlan adds drawing input after existing overlays',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
          strokes: [
            EditorStroke(
              id: 'stroke-1',
              tool: EditorDrawTool.pencil,
              colorValue: 0xffffffff,
              width: 6,
              points: [Offset(0.1, 0.1), Offset(0.9, 0.9)],
            ),
          ],
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        stagedOverlayImagePath: '/tmp/overlay.png',
        stagedDrawingImagePath: '/tmp/drawing.png',
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(
        plan.arguments,
        containsAllInOrder([
          '-i',
          '/tmp/input.mp4',
          '-i',
          '/tmp/overlay.png',
          '-i',
          '/tmp/drawing.png',
        ]),
      );
      final filterComplex =
          plan.arguments[plan.arguments.indexOf('-filter_complex') + 1];
      expect(filterComplex, contains('[1:v]overlay=0:0:format=auto[voverlay]'));
      expect(
        filterComplex,
        contains('[voverlay][2:v]overlay=0:0:format=auto[vout]'),
      );
    },
  );

  test(
    'buildEditorExportPlan mixes original audio with soundtrack when source audio exists',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 12),
          trimRange: EditorTrimRange(
            start: Duration(seconds: 1),
            end: Duration(seconds: 9),
          ),
          audioSelection: EditorAudioSelection(
            trackId: 'track_01',
            assetPath: 'assets/editor/music/track_01.mp3',
            volume: 0.4,
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        sourceHasAudio: true,
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      final filterComplex =
          plan.arguments[plan.arguments.indexOf('-filter_complex') + 1];
      expect(filterComplex, contains('[0:a]volume=1.000[original]'));
      expect(
        filterComplex,
        contains(
          '[1:a]volume=0.400,atrim=duration=8.000,asetpts=N/SR/TB[music]',
        ),
      );
      expect(
        filterComplex,
        contains(
          '[original][music]amix=inputs=2:duration=first:dropout_transition=2[aout]',
        ),
      );
      expect(
        plan.arguments,
        containsAllInOrder(['-map', '[aout]', '-shortest']),
      );
    },
  );

  test(
    'buildEditorExportPlan preserves source audio when overlays are present without soundtrack',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        stagedOverlayImagePath: '/tmp/overlay.png',
        sourceHasAudio: true,
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      expect(
        plan.arguments,
        containsAllInOrder(['-map', '[vout]', '-map', '0:a?', '-shortest']),
      );
    },
  );

  test('normalizeEditorRenderSize keeps output even and capped', () {
    expect(
      normalizeEditorRenderSize(const ui.Size(2160, 3840)),
      const ui.Size(1080, 1920),
    );
    expect(
      normalizeEditorRenderSize(const ui.Size(1081, 1921)),
      const ui.Size(1080, 1920),
    );
  });

  test(
    'buildEditorExportPlan uses qscale fallback for mpeg4 exports',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
        videoCodec: 'mpeg4',
      );

      expect(
        plan.arguments,
        containsAllInOrder(['-c:v', 'mpeg4', '-q:v', '4']),
      );
      expect(plan.arguments, isNot(contains('-crf')));
      expect(plan.arguments, isNot(contains('-preset')));
    },
  );

  test('scaleEditorRenderSize respects an explicit max dimension override', () {
    expect(
      scaleEditorRenderSize(const ui.Size(1080, 1920), 1, maxDimension: 1280),
      const ui.Size(720, 1280),
    );
  });

  test(
    'buildEditorExportPlan disables ffmpeg autorotate before applying manual rotation',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceEncodedSize: const ui.Size(1280, 720),
        sourceRotationDegrees: 90,
      );

      expect(plan.arguments, containsAllInOrder(['-noautorotate', '-i']));
      expect(
        plan.arguments.where((value) => value.contains('transpose=1')).single,
        contains('scale=720:1280'),
      );
    },
  );

  test(
    'buildEditorExportPlan does not double-rotate portrait sources that already match the render orientation',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceEncodedSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 90,
      );

      final videoFilter = plan.arguments[plan.arguments.indexOf('-vf') + 1];
      expect(videoFilter, isNot(contains('transpose=')));
      expect(videoFilter, contains('scale=720:1280'));
    },
  );

  test(
    'buildEditorExportPlan combines overlay and soundtrack in a single filter_complex',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 12),
          trimRange: EditorTrimRange(
            start: Duration(seconds: 1),
            end: Duration(seconds: 9),
          ),
          filterPresetId: 'warm',
          audioSelection: EditorAudioSelection(
            trackId: 'track_01',
            assetPath: 'assets/editor/music/track_01.mp3',
            volume: 0.5,
          ),
          adjustments: EditorAdjustments(sharpness: 0.5, vignette: 0.3),
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/editor-staging',
        assetBundle: _FakeAssetBundle(),
        stagedOverlayImagePath: '/tmp/overlay.png',
        sourceHasAudio: true,
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      // Overlay image is input 2 (audio is input 1).
      expect(plan.arguments, contains('/tmp/overlay.png'));
      final filterComplex =
          plan.arguments[plan.arguments.indexOf('-filter_complex') + 1];
      expect(filterComplex, contains('[2:v]overlay=0:0:format=auto[vout]'));
      expect(filterComplex, contains('[0:a]volume=1.000[original]'));
      expect(
        filterComplex,
        contains(
          '[1:a]volume=0.500,atrim=duration=8.000,asetpts=N/SR/TB[music]',
        ),
      );
      expect(
        filterComplex,
        contains(
          '[original][music]amix=inputs=2:duration=first:dropout_transition=2[aout]',
        ),
      );
      expect(
        plan.arguments,
        containsAllInOrder(['-map', '[vout]', '-map', '[aout]', '-shortest']),
      );
      // Video effects should be in the filter_complex, not -vf.
      expect(plan.arguments, isNot(contains('-vf')));
      expect(filterComplex, contains('lut3d=file='));
      expect(filterComplex, contains('unsharp='));
      expect(filterComplex, contains('vignette='));
    },
  );

  test(
    'buildEditorExportPlan does not corrupt lut3d paths containing spaces',
    () async {
      final plan = await buildEditorExportPlan(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
          filterPresetId: 'warm',
        ),
        outputPath: '/tmp/output.mp4',
        stagingDir: '/tmp/Application Support/editor staging',
        assetBundle: _FakeAssetBundle(),
        renderSize: const ui.Size(720, 1280),
        sourceRotationDegrees: 0,
      );

      final videoFilter = plan.arguments[plan.arguments.indexOf('-vf') + 1];
      // The path is wrapped in single quotes within the filter string.
      // Spaces must NOT be backslash-escaped inside single quotes, otherwise
      // FFmpeg will look for a path with literal backslash characters.
      expect(videoFilter, isNot(contains(r'\ ')));
      expect(videoFilter, contains("lut3d=file='"));
    },
  );

  test(
    'EditorExportService saves remixes into the local videos library',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.upsertProfile(
        id: 'profile-1',
        name: 'Emma',
        theme: 'campfire',
        avatarAsset: 'assets/avatar.png',
      );

      final tempRoot = await Directory.systemTemp.createTemp(
        'editor-export-test',
      );
      addTearDown(() async {
        if (tempRoot.existsSync()) {
          await tempRoot.delete(recursive: true);
        }
      });
      final documentsDir = Directory('${tempRoot.path}/documents')
        ..createSync(recursive: true);
      final supportDir = Directory('${tempRoot.path}/support')
        ..createSync(recursive: true);
      final mediaLibrary = LocalMediaLibraryService(
        documentsDirectoryProvider: () async => documentsDir,
        supportDirectoryProvider: () async => supportDir,
      );
      final service = EditorExportService(
        database: database,
        thumbnailService: _FakeThumbnailService(),
        videoApprovalService: _FakeVideoApprovalService(database: database),
        localMediaLibraryService: mediaLibrary,
        assetBundle: _FakeAssetBundle(),
        executeFfmpeg: (arguments) async =>
            const FfmpegExecutionResult(success: true),
        probeSourceMediaInfo: (path) async =>
            const SourceMediaInfo(size: ui.Size(720, 1280), hasAudio: false),
      );

      final result = await service.export(
        session: const EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/input.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        ),
        profileId: 'profile-1',
        title: 'Remix',
      );
      final saved = await database.getLocalVideoById(result.videoId);

      expect(result.outputPath, contains('${documentsDir.path}/videos/'));
      expect(saved?.filePath, result.outputPath);
    },
  );

  test('EditorExportService deletes staged drawing PNG after export', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    await database.upsertProfile(
      id: 'profile-1',
      name: 'Emma',
      theme: 'campfire',
      avatarAsset: 'assets/avatar.png',
    );

    final tempRoot = await Directory.systemTemp.createTemp(
      'editor-drawing-export-test',
    );
    addTearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });
    final documentsDir = Directory('${tempRoot.path}/documents')
      ..createSync(recursive: true);
    final supportDir = Directory('${tempRoot.path}/support')
      ..createSync(recursive: true);
    final mediaLibrary = LocalMediaLibraryService(
      documentsDirectoryProvider: () async => documentsDir,
      supportDirectoryProvider: () async => supportDir,
    );
    String? stagedDrawingPath;
    final service = EditorExportService(
      database: database,
      thumbnailService: _FakeThumbnailService(),
      videoApprovalService: _FakeVideoApprovalService(database: database),
      localMediaLibraryService: mediaLibrary,
      assetBundle: _FakeAssetBundle(),
      executeFfmpeg: (arguments) async {
        stagedDrawingPath = arguments.firstWhere(
          (argument) => argument.contains('/drawing_'),
        );
        expect(File(stagedDrawingPath!).existsSync(), isTrue);
        return const FfmpegExecutionResult(success: true);
      },
      probeSourceMediaInfo: (path) async =>
          const SourceMediaInfo(size: ui.Size(720, 1280), hasAudio: false),
    );

    await service.export(
      session: const EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/input.mp4',
        videoDuration: Duration(seconds: 10),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 10),
        ),
        strokes: [
          EditorStroke(
            id: 'stroke-1',
            tool: EditorDrawTool.marker,
            colorValue: 0xffff0000,
            width: 12,
            points: [Offset(0.1, 0.1), Offset(0.9, 0.9)],
          ),
        ],
      ),
      profileId: 'profile-1',
      title: 'Remix',
    );

    expect(stagedDrawingPath, isNotNull);
    expect(File(stagedDrawingPath!).existsSync(), isFalse);
  });
}

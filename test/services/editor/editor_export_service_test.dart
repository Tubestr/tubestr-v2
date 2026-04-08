import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/editor_session.dart';
import 'package:mytube/services/editor/editor_export_service.dart';

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
          '20',
          '-maxrate',
          '10000k',
          '-bufsize',
          '20000k',
        ]),
      );
    },
  );

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
      expect(filterComplex, contains('[1:a]volume=0.400[music]'));
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
      expect(filterComplex, contains('[1:a]volume=0.500[music]'));
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
}

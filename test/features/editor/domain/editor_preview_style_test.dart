import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mytube/domain/models/editor_session.dart';
import 'package:mytube/features/editor/domain/editor_preview_style.dart';

void main() {
  group('buildEditorPreviewStyle', () {
    test('builds a neutral matrix for the default session', () {
      const session = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 12),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 12),
        ),
      );

      final style = buildEditorPreviewStyle(session);

      expect(style.colorMatrix, hasLength(20));
      expect(style.tintColor, isNull);
      expect(style.tintOpacity, 0);
      expect(style.vignetteStrength, 0);
    });

    test('applies a tint and vignette for warm and matte looks', () {
      const warmSession = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 12),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 12),
        ),
        filterPresetId: 'warm',
      );
      const matteSession = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 12),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 12),
        ),
        filterPresetId: 'matte',
      );

      final warmStyle = buildEditorPreviewStyle(warmSession);
      final matteStyle = buildEditorPreviewStyle(matteSession);

      expect(warmStyle.tintColor, const Color(0xFFFF9F43));
      expect(warmStyle.tintOpacity, greaterThan(0));
      expect(matteStyle.tintColor, const Color(0xFFF5D6B4));
      expect(matteStyle.vignetteStrength, greaterThan(0));
    });

    test('keeps noir desaturated even with user adjustments', () {
      const session = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 12),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 12),
        ),
        filterPresetId: 'noir',
        adjustments: EditorAdjustments(
          brightness: 0.2,
          contrast: 1.1,
          saturation: 1.7,
          vignette: 0.4,
        ),
      );

      final style = buildEditorPreviewStyle(session);

      expect(style.tintColor, isNull);
      expect(style.vignetteStrength, greaterThan(0.4));
      expect(style.colorMatrix[1], greaterThan(0));
      expect(style.colorMatrix[2], greaterThan(0));
      expect(style.colorMatrix[5], greaterThan(0));
      expect(style.colorMatrix[10], greaterThan(0));
    });
  });
}

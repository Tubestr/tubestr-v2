import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/domain/models/editor_session.dart';

void main() {
  group('StickerTransform', () {
    test('uses centered identity transform defaults', () {
      const transform = StickerTransform();

      expect(transform.position, const Offset(0.5, 0.5));
      expect(transform.scale, 1);
      expect(transform.rotationDegrees, 0);
    });

    test('copyWith overrides values and preserves omitted fields', () {
      const transform = StickerTransform(
        position: Offset(0.1, 0.2),
        scale: 2,
        rotationDegrees: 45,
      );

      final copied = transform.copyWith(
        position: const Offset(0.3, 0.4),
        scale: 3,
      );

      expect(copied, isNot(same(transform)));
      expect(copied.position, const Offset(0.3, 0.4));
      expect(copied.scale, 3);
      expect(copied.rotationDegrees, 45);
    });
  });

  group('EditorTrimRange', () {
    test('duration returns end minus start', () {
      const trimRange = EditorTrimRange(
        start: Duration(seconds: 3),
        end: Duration(seconds: 11),
      );

      expect(trimRange.duration, const Duration(seconds: 8));
    });

    test('copyWith preserves untouched field', () {
      const trimRange = EditorTrimRange(
        start: Duration(seconds: 3),
        end: Duration(seconds: 11),
      );

      final copied = trimRange.copyWith(end: const Duration(seconds: 15));

      expect(copied.start, const Duration(seconds: 3));
      expect(copied.end, const Duration(seconds: 15));
    });
  });

  group('EditorOverlayItem', () {
    test('uses text size and transform defaults', () {
      const item = EditorOverlayItem(
        id: 'overlay-1',
        type: EditorOverlayType.text,
      );

      expect(item.textSize, 40);
      expect(item.transform.position, const Offset(0.5, 0.5));
      expect(item.transform.scale, 1);
      expect(item.transform.rotationDegrees, 0);
    });

    test('copyWith overrides each field', () {
      const item = EditorOverlayItem(
        id: 'overlay-1',
        type: EditorOverlayType.sticker,
        stickerId: 'sticker-1',
        stickerAssetPath: 'assets/sticker-1.png',
        text: 'hello',
        fontFamily: 'Inter',
        textColorValue: 0xff000000,
        textSize: 24,
        transform: StickerTransform(scale: 2),
      );

      const transform = StickerTransform(
        position: Offset(0.2, 0.8),
        scale: 1.5,
        rotationDegrees: 30,
      );
      final copied = item.copyWith(
        id: 'overlay-2',
        type: EditorOverlayType.text,
        stickerId: 'sticker-2',
        stickerAssetPath: 'assets/sticker-2.png',
        text: 'updated',
        fontFamily: 'Roboto',
        textColorValue: 0xffffffff,
        textSize: 32,
        transform: transform,
      );

      expect(copied.id, 'overlay-2');
      expect(copied.type, EditorOverlayType.text);
      expect(copied.stickerId, 'sticker-2');
      expect(copied.stickerAssetPath, 'assets/sticker-2.png');
      expect(copied.text, 'updated');
      expect(copied.fontFamily, 'Roboto');
      expect(copied.textColorValue, 0xffffffff);
      expect(copied.textSize, 32);
      expect(copied.transform, same(transform));
    });

    test('copyWith preserves un-passed fields', () {
      const transform = StickerTransform(scale: 2);
      const item = EditorOverlayItem(
        id: 'overlay-1',
        type: EditorOverlayType.sticker,
        stickerId: 'sticker-1',
        stickerAssetPath: 'assets/sticker-1.png',
        text: 'hello',
        fontFamily: 'Inter',
        textColorValue: 0xff000000,
        textSize: 24,
        transform: transform,
      );

      final copied = item.copyWith(text: 'updated');

      expect(copied.id, 'overlay-1');
      expect(copied.type, EditorOverlayType.sticker);
      expect(copied.stickerId, 'sticker-1');
      expect(copied.stickerAssetPath, 'assets/sticker-1.png');
      expect(copied.text, 'updated');
      expect(copied.fontFamily, 'Inter');
      expect(copied.textColorValue, 0xff000000);
      expect(copied.textSize, 24);
      expect(copied.transform, same(transform));
    });
  });

  group('EditorAudioSelection', () {
    test('uses start offset and volume defaults', () {
      const selection = EditorAudioSelection(
        trackId: 'track-1',
        assetPath: 'assets/audio.mp3',
      );

      expect(selection.startOffset, Duration.zero);
      expect(selection.volume, 0.75);
    });

    test('copyWith overrides each field', () {
      const selection = EditorAudioSelection(
        trackId: 'track-1',
        assetPath: 'assets/audio.mp3',
      );

      final copied = selection.copyWith(
        trackId: 'track-2',
        assetPath: 'assets/updated.mp3',
        startOffset: const Duration(seconds: 4),
        volume: 0.5,
      );

      expect(copied.trackId, 'track-2');
      expect(copied.assetPath, 'assets/updated.mp3');
      expect(copied.startOffset, const Duration(seconds: 4));
      expect(copied.volume, 0.5);
    });
  });

  group('EditorStroke', () {
    test('stores required drawing fields', () {
      const stroke = EditorStroke(
        id: 'stroke-1',
        tool: EditorDrawTool.pencil,
        colorValue: 0xffffffff,
        width: 6,
        points: [Offset(0.1, 0.2)],
      );

      expect(stroke.id, 'stroke-1');
      expect(stroke.tool, EditorDrawTool.pencil);
      expect(stroke.colorValue, 0xffffffff);
      expect(stroke.width, 6);
      expect(stroke.points, const [Offset(0.1, 0.2)]);
    });

    test('copyWith overrides values and preserves omitted fields', () {
      const points = [Offset(0.1, 0.2)];
      const stroke = EditorStroke(
        id: 'stroke-1',
        tool: EditorDrawTool.marker,
        colorValue: 0xffff0000,
        width: 12,
        points: points,
      );

      final copied = stroke.copyWith(tool: EditorDrawTool.eraser, width: 18);

      expect(copied.id, 'stroke-1');
      expect(copied.tool, EditorDrawTool.eraser);
      expect(copied.colorValue, 0xffff0000);
      expect(copied.width, 18);
      expect(copied.points, same(points));
    });
  });

  group('EditorAdjustments', () {
    test('uses neutral adjustment defaults', () {
      const adjustments = EditorAdjustments();

      expect(adjustments.brightness, 0);
      expect(adjustments.contrast, 1);
      expect(adjustments.saturation, 1);
      expect(adjustments.sharpness, 0);
      expect(adjustments.vignette, 0);
    });

    test('copyWith overrides each field and preserves others', () {
      const adjustments = EditorAdjustments(
        brightness: 0.1,
        contrast: 1.2,
        saturation: 1.3,
        sharpness: 0.4,
        vignette: 0.5,
      );

      final copied = adjustments.copyWith(
        brightness: 0.2,
        contrast: 1.4,
        saturation: 1.6,
        sharpness: 0.8,
        vignette: 1,
      );
      final partiallyCopied = adjustments.copyWith(contrast: 2);

      expect(copied.brightness, 0.2);
      expect(copied.contrast, 1.4);
      expect(copied.saturation, 1.6);
      expect(copied.sharpness, 0.8);
      expect(copied.vignette, 1);
      expect(partiallyCopied.brightness, 0.1);
      expect(partiallyCopied.contrast, 2);
      expect(partiallyCopied.saturation, 1.3);
      expect(partiallyCopied.sharpness, 0.4);
      expect(partiallyCopied.vignette, 0.5);
    });
  });

  group('EditorSession', () {
    test(
      'uses filter, speed, adjustments, overlays, strokes, and audio defaults',
      () {
        const session = EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/video.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
        );

        expect(session.filterPresetId, 'none');
        expect(session.playbackSpeed, 1.0);
        expect(session.adjustments.brightness, 0);
        expect(session.adjustments.contrast, 1);
        expect(session.adjustments.saturation, 1);
        expect(session.adjustments.sharpness, 0);
        expect(session.adjustments.vignette, 0);
        expect(session.overlays, isEmpty);
        expect(session.strokes, isEmpty);
        expect(session.audioSelection, isNull);
      },
    );

    test('copyWith preserves un-passed fields', () {
      const trimRange = EditorTrimRange(
        start: Duration(seconds: 1),
        end: Duration(seconds: 9),
      );
      const adjustments = EditorAdjustments(brightness: 0.2);
      const overlays = <EditorOverlayItem>[
        EditorOverlayItem(id: 'overlay-1', type: EditorOverlayType.text),
      ];
      const strokes = <EditorStroke>[
        EditorStroke(
          id: 'stroke-1',
          tool: EditorDrawTool.pencil,
          colorValue: 0xffffffff,
          width: 6,
          points: [Offset(0.2, 0.3)],
        ),
      ];
      const audioSelection = EditorAudioSelection(
        trackId: 'track-1',
        assetPath: 'assets/audio.mp3',
      );
      const session = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 10),
        trimRange: trimRange,
        filterPresetId: 'warm',
        playbackSpeed: 1.5,
        adjustments: adjustments,
        overlays: overlays,
        strokes: strokes,
        audioSelection: audioSelection,
      );

      final copied = session.copyWith(sourcePath: '/tmp/updated.mp4');

      expect(copied.videoId, 'video-1');
      expect(copied.sourcePath, '/tmp/updated.mp4');
      expect(copied.videoDuration, const Duration(seconds: 10));
      expect(copied.trimRange, same(trimRange));
      expect(copied.filterPresetId, 'warm');
      expect(copied.playbackSpeed, 1.5);
      expect(copied.adjustments, same(adjustments));
      expect(copied.overlays, same(overlays));
      expect(copied.strokes, same(strokes));
      expect(copied.audioSelection, same(audioSelection));
    });

    test('copyWith replaces strokes', () {
      const session = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 10),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 10),
        ),
      );
      const strokes = <EditorStroke>[
        EditorStroke(
          id: 'stroke-1',
          tool: EditorDrawTool.marker,
          colorValue: 0xffff0000,
          width: 12,
          points: [Offset(0.1, 0.2), Offset(0.3, 0.4)],
        ),
      ];

      final copied = session.copyWith(strokes: strokes);

      expect(copied.strokes, same(strokes));
    });

    test('copyWith replaces playback speed', () {
      const session = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 10),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 10),
        ),
      );

      final copied = session.copyWith(playbackSpeed: 2);

      expect(copied.playbackSpeed, 2);
    });

    test('clampPlaybackSpeed clamps to supported boundaries', () {
      expect(EditorSession.clampPlaybackSpeed(0.1), 0.25);
      expect(EditorSession.clampPlaybackSpeed(0.25), 0.25);
      expect(EditorSession.clampPlaybackSpeed(1.5), 1.5);
      expect(EditorSession.clampPlaybackSpeed(4.0), 4.0);
      expect(EditorSession.clampPlaybackSpeed(8.0), 4.0);
    });

    test(
      'copyWith clearAudioSelection nulls audio selection when one is passed',
      () {
        const session = EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/video.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
          audioSelection: EditorAudioSelection(
            trackId: 'track-1',
            assetPath: 'assets/audio.mp3',
          ),
        );

        final copied = session.copyWith(
          audioSelection: const EditorAudioSelection(
            trackId: 'track-2',
            assetPath: 'assets/updated.mp3',
          ),
          clearAudioSelection: true,
        );

        expect(copied.audioSelection, isNull);
      },
    );

    test(
      'copyWith keeps existing audio selection when no new value is passed',
      () {
        const audioSelection = EditorAudioSelection(
          trackId: 'track-1',
          assetPath: 'assets/audio.mp3',
        );
        const session = EditorSession(
          videoId: 'video-1',
          sourcePath: '/tmp/video.mp4',
          videoDuration: Duration(seconds: 10),
          trimRange: EditorTrimRange(
            start: Duration.zero,
            end: Duration(seconds: 10),
          ),
          audioSelection: audioSelection,
        );

        final copied = session.copyWith();

        expect(copied.audioSelection, same(audioSelection));
      },
    );

    test('copyWith replaces existing audio selection with a new value', () {
      const session = EditorSession(
        videoId: 'video-1',
        sourcePath: '/tmp/video.mp4',
        videoDuration: Duration(seconds: 10),
        trimRange: EditorTrimRange(
          start: Duration.zero,
          end: Duration(seconds: 10),
        ),
        audioSelection: EditorAudioSelection(
          trackId: 'track-1',
          assetPath: 'assets/audio.mp3',
        ),
      );
      const audioSelection = EditorAudioSelection(
        trackId: 'track-2',
        assetPath: 'assets/updated.mp3',
      );

      final copied = session.copyWith(audioSelection: audioSelection);

      expect(copied.audioSelection, same(audioSelection));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/core/theme/theme_descriptor.dart';
import 'package:mytube/domain/models/editor_resources.dart';
import 'package:mytube/domain/models/editor_session.dart';
import 'package:mytube/features/editor/presentation/editor_detail_page.dart';
import 'package:mytube/l10n/app_localizations.dart';
import 'package:mytube/l10n/app_localizations_en.dart';

// A full EditorDetailPage smoke test is intentionally skipped here because the
// page initializes media_kit Player/VideoController, whose native runtime is
// unavailable in Flutter widget tests. The tests below exercise the real
// page-level private widgets through stable @visibleForTesting builders so they
// survive extraction into separate files.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final palette = ThemeDescriptor.campfire.lightPalette;
  final l10n = AppLocalizationsEn();

  testWidgets(
    'full EditorDetailPage smoke is covered outside widget tests',
    (tester) async {},
    skip: true,
  );

  testWidgets('side toolbar opens and closes each tool button', (tester) async {
    final selections = <EditorTool?>[];
    EditorTool? activeTool;

    await tester.pumpLocalized(
      StatefulBuilder(
        builder: (context, setState) {
          return buildEditorDetailPageSideToolbarForTest(
            palette: palette,
            activeTool: activeTool,
            onToolTap: (tool) {
              setState(() {
                activeTool = activeTool == tool ? null : tool;
                selections.add(activeTool);
              });
            },
          );
        },
      ),
    );

    for (final entry in <(EditorTool, IconData)>[
      (EditorTool.trim, Icons.content_cut_rounded),
      (EditorTool.effects, Icons.auto_awesome_rounded),
      (EditorTool.overlays, Icons.face_retouching_natural),
      (EditorTool.audio, Icons.music_note_rounded),
      (EditorTool.text, Icons.text_fields_rounded),
      (EditorTool.draw, Icons.brush_rounded),
    ]) {
      await tester.tap(find.byIcon(entry.$2));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selections.last, entry.$1);

      await tester.tap(find.byIcon(entry.$2));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selections.last, isNull);
    }
  });

  testWidgets('trim range slider updates visible timecodes', (tester) async {
    EditorSession session = _session(
      duration: const Duration(seconds: 12),
      trimRange: const EditorTrimRange(
        start: Duration(seconds: 2),
        end: Duration(seconds: 8),
      ),
    );

    await tester.pumpLocalized(
      StatefulBuilder(
        builder: (context, setState) {
          return buildEditorDetailPageTimelineBarForTest(
            palette: palette,
            thumbPath: null,
            session: session,
            isTrimActive: true,
            previewPosition: Duration.zero,
            onTrimChanged: (values) {
              final totalMs = session.videoDuration.inMilliseconds;
              setState(() {
                session = session.copyWith(
                  trimRange: EditorTrimRange(
                    start: Duration(
                      milliseconds: (values.start * totalMs).round(),
                    ),
                    end: Duration(milliseconds: (values.end * totalMs).round()),
                  ),
                );
              });
            },
          );
        },
      ),
    );

    expect(find.text('00:02'), findsOneWidget);
    expect(find.text('00:08'), findsOneWidget);

    final rangeSlider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    rangeSlider.onChanged?.call(const RangeValues(0.25, 0.75));
    await tester.pump();

    expect(find.text('00:03'), findsOneWidget);
    expect(find.text('00:09'), findsOneWidget);
  });

  testWidgets('stickers tool selects and deletes a user sticker', (
    tester,
  ) async {
    const userSticker = EditorStickerAsset(
      id: 'user-sticker',
      assetPath: 'assets/editor/stickers/sticker_01.png',
      label: 'User sticker',
      isUserCreated: true,
    );
    String? selectedStickerId;
    String? selectedStickerPath;
    EditorStickerAsset? deletedSticker;

    await tester.pumpLocalized(
      _overlay(
        activeTool: EditorTool.overlays,
        userStickers: [userSticker],
        onStickerSelected: (id, path) {
          selectedStickerId = id;
          selectedStickerPath = path;
        },
        onDeleteUserSticker: (sticker) async {
          deletedSticker = sticker;
        },
      ),
    );

    final userStickerTile = find.byWidgetPredicate(
      (widget) => widget is GestureDetector && widget.onLongPress != null,
    );
    expect(userStickerTile, findsOneWidget);

    tester.widget<GestureDetector>(userStickerTile).onTap?.call();
    await tester.pump();
    expect(selectedStickerId, userSticker.id);
    expect(selectedStickerPath, userSticker.assetPath);

    tester.widget<GestureDetector>(userStickerTile).onLongPress?.call();
    await tester.pump();
    expect(deletedSticker, userSticker);
  });

  testWidgets('text tool fires add text and font selection callbacks', (
    tester,
  ) async {
    var addTextCount = 0;
    String? changedOverlayId;
    String? changedFontFamily;

    await tester.pumpLocalized(
      _overlay(
        activeTool: EditorTool.text,
        session: _session(
          overlays: const [
            EditorOverlayItem(
              id: 'text-1',
              type: EditorOverlayType.text,
              text: 'Hello',
              fontFamily: 'Fredoka',
            ),
          ],
        ),
        selectedOverlayId: 'text-1',
        onAddTextOverlay: () => addTextCount++,
        onTextChanged:
            ({required overlayId, text, fontFamily, color, textSize}) {
              changedOverlayId = overlayId;
              changedFontFamily = fontFamily;
            },
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(addTextCount, 1);

    await tester.tap(find.text('Aa').at(1));
    await tester.pump();
    expect(changedOverlayId, 'text-1');
    expect(changedFontFamily, 'Baloo');
  });

  testWidgets('audio tool selects track, changes volume, and removes track', (
    tester,
  ) async {
    EditorSession session = _session();
    EditorMusicTrackAsset? selectedTrack;
    double? changedVolume;
    var removeCount = 0;

    await tester.pumpLocalized(
      StatefulBuilder(
        builder: (context, setState) {
          return _overlay(
            activeTool: EditorTool.audio,
            session: session,
            onMusicSelected: (track) async {
              selectedTrack = track;
              setState(() {
                session = session.copyWith(
                  audioSelection: EditorAudioSelection(
                    trackId: track.id,
                    assetPath: track.assetPath,
                  ),
                );
              });
            },
            onMusicVolumeChanged: (volume) {
              changedVolume = volume;
              final selection = session.audioSelection;
              if (selection == null) return;
              setState(() {
                session = session.copyWith(
                  audioSelection: selection.copyWith(volume: volume),
                );
              });
            },
            onMusicRemoved: () {
              removeCount++;
              setState(() {
                session = session.copyWith(clearAudioSelection: true);
              });
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Track 1'));
    await tester.pump();
    expect(selectedTrack?.id, 'track_01');

    expect(find.byType(Slider), findsOneWidget);
    final volumeSlider = tester.widget<Slider>(find.byType(Slider));
    volumeSlider.onChanged?.call(0.42);
    await tester.pump();
    expect(changedVolume, 0.42);

    await tester.tap(find.text(l10n.actionRemove));
    await tester.pump();
    expect(removeCount, 1);
  });

  testWidgets('effects tool changes filter chip and adjustment slider', (
    tester,
  ) async {
    String? selectedFilterId;
    EditorAdjustments? changedAdjustments;
    double? changedSpeed;

    await tester.pumpLocalized(
      _overlay(
        activeTool: EditorTool.effects,
        onFilterChanged: (filterId) => selectedFilterId = filterId,
        onAdjustmentsChanged: (adjustments) {
          changedAdjustments = adjustments;
        },
        onPlaybackSpeedChanged: (speed) => changedSpeed = speed,
      ),
    );

    expect(find.text(l10n.editorSpeedLabel), findsOneWidget);
    await tester.tap(find.text('1.5×'));
    await tester.pump();
    expect(changedSpeed, 1.5);

    await tester.tap(find.text(l10n.editorFilterVivid));
    await tester.pump();
    expect(selectedFilterId, 'vivid');

    final brightnessSlider = tester.widget<Slider>(find.byType(Slider).first);
    brightnessSlider.onChanged?.call(0.5);
    await tester.pump();
    expect(changedAdjustments?.brightness, 0.5);
  });

  testWidgets('drawing tool selector switches active draw tool', (
    tester,
  ) async {
    EditorDrawTool activeTool = EditorDrawTool.pencil;

    await tester.pumpLocalized(
      StatefulBuilder(
        builder: (context, setState) {
          return _overlay(
            activeTool: EditorTool.draw,
            activeDrawTool: activeTool,
            onDrawToolChanged: (tool) {
              setState(() => activeTool = tool);
            },
          );
        },
      ),
    );

    expect(find.text(l10n.editorDrawToolPencil), findsOneWidget);
    await tester.tap(find.text(l10n.editorDrawToolMarker));
    await tester.pump();
    expect(activeTool, EditorDrawTool.marker);

    await tester.tap(find.text(l10n.editorDrawToolEraser));
    await tester.pump();
    expect(activeTool, EditorDrawTool.eraser);
  });

  testWidgets('drawing tool updates color and width', (tester) async {
    var colorValue = 0xffffffff;
    var width = 6.0;

    await tester.pumpLocalized(
      StatefulBuilder(
        builder: (context, setState) {
          return _overlay(
            activeTool: EditorTool.draw,
            drawColorValue: colorValue,
            drawWidth: width,
            onDrawColorChanged: (value) {
              setState(() => colorValue = value);
            },
            onDrawWidthChanged: (value) {
              setState(() => width = value);
            },
          );
        },
      ),
    );

    final colorChip = find.byWidgetPredicate((widget) {
      if (widget is! Container) return false;
      final decoration = widget.decoration;
      return decoration is BoxDecoration &&
          decoration.color == const Color(0xFFFFD54F);
    });
    await tester.tap(colorChip.first);
    await tester.pump();
    expect(colorValue, const Color(0xFFFFD54F).toARGB32());

    final widthSlider = tester.widget<Slider>(find.byType(Slider));
    widthSlider.onChanged?.call(18);
    await tester.pump();
    expect(width, 18);
  });

  testWidgets(
    'drawing tool undo removes last stroke and clear empties strokes',
    (tester) async {
      var session = _session(
        strokes: const [
          EditorStroke(
            id: 'stroke-1',
            tool: EditorDrawTool.pencil,
            colorValue: 0xffffffff,
            width: 6,
            points: [Offset(0.1, 0.1)],
          ),
          EditorStroke(
            id: 'stroke-2',
            tool: EditorDrawTool.marker,
            colorValue: 0xffff0000,
            width: 12,
            points: [Offset(0.2, 0.2)],
          ),
        ],
      );

      await tester.pumpLocalized(
        StatefulBuilder(
          builder: (context, setState) {
            return _overlay(
              activeTool: EditorTool.draw,
              session: session,
              onDrawUndo: () {
                setState(() {
                  session = session.copyWith(
                    strokes: session.strokes
                        .take(session.strokes.length - 1)
                        .toList(),
                  );
                });
              },
              onDrawClear: () {
                setState(() {
                  session = session.copyWith(strokes: const <EditorStroke>[]);
                });
              },
            );
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.undo_rounded));
      await tester.pump();
      expect(session.strokes.map((stroke) => stroke.id), ['stroke-1']);

      await tester.tap(find.byIcon(Icons.delete_sweep_rounded));
      await tester.pump();
      expect(session.strokes, isEmpty);
    },
  );
}

extension on WidgetTester {
  Future<void> pumpLocalized(Widget child) {
    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: SizedBox(width: 720, height: 520, child: child)),
        ),
      ),
    );
  }
}

Widget _overlay({
  required EditorTool activeTool,
  EditorSession? session,
  ValueChanged<String>? onFilterChanged,
  ValueChanged<EditorAdjustments>? onAdjustmentsChanged,
  ValueChanged<double>? onPlaybackSpeedChanged,
  void Function(String stickerId, String assetPath)? onStickerSelected,
  Future<void> Function()? onOpenSelfieStickerCapture,
  List<EditorStickerAsset> userStickers = const [],
  Future<void> Function(EditorStickerAsset sticker)? onDeleteUserSticker,
  Future<void> Function(EditorMusicTrackAsset track)? onMusicSelected,
  VoidCallback? onMusicRemoved,
  ValueChanged<double>? onMusicVolumeChanged,
  Future<void> Function(EditorMusicTrackAsset track)? onMusicPreviewToggled,
  String? previewingTrackId,
  Set<String> cachedAudioTrackIds = const {},
  Set<String> downloadingAudioTrackIds = const {},
  String? selectedOverlayId,
  VoidCallback? onAddTextOverlay,
  void Function({
    required String overlayId,
    String? text,
    String? fontFamily,
    Color? color,
    double? textSize,
  })?
  onTextChanged,
  EditorDrawTool activeDrawTool = EditorDrawTool.pencil,
  int drawColorValue = 0xffffffff,
  double drawWidth = 6,
  ValueChanged<EditorDrawTool>? onDrawToolChanged,
  ValueChanged<int>? onDrawColorChanged,
  ValueChanged<double>? onDrawWidthChanged,
  VoidCallback? onDrawUndo,
  VoidCallback? onDrawClear,
}) {
  return buildEditorDetailPageActiveToolOverlayForTest(
    palette: ThemeDescriptor.campfire.lightPalette,
    activeTool: activeTool,
    session: session ?? _session(),
    onFilterChanged: onFilterChanged ?? (_) {},
    onAdjustmentsChanged: onAdjustmentsChanged ?? (_) {},
    onPlaybackSpeedChanged: onPlaybackSpeedChanged ?? (_) {},
    onStickerSelected: onStickerSelected ?? (_, _) {},
    onOpenSelfieStickerCapture: onOpenSelfieStickerCapture ?? () async {},
    userStickers: userStickers,
    onDeleteUserSticker: onDeleteUserSticker ?? (_) async {},
    onMusicSelected: onMusicSelected ?? (_) async {},
    onMusicRemoved: onMusicRemoved ?? () {},
    onMusicVolumeChanged: onMusicVolumeChanged ?? (_) {},
    onMusicPreviewToggled: onMusicPreviewToggled ?? (_) async {},
    previewingTrackId: previewingTrackId,
    cachedAudioTrackIds: cachedAudioTrackIds,
    downloadingAudioTrackIds: downloadingAudioTrackIds,
    selectedOverlayId: selectedOverlayId,
    onAddTextOverlay: onAddTextOverlay ?? () {},
    onTextChanged:
        onTextChanged ??
        ({required overlayId, text, fontFamily, color, textSize}) {},
    activeDrawTool: activeDrawTool,
    drawColorValue: drawColorValue,
    drawWidth: drawWidth,
    onDrawToolChanged: onDrawToolChanged ?? (_) {},
    onDrawColorChanged: onDrawColorChanged ?? (_) {},
    onDrawWidthChanged: onDrawWidthChanged ?? (_) {},
    onDrawUndo: onDrawUndo ?? () {},
    onDrawClear: onDrawClear ?? () {},
  );
}

EditorSession _session({
  Duration duration = const Duration(seconds: 12),
  EditorTrimRange? trimRange,
  List<EditorOverlayItem> overlays = const [],
  List<EditorStroke> strokes = const [],
  EditorAudioSelection? audioSelection,
}) {
  return EditorSession(
    videoId: 'video-1',
    sourcePath: '/tmp/video.mp4',
    videoDuration: duration,
    trimRange:
        trimRange ?? EditorTrimRange(start: Duration.zero, end: duration),
    overlays: overlays,
    strokes: strokes,
    audioSelection: audioSelection,
  );
}

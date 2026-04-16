import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/editor/editor_resource_catalog.dart';

void main() {
  test('resource catalog exposes the bundled editor assets', () {
    expect(EditorResourceCatalog.lutAssets, hasLength(5));
    expect(EditorResourceCatalog.builtInStickerAssets, hasLength(181));
    expect(EditorResourceCatalog.builtInMusicTracks.length, greaterThan(5));
    expect(
      EditorResourceCatalog.builtInMusicTracks.where(
        (track) => track.isBlossomBacked,
      ),
      isNotEmpty,
    );
  });

  test('filter presets match the tablet editor chips', () {
    final labels = EditorResourceCatalog.filterPresets
        .map((preset) => preset.label)
        .toList();

    expect(
      labels,
      equals(<String>[
        'None',
        'Vivid',
        'Matte',
        'Fade',
        'Warm',
        'Cool',
        'Noir',
      ]),
    );
  });
}

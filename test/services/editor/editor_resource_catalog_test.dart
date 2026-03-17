import 'package:flutter_test/flutter_test.dart';
import 'package:mytube/services/editor/editor_resource_catalog.dart';

void main() {
  test('resource catalog exposes the old app editor assets', () {
    expect(EditorResourceCatalog.lutAssets, hasLength(5));
    expect(EditorResourceCatalog.builtInStickerAssets, hasLength(13));
    expect(EditorResourceCatalog.builtInMusicTracks, hasLength(5));
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

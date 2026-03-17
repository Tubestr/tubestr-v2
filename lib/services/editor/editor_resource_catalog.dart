import '../../domain/models/editor_resources.dart';

class EditorResourceCatalog {
  static const lutAssets = <EditorLutAsset>[
    EditorLutAsset(
      id: 'dusty_light',
      assetPath: 'assets/editor/luts/dusty_light.cube',
      label: 'Matte',
    ),
    EditorLutAsset(
      id: 'fade',
      assetPath: 'assets/editor/luts/fade.cube',
      label: 'Fade',
    ),
    EditorLutAsset(
      id: 'tinted_shades',
      assetPath: 'assets/editor/luts/tinted_shades.cube',
      label: 'Cool',
    ),
    EditorLutAsset(
      id: 'vintage',
      assetPath: 'assets/editor/luts/vintage.cube',
      label: 'Warm',
    ),
    EditorLutAsset(
      id: 'white_black',
      assetPath: 'assets/editor/luts/white_black.cube',
      label: 'Noir',
    ),
  ];

  static const filterPresets = <EditorFilterPreset>[
    EditorFilterPreset(
      id: 'none',
      label: 'None',
      engine: EditorFilterEngine.none,
    ),
    EditorFilterPreset(
      id: 'vivid',
      label: 'Vivid',
      engine: EditorFilterEngine.eq,
      contrast: 1.08,
      saturation: 1.2,
      brightness: 0.03,
    ),
    EditorFilterPreset(
      id: 'matte',
      label: 'Matte',
      engine: EditorFilterEngine.lut3d,
      lutAssetId: 'dusty_light',
    ),
    EditorFilterPreset(
      id: 'fade',
      label: 'Fade',
      engine: EditorFilterEngine.lut3d,
      lutAssetId: 'fade',
    ),
    EditorFilterPreset(
      id: 'warm',
      label: 'Warm',
      engine: EditorFilterEngine.lut3d,
      lutAssetId: 'vintage',
    ),
    EditorFilterPreset(
      id: 'cool',
      label: 'Cool',
      engine: EditorFilterEngine.lut3d,
      lutAssetId: 'tinted_shades',
    ),
    EditorFilterPreset(
      id: 'noir',
      label: 'Noir',
      engine: EditorFilterEngine.lut3d,
      lutAssetId: 'white_black',
    ),
  ];

  static const builtInStickerAssets = <EditorStickerAsset>[
    EditorStickerAsset(
      id: 'sticker_01',
      assetPath: 'assets/editor/stickers/sticker_01.png',
      label: 'Sticker 1',
    ),
    EditorStickerAsset(
      id: 'sticker_02',
      assetPath: 'assets/editor/stickers/sticker_02.png',
      label: 'Sticker 2',
    ),
    EditorStickerAsset(
      id: 'sticker_03',
      assetPath: 'assets/editor/stickers/sticker_03.png',
      label: 'Sticker 3',
    ),
    EditorStickerAsset(
      id: 'sticker_04',
      assetPath: 'assets/editor/stickers/sticker_04.png',
      label: 'Sticker 4',
    ),
    EditorStickerAsset(
      id: 'sticker_05',
      assetPath: 'assets/editor/stickers/sticker_05.png',
      label: 'Sticker 5',
    ),
    EditorStickerAsset(
      id: 'sticker_06',
      assetPath: 'assets/editor/stickers/sticker_06.png',
      label: 'Sticker 6',
    ),
    EditorStickerAsset(
      id: 'sticker_07',
      assetPath: 'assets/editor/stickers/sticker_07.png',
      label: 'Sticker 7',
    ),
    EditorStickerAsset(
      id: 'sticker_08',
      assetPath: 'assets/editor/stickers/sticker_08.png',
      label: 'Sticker 8',
    ),
    EditorStickerAsset(
      id: 'sticker_09',
      assetPath: 'assets/editor/stickers/sticker_09.png',
      label: 'Sticker 9',
    ),
    EditorStickerAsset(
      id: 'sticker_10',
      assetPath: 'assets/editor/stickers/sticker_10.png',
      label: 'Sticker 10',
    ),
    EditorStickerAsset(
      id: 'sticker_11',
      assetPath: 'assets/editor/stickers/sticker_11.png',
      label: 'Sticker 11',
    ),
    EditorStickerAsset(
      id: 'sticker_12',
      assetPath: 'assets/editor/stickers/sticker_12.png',
      label: 'Sticker 12',
    ),
    EditorStickerAsset(
      id: 'sticker_13',
      assetPath: 'assets/editor/stickers/sticker_13.png',
      label: 'Sticker 13',
    ),
  ];

  static const builtInMusicTracks = <EditorMusicTrackAsset>[
    EditorMusicTrackAsset(
      id: 'track_01',
      assetPath: 'assets/editor/music/track_01.mp3',
      label: 'Track 1',
    ),
    EditorMusicTrackAsset(
      id: 'track_02',
      assetPath: 'assets/editor/music/track_02.mp3',
      label: 'Track 2',
    ),
    EditorMusicTrackAsset(
      id: 'track_03',
      assetPath: 'assets/editor/music/track_03.mp3',
      label: 'Track 3',
    ),
    EditorMusicTrackAsset(
      id: 'track_04',
      assetPath: 'assets/editor/music/track_04.mp3',
      label: 'Track 4',
    ),
    EditorMusicTrackAsset(
      id: 'track_05',
      assetPath: 'assets/editor/music/track_05.mp3',
      label: 'Track 5',
    ),
  ];

  static EditorLutAsset? lutById(String id) {
    for (final lut in lutAssets) {
      if (lut.id == id) {
        return lut;
      }
    }
    return null;
  }

  static EditorFilterPreset? filterPresetById(String id) {
    for (final preset in filterPresets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }
}

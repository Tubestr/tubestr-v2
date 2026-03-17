import 'package:flutter/material.dart';

import '../../../domain/models/editor_session.dart';
import '../../../services/editor/editor_resource_catalog.dart';

@immutable
class EditorPreviewStyle {
  const EditorPreviewStyle({
    required this.colorMatrix,
    this.tintColor,
    this.tintOpacity = 0,
    this.vignetteStrength = 0,
  });

  final List<double> colorMatrix;
  final Color? tintColor;
  final double tintOpacity;
  final double vignetteStrength;
}

EditorPreviewStyle buildEditorPreviewStyle(EditorSession session) {
  final preset = EditorResourceCatalog.filterPresetById(session.filterPresetId);
  final tuning = _presetTuningForId(preset?.id ?? 'none');
  final brightness =
      (preset?.brightness ?? 0) +
      tuning.brightnessOffset +
      session.adjustments.brightness;
  final contrast =
      (preset?.contrast ?? 1) *
      tuning.contrastMultiplier *
      session.adjustments.contrast;
  final saturation =
      (preset?.saturation ?? 1) *
      tuning.saturationMultiplier *
      session.adjustments.saturation;

  return EditorPreviewStyle(
    colorMatrix: _composeColorMatrix(
      brightness: brightness.clamp(-1.0, 1.0),
      contrast: contrast.clamp(0.2, 2.4),
      saturation: saturation.clamp(0.0, 2.6),
    ),
    tintColor: tuning.tintColor,
    tintOpacity: tuning.tintOpacity.clamp(0.0, 0.3),
    vignetteStrength: (tuning.vignetteBoost + session.adjustments.vignette)
        .clamp(0.0, 1.0),
  );
}

class _PresetTuning {
  const _PresetTuning({
    this.brightnessOffset = 0,
    this.contrastMultiplier = 1,
    this.saturationMultiplier = 1,
    this.tintColor,
    this.tintOpacity = 0,
    this.vignetteBoost = 0,
  });

  final double brightnessOffset;
  final double contrastMultiplier;
  final double saturationMultiplier;
  final Color? tintColor;
  final double tintOpacity;
  final double vignetteBoost;
}

_PresetTuning _presetTuningForId(String presetId) {
  return switch (presetId) {
    'matte' => const _PresetTuning(
      brightnessOffset: 0.04,
      contrastMultiplier: 0.92,
      saturationMultiplier: 0.92,
      tintColor: Color(0xFFF5D6B4),
      tintOpacity: 0.08,
      vignetteBoost: 0.08,
    ),
    'fade' => const _PresetTuning(
      brightnessOffset: 0.05,
      contrastMultiplier: 0.86,
      saturationMultiplier: 0.88,
      tintColor: Color(0xFFF7EFE3),
      tintOpacity: 0.10,
    ),
    'warm' => const _PresetTuning(
      brightnessOffset: 0.02,
      contrastMultiplier: 1.04,
      saturationMultiplier: 1.06,
      tintColor: Color(0xFFFF9F43),
      tintOpacity: 0.10,
      vignetteBoost: 0.04,
    ),
    'cool' => const _PresetTuning(
      contrastMultiplier: 1.02,
      saturationMultiplier: 0.98,
      tintColor: Color(0xFF6EC5FF),
      tintOpacity: 0.08,
      vignetteBoost: 0.03,
    ),
    'noir' => const _PresetTuning(
      contrastMultiplier: 1.08,
      saturationMultiplier: 0,
      vignetteBoost: 0.18,
    ),
    _ => const _PresetTuning(),
  };
}

List<double> _composeColorMatrix({
  required double brightness,
  required double contrast,
  required double saturation,
}) {
  final saturationMatrix = _saturationMatrix(saturation);
  final brightnessContrastMatrix = _brightnessContrastMatrix(
    brightness: brightness,
    contrast: contrast,
  );
  return _multiplyColorMatrices(brightnessContrastMatrix, saturationMatrix);
}

List<double> _brightnessContrastMatrix({
  required double brightness,
  required double contrast,
}) {
  final offset = ((1 - contrast) * 128) + (brightness * 255);
  return <double>[
    contrast,
    0,
    0,
    0,
    offset,
    0,
    contrast,
    0,
    0,
    offset,
    0,
    0,
    contrast,
    0,
    offset,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _saturationMatrix(double saturation) {
  const rw = 0.2126;
  const gw = 0.7152;
  const bw = 0.0722;
  final inv = 1 - saturation;
  final r = inv * rw;
  final g = inv * gw;
  final b = inv * bw;
  return <double>[
    r + saturation,
    g,
    b,
    0,
    0,
    r,
    g + saturation,
    b,
    0,
    0,
    r,
    g,
    b + saturation,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];
}

List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
  final result = List<double>.filled(20, 0);
  for (var row = 0; row < 4; row += 1) {
    for (var col = 0; col < 5; col += 1) {
      final index = (row * 5) + col;
      result[index] =
          a[(row * 5)] * b[col] +
          a[(row * 5) + 1] * b[col + 5] +
          a[(row * 5) + 2] * b[col + 10] +
          a[(row * 5) + 3] * b[col + 15] +
          (col == 4 ? a[(row * 5) + 4] : 0);
    }
  }
  return result;
}

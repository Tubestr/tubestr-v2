import 'package:flutter/material.dart';

import '../../../../../core/theme/radii.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/theme_descriptor.dart';
import '../../../../../domain/models/editor_session.dart';
import '../../../../../services/editor/editor_resource_catalog.dart';
import '../../../../../l10n/l10n.dart';

class CompactEffectsTool extends StatelessWidget {
  const CompactEffectsTool({
    super.key,
    required this.palette,
    required this.session,
    required this.onFilterChanged,
    required this.onAdjustmentsChanged,
    required this.onPlaybackSpeedChanged,
  });

  final KidPalette palette;
  final EditorSession session;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<EditorAdjustments> onAdjustmentsChanged;
  final ValueChanged<double> onPlaybackSpeedChanged;

  static const _playbackSpeeds = <double>[0.5, 1.0, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final preset = EditorResourceCatalog.filterPresets[index];
                  final selected = session.filterPresetId == preset.id;
                  return GestureDetector(
                    onTap: () => onFilterChanged(preset.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(
                                colors: [
                                  palette.accent,
                                  palette.accentSecondary,
                                ],
                              )
                            : null,
                        color: selected ? null : palette.mediaSurfaceSubtle,
                        borderRadius: AppRadii.xlAll,
                      ),
                      child: Text(
                        _localizedFilterPresetLabel(preset.id, context),
                        style: TextStyle(
                          color: palette.mediaInk,
                          fontSize: AppTextSize.label,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemCount: EditorResourceCatalog.filterPresets.length,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: Text(
                    context.l10n.editorSpeedLabel,
                    style: TextStyle(
                      color: palette.mediaMutedInk,
                      fontSize: AppTextSize.label,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final speed = _playbackSpeeds[index];
                        final selected =
                            (session.playbackSpeed - speed).abs() < 0.01;
                        return GestureDetector(
                          onTap: () => onPlaybackSpeedChanged(speed),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? LinearGradient(
                                      colors: [
                                        palette.accent,
                                        palette.accentSecondary,
                                      ],
                                    )
                                  : null,
                              color: selected
                                  ? null
                                  : palette.mediaSurfaceSubtle,
                              borderRadius: AppRadii.xlAll,
                            ),
                            child: Text(
                              _formatPlaybackSpeed(speed),
                              style: TextStyle(
                                color: palette.mediaInk,
                                fontSize: AppTextSize.label,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemCount: _playbackSpeeds.length,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            CompactSlider(
              palette: palette,
              label: context.l10n.editorBrightness,
              value: session.adjustments.brightness,
              min: -1,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(brightness: v),
              ),
            ),
            CompactSlider(
              palette: palette,
              label: context.l10n.editorContrast,
              value: session.adjustments.contrast,
              min: 0.5,
              max: 1.8,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(contrast: v),
              ),
            ),
            CompactSlider(
              palette: palette,
              label: context.l10n.editorSaturation,
              value: session.adjustments.saturation,
              min: 0,
              max: 2,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(saturation: v),
              ),
            ),
            CompactSlider(
              palette: palette,
              label: context.l10n.editorSharpness,
              value: session.adjustments.sharpness,
              min: 0,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(sharpness: v),
              ),
            ),
            CompactSlider(
              palette: palette,
              label: context.l10n.editorVignette,
              value: session.adjustments.vignette,
              min: 0,
              max: 1,
              onChanged: (v) => onAdjustmentsChanged(
                session.adjustments.copyWith(vignette: v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPlaybackSpeed(double speed) {
  final label = speed == speed.roundToDouble()
      ? speed.toStringAsFixed(0)
      : speed.toString();
  return '$label×';
}

class CompactSlider extends StatelessWidget {
  const CompactSlider({
    super.key,
    required this.palette,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final KidPalette palette;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                color: palette.mediaMutedInk,
                fontSize: AppTextSize.label,
              ),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: palette.mediaMutedInk,
                inactiveTrackColor: palette.mediaSurfaceSubtle,
                thumbColor: palette.mediaInk,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: palette.mediaSubtleInk,
                fontSize: AppTextSize.caption,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact Overlay (Stickers) Tool ─────────────────────────────────────

String _localizedFilterPresetLabel(String presetId, BuildContext context) =>
    switch (presetId) {
      'none' => context.l10n.editorFilterNone,
      'vivid' => context.l10n.editorFilterVivid,
      'matte' => context.l10n.editorFilterMatte,
      'fade' => context.l10n.editorFilterFade,
      'warm' => context.l10n.editorFilterWarm,
      'cool' => context.l10n.editorFilterCool,
      'noir' => context.l10n.editorFilterNoir,
      _ => presetId,
    };

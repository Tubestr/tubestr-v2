import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/editor_session.dart';
import '../../../../shared_ui/components/media_thumbnail_frame.dart';
import '../../domain/editor_trim_utils.dart';
import '../../../../l10n/l10n.dart';

class TimelineBar extends StatelessWidget {
  const TimelineBar({
    super.key,
    required this.palette,
    required this.thumbPath,
    required this.session,
    required this.isTrimActive,
    required this.previewPosition,
    required this.onTrimChanged,
  });

  final KidPalette palette;
  final String? thumbPath;
  final EditorSession session;
  final bool isTrimActive;
  final Duration previewPosition;
  final ValueChanged<RangeValues> onTrimChanged;

  @override
  Widget build(BuildContext context) {
    final normalizedTrim = normalizeEditorTrim(
      rawVideoDuration: session.videoDuration,
      rawTrimRange: session.trimRange,
    );
    final progressFraction = session.videoDuration.inMilliseconds > 0
        ? (previewPosition.inMilliseconds /
                  session.videoDuration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      height: isTrimActive ? 96 : 54,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.lg),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: palette.mediaSurface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
              border: Border(top: BorderSide(color: palette.mediaBorder)),
            ),
            child: Column(
              children: [
                if (isTrimActive) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formatDuration(normalizedTrim.trimRange.start),
                          style: TextStyle(
                            color: palette.mediaMutedInk,
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.accent.withValues(alpha: 0.3),
                            borderRadius: AppRadii.mdAll,
                          ),
                          child: Text(
                            context.l10n.editorTrimKeepDuration(
                              _formatDuration(
                                normalizedTrim.trimRange.duration,
                              ),
                            ),
                            style: TextStyle(
                              color: palette.accentSecondary,
                              fontSize: AppTextSize.caption,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDuration(normalizedTrim.trimRange.end),
                          style: TextStyle(
                            color: palette.mediaMutedInk,
                            fontSize: AppTextSize.caption,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        activeTrackColor: palette.accent,
                        inactiveTrackColor: palette.mediaSurfaceSubtle,
                        thumbColor: palette.mediaInk,
                        overlayColor: palette.accent.withValues(alpha: 0.2),
                      ),
                      child: RangeSlider(
                        values: normalizedTrim.sliderValues,
                        min: 0,
                        max: 1,
                        onChanged: onTrimChanged,
                      ),
                    ),
                  ),
                ],
                if (!isTrimActive)
                  Expanded(
                    child: TimelineStripContent(
                      thumbPath: thumbPath,
                      palette: palette,
                      progressFraction: progressFraction,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class TimelineStripContent extends StatelessWidget {
  const TimelineStripContent({
    super.key,
    required this.thumbPath,
    required this.palette,
    required this.progressFraction,
  });

  final String? thumbPath;
  final KidPalette palette;
  final double progressFraction;

  @override
  Widget build(BuildContext context) {
    final thumbFile = thumbPath == null || thumbPath!.isEmpty
        ? null
        : File(thumbPath!);
    final hasThumb = thumbFile?.existsSync() == true;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: List.generate(8, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 7 ? 0 : AppSpacing.xs,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadii.xsAll,
                        child: SizedBox(
                          height: 36,
                          child: hasThumb
                              ? MediaThumbnailFrame(
                                  file: thumbFile!,
                                  borderRadius: AppRadii.xsAll,
                                  background: LinearGradient(
                                    colors: [
                                      palette.mediaSurfaceStrong,
                                      palette.mediaSurface,
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.xs),
                                )
                              : DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        palette.accent.withValues(alpha: 0.25),
                                        palette.accentSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: const SizedBox.expand(),
                                ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              left: 8 + (progressFraction * (constraints.maxWidth - 16)),
              top: 4,
              bottom: 4,
              child: Container(
                width: 2.5,
                decoration: BoxDecoration(
                  color: palette.mediaInk,
                  borderRadius: AppRadii.pillAll,
                  boxShadow: [
                    BoxShadow(color: palette.mediaScrim, blurRadius: 4),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Active Tool Overlay ─────────────────────────────────────────────────

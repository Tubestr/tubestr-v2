import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/editor_session.dart';
import '../../domain/editor_preview_style.dart';

class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.palette,
    required this.videoController,
    required this.session,
    required this.videoAspectRatio,
    required this.selectedOverlayId,
    required this.isPlaying,
    required this.onTogglePlayback,
    required this.onOverlaySelected,
    required this.onOverlayScaleStart,
    required this.onOverlayScaleUpdate,
    required this.onOverlayDeleted,
    this.drawingCanvas,
  });

  final KidPalette palette;
  final VideoController videoController;
  final EditorSession session;
  final double videoAspectRatio;
  final String? selectedOverlayId;
  final bool isPlaying;
  final Future<void> Function() onTogglePlayback;
  final ValueChanged<String?> onOverlaySelected;
  final void Function(
    ScaleStartDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  )
  onOverlayScaleStart;
  final void Function(
    ScaleUpdateDetails details,
    Size previewSize,
    EditorOverlayItem overlay,
  )
  onOverlayScaleUpdate;
  final ValueChanged<String> onOverlayDeleted;
  final Widget? drawingCanvas;

  @override
  Widget build(BuildContext context) {
    final previewFile = File(session.sourcePath);
    final hasPreviewFile = previewFile.existsSync();
    final textOverlays = session.overlays
        .where((overlay) => overlay.type == EditorOverlayType.text)
        .toList(growable: false);
    final stickerOverlays = session.overlays
        .where((overlay) => overlay.type == EditorOverlayType.sticker)
        .toList(growable: false);
    final previewStyle = buildEditorPreviewStyle(session);

    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, viewport) {
          final previewSize = _fitSizeWithin(
            viewport.biggest,
            videoAspectRatio,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      palette.accent.withValues(alpha: 0.15),
                      Colors.black,
                    ],
                    radius: 1.2,
                  ),
                ),
              ),
              Center(
                child: SizedBox(
                  width: previewSize.width,
                  height: previewSize.height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasPreviewFile)
                        ColorFiltered(
                          colorFilter: ColorFilter.matrix(
                            previewStyle.colorMatrix,
                          ),
                          child: Video(controller: videoController),
                        )
                      else
                        const ColoredBox(color: Colors.black12),
                      if (previewStyle.tintColor case final tint?)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: tint.withValues(
                                alpha: previewStyle.tintOpacity,
                              ),
                            ),
                          ),
                        ),
                      if (previewStyle.vignetteStrength > 0)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(
                                    alpha: 0.28 * previewStyle.vignetteStrength,
                                  ),
                                ],
                                stops: const [0.1, 0.64, 1],
                                radius:
                                    0.96 +
                                    (previewStyle.vignetteStrength * 0.2),
                              ),
                            ),
                          ),
                        ),
                      Stack(
                        children: [
                          for (final overlay in stickerOverlays)
                            StickerOverlay(
                              overlay: overlay,
                              previewSize: previewSize,
                              selected: overlay.id == selectedOverlayId,
                              onTap: () => onOverlaySelected(overlay.id),
                              onScaleStart: (details) {
                                onOverlaySelected(overlay.id);
                                onOverlayScaleStart(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onScaleUpdate: (details) {
                                onOverlayScaleUpdate(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onDelete: () => onOverlayDeleted(overlay.id),
                            ),
                          for (final overlay in textOverlays)
                            TextOverlay(
                              overlay: overlay,
                              previewSize: previewSize,
                              selected: overlay.id == selectedOverlayId,
                              onTap: () => onOverlaySelected(overlay.id),
                              onScaleStart: (details) {
                                onOverlaySelected(overlay.id);
                                onOverlayScaleStart(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onScaleUpdate: (details) {
                                onOverlayScaleUpdate(
                                  details,
                                  previewSize,
                                  overlay,
                                );
                              },
                              onDelete: () => onOverlayDeleted(overlay.id),
                            ),
                        ],
                      ),
                      if (drawingCanvas case final drawingCanvas?)
                        Positioned.fill(child: drawingCanvas),
                    ],
                  ),
                ),
              ),
              Center(
                child: GestureDetector(
                  onTap: () => unawaited(onTogglePlayback()),
                  child: AnimatedOpacity(
                    opacity: isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: AppIconSize.empty,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Size _fitSizeWithin(Size viewport, double aspectRatio) {
  if (viewport.width <= 0 || viewport.height <= 0 || aspectRatio <= 0) {
    return viewport;
  }
  final viewportAspect = viewport.width / viewport.height;
  if (viewportAspect > aspectRatio) {
    final height = viewport.height;
    return ui.Size(height * aspectRatio, height);
  }
  final width = viewport.width;
  return ui.Size(width, width / aspectRatio);
}

// ── Sticker Overlay ─────────────────────────────────────────────────────

class StickerOverlay extends StatelessWidget {
  const StickerOverlay({
    super.key,
    required this.overlay,
    required this.previewSize,
    required this.selected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onDelete,
  });

  final EditorOverlayItem overlay;
  final Size previewSize;
  final bool selected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final VoidCallback onDelete;

  static const _touchPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final transform = overlay.transform;
    final stickerSize = 92 * transform.scale;
    final stickerPath = overlay.stickerAssetPath!;
    final isBundledAsset = stickerPath.startsWith('assets/');
    return Positioned(
      left:
          (transform.position.dx * previewSize.width) -
          (stickerSize / 2) -
          _touchPadding,
      top:
          (transform.position.dy * previewSize.height) -
          (stickerSize / 2) -
          _touchPadding,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onScaleStart: onScaleStart,
        onScaleUpdate: onScaleUpdate,
        child: Padding(
          padding: const EdgeInsets.all(_touchPadding),
          child: Transform.rotate(
            angle: transform.rotationDegrees * math.pi / 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: stickerSize,
                  height: stickerSize,
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.xlAll,
                    border: selected
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadii.xlAll,
                    child: isBundledAsset
                        ? Image.asset(stickerPath, fit: BoxFit.contain)
                        : Image.file(File(stickerPath), fit: BoxFit.contain),
                  ),
                ),
                if (selected)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: OverlayDeleteBadge(onTap: onDelete),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Text Overlay ────────────────────────────────────────────────────────

class TextOverlay extends StatelessWidget {
  const TextOverlay({
    super.key,
    required this.overlay,
    required this.previewSize,
    required this.selected,
    required this.onTap,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onDelete,
  });

  final EditorOverlayItem overlay;
  final Size previewSize;
  final bool selected;
  final VoidCallback onTap;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final VoidCallback onDelete;

  static const _touchPadding = 24.0;

  @override
  Widget build(BuildContext context) {
    final text = overlay.text;
    if (text == null || text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final transform = overlay.transform;
    return Positioned(
      left: transform.position.dx * previewSize.width,
      top: transform.position.dy * previewSize.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          child: Padding(
            padding: const EdgeInsets.all(_touchPadding),
            child: Transform.rotate(
              angle: transform.rotationDegrees * math.pi / 180,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: selected
                        ? BoxDecoration(
                            borderRadius: AppRadii.lgAll,
                            border: Border.all(color: Colors.white, width: 2),
                          )
                        : null,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: overlay.fontFamily,
                        fontSize: overlay.textSize * transform.scale,
                        fontWeight: FontWeight.w800,
                        color: overlay.textColorValue == null
                            ? Colors.white
                            : Color(overlay.textColorValue!),
                        shadows: const [
                          Shadow(
                            blurRadius: 12,
                            color: Colors.black54,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      top: -10,
                      right: -10,
                      child: OverlayDeleteBadge(onTap: onDelete),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Overlay Delete Badge ────────────────────────────────────────────────

class OverlayDeleteBadge extends StatelessWidget {
  const OverlayDeleteBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.75),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: const Icon(
          Icons.close_rounded,
          size: AppIconSize.sm,
          color: Colors.white,
        ),
      ),
    );
  }
}

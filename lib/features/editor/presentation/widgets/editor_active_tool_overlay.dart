import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/editor_resources.dart';
import '../../../../domain/models/editor_session.dart';
import 'tools/editor_audio_tool.dart';
import 'tools/editor_drawing_tool.dart';
import 'tools/editor_effects_tool.dart';
import 'tools/editor_overlay_tool.dart';
import 'tools/editor_text_tool.dart';

class ActiveToolOverlay extends StatelessWidget {
  const ActiveToolOverlay({
    super.key,
    required this.palette,
    required this.activeTool,
    required this.session,
    required this.onFilterChanged,
    required this.onAdjustmentsChanged,
    required this.onPlaybackSpeedChanged,
    required this.onStickerSelected,
    required this.onOpenSelfieStickerCapture,
    required this.userStickers,
    required this.onDeleteUserSticker,
    required this.onMusicSelected,
    required this.onMusicRemoved,
    required this.onMusicVolumeChanged,
    required this.onMusicPreviewToggled,
    required this.previewingTrackId,
    required this.cachedAudioTrackIds,
    required this.downloadingAudioTrackIds,
    required this.selectedOverlayId,
    required this.onAddTextOverlay,
    required this.onTextChanged,
    required this.activeDrawTool,
    required this.drawColorValue,
    required this.drawWidth,
    required this.onDrawToolChanged,
    required this.onDrawColorChanged,
    required this.onDrawWidthChanged,
    required this.onDrawUndo,
    required this.onDrawClear,
    this.isTablet = false,
  });

  final KidPalette palette;
  final EditorTool activeTool;
  final EditorSession session;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<EditorAdjustments> onAdjustmentsChanged;
  final ValueChanged<double> onPlaybackSpeedChanged;
  final void Function(String stickerId, String assetPath) onStickerSelected;
  final Future<void> Function() onOpenSelfieStickerCapture;
  final List<EditorStickerAsset> userStickers;
  final Future<void> Function(EditorStickerAsset sticker) onDeleteUserSticker;
  final Future<void> Function(EditorMusicTrackAsset track) onMusicSelected;
  final VoidCallback onMusicRemoved;
  final ValueChanged<double> onMusicVolumeChanged;
  final Future<void> Function(EditorMusicTrackAsset track)
  onMusicPreviewToggled;
  final String? previewingTrackId;
  final Set<String> cachedAudioTrackIds;
  final Set<String> downloadingAudioTrackIds;
  final String? selectedOverlayId;
  final VoidCallback onAddTextOverlay;
  final void Function({
    required String overlayId,
    String? text,
    String? fontFamily,
    Color? color,
    double? textSize,
  })
  onTextChanged;
  final EditorDrawTool activeDrawTool;
  final int drawColorValue;
  final double drawWidth;
  final ValueChanged<EditorDrawTool> onDrawToolChanged;
  final ValueChanged<int> onDrawColorChanged;
  final ValueChanged<double> onDrawWidthChanged;
  final VoidCallback onDrawUndo;
  final VoidCallback onDrawClear;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.xlAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight:
                activeTool == EditorTool.overlays ||
                    activeTool == EditorTool.audio ||
                    activeTool == EditorTool.draw
                ? (isTablet ? 360 : 310)
                : (isTablet ? 260 : 210),
          ),
          decoration: BoxDecoration(
            color: palette.mediaSurfaceStrong,
            borderRadius: AppRadii.xlAll,
            border: Border.all(color: palette.mediaBorder),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildToolContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildToolContent() {
    return switch (activeTool) {
      EditorTool.trim => const SizedBox.shrink(),
      EditorTool.effects => CompactEffectsTool(
        key: const ValueKey('effects'),
        palette: palette,
        session: session,
        onFilterChanged: onFilterChanged,
        onAdjustmentsChanged: onAdjustmentsChanged,
        onPlaybackSpeedChanged: onPlaybackSpeedChanged,
      ),
      EditorTool.overlays => CompactOverlayTool(
        key: const ValueKey('overlays'),
        palette: palette,
        session: session,
        onStickerSelected: onStickerSelected,
        onOpenSelfieStickerCapture: onOpenSelfieStickerCapture,
        userStickers: userStickers,
        onDeleteUserSticker: onDeleteUserSticker,
      ),
      EditorTool.audio => CompactAudioTool(
        key: const ValueKey('audio'),
        palette: palette,
        session: session,
        onMusicSelected: onMusicSelected,
        onMusicRemoved: onMusicRemoved,
        onMusicVolumeChanged: onMusicVolumeChanged,
        onMusicPreviewToggled: onMusicPreviewToggled,
        previewingTrackId: previewingTrackId,
        cachedTrackIds: cachedAudioTrackIds,
        downloadingTrackIds: downloadingAudioTrackIds,
      ),
      EditorTool.text => CompactTextTool(
        key: const ValueKey('text'),
        palette: palette,
        session: session,
        selectedOverlayId: selectedOverlayId,
        onAddTextOverlay: onAddTextOverlay,
        onTextChanged: onTextChanged,
      ),
      EditorTool.draw => CompactDrawingTool(
        key: const ValueKey('draw'),
        palette: palette,
        activeTool: activeDrawTool,
        colorValue: drawColorValue,
        width: drawWidth,
        canUndo: session.strokes.isNotEmpty,
        canClear: session.strokes.isNotEmpty,
        onToolChanged: onDrawToolChanged,
        onColorChanged: onDrawColorChanged,
        onWidthChanged: onDrawWidthChanged,
        onUndo: onDrawUndo,
        onClear: onDrawClear,
      ),
    };
  }
}

// ── Compact Effects Tool ────────────────────────────────────────────────

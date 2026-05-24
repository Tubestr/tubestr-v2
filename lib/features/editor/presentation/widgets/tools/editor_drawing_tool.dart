import 'package:flutter/material.dart';

import '../../../../../core/theme/radii.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/theme_descriptor.dart';
import '../../../../../domain/models/editor_session.dart';
import '../../../../../l10n/l10n.dart';
import '../editor_text_constants.dart';

class CompactDrawingTool extends StatelessWidget {
  const CompactDrawingTool({
    super.key,
    required this.palette,
    required this.activeTool,
    required this.colorValue,
    required this.width,
    required this.canUndo,
    required this.canClear,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onWidthChanged,
    required this.onUndo,
    required this.onClear,
  });

  final KidPalette palette;
  final EditorDrawTool activeTool;
  final int colorValue;
  final double width;
  final bool canUndo;
  final bool canClear;
  final ValueChanged<EditorDrawTool> onToolChanged;
  final ValueChanged<int> onColorChanged;
  final ValueChanged<double> onWidthChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolChip(
                    palette: palette,
                    label: context.l10n.editorDrawToolPencil,
                    icon: Icons.edit_rounded,
                    selected: activeTool == EditorDrawTool.pencil,
                    onTap: () => onToolChanged(EditorDrawTool.pencil),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _ToolChip(
                    palette: palette,
                    label: context.l10n.editorDrawToolMarker,
                    icon: Icons.brush_rounded,
                    selected: activeTool == EditorDrawTool.marker,
                    onTap: () => onToolChanged(EditorDrawTool.marker),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _ToolChip(
                    palette: palette,
                    label: context.l10n.editorDrawToolEraser,
                    icon: Icons.auto_fix_normal_rounded,
                    selected: activeTool == EditorDrawTool.eraser,
                    onTap: () => onToolChanged(EditorDrawTool.eraser),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (final color in editorTextToolColors) ...[
                  GestureDetector(
                    onTap: () => onColorChanged(color.toARGB32()),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorValue == color.toARGB32()
                              ? palette.mediaInk
                              : palette.mediaBorder,
                          width: colorValue == color.toARGB32() ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.editorDrawUndo,
                  onPressed: canUndo ? onUndo : null,
                  icon: const Icon(Icons.undo_rounded),
                  color: palette.mediaInk,
                  disabledColor: palette.mediaSubtleInk,
                ),
                IconButton(
                  tooltip: context.l10n.editorDrawClear,
                  onPressed: canClear ? onClear : null,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  color: palette.mediaInk,
                  disabledColor: palette.mediaSubtleInk,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  context.l10n.editorDrawWidthLabel,
                  style: TextStyle(
                    color: palette.mediaSubtleInk,
                    fontSize: AppTextSize.caption,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      activeTrackColor: palette.mediaMutedInk,
                      inactiveTrackColor: palette.mediaSurfaceSubtle,
                      thumbColor: palette.mediaInk,
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 10,
                      ),
                    ),
                    child: Slider(
                      value: width.clamp(2, 24),
                      min: 2,
                      max: 24,
                      onChanged: onWidthChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({
    required this.palette,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final KidPalette palette;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [palette.accent, palette.accentSecondary],
                )
              : null,
          color: selected ? null : palette.mediaSurfaceSubtle,
          borderRadius: AppRadii.mdAll,
          border: Border.all(
            color: selected ? palette.mediaBorderStrong : palette.mediaBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.sm, color: palette.mediaInk),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                color: palette.mediaInk,
                fontSize: AppTextSize.label,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

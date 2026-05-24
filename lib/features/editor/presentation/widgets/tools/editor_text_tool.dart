import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/radii.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/theme/theme_descriptor.dart';
import '../../../../../domain/models/editor_session.dart';
import '../../../../../l10n/l10n.dart';
import '../editor_text_constants.dart';

class CompactTextTool extends StatefulWidget {
  const CompactTextTool({
    super.key,
    required this.palette,
    required this.session,
    required this.selectedOverlayId,
    required this.onAddTextOverlay,
    required this.onTextChanged,
  });

  final KidPalette palette;
  final EditorSession session;
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

  @override
  State<CompactTextTool> createState() => CompactTextToolState();
}

class CompactTextToolState extends State<CompactTextTool> {
  final TextEditingController _controller = TextEditingController();
  String? _syncedOverlayId;

  EditorOverlayItem? get _selectedText {
    final id = widget.selectedOverlayId;
    if (id == null) return null;
    return widget.session.overlays
        .where((item) => item.id == id && item.type == EditorOverlayType.text)
        .firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _syncController(_selectedText);
  }

  @override
  void didUpdateWidget(covariant CompactTextTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_selectedText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncController(EditorOverlayItem? overlay) {
    if (overlay == null) {
      if (_syncedOverlayId != null) {
        _controller.text = '';
        _syncedOverlayId = null;
      }
      return;
    }
    final incoming = overlay.text ?? '';
    if (_syncedOverlayId != overlay.id || _controller.text != incoming) {
      _controller.value = TextEditingValue(
        text: incoming,
        selection: TextSelection.collapsed(offset: incoming.length),
      );
      _syncedOverlayId = overlay.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedText;

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
            Row(
              children: [
                Expanded(
                  child: selected == null
                      ? Text(
                          context.l10n.editorTapText,
                          style: TextStyle(
                            color: widget.palette.mediaMutedInk,
                            fontSize: AppTextSize.label,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: widget.palette.mediaInk,
                            fontSize: AppTextSize.body,
                          ),
                          decoration: InputDecoration(
                            hintText: context.l10n.editorTypeSomething,
                            hintStyle: TextStyle(
                              color: widget.palette.mediaSubtleInk,
                            ),
                            filled: true,
                            fillColor: widget.palette.mediaSurfaceSubtle,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: AppRadii.lgAll,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) => widget.onTextChanged(
                            overlayId: selected.id,
                            text: value,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AddTextButton(
                  palette: widget.palette,
                  onTap: widget.onAddTextOverlay,
                ),
              ],
            ),
            if (selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final family in editorTextToolFontFamilies) ...[
                      GestureDetector(
                        onTap: () => widget.onTextChanged(
                          overlayId: selected.id,
                          fontFamily: family,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected.fontFamily == family
                                ? LinearGradient(
                                    colors: [
                                      widget.palette.accent,
                                      widget.palette.accentSecondary,
                                    ],
                                  )
                                : null,
                            color: selected.fontFamily == family
                                ? null
                                : widget.palette.mediaSurfaceSubtle,
                            borderRadius: AppRadii.mdAll,
                          ),
                          child: Text(
                            'Aa',
                            style: TextStyle(
                              fontFamily: family,
                              color: widget.palette.mediaInk,
                              fontSize: AppTextSize.label,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    const SizedBox(width: AppSpacing.xs),
                    for (final color in editorTextToolColors) ...[
                      GestureDetector(
                        onTap: () => widget.onTextChanged(
                          overlayId: selected.id,
                          color: color,
                        ),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected.textColorValue == color.toARGB32()
                                  ? widget.palette.mediaInk
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text(
                    'Size',
                    style: TextStyle(
                      color: widget.palette.mediaSubtleInk,
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
                        activeTrackColor: widget.palette.mediaMutedInk,
                        inactiveTrackColor: widget.palette.mediaSurfaceSubtle,
                        thumbColor: widget.palette.mediaInk,
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: selected.textSize.clamp(24, 96),
                        min: 24,
                        max: 96,
                        onChanged: (value) => widget.onTextChanged(
                          overlayId: selected.id,
                          textSize: value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddTextButton extends StatelessWidget {
  const AddTextButton({super.key, required this.palette, required this.onTap});

  final KidPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.accent, palette.accentSecondary],
          ),
          borderRadius: AppRadii.mdAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              color: palette.onAccent,
              size: AppIconSize.md,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.l10n.editorAddText,
              style: TextStyle(
                color: palette.onAccent,
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

// ── Preview Pane ────────────────────────────────────────────────────────

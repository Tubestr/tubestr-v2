import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../domain/models/editor_session.dart';
import '../../../../l10n/l10n.dart';

class SideToolbar extends StatelessWidget {
  const SideToolbar({
    super.key,
    required this.palette,
    required this.activeTool,
    required this.onToolTap,
    this.isTablet = false,
    this.isCompact = false,
  });

  final KidPalette palette;
  final EditorTool? activeTool;
  final ValueChanged<EditorTool?> onToolTap;
  final bool isTablet;
  final bool isCompact;

  static const _tools = EditorTool.values;

  @override
  Widget build(BuildContext context) {
    final spacing = isCompact ? 2.0 : (isTablet ? 10.0 : 6.0);
    final toolbar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _tools.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          SideToolButton(
            palette: palette,
            tool: _tools[i],
            isActive: activeTool == _tools[i],
            onTap: () => onToolTap(_tools[i]),
            isTablet: isTablet,
            isCompact: isCompact,
          ),
        ],
      ],
    );

    if (!isCompact) {
      return Center(child: toolbar);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 0.0;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(child: toolbar),
          ),
        );
      },
    );
  }
}

class SideToolButton extends StatelessWidget {
  const SideToolButton({
    super.key,
    required this.palette,
    required this.tool,
    required this.isActive,
    required this.onTap,
    this.isTablet = false,
    this.isCompact = false,
  });

  final KidPalette palette;
  final EditorTool tool;
  final bool isActive;
  final VoidCallback onTap;
  final bool isTablet;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final btnSize = isCompact ? 44.0 : (isTablet ? 60.0 : 52.0);
    final iconSize = isCompact ? 22.0 : (isTablet ? 28.0 : 24.0);
    final labelSize = isTablet ? 11.0 : 10.0;
    final label = _labelFor(tool, context);

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isActive ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(btnSize / 2),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: btnSize,
                      height: btnSize,
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  palette.accent,
                                  palette.accentSecondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isActive ? null : palette.mediaSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? palette.mediaBorderStrong
                              : palette.mediaBorder,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: palette.accent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        _iconFor(tool),
                        color: palette.mediaInk,
                        size: iconSize,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? palette.mediaInk : palette.mediaMutedInk,
                    fontSize: labelSize,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    shadows: [Shadow(blurRadius: 6, color: palette.mediaScrim)],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(EditorTool tool) {
    return switch (tool) {
      EditorTool.trim => Icons.content_cut_rounded,
      EditorTool.effects => Icons.auto_awesome_rounded,
      EditorTool.overlays => Icons.face_retouching_natural,
      EditorTool.audio => Icons.music_note_rounded,
      EditorTool.text => Icons.text_fields_rounded,
      EditorTool.draw => Icons.brush_rounded,
    };
  }

  static String _labelFor(EditorTool tool, BuildContext context) {
    return switch (tool) {
      EditorTool.trim => context.l10n.editorToolTrim,
      EditorTool.effects => context.l10n.editorToolEffects,
      EditorTool.overlays => context.l10n.editorToolStickers,
      EditorTool.audio => context.l10n.editorToolAudio,
      EditorTool.text => context.l10n.editorToolText,
      EditorTool.draw => context.l10n.editorToolDraw,
    };
  }
}

// ── Timeline Bar ────────────────────────────────────────────────────────

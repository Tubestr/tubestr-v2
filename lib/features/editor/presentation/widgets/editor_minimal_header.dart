import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../l10n/l10n.dart';
import 'editor_frosted_buttons.dart';

class MinimalHeader extends StatelessWidget {
  const MinimalHeader({
    super.key,
    required this.palette,
    required this.isExporting,
    required this.onExport,
  });

  final KidPalette palette;
  final bool isExporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FrostedCircleButton(
          palette: palette,
          onTap: () => Navigator.of(context).pop(),
          child: Icon(
            Icons.arrow_back_rounded,
            color: palette.mediaInk,
            size: AppIconSize.xl,
          ),
        ),
        const Spacer(),
        FrostedPillButton(
          palette: palette,
          onTap: isExporting ? null : onExport,
          accentGradient: LinearGradient(
            colors: [
              palette.accent.withValues(alpha: 0.7),
              palette.accentSecondary.withValues(alpha: 0.7),
            ],
          ),
          icon: isExporting
              ? SizedBox(
                  width: AppIconSize.md,
                  height: AppIconSize.md,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(palette.mediaInk),
                  ),
                )
              : Icon(
                  Icons.file_upload_outlined,
                  color: palette.mediaInk,
                  size: AppIconSize.lg,
                ),
          label: isExporting
              ? context.l10n.editorActionExporting
              : context.l10n.editorActionExport,
        ),
      ],
    );
  }
}

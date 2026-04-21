import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/components/pin_widgets.dart';
import '../../../../l10n/l10n.dart';

class ParentZonePinSetupView extends StatelessWidget {
  const ParentZonePinSetupView({
    super.key,
    required this.palette,
    required this.pinError,
    required this.onNewPinChanged,
    required this.onConfirmPinChanged,
    required this.onSavePin,
  });

  final KidPalette palette;
  final String? pinError;
  final ValueChanged<String> onNewPinChanged;
  final ValueChanged<String> onConfirmPinChanged;
  final VoidCallback onSavePin;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? AppSpacing.xl : AppSpacing.xxxl;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: hPad,
          right: hPad,
          top: AppSpacing.xxxl,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxxl,
        ),
        child: Center(
          child: FrostCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadii.lgAll,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: AppIconSize.display,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.l10n.parentCreatePinTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.parentPinCreateDetail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.parentPinNew,
                    counterText: '',
                  ),
                  onChanged: onNewPinChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: context.l10n.parentPinConfirm,
                    counterText: '',
                  ),
                  onChanged: onConfirmPinChanged,
                ),
                if (pinError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pinError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.parentPinUpdateLater,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSavePin,
                    child: Text(context.l10n.parentPinSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ParentZonePinEntryView extends StatelessWidget {
  const ParentZonePinEntryView({
    super.key,
    required this.palette,
    required this.pinEntry,
    required this.pinError,
    required this.onDigit,
    required this.onDelete,
  });

  final KidPalette palette;
  final String pinEntry;
  final String? pinError;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final hPad = screenWidth < 600 ? AppSpacing.xl : AppSpacing.xxxl;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: hPad,
          vertical: AppSpacing.xxxl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: FrostCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.12),
                      borderRadius: AppRadii.lgAll,
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      size: AppIconSize.display,
                      color: palette.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    context.l10n.parentUnlockTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.parentPinUnlockDetail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Align(
                    alignment: Alignment.center,
                    child: PinDots(filled: pinEntry.length),
                  ),
                  if (pinError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        pinError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  PinKeypad(onDigit: onDigit, onDelete: onDelete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

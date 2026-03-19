import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme_descriptor.dart';
import '../../../../shared_ui/components/kid_scaffold.dart';
import '../../../../shared_ui/components/pin_widgets.dart';

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
    final hPad = screenWidth < 600 ? 20.0 : 32.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: hPad,
          right: hPad,
          top: 32,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 28,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Create Parent PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a four-digit code so family controls stay separate from the kid-facing app.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                ),
                const SizedBox(height: 20),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'New PIN (4 digits)',
                    counterText: '',
                  ),
                  onChanged: onNewPinChanged,
                ),
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Confirm PIN',
                    counterText: '',
                  ),
                  onChanged: onConfirmPinChanged,
                ),
                if (pinError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    pinError!,
                    style: TextStyle(color: palette.danger, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'You can update this later in Settings.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.mutedInk),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onSavePin,
                    child: const Text('Save PIN'),
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
    final hPad = screenWidth < 600 ? 20.0 : 32.0;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
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
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 28,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlock Parent Zone',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your four-digit PIN to open family settings, approvals, and safety controls.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: PinDots(filled: pinEntry.length),
                ),
                if (pinError != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      pinError!,
                      style: TextStyle(color: palette.danger, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
                    child: PinKeypad(onDigit: onDigit, onDelete: onDelete),
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

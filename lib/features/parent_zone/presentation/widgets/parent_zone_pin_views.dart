import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: FrostCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 48, color: palette.accent),
                const SizedBox(height: 16),
                Text(
                  'Create Parent PIN',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a 4-digit PIN to protect parent tools.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.mutedInk),
                ),
                const SizedBox(height: 20),
                TextField(
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
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
    required this.onSubmit,
  });

  final KidPalette palette;
  final String pinEntry;
  final String? pinError;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, size: 48, color: palette.accent),
              const SizedBox(height: 16),
              Text(
                'Unlock Parent Tools',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              PinDots(filled: pinEntry.length),
              if (pinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  pinError!,
                  style: TextStyle(color: palette.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: 280,
                child: PinKeypad(
                  onDigit: onDigit,
                  onDelete: onDelete,
                  onSubmit: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/radii.dart';
import '../../core/theme/spacing.dart';

/// Four dots that fill in as digits are entered.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filled, this.total = 4});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: AppIconSize.md,
          height: AppIconSize.md,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? accent : accent.withValues(alpha: 0),
            border: Border.all(
              color: isFilled ? accent : accent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

/// 3×4 numeric keypad: 1-9, ⌫, 0.
class PinKeypad extends StatelessWidget {
  const PinKeypad({super.key, required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  static const _keys = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '',
    '0',
    '⌫',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.6,
      ),
      itemCount: _keys.length,
      itemBuilder: (context, i) {
        final key = _keys[i];
        if (key.isEmpty) {
          return const SizedBox.shrink();
        }
        if (key == '⌫') {
          return _KeypadButton(
            onTap: onDelete,
            child: Icon(Icons.backspace_outlined, color: accent),
          );
        }
        return _KeypadButton(
          onTap: () => onDigit(key),
          child: Text(
            key,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: AppRadii.xlAll,
      child: InkWell(
        borderRadius: AppRadii.xlAll,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Center(child: child),
      ),
    );
  }
}

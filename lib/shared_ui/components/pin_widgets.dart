import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? accent : Colors.transparent,
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

/// 3×4 numeric keypad: 1-9, ⌫, 0, OK.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    required this.onSubmit,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '⌫', '0', 'OK',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: _keys.length,
      itemBuilder: (context, i) {
        final key = _keys[i];
        if (key == '⌫') {
          return _KeypadButton(
            onTap: onDelete,
            child: Icon(Icons.backspace_outlined, color: accent),
          );
        }
        if (key == 'OK') {
          return _KeypadButton(
            color: accent.withValues(alpha: 0.12),
            onTap: onSubmit,
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          );
        }
        return _KeypadButton(
          onTap: () => onDigit(key),
          child: Text(
            key,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onTap,
    required this.child,
    this.color,
  });

  final VoidCallback onTap;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Center(child: child),
      ),
    );
  }
}

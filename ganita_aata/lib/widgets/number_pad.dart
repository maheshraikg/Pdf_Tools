import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'l10n_ext.dart';

/// A large on-screen number pad: digits, backspace and OK. When
/// [showRemainderKey] is true an "R" key separates quotient and remainder.
class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onKey,
    required this.onBackspace,
    required this.onSubmit,
    this.showRemainderKey = false,
    this.keyHeight = 64,
  });

  final double keyHeight;

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool showRemainderKey;

  @override
  Widget build(BuildContext context) {
    final r = context.l10n.remainderShort;
    Widget key(String label, {VoidCallback? onTap, Color? color, Widget? child, String? id}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: 2,
          child: InkWell(
            key: ValueKey('key_${id ?? label}'),
            borderRadius: BorderRadius.circular(20),
            onTap: onTap ?? () => onKey(label),
            child: SizedBox(
              height: keyHeight,
              child: Center(
                child: child ?? Text(label, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [key('1'), key('2'), key('3')]),
        Row(children: [key('4'), key('5'), key('6')]),
        Row(children: [key('7'), key('8'), key('9')]),
        Row(
          children: [
            if (showRemainderKey)
              key(r, id: 'R', onTap: () => onKey('R'), color: const Color(0xFFEDE7FF))
            else
              key(
                '⌫',
                id: 'back',
                onTap: onBackspace,
                color: const Color(0xFFFFE9D6),
                child: const Icon(Icons.backspace_outlined, size: 30),
              ),
            key('0'),
            key(
              'OK',
              id: 'ok',
              onTap: onSubmit,
              color: AppColors.good,
              child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
            ),
          ],
        ),
        if (showRemainderKey)
          Row(
            children: [
              key(
                '⌫',
                id: 'back',
                onTap: onBackspace,
                color: const Color(0xFFFFE9D6),
                child: const Icon(Icons.backspace_outlined, size: 30),
              ),
            ],
          ),
      ],
    );
  }
}

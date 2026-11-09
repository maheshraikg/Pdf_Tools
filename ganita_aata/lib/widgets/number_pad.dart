import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'common.dart';
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

  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool showRemainderKey;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    final r = context.l10n.remainderShort;
    Widget key(String label, {VoidCallback? onTap, Color? color, Widget? child, String? id, Color? edge}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          height: keyHeight,
          child: ChunkyButton(
            key: ValueKey('key_${id ?? label}'),
            color: color ?? Colors.white,
            edgeColor: edge ?? const Color(0xFFD5CFEA),
            radius: 18,
            depth: 5,
            padding: EdgeInsets.zero,
            onTap: onTap ?? () => onKey(label),
            child: child ?? Text(label, style: display(34, height: 1)),
          ),
        ),
      ),
    );
    final back = key(
      '⌫',
      id: 'back',
      onTap: onBackspace,
      color: const Color(0xFFFFE6CC),
      edge: const Color(0xFFF2C08F),
      child: const Icon(Icons.backspace_rounded, size: 30, color: AppColors.primaryDark),
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
              key(
                r,
                id: 'R',
                onTap: () => onKey('R'),
                color: const Color(0xFFEDE7FF),
                edge: const Color(0xFFC9BCF7),
                child: Text(r, style: display(30, color: AppColors.secondary, height: 1)),
              )
            else
              back,
            key('0'),
            key(
              'OK',
              id: 'ok',
              onTap: onSubmit,
              color: AppColors.good,
              edge: AppColors.goodDark,
              child: const Icon(Icons.check_rounded, size: 42, color: Colors.white),
            ),
          ],
        ),
        if (showRemainderKey) Row(children: [back]),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// Large custom numeric keypad (no system keyboard delay).
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({super.key, required this.onDigit, required this.onBackspace, required this.onClear, this.scale = 1.0, this.extraKey});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final double scale;

  /// Optional widget replacing the "clear" key position.
  final Widget? extraKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final h = 58.0 * scale;
    Widget key(String label, {VoidCallback? onTap, Widget? child, String? semantics, Color? bg}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Semantics(
          button: true,
          label: semantics ?? label,
          child: Material(
            color: bg ?? Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              key: ValueKey('key_$label'),
              borderRadius: BorderRadius.circular(12),
              onTap: onTap ?? () => onDigit(label),
              onLongPress: label == '⌫' ? onClear : null,
              child: SizedBox(
                height: h,
                child: Center(
                  child: child ??
                      Text(label, style: TextStyle(fontSize: 30 * scale.clamp(0.8, 1.3), fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']])
          Row(children: [for (final d in row) key(d)]),
        Row(
          children: [
            key('C', onTap: onClear, semantics: l.clear, bg: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(l.clear, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            key('0'),
            key('⌫', onTap: onBackspace, semantics: l.backspace, bg: Theme.of(context).colorScheme.secondaryContainer,
                child: const Icon(Icons.backspace_outlined, size: 30)),
          ],
        ),
      ],
    );
  }
}

/// "5 7 4 _ _ _" display of the PIN being typed.
class PinDisplay extends StatelessWidget {
  const PinDisplay({super.key, required this.digits, this.error = false});

  final String digits;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: digits.isEmpty ? AppLocalizations.of(context).enterPin : digits.split('').join(' '),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 6; i++) ...[
            Container(
              width: 40,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(width: 3, color: error ? c.error : (i < digits.length ? c.primary : c.outlineVariant))),
              ),
              child: Text(
                i < digits.length ? digits[i] : '',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: error ? c.error : null),
              ),
            ),
            if (i == 2) const SizedBox(width: 14) else const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

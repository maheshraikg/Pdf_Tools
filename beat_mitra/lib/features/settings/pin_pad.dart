import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Big numeric keypad with dots (no keyboard / text field needed).
class PinPad extends StatefulWidget {
  const PinPad({super.key, required this.onDone, this.length = 4, this.extraKey, this.error});
  final Future<bool> Function(String pin) onDone;
  final int length;
  final Widget? extraKey;
  final String? error;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _pin = '';
  bool _busy = false;

  Future<void> _tap(String d) async {
    if (_busy || _pin.length >= widget.length) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += d);
    if (_pin.length == widget.length) {
      setState(() => _busy = true);
      final ok = await widget.onDone(_pin);
      if (!mounted) return;
      if (!ok) HapticFeedback.heavyImpact();
      setState(() {
        _pin = '';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget key(String d) => Semantics(
      button: true,
      label: d,
      child: SizedBox(
        width: 84,
        height: 72,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
          onPressed: () => _tap(d),
          child: Text(d, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              Container(
                margin: const EdgeInsets.all(8),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? scheme.primary : Colors.transparent,
                  border: Border.all(color: scheme.primary, width: 2),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 28,
          child: widget.error == null
              ? null
              : Text(
                  widget.error!,
                  style: TextStyle(color: scheme.error, fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final d in row) key(d)]),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(width: 84, height: 72, child: widget.extraKey),
              key('0'),
              SizedBox(
                width: 84,
                height: 72,
                child: IconButton(
                  icon: const Icon(Icons.backspace_outlined, size: 30),
                  tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                  onPressed: () {
                    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

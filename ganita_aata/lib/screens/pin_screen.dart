import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';

/// Asks for the parent PIN (creating one first if none is set).
/// Returns true when the parent may continue.
Future<bool> requireParentPin(BuildContext context) async {
  final app = context.read<AppState>();
  final mode = app.hasPin ? PinMode.verify : PinMode.create;
  final ok = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => PinScreen(mode: mode), fullscreenDialog: true));
  return ok ?? false;
}

/// Sets a new PIN (after the old one was checked).
Future<bool> changeParentPin(BuildContext context) async {
  final ok = await Navigator.of(context)
      .push<bool>(MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.change), fullscreenDialog: true));
  return ok ?? false;
}

enum PinMode { verify, create, change }

class PinScreen extends StatefulWidget {
  const PinScreen({super.key, required this.mode});

  static const length = 4;

  final PinMode mode;

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String? _first;
  String? _error;

  String _title() {
    final l = context.l10n;
    if (widget.mode == PinMode.verify) return l.enterPin;
    if (_first != null) return l.confirmPin;
    return widget.mode == PinMode.change ? l.newPin : l.createPin;
  }

  void _digit(String d) {
    if (_pin.length >= PinScreen.length) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == PinScreen.length) Future.delayed(const Duration(milliseconds: 120), _complete);
  }

  void _complete() {
    if (!mounted) return;
    final app = context.read<AppState>();
    final l = context.l10n;
    if (widget.mode == PinMode.verify) {
      if (app.checkPin(_pin)) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _pin = '';
          _error = l.pinWrong;
        });
      }
      return;
    }
    if (_first == null) {
      setState(() {
        _first = _pin;
        _pin = '';
      });
    } else if (_first == _pin) {
      app.setPin(_pin);
      Navigator.pop(context, true);
    } else {
      setState(() {
        _first = null;
        _pin = '';
        _error = l.pinMismatch;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget key(String d) => Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 84,
        height: 72,
        child: ChunkyButton(
          key: ValueKey('pin_$d'),
          color: Colors.white,
          edgeColor: const Color(0xFFD5CFEA),
          radius: 20,
          depth: 5,
          padding: EdgeInsets.zero,
          onTap: () => _digit(d),
          child: Text(d, style: display(32, height: 1)),
        ),
      ),
    );
    return Theme(
      data: buildParentTheme(),
      child: Scaffold(
        appBar: AppBar(title: Text(l.forParents)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.lock_rounded, size: 56, color: AppColors.secondary),
                Text(l.pinForParents, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 12),
                Text(_title(), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < PinScreen.length; i++)
                      Container(
                        margin: const EdgeInsets.all(8),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length ? AppColors.secondary : Colors.transparent,
                          border: Border.all(color: AppColors.secondary, width: 2),
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 52,
                  child: _error == null
                      ? null
                      : Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFB35C00), fontSize: 17),
                        ),
                ),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Column(
                    children: [
                      for (final row in const [
                        ['1', '2', '3'],
                        ['4', '5', '6'],
                        ['7', '8', '9'],
                      ])
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final d in row) key(d)]),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 100),
                          key('0'),
                          SizedBox(
                            width: 100,
                            child: IconButton(
                              iconSize: 32,
                              onPressed: _pin.isEmpty
                                  ? null
                                  : () => setState(() => _pin = _pin.substring(0, _pin.length - 1)),
                              icon: const Icon(Icons.backspace_outlined),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.mode == PinMode.verify)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      l.pinForgot,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
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

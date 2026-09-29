/// Home screen: type a PIN on the big keypad, results update live.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/constants.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/pin_utils.dart';
import '../../core/voice_input.dart';
import '../../core/widgets.dart';
import '../../data/sort_engine.dart';
import '../find_pin/mismatch_view.dart';
import '../scan/scan_screen.dart';
import 'keypad.dart';
import 'label_view.dart';
import 'sort_result_view.dart';

class SortScreen extends StatefulWidget {
  const SortScreen({super.key});

  @override
  State<SortScreen> createState() => SortScreenState();
}

class SortScreenState extends State<SortScreen> {
  String _digits = '';
  SortResult? _result;
  int _seq = 0;
  List<int> _recents = [];
  int _recentsVersion = -1;
  final _place = TextEditingController();
  bool _placeOpen = false;
  String _lastSpoken = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.services.recentsVersion;
    if (v != _recentsVersion) {
      _recentsVersion = v;
      _loadRecents();
    }
    _placeOpen = _placeOpen || context.settings.showMismatchField;
  }

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final r = await context.services.user.recents();
    if (mounted) setState(() => _recents = r);
  }

  /// Sets a complete PIN from outside (Find PIN, favourites, scan).
  void setPin(String pin, {String? place}) {
    if (place != null) {
      _place.text = place;
      _placeOpen = true;
    }
    _update(PinUtils.digitsOnly(pin));
  }

  void _update(String digits) {
    if (digits.length > 6) digits = digits.substring(0, 6);
    setState(() => _digits = digits);
    _resolve();
  }

  Future<void> _resolve() async {
    final seq = ++_seq;
    final services = context.services;
    final settings = context.settings;
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    if (_digits.isEmpty) {
      setState(() => _result = null);
      return;
    }
    final r = await services.engine.resolvePin(_digits, category: settings.category, officeName: _placeOpen ? _place.text : null);
    if (!mounted || seq != _seq) return;
    setState(() => _result = r);
    if (r.complete && r.valid) {
      if (r.bag == null || r.notInDirectory || (isAirCategory(r.category) && r.air == null)) {
        AppFeedback.warning(settings);
      } else {
        AppFeedback.success(settings);
      }
      final key = '${r.digits}|${r.category}';
      if (key != _lastSpoken) {
        _lastSpoken = key;
        AppFeedback.speak(settings, spokenResult(l, r), lang: lang);
        await services.user.addRecent(int.parse(r.digits));
        services.touchRecents();
      }
    }
  }

  void _digit(String d) {
    AppFeedback.tap(context.settings);
    if (_digits.length >= 6) {
      // Typing a 7th digit starts a new PIN: fastest flow for sorting.
      _lastSpoken = '';
      _update(d);
    } else {
      _update(_digits + d);
    }
  }

  Future<void> _voice() async {
    final lang = Localizations.localeOf(context).languageCode;
    final d = await listenForDigits(context, languageCode: lang);
    if (d != null && d.isNotEmpty) _update(d.length > 6 ? d.substring(0, 6) : d);
  }

  Future<void> _scan() async {
    final r = await Navigator.push<ScanOutcome>(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (r != null && r.pin.isNotEmpty) setPin(r.pin, place: r.place);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final settings = context.settings;
    final services = context.services;
    final scheme = services.active;
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navSort),
        actions: [
          if (scheme?.scheme.isSample ?? false) const Padding(padding: EdgeInsets.only(right: 4), child: SampleChip()),
          IconButton(
            tooltip: l.checkPlace,
            icon: Icon(_placeOpen ? Icons.location_off_outlined : Icons.fact_check_outlined),
            onPressed: () => setState(() {
              _placeOpen = !_placeOpen;
              settings.showMismatchField = _placeOpen;
            }),
          ),
          if (r != null && r.complete && r.valid)
            IconButton(
              tooltip: l.labelView,
              icon: const Icon(Icons.label_outline),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelViewScreen(result: r))),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mail category toggle.
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                children: [
                  for (final c in services.categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(categoryLabel(l, c)),
                        selected: settings.category == c,
                        onSelected: (_) {
                          settings.category = c;
                          _lastSpoken = '';
                          _resolve();
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton.filledTonal(iconSize: 30, tooltip: l.voiceInput, onPressed: _voice, icon: const Icon(Icons.mic)),
                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: PinDisplay(digits: _digits, error: r != null && r.complete && !r.valid))),
                  IconButton.filledTonal(iconSize: 30, tooltip: l.scanAddress, onPressed: _scan, icon: const Icon(Icons.document_scanner_outlined)),
                ],
              ),
            ),
            if (_placeOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: TextField(
                  controller: _place,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: l.placeOnAddress,
                    prefixIcon: const Icon(Icons.place_outlined),
                    suffixIcon: _place.text.isEmpty
                        ? null
                        : IconButton(tooltip: l.clear, icon: const Icon(Icons.close), onPressed: () => setState(_place.clear)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  if (scheme == null && _digits.isEmpty)
                    WarningBanner(text: l.noActiveScheme, icon: Icons.rule_folder_outlined),
                  if (_placeOpen && _digits.length == 6 && _place.text.trim().length >= 2) ...[
                    MismatchView(pin: _digits, place: _place.text, onPickPin: (o) => setPin(o.pin)),
                    const SizedBox(height: 10),
                  ],
                  if (r != null && r.digits == _digits) SortResultView(result: r),
                  if (_digits.isEmpty && _recents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Text(l.recentLookups, style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          await services.user.clearRecents();
                          services.touchRecents();
                        },
                        child: Text(l.clear),
                      ),
                    ]),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final p in _recents) ActionChip(label: Text('$p', style: const TextStyle(fontSize: 18)), onPressed: () => setPin('$p'))],
                    ),
                  ],
                  if (_digits.isEmpty && _recents.isEmpty && scheme != null)
                    Padding(padding: const EdgeInsets.all(24), child: Text(l.sortHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: NumericKeypad(
                scale: settings.keypadScale,
                onDigit: _digit,
                onBackspace: () {
                  AppFeedback.tap(settings);
                  if (_digits.isNotEmpty) _update(_digits.substring(0, _digits.length - 1));
                },
                onClear: () {
                  AppFeedback.tap(settings);
                  _lastSpoken = '';
                  _update('');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

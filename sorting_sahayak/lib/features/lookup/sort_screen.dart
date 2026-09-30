/// Home screen: type a PIN (or office name) with the phone keyboard; the
/// bag is shown big at the top and matching rules are listed live below.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_scope.dart';
import '../../core/constants.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/pin_utils.dart';
import '../../core/theme.dart';
import '../../core/voice_input.dart';
import '../../core/widgets.dart';
import '../../data/live_search.dart';
import '../../data/models/office.dart';
import '../../data/models/scheme.dart';
import '../../data/scheme_repo.dart';
import '../../data/sort_engine.dart';
import '../find_pin/mismatch_view.dart';
import '../scan/scan_screen.dart';
import '../schemes/scheme_editor.dart';
import 'label_view.dart';
import 'sort_result_view.dart';

class SortScreen extends StatefulWidget {
  const SortScreen({super.key});

  @override
  State<SortScreen> createState() => SortScreenState();
}

class SortScreenState extends State<SortScreen> {
  String _digits = '';
  String _query = '';
  bool _letters = false;
  final _input = TextEditingController();
  final _focus = FocusNode();
  SortResult? _result;
  int _seq = 0;
  List<int> _recents = [];
  int _recentsVersion = -1;
  final _place = TextEditingController();
  bool _placeOpen = false;
  String _lastSpoken = '';
  Object? _schemeSeen;
  List<_PlaceHit> _places = [];
  int _placeSeq = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final v = context.services.recentsVersion;
    if (v != _recentsVersion) {
      _recentsVersion = v;
      _loadRecents();
    }
    _placeOpen = _placeOpen || context.settings.showMismatchField;
    // Re-resolve when the active scheme changes (import, edit, switch).
    final scheme = context.services.active;
    if (!identical(scheme, _schemeSeen)) {
      final first = _schemeSeen == null && scheme == null;
      _schemeSeen = scheme;
      if (!first && _digits.isNotEmpty) _resolve();
      if (!first && _places.isNotEmpty) _searchPlaces();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
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
    _letters = false;
    _setText(PinUtils.digitsOnly(pin));
  }

  void _setText(String text) {
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _onChanged(text);
  }

  void _onChanged(String text) {
    final t = PinUtils.normalizeDigits(text);
    if (RegExp(r'[^\d\s]').hasMatch(t)) {
      // Office / place name: scheme rules plus the PIN directory (BOs too).
      setState(() {
        _query = t.trim();
        _digits = '';
        _result = null;
      });
      _searchPlaces();
      return;
    }
    if (_places.isNotEmpty) _places = [];
    var d = PinUtils.digitsOnly(t);
    if (d.length > 6) {
      // Typing a 7th digit starts a new PIN: fastest flow for sorting.
      _lastSpoken = '';
      d = d.substring(6);
      _input.value = TextEditingValue(
        text: d,
        selection: TextSelection.collapsed(offset: d.length),
      );
    }
    setState(() {
      _digits = d;
      _query = d;
    });
    _resolve();
  }

  /// Post offices (HO / SO / BO) matching the typed name, each with its PIN,
  /// account office (SO) and the line / bag from the active scheme.
  Future<void> _searchPlaces() async {
    final q = _query;
    final seq = ++_placeSeq;
    if (q.length < 3) {
      setState(() => _places = []);
      return;
    }
    final services = context.services;
    final category = context.settings.category;
    final hits = await services.directory.search(q, limit: 10);
    final engine = services.engine;
    final out = <_PlaceHit>[];
    for (final h in hits) {
      final o = h.office;
      final same = await services.directory.officesForPin(o.pincode);
      const heads = {'SO', 'PO', 'HO'};
      final so = heads.contains(o.officeType) ? null : same.where((x) => heads.contains(x.officeType)).firstOrNull;
      out.add(_PlaceHit(o, so, engine.resolveOffice(o, category: category)));
    }
    if (!mounted || seq != _placeSeq || q != _query) return;
    setState(() => _places = out);
  }

  void _update(String digits) => _setText(digits.length > 6 ? digits.substring(0, 6) : digits);

  void _clear() {
    AppFeedback.tap(context.settings);
    _lastSpoken = '';
    _setText('');
    _focus.requestFocus();
  }

  /// Tapped office / PIN in the live list: show its line / bag box.
  Future<void> _showBox(ActiveScheme scheme, LiveMatch m) async {
    final l = AppLocalizations.of(context);
    final id = scheme.scheme.id;
    final isPin = m.rule.match.type == RuleType.exact;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(m.key, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              BagCard(bag: scheme.bagFor(m.rule), rule: m.rule, level: m.rule.match.type),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isPin)
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(c, 'open'),
                      icon: const Icon(Icons.search),
                      label: Text(l.openThisPin),
                    ),
                  if (id != null)
                    OutlinedButton.icon(
                      key: const ValueKey('box_edit'),
                      onPressed: () => Navigator.pop(c, 'edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l.editRule),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'open') setPin(m.key);
    if (action == 'edit' && id != null) {
      if (await editRuleFor(context, schemeId: id, rule: m.rule) && mounted) toast(context, l.savedSortingUpdated);
    }
  }

  /// "+ Add office" on a line: new office rule on that line / bag.
  Future<void> _addOffice(ActiveScheme scheme, Bag bag) async {
    final id = scheme.scheme.id;
    if (id == null) return;
    final l = AppLocalizations.of(context);
    final ok = await editRuleFor(context, schemeId: id, category: context.settings.category, bagCode: bag.code, type: RuleType.office);
    if (ok && mounted) toast(context, l.savedSortingUpdated);
  }

  void _toggleKeyboard() {
    setState(() => _letters = !_letters);
    // Re-open the keyboard with the new layout.
    _focus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
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
    final matches = scheme == null ? const <LiveMatch>[] : liveMatches(scheme.rules, _query, category: settings.category, limit: 400);
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.appTitle),
              if (scheme?.scheme.isSample ?? false) ...[const SizedBox(width: 8), const SampleChip()],
            ],
          ),
        ),
        scrolledUnderElevation: 0,
        actionsPadding: const EdgeInsets.only(right: 4),
        actions: [
          IconButton(tooltip: l.voiceInput, visualDensity: VisualDensity.compact, onPressed: _voice, icon: const Icon(Icons.mic_none)),
          IconButton(
            tooltip: l.scanAddress,
            visualDensity: VisualDensity.compact,
            onPressed: _scan,
            icon: const Icon(Icons.document_scanner_outlined),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: l.checkPlace,
            icon: Icon(_placeOpen ? Icons.location_off_outlined : Icons.fact_check_outlined),
            onPressed: () => setState(() {
              _placeOpen = !_placeOpen;
              settings.showMismatchField = _placeOpen;
            }),
          ),
          if (r != null && r.complete && r.valid)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: l.labelView,
              icon: const Icon(Icons.label_outline),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LabelViewScreen(result: r))),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Navy header: TD / Non-TD and the big search field.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
              decoration: BoxDecoration(
                gradient: headerGradient(context),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _ModeSwitch(
                    modes: services.categories,
                    selected: services.categories.contains(settings.category) ? settings.category : services.categories.first,
                    onChanged: (c) {
                      settings.category = c;
                      _lastSpoken = '';
                      _resolve();
                      if (_places.isNotEmpty) _searchPlaces();
                    },
                  ),
                  const SizedBox(height: 10),
                  _SearchField(
                    controller: _input,
                    focusNode: _focus,
                    letters: _letters,
                    error: r != null && r.complete && !r.valid,
                    onChanged: _onChanged,
                    onClear: _clear,
                    onToggleKeyboard: _toggleKeyboard,
                  ),
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
            if (_placeOpen && _place.text.trim().length >= 2 && _digits.length < 6)
              Padding(
                key: const ValueKey('place_needs_pin'),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(l.placeCheckNeedsPin, style: Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (scheme == null) ...[const NoSchemeBar(), const SizedBox(height: 10)],
                  // Main answer first: the big bag card.
                  if (r != null && r.digits == _digits && r.complete) ...[
                    if (_placeOpen && _place.text.trim().length >= 2) ...[
                      MismatchView(pin: _digits, place: _place.text, onPickPin: (o) => setPin(o.pin)),
                      const SizedBox(height: 10),
                    ],
                    SortResultView(result: r),
                  ] else ...[
                    if (_places.isNotEmpty && _digits.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                        child: Text(
                          l.postOfficesFound,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      for (final p in _places) _PlaceCard(hit: p, onTap: () => setPin(p.office.pin)),
                      const SizedBox(height: 8),
                    ],
                    if (scheme != null && _query.isNotEmpty && (matches.isNotEmpty || _places.isEmpty))
                      _LiveList(
                        matches: matches,
                        scheme: scheme,
                        query: _query,
                        onPick: (m) => _showBox(scheme, m),
                        onAdd: (bag) => _addOffice(scheme, bag),
                      ),
                    // Partial PIN without list entries: sorting district / likely bag.
                    if (r != null && r.digits == _digits && _digits.isNotEmpty && matches.isEmpty) SortResultView(result: r),
                  ],
                  if (_query.isEmpty && _recents.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(l.recentLookups, style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        TextButton(
                          onPressed: () async {
                            await services.user.clearRecents();
                            services.touchRecents();
                          },
                          child: Text(l.clear),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in _recents)
                          ActionChip(
                            label: Text('$p', style: const TextStyle(fontSize: 18)),
                            onPressed: () => setPin('$p'),
                          ),
                      ],
                    ),
                  ],
                  if (_query.isEmpty && _recents.isEmpty && scheme != null)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l.sortHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big PIN / office field using the phone keyboard.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.letters,
    required this.error,
    required this.onChanged,
    required this.onClear,
    required this.onToggleKeyboard,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool letters;
  final bool error;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onToggleKeyboard;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = Theme.of(context).colorScheme;
    // The digits are already large: don't let big system text push the
    // 6th digit out of view.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: TextField(
        key: const ValueKey('pin_field'),
        controller: controller,
        focusNode: focusNode,
        autofocus: true,
        keyboardType: letters ? TextInputType.text : TextInputType.number,
        textInputAction: TextInputAction.search,
        inputFormatters: letters ? null : [FilteringTextInputFormatter.allow(RegExp(r'[0-9०-९೦-೯ ]'))],
        style: TextStyle(
          fontSize: letters ? 26 : 36,
          fontWeight: FontWeight.w900,
          letterSpacing: letters ? 0 : 4,
          color: error ? c.error : c.primary,
        ),
        onChanged: onChanged,
        onTap: () {
          // Tap selects everything so the next PIN simply replaces it.
          if (controller.text.isNotEmpty) controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
        },
        decoration: InputDecoration(
          hintText: letters ? l.officeNameHint : l.pinHint,
          hintStyle: TextStyle(fontSize: 22, letterSpacing: 0, fontWeight: FontWeight.w600, color: c.onSurfaceVariant),
          contentPadding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: c.primary, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: c.primary, width: 3),
          ),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.text.isNotEmpty)
                IconButton(
                  key: const ValueKey('clear_field'),
                  tooltip: l.clear,
                  visualDensity: VisualDensity.compact,
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
              IconButton(
                key: const ValueKey('kb_toggle'),
                tooltip: l.switchKeyboard,
                visualDensity: VisualDensity.compact,
                onPressed: onToggleKeyboard,
                icon: Icon(letters ? Icons.dialpad : Icons.abc),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Printed-list style results, grouped by bag / line:
/// "KOZHIKODE · Kerala  [673] [674] [675] [676]".
class _LiveList extends StatelessWidget {
  const _LiveList({required this.matches, required this.scheme, required this.query, required this.onPick, required this.onAdd});

  final List<LiveMatch> matches;
  final ActiveScheme scheme;
  final String query;
  final ValueChanged<LiveMatch> onPick;
  final ValueChanged<Bag> onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(l.noMatchingRules, style: t.titleMedium?.copyWith(color: c.onSurfaceVariant)),
      );
    }
    final groups = <String, List<LiveMatch>>{};
    for (final m in matches) {
      (groups[m.rule.bagCode] ??= []).add(m);
    }
    final entries = groups.entries.toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in entries.indexed) ...[
            _LiveGroup(
              key: ValueKey('group_${e.key}'),
              bag: scheme.bagFor(e.value.first.rule),
              matches: e.value,
              highlight: i == 0 && e.value.first.covers,
              onPick: onPick,
              onAdd: () => onAdd(scheme.bagFor(e.value.first.rule)),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _LiveGroup extends StatefulWidget {
  const _LiveGroup({
    super.key,
    required this.bag,
    required this.matches,
    required this.highlight,
    required this.onPick,
    required this.onAdd,
  });

  final Bag bag;
  final List<LiveMatch> matches;
  final bool highlight;
  final ValueChanged<LiveMatch> onPick;
  final VoidCallback onAdd;

  @override
  State<_LiveGroup> createState() => _LiveGroupState();
}

class _LiveGroupState extends State<_LiveGroup> {
  static const _collapsed = 24;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bag = widget.bag;
    final matches = widget.matches;
    final highlight = widget.highlight;
    final onPick = widget.onPick;
    final shown = _all ? matches : matches.take(_collapsed).toList();
    final hidden = matches.length - shown.length;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final colour = bagColour(context, bag);
    final bg = highlight ? colour : c.surfaceContainerLowest;
    final fg = highlight ? onColour(colour) : c.onSurface;
    final sections = {
      for (final m in matches)
        if (m.rule.section.isNotEmpty) m.rule.section,
    };
    final sub = [if (bag.name.isNotEmpty && bag.name != bag.code) bag.name, if (sections.length == 1) '#${sections.first}'].join(' · ');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: highlight ? null : Border.all(color: c.outlineVariant),
        boxShadow: highlight ? [BoxShadow(color: colour.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 8, color: highlight ? Colors.white.withValues(alpha: 0.35) : colour),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bag.code,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: fg),
                    ),
                    if (sub.isNotEmpty)
                      Text(
                        sub,
                        style: t.titleSmall?.copyWith(color: fg.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in shown) _KeyChip(match: m, colour: colour, onDark: highlight, onTap: () => onPick(m)),
                        if (hidden > 0)
                          ActionChip(
                            key: const ValueKey('show_all'),
                            avatar: const Icon(Icons.expand_more),
                            label: Text(l.showAllN(matches.length), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            onPressed: () => setState(() => _all = true),
                          ),
                        ActionChip(
                          key: const ValueKey('add_office'),
                          avatar: const Icon(Icons.add),
                          label: Text(l.addOffice, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          onPressed: widget.onAdd,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({required this.match, required this.colour, required this.onDark, required this.onTap});

  final LiveMatch match;
  final Color colour;
  final bool onDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final bg = onDark ? Colors.white.withValues(alpha: 0.22) : Color.alphaBlend(colour.withValues(alpha: 0.14), c.surfaceContainerLowest);
    final fg = onDark ? onColour(colour) : c.onSurface;
    final r = match.rule;
    final label = r.match.type == RuleType.exact && r.remarks.isNotEmpty ? '${match.key}  ${r.remarks}' : match.key;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
    );
  }
}

class _PlaceHit {
  const _PlaceHit(this.office, this.accountOffice, this.result);

  final Office office;

  /// The SO / HO a branch office belongs to (same PIN), if any.
  final Office? accountOffice;
  final SortResult result;
}

/// One post office found by name: "Sulkeri BO · 574109 · SO Naravi" with
/// its line / bag and position on the right.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.hit, required this.onTap});

  final _PlaceHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final o = hit.office;
    final r = hit.result;
    final bag = r.bag;
    final colour = bag == null ? c.outlineVariant : bagColour(context, bag);
    final section = r.bagRule?.section ?? '';
    final so = hit.accountOffice;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: colour),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${o.officeName} ${o.officeType}', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      Text(
                        [o.pin, if (so != null) '${l.soLabel} ${so.officeName}', o.district].join(' · '),
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: c.onSurfaceVariant),
                      ),
                      if (bag == null && r.otherBag != null)
                        Text(
                          l.otherModeHint(categoryLabel(l, r.otherCategory!), r.otherBag!.label),
                          style: t.bodyMedium?.copyWith(color: warningColor(context), fontWeight: FontWeight.w700),
                        )
                      else if (bag == null)
                        Text(l.noLineInScheme, style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
              if (bag != null)
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Color.alphaBlend(colour.withValues(alpha: 0.14), c.surfaceContainerLowest),
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bag.code,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: c.onSurface),
                      ),
                      if (section.isNotEmpty) Text('${l.section} $section', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big segmented TD / Non-TD switch; scrolls when custom categories exist.
class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.modes, required this.selected, required this.onChanged});

  final List<String> modes;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget seg(String m) {
      final on = m == selected;
      return Semantics(
        selected: on,
        button: true,
        label: categoryLabel(l, m),
        child: Material(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: ValueKey('mode_$m'),
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChanged(m),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: Text(
                categoryLabel(l, m),
                maxLines: 1,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: on ? kNavy : Colors.white.withValues(alpha: 0.8)),
              ),
            ),
          ),
        ),
      );
    }

    final box = BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14));
    if (modes.length <= 3) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: box,
        child: Row(children: [for (final m in modes) Expanded(child: seg(m))]),
      );
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: box,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [for (final m in modes) seg(m)]),
      ),
    );
  }
}

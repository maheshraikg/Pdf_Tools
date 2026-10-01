/// All lines / bags of the active scheme. Pick one to see the whole line:
/// every office in position order with its PIN.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/live_search.dart';
import '../../data/models/office.dart';
import '../../data/models/scheme.dart';
import '../../data/resolver.dart';
import '../../data/scheme_repo.dart';
import '../home_shell.dart';
import '../lookup/line_table.dart';
import '../lookup/sort_result_view.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final services = context.services;
    final settings = context.settings;
    final scheme = services.active;
    final modes = services.categories;
    final mode = modes.contains(settings.category) ? settings.category : modes.first;

    final lines = <String, List<BagRule>>{};
    for (final r in scheme?.rules ?? const <BagRule>[]) {
      if (r.category != null && r.category != mode) continue;
      (lines[r.bagCode] ??= []).add(r);
    }
    final order = scheme?.bagOrder ?? const <String>[];
    final codes = lines.keys.where((k) => _filter.isEmpty || k.toLowerCase().contains(_filter.toLowerCase())).toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 1 << 20 : ia).compareTo(ib < 0 ? 1 << 20 : ib);
      });

    return Scaffold(
      appBar: AppBar(title: Text(l.allLines), scrolledUnderElevation: 0),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            decoration: BoxDecoration(
              gradient: headerGradient(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      selectedBackgroundColor: Colors.white,
                      selectedForegroundColor: kNavy,
                      textStyle: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w900),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    showSelectedIcon: false,
                    segments: [for (final m in modes) ButtonSegment(value: m, label: Text(categoryLabel(l, m)))],
                    selected: {mode},
                    onSelectionChanged: (v) => setState(() => settings.category = v.first),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('lines_filter'),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                  decoration: InputDecoration(
                    hintText: l.filterLines,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: c.surfaceContainerLowest,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: scheme == null
                ? const Padding(padding: EdgeInsets.all(12), child: NoSchemeBar())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: codes.length,
                    itemBuilder: (_, i) {
                      final code = codes[i];
                      final bag = scheme.bags[code] ?? Bag(code: code);
                      final stops = lineRoster(scheme.rules, code, category: mode);
                      final colour = bagColour(context, bag);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LineDetailScreen(code: code, category: mode),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 8, color: colour),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(code, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                        Text(
                                          [if (bag.name.isNotEmpty && bag.name != code) bag.name, l.stopsN(stops.length)].join(' · '),
                                          style: t.titleSmall?.copyWith(color: c.onSurfaceVariant, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One line: every office in position order with its PIN. Prefix / range
/// rules (Non-TD "573xxx") list the real PINs and offices they cover.
class LineDetailScreen extends StatelessWidget {
  const LineDetailScreen({super.key, required this.code, required this.category});

  final String code;
  final String category;

  static bool _isArea(LineStop s) =>
      s.officeRule == null && s.pinRules.isNotEmpty && s.pinRules.every((r) => r.match.type == RuleType.prefix || r.match.type == RuleType.range);

  void _openPin(BuildContext context, String pin) {
    final shell = HomeShell.of(context);
    Navigator.popUntil(context, (r) => r.isFirst);
    shell?.openSort(pin);
  }

  List<Widget> _sections(BuildContext context, List<LineStop> stops, Color colour, ActiveScheme? scheme) {
    final out = <Widget>[];
    var run = <LineStop>[];
    void flush() {
      if (run.isEmpty) return;
      out.add(LineTable(stops: run, colour: colour, onDark: false, matched: const {}, onPin: (p) => _openPin(context, p)));
      run = [];
    }

    for (final s in stops) {
      if (!_isArea(s)) {
        run.add(s);
        continue;
      }
      flush();
      for (final r in s.pinRules) {
        out.add(_AreaStop(rule: r, code: code, category: category, colour: colour, scheme: scheme, onPin: (p) => _openPin(context, p)));
      }
    }
    flush();
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = context.services.active;
    final bag = scheme?.bags[code] ?? Bag(code: code);
    final stops = scheme == null ? const <LineStop>[] : lineRoster(scheme.rules, code, category: category);
    final colour = bagColour(context, bag);
    return Scaffold(
      appBar: AppBar(title: Text(code)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colour, Color.lerp(colour, Colors.black, 0.28)!]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: t.headlineMedium?.copyWith(color: onColour(colour), fontWeight: FontWeight.w900),
                ),
                Text(
                  [if (bag.name.isNotEmpty && bag.name != code) bag.name, categoryLabel(l, category), l.stopsN(stops.length)].join(' · '),
                  style: t.titleMedium?.copyWith(color: onColour(colour), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._sections(context, stops, colour, scheme),
        ],
      ),
    );
  }
}

/// A prefix / range rule ("573xxx"): its districts, then every PIN it sends
/// to this line with the office names. PINs that a more exact rule sends to
/// another line are left out.
class _AreaStop extends StatefulWidget {
  const _AreaStop({required this.rule, required this.code, required this.category, required this.colour, required this.scheme, required this.onPin});

  final BagRule rule;
  final String code;
  final String category;
  final Color colour;
  final ActiveScheme? scheme;
  final ValueChanged<String> onPin;

  @override
  State<_AreaStop> createState() => _AreaStopState();
}

class _AreaPin {
  _AreaPin(this.pin, this.head);

  final String pin;
  final Office head;
  int others = 0;
}

class _AreaStopState extends State<_AreaStop> {
  List<_AreaPin>? _pins;
  List<String> _districts = [];
  bool _open = false;

  (int, int)? get _range {
    final m = widget.rule.match;
    if (m.type == RuleType.range) return (m.pinFrom!, m.pinTo!);
    final p = (m.prefix ?? '').replaceAll(RegExp(r'\D'), '');
    if (p.isEmpty || p.length > 6) return null;
    return (int.parse(p.padRight(6, '0')), int.parse(p.padRight(6, '9')));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pins == null) _load();
  }

  Future<void> _load() async {
    final range = _range;
    if (range == null) {
      setState(() => _pins = []);
      return;
    }
    final offices = await context.services.directory.officesInRange(range.$1, range.$2);
    final resolver = widget.scheme?.bagResolver;
    final byPin = <int, _AreaPin>{};
    final districts = <String, int>{};
    for (final o in offices) {
      final have = byPin[o.pincode];
      if (have != null) {
        have.others++;
        continue;
      }
      // Keep only PINs this line really gets.
      final res = resolver?.resolve(ResolveQuery(pin: o.pincode, category: widget.category));
      if (res != null && res.rule.bagCode != widget.code) continue;
      byPin[o.pincode] = _AreaPin(o.pin, o);
      if (o.district.isNotEmpty) districts[o.district] = (districts[o.district] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _pins = byPin.values.toList();
      _districts = (districts.keys.toList()..sort((a, b) => districts[b]!.compareTo(districts[a]!)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final pins = _pins;
    final label = widget.rule.match.type == RuleType.range
        ? '${widget.rule.match.pinFrom}–${widget.rule.match.pinTo}'
        : (widget.rule.match.prefix ?? '').padRight(6, 'x');
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: ValueKey('area_$label'),
            onTap: pins == null || pins.isEmpty ? null : () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        if (pins == null)
                          const Padding(padding: EdgeInsets.only(top: 4), child: LinearProgressIndicator())
                        else ...[
                          if (_districts.isNotEmpty)
                            Text(_districts.take(4).join(' · '), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(l.areaPinsN(pins.length), style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  if (pins != null && pins.isNotEmpty) Icon(_open ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_open && pins != null)
            for (final p in pins)
              InkWell(
                onTap: () => widget.onPin(p.pin),
                child: Container(
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: c.outlineVariant.withValues(alpha: 0.5)))),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(
                          p.pin,
                          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          [
                            '${p.head.officeName} ${p.head.officeType}',
                            if (p.others > 0) l.moreOfficesN(p.others),
                          ].join(' · '),
                          style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(p.head.district, style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

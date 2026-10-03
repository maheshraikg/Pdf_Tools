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
import '../schemes/scheme_editor.dart';
import '../lookup/sort_result_view.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  String _filter = '';

  /// Name + colour, then straight to the new line to add its offices / PINs.
  Future<void> _newLine(BuildContext context, ActiveScheme scheme, String mode) async {
    final l = AppLocalizations.of(context);
    final services = context.services;
    final bag = await showDialog<Bag>(context: context, builder: (_) => BagDialog(order: scheme.bags.length));
    if (bag == null || !context.mounted) return;
    if (scheme.bags.containsKey(bag.code)) {
      toast(context, l.lineExists(bag.code));
      return;
    }
    await services.schemes.upsertBag(scheme.scheme.id!, bag);
    await services.reloadActive();
    if (!context.mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => LineDetailScreen(code: bag.code, category: mode)));
  }

  /// Deletes the line's rules in this mode; the line itself goes when it has
  /// no rules left in any mode.
  Future<void> _removeLine(BuildContext context, ActiveScheme scheme, String code, String mode, List<BagRule> rules) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.removeLineQ(code)),
        content: Text(l.removeLineBody(rules.length, categoryLabel(l, mode))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(key: const ValueKey('confirm_remove_line'), onPressed: () => Navigator.pop(d, true), child: Text(l.removeLine)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final services = context.services;
    final id = scheme.scheme.id!;
    for (final r in rules) {
      if (r.id != null) await services.schemes.deleteRule(r.id!);
    }
    final left = scheme.rules.where((r) => r.bagCode == code && !rules.contains(r));
    if (left.isEmpty) await services.schemes.deleteBag(id, code);
    await services.reloadActive();
    if (context.mounted) toast(context, l.lineRemoved(code));
  }

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
    // New lines with nothing on them yet (in any mode) show too.
    final used = {for (final r in scheme?.rules ?? const <BagRule>[]) r.bagCode};
    for (final b in scheme?.bags.keys ?? const <String>[]) {
      if (!used.contains(b)) lines[b] ??= [];
    }
    final order = scheme?.bagOrder ?? const <String>[];
    final codes = lines.keys.where((k) => _filter.isEmpty || k.toLowerCase().contains(_filter.toLowerCase())).toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 1 << 20 : ia).compareTo(ib < 0 ? 1 << 20 : ib);
      });

    return Scaffold(
      appBar: AppBar(title: Text(l.allLines), scrolledUnderElevation: 0),
      floatingActionButton: scheme == null
          ? null
          : FloatingActionButton.extended(
              key: const ValueKey('new_line'),
              onPressed: () => _newLine(context, scheme, mode),
              icon: const Icon(Icons.add),
              label: Text(l.newLine),
            ),
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
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
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
                                IconButton(
                                  key: ValueKey('remove_line_$code'),
                                  tooltip: l.removeLine,
                                  icon: Icon(Icons.delete_outline, color: c.error),
                                  onPressed: () => _removeLine(context, scheme, code, mode, lines[code]!),
                                ),
                                const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.chevron_right)),
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

  int? _schemeId(BuildContext context) => context.services.active?.scheme.id;

  /// Deletes the rules that put [name] on this line, after a confirmation.
  Future<void> _remove(BuildContext context, String name, List<BagRule> rules) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.lineRemoveQ(name, code)),
        content: Text(l.lineRemoveBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
          FilledButton(key: const ValueKey('confirm_remove'), onPressed: () => Navigator.pop(d, true), child: Text(l.lineRemove)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final services = context.services;
    for (final r in rules) {
      if (r.id != null) await services.schemes.deleteRule(r.id!);
    }
    await services.reloadActive();
    if (context.mounted) toast(context, l.lineRemoved(name));
  }

  /// Edits the office / PIN rule of a row (asks which one when a row has
  /// several, e.g. the office and its PIN).
  Future<void> _editStop(BuildContext context, List<BagRule> rules) async {
    final id = _schemeId(context);
    if (id == null || rules.isEmpty) return;
    var rule = rules.first;
    if (rules.length > 1) {
      final l = AppLocalizations.of(context);
      final picked = await showModalBottomSheet<BagRule>(
        context: context,
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(l.chooseRuleToEdit, style: const TextStyle(fontWeight: FontWeight.w800))),
              for (final r in rules)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(r.describe),
                  subtitle: r.remarks.isEmpty ? null : Text(r.remarks),
                  onTap: () => Navigator.pop(sheet, r),
                ),
            ],
          ),
        ),
      );
      if (picked == null || !context.mounted) return;
      rule = picked;
    }
    final changed = await editRuleFor(context, schemeId: id, rule: rule);
    if (changed && context.mounted) await context.services.reloadActive();
  }

  /// Line name / extra name / colour. A new name moves all its rules.
  Future<void> _editLine(BuildContext context, ActiveScheme scheme, Bag bag) async {
    final edited = await showDialog<Bag>(context: context, builder: (_) => BagDialog(bag: bag, order: bag.order));
    if (edited == null || !context.mounted) return;
    final l = AppLocalizations.of(context);
    final services = context.services;
    final id = scheme.scheme.id!;
    if (edited.code != bag.code && scheme.bags.containsKey(edited.code)) {
      toast(context, l.lineExists(edited.code));
      return;
    }
    if (edited.code == bag.code) await services.schemes.upsertBag(id, edited);
    await services.schemes.moveRules(id, bag.code, edited);
    await services.reloadActive();
    if (!context.mounted || edited.code == bag.code) return;
    await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LineDetailScreen(code: edited.code, category: category)));
  }

  /// One PIN of a prefix line: an exact rule sending it to another line.
  Future<void> _move(BuildContext context, String pin) async {
    final id = _schemeId(context);
    if (id == null) return;
    final changed = await editRuleFor(context, schemeId: id, pin: pin, category: category, type: RuleType.exact);
    if (changed && context.mounted) await context.services.reloadActive();
  }

  Future<void> _add(BuildContext context, RuleType type) async {
    final id = _schemeId(context);
    if (id == null) return;
    final changed = await editRuleFor(context, schemeId: id, category: category, bagCode: code, type: type);
    if (changed && context.mounted) await context.services.reloadActive();
  }

  List<Widget> _sections(BuildContext context, List<LineStop> stops, Color colour, ActiveScheme? scheme) {
    final out = <Widget>[];
    var run = <LineStop>[];
    void flush() {
      if (run.isEmpty) return;
      out.add(LineTable(
        stops: run,
        colour: colour,
        onDark: false,
        matched: const {},
        onPin: (p) => _openPin(context, p),
        onRemove: scheme == null ? null : (s) => _remove(context, s.name, [?s.officeRule, ...s.pinRules]),
        removeTooltip: AppLocalizations.of(context).lineRemove,
        onEdit: scheme == null ? null : (s) => _editStop(context, [?s.officeRule, ...s.pinRules]),
        editTooltip: AppLocalizations.of(context).edit,
      ));
      run = [];
    }

    for (final s in stops) {
      if (!_isArea(s)) {
        run.add(s);
        continue;
      }
      flush();
      for (final r in s.pinRules) {
        out.add(_AreaStop(
          // A new state when the scheme changes, so the PIN list reloads.
          key: ValueKey('${r.id}-${identityHashCode(scheme)}'),
          rule: r,
          code: code,
          category: category,
          colour: colour,
          scheme: scheme,
          onPin: (p) => _openPin(context, p),
          onRemove: scheme == null ? null : () => _remove(context, (r.match.prefix ?? r.describe).padRight(6, 'x'), [r]),
          onMovePin: scheme == null ? null : (p) => _move(context, p),
          onEdit: scheme == null ? null : () => _editStop(context, [r]),
        ));
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
      appBar: AppBar(
        title: Text(code),
        actions: [
          if (scheme != null)
            IconButton(
              key: const ValueKey('edit_line'),
              tooltip: l.editLine,
              icon: const Icon(Icons.edit),
              onPressed: () => _editLine(context, scheme, bag),
            ),
        ],
      ),
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
          const SizedBox(height: 10),
          if (scheme != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    key: const ValueKey('line_add_office'),
                    onPressed: () => _add(context, RuleType.office),
                    icon: const Icon(Icons.add_business),
                    label: Text(l.addOffice),
                  ),
                  FilledButton.tonalIcon(
                    key: const ValueKey('line_add_pin'),
                    onPressed: () => _add(context, RuleType.exact),
                    icon: const Icon(Icons.pin_outlined),
                    label: Text(l.lineAddPin),
                  ),
                ],
              ),
            ),
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
  const _AreaStop({
    super.key,
    required this.rule,
    required this.code,
    required this.category,
    required this.colour,
    required this.scheme,
    required this.onPin,
    this.onRemove,
    this.onMovePin,
    this.onEdit,
  });

  final BagRule rule;
  final String code;
  final String category;
  final Color colour;
  final ActiveScheme? scheme;
  final ValueChanged<String> onPin;
  final VoidCallback? onRemove;
  final ValueChanged<String>? onMovePin;
  final VoidCallback? onEdit;

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
                  if (widget.onEdit != null)
                    IconButton(
                      key: ValueKey('edit_$label'),
                      tooltip: l.edit,
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: widget.onEdit,
                    ),
                  if (widget.onRemove != null)
                    IconButton(
                      key: ValueKey('remove_$label'),
                      tooltip: l.lineRemove,
                      icon: Icon(Icons.remove_circle_outline, color: c.error),
                      onPressed: widget.onRemove,
                    ),
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
                      if (widget.onMovePin != null)
                        IconButton(
                          key: ValueKey('move_${p.pin}'),
                          tooltip: l.lineMovePin,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.remove_circle_outline, color: c.error),
                          onPressed: () => widget.onMovePin!(p.pin),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

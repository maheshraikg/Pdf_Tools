/// Create / edit a scheme in the app: rules, bags (with colours), air codes
/// and DMSL versions.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/fuzzy.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/pin_utils.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/import/scheme_import.dart';
import '../../data/models/scheme.dart';
import 'dmsl_diff_screen.dart';
import 'import_wizard.dart';

class SchemeEditor extends StatefulWidget {
  const SchemeEditor({super.key, required this.schemeId});

  final int schemeId;

  @override
  State<SchemeEditor> createState() => _SchemeEditorState();
}

class _SchemeEditorState extends State<SchemeEditor> {
  Scheme? _scheme;
  List<BagRule> _rules = [];
  List<Bag> _bags = [];
  List<AirCodeRule> _air = [];
  List<DmslVersion> _versions = [];
  String _filter = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheme == null) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final r = context.services.schemes;
    final s = await r.scheme(widget.schemeId);
    final rules = await r.rules(widget.schemeId);
    final bags = await r.bags(widget.schemeId);
    final air = await r.airCodes(widget.schemeId);
    final versions = await r.dmslVersions(widget.schemeId);
    if (!mounted) return;
    setState(() {
      _scheme = s;
      _rules = rules;
      _bags = bags;
      _air = air;
      _versions = versions;
    });
  }

  Future<void> _changed() async {
    if (!mounted) return;
    await _load();
    if (mounted) await context.services.reloadActive();
  }

  Future<void> _editRule([BagRule? rule]) async {
    final r = await showDialog<BagRule>(
      context: context,
      builder: (_) => _RuleDialog(rule: rule, bags: _bags, categories: context.services.categories),
    );
    if (r == null || !mounted) return;
    final repo = context.services.schemes;
    if (!_bags.any((b) => b.code == r.bagCode)) {
      await repo.upsertBag(widget.schemeId, Bag(
        code: r.bagCode,
        name: r.bagName,
        colour: colourToHex(kBagPalette[_bags.length % kBagPalette.length]),
        order: _bags.length,
      ));
    }
    await repo.upsertRule(widget.schemeId, r);
    await _changed();
  }

  Future<void> _editBag([Bag? bag]) async {
    final b = await showDialog<Bag>(context: context, builder: (_) => _BagDialog(bag: bag, order: _bags.length));
    if (b == null || !mounted) return;
    await context.services.schemes.upsertBag(widget.schemeId, b);
    await _changed();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _scheme;
    if (s == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final bagMap = {for (final b in _bags) b.code: b};
    final f = _filter.toLowerCase();
    final rules = f.isEmpty
        ? _rules
        : _rules.where((r) => '${r.describe} ${r.bagCode} ${r.bagName} ${r.remarks}'.toLowerCase().contains(f)).toList();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.name),
          actions: [
            IconButton(
              tooltip: l.rename,
              icon: const Icon(Icons.drive_file_rename_outline),
              onPressed: () async {
                final c = TextEditingController(text: s.name);
                final o = TextEditingController(text: s.office);
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: Text(l.rename),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(controller: c, decoration: InputDecoration(labelText: l.schemeName)),
                      TextField(controller: o, decoration: InputDecoration(labelText: l.officeName)),
                    ]),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.cancel)),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(l.save)),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.services.schemes.updateScheme(s.id!, name: c.text.trim(), office: o.text.trim());
                  await _changed();
                }
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
            indicatorColor: kAccentAmber,
            tabs: [
              Tab(text: '${l.rules} (${_rules.length})'),
              Tab(text: '${l.bags} (${_bags.length})'),
              Tab(text: '${l.airCodes} (${_air.length})'),
              Tab(text: 'DMSL (${_versions.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Rules
            Column(
              children: [
                if (s.isSample) const Padding(padding: EdgeInsets.only(top: 8), child: SampleChip()),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.filterRules, isDense: true),
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: rules.length,
                    itemBuilder: (_, i) {
                      final r = rules[i];
                      final bag = bagMap[r.bagCode];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: bagColour(context, bag), child: Text(ruleTypeLabel(l, r.match.type)[0], style: TextStyle(color: onColour(bagColour(context, bag))))),
                        title: Text('${r.describe}  →  ${r.bagCode}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text([
                          ruleTypeLabel(l, r.match.type),
                          if ((bag?.name ?? r.bagName).isNotEmpty) bag?.name ?? r.bagName,
                          if (r.section.isNotEmpty) '${l.section} ${r.section}',
                          if (r.category != null) categoryLabel(l, r.category!),
                          if (r.connectivity != null) connectivityLabel(l, r.connectivity!),
                          if (r.remarks.isNotEmpty) r.remarks,
                        ].join(' · ')),
                        onTap: () => _editRule(r),
                        trailing: IconButton(
                          tooltip: l.delete,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await context.services.schemes.deleteRule(r.id!);
                            await _changed();
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Bags
            ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final b in _bags)
                  ListTile(
                    leading: CircleAvatar(backgroundColor: bagColour(context, b)),
                    title: Text(b.code, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${b.name}  ·  ${l.rulesCount(_rules.where((r) => r.bagCode == b.code).length)}'),
                    onTap: () => _editBag(b),
                    trailing: IconButton(
                      tooltip: l.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirm(context, l.deleteBagConfirm(b.code))) {
                          if (!context.mounted) return;
                          await context.services.schemes.deleteBag(widget.schemeId, b.code);
                          await _changed();
                        }
                      },
                    ),
                  ),
              ],
            ),
            // Air codes
            ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.file_open),
                    label: Text(l.importAirCodes),
                    onPressed: () async {
                      final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ImportWizard(kind: ImportKind.airCodes, schemeId: widget.schemeId)));
                      if (ok == true) await _changed();
                    },
                  ),
                ),
                if (_air.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text(l.noAirCodes)),
                for (final a in _air)
                  ListTile(
                    leading: Text(a.airCode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                    title: Text('${ruleTypeLabel(l, a.match.type)}: ${a.describe}'),
                    subtitle: Text([a.stationName, if (a.viaHub.isNotEmpty) '${l.via} ${a.viaHub}', a.remarks].where((x) => x.isNotEmpty).join(' · ')),
                  ),
              ],
            ),
            // DMSL
            ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.file_open),
                    label: Text(l.importDmsl),
                    onPressed: () async {
                      await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ImportWizard(kind: ImportKind.dmsl, schemeId: widget.schemeId)));
                      await _changed();
                    },
                  ),
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(l.dmslHelp, style: Theme.of(context).textTheme.bodySmall)),
                for (var i = 0; i < _versions.length; i++)
                  ListTile(
                    leading: Icon(_versions[i].active ? Icons.radio_button_checked : Icons.radio_button_off, color: _versions[i].active ? Theme.of(context).colorScheme.primary : null),
                    title: Text(_versions[i].versionName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text([
                      if (_versions[i].validFrom != null) l.validFromDate(_versions[i].validFrom!.toIso8601String().substring(0, 10)),
                      if (_versions[i].active) l.active,
                    ].join(' · ')),
                    onTap: () async {
                      await context.services.schemes.setActiveDmsl(widget.schemeId, _versions[i].id!);
                      await _changed();
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'diff' && i + 1 < _versions.length) {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => DmslDiffScreen(
                            schemeId: widget.schemeId,
                            oldVersionId: _versions[i + 1].id!,
                            newVersionId: _versions[i].id!,
                          )));
                        } else if (v == 'delete') {
                          await context.services.schemes.deleteDmslVersion(_versions[i].id!);
                          await _changed();
                        }
                      },
                      itemBuilder: (_) => [
                        if (i + 1 < _versions.length) PopupMenuItem(value: 'diff', child: Text(l.compareWithPrevious)),
                        PopupMenuItem(value: 'delete', child: Text(l.delete)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (c) => FloatingActionButton.extended(
            onPressed: () {
              final tab = DefaultTabController.of(c).index;
              if (tab == 1) {
                _editBag();
              } else {
                _editRule();
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l.add),
          ),
        ),
      ),
    );
  }
}

class _RuleDialog extends StatefulWidget {
  const _RuleDialog({this.rule, required this.bags, required this.categories});

  final BagRule? rule;
  final List<Bag> bags;
  final List<String> categories;

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late RuleType _type = widget.rule?.match.type ?? RuleType.exact;
  late final _a = TextEditingController(text: _initialA());
  late final _b = TextEditingController(text: widget.rule?.match.pinTo?.toString() ?? '');
  late final _bag = TextEditingController(text: widget.rule?.bagCode ?? '');
  late final _bagName = TextEditingController(text: widget.rule?.bagName ?? '');
  late final _section = TextEditingController(text: widget.rule?.section ?? '');
  late final _remarks = TextEditingController(text: widget.rule?.remarks ?? '');
  late String? _category = widget.rule?.category;
  late Connectivity? _conn = widget.rule?.connectivity;
  String? _error;

  String _initialA() {
    final r = widget.rule;
    if (r == null) return '';
    final m = r.match;
    return switch (m.type) {
      RuleType.exact => '${m.pin}',
      RuleType.range => '${m.pinFrom}',
      RuleType.prefix => m.prefix ?? '',
      RuleType.office => r.officeName ?? m.officeNorm ?? '',
      RuleType.district => r.district ?? m.districtNorm ?? '',
      RuleType.state => r.state ?? m.stateNorm ?? '',
      RuleType.fallback => '',
    };
  }

  void _submit() {
    final l = AppLocalizations.of(context);
    final a = PinUtils.normalizeDigits(_a.text.trim());
    MatchSpec? m;
    String? office, district, state;
    switch (_type) {
      case RuleType.exact:
        if (PinUtils.isValid(a)) m = MatchSpec.exact(int.parse(a));
      case RuleType.range:
        final b = PinUtils.normalizeDigits(_b.text.trim());
        if (PinUtils.isValid(a) && PinUtils.isValid(b) && int.parse(a) <= int.parse(b)) m = MatchSpec.range(int.parse(a), int.parse(b));
      case RuleType.prefix:
        if (RegExp(r'^[1-9]\d{0,4}$').hasMatch(a)) m = MatchSpec.prefix(a);
      case RuleType.office:
        if (a.isNotEmpty) m = MatchSpec(type: RuleType.office, officeNorm: normalizePlace(a));
        office = a;
      case RuleType.district:
        if (a.isNotEmpty) m = MatchSpec(type: RuleType.district, districtNorm: normalizePlace(a));
        district = a;
      case RuleType.state:
        if (a.isNotEmpty) m = MatchSpec(type: RuleType.state, stateNorm: normalizePlace(a));
        state = a;
      case RuleType.fallback:
        m = const MatchSpec.fallback();
    }
    if (m == null) {
      setState(() => _error = l.invalidRuleKey);
      return;
    }
    if (_bag.text.trim().isEmpty) {
      setState(() => _error = l.issueNoBag);
      return;
    }
    Navigator.pop(
      context,
      BagRule(
        id: widget.rule?.id,
        match: m,
        officeName: office,
        district: district,
        state: state,
        bagCode: _bag.text.trim(),
        bagName: _bagName.text.trim(),
        section: _section.text.trim(),
        remarks: _remarks.text.trim(),
        category: _category,
        connectivity: _conn,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final numeric = _type == RuleType.exact || _type == RuleType.range || _type == RuleType.prefix;
    return AlertDialog(
      title: Text(widget.rule == null ? l.addRule : l.editRule),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<RuleType>(
              isExpanded: true,
              initialValue: _type,
              decoration: InputDecoration(labelText: l.fType),
              items: [for (final t in RuleType.values) DropdownMenuItem(value: t, child: Text(ruleTypeLabel(l, t)))],
              onChanged: (t) => setState(() => _type = t ?? RuleType.exact),
            ),
            if (_type != RuleType.fallback)
              TextField(
                controller: _a,
                keyboardType: numeric ? TextInputType.number : TextInputType.text,
                decoration: InputDecoration(labelText: switch (_type) {
                  RuleType.exact => l.fPin,
                  RuleType.range => l.fPinFrom,
                  RuleType.prefix => l.fPrefix,
                  RuleType.office => l.fOffice,
                  RuleType.district => l.fDistrict,
                  _ => l.fState,
                }),
              ),
            if (_type == RuleType.range)
              TextField(controller: _b, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l.fPinTo)),
            TextField(
              controller: _bag,
              decoration: InputDecoration(
                labelText: l.fBagCode,
                suffixIcon: widget.bags.isEmpty
                    ? null
                    : PopupMenuButton<Bag>(
                        tooltip: l.bags,
                        icon: const Icon(Icons.arrow_drop_down),
                        onSelected: (b) => setState(() {
                          _bag.text = b.code;
                          if (_bagName.text.isEmpty) _bagName.text = b.name;
                        }),
                        itemBuilder: (_) => [for (final b in widget.bags) PopupMenuItem(value: b, child: Text(b.label))],
                      ),
              ),
            ),
            TextField(controller: _bagName, decoration: InputDecoration(labelText: l.fBagName)),
            TextField(controller: _section, decoration: InputDecoration(labelText: l.fSection)),
            TextField(controller: _remarks, decoration: InputDecoration(labelText: l.fRemarks)),
            DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: widget.categories.contains(_category) ? _category : null,
              decoration: InputDecoration(labelText: l.fCategory),
              items: [
                DropdownMenuItem(value: null, child: Text(l.allCategories)),
                for (final c in widget.categories) DropdownMenuItem(value: c, child: Text(categoryLabel(l, c))),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            DropdownButtonFormField<Connectivity?>(
              isExpanded: true,
              initialValue: _conn,
              decoration: InputDecoration(labelText: l.fConnectivity),
              items: [
                DropdownMenuItem(value: null, child: Text(l.notSet)),
                for (final c in Connectivity.values) DropdownMenuItem(value: c, child: Text(connectivityLabel(l, c))),
              ],
              onChanged: (v) => setState(() => _conn = v),
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}

class _BagDialog extends StatefulWidget {
  const _BagDialog({this.bag, required this.order});

  final Bag? bag;
  final int order;

  @override
  State<_BagDialog> createState() => _BagDialogState();
}

class _BagDialogState extends State<_BagDialog> {
  late final _code = TextEditingController(text: widget.bag?.code ?? '');
  late final _name = TextEditingController(text: widget.bag?.name ?? '');
  late String _colour = widget.bag?.colour ?? colourToHex(kBagPalette[widget.order % kBagPalette.length]);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.bag == null ? l.addBag : l.editBag),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _code, enabled: widget.bag == null, decoration: InputDecoration(labelText: l.fBagCode)),
          TextField(controller: _name, decoration: InputDecoration(labelText: l.fBagName)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in kBagPalette)
                Semantics(
                  label: colourToHex(c),
                  selected: colourToHex(c) == _colour,
                  child: InkWell(
                    onTap: () => setState(() => _colour = colourToHex(c)),
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 20,
                      child: colourToHex(c) == _colour ? Icon(Icons.check, color: onColour(c)) : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            if (_code.text.trim().isEmpty) return;
            Navigator.pop(context, Bag(code: _code.text.trim(), name: _name.text.trim(), colour: _colour, order: widget.bag?.order ?? widget.order));
          },
          child: Text(l.save),
        ),
      ],
    );
  }
}

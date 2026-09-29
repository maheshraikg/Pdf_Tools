/// File → preview (first 20 rows) → column mapping → validation report →
/// save. Used for sorting schemes, air code sheets and DMSL files.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/files.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/import/scheme_import.dart';
import '../../data/import/table_reader.dart';
import '../../data/models/scheme.dart';
import 'dmsl_diff_screen.dart';

class ImportWizard extends StatefulWidget {
  const ImportWizard({super.key, required this.kind, this.schemeId});

  final ImportKind kind;

  /// Scheme to attach air codes / DMSL to (required for those kinds).
  final int? schemeId;

  @override
  State<ImportWizard> createState() => _ImportWizardState();
}

class _ImportWizardState extends State<ImportWizard> {
  int _step = 0;
  PickedFile? _file;
  TableFile? _table;
  String? _sheet;
  int _headerRow = 0;
  Map<ImportField, int> _mapping = {};
  ImportResult<Matchable>? _result;
  String? _error;
  bool _saving = false;

  final _name = TextEditingController();
  final _office = TextEditingController();
  final _version = TextEditingController();
  DateTime? _validFrom;

  List<List<String>> get _rows => _table?.sheets[_sheet] ?? const [];
  List<String> get _header => _rows.isEmpty || _headerRow >= _rows.length ? const [] : _rows[_headerRow];

  String get _templateAsset => switch (widget.kind) {
    ImportKind.bagRules => 'assets/samples/template_scheme.xlsx',
    ImportKind.airCodes => 'assets/samples/template_air_codes.xlsx',
    ImportKind.dmsl => 'assets/samples/template_dmsl.xlsx',
  };

  String _title(AppLocalizations l) => switch (widget.kind) {
    ImportKind.bagRules => l.importScheme,
    ImportKind.airCodes => l.importAirCodes,
    ImportKind.dmsl => l.importDmsl,
  };

  @override
  void dispose() {
    _name.dispose();
    _office.dispose();
    _version.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _error = null);
    try {
      final f = await pickTableFile();
      if (f == null) return;
      final t = readTable(f.bytes, f.name);
      _file = f;
      _table = t;
      _sheet = t.defaultSheet;
      _detect();
      final base = f.name.replaceAll(RegExp(r'\.(xlsx|xlsm|csv)$', caseSensitive: false), '');
      if (_name.text.isEmpty) _name.text = base;
      if (_version.text.isEmpty) _version.text = _guessVersion() ?? base;
      _validFrom ??= _guessValidFrom();
      setState(() => _step = 1);
    } on Object catch (e) {
      setState(() => _error = '$e');
    }
  }

  void _detect() {
    _headerRow = detectHeaderRow(_rows, widget.kind);
    _mapping = autoDetectColumns(_header, widget.kind);
  }

  String get _titleText => _rows.take(_headerRow).expand((r) => r).join(' ');

  String? _guessVersion() => RegExp(r'version\s*[:\-]?\s*([A-Za-z0-9._\-/]+)', caseSensitive: false).firstMatch(_titleText)?[1];

  DateTime? _guessValidFrom() {
    final m = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(_titleText) ??
        RegExp(r'(\d{1,2})[./-](\d{1,2})[./-](\d{4})').firstMatch(_titleText);
    if (m == null) return null;
    if (m[1]!.length == 4) return DateTime.tryParse('${m[1]}-${m[2]}-${m[3]}');
    return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
  }

  void _validate() {
    setState(() {
      _result = switch (widget.kind) {
        ImportKind.bagRules => parseRows<BagRule>(rows: _rows, headerRow: _headerRow, mapping: _mapping, kind: widget.kind),
        ImportKind.airCodes => parseRows<AirCodeRule>(rows: _rows, headerRow: _headerRow, mapping: _mapping, kind: widget.kind),
        ImportKind.dmsl => parseRows<HubRule>(rows: _rows, headerRow: _headerRow, mapping: _mapping, kind: widget.kind),
      };
      _step = 3;
    });
  }

  Future<void> _save() async {
    final r = _result;
    if (r == null || r.rows.isEmpty) return;
    final services = context.services;
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      switch (widget.kind) {
        case ImportKind.bagRules:
          final rules = r.rules.cast<BagRule>();
          final bags = completeBags(rules, r.bags, kBagPalette.map(colourToHex).toList());
          final isSample = (_titleText + (_file?.name ?? '')).toUpperCase().contains('SAMPLE');
          await services.schemes.saveScheme(
            Scheme(name: _name.text.trim().isEmpty ? _file!.name : _name.text.trim(), office: _office.text.trim(), isSample: isSample),
            rules,
            bags,
          );
        case ImportKind.airCodes:
          await services.schemes.replaceAirCodes(widget.schemeId!, r.rules.cast<AirCodeRule>());
        case ImportKind.dmsl:
          final id = widget.schemeId!;
          final previous = (await services.schemes.dmslVersions(id)).where((v) => v.active).firstOrNull;
          final newId = await services.schemes.addDmslVersion(
            id,
            _version.text.trim().isEmpty ? _file!.name : _version.text.trim(),
            _validFrom,
            r.rules.cast<HubRule>(),
          );
          await services.reloadActive();
          if (!mounted) return;
          if (previous != null) {
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DmslDiffScreen(schemeId: id, oldVersionId: previous.id!, newVersionId: newId)),
            );
            return;
          }
      }
      await services.reloadActive();
      if (!mounted) return;
      toast(context, l.importSaved(r.rows.length));
      Navigator.pop(context, true);
    } on Object catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_title(l))),
      body: Column(
        children: [
          _StepHeader(step: _step, labels: [l.stepFile, l.stepPreview, l.stepMapping, l.stepReport]),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: WarningBanner(text: l.error(_error!))),
          Expanded(child: switch (_step) {
            0 => _fileStep(l),
            1 => _previewStep(l),
            2 => _mappingStep(l),
            _ => _reportStep(l),
          }),
        ],
      ),
      bottomNavigationBar: _step == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    OutlinedButton(onPressed: _saving ? null : () => setState(() => _step--), child: Text(l.back)),
                    const Spacer(),
                    if (_step == 1) FilledButton(onPressed: _rows.isEmpty ? null : () => setState(() => _step = 2), child: Text(l.next)),
                    if (_step == 2) FilledButton(onPressed: _validate, child: Text(l.validate)),
                    if (_step == 3)
                      FilledButton.icon(
                        onPressed: _saving || (_result?.rows.isEmpty ?? true) ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(l.saveRules(_result?.rows.length ?? 0)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _fileStep(AppLocalizations l) {
    final cols = switch (widget.kind) {
      ImportKind.bagRules => l.importSchemeHelp,
      ImportKind.airCodes => l.importAirHelp,
      ImportKind.dmsl => l.importDmslHelp,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(cols, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _pick, icon: const Icon(Icons.file_open), label: Text(l.chooseFile)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await saveAsset(_templateAsset);
            if (mounted && ok) toast(context, l.templateSaved);
          },
          icon: const Icon(Icons.download),
          label: Text(l.downloadTemplate),
        ),
        const SizedBox(height: 24),
        Text(l.importPrivacy, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _previewStep(AppLocalizations l) {
    final rows = _rows.take(20).toList();
    final width = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(_file?.name ?? '', style: Theme.of(context).textTheme.titleMedium),
        if ((_table?.sheetNames.length ?? 0) > 1)
          DropdownButtonFormField<String>(
            initialValue: _sheet,
            decoration: InputDecoration(labelText: l.sheet),
            items: [for (final s in _table!.sheetNames) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (s) => setState(() {
              _sheet = s;
              _detect();
            }),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _headerRow,
          decoration: InputDecoration(labelText: l.headerRow),
          items: [
            for (var i = 0; i < _rows.length && i < 15; i++)
              DropdownMenuItem(value: i, child: Text('${i + 1}: ${_rows[i].where((c) => c.isNotEmpty).take(4).join(' | ')}', overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => setState(() {
            _headerRow = v ?? 0;
            _mapping = autoDetectColumns(_header, widget.kind);
          }),
        ),
        const SizedBox(height: 8),
        Text(l.previewRows(rows.length, _rows.length)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 40,
            columns: [
              const DataColumn(label: Text('#')),
              for (var c = 0; c < width; c++) DataColumn(label: Text(_colName(c))),
            ],
            rows: [
              for (var r = 0; r < rows.length; r++)
                DataRow(
                  color: r == _headerRow ? WidgetStatePropertyAll(Theme.of(context).colorScheme.secondaryContainer) : null,
                  cells: [
                    DataCell(Text('${r + 1}')),
                    for (var c = 0; c < width; c++) DataCell(Text(c < rows[r].length ? rows[r][c] : '')),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _colName(int c) {
    var n = c;
    var s = '';
    do {
      s = String.fromCharCode(65 + n % 26) + s;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return s;
  }

  Widget _mappingStep(AppLocalizations l) {
    final fields = kImportFields[widget.kind]!;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(l.mappingHelp),
        const SizedBox(height: 8),
        for (final f in fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: DropdownButtonFormField<int>(
              initialValue: _mapping[f] ?? -1,
              isExpanded: true,
              decoration: InputDecoration(labelText: fieldLabel(l, f), isDense: true),
              items: [
                DropdownMenuItem(value: -1, child: Text(l.notMapped)),
                for (var c = 0; c < _header.length; c++)
                  DropdownMenuItem(value: c, child: Text('${_colName(c)}: ${_header[c]}', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() {
                if (v == null || v < 0) {
                  _mapping.remove(f);
                } else {
                  _mapping.removeWhere((k, c) => c == v);
                  _mapping[f] = v;
                }
              }),
            ),
          ),
      ],
    );
  }

  Widget _reportStep(AppLocalizations l) {
    final r = _result!;
    final t = Theme.of(context).textTheme;
    final counts = <IssueKind, int>{};
    for (final i in r.issues) {
      counts[i.kind] = (counts[i.kind] ?? 0) + 1;
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: Icon(r.errors.isEmpty ? Icons.check_circle : Icons.error_outline, color: r.errors.isEmpty ? okColor(context) : Theme.of(context).colorScheme.error, size: 36),
            title: Text(l.reportRulesOk(r.rows.length), style: t.titleMedium),
            subtitle: Text(l.reportSummary(r.errors.length, r.warnings.length)),
          ),
        ),
        if (widget.kind == ImportKind.bagRules) ...[
          TextField(controller: _name, decoration: InputDecoration(labelText: l.schemeName)),
          const SizedBox(height: 8),
          TextField(controller: _office, decoration: InputDecoration(labelText: l.officeName)),
          const SizedBox(height: 4),
          Text(l.bagsFound(r.bags.length)),
        ],
        if (widget.kind == ImportKind.airCodes) Text(l.airReplaceNote),
        if (widget.kind == ImportKind.dmsl) ...[
          TextField(controller: _version, decoration: InputDecoration(labelText: l.dmslVersionName)),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.validFrom),
            subtitle: Text(_validFrom == null ? '—' : _validFrom!.toIso8601String().substring(0, 10)),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2035), initialDate: _validFrom ?? DateTime.now());
              if (d != null) setState(() => _validFrom = d);
            },
          ),
        ],
        const SizedBox(height: 8),
        for (final e in counts.entries)
          ExpansionTile(
            leading: Icon(
              r.issues.firstWhere((i) => i.kind == e.key).isError ? Icons.error_outline : Icons.info_outline,
              color: r.issues.firstWhere((i) => i.kind == e.key).isError ? Theme.of(context).colorScheme.error : warningColor(context),
            ),
            title: Text('${issueLabel(l, e.key)}: ${e.value}'),
            children: [
              for (final i in r.issues.where((i) => i.kind == e.key).take(100))
                ListTile(dense: true, title: Text(l.rowN(i.row)), subtitle: Text(i.message)),
            ],
          ),
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.labels});

  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: i <= step ? c.primary : c.surfaceContainerHighest,
                    child: Text('${i + 1}', style: TextStyle(color: i <= step ? c.onPrimary : c.onSurface, fontSize: 14)),
                  ),
                  Text(labels[i], style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

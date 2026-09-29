/// List of imported schemes: import, create, sample, export, set active, delete.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/files.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/import/scheme_import.dart';
import '../../data/import/scheme_io.dart';
import '../../data/models/scheme.dart';
import 'import_wizard.dart';
import 'scheme_editor.dart';

class SchemesScreen extends StatefulWidget {
  const SchemesScreen({super.key});

  @override
  State<SchemesScreen> createState() => _SchemesScreenState();
}

class _SchemesScreenState extends State<SchemesScreen> {
  List<Scheme>? _schemes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    final s = await context.services.schemes.schemes();
    if (mounted) setState(() => _schemes = s);
  }

  Future<void> _afterChange() async {
    await context.services.reloadActive();
    await _load();
  }

  Future<void> _import() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ImportWizard(kind: ImportKind.bagRules)));
    if (ok == true) await _afterChange();
  }

  Future<void> _create() async {
    final l = AppLocalizations.of(context);
    final name = await _askText(context, l.newScheme, l.schemeName);
    if (name == null || name.isEmpty || !mounted) return;
    final repo = context.services.schemes;
    final id = await repo.createScheme(Scheme(name: name, importedAt: DateTime.now()));
    if ((_schemes ?? []).isEmpty) await repo.setActive(id);
    await _afterChange();
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => SchemeEditor(schemeId: id)));
    await _afterChange();
  }

  Future<void> _installSample() async {
    await installSampleScheme(context.services.schemes, loadAssetBytes);
    await _afterChange();
  }

  Future<void> _export(Scheme s, bool xlsx) async {
    final files = await exportScheme(context.services.schemes, s, xlsx: xlsx);
    await shareFiles(files, text: s.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final list = _schemes;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.schemes),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'sample':
                  await _installSample();
                case 'template':
                  final ok = await saveAsset('assets/samples/template_scheme.xlsx');
                  if (context.mounted && ok) toast(context, l.templateSaved);
                case 'sampleFile':
                  final ok = await saveAsset('assets/samples/sample_scheme.xlsx');
                  if (context.mounted && ok) toast(context, l.templateSaved);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'sample', child: Text(l.installSample)),
              PopupMenuItem(value: 'template', child: Text(l.downloadTemplate)),
              PopupMenuItem(value: 'sampleFile', child: Text(l.downloadSampleFile)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (c) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(leading: const Icon(Icons.file_open), title: Text(l.importScheme), subtitle: Text(l.importSchemeSub), onTap: () {
                  Navigator.pop(c);
                  _import();
                }),
                ListTile(leading: const Icon(Icons.edit_note), title: Text(l.createManually), onTap: () {
                  Navigator.pop(c);
                  _create();
                }),
                ListTile(leading: const Icon(Icons.science_outlined), title: Text(l.installSample), onTap: () {
                  Navigator.pop(c);
                  _installSample();
                }),
              ],
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(l.add),
      ),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? EmptyState(
              icon: Icons.rule_folder_outlined,
              text: l.noSchemes,
              action: FilledButton(onPressed: _installSample, child: Text(l.useSample)),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Text(l.schemesPrivacy, style: Theme.of(context).textTheme.bodySmall)),
                RadioGroup<int>(
                  groupValue: list.where((s) => s.active).firstOrNull?.id,
                  onChanged: (id) async {
                    await context.services.schemes.setActive(id);
                    await _afterChange();
                  },
                  child: Column(
                    children: [
                      for (final s in list)
                        ListTile(
                          leading: Radio<int>(value: s.id!),
                          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (s.isSample) const SampleChip(),
                              if (s.office.isNotEmpty) Text(s.office),
                              if (s.importedAt != null) Text(s.importedAt!.toIso8601String().substring(0, 10)),
                              if (s.active) Text(l.active, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => SchemeEditor(schemeId: s.id!)));
                            await _afterChange();
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              switch (v) {
                                case 'active':
                                  await context.services.schemes.setActive(s.id);
                                  await _afterChange();
                                case 'xlsx':
                                  await _export(s, true);
                                case 'csv':
                                  await _export(s, false);
                                case 'air':
                                  final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ImportWizard(kind: ImportKind.airCodes, schemeId: s.id)));
                                  if (ok == true) await _afterChange();
                                case 'dmsl':
                                  await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ImportWizard(kind: ImportKind.dmsl, schemeId: s.id)));
                                  await _afterChange();
                                case 'delete':
                                  if (await confirm(context, l.confirmDelete(s.name))) {
                                    if (!context.mounted) return;
                                    await context.services.schemes.deleteScheme(s.id!);
                                    await _afterChange();
                                  }
                              }
                            },
                            itemBuilder: (_) => [
                              if (!s.active) PopupMenuItem(value: 'active', child: Text(l.setActive)),
                              PopupMenuItem(value: 'air', child: Text(l.importAirCodes)),
                              PopupMenuItem(value: 'dmsl', child: Text(l.importDmsl)),
                              PopupMenuItem(value: 'xlsx', child: Text(l.exportXlsx)),
                              PopupMenuItem(value: 'csv', child: Text(l.exportCsv)),
                              PopupMenuItem(value: 'delete', child: Text(l.delete)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

Future<String?> _askText(BuildContext context, String title, String label, {String initial = ''}) {
  final l = AppLocalizations.of(context);
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: label)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(d, c.text.trim()), child: Text(l.ok)),
      ],
    ),
  );
}

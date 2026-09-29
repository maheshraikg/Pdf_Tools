/// Shows PINs whose parcel hub changed between two DMSL versions and lets
/// the user practise just those PINs.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import '../../data/dmsl_diff.dart';
import '../learn/flashcards_screen.dart';

class DmslDiffScreen extends StatefulWidget {
  const DmslDiffScreen({super.key, required this.schemeId, required this.oldVersionId, required this.newVersionId});

  final int schemeId;
  final int oldVersionId;
  final int newVersionId;

  @override
  State<DmslDiffScreen> createState() => _DmslDiffScreenState();
}

class _DmslDiffScreenState extends State<DmslDiffScreen> {
  List<DmslChange>? _changes;
  String _oldName = '', _newName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_changes == null) _load();
  }

  Future<void> _load() async {
    final s = context.services;
    final versions = await s.schemes.dmslVersions(widget.schemeId);
    _oldName = versions.where((v) => v.id == widget.oldVersionId).firstOrNull?.versionName ?? '';
    _newName = versions.where((v) => v.id == widget.newVersionId).firstOrNull?.versionName ?? '';
    final a = await s.schemes.hubRules(widget.oldVersionId);
    final b = await s.schemes.hubRules(widget.newVersionId);
    final regions = await s.directory.pinRegions();
    final changes = diffDmsl(a, b, universe: regions.keys, districtOf: (p) => regions[p] ?? (districts: const [], states: const []));
    if (mounted) setState(() => _changes = changes);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = _changes;
    return Scaffold(
      appBar: AppBar(title: Text(l.dmslChanges)),
      body: c == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ListTile(
                  title: Text(l.dmslCompare(_oldName, _newName)),
                  subtitle: Text(l.dmslChangedCount(c.length)),
                ),
                if (c.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: FilledButton.icon(
                      icon: const Icon(Icons.school),
                      label: Text(l.practiseChanged),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FlashcardsScreen(mode: FlashMode.hub, onlyPins: c.map((x) => x.pin).toSet())),
                      ),
                    ),
                  ),
                Expanded(
                  child: c.isEmpty
                      ? EmptyState(icon: Icons.check_circle_outline, text: l.dmslNoChanges)
                      : ListView.builder(
                          itemCount: c.length,
                          itemBuilder: (_, i) {
                            final x = c[i];
                            return ListTile(
                              title: Text('${x.pin}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                              subtitle: Text('${x.before?.route ?? l.none}\n→ ${x.after?.route ?? l.none}'),
                              isThreeLine: true,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

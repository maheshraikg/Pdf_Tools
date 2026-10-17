import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import 'beat_detail_screen.dart';

/// List of beats (own beat + relief beats).
class BeatsScreen extends StatelessWidget {
  const BeatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(l.beats)),
      body: app.beats.isEmpty
          ? EmptyState(icon: Icons.map_outlined, text: l.noBeatYet)
          : ListView(
              children: [
                for (final b in app.beats)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        b.id == app.activeBeat?.id ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(b.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                      subtitle: b.office.isEmpty ? null : Text(b.office),
                      onTap: () => app.setActiveBeat(b),
                      trailing: IconButton(
                        tooltip: l.edit,
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => BeatDetailScreen(beatId: b.id!))),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editBeat(context, null),
        icon: const Icon(Icons.add),
        label: Text(l.createBeat),
      ),
    );
  }
}

/// Create or edit a beat (name, office, notes).
Future<void> editBeat(BuildContext context, Beat? beat) async {
  final l = context.l;
  final name = TextEditingController(text: beat?.name ?? '');
  final office = TextEditingController(text: beat?.office ?? '');
  final notes = TextEditingController(text: beat?.notes ?? '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(beat == null ? l.createBeat : l.editBeat),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: InputDecoration(labelText: l.beatName, hintText: l.beatNameHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: office,
              decoration: InputDecoration(labelText: l.office),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.notes),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.save)),
      ],
    ),
  );
  if (ok != true || name.text.trim().isEmpty || !context.mounted) return;
  final s = context.services;
  final app = context.app;
  final b = beat == null
      ? Beat(name: name.text.trim(), office: office.text.trim(), notes: notes.text.trim())
      : beat.copyWith(name: name.text.trim(), office: office.text.trim(), notes: notes.text.trim());
  final id = await s.beats.saveBeat(b);
  await app.reloadBeats();
  if (beat == null) {
    final created = app.beats.firstWhere((x) => x.id == id);
    app.setActiveBeat(created);
  }
}

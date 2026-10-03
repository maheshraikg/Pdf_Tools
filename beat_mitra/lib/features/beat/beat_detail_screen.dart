import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/fuzzy.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import '../places/place_detail_screen.dart';
import '../places/place_edit_screen.dart';
import 'beats_screen.dart';

/// One beat: streets (drag to reorder = usual walking order), places by
/// street, and the postman's own area notes.
class BeatDetailScreen extends StatefulWidget {
  const BeatDetailScreen({super.key, required this.beatId});
  final int beatId;

  @override
  State<BeatDetailScreen> createState() => _BeatDetailScreenState();
}

class _BeatDetailScreenState extends State<BeatDetailScreen> {
  Beat? _beat;
  List<Street> _streets = [];
  List<PlaceDetails> _places = [];
  List<AreaNote> _notes = [];
  int _version = -1;

  Future<void> _load() async {
    final s = context.services;
    final beat = await s.beats.beat(widget.beatId);
    final streets = await s.beats.streets(widget.beatId);
    final places = await s.places.allDetails(beatId: widget.beatId);
    final notes = await s.beats.areaNotes(widget.beatId);
    if (!mounted) return;
    setState(() {
      _beat = beat;
      _streets = streets;
      _places = places;
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final v = context.watch<AppState>().version;
    if (v != _version) {
      _version = v;
      _load();
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_beat?.name ?? ''),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'edit' && _beat != null) {
                  await editBeat(context, _beat);
                } else if (v == 'delete') {
                  await _deleteBeat();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l.editBeat)),
                PopupMenuItem(value: 'delete', child: Text(l.deleteBeat)),
              ],
            ),
          ],
          bottom: TabBar(
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.75),
            indicatorColor: Theme.of(context).colorScheme.secondary,
            tabs: [
              Tab(text: l.streets),
              Tab(text: l.placesCount(_places.length)),
              Tab(text: l.areaNotes),
            ],
          ),
        ),
        body: TabBarView(children: [_streetsTab(), _placesTab(), _notesTab()]),
      ),
    );
  }

  Future<void> _deleteBeat() async {
    final l = context.l;
    if (!await confirm(context, l.deleteBeat, l.deleteBeatConfirm(_places.length), danger: true, ok: l.delete)) return;
    if (!mounted) return;
    final s = context.services;
    final app = context.app;
    for (final p in _places) {
      for (final ph in p.photos) {
        await s.photos.delete(ph.filePath);
      }
    }
    await s.beats.deleteBeat(widget.beatId);
    await app.reloadBeats();
    await app.rebuildIndex();
    if (mounted) Navigator.pop(context);
  }

  // ---- Streets ----

  Widget _streetsTab() {
    final l = context.l;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(l.streetsHelp, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: _streets.isEmpty
              ? EmptyState(icon: Icons.signpost_outlined, text: l.noStreets)
              : ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: _streets.length,
                  onReorderItem: (oldI, newI) async {
                    setState(() => _streets.insert(newI, _streets.removeAt(oldI)));
                    await context.services.beats.reorderStreets(_streets.map((s) => s.id!).toList());
                    if (mounted) context.app.touch();
                  },
                  itemBuilder: (c, i) {
                    final s = _streets[i];
                    final count = _places.where((p) => p.place.streetId == s.id).length;
                    return Card(
                      key: ValueKey(s.id),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text(s.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          [
                            if (s.area.isNotEmpty) s.area,
                            if (s.crossMainNote.isNotEmpty) s.crossMainNote,
                            l.placesCount(count),
                          ].join(' · '),
                        ),
                        onTap: () => editStreet(context, widget.beatId, s),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.drag_handle, size: 30)),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.add_road),
            label: Text(l.addStreet),
            onPressed: () => editStreet(context, widget.beatId, null),
          ),
        ),
      ],
    );
  }

  // ---- Places ----

  Widget _placesTab() {
    final l = context.l;
    if (_places.isEmpty) {
      return EmptyState(
        icon: Icons.home_outlined,
        text: l.noPlaces,
        action: FilledButton.icon(
          icon: const Icon(Icons.add_location_alt),
          label: Text(l.addPlace),
          onPressed: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceEditScreen(beatId: widget.beatId))),
        ),
      );
    }
    final byStreet = <int?, List<PlaceDetails>>{};
    for (final p in _places) {
      byStreet.putIfAbsent(p.place.streetId, () => []).add(p);
    }
    for (final list in byStreet.values) {
      list.sort((a, b) {
        final wa = a.place.walkOrder, wb = b.place.walkOrder;
        if (wa != null && wb != null && wa != wb) return wa.compareTo(wb);
        return compareDoorNo(a.place.doorNo, b.place.doorNo);
      });
    }
    final sections = <(String, List<PlaceDetails>)>[
      for (final s in _streets)
        if (byStreet[s.id] != null) (s.name, byStreet[s.id]!),
      if (byStreet[null] != null) (l.noStreet, byStreet[null]!),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        for (final (title, list) in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final d in list)
            ListTile(
              leading: PhotoThumb(d.photos.firstOrNull?.filePath, size: 52),
              title: Text(d.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              subtitle: Text(
                [d.addressees.map((a) => a.name).join(', '), d.place.landmark].where((x) => x.isNotEmpty).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: d.place.id!))),
            ),
        ],
      ],
    );
  }

  // ---- Area notes ----

  Widget _notesTab() {
    final l = context.l;
    return Column(
      children: [
        Expanded(
          child: _notes.isEmpty
              ? EmptyState(icon: Icons.sticky_note_2_outlined, text: l.noAreaNotes)
              : ListView(
                  children: [
                    for (final n in _notes)
                      Card(
                        child: ListTile(
                          title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                          subtitle: Text(n.text, style: const TextStyle(fontSize: 16)),
                          onTap: () => _editNote(n),
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.note_add_outlined),
            label: Text(l.addAreaNote),
            onPressed: () => _editNote(null),
          ),
        ),
      ],
    );
  }

  Future<void> _editNote(AreaNote? n) async {
    final l = context.l;
    final title = TextEditingController(text: n?.title ?? '');
    final text = TextEditingController(text: n?.text ?? '');
    final r = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.areaNote),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: InputDecoration(labelText: l.title),
              ),
              const SizedBox(height: 12),
              VoiceTextField(controller: text, label: l.areaNoteHint, maxLines: 5, appendVoice: true),
            ],
          ),
        ),
        actions: [
          if (n != null) TextButton(onPressed: () => Navigator.pop(c, 'delete'), child: Text(l.delete)),
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, 'save'), child: Text(l.save)),
        ],
      ),
    );
    if (!mounted || r == null) return;
    final repo = context.services.beats;
    if (r == 'delete' && n != null) {
      await repo.deleteAreaNote(n.id!);
    } else if (r == 'save' && title.text.trim().isNotEmpty) {
      await repo.saveAreaNote(
        AreaNote(id: n?.id, beatId: widget.beatId, title: title.text.trim(), text: text.text.trim()),
      );
    }
    _load();
  }
}

/// Add / edit a street. Returns the street id.
Future<int?> editStreet(BuildContext context, int beatId, Street? street, {String initialName = ''}) async {
  final l = context.l;
  final name = TextEditingController(text: street?.name ?? initialName);
  final area = TextEditingController(text: street?.area ?? '');
  final note = TextEditingController(text: street?.crossMainNote ?? '');
  final r = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(street == null ? l.addStreet : l.editStreet),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceTextField(controller: name, label: l.streetName, autofocus: street == null),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(l.streetNameHint, style: Theme.of(c).textTheme.bodySmall),
            ),
            TextField(
              controller: area,
              decoration: InputDecoration(labelText: l.area),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(labelText: l.crossMainNote),
            ),
          ],
        ),
      ),
      actions: [
        if (street != null) TextButton(onPressed: () => Navigator.pop(c, 'delete'), child: Text(l.delete)),
        TextButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(c, 'save'), child: Text(l.save)),
      ],
    ),
  );
  if (!context.mounted || r == null) return null;
  final s = context.services;
  final app = context.app;
  if (r == 'delete' && street != null) {
    if (!await confirm(context, l.deleteStreet, l.deleteStreetConfirm, danger: true, ok: l.delete)) return null;
    await s.beats.deleteStreet(street.id!);
    await app.rebuildIndex();
    return null;
  }
  if (name.text.trim().isEmpty) return null;
  final saved = (street ?? Street(beatId: beatId, name: '')).copyWith(
    name: name.text.trim(),
    area: area.text.trim(),
    crossMainNote: note.text.trim(),
  );
  final id = await s.beats.saveStreet(saved);
  if (street != null) await app.rebuildIndex();
  app.touch();
  return id;
}

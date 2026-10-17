import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../data/models.dart';
import '../common/widgets.dart';
import '../search/place_card.dart';
import '../search/search_screen.dart';
import 'place_edit_screen.dart';

/// Full view of one place with photos and management actions.
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});
  final int placeId;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  PlaceDetails? _d;
  int _version = -1;
  bool _gone = false;

  Future<void> _load() async {
    final d = await context.services.places.details(widget.placeId);
    if (!mounted) return;
    setState(() {
      _d = d;
      _gone = d == null;
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
    final d = _d;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.title ?? ''),
        actions: [
          if (d != null)
            PopupMenuButton<String>(
              onSelected: (a) => _action(a, d),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'merge', child: Text(l.mergeDuplicate)),
                PopupMenuItem(value: 'delete', child: Text(l.deletePlace)),
              ],
            ),
        ],
      ),
      body: _gone
          ? EmptyState(icon: Icons.delete_outline, text: l.placeDeleted)
          : d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                if (d.photos.isNotEmpty)
                  SizedBox(
                    height: 240,
                    child: PageView(
                      children: [
                        for (final ph in d.photos)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: PhotoThumb(ph.filePath, size: 400, fit: BoxFit.contain),
                          ),
                      ],
                    ),
                  ),
                PlaceCard(details: d),
                for (final a in d.addressees)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(a.name),
                    subtitle: Text([a.aliases, a.note, a.phone].where((x) => x.isNotEmpty).join(' · ')),
                  ),
                if (d.place.area.isNotEmpty || d.place.pin.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.location_city),
                    title: Text('${d.place.area} ${d.place.pin}'.trim()),
                  ),
                ListTile(leading: Icon(placeTypeIcon(d.place.type)), title: Text(placeTypeLabel(l, d.place.type))),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: Text(l.updateGpsHere),
                    onPressed: () => _updateGps(d),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _updateGps(PlaceDetails d) async {
    final l = context.l;
    final s = context.services;
    final app = context.app;
    final fix = await s.location.current();
    if (!mounted) return;
    if (fix == null) {
      context.toast(l.gpsWaiting);
      return;
    }
    if (!await confirm(context, l.updateGpsHere, l.updateGpsConfirm(fix.accuracyM.round()))) return;
    await s.places.savePlace(d.place.copyWith(lat: fix.point.lat, lng: fix.point.lng, gpsAccuracyM: fix.accuracyM));
    await app.placeChanged(d.place.id!);
    if (mounted) context.toast(l.saved);
  }

  Future<void> _action(String a, PlaceDetails d) async {
    final l = context.l;
    final s = context.services;
    final app = context.app;
    if (a == 'delete') {
      if (!await confirm(context, l.deletePlace, l.deletePlaceConfirm, danger: true, ok: l.delete)) return;
      for (final ph in d.photos) {
        await s.photos.delete(ph.filePath);
      }
      await s.places.deletePlace(d.place.id!);
      app.placeRemoved(d.place.id!);
      if (mounted) Navigator.pop(context);
    } else if (a == 'merge') {
      final other = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SearchScreen(pickMode: true, pickLabel: l.mergeIntoThis, excludeId: d.place.id, title: l.pickDuplicate),
        ),
      );
      if (other == null || !mounted) return;
      if (!await confirm(context, l.mergeDuplicate, l.mergeConfirm)) return;
      await s.places.merge(keepId: d.place.id!, dropId: other);
      app.placeRemoved(other);
      await app.placeChanged(d.place.id!);
      if (mounted) context.toast(l.merged);
    }
  }
}

/// Opens the editor for a new place in the active beat.
Future<int?> addPlaceFlow(BuildContext context, {bool here = true}) {
  final beat = context.app.activeBeat;
  if (beat == null) return Future.value(null);
  return Navigator.push<int>(
    context,
    MaterialPageRoute(
      builder: (_) => PlaceEditScreen(beatId: beat.id!, addHere: here),
    ),
  );
}

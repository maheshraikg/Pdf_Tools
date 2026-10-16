import 'package:flutter/material.dart';

import '../app/city_data.dart';
import '../app/location.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../core/cities.dart';
import '../core/place.dart';
import '../core/timetable.dart';
import '../ui/widgets.dart';

class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key});

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  String _query = '';
  bool _locating = false;
  List<City>? _cities;

  @override
  void initState() {
    super.initState();
    loadCities().then((c) {
      if (mounted) setState(() => _cities = c);
    }, onError: (Object _) {});
  }

  Future<void> _useGps() async {
    final s = context.s, settings = context.settings;
    setState(() => _locating = true);
    final err = await useMyLocation(settings);
    if (!mounted) return;
    setState(() => _locating = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (err) {
            LocationError.denied => s.locationDenied,
            LocationError.disabled => s.locationDisabled,
            LocationError.unavailable => s.locationUnavailable,
          }),
        ),
      );
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _manual() async {
    final s = context.s, settings = context.settings;
    final name = TextEditingController();
    final lat = TextEditingController();
    final lng = TextEditingController();
    final utc = TextEditingController();
    final place = await showDialog<Place>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.enterCoordinates),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: s.placeName),
              ),
              TextField(
                controller: lat,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: s.latitude),
              ),
              TextField(
                controller: lng,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: s.longitude),
              ),
              TextField(
                controller: utc,
                decoration: InputDecoration(labelText: s.utcOffsetOptional),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final la = double.tryParse(lat.text.trim());
              final lo = double.tryParse(lng.text.trim());
              final off = utc.text.trim().isEmpty
                  ? null
                  : parseUtcOffset(utc.text.trim());
              if (la == null ||
                  lo == null ||
                  la.abs() > 90 ||
                  lo.abs() > 180 ||
                  (utc.text.trim().isNotEmpty && off == null)) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(s.invalidCoordinates)));
                return;
              }
              Navigator.pop(
                context,
                Place(
                  id: 'manual',
                  name: name.text.trim().isEmpty
                      ? '${la.toStringAsFixed(3)}, ${lo.toStringAsFixed(3)}'
                      : name.text.trim(),
                  latitude: la,
                  longitude: lo,
                  utcOffsetMinutes: off,
                  methodId: settings.method.id,
                  asr: settings.asr,
                ),
              );
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    if (place == null) return;
    await settings.choosePlace(place, applySuggestions: false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, settings = context.settings;
    final q = _query.trim().toLowerCase();
    final places = presetPlaces
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              (p.nameMl?.contains(q) ?? false) ||
              p.region.toLowerCase().contains(q),
        )
        .toList();

    // Group the (filtered) places by region, keeping their order.
    final regions = <String, List<Place>>{};
    for (final p in places) {
      regions.putIfAbsent(p.region, () => []).add(p);
    }
    final scheme = Theme.of(context).colorScheme;
    final world = _cities == null
        ? const <City>[]
        : searchCities(
            _cities!,
            _query,
            near: (settings.place.latitude, settings.place.longitude),
          );

    return Scaffold(
      appBar: AppBar(title: Text(s.location)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: s.searchPlaces,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Section(
            children: [
              ListTile(
                leading: _locating
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const IconBadge(Icons.my_location),
                title: Text(_locating ? s.locating : s.useMyLocation),
                onTap: _locating ? null : _useGps,
              ),
              if (settings.place.id == 'gps')
                SwitchListTile(
                  secondary: const IconBadge(Icons.sync),
                  title: Text(s.autoLocation),
                  subtitle: Text(s.autoLocationHelp),
                  value: settings.autoLocation,
                  onChanged: (v) => settings.update((x) => x.autoLocation = v),
                ),
              ListTile(
                leading: const IconBadge(Icons.edit_location_alt_outlined),
                title: Text(s.enterCoordinates),
                onTap: _manual,
              ),
            ],
          ),
          for (final e in regions.entries)
            Section(
              title: e.key,
              children: [
                for (final p in e.value)
                  ListTile(
                    title: Text(p.label(s.ml)),
                    subtitle: s.ml && p.nameMl != null ? Text(p.name) : null,
                    trailing: settings.place.id == p.id
                        ? Icon(Icons.check_circle, color: scheme.primary)
                        : null,
                    onTap: () async {
                      await settings.choosePlace(p);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          if (world.isNotEmpty)
            Section(
              title: s.worldPlaces,
              children: [
                for (final c in world)
                  ListTile(
                    title: Text(s.ml && c.nameMl != null ? c.nameMl! : c.name),
                    subtitle: Text(c.region),
                    trailing: settings.place.id == c.toPlace().id
                        ? Icon(Icons.check_circle, color: scheme.primary)
                        : null,
                    onTap: () async {
                      await settings.choosePlace(c.toPlace());
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
              ],
            ),
          if (q.isEmpty || world.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                q.isEmpty ? s.searchWorldHint : s.geonamesCredit,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

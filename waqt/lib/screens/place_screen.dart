import 'package:flutter/material.dart';

import '../app/chart_data.dart';
import '../app/city_data.dart';
import '../app/location.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../core/charts.dart';
import '../core/cities.dart';
import '../core/place.dart';
import '../core/timetable.dart';
import '../ui/widgets.dart';
import '../core/prayer_calc.dart';
import 'timetable_screen.dart';

class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key});

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

enum _Find { browse, search, coordinates }

/// Calculated, a built-in Azan Time Chart, or the mosque's own chart.
enum _Source { calculated, builtin, own }

class _PlaceScreenState extends State<PlaceScreen> {
  String _query = '';
  bool _locating = false;
  List<City>? _cities;
  _Find _find = _Find.browse;
  List<ChartPlace> _charts = const [];

  /// Browse selection: country, state and district names.
  String? _country, _state, _district;

  @override
  void initState() {
    super.initState();
    loadCharts().then((c) {
      if (mounted) setState(() => _charts = c);
    });
    loadCities().then((c) {
      if (!mounted) return;
      setState(() {
        _cities = c;
        _selectFrom(_currentCity(c));
      });
    }, onError: (Object _) {});
  }

  /// The listed town of the current place (or the closest one).
  City? _currentCity(List<City> cities) {
    final p = context.settings.place;
    for (final c in cities) {
      if (p.id.startsWith('gn:') && c.toPlace().id == p.id) return c;
    }
    return nearestCity(cities, p.latitude, p.longitude);
  }

  void _selectFrom(City? c) {
    _country = c?.countryName ?? 'India';
    _state = c?.regionName;
    _district = c?.district;
  }

  /// A searchable list in a bottom sheet; returns the picked item.
  Future<T?> _pick<T>(String title, List<T> items, String Function(T) label) =>
      showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) =>
            _PickSheet<T>(title: title, items: items, label: label),
      );

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
    if (mounted) Navigator.pop(context);
  }

  /// Picks one of the built-in charts (closest ones first).
  Future<void> _pickChart() async {
    final settings = context.settings, s = context.s;
    final p = settings.place;
    double d(ChartPlace c) =>
        (c.latitude - p.latitude).abs() + (c.longitude - p.longitude).abs();
    final sorted = [..._charts]..sort((a, b) => d(a).compareTo(d(b)));
    final c = await _pick<ChartPlace>(s.builtinCharts, sorted, (c) => c.name);
    if (c != null) await settings.useChart(c);
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
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final cities = _cities;
    final masjid = settings.masjid?.name ?? s.masjidN(1);

    Future<void> choose(Place p, {bool pop = false}) async {
      await settings.choosePlace(p);
      // Like the original: a town with an Azan Time Chart uses it.
      final c = chartFor(_charts, p.latitude, p.longitude, asr: settings.asr);
      if (c != null) await settings.useChart(c);
      if (pop && context.mounted) Navigator.pop(context);
    }

    // Browse levels.
    final inCountry = cities == null
        ? const <City>[]
        : cities.where((c) => c.countryName == _country).toList();
    final states = {
      for (final c in inCountry)
        if (c.regionName != null) c.regionName!,
    }.toList()..sort();
    final inState = _state == null
        ? inCountry
        : inCountry.where((c) => c.regionName == _state).toList();
    final districts = {
      for (final c in inState)
        if (c.district != null) c.district!,
    }.toList()..sort();
    final towns =
        (_district == null
                ? inState
                : inState.where((c) => c.district == _district).toList())
            .toList()
          ..sort(
            (a, b) => foldForSearch(a.name).compareTo(foldForSearch(b.name)),
          );
    String townName(City c) => s.ml && c.nameMl != null ? c.nameMl! : c.name;

    Widget level(String title, String? value, VoidCallback? onTap) => ListTile(
      title: Text(
        title,
        style: t.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        value ?? s.choose,
        style: t.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: value == null ? scheme.onSurfaceVariant : null,
        ),
      ),
      trailing: const Icon(Icons.unfold_more),
      onTap: onTap,
    );

    final world = cities == null
        ? const <City>[]
        : searchCities(
            cities,
            _query,
            near: (settings.place.latitude, settings.place.longitude),
          );
    final q = _query.trim().toLowerCase();
    final presets = q.length < 2
        ? const <Place>[]
        : presetPlaces
              .where(
                (p) =>
                    p.name.toLowerCase().contains(q) ||
                    (p.nameMl?.contains(q) ?? false),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.locationSettings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              s.locationSettingsOf(masjid),
              style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          // The current place.
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: IconBadge(Icons.place, color: scheme.primary),
              title: Text(
                settings.place.label(s.ml),
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                [
                  if (settings.place.region.isNotEmpty) settings.place.region,
                  settings.timetableEnabled && settings.timetable != null
                      ? settings.timetable!.name
                      : settings.method.name,
                ].join(' · '),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              icon: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(_locating ? s.locating : s.automaticGps),
              onPressed: _locating ? null : _useGps,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Text(
              s.automaticHelp,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (settings.place.id == 'gps')
            Section(
              children: [
                SwitchListTile(
                  secondary: const IconBadge(Icons.sync),
                  title: Text(s.autoLocation),
                  subtitle: Text(s.autoLocationHelp),
                  value: settings.autoLocation,
                  onChanged: (v) => settings.update((x) => x.autoLocation = v),
                ),
              ],
            ),
          Section(
            title: s.timeSource,
            children: [
              RadioGroup<_Source>(
                groupValue: settings.usesChart
                    ? _Source.builtin
                    : settings.timetableEnabled
                    ? _Source.own
                    : _Source.calculated,
                onChanged: (v) async {
                  switch (v) {
                    case _Source.builtin:
                      await _pickChart();
                    case _Source.own:
                      if (settings.timetableCsv == null || settings.usesChart) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const TimetableScreen(),
                          ),
                        );
                      } else {
                        await settings.update((x) => x.timetableEnabled = true);
                      }
                    case _Source.calculated || null:
                      await settings.update((x) => x.timetableEnabled = false);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<_Source>(
                      value: _Source.calculated,
                      title: Text(s.calculatedSource),
                      subtitle: Text(
                        '${settings.method.name} · ${s.asrName(settings.asr)}',
                      ),
                    ),
                    if (_charts.isNotEmpty)
                      RadioListTile<_Source>(
                        value: _Source.builtin,
                        title: Text(s.builtinCharts),
                        subtitle: Text(
                          settings.usesChart
                              ? settings.place.name
                              : s.builtinChartsHelp(_charts.length),
                        ),
                      ),
                    RadioListTile<_Source>(
                      value: _Source.own,
                      title: Text(s.chartSource),
                      subtitle: Text(
                        !settings.usesChart &&
                                settings.timetableCsv != null &&
                                settings.timetable != null
                            ? settings.timetable!.name
                            : s.chartSourceHelp,
                      ),
                    ),
                  ],
                ),
              ),
              if (settings.usesChart)
                ListTile(
                  leading: const IconBadge(Icons.table_chart),
                  title: Text(s.builtinCharts),
                  subtitle: Text(settings.place.name),
                  trailing: const Icon(Icons.unfold_more),
                  onTap: _pickChart,
                )
              else if (!settings.timetableEnabled)
                ListTile(
                  leading: const IconBadge(Icons.calculate_outlined),
                  title: Text(s.method),
                  subtitle: Text(settings.method.name),
                  trailing: const Icon(Icons.unfold_more),
                  onTap: () async {
                    final m = await _pick<CalcMethod>(
                      s.method,
                      CalcMethod.all,
                      (m) => m.name,
                    );
                    if (m != null) await settings.update((x) => x.method = m);
                  },
                )
              else
                ListTile(
                  leading: const IconBadge(Icons.table_chart),
                  title: Text(s.timetable),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const TimetableScreen(),
                    ),
                  ),
                ),
            ],
          ),
          Section(
            title: s.howFindPlace,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: SegmentedButton<_Find>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: _Find.browse, label: Text(s.browse)),
                    ButtonSegment(value: _Find.search, label: Text(s.search)),
                    ButtonSegment(
                      value: _Find.coordinates,
                      label: Text(s.coordinates),
                    ),
                  ],
                  selected: {_find},
                  onSelectionChanged: (v) => setState(() => _find = v.first),
                ),
              ),
              if (_find == _Find.browse) ...[
                if (cities == null)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  level(s.country, _country, () async {
                    final names =
                        {for (final c in cities) c.countryName}.toList()
                          ..sort((a, b) {
                            if (a == 'India') return -1;
                            if (b == 'India') return 1;
                            return a.compareTo(b);
                          });
                    final v = await _pick<String>(s.country, names, (x) => x);
                    if (v != null && v != _country) {
                      setState(() {
                        _country = v;
                        _state = _district = null;
                      });
                    }
                  }),
                  if (states.isNotEmpty)
                    level(s.state, _state, () async {
                      final v = await _pick<String>(s.state, states, (x) => x);
                      if (v != null && v != _state) {
                        setState(() {
                          _state = v;
                          _district = null;
                        });
                      }
                    }),
                  if (_state != null && districts.isNotEmpty)
                    level(s.district, _district, () async {
                      final v = await _pick<String>(s.district, [
                        s.all,
                        ...districts,
                      ], (x) => x);
                      if (v != null) {
                        setState(() => _district = v == s.all ? null : v);
                      }
                    }),
                  level(
                    s.place,
                    () {
                      final cur = _currentCity(cities);
                      return cur != null &&
                              cur.countryName == _country &&
                              (_state == null || cur.regionName == _state)
                          ? townName(cur)
                          : null;
                    }(),
                    states.isNotEmpty && _state == null
                        ? null
                        : () async {
                            final c = await _pick<City>(
                              s.place,
                              towns,
                              townName,
                            );
                            if (c != null) await choose(c.toPlace());
                          },
                  ),
                ],
              ],
              if (_find == _Find.search) ...[
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
                for (final p in presets)
                  ListTile(
                    title: Text(p.label(s.ml)),
                    subtitle: Text(p.region),
                    trailing: settings.place.id == p.id
                        ? Icon(Icons.check_circle, color: scheme.primary)
                        : null,
                    onTap: () => choose(p, pop: true),
                  ),
                for (final c in world)
                  ListTile(
                    title: Text(townName(c)),
                    subtitle: Text(
                      c.district == null
                          ? c.region
                          : '${c.district}, ${c.region}',
                    ),
                    trailing: settings.place.id == c.toPlace().id
                        ? Icon(Icons.check_circle, color: scheme.primary)
                        : null,
                    onTap: () => choose(c.toPlace(), pop: true),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    q.isEmpty ? s.searchWorldHint : s.geonamesCredit,
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (_find == _Find.coordinates)
                ListTile(
                  leading: const IconBadge(Icons.edit_location_alt_outlined),
                  title: Text(s.enterCoordinates),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _manual,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet list with a filter field.
class _PickSheet<T> extends StatefulWidget {
  const _PickSheet({
    required this.title,
    required this.items,
    required this.label,
  });

  final String title;
  final List<T> items;
  final String Function(T) label;

  @override
  State<_PickSheet<T>> createState() => _PickSheetState<T>();
}

class _PickSheetState<T> extends State<_PickSheet<T>> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final f = foldForSearch(_filter.trim());
    final items = widget.items
        .where((x) => f.isEmpty || foldForSearch(widget.label(x)).contains(f))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (widget.items.length > 8)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.filter_list),
                    hintText: s.filter,
                  ),
                  onChanged: (v) => setState(() => _filter = v),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(widget.label(items[i])),
                  onTap: () => Navigator.pop(context, items[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

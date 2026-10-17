import 'package:flutter/material.dart';

import '../app/city_data.dart';
import '../app/scope.dart';
import '../core/cities.dart';
import '../ui/widgets.dart';

/// Pick a place step by step: country, then state (India), then town.
class PlaceBrowseScreen extends StatefulWidget {
  const PlaceBrowseScreen({super.key, this.country, this.region});

  /// Shown level: null = countries; country only = its states or towns.
  final String? country, region;

  @override
  State<PlaceBrowseScreen> createState() => _PlaceBrowseScreenState();
}

class _PlaceBrowseScreenState extends State<PlaceBrowseScreen> {
  List<City>? _cities;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    loadCities().then((c) {
      if (mounted) setState(() => _cities = c);
    }, onError: (Object _) {});
  }

  Future<void> _open(String? country, String? region) async {
    final picked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceBrowseScreen(country: country, region: region),
      ),
    );
    // A town was picked further down: close this level too.
    if (picked == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, settings = context.settings;
    final scheme = Theme.of(context).colorScheme;
    final cities = _cities;
    final f = foldForSearch(_filter.trim());
    bool match(String name) => f.isEmpty || foldForSearch(name).contains(f);

    Widget body;
    String title;
    if (cities == null) {
      title = s.browsePlaces;
      body = const Center(child: CircularProgressIndicator());
    } else if (widget.country == null) {
      // Countries, India first, then by number of listed places.
      title = s.country;
      final count = <String, int>{};
      for (final c in cities) {
        count[c.countryName] = (count[c.countryName] ?? 0) + 1;
      }
      final names = count.keys.where(match).toList()
        ..sort((a, b) {
          if (a == 'India') return -1;
          if (b == 'India') return 1;
          return a.compareTo(b);
        });
      body = _list([
        for (final n in names)
          ListTile(
            title: Text(n),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(n, null),
          ),
      ]);
    } else {
      final inCountry = cities.where((c) => c.countryName == widget.country);
      final regions = {
        for (final c in inCountry)
          if (c.regionName != null) c.regionName!,
      }.toList()..sort();
      if (widget.region == null && regions.isNotEmpty) {
        title = s.stateOf(widget.country!);
        body = _list([
          for (final r in regions.where(match))
            ListTile(
              title: Text(r),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(widget.country, r),
            ),
        ]);
      } else {
        title = widget.region ?? widget.country!;
        final towns =
            inCountry
                .where(
                  (c) => widget.region == null || c.regionName == widget.region,
                )
                .where((c) => match(c.name))
                .toList()
              ..sort(
                (a, b) =>
                    foldForSearch(a.name).compareTo(foldForSearch(b.name)),
              );
        body = _list([
          for (final c in towns.take(800))
            ListTile(
              title: Text(s.ml && c.nameMl != null ? c.nameMl! : c.name),
              subtitle: c.population >= 100000 ? Text(s.bigCity) : null,
              trailing: settings.place.id == c.toPlace().id
                  ? Icon(Icons.check_circle, color: scheme.primary)
                  : null,
              onTap: () async {
                await settings.choosePlace(c.toPlace());
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
        ]);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.filter_list),
                hintText: s.filter,
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _list(List<Widget> tiles) => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [Section(children: tiles)],
  );
}

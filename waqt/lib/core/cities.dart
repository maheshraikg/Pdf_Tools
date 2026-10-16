/// World places from GeoNames (geonames.org, CC BY 4.0), shipped as
/// `assets/cities.tsv.gz` (see tool/places/gen_cities.py).
library;

import 'dart:math' as math;

import 'place.dart';
import 'prayer_calc.dart';

class City {
  City({
    required this.name,
    required this.otherNames,
    this.nameMl,
    required this.country,
    required this.countryName,
    this.regionName,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.population,
  });

  final String name;
  final List<String> otherNames;
  final String? nameMl;

  /// ISO country code and name.
  final String country, countryName;

  /// State (India only).
  final String? regionName;
  final double latitude, longitude;
  final String timeZone;
  final int population;

  /// [name] folded for search.
  late final String folded = foldForSearch(name);

  String get region =>
      regionName == null ? countryName : '$regionName, $countryName';

  Place toPlace() {
    final (method, asr) = suggestedMethod(country, regionName);
    return Place(
      id: 'gn:$name:${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}',
      name: name,
      nameMl: nameMl,
      latitude: latitude,
      longitude: longitude,
      timeZone: timeZone,
      region: region,
      methodId: method,
      asr: asr,
    );
  }
}

/// Usual calculation method and Asr school in a country.
(String, AsrMethod) suggestedMethod(String country, [String? region]) {
  const hanafi = AsrMethod.hanafi, shafii = AsrMethod.shafii;
  switch (country) {
    case 'IN':
      return region == 'Kerala' || region == 'Lakshadweep'
          ? ('kerala', shafii)
          : ('karachi', hanafi);
    case 'PK' || 'BD' || 'AF':
      return ('karachi', hanafi);
    case 'LK' || 'MV':
      return ('karachi', shafii);
    case 'SA' || 'YE' || 'OM' || 'BH':
      return ('umm_al_qura', shafii);
    case 'AE':
      return ('dubai', shafii);
    case 'QA':
      return ('qatar', shafii);
    case 'KW':
      return ('kuwait', shafii);
    case 'EG' || 'SD' || 'LY' || 'SY' || 'LB' || 'IQ' || 'JO' || 'PS':
      return ('egypt', shafii);
    case 'MY' || 'ID' || 'SG' || 'BN' || 'TH' || 'PH':
      return ('sea', shafii);
    case 'TR' || 'AZ' || 'UZ' || 'TJ' || 'KZ' || 'KG' || 'TM':
      return ('mwl', hanafi);
    case 'US' || 'CA':
      return ('isna', shafii);
    default:
      return ('mwl', shafii);
  }
}

/// Parses the asset text; cities are already sorted by population.
List<City> parseCities(String text) {
  final countries = <String, String>{};
  final regions = <String, String>{};
  final out = <City>[];
  for (final line in text.split('\n')) {
    if (line.isEmpty) continue;
    final f = line.split('\t');
    if (f[0] == '#C') {
      countries[f[1]] = f[2];
    } else if (f[0] == '#A') {
      regions[f[1]] = f[2];
    } else if (f.length >= 9) {
      out.add(
        City(
          name: f[0],
          otherNames: f[1].isEmpty ? const [] : f[1].split(';'),
          nameMl: f[2].isEmpty ? null : f[2],
          country: f[3],
          countryName: countries[f[3]] ?? f[3],
          regionName: regions['${f[3]}.${f[4]}'],
          latitude: double.parse(f[5]),
          longitude: double.parse(f[6]),
          timeZone: f[7],
          population: int.tryParse(f[8]) ?? 0,
        ),
      );
    }
  }
  return out;
}

const _fold = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ä': 'a',
  'ã': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ď': 'd',
  'đ': 'd',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ę': 'e',
  'ě': 'e',
  'ğ': 'g',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ī': 'i',
  'ı': 'i',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ň': 'n',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'ö': 'o',
  'õ': 'o',
  'ō': 'o',
  'ø': 'o',
  'ő': 'o',
  'ř': 'r',
  'ś': 's',
  'š': 's',
  'ş': 's',
  'ș': 's',
  'ť': 't',
  'ţ': 't',
  'ț': 't',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ū': 'u',
  'ů': 'u',
  'ű': 'u',
  'ý': 'y',
  'ÿ': 'y',
  'ź': 'z',
  'ż': 'z',
  'ž': 'z',
  'ṭ': 't',
  'ḍ': 'd',
  'ṣ': 's',
  'ḥ': 'h',
  'ẓ': 'z',
  'ṇ': 'n',
  'ṛ': 'r',
  'ḷ': 'l',
  'ṁ': 'm',
  'ṅ': 'n',
  "'": '',
  '’': '',
  'ʻ': '',
  'ʼ': '',
  '-': ' ',
};

/// Lower case without accents, for matching.
String foldForSearch(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    final c = String.fromCharCode(r);
    b.write(_fold[c] ?? c);
  }
  return b.toString();
}

/// Up to [limit] cities matching [query]: name prefix first, then other
/// names and word starts, then anywhere in the name. Within each group
/// places within 300 km of [near] (lat, lng) come first, then bigger ones.
List<City> searchCities(
  List<City> cities,
  String query, {
  int limit = 60,
  (double, double)? near,
}) {
  final q = foldForSearch(query.trim());
  if (q.length < 2) return const [];
  bool close(City c) {
    if (near == null) return false;
    final dLat = c.latitude - near.$1;
    final dLng = (c.longitude - near.$2) * math.cos(near.$1 * math.pi / 180);
    return dLat * dLat + dLng * dLng < 2.7 * 2.7; // ~300 km
  }

  final groups = [<City>[], <City>[], <City>[]];
  for (final c in cities) {
    final n = c.folded;
    if (n.startsWith(q) || (c.nameMl?.startsWith(query.trim()) ?? false)) {
      groups[0].add(c);
    } else if (n.contains(' $q') ||
        c.otherNames.any((o) => foldForSearch(o).startsWith(q))) {
      groups[1].add(c);
    } else if (q.length >= 3 && n.contains(q)) {
      groups[2].add(c);
    }
  }
  List<City> sorted(List<City> g) => [
    ...g.where(close),
    ...g.where((c) => !close(c)),
  ];
  return [
    ...sorted(groups[0]),
    ...sorted(groups[1]),
    ...sorted(groups[2]),
  ].take(limit).toList();
}

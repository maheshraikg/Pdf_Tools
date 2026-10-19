/// Ready-made yearly prayer-time charts of named places ("Azan Time
/// Charts"), shipped as `assets/charts.tsv.gz` when the app is built with
/// them. Lines (tab separated):
///     #P  name  latitude  longitude  time zone  country code
///     MMDD  fajr  sunrise  dhuhr  asr  maghrib  isha   (local minutes)
library;

import 'dart:math' as math;

import 'place.dart';
import 'prayer_calc.dart';
import 'timetable.dart';

class ChartPlace {
  ChartPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    required this.country,
    required this.rows,
  });

  final String name;
  final double latitude, longitude;
  final String timeZone, country;

  /// `MM-DD` → six local minute-of-day values.
  final Map<String, List<int>> rows;

  /// Fixed UTC offset of the chart's zone (none of them use daylight time).
  int get utcOffsetMinutes => switch (timeZone) {
    'Asia/Riyadh' || 'Asia/Kuwait' || 'Asia/Qatar' || 'Asia/Bahrain' => 180,
    'Asia/Dubai' || 'Asia/Muscat' => 240,
    'Indian/Maldives' || 'Asia/Karachi' => 300,
    _ => 330,
  };

  Timetable get timetable => Timetable(
    name: name,
    utcOffsetMinutes: utcOffsetMinutes,
    rows: rows,
    source: 'Azan Time Charts',
  );

  /// The place the chart belongs to (for Qibla, the zone and the display).
  Place get place => Place(
    id: 'chart:$name',
    name: name,
    latitude: latitude,
    longitude: longitude,
    timeZone: timeZone,
    region: country == 'IN' ? 'India' : country,
    methodId: country == 'IN' ? 'kerala' : 'umm_al_qura',
    asr: name.contains('Hanafi') ? AsrMethod.hanafi : AsrMethod.shafii,
  );
}

List<ChartPlace> parseCharts(String text) {
  final out = <ChartPlace>[];
  Map<String, List<int>>? rows;
  for (final line in text.split('\n')) {
    if (line.isEmpty) continue;
    final f = line.split('\t');
    if (f[0] == '#P' && f.length >= 6) {
      rows = {};
      out.add(
        ChartPlace(
          name: f[1],
          latitude: double.parse(f[2]),
          longitude: double.parse(f[3]),
          timeZone: f[4],
          country: f[5],
          rows: rows,
        ),
      );
    } else if (rows != null && f.length == 7 && f[0].length == 4) {
      rows['${f[0].substring(0, 2)}-${f[0].substring(2)}'] = [
        for (var i = 1; i < 7; i++) int.parse(f[i]),
      ];
    }
  }
  return out;
}

/// The chart nearest to a point within [maxKm], preferring the plain chart
/// of a town (or its variant for the Asr school [asr]) over its other
/// Hanafi / Shafi / Salafi / LAC / MDK variants.
ChartPlace? nearestChart(
  List<ChartPlace> charts,
  double lat,
  double lng, {
  double maxKm = 20,
  AsrMethod? asr,
}) {
  ChartPlace? best;
  var bestScore = double.infinity;
  for (final c in charts) {
    final dy = (c.latitude - lat) * 111.2;
    final dx = (c.longitude - lng) * 111.2 * math.cos(lat * math.pi / 180);
    final d = math.sqrt(dx * dx + dy * dy);
    if (d > maxKm) continue;
    final school = asr == AsrMethod.hanafi
        ? c.name.contains('Hanafi') || c.name.contains('Hanfi')
        : c.name.contains('(Shafi)');
    final variant =
        (c.name.contains('(') && !school) ||
            c.name.contains('LAC') ||
            c.name.contains('MDK')
        ? 5
        : 0;
    if (d + variant < bestScore) {
      bestScore = d + variant;
      best = c;
    }
  }
  return best;
}

/// Districts whose mosques follow one calendar for the whole district
/// (e.g. the Dakshina Kannada calendar, "applicable to D K district only").
const Map<String, String> districtCharts = {'Dakshina Kannada': 'Mangalore'};

/// The chart for a place: its district's calendar when the district has
/// one, otherwise the nearest chart (see [nearestChart]).
ChartPlace? chartFor(
  List<ChartPlace> charts,
  double lat,
  double lng, {
  String? district,
  double maxKm = 20,
  AsrMethod? asr,
}) {
  final name = districtCharts[district];
  if (name != null) {
    final wanted = asr == AsrMethod.hanafi ? '$name (Hanafi)' : name;
    for (final n in [wanted, name]) {
      for (final c in charts) {
        if (c.name == n) return c;
      }
    }
  }
  return nearestChart(charts, lat, lng, maxKm: maxKm, asr: asr);
}

/// The phone's position as a place: named after the nearest town and on
/// that town's time zone.
library;

import 'dart:math' as math;

import '../core/charts.dart';
import '../core/cities.dart';
import '../core/place.dart';
import 'chart_data.dart';
import 'city_data.dart';
import 'native.dart';
import 'settings.dart';
import 'strings.dart';

/// Distance in km between two points (haversine).
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Builds the GPS place for a fix, keeping the current method and Asr.
Future<Place> gpsPlace(
  AppSettings settings,
  S s,
  double lat,
  double lng,
) async {
  List<City> cities;
  try {
    cities = await loadCities();
  } catch (_) {
    cities = const [];
  }
  final near = nearestCity(cities, lat, lng);
  // The nearest town's zone, country and method; far from any town, the
  // phone's zone and the current method.
  final area = nearestCity(cities, lat, lng, maxKm: 150);
  final (method, asr) = area == null
      ? (settings.method.id, settings.asr)
      : suggestedMethod(area.country, area.regionName, lng);
  return Place(
    id: 'gps',
    name: near != null
        ? '${s.myLocation} · ${s.nearPlace(near.nameMl != null && s.ml ? near.nameMl! : near.name)}'
        : '${s.myLocation} (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})',
    latitude: lat,
    longitude: lng,
    timeZone: area?.timeZone,
    region: area?.region ?? '',
    methodId: method,
    asr: asr,
  );
}

/// Locates the phone and switches to it ([prompt]: may ask for permission),
/// as the original app's "Automatic": to the Azan Time Chart of the place
/// when there is one, otherwise to times calculated for the exact position
/// with the country's method. Returns the error, or null when the place
/// was set.
Future<LocationError?> useMyLocation(
  AppSettings settings, {
  bool prompt = true,
}) async {
  final r = await Native.getLocation(prompt: prompt);
  if (!r.ok) return r.error;
  final p = await gpsPlace(
    settings,
    S(settings.lang),
    r.latitude!,
    r.longitude!,
  );
  await settings.choosePlace(p);
  final c = chartFor(
    await loadCharts(),
    p.latitude,
    p.longitude,
    asr: settings.asr,
  );
  if (c != null) await settings.useChart(c);
  return null;
}

/// With automatic location on: moves the GPS place when the phone has
/// moved more than 2 km (or into another time zone). Returns the new place
/// when it changed. Never asks for permission.
Future<Place?> refreshAutoLocation(AppSettings settings) async {
  if (!settings.autoLocation || settings.place.id != 'gps') return null;
  final r = await Native.getLocation(prompt: false);
  if (!r.ok) return null;
  final old = settings.place;
  final p = await gpsPlace(
    settings,
    S(settings.lang),
    r.latitude!,
    r.longitude!,
  );
  final moved = distanceKm(
    old.latitude,
    old.longitude,
    p.latitude,
    p.longitude,
  );
  if (moved < 2 && p.timeZone == old.timeZone) return null;
  // Same country and state: keep the user's method; new area: its own.
  await settings.choosePlace(p, applySuggestions: p.region != old.region);
  return p;
}

/// On start: keeps a built-in chart in step with the bundled data (a chart
/// saved by an older version is replaced), and once after an update checks
/// the place as "Automatic" does: a chart far from the phone (applied for
/// a whole district before) gives way to the exact position, and a place
/// with a chart of its own moves onto it.
Future<void> refreshBuiltInChart(AppSettings settings) async {
  final List<ChartPlace> charts;
  try {
    charts = await loadCharts();
  } catch (_) {
    return;
  }
  final checked = settings.chartsChecked;
  if (settings.usesChart) {
    final name = settings.place.id.substring('chart:'.length);
    for (final c in charts) {
      if (c.name == name &&
          (settings.timetableCsv != c.timetable.toCsv() ||
              settings.adjustments.isNotEmpty)) {
        await settings.useChart(c);
      }
    }
  }
  if (checked) return;
  await settings.update((s) => s.chartsChecked = true);
  if (settings.usesChart) {
    final r = await Native.getLocation(prompt: false);
    final p = settings.place;
    if (r.ok &&
        distanceKm(p.latitude, p.longitude, r.latitude!, r.longitude!) >
            chartReachKm) {
      await useMyLocation(settings, prompt: false);
    }
  } else if (settings.placeChosen && !settings.timetableEnabled) {
    final p = settings.place;
    final c = chartFor(charts, p.latitude, p.longitude, asr: settings.asr);
    if (c != null) await settings.useChart(c);
  }
}

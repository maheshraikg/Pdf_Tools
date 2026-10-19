import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/cities.dart';

Future<List<City>>? _cities;

/// The bundled world place list (loaded once, parsed off the UI thread).
Future<List<City>> loadCities() => _cities ??= () async {
  final data = await rootBundle.load('assets/cities.tsv.gz');
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  return compute(_parse, bytes);
}();

List<City> _parse(Uint8List bytes) =>
    parseCities(utf8.decode(gzip.decode(bytes)));

/// Forgets the loaded list (tests load it outside the fake-async zone).
void debugResetCities() => _cities = null;

/// The closest listed place to a GPS fix, within [maxKm].
City? nearestCity(
  List<City> cities,
  double lat,
  double lng, {
  double maxKm = 30,
}) {
  City? best;
  var bestD = double.infinity;
  final cosLat = math.cos(lat * math.pi / 180);
  for (final c in cities) {
    final dy = c.latitude - lat;
    final dx = (c.longitude - lng) * cosLat;
    final d = dx * dx + dy * dy;
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return math.sqrt(bestD) * 111.2 <= maxKm ? best : null;
}

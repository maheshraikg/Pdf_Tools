/// Pure-Dart route planner for the day's delivery stops.
///
/// Two modes:
///  * [RouteMode.shortest]: nearest neighbour from the start point, improved
///    with 2-opt on straight-line (haversine) distance.
///  * [RouteMode.streetOrder]: follow the beat's usual walking order —
///    streets by `order_index`, places inside a street by the remembered
///    manual order, then by door number.
library;

import 'fuzzy.dart' show compareDoorNo;
import 'geo.dart';

enum RouteMode { shortest, streetOrder }

class RouteStop {
  const RouteStop({required this.id, this.point, this.streetId, this.streetOrder, this.walkOrder, this.doorNo = ''});

  /// Usually the place id.
  final int id;
  final GeoPoint? point;
  final int? streetId;

  /// Order of the street in the beat's walking order (smaller first).
  final int? streetOrder;

  /// Remembered manual order of the place inside its street.
  final int? walkOrder;
  final String doorNo;
}

class RoutePlan {
  RoutePlan(this.stops, this.totalMeters);
  final List<RouteStop> stops;

  /// Straight-line length from the start through every stop with GPS.
  final double totalMeters;

  List<int> get ids => stops.map((s) => s.id).toList();
}

/// Length of a path that starts at [start] (optional) and visits [stops]
/// in order, skipping stops without coordinates.
double pathLength(GeoPoint? start, List<RouteStop> stops) {
  var total = 0.0;
  var prev = start;
  for (final s in stops) {
    final p = s.point;
    if (p == null) continue;
    if (prev != null) total += haversineMeters(prev, p);
    prev = p;
  }
  return total;
}

RoutePlan planRoute(List<RouteStop> stops, {GeoPoint? start, RouteMode mode = RouteMode.shortest}) {
  if (stops.isEmpty) return RoutePlan(const [], 0);
  final ordered = mode == RouteMode.streetOrder ? _streetOrder(stops, start) : _shortest(stops, start);
  return RoutePlan(ordered, pathLength(start, ordered));
}

List<RouteStop> _shortest(List<RouteStop> stops, GeoPoint? start) {
  final withGps = stops.where((s) => s.point != null).toList();
  final without = stops.where((s) => s.point == null).toList();
  var tour = nearestNeighbour(withGps, start);
  tour = twoOpt(tour, start);
  return [...tour, ...without];
}

/// Greedy nearest-neighbour tour (open path) from [start] or the first stop.
List<RouteStop> nearestNeighbour(List<RouteStop> stops, GeoPoint? start) {
  if (stops.isEmpty) return [];
  final remaining = List<RouteStop>.of(stops);
  final out = <RouteStop>[];
  var cur = start;
  if (cur == null) {
    out.add(remaining.removeAt(0));
    cur = out.first.point;
  }
  while (remaining.isNotEmpty) {
    var bestI = 0;
    var bestD = double.infinity;
    for (var i = 0; i < remaining.length; i++) {
      final d = haversineMeters(cur!, remaining[i].point!);
      if (d < bestD) {
        bestD = d;
        bestI = i;
      }
    }
    final next = remaining.removeAt(bestI);
    out.add(next);
    cur = next.point;
  }
  return out;
}

/// 2-opt improvement for an open path with a fixed start point.
List<RouteStop> twoOpt(List<RouteStop> tour, GeoPoint? start, {int maxRounds = 50}) {
  final n = tour.length;
  if (n < 3) return tour;
  final route = List<RouteStop>.of(tour);
  // Index 0 of pts is the fixed start (or the first stop when no start).
  List<GeoPoint> pts() => [?start, ...route.map((s) => s.point!)];
  final offset = start != null ? 1 : 0;
  var improved = true;
  var rounds = 0;
  while (improved && rounds < maxRounds) {
    improved = false;
    rounds++;
    final p = pts();
    final m = p.length;
    // Reverse p[i..k] (i >= 1 so the start stays fixed).
    for (var i = 1; i < m - 1; i++) {
      for (var k = i + 1; k < m; k++) {
        final a = p[i - 1], b = p[i], c = p[k];
        final before = haversineMeters(a, b) + (k + 1 < m ? haversineMeters(c, p[k + 1]) : 0);
        final after = haversineMeters(a, c) + (k + 1 < m ? haversineMeters(b, p[k + 1]) : 0);
        if (after + 1e-6 < before) {
          final ri = i - offset, rk = k - offset;
          final rev = route.sublist(ri, rk + 1).reversed.toList();
          route.replaceRange(ri, rk + 1, rev);
          improved = true;
          break;
        }
      }
      if (improved) break;
    }
  }
  return route;
}

List<RouteStop> _streetOrder(List<RouteStop> stops, GeoPoint? start) {
  final byStreet = <int?, List<RouteStop>>{};
  for (final s in stops) {
    byStreet.putIfAbsent(s.streetId, () => []).add(s);
  }
  final streets = byStreet.keys.where((k) => k != null).toList()
    ..sort((a, b) {
      final oa = byStreet[a]!.first.streetOrder ?? 1 << 30;
      final ob = byStreet[b]!.first.streetOrder ?? 1 << 30;
      final c = oa.compareTo(ob);
      return c != 0 ? c : a!.compareTo(b!);
    });
  final out = <RouteStop>[];
  for (final sid in streets) {
    final list = byStreet[sid]!
      ..sort((a, b) {
        final wa = a.walkOrder, wb = b.walkOrder;
        if (wa != null && wb != null && wa != wb) return wa.compareTo(wb);
        if (wa != null && wb == null) return -1;
        if (wa == null && wb != null) return 1;
        return compareDoorNo(a.doorNo, b.doorNo);
      });
    out.addAll(list);
  }
  // Places without a street: nearest neighbour from the last stop.
  final loose = byStreet[null] ?? const [];
  if (loose.isNotEmpty) {
    final lastPoint = out.reversed.map((s) => s.point).firstWhere((p) => p != null, orElse: () => start);
    final gps = loose.where((s) => s.point != null).toList();
    out.addAll(nearestNeighbour(gps, lastPoint));
    out.addAll(loose.where((s) => s.point == null));
  }
  return out;
}

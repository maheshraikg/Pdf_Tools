import 'dart:math';

import 'package:beat_mitra/core/geo.dart';
import 'package:beat_mitra/core/route_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const start = GeoPoint(12.9716, 77.6412);

  test('haversine and bearing', () {
    const a = GeoPoint(12.9716, 77.6412);
    const north = GeoPoint(12.9806, 77.6412); // ~1 km north
    expect(haversineMeters(a, north), closeTo(1000, 10));
    expect(bearingDegrees(a, north), closeTo(0, 0.5));
    expect(bearingDegrees(a, const GeoPoint(12.9716, 77.6512)), closeTo(90, 0.5));
    expect(relativeBearing(90, 80), 10);
    expect(relativeBearing(10, 350), 20);
    expect(formatDistance(45.4), '45 m');
    expect(formatDistance(1234), '1.2 km');
  });

  test('empty and single', () {
    expect(planRoute([]).stops, isEmpty);
    final p = planRoute([const RouteStop(id: 1, point: start)], start: start);
    expect(p.ids, [1]);
    expect(p.totalMeters, 0);
  });

  test('nearest neighbour visits closest first along a line', () {
    final stops = [
      for (final i in [5, 1, 3, 2, 4]) RouteStop(id: i, point: GeoPoint(start.lat + i * 0.001, start.lng)),
    ];
    final p = planRoute(stops, start: start);
    expect(p.ids, [1, 2, 3, 4, 5]);
  });

  test('2-opt never makes the route longer than nearest neighbour and often improves it', () {
    final rnd = Random(42);
    var improvedCount = 0;
    for (var trial = 0; trial < 30; trial++) {
      final stops = List.generate(
        25,
        (i) =>
            RouteStop(id: i, point: GeoPoint(start.lat + rnd.nextDouble() * 0.02, start.lng + rnd.nextDouble() * 0.02)),
      );
      final nn = nearestNeighbour(stops, start);
      final nnLen = pathLength(start, nn);
      final opt = twoOpt(nn, start);
      final optLen = pathLength(start, opt);
      expect(optLen, lessThanOrEqualTo(nnLen + 1e-6));
      expect(opt.map((s) => s.id).toSet(), stops.map((s) => s.id).toSet());
      if (optLen < nnLen - 1) improvedCount++;
    }
    expect(improvedCount, greaterThan(5));
  });

  test('2-opt fixes a crossing', () {
    // NN from start picks a zig-zag; 2-opt should untangle.
    final pts = {1: const GeoPoint(0, 1), 2: const GeoPoint(1, 0), 3: const GeoPoint(1, 1), 4: const GeoPoint(0, 2)};
    final crossed = [
      for (final id in [1, 3, 2, 4]) RouteStop(id: id, point: pts[id]),
    ];
    final fixed = twoOpt(crossed, const GeoPoint(0, 0));
    expect(pathLength(const GeoPoint(0, 0), fixed), lessThan(pathLength(const GeoPoint(0, 0), crossed)));
  });

  test('stops without GPS go last', () {
    final p = planRoute([
      const RouteStop(id: 1),
      RouteStop(id: 2, point: GeoPoint(start.lat + 0.001, start.lng)),
    ], start: start);
    expect(p.ids, [2, 1]);
  });

  test('street order mode: streets by order_index, then walk order, then door no', () {
    final stops = [
      const RouteStop(id: 1, streetId: 10, streetOrder: 2, doorNo: '5'),
      const RouteStop(id: 2, streetId: 20, streetOrder: 1, doorNo: '10'),
      const RouteStop(id: 3, streetId: 20, streetOrder: 1, doorNo: '2'),
      const RouteStop(id: 4, streetId: 10, streetOrder: 2, doorNo: '1', walkOrder: 5),
      const RouteStop(id: 5, streetId: 10, streetOrder: 2, doorNo: '9', walkOrder: 1),
      RouteStop(id: 6, point: GeoPoint(start.lat + 0.001, start.lng)),
    ];
    final p = planRoute(stops, start: start, mode: RouteMode.streetOrder);
    expect(p.ids, [3, 2, 5, 4, 1, 6]);
  });
}

// Rough performance check (AOT):
//   dart compile exe tool/bench.dart -o /tmp/bench && /tmp/bench
// ignore_for_file: avoid_print

import 'package:tulu_panchanga/panchanga/engine.dart';
import 'package:tulu_panchanga/panchanga/festivals.dart';
import 'package:tulu_panchanga/panchanga/muhurta.dart';
import 'package:tulu_panchanga/panchanga/place.dart';

void main() {
  final place = placeById('mangaluru');
  int ms(void Function() f) {
    final sw = Stopwatch()..start();
    f();
    return sw.elapsedMilliseconds;
  }

  print(
    '1 day:        ${ms(() => PanchangaEngine(place).day(DateTime.utc(2026, 10, 4)))} ms',
  );
  print(
    '42-day month: ${ms(() => PanchangaEngine(place).days(DateTime.utc(2026, 10, 1), 42))} ms',
  );
  print(
    'festival yr:  ${ms(() => FestivalCalculator(PanchangaEngine(place)).forYear(2026))} ms',
  );
  print(
    'muhurta 90d:  ${ms(() => MuhurtaFinder(PanchangaEngine(place)).find(muhurtaPresets.first, DateTime.utc(2026, 10, 1), 90))} ms',
  );
}

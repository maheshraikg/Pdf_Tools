import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/charts.dart';
import 'package:waqt/core/prayer_calc.dart';

/// A made-up chart in the bundled format (the real one is not in the repo).
const _sample =
    '#P\tTestpur\t11.8700\t75.3600\tAsia/Kolkata\tIN\n'
    '1017\t303\t378\t738\t938\t1094\t1164\n'
    '1018\t303\t378\t738\t938\t1094\t1164\n'
    '#P\tTestpur (Hanafi)\t11.8700\t75.3600\tAsia/Kolkata\tIN\n'
    '1017\t303\t378\t738\t990\t1094\t1164\n'
    '#P\tGulf Town\t24.7136\t46.6753\tAsia/Riyadh\tSA\n'
    '1017\t275\t351\t699\t898\t1046\t1136\n';

void main() {
  final charts = parseCharts(_sample);

  test('parse charts', () {
    expect(charts, hasLength(3));
    expect(charts.first.rows['10-17'], [303, 378, 738, 938, 1094, 1164]);
    expect(charts.last.utcOffsetMinutes, 180);
    expect(charts[1].place.asr, AsrMethod.hanafi);
  });

  test('nearest chart prefers the plain town chart', () {
    expect(nearestChart(charts, 11.87, 75.37)?.name, 'Testpur');
    expect(nearestChart(charts, 20, 80), isNull);
  });

  test('a chart gives its exact times to the second', () async {
    final s = AppSettings.memory();
    await s.useChart(charts.first);
    expect(s.usesChart, isTrue);
    final d = s.calculator.day(2026, 10, 17);
    String hm(Prayer p) => s.wall(d[p]).toString().substring(11, 19);
    expect(
      [for (final p in Prayer.fard) hm(p)],
      ['05:03:00', '12:18:00', '15:38:00', '18:14:00', '19:24:00'],
    );
    expect(hm(Prayer.sunrise), '06:18:00');
    // Gulf chart: its own zone.
    await s.useChart(charts.last);
    final g = s.calculator.day(2026, 10, 17);
    expect(s.wall(g[Prayer.fajr]).toString().substring(11, 16), '04:35');
  });
}

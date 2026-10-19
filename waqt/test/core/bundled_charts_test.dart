import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/charts.dart';
import 'package:waqt/core/prayer_calc.dart';

void main() {
  final charts = parseCharts(
    utf8.decode(gzip.decode(File('assets/charts.tsv.gz').readAsBytesSync())),
  );

  test('every chart is a full, ordered year', () {
    expect(charts.length, greaterThan(500));
    for (final c in charts) {
      expect(c.rows.length, greaterThanOrEqualTo(365), reason: c.name);
      c.rows.forEach((day, v) {
        for (var i = 0; i < 5; i++) {
          expect(v[i] < v[i + 1], isTrue, reason: '${c.name} $day');
        }
      });
    }
  });

  test('Kannur gives the original chart to the second', () async {
    final kannur = nearestChart(charts, 11.8745, 75.3704)!;
    expect(kannur.name, 'Kannur');
    final s = AppSettings.memory();
    await s.useChart(kannur);
    final d = s.calculator.day(2026, 10, 17);
    expect(
      [for (final p in Prayer.fard) s.wall(d[p]).toString().substring(11, 19)],
      ['05:03:00', '12:18:00', '15:38:00', '18:14:00', '19:24:00'],
    );
  });

  test('the Asr school picks the matching variant', () {
    expect(
      nearestChart(charts, 13.0827, 80.2707, asr: AsrMethod.hanafi)?.name,
      'Chennai 1 (Hanafi)',
    );
    expect(
      nearestChart(charts, 13.0827, 80.2707, asr: AsrMethod.shafii)?.name,
      'Chennai 1 (Shafi)',
    );
  });

  test('a chart only for its own place, as the original "Automatic"', () {
    // Mangaluru itself: the DK calendar (17 Oct: 5:05 6:20 12:20 3:41 ...).
    final c = chartFor(charts, 12.9172, 74.8560)!;
    expect(c.name, 'Mangalore');
    expect(c.rows['10-17'], [305, 380, 740, 941, 1096, 1166]);
    expect(
      chartFor(charts, 12.9172, 74.8560, asr: AsrMethod.hanafi)!.name,
      'Mangalore (Hanafi)',
    );
    // Nelyady (Puttur taluk): no chart of its own, so calculated there.
    expect(chartFor(charts, 12.8378, 75.3967), isNull);
  });
}

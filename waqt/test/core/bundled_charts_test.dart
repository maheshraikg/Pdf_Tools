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

  test('all of Dakshina Kannada follows the DK calendar', () {
    // Belthangady, Puttur, Sullia: the district chart, not the town's.
    for (final (lat, lng) in [
      (12.9795, 75.2699),
      (12.7620, 75.0930),
      (12.5610, 75.2870),
    ]) {
      final c = chartFor(charts, lat, lng, district: 'Dakshina Kannada')!;
      expect(c.name, 'Mangalore');
      // 17 October in the DK calendar: 5:05 6:20 12:20 3:41 6:16 7:26.
      expect(c.rows['10-17'], [305, 380, 740, 941, 1096, 1166]);
    }
    expect(
      chartFor(
        charts,
        12.9795,
        75.2699,
        district: 'Dakshina Kannada',
        asr: AsrMethod.hanafi,
      )!.name,
      'Mangalore (Hanafi)',
    );
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/location.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/charts.dart';
import 'package:waqt/core/cities.dart';
import 'package:waqt/core/place.dart';
import 'package:waqt/core/prayer_calc.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final charts = parseCharts(
    utf8.decode(gzip.decode(File('assets/charts.tsv.gz').readAsBytesSync())),
  );

  List<String> times(AppSettings s, int m, int d) {
    final day = s.calculator.day(2026, m, d);
    return [
      for (final p in [
        Prayer.fajr,
        Prayer.sunrise,
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ])
        s.wall(day[p]).toString().substring(11, 16),
    ];
  }

  test('Nelyady: exact position with Karachi, as the original app', () {
    final b = computeBasicTimes(
      year: 2026,
      month: 10,
      day: 19,
      latitude: 12.8378,
      longitude: 75.3967,
      params: CalcParams(
        method: CalcMethod.byId(suggestedMethod('IN').$1),
        asr: suggestedMethod('IN').$2,
      ),
      utcOffsetMinutes: 330,
    );
    String hm(DateTime t) {
      final l = t.add(const Duration(minutes: 330, seconds: 30));
      return '${l.hour}:${l.minute.toString().padLeft(2, '0')}';
    }

    expect([b.fajr, b.sunrise, b.dhuhr, b.asr, b.maghrib, b.isha].map(hm), [
      '5:08',
      '6:19',
      '12:13',
      '15:34',
      '18:08',
      '19:19',
    ]);
  });

  test('DK calendar of 17 October to the minute', () async {
    final s = AppSettings.memory();
    await s.useChart(charts.firstWhere((c) => c.name == 'Mangalore'));
    expect(times(s, 10, 17), [
      '05:05',
      '06:20',
      '12:20',
      '15:41',
      '18:16',
      '19:26',
    ]);
  });

  test('older setups move onto their chart, once', () async {
    final s = AppSettings.memory();
    await s.update((x) {
      x.place = presetPlaces.firstWhere((p) => p.id == 'kannur');
      x.placeChosen = true;
      x.chartsChecked = false;
      x.adjustments = {Prayer.asr: 1};
    });
    await refreshBuiltInChart(s);
    expect(s.usesChart, isTrue);
    expect(s.place.name, 'Kannur');
    expect(s.adjustments, isEmpty);
    expect(times(s, 10, 17)[3], '15:38');

    // A chart saved by an older version is brought up to date.
    await s.update((x) {
      x.timetableCsv = x.timetableCsv!.replaceFirst('15:38', '15:39');
      x.adjustments = {Prayer.fajr: 1};
    });
    await refreshBuiltInChart(s);
    expect(s.adjustments, isEmpty);
    expect(times(s, 10, 17)[0], '05:03');

    // Calculated times picked after that stay.
    final c = AppSettings.memory();
    await c.choosePlace(presetPlaces.firstWhere((p) => p.id == 'kannur'));
    await refreshBuiltInChart(c);
    expect(c.usesChart, isFalse);
  });
}

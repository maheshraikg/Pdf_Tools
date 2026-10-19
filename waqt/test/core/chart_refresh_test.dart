import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/city_data.dart';
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
  final cities = parseCities(
    utf8.decode(gzip.decode(File('assets/cities.tsv.gz').readAsBytesSync())),
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

  test('every Dakshina Kannada town gets the DK calendar', () {
    final dk = cities.where((c) => c.district == 'Dakshina Kannada');
    expect(dk.length, greaterThan(30));
    for (final t in dk) {
      final c = chartFor(
        charts,
        t.latitude,
        t.longitude,
        district: nearestCity(cities, t.latitude, t.longitude)?.district,
      );
      expect(c?.name, 'Mangalore', reason: t.name);
    }
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

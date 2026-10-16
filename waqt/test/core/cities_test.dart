import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:waqt/app/city_data.dart';
import 'package:waqt/core/cities.dart';
import 'package:waqt/core/place.dart';

void main() {
  final cities = parseCities(
    utf8.decode(gzip.decode(File('assets/cities.tsv.gz').readAsBytesSync())),
  );

  test('asset has world and Kerala places with valid zones', () {
    expect(cities.length, greaterThan(30000));
    final kerala = cities.where((c) => c.regionName == 'Kerala').toList();
    expect(kerala.length, greaterThan(400));
    tzdata.initializeTimeZones();
    for (final z in cities.map((c) => c.timeZone).toSet()) {
      expect(() => tz.getLocation(z), returnsNormally, reason: z);
    }
  });

  test('search: prefix, accents and other names', () {
    expect(searchCities(cities, 'kozhik').first.name, 'Kozhikode');
    expect(searchCities(cities, 'calicut').first.name, 'Kozhikode');
    expect(searchCities(cities, 'ponnani').first.name, startsWith('Ponn'));
    expect(searchCities(cities, 'london').first.countryName, 'United Kingdom');
    expect(searchCities(cities, 'k'), isEmpty);
  });

  test('world place follows daylight saving', () {
    final london = searchCities(cities, 'london').first.toPlace();
    expect(london.offsetMinutesAt(DateTime.utc(2026, 1, 15)), 0);
    expect(london.offsetMinutesAt(DateTime.utc(2026, 7, 15)), 60);
    expect(london.methodId, 'mwl');
    final kochi = searchCities(cities, 'kochi').first.toPlace();
    expect(kochi.methodId, 'kerala');
    expect(kochi.offsetMinutesAt(DateTime.utc(2026, 7, 15)), 330);
    expect(Place.fromJson(london.toJson()), london);
  });

  test('search puts nearby places first', () {
    final r = searchCities(cities, 'tir', near: (11.25, 75.78));
    final names = r.take(8).map((c) => c.name).toList();
    expect(names, contains('Tirur'));
    expect(names, isNot(contains('Tirana')));
  });

  test('nearest city to a GPS fix', () {
    expect(nearestCity(cities, 10.91, 75.92)?.regionName, 'Kerala');
    expect(nearestCity(cities, 0, -140), isNull); // Pacific Ocean
  });
}

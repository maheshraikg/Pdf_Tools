import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/astro/astro.dart';

/// Reference values from the Swiss Ephemeris (tool/gen_reference.py).
final Map<String, dynamic> ref = jsonDecode(
    File('test/fixtures/swisseph_reference.json').readAsStringSync());

double arcsec(double a, double b) => norm180(a - b).abs() * 3600;

const mangaluruLat = 12.9141, mangaluruLon = 74.8560;

void main() {
  group('positions vs Swiss Ephemeris (1950–2100)', () {
    final rows = (ref['positions'] as List).cast<Map<String, dynamic>>();

    test('Sun tropical longitude within 2"', () {
      var worst = 0.0;
      for (final r in rows) {
        final s = tropicalSunMoon(r['jd']).sun;
        final e = arcsec(s, r['sunTrop']);
        if (e > worst) worst = e;
      }
      expect(worst, lessThan(2.0));
    });

    test('Moon tropical longitude within 20"', () {
      var worst = 0.0;
      for (final r in rows) {
        final m = tropicalSunMoon(r['jd']).moon;
        final e = arcsec(m, r['moonTrop']);
        if (e > worst) worst = e;
      }
      expect(worst, lessThan(20.0));
    });

    test('sidereal (Lahiri) Sun within 2" and Moon within 20"', () {
      for (final r in rows) {
        expect(arcsec(siderealSun(r['jd']), r['sunSid']), lessThan(2.0));
        expect(arcsec(siderealMoon(r['jd']), r['moonSid']), lessThan(20.0));
      }
    });
  });

  test('tithi boundaries 2026–27 within 1 minute', () {
    final rows = (ref['tithis'] as List).cast<Map<String, dynamic>>();
    expect(rows.length, greaterThan(700));
    var worst = 0.0;
    for (final r in rows) {
      final k = r['tithi'] as int; // tithi index (0-based) that starts here
      final jdRef = r['jd'] as double;
      final jd =
          nextCrossing(elongation, jdRef - 0.3, (k * 12.0) % 360, 12.19);
      final err = (jd - jdRef).abs() * 1440;
      if (err > worst) worst = err;
    }
    expect(worst, lessThan(1.0));
  });

  test('sankranti instants 2026–27 within 1 minute', () {
    final rows = (ref['sankrantis'] as List).cast<Map<String, dynamic>>();
    for (final r in rows) {
      final jdRef = r['jd'] as double;
      final jd = nextCrossing(
          siderealSun, jdRef - 3, ((r['rashi'] as int) * 30.0) % 360, 0.9856);
      expect((jd - jdRef).abs() * 1440, lessThan(1.0),
          reason: 'rashi ${r['rashi']}');
    }
  });

  test('Mangaluru sunrise/sunset within 30 s (both conventions)', () {
    final rows = (ref['risesets'] as List).cast<Map<String, dynamic>>();
    for (final r in rows) {
      final jd0 = r['jd0'] as double; // local midnight
      for (final (suffix, h0) in [('', -0.8333), ('Centre', 0.0)]) {
        final rise = sunRiseSet(jd0 + 0.25, mangaluruLat, mangaluruLon,
            rising: true, h0: h0)!;
        final set = sunRiseSet(jd0 + 0.75, mangaluruLat, mangaluruLon,
            rising: false, h0: h0)!;
        expect((rise - r['rise$suffix']).abs() * 86400, lessThan(30));
        expect((set - r['set$suffix']).abs() * 86400, lessThan(30));
      }
    }
  });

  test('Mangaluru moonrise within 2 minutes', () {
    final rows = (ref['risesets'] as List).cast<Map<String, dynamic>>();
    var checked = 0;
    for (final r in rows) {
      final jd0 = r['jd0'] as double;
      final refRise = r['moonrise'] as double;
      final m = moonRiseSet(jd0, jd0 + 1, mangaluruLat, mangaluruLon);
      if (refRise < jd0 + 1) {
        expect(m.rise, isNotNull);
        expect((m.rise! - refRise).abs() * 1440, lessThan(2.0));
        checked++;
      } else {
        expect(m.rise, isNull);
      }
    }
    expect(checked, greaterThan(90));
  });

  test('JD round trip and ΔT sanity', () {
    final t = DateTime.utc(2026, 10, 4, 6, 30);
    expect(dateTimeFromJd(jdFromDateTime(t)), t);
    expect(jdFromDateTime(DateTime.utc(2000, 1, 1, 12)), 2451545.0);
    expect(deltaTSeconds(2026), inInclusiveRange(68.0, 72.0));
  });
}

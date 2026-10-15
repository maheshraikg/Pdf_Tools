import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/prayer_calc.dart';

/// Reference instants (UTC) from the independent `astral` Python library
/// (NOAA algorithm, no refraction for Asr): Fajr/Isha at 18°, sunrise and
/// sunset at the standard 0.833°.
void expectNear(DateTime actual, String expectedUtc, {int seconds = 60}) {
  final e = DateTime.parse('${expectedUtc}Z');
  expect(
    actual.difference(e).inSeconds.abs(),
    lessThanOrEqualTo(seconds),
    reason: 'got $actual, expected $e',
  );
}

BasicTimes calc(
  double lat,
  double lng,
  int y,
  int m,
  int d, {
  CalcMethod method = CalcMethod.karachi,
  AsrMethod asr = AsrMethod.shafii,
  bool ramadan = false,
}) => computeBasicTimes(
  year: y,
  month: m,
  day: d,
  latitude: lat,
  longitude: lng,
  params: CalcParams(method: method, asr: asr),
  ramadan: ramadan,
);

void main() {
  group('matches astral within a minute', () {
    test('Kozhikode, 1 Jan 2026', () {
      final t = calc(11.2588, 75.7804, 2026, 1, 1);
      expectNear(t.fajr, '2026-01-01T00:00:23');
      expectNear(t.sunrise, '2026-01-01T01:16:07');
      expectNear(t.dhuhr, '2026-01-01T07:00:12');
      expectNear(t.asr, '2026-01-01T10:18:02');
      expectNear(t.maghrib, '2026-01-01T12:44:36');
      expectNear(t.isha, '2026-01-01T14:00:19');
    });

    test('Kozhikode, 21 Jun 2026 (Fajr falls on the previous UTC day)', () {
      final t = calc(11.2588, 75.7804, 2026, 6, 21);
      expectNear(t.fajr, '2026-06-20T23:16:50', seconds: 75);
      expectNear(t.sunrise, '2026-06-21T00:35:16');
      expectNear(t.dhuhr, '2026-06-21T06:58:35');
      expectNear(t.asr, '2026-06-21T10:25:31');
      expectNear(t.maghrib, '2026-06-21T13:22:02');
      expectNear(t.isha, '2026-06-21T14:40:36');
    });

    test('Makkah, equinox', () {
      final t = calc(21.4225, 39.8262, 2026, 3, 20);
      expectNear(t.fajr, '2026-03-20T02:10:57');
      expectNear(t.sunrise, '2026-03-20T03:25:07');
      expectNear(t.dhuhr, '2026-03-20T09:28:16');
      expectNear(t.asr, '2026-03-20T12:52:59');
      expectNear(t.maghrib, '2026-03-20T15:31:29');
    });

    test('London, winter solstice', () {
      final t = calc(51.5074, -0.1278, 2026, 12, 21);
      expectNear(t.fajr, '2026-12-21T05:59:15');
      expectNear(t.sunrise, '2026-12-21T08:04:06');
      expectNear(t.dhuhr, '2026-12-21T11:58:20');
      expectNear(t.asr, '2026-12-21T13:37:33');
      expectNear(t.maghrib, '2026-12-21T15:53:03');
      expectNear(t.isha, '2026-12-21T17:57:54');
    });

    test('Hanafi Asr', () {
      final t = calc(11.2588, 75.7804, 2026, 1, 1, asr: AsrMethod.hanafi);
      expectNear(t.asr, '2026-01-01T11:07:54');
    });
  });

  test('Kerala preset adds its margins to the plain angles', () {
    final plain = computeBasicTimes(
      year: 2026,
      month: 3,
      day: 1,
      latitude: 11.2588,
      longitude: 75.7804,
      params: const CalcParams(
        method: CalcMethod(
          id: 'x',
          name: 'x',
          fajrAngle: 19.5,
          ishaAngle: 18.5,
        ),
      ),
    );
    final kerala = calc(
      11.2588,
      75.7804,
      2026,
      3,
      1,
      method: CalcMethod.kerala,
    );
    expect(kerala.fajr, plain.fajr);
    expect(kerala.sunrise, plain.sunrise);
    expect(kerala.dhuhr.difference(plain.dhuhr), const Duration(minutes: 3));
    expect(kerala.asr.difference(plain.asr), const Duration(minutes: 2));
    expect(
      kerala.maghrib.difference(plain.maghrib),
      const Duration(minutes: 3),
    );
    expect(kerala.isha, plain.isha);
  });

  test('Umm al-Qura: Isha 90 min after Maghrib, 120 in Ramadan', () {
    final t = calc(21.4225, 39.8262, 2026, 3, 1, method: CalcMethod.ummAlQura);
    expect(t.isha.difference(t.maghrib), const Duration(minutes: 90));
    final r = calc(
      21.4225,
      39.8262,
      2026,
      3,
      1,
      method: CalcMethod.ummAlQura,
      ramadan: true,
    );
    expect(r.isha.difference(r.maghrib), const Duration(minutes: 120));
  });

  test('high latitude in summer still gives ordered times', () {
    // Oslo, midsummer: the sun never reaches 18° below the horizon.
    for (final rule in HighLatitudeRule.values.where(
      (r) => r != HighLatitudeRule.none,
    )) {
      final t = computeBasicTimes(
        year: 2026,
        month: 6,
        day: 21,
        latitude: 59.9139,
        longitude: 10.7522,
        params: CalcParams(method: CalcMethod.mwl, highLatitude: rule),
      );
      expect(t.fajr.isBefore(t.sunrise), isTrue, reason: '$rule');
      expect(t.sunrise.isBefore(t.dhuhr), isTrue);
      expect(t.dhuhr.isBefore(t.asr), isTrue);
      expect(t.asr.isBefore(t.maghrib), isTrue);
      expect(t.maghrib.isBefore(t.isha), isTrue, reason: '$rule');
    }
  });

  test('whole year in Kerala is ordered and within sane hours', () {
    for (
      var d = DateTime.utc(2026);
      d.year == 2026;
      d = d.add(const Duration(days: 1))
    ) {
      final t = calc(
        8.5241,
        76.9366,
        d.year,
        d.month,
        d.day,
        method: CalcMethod.kerala,
      );
      final list = [t.fajr, t.sunrise, t.dhuhr, t.asr, t.maghrib, t.isha];
      for (var i = 1; i < list.length; i++) {
        expect(list[i].isAfter(list[i - 1]), isTrue, reason: '$d');
      }
      // Local (IST) Fajr between 4:30 and 5:30.
      final fajrIst = t.fajr.add(const Duration(minutes: 330));
      expect(fajrIst.hour * 60 + fajrIst.minute, inInclusiveRange(270, 330));
    }
  });

  test('CalcMethod.byId falls back to Kerala', () {
    expect(CalcMethod.byId('mwl'), CalcMethod.mwl);
    expect(CalcMethod.byId('nope'), CalcMethod.kerala);
    expect(CalcMethod.byId(null), CalcMethod.kerala);
  });
}

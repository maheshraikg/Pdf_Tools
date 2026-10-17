import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/day.dart';
import 'package:waqt/core/place.dart';
import 'package:waqt/core/prayer_calc.dart';

DateTime _local(Place p, DateTime u) =>
    u.add(Duration(minutes: p.offsetMinutesAt(u)));

void main() {
  test('places beside the date line get their own civil day', () {
    for (final (name, lat, lng, tz) in [
      ('Apia', -13.8333, -171.7667, 'Pacific/Apia'), // UTC+13
      ('Kiritimati', 1.8721, -157.4278, 'Pacific/Kiritimati'), // UTC+14
      ('Chatham', -43.95, -176.55, 'Pacific/Chatham'), // UTC+12:45/+13:45
      ('Honolulu', 21.3069, -157.8583, 'Pacific/Honolulu'), // UTC-10
      ('Auckland', -36.8485, 174.7633, 'Pacific/Auckland'),
    ]) {
      final p = Place(
        id: name,
        name: name,
        latitude: lat,
        longitude: lng,
        timeZone: tz,
      );
      final calc = DayCalculator(place: p, params: const CalcParams());
      for (final date in [DateTime.utc(2026, 1, 1), DateTime.utc(2026, 7, 1)]) {
        final d = calc.day(date.year, date.month, date.day);
        for (final pr in [
          Prayer.fajr,
          Prayer.sunrise,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ]) {
          final l = _local(p, d[pr]);
          expect(
            DateTime.utc(l.year, l.month, l.day),
            date,
            reason: '$name ${pr.name}',
          );
        }
        final noon = _local(p, d[Prayer.dhuhr]);
        expect(noon.hour, inInclusiveRange(11, 13), reason: name);
      }
    }
  });

  test('polar day and night stay ordered and on the day', () {
    for (final lat in [69.65, 78.22, -77.85]) {
      final p = Place(
        id: 'p',
        name: 'p',
        latitude: lat,
        longitude: 18.96,
        utcOffsetMinutes: 60,
      );
      final calc = DayCalculator(place: p, params: const CalcParams());
      for (
        var dt = DateTime.utc(2026, 1, 1);
        dt.year == 2026;
        dt = dt.add(const Duration(days: 5))
      ) {
        final d = calc.day(dt.year, dt.month, dt.day);
        final order = [
          Prayer.fajr,
          Prayer.sunrise,
          Prayer.dhuhr,
          Prayer.asr,
          Prayer.maghrib,
          Prayer.isha,
        ].map((x) => d[x]).toList();
        for (var i = 1; i < order.length; i++) {
          expect(
            order[i].isAfter(order[i - 1]),
            isTrue,
            reason: '$lat $dt #$i',
          );
        }
        final l = _local(p, d[Prayer.dhuhr]);
        expect(DateTime.utc(l.year, l.month, l.day), dt);
      }
    }
  });
}

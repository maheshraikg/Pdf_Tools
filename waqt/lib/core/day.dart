/// One day of times for a place, from a timetable or by calculation.
library;

import 'hijri.dart';
import 'place.dart';
import 'prayer_calc.dart';
import 'timetable.dart';

/// Where a day's basic times came from.
enum TimeSource { calculation, timetable }

class PrayerDay {
  const PrayerDay({
    required this.year,
    required this.month,
    required this.day,
    required this.times,
    required this.source,
    required this.hijri,
    this.utcOffsetMinutes = 0,
  });

  /// Civil date at the place.
  final int year, month, day;

  /// UTC instants rounded to the minute, for every [Prayer].
  final Map<Prayer, DateTime> times;
  final TimeSource source;
  final HijriDate hijri;

  /// Local clock offset at the place that day (for fixed Iqama times).
  final int utcOffsetMinutes;

  DateTime operator [](Prayer p) => times[p]!;

  /// UTC instant of local clock time [minutes] (after midnight) on this day.
  DateTime atLocal(int minutes) =>
      date.add(Duration(minutes: minutes - utcOffsetMinutes));

  /// Friday (Jumu'ah replaces Dhuhr).
  bool get isFriday =>
      DateTime.utc(year, month, day).weekday == DateTime.friday;

  DateTime get date => DateTime.utc(year, month, day);
}

/// Builds [PrayerDay]s for a place with the user's parameters.
class DayCalculator {
  DayCalculator({
    required this.place,
    required this.params,
    this.timetable,
    this.hijriAdjustDays = 0,
  });

  final Place place;
  final CalcParams params;

  /// When set, its rows replace the calculated basic times (calculation is
  /// still used for dates the table does not cover).
  final Timetable? timetable;
  final int hijriAdjustDays;

  final Map<int, BasicTimes> _basic = {};
  final Map<int, (List<DateTime>, TimeSource)> _six = {};

  static int _key(int y, int m, int d) => y * 10000 + m * 100 + d;

  (List<DateTime>, TimeSource) _sixFor(int y, int m, int d) =>
      _six.putIfAbsent(_key(y, m, d), () {
        final t = timetable?.utcFor(y, m, d);
        if (t != null) return (t, TimeSource.timetable);
        final ramadan = HijriDate.fromGregorian(
          y,
          m,
          d,
          adjustDays: hijriAdjustDays,
        ).isRamadan;
        final b = _basic.putIfAbsent(
          _key(y, m, d),
          () => computeBasicTimes(
            year: y,
            month: m,
            day: d,
            latitude: place.latitude,
            longitude: place.longitude,
            elevation: place.elevation,
            params: params,
            ramadan: ramadan,
            utcOffsetMinutes: place.offsetMinutesAt(DateTime.utc(y, m, d, 12)),
          ),
        );
        return (
          [b.fajr, b.sunrise, b.dhuhr, b.asr, b.maghrib, b.isha],
          TimeSource.calculation,
        );
      });

  PrayerDay day(int year, int month, int day) {
    final (six, source) = _sixFor(year, month, day);
    final next = DateTime.utc(year, month, day + 1);
    final (nextSix, _) = _sixFor(next.year, next.month, next.day);
    final adj = params.adjustments;
    final offset = place.offsetMinutesAt(DateTime.utc(year, month, day, 12));
    DateTime a(Prayer p, DateTime t) {
      final fixed = params.fixedTimes[p];
      if (fixed != null) {
        return DateTime.utc(
          year,
          month,
          day,
        ).add(Duration(minutes: fixed - offset));
      }
      return _roundToMinute(t.add(Duration(minutes: adj[p] ?? 0)));
    }

    final fajr = a(Prayer.fajr, six[0]);
    final sunrise = a(Prayer.sunrise, six[1]);
    final maghrib = a(Prayer.maghrib, six[4]);
    final nextFajr = _roundToMinute(
      nextSix[0].add(Duration(minutes: adj[Prayer.fajr] ?? 0)),
    );
    // Last third of the night (Maghrib → next Fajr).
    final night = nextFajr.difference(maghrib);
    final lastThird = maghrib.add(night * 2 ~/ 3);

    return PrayerDay(
      year: year,
      month: month,
      day: day,
      source: source,
      utcOffsetMinutes: offset,
      hijri: HijriDate.fromGregorian(
        year,
        month,
        day,
        adjustDays: hijriAdjustDays,
      ),
      times: {
        Prayer.imsak: a(
          Prayer.imsak,
          fajr.subtract(Duration(minutes: params.imsakMinutesBeforeFajr)),
        ),
        Prayer.fajr: fajr,
        Prayer.sunrise: sunrise,
        Prayer.ishraq: a(
          Prayer.ishraq,
          sunrise.add(Duration(minutes: params.ishraqMinutesAfterSunrise)),
        ),
        Prayer.dhuhr: a(Prayer.dhuhr, six[2]),
        Prayer.asr: a(Prayer.asr, six[3]),
        Prayer.maghrib: maghrib,
        Prayer.isha: a(Prayer.isha, six[5]),
        Prayer.tahajjud: a(Prayer.tahajjud, lastThird),
      },
    );
  }

  /// [count] consecutive days starting at the civil date of [from].
  List<PrayerDay> days(DateTime from, int count) => [
    for (var i = 0; i < count; i++)
      () {
        final d = DateTime.utc(from.year, from.month, from.day + i);
        return day(d.year, d.month, d.day);
      }(),
  ];
}

DateTime _roundToMinute(DateTime t) {
  final ms = t.millisecondsSinceEpoch;
  const minute = 60000;
  return DateTime.fromMillisecondsSinceEpoch(
    ((ms + minute ~/ 2) ~/ minute) * minute,
    isUtc: true,
  );
}

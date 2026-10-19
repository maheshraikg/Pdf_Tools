import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/alerts.dart';
import 'package:waqt/core/day.dart';
import 'package:waqt/core/place.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/core/timetable.dart';

final _koz = presetPlaces.firstWhere((p) => p.id == 'kozhikode');

DayCalculator _calc({CalcParams params = const CalcParams(), Timetable? t}) =>
    DayCalculator(place: _koz, params: params, timetable: t);

void main() {
  group('DayCalculator', () {
    test('derived times', () {
      final d = _calc().day(2026, 3, 10);
      expect(d.source, TimeSource.calculation);
      for (final p in Prayer.values) {
        expect(d[p].second, 0, reason: 'rounded to the minute');
      }
      expect(
        d[Prayer.fajr].difference(d[Prayer.imsak]),
        const Duration(minutes: 10),
      );
      expect(
        d[Prayer.ishraq].difference(d[Prayer.sunrise]),
        const Duration(minutes: 15),
      );
      expect(d[Prayer.tahajjud].isAfter(d[Prayer.isha]), isTrue);
      final next = _calc().day(2026, 3, 11);
      expect(d[Prayer.tahajjud].isBefore(next[Prayer.fajr]), isTrue);
    });

    test('user adjustments are applied after rounding inputs', () {
      final base = _calc().day(2026, 3, 10);
      final adj = _calc(
        params: const CalcParams(
          adjustments: {Prayer.isha: 5, Prayer.fajr: -2},
        ),
      ).day(2026, 3, 10);
      expect(
        adj[Prayer.isha].difference(base[Prayer.isha]),
        const Duration(minutes: 5),
      );
      expect(
        adj[Prayer.fajr].difference(base[Prayer.fajr]),
        const Duration(minutes: -2),
      );
      // Imsak follows the adjusted Fajr.
      expect(
        adj[Prayer.imsak].difference(base[Prayer.imsak]),
        const Duration(minutes: -2),
      );
      expect(adj[Prayer.dhuhr], base[Prayer.dhuhr]);
    });

    test('timetable rows replace calculation, other days are calculated', () {
      final t = Timetable.parse(
        'date,fajr,sunrise,dhuhr,asr,maghrib,isha\n'
        '03-10,05:01,06:20,12:30,15:45,18:30,19:45\n',
      );
      final c = _calc(t: t);
      final d = c.day(2026, 3, 10);
      expect(d.source, TimeSource.timetable);
      expect(d[Prayer.fajr], DateTime.utc(2026, 3, 9, 23, 31));
      expect(d[Prayer.isha], DateTime.utc(2026, 3, 10, 14, 15));
      expect(c.day(2026, 3, 11).source, TimeSource.calculation);
    });

    test('Friday and Hijri', () {
      final d = _calc().day(2026, 10, 16);
      expect(d.isFriday, isTrue);
      expect(d.hijri.year, 1448);
      expect(_calc().days(DateTime.utc(2026, 12, 30), 3).map((d) => d.day), [
        30,
        31,
        1,
      ]);
    });
  });

  group('alerts', () {
    final days = _calc().days(DateTime.utc(2026, 10, 15), 3); // Thu, Fri, Sat
    final start = DateTime.utc(2026, 10, 14, 18, 30); // before Thursday Fajr

    test('Azan + Iqama for each prayer, sorted, unique ids', () {
      final plan = planAlerts(days, const AlertConfig(), start);
      expect(plan.length, 3 * 5 * 2);
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
      }
      expect(plan.map((a) => a.id).toSet().length, plan.length);
    });

    test("Jumu'ah uses its own Iqama delay", () {
      final friday = days[1];
      final plan = planAlerts(days, const AlertConfig(), start);
      final iq = plan.firstWhere(
        (a) =>
            a.kind == AlertKind.iqama && a.prayer == Prayer.dhuhr && a.friday,
      );
      expect(
        iq.at.difference(friday[Prayer.dhuhr]),
        const Duration(minutes: 30),
      );
      final thuIq = plan.firstWhere(
        (a) => a.kind == AlertKind.iqama && a.prayer == Prayer.dhuhr,
      );
      expect(
        thuIq.at.difference(days[0][Prayer.dhuhr]),
        const Duration(minutes: 15),
      );
    });

    test('past alerts are skipped, reminders and extras added', () {
      final config = const AlertConfig(imsakAlert: true).withPrayer(
        Prayer.asr,
        const PrayerAlert(iqama: false, reminderMinutes: 10),
      );
      final now = days[0][Prayer.dhuhr]; // Thursday Dhuhr Azan is not after now
      final plan = planAlerts(days, config, now);
      expect(
        plan.any((a) => a.prayer == Prayer.fajr && a.at.isBefore(now)),
        isFalse,
      );
      final reminder = plan.firstWhere(
        (a) => a.kind == AlertKind.reminder && a.prayer == Prayer.asr,
      );
      expect(
        days[0][Prayer.asr].difference(reminder.at),
        const Duration(minutes: 10),
      );
      expect(
        plan.where((a) => a.prayer == Prayer.asr && a.kind == AlertKind.iqama),
        isEmpty,
      );
      expect(plan.where((a) => a.prayer == Prayer.imsak).length, 2);
    });

    test('silent windows run Azan → Iqama + N and merge overlaps', () {
      const config = AlertConfig(silentEnabled: true);
      final w = planSilent(days, config, start);
      expect(w.length, 15);
      final first = w.first;
      expect(first.start, days[0][Prayer.fajr]);
      expect(
        first.end.difference(first.start),
        const Duration(minutes: 20 + 20),
      );
      // Jumu'ah: 30 min to Iqama + 45 min.
      final fri = w.firstWhere((x) => x.start == days[1][Prayer.dhuhr]);
      expect(fri.end.difference(fri.start), const Duration(minutes: 75));

      // A long window swallows the next prayer.
      final long = planSilent(
        days,
        const AlertConfig(
          silentEnabled: true,
          silentMinutesAfterIqama: 60,
        ).withPrayer(Prayer.maghrib, const PrayerAlert(iqamaDelay: 60)),
        start,
      );
      expect(long.length, lessThan(15));
      for (var i = 1; i < long.length; i++) {
        expect(long[i].start.isAfter(long[i - 1].end), isTrue);
      }
      expect(planSilent(days, const AlertConfig(), start), isEmpty);
    });

    test('fixed Iqama times, with fallback to the delay', () {
      final thu = days[0], fri = days[1];
      expect(thu.utcOffsetMinutes, 330);
      final c = const AlertConfig(jumuahFixedIqama: 13 * 60 + 15)
          .withPrayer(Prayer.dhuhr, const PrayerAlert(fixedIqama: 12 * 60 + 45))
          .withPrayer(Prayer.fajr, const PrayerAlert(fixedIqama: 4 * 60));
      // 12:45 IST = 07:15 UTC.
      expect(
        iqamaTime(thu, Prayer.dhuhr, c),
        DateTime.utc(2026, 10, 15, 7, 15),
      );
      // Friday uses the Jumu'ah time, not the Dhuhr one.
      expect(
        iqamaTime(fri, Prayer.dhuhr, c),
        DateTime.utc(2026, 10, 16, 7, 45),
      );
      // 04:00 is before Fajr Azan: falls back to the delay.
      expect(
        iqamaTime(thu, Prayer.fajr, c).difference(thu[Prayer.fajr]),
        const Duration(minutes: 15),
      );
      final plan = planAlerts(days, c, start);
      expect(
        plan.any(
          (a) =>
              a.kind == AlertKind.iqama &&
              a.at == DateTime.utc(2026, 10, 15, 7, 15),
        ),
        isTrue,
      );
      final r = AlertConfig.fromJson(c.toJson());
      expect(r.of(Prayer.dhuhr).fixedIqama, 12 * 60 + 45);
      expect(r.jumuahFixedIqama, 13 * 60 + 15);
      expect(r.copyWith(jumuahFixedIqama: null).jumuahFixedIqama, isNull);
      expect(r.of(Prayer.dhuhr).copyWith(fixedIqama: null).fixedIqama, isNull);
      expect(r.of(Prayer.dhuhr).copyWith(azan: false).fixedIqama, 765);
    });

    test('next prayer', () {
      final n = nextPrayer(days, days[0][Prayer.isha]);
      expect(n!.prayer, Prayer.fajr);
      expect(n.day, days[1]);
    });

    test('config JSON round trip', () {
      final c = const AlertConfig(
        silentEnabled: true,
        silentMode: SilentMode.silent,
      ).withPrayer(Prayer.isha, const PrayerAlert(azan: false, iqamaDelay: 25));
      final r = AlertConfig.fromJson(c.toJson());
      expect(r.silentEnabled, isTrue);
      expect(r.silentMode, SilentMode.silent);
      expect(r.of(Prayer.isha).azan, isFalse);
      expect(r.of(Prayer.isha).iqamaDelay, 25);
      expect(r.of(Prayer.fajr).iqamaDelay, 20);
    });
  });
}

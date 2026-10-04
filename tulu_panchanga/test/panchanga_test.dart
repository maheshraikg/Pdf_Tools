import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/astro/astro.dart';
import 'package:tulu_panchanga/panchanga/engine.dart';
import 'package:tulu_panchanga/panchanga/festivals.dart';
import 'package:tulu_panchanga/panchanga/names.dart';
import 'package:tulu_panchanga/panchanga/place.dart';

final mangaluru = placeById('mangaluru');

void main() {
  final engine = PanchangaEngine(mangaluru);

  group('day panchanga', () {
    test('spans are contiguous and cover sunrise to next sunrise', () {
      for (final d in engine.days(DateTime.utc(2026, 1, 1), 60)) {
        for (final spans in [d.tithis, d.nakshatras, d.yogas, d.karanas]) {
          expect(spans.first.start, lessThanOrEqualTo(d.sunrise));
          expect(spans.last.end, greaterThanOrEqualTo(d.nextSunrise));
          for (var i = 1; i < spans.length; i++) {
            expect(spans[i].start, closeTo(spans[i - 1].end, 1e-6));
          }
        }
        expect(d.sunset, greaterThan(d.sunrise));
        expect(d.dayLength * 24, inInclusiveRange(11.0, 13.5));
      }
    });

    test('tithi at sunrise agrees with elongation', () {
      for (final d in engine.days(DateTime.utc(2026, 6, 1), 30)) {
        expect(d.tithi, (elongation(d.sunrise) / 12).floor());
        expect(d.nakshatra, (siderealMoon(d.sunrise) / (360 / 27)).floor());
      }
    });

    test('kaala timings are inside daytime and follow the weekday table', () {
      // 2026-10-04 is a Sunday: Rahu kaala is the 8th part of the day.
      final d = engine.day(DateTime.utc(2026, 10, 4));
      expect(d.weekday, 0);
      expect(d.kaalas.rahu.end, closeTo(d.sunset, 1e-9));
      expect(d.kaalas.rahu.length, closeTo(d.dayLength / 8, 1e-9));
      // Monday: 2nd part.
      final m = engine.day(DateTime.utc(2026, 10, 5));
      expect(m.kaalas.rahu.start, closeTo(m.sunrise + m.dayLength / 8, 1e-9));
      expect(d.kaalas.abhijit.start,
          closeTo(d.sunrise + 7 * d.dayLength / 15, 1e-9));
    });

    test('Mangaluru sunrise 2026-10-04 is about 06:19 IST', () {
      final d = engine.day(DateTime.utc(2026, 10, 4));
      final w = engine.wall(d.sunrise);
      expect(w.hour, 6);
      expect(w.minute, inInclusiveRange(18, 20));
    });
  });

  group('months and years', () {
    test('2026 has Adhika Jyeshtha (mid-May to mid-June)', () {
      final may25 = engine.day(DateTime.utc(2026, 5, 25)).lunarMonth;
      expect(may25.index, 2);
      expect(may25.adhika, isTrue);
      final jul1 = engine.day(DateTime.utc(2026, 7, 1)).lunarMonth;
      expect(jul1.index, 2);
      expect(jul1.adhika, isFalse);
    });

    test('Mesha sankramana 2026 on 14 April starts Paggu', () {
      final d = engine.day(DateTime.utc(2026, 4, 14));
      expect(d.sankrantiToday, isNotNull);
      final w = engine.wall(d.sankrantiToday!);
      expect((w.month, w.day, w.hour), (4, 14, 9));
      expect(d.solar.month, 0);
      expect(d.solar.day, 1);
      expect(engine.day(DateTime.utc(2026, 4, 13)).solar.month, 11);
    });

    test('solar month days count up without gaps across a year', () {
      DayPanchanga? prev;
      for (final d in engine.days(DateTime.utc(2026, 1, 1), 366)) {
        if (prev != null) {
          if (d.solar.month == prev.solar.month) {
            expect(d.solar.day, prev.solar.day + 1);
          } else {
            expect(d.solar.month, (prev.solar.month + 1) % 12);
            expect(d.solar.day, 1);
            expect(prev.solar.day, inInclusiveRange(29, 32));
          }
        }
        prev = d;
      }
    });

    test('day-1 rule changes the Tulu month start', () {
      // Makara sankramana 2026 is at 15:07 IST on 14 January.
      DateTime start(SolarMonthRule r) =>
          PanchangaEngine(mangaluru, PanchangaConfig(solarMonthRule: r))
              .day(DateTime.utc(2026, 1, 20))
              .solar
              .monthStart;
      expect(start(SolarMonthRule.sunset), DateTime.utc(2026, 1, 14));
      expect(start(SolarMonthRule.aparahna), DateTime.utc(2026, 1, 15));
      expect(start(SolarMonthRule.nextDay), DateTime.utc(2026, 1, 15));
    });

    test('samvatsara: Vishvavasu until Ugadi 2026, then Parabhava', () {
      final before = engine.day(DateTime.utc(2026, 3, 18));
      final after = engine.day(DateTime.utc(2026, 3, 20));
      expect(samvatsaraNames[before.samvatsara].en, 'Vishvavasu');
      expect(samvatsaraNames[after.samvatsara].en, 'Parabhava');
      expect(after.shakaYear, 1948);
      // Sauramana year changes at Bisu.
      expect(samvatsaraNames[after.sauraSamvatsara].en, 'Vishvavasu');
      expect(
          samvatsaraNames[engine.day(DateTime.utc(2026, 4, 15)).sauraSamvatsara]
              .en,
          'Parabhava');
    });
  });

  group('festivals (Mangaluru)', () {
    final calc = FestivalCalculator(engine);
    DateTime? dateOf(int year, String id) {
      for (final o in calc.forYear(year)) {
        if (o.festival.id == id) return o.date;
      }
      return null;
    }

    // Widely published 2026/2027 dates for Karnataka.
    final known = <(int, String, DateTime)>[
      (2026, 'makara_sankranti', DateTime.utc(2026, 1, 14)),
      (2026, 'sankashti', DateTime.utc(2026, 1, 6)),
      (2026, 'shivaratri', DateTime.utc(2026, 2, 15)),
      (2026, 'ugadi', DateTime.utc(2026, 3, 19)),
      (2026, 'bisu', DateTime.utc(2026, 4, 14)),
      (2026, 'janmashtami', DateTime.utc(2026, 9, 4)),
      (2026, 'ganesh_chaturthi', DateTime.utc(2026, 9, 14)),
      (2026, 'vijayadashami', DateTime.utc(2026, 10, 20)),
      (2026, 'deepavali_amavasya', DateTime.utc(2026, 11, 8)),
      (2027, 'shivaratri', DateTime.utc(2027, 3, 6)),
      (2027, 'ugadi', DateTime.utc(2027, 4, 7)),
      (2027, 'ganesh_chaturthi', DateTime.utc(2027, 9, 4)),
      (2027, 'deepavali_amavasya', DateTime.utc(2027, 10, 29)),
    ];
    for (final (year, id, date) in known) {
      test('$id $year', () => expect(dateOf(year, id), date));
    }

    test('every named festival occurs at most once per year', () {
      for (final year in [2026, 2027]) {
        final counts = <String, int>{};
        for (final o in calc.forYear(year)) {
          if (o.festival.category == FestivalCategory.vrata) continue;
          counts.update(o.festival.id, (v) => v + 1, ifAbsent: () => 1);
        }
        counts.forEach((id, n) => expect(n, 1, reason: '$id in $year'));
      }
    });

    test('24 Ekadashis and 12 sankramanas a year (approximately)', () {
      final occ = calc.forYear(2026);
      expect(occ.where((o) => o.festival.id == 'ekadashi').length,
          inInclusiveRange(24, 26));
      final sk = occ.where((o) =>
          o.festival.category == FestivalCategory.sankramana ||
          o.festival.rule is SankrantiRule);
      expect(sk.length, 12);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/hijri.dart';
import 'package:waqt/core/place.dart';
import 'package:waqt/core/qibla.dart';

void main() {
  group('Qibla', () {
    test('known bearings', () {
      expect(qiblaBearing(40.7128, -74.0060), closeTo(58.48, 0.1)); // New York
      expect(qiblaBearing(51.5074, -0.1278), closeTo(118.99, 0.1)); // London
      // Kerala faces a little north of west.
      final koz = qiblaBearing(11.2588, 75.7804);
      expect(koz, inInclusiveRange(285, 300));
    });

    test('distance to the Kaaba', () {
      expect(kaabaDistanceKm(kaabaLatitude, kaabaLongitude), closeTo(0, 0.01));
      expect(kaabaDistanceKm(11.2588, 75.7804), closeTo(3988, 5));
    });

    test('compass heading from sensors (phone flat)', () {
      const down = (x: 0.0, y: 0.0, z: 9.81);
      // Field points north (+y) and down: heading 0.
      expect(
        compassHeading(down, (x: 0.0, y: 20.0, z: -40.0)),
        closeTo(0, 0.01),
      );
      // Top edge pointing east: north is to the left (−x).
      expect(
        compassHeading(down, (x: -20.0, y: 0.0, z: -40.0)),
        closeTo(90, 0.01),
      );
      expect(
        compassHeading(down, (x: 0.0, y: -20.0, z: -40.0)),
        closeTo(180, 0.01),
      );
      expect(
        compassHeading(down, (x: 20.0, y: 0.0, z: -40.0)),
        closeTo(270, 0.01),
      );
      // Field parallel to gravity: unusable.
      expect(compassHeading(down, (x: 0.0, y: 0.0, z: -40.0)), isNull);
    });

    test('angle smoother does not jump across north', () {
      final s = AngleSmoother(0.5);
      s.add(350);
      final v = s.add(10);
      expect(v < 5 || v > 355, isTrue, reason: '$v');
    });
  });

  group('Hijri', () {
    test('epoch', () {
      // 16 July 622 (Julian) = 19 July 622 (proleptic Gregorian).
      expect(HijriDate.fromGregorian(622, 7, 19), const HijriDate(1, 1, 1));
    });

    test('within a day of Umm al-Qura', () {
      // Umm al-Qura: 1 Muharram 1447 = 26 Jun 2025; 1 Ramadan 1447 = 18 Feb 2026.
      for (final (y, m, d, hm) in [(2025, 6, 26, 1), (2026, 2, 18, 9)]) {
        final candidates = [
          -1,
          0,
          1,
        ].map((k) => HijriDate.fromGregorian(y, m, d, adjustDays: k));
        expect(
          candidates.any((h) => h.day == 1 && h.month == hm && h.year == 1447),
          isTrue,
        );
      }
    });

    test('adjustment shifts by days and months roll over', () {
      final a = HijriDate.fromGregorian(2026, 2, 18);
      final b = HijriDate.fromGregorian(2026, 2, 18, adjustDays: 1);
      final c = HijriDate.fromGregorian(2026, 2, 19);
      expect(b, c);
      expect(a == b, isFalse);
      expect(HijriDate.monthsMl, hasLength(12));
    });

    test('a year of days is continuous', () {
      var prev = HijriDate.fromGregorian(2026, 1, 1);
      for (
        var d = DateTime.utc(2026, 1, 2);
        d.year == 2026;
        d = d.add(const Duration(days: 1))
      ) {
        final h = HijriDate.fromGregorian(d.year, d.month, d.day);
        final sameMonth = h.month == prev.month && h.day == prev.day + 1;
        final newMonth = h.day == 1 && prev.day >= 29;
        expect(sameMonth || newMonth, isTrue, reason: '$d: $prev → $h');
        prev = h;
      }
    });
  });

  group('Places', () {
    test('ids are unique and coordinates plausible', () {
      final ids = presetPlaces.map((p) => p.id).toSet();
      expect(ids.length, presetPlaces.length);
      for (final p in presetPlaces.where((p) => p.region == 'Kerala')) {
        expect(p.latitude, inInclusiveRange(8.2, 12.8), reason: p.name);
        expect(p.longitude, inInclusiveRange(74.8, 77.5), reason: p.name);
        expect(p.nameMl, isNotNull);
      }
    });

    test('JSON round trip', () {
      final p = presetPlaces.firstWhere((p) => p.id == 'dubai');
      expect(Place.fromJson(p.toJson()), p);
      expect(Place.fromJson(p.toJson()).methodId, 'dubai');
    });
  });
}

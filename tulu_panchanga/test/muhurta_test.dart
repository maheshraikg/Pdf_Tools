import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/panchanga/engine.dart';
import 'package:tulu_panchanga/panchanga/muhurta.dart';
import 'package:tulu_panchanga/panchanga/place.dart';

void main() {
  final engine = PanchangaEngine(placeById('mangaluru'));
  final finder = MuhurtaFinder(engine);
  final from = DateTime.utc(2026, 11, 1);

  test('general windows avoid Rahu/Yama/Gulika, Vishti and Rikta tithis', () {
    final ws = finder.find(muhurtaPresets.first, from, 30);
    expect(ws, isNotEmpty);
    for (final w in ws) {
      final d = engine.day(w.date);
      expect(const {1, 3, 4, 5}.contains(d.weekday), isTrue);
      for (final bad in [
        d.kaalas.rahu,
        d.kaalas.yamaganda,
        d.kaalas.gulika,
        ...d.kaalas.durmuhurta,
      ]) {
        expect(bad.overlaps(w.start + 1e-6, w.end - 1e-6), isFalse);
      }
      expect(w.start, greaterThanOrEqualTo(d.sunrise));
      expect(w.end, lessThanOrEqualTo(d.sunset));
      expect(w.minutes, greaterThanOrEqualTo(24));
      expect(const {3, 8, 13, 18, 23, 28, 29}.contains(w.tithi), isFalse);
      expect(const {16, 26}.contains(w.yoga), isFalse);
    }
  });

  test('preset nakshatra and month filters are respected', () {
    final p = muhurtaPresets.firstWhere((p) => p.id == 'griha_pravesha');
    final ws = finder.find(p, DateTime.utc(2027, 1, 1), 120);
    expect(ws, isNotEmpty);
    for (final w in ws) {
      expect(p.nakshatras!.contains(w.nakshatra), isTrue);
      final lm = engine.day(w.date).lunarMonth;
      expect(p.lunarMonths!.contains(lm.index), isTrue);
      expect(lm.adhika, isFalse);
    }
  });

  test('adhika masa is skipped', () {
    // Adhika Jyeshtha 2026: 17 May – 15 June.
    final ws = finder.find(muhurtaPresets.first, DateTime.utc(2026, 5, 20), 20);
    expect(ws, isEmpty);
  });

  test('tarabala and chandrabala', () {
    const j = Janma(nakshatra: 0, rashi: 0);
    expect(j.tara(0), 1);
    expect(j.tara(2), 3);
    expect(j.taraGood(2), isFalse);
    expect(j.taraGood(11), isFalse); // 12th star → tara 3
    expect(j.taraGood(1), isTrue);
    expect(j.chandraGood(0), isTrue);
    expect(j.chandraGood(3), isFalse); // 4th house
    final ws = finder.find(muhurtaPresets.first, from, 30, janma: j);
    for (final w in ws) {
      expect(j.taraGood(w.nakshatra), isTrue);
    }
  });
}

/// Muhurta helper: finds daytime windows that satisfy simple, commonly used
/// rules for an activity. This is a shortlist to take to a priest, not a
/// substitute for one — marriage and upanayana are deliberately not offered.
library;

import 'engine.dart';
import 'names.dart';

/// Tithi indices (0..29) of the Rikta tithis (4, 9, 14 of either paksha)
/// and Amavasya.
const Set<int> _rikta = {3, 8, 13, 18, 23, 28};
const int _amavasya = 29;

/// Yogas always avoided: Vyatipata and Vaidhriti.
const Set<int> _badYogas = {16, 26};

/// Yogas considered unfavourable (lower score): Vishkambha, Atiganda, Shula,
/// Ganda, Vyaghata, Vajra, Parigha.
const Set<int> _weakYogas = {0, 5, 8, 9, 12, 14, 18};

/// Vishti (Bhadra) karana.
const int _vishti = 6;

class MuhurtaPreset {
  const MuhurtaPreset({
    required this.id,
    required this.name,
    required this.nakshatras,
    required this.weekdays,
    this.avoidTithis = const {..._rikta, _amavasya},
    this.lunarMonths,
    this.avoidAdhika = true,
    this.note = '',
  });

  final String id;
  final Name name;

  /// Favourable nakshatras (0 = Ashwini). Null = any.
  final Set<int>? nakshatras;

  /// Favourable weekdays (0 = Sunday).
  final Set<int> weekdays;
  final Set<int> avoidTithis;

  /// Favourable lunar months (0 = Chaitra). Null = any.
  final Set<int>? lunarMonths;
  final bool avoidAdhika;
  final String note;
}

// Nakshatra indices used below.
const _ashwini = 0, _rohini = 3, _mrigashira = 4, _punarvasu = 6;
const _pushya = 7, _uPhalguni = 11, _hasta = 12, _chitra = 13, _swati = 14;
const _anuradha = 16, _uAshadha = 20, _shravana = 21, _dhanishta = 22;
const _shatabhisha = 23, _uBhadra = 25, _revati = 26;

const List<MuhurtaPreset> muhurtaPresets = [
  MuhurtaPreset(
    id: 'general',
    name: Name('General auspicious work', 'ಸಾಮಾನ್ಯ ಶುಭ ಕಾರ್ಯ'),
    nakshatras: null,
    weekdays: {1, 3, 4, 5},
    note:
        'Avoids Rikta tithis, Amavasya, Vishti karana, Vyatipata/'
        'Vaidhriti yoga, Rahu kaala, Yamaganda, Gulika and Durmuhurta.',
  ),
  MuhurtaPreset(
    id: 'griha_pravesha',
    name: Name('Griha pravesha (house warming)', 'ಗೃಹ ಪ್ರವೇಶ'),
    nakshatras: {
      _rohini, _mrigashira, _uPhalguni, _chitra, _anuradha, _uAshadha, //
      _uBhadra, _revati, _dhanishta, _shatabhisha,
    },
    weekdays: {1, 3, 4, 5},
    lunarMonths: {1, 2, 10, 11},
    note: 'Classical months: Vaishakha, Jyeshtha, Magha, Phalguna.',
  ),
  MuhurtaPreset(
    id: 'vehicle',
    name: Name('Vehicle purchase', 'ವಾಹನ ಖರೀದಿ'),
    nakshatras: {
      _ashwini, _mrigashira, _punarvasu, _pushya, _hasta, _chitra, _swati, //
      _anuradha, _shravana, _dhanishta, _shatabhisha, _revati,
    },
    weekdays: {1, 3, 4, 5},
  ),
  MuhurtaPreset(
    id: 'business',
    name: Name('Starting a business / shop', 'ವ್ಯಾಪಾರ ಆರಂಭ'),
    nakshatras: {
      _ashwini, _rohini, _mrigashira, _pushya, _uPhalguni, _hasta, //
      _chitra, _anuradha, _uAshadha, _uBhadra, _revati,
    },
    weekdays: {1, 3, 4, 5},
  ),
  MuhurtaPreset(
    id: 'travel',
    name: Name('Starting a journey', 'ಪ್ರಯಾಣ ಆರಂಭ'),
    nakshatras: {
      _ashwini, _mrigashira, _punarvasu, _pushya, _hasta, _anuradha, //
      _shravana, _dhanishta, _revati,
    },
    weekdays: {1, 3, 4, 5},
    note: 'Disha shoola (direction by weekday) is not checked.',
  ),
  MuhurtaPreset(
    id: 'namakarana',
    name: Name('Naming ceremony (namakarana)', 'ನಾಮಕರಣ'),
    nakshatras: {
      _ashwini, _rohini, _mrigashira, _punarvasu, _pushya, _uPhalguni, //
      _hasta, _chitra, _swati, _anuradha, _uAshadha, _shravana, _dhanishta,
      _shatabhisha, _uBhadra, _revati,
    },
    weekdays: {1, 3, 4, 5},
  ),
];

/// Personal strength checks, used when the person's birth star/rashi is known.
class Janma {
  const Janma({this.nakshatra, this.rashi});
  final int? nakshatra;
  final int? rashi;

  /// Tara (1..9) of [dayNakshatra] counted from the birth star.
  int? tara(int dayNakshatra) => nakshatra == null
      ? null
      : ((dayNakshatra - nakshatra! + 27) % 27) % 9 + 1;

  /// Taras 3 (Vipat), 5 (Pratyak) and 7 (Naidhana) are unfavourable.
  bool taraGood(int dayNakshatra) {
    final t = tara(dayNakshatra);
    return t == null || !(t == 3 || t == 5 || t == 7);
  }

  /// Moon in the 1, 3, 6, 7, 10 or 11th house from the birth rashi.
  bool chandraGood(int moonRashi) {
    if (rashi == null) return true;
    final h = (moonRashi - rashi! + 12) % 12 + 1;
    return const {1, 3, 6, 7, 10, 11}.contains(h);
  }
}

class MuhurtaWindow {
  const MuhurtaWindow({
    required this.date,
    required this.start,
    required this.end,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.score,
    required this.reasons,
  });

  final DateTime date;
  final double start;
  final double end;
  final int tithi;
  final int nakshatra;
  final int yoga;

  /// 0..100; higher is better.
  final int score;

  /// Short English notes on what made the window strong or weak.
  final List<String> reasons;

  double get minutes => (end - start) * 1440;
}

class MuhurtaFinder {
  MuhurtaFinder(this.engine);
  final PanchangaEngine engine;

  /// Windows between sunrise and sunset on each of [days] days from [from],
  /// at least [minMinutes] long, best first within each day.
  List<MuhurtaWindow> find(
    MuhurtaPreset preset,
    DateTime from,
    int days, {
    Janma janma = const Janma(),
    double minMinutes = 24,
  }) {
    final out = <MuhurtaWindow>[];
    for (final d in engine.days(from, days)) {
      if (!preset.weekdays.contains(d.weekday)) continue;
      final lm = d.lunarMonth;
      if (preset.avoidAdhika && lm.adhika) continue;
      if (preset.lunarMonths != null &&
          !preset.lunarMonths!.contains(lm.index)) {
        continue;
      }

      // Cut points: element changes and the edges of avoided kaalas.
      final k = d.kaalas;
      final avoid = [k.rahu, k.yamaganda, k.gulika, ...k.durmuhurta];
      final cuts = <double>{d.sunrise, d.sunset};
      for (final spans in [d.tithis, d.nakshatras, d.yogas, d.karanas]) {
        for (final s in spans) {
          if (s.end > d.sunrise && s.end < d.sunset) cuts.add(s.end);
        }
      }
      for (final w in avoid) {
        for (final t in [w.start, w.end]) {
          if (t > d.sunrise && t < d.sunset) cuts.add(t);
        }
      }
      final sorted = cuts.toList()..sort();

      final segs = <MuhurtaWindow>[];
      for (var i = 0; i + 1 < sorted.length; i++) {
        final a = sorted[i], b = sorted[i + 1];
        final mid = (a + b) / 2;
        if (avoid.any((w) => w.contains(mid))) continue;
        final t = DayPanchanga.at(d.tithis, mid)!.index;
        final n = DayPanchanga.at(d.nakshatras, mid)!.index;
        final y = DayPanchanga.at(d.yogas, mid)!.index;
        final kr = karanaIndex(DayPanchanga.at(d.karanas, mid)!.index);
        final mr = DayPanchanga.at(d.moonRashis, mid)?.index ?? d.moonRashi;
        if (preset.avoidTithis.contains(t)) continue;
        if (preset.nakshatras != null && !preset.nakshatras!.contains(n)) {
          continue;
        }
        if (_badYogas.contains(y) || kr == _vishti) continue;
        if (!janma.taraGood(n) || !janma.chandraGood(mr)) continue;

        var score = 70;
        final reasons = <String>[];
        if (t < 15) {
          score += 10;
          reasons.add('Shukla paksha');
        }
        if (_weakYogas.contains(y)) {
          score -= 15;
          reasons.add('weak yoga ${yogaNames[y].en}');
        }
        if (d.kaalas.abhijit.contains(mid) && d.weekday != 3) {
          score += 10;
          reasons.add('Abhijit muhurta');
        }
        if (janma.nakshatra != null) {
          score += 5;
          reasons.add('tara ${janma.tara(n)} good');
        }
        if (janma.rashi != null) {
          score += 5;
          reasons.add('chandrabala good');
        }
        segs.add(
          MuhurtaWindow(
            date: d.date,
            start: a,
            end: b,
            tithi: t,
            nakshatra: n,
            yoga: y,
            score: score.clamp(0, 100),
            reasons: reasons,
          ),
        );
      }

      // Merge adjacent segments with the same elements and score.
      final merged = <MuhurtaWindow>[];
      for (final s in segs) {
        final last = merged.isEmpty ? null : merged.last;
        if (last != null &&
            (s.start - last.end).abs() < 1e-9 &&
            last.tithi == s.tithi &&
            last.nakshatra == s.nakshatra &&
            last.yoga == s.yoga) {
          merged[merged.length - 1] = MuhurtaWindow(
            date: last.date,
            start: last.start,
            end: s.end,
            tithi: last.tithi,
            nakshatra: last.nakshatra,
            yoga: last.yoga,
            score: last.score > s.score ? last.score : s.score,
            reasons: {...last.reasons, ...s.reasons}.toList(),
          );
        } else {
          merged.add(s);
        }
      }
      out.addAll(merged.where((w) => w.minutes >= minMinutes));
    }
    return out;
  }
}

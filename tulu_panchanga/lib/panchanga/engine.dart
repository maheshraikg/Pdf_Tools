/// Day-level panchanga: tithi, nakshatra, yoga, karana, vara, kaala timings,
/// lunar (Chandramana, amanta) and solar (Sauramana / Tulu) months.
///
/// Instants are Julian Days (UT). Use [PanchangaEngine.wall] to turn one into
/// a wall-clock [DateTime] for the place (returned with `isUtc: true` but
/// holding local fields — never pass it to `toLocal()`).
library;

import 'dart:math' as math;

import '../astro/astro.dart';
import 'place.dart';

/// Optional time-zone hook. The app installs one backed by the IANA database;
/// without it the place's fixed offset is used (exact for India).
Duration Function(Place place, DateTime utc)? tzOffsetResolver;

/// One element (tithi, nakshatra, …) and the interval during which it runs.
class Span {
  const Span(this.index, this.start, this.end);

  /// Element index: tithi 0..29, nakshatra/yoga 0..26, karana half-tithi
  /// 0..59, rashi 0..11.
  final int index;
  final double start;
  final double end;

  bool contains(double jd) => jd >= start && jd < end;

  /// Length (days) of the overlap with [a, b).
  double overlap(double a, double b) =>
      math.max(0.0, math.min(end, b) - math.max(start, a));

  @override
  String toString() => 'Span($index, $start, $end)';
}

/// A time window.
class Window {
  const Window(this.start, this.end);
  final double start;
  final double end;

  double get length => end - start;
  bool contains(double jd) => jd >= start && jd < end;
  bool overlaps(double a, double b) => start < b && a < end;
}

class LunarMonth {
  const LunarMonth(this.index, this.adhika, this.newMoonStart, this.newMoonEnd);

  /// 0 = Chaitra … 11 = Phalguna.
  final int index;
  final bool adhika;
  final double newMoonStart;
  final double newMoonEnd;
}

class SolarDate {
  const SolarDate({
    required this.month,
    required this.day,
    required this.monthStart,
    required this.sankranti,
  });

  /// 0 = Mesha / Paggu … 11 = Meena / Suggi.
  final int month;

  /// 1-based day of the solar month.
  final int day;

  /// Civil date of day 1 of this month.
  final DateTime monthStart;

  /// The sankramana instant that began this month.
  final double sankranti;
}

/// Inauspicious / auspicious periods of a day.
class Kaalas {
  const Kaalas({
    required this.rahu,
    required this.yamaganda,
    required this.gulika,
    required this.abhijit,
    required this.brahma,
    required this.durmuhurta,
    required this.madhyahna,
    required this.aparahna,
    required this.pradosha,
    required this.nishita,
    required this.arunodaya,
  });

  final Window rahu;
  final Window yamaganda;
  final Window gulika;

  /// 8th of 15 daytime muhurtas. Traditionally not used on Wednesdays.
  final Window abhijit;

  /// 14th muhurta of the preceding night (two muhurtas before sunrise).
  final Window brahma;
  final List<Window> durmuhurta;

  // Festival kaalas.
  final Window madhyahna;
  final Window aparahna;
  final Window pradosha;
  final Window nishita;
  final Window arunodaya;
}

class DayPanchanga {
  DayPanchanga({
    required this.date,
    required this.weekday,
    required this.sunrise,
    required this.sunset,
    required this.nextSunrise,
    required this.prevSunset,
    required this.moonrise,
    required this.moonset,
    required this.tithis,
    required this.nakshatras,
    required this.yogas,
    required this.karanas,
    required this.moonRashis,
    required this.sunRashi,
    required this.nakshatraPada,
    required this.lunarMonth,
    required this.solar,
    required this.sankrantiToday,
    required this.kaalas,
  });

  /// Civil date (UTC midnight holding the local date).
  final DateTime date;

  /// 0 = Sunday.
  final int weekday;
  final double sunrise;
  final double sunset;
  final double nextSunrise;
  final double prevSunset;
  final double? moonrise;
  final double? moonset;

  /// Elements running between [sunrise] and [nextSunrise], in order.
  final List<Span> tithis;
  final List<Span> nakshatras;
  final List<Span> yogas;
  final List<Span> karanas;
  final List<Span> moonRashis;

  /// Sidereal rashi of the Sun at sunrise.
  final int sunRashi;

  /// Pada (1–4) of the nakshatra at sunrise.
  final int nakshatraPada;
  final LunarMonth lunarMonth;
  final SolarDate solar;

  /// Sankramana instant if one falls within this Hindu day.
  final double? sankrantiToday;
  final Kaalas kaalas;

  /// Tithi prevailing at sunrise (udaya tithi), 0..29.
  int get tithi => tithis.first.index;

  /// 0 = Shukla, 1 = Krishna (by sunrise tithi).
  int get paksha => tithi < 15 ? 0 : 1;
  int get nakshatra => nakshatras.first.index;
  int get yoga => yogas.first.index;
  int get moonRashi => moonRashis.first.index;

  /// A tithi that begins and ends within this day (kshaya), if any.
  Iterable<Span> get kshayaTithis =>
      tithis.where((s) => s.start > sunrise && s.end < nextSunrise);

  double get dayLength => sunset - sunrise;

  /// Ayana by the sidereal Sun at sunrise: 0 = Uttarayana (Makara..Mithuna).
  int get ayana => (sunRashi >= 9 || sunRashi <= 2) ? 0 : 1;

  /// Ritu by lunar month (Chaitra + Vaishakha = Vasanta, …).
  int get ritu => lunarMonth.index ~/ 2;

  /// Shaka year (Chandramana: changes at Chaitra shukla pratipada).
  int get shakaYear =>
      date.year - 78 - ((date.month <= 4 && lunarMonth.index >= 9) ? 1 : 0);

  /// Shaka year in the Sauramana (Tulu) reckoning: changes at Mesha
  /// sankramana (Bisu).
  int get sauraShakaYear =>
      date.year - 78 - ((date.month <= 4 && solar.month >= 8) ? 1 : 0);

  /// Samvatsara index (0 = Prabhava) of the Chandramana year.
  int get samvatsara => (shakaYear + 11) % 60;

  /// Samvatsara index of the Sauramana (Tulu) year.
  int get sauraSamvatsara => (sauraShakaYear + 11) % 60;

  /// Kali-yuga year (Chandramana).
  int get kaliYear => shakaYear + 3179;

  /// The element of [spans] in force at [jd], if within this day.
  static Span? at(List<Span> spans, double jd) {
    for (final s in spans) {
      if (s.contains(jd)) return s;
    }
    return null;
  }
}

/// Computes panchanga days for one place and set of conventions, with
/// caching. Not thread-safe; create one per isolate.
class PanchangaEngine {
  PanchangaEngine(this.place, [this.config = const PanchangaConfig()]);

  final Place place;
  final PanchangaConfig config;

  final Map<int, DayPanchanga> _days = {};
  final Map<int, double> _sunrises = {};
  final Map<int, double> _sunsets = {};
  final List<LunarMonth> _lunarMonths = [];

  /// Known solar-month intervals: (sankramana, next sankramana, rashi).
  final List<(double, double, int)> _solarMonths = [];

  static const double _tithiRate = 12.19;
  static const double _moonRate = 13.18;
  static const double _yogaRate = 14.17;
  static const double _sunRate = 0.9856;
  static const double _nakSize = 360.0 / 27.0;

  // --- Dates and time zones ------------------------------------------------

  static int _key(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  static DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  static DateTime addDays(DateTime d, int n) =>
      DateTime.utc(d.year, d.month, d.day + n);

  Duration offsetAtUtc(DateTime utc) =>
      tzOffsetResolver?.call(place, utc) ??
      Duration(minutes: place.fixedOffsetMinutes);

  Duration offsetAt(double jd) => offsetAtUtc(dateTimeFromJd(jd));

  /// Wall-clock time at the place for [jd] (fields are local; isUtc is set
  /// only so that no further conversion happens).
  DateTime wall(double jd) {
    final utc = dateTimeFromJd(jd);
    return utc.add(offsetAtUtc(utc));
  }

  /// Julian Day of local midnight starting civil date [date].
  double localMidnight(DateTime date) {
    final d = dateOnly(date);
    final guess = d.subtract(Duration(minutes: place.fixedOffsetMinutes));
    final off = offsetAtUtc(guess);
    return jdFromDateTime(d.subtract(off));
  }

  /// Julian Day for a wall-clock [local] time at the place.
  double jdFromWall(DateTime local) {
    final asUtc = DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
    );
    final off = offsetAtUtc(
      asUtc.subtract(Duration(minutes: place.fixedOffsetMinutes)),
    );
    return jdFromDateTime(asUtc.subtract(off));
  }

  /// Civil date (local) containing [jd].
  DateTime civilDate(double jd) => dateOnly(wall(jd));

  // --- Sun -----------------------------------------------------------------

  double sunrise(DateTime date) => _sunrises.putIfAbsent(_key(date), () {
    final m = localMidnight(date);
    return sunRiseSet(
          m + 0.25,
          place.lat,
          place.lon,
          rising: true,
          h0: config.sunrise.h0,
        ) ??
        m + 0.25;
  });

  double sunset(DateTime date) => _sunsets.putIfAbsent(_key(date), () {
    final m = localMidnight(date);
    return sunRiseSet(
          m + 0.75,
          place.lat,
          place.lon,
          rising: false,
          h0: config.sunrise.h0,
        ) ??
        m + 0.75;
  });

  /// Civil date whose Hindu day (sunrise to next sunrise) contains [jd].
  DateTime hinduDate(double jd) {
    var d = civilDate(jd);
    if (jd < sunrise(d)) d = addDays(d, -1);
    return d;
  }

  // --- Angles --------------------------------------------------------------

  static double yogaAngle(double jd) {
    final jde = jdeFromJd(jd);
    final ay = lahiriAyanamsa(jde);
    return norm360(sunMean(jde).lon + moonMean(jde).lon - 2 * ay);
  }

  /// Consecutive spans of an increasing angle [f] divided into [count]
  /// segments, covering [a, b).
  static List<Span> spans(
    double Function(double) f,
    int count,
    double rate,
    double a,
    double b,
  ) {
    final seg = 360.0 / count;
    var idx = (f(a) / seg).floor() % count;
    var start = prevCrossing(f, a, idx * seg, rate);
    final out = <Span>[];
    var from = a;
    while (true) {
      final end = nextCrossing(f, from, ((idx + 1) % count) * seg, rate);
      out.add(Span(idx, start, end));
      if (end >= b || out.length > 8) break;
      idx = (idx + 1) % count;
      start = end;
      from = end + 1e-6;
    }
    return out;
  }

  // --- Lunar months ----------------------------------------------------------

  /// Amanta lunar month containing [jd]: named after the rashi the Sun is in
  /// at the opening new moon (+1); adhika when the Sun does not change rashi
  /// between the two new moons.
  LunarMonth lunarMonthAt(double jd) {
    for (final m in _lunarMonths) {
      if (jd >= m.newMoonStart && jd < m.newMoonEnd) return m;
    }
    final nm1 = prevCrossing(elongation, jd, 0, _tithiRate);
    final nm2 = nextCrossing(elongation, nm1 + 20, 0, _tithiRate);
    final r1 = (siderealSun(nm1) / 30).floor();
    final r2 = (siderealSun(nm2) / 30).floor();
    final m = LunarMonth((r1 + 1) % 12, r1 == r2, nm1, nm2);
    _lunarMonths.add(m);
    return m;
  }

  /// All new moons in [a, b).
  List<double> newMoons(double a, double b) {
    final out = <double>[];
    var t = nextCrossing(elongation, a, 0, _tithiRate);
    while (t < b) {
      out.add(t);
      t = nextCrossing(elongation, t + 20, 0, _tithiRate);
    }
    return out;
  }

  // --- Solar months ----------------------------------------------------------

  /// Civil date of day 1 of the solar month that begins at [sankranti].
  DateTime monthStartFor(double sankranti) {
    final c = hinduDate(sankranti);
    final sr = sunrise(c), ss = sunset(c);
    final sameDay = switch (config.solarMonthRule) {
      SolarMonthRule.sunset => sankranti < ss,
      SolarMonthRule.aparahna => sankranti < sr + (ss - sr) * 3 / 5,
      SolarMonthRule.nextDay => false,
    };
    return sameDay ? c : addDays(c, 1);
  }

  /// Sankramana instants in [a, b) as (instant, rashi entered).
  List<(double, int)> sankrantis(double a, double b) {
    final out = <(double, int)>[];
    var r = ((siderealSun(a) / 30).floor() + 1) % 12;
    var t = nextCrossing(siderealSun, a, r * 30.0, _sunRate);
    while (t < b) {
      out.add((t, r));
      r = (r + 1) % 12;
      t = nextCrossing(siderealSun, t + 25, r * 30.0, _sunRate);
    }
    return out;
  }

  /// The sidereal solar month containing [jd]: (sankramana that began it,
  /// the next sankramana, rashi). Cached.
  (double, double, int) solarMonthAt(double jd) {
    for (final m in _solarMonths) {
      if (jd >= m.$1 && jd < m.$2) return m;
    }
    final r = (siderealSun(jd) / 30).floor();
    final a = prevCrossing(siderealSun, jd, r * 30.0, _sunRate);
    final b = nextCrossing(siderealSun, jd, ((r + 1) % 12) * 30.0, _sunRate);
    final m = (a, b, r);
    _solarMonths.add(m);
    return m;
  }

  SolarDate solarDate(DateTime date) {
    final d = dateOnly(date);
    final sr = sunrise(d);
    final (s, nextS, r) = solarMonthAt(sr);
    // A sankramana later today may already make today day 1 of the next
    // month.
    if (nextS < sunrise(addDays(d, 1))) {
      final start = monthStartFor(nextS);
      if (!start.isAfter(d)) {
        return SolarDate(
          month: (r + 1) % 12,
          day: 1,
          monthStart: start,
          sankranti: nextS,
        );
      }
    }
    // Otherwise the month that began at the last sankramana before sunrise
    // (its day 1 can be no later than today).
    final start = monthStartFor(s);
    return SolarDate(
      month: r,
      day: d.difference(start).inDays + 1,
      monthStart: start,
      sankranti: s,
    );
  }

  // --- Days ------------------------------------------------------------------

  static const _rahuPart = [8, 2, 7, 5, 6, 4, 3];
  static const _yamaPart = [5, 4, 3, 2, 1, 7, 6];
  static const _gulikaPart = [7, 6, 5, 4, 3, 2, 1];

  /// Durmuhurta: (day muhurta numbers, night muhurta numbers), 1-based.
  static const _durmuhurta = <(List<int>, List<int>)>[
    ([14], []),
    ([9, 12], []),
    ([4], [7]),
    ([8], []),
    ([6, 12], []),
    ([4, 9], []),
    ([1, 2], []),
  ];

  Kaalas _kaalas(int wd, double sr, double ss, double nsr, double pss) {
    final day = ss - sr;
    final night = nsr - ss;
    final part = day / 8;
    Window p(int n) => Window(sr + (n - 1) * part, sr + n * part);
    final dm = day / 15, nm = night / 15;
    final prevNm = (sr - pss) / 15;
    final dur = _durmuhurta[wd];
    return Kaalas(
      rahu: p(_rahuPart[wd]),
      yamaganda: p(_yamaPart[wd]),
      gulika: p(_gulikaPart[wd]),
      abhijit: Window(sr + 7 * dm, sr + 8 * dm),
      brahma: Window(sr - 2 * prevNm, sr - prevNm),
      durmuhurta: [
        for (final n in dur.$1) Window(sr + (n - 1) * dm, sr + n * dm),
        for (final n in dur.$2) Window(ss + (n - 1) * nm, ss + n * nm),
      ],
      madhyahna: Window(sr + day * 2 / 5, sr + day * 3 / 5),
      aparahna: Window(sr + day * 3 / 5, sr + day * 4 / 5),
      pradosha: Window(ss, ss + night / 5),
      nishita: Window(ss + 7 * nm, ss + 8 * nm),
      arunodaya: Window(sr - 2 * prevNm, sr),
    );
  }

  DayPanchanga day(DateTime date) {
    final d = dateOnly(date);
    final cached = _days[_key(d)];
    if (cached != null) return cached;

    final sr = sunrise(d);
    final ss = sunset(d);
    final nsr = sunrise(addDays(d, 1));
    final pss = sunset(addDays(d, -1));
    // Moonrise/moonset within the Hindu day (sunrise to next sunrise), as in
    // printed panchangas; one after midnight belongs to this day.
    final moon = moonRiseSet(sr, nsr, place.lat, place.lon);
    final wd = d.weekday % 7;

    final naks = spans(siderealMoon, 27, _moonRate, sr, nsr);
    final yogas = spans(yogaAngle, 27, _yogaRate, sr, nsr);
    final karanas = spans(elongation, 60, _tithiRate, sr, nsr);
    // Tithis are pairs of karanas.
    final tithis = <Span>[];
    for (final k in karanas) {
      final t = k.index ~/ 2;
      if (tithis.isNotEmpty && tithis.last.index == t) {
        tithis[tithis.length - 1] = Span(t, tithis.last.start, k.end);
      } else {
        tithis.add(
          Span(
            t,
            k.index.isOdd
                ? prevCrossing(elongation, k.start, t * 12.0, _tithiRate)
                : k.start,
            k.index.isEven
                ? nextCrossing(
                    elongation,
                    k.start + 1e-6,
                    (t + 1) * 12.0 % 360,
                    _tithiRate,
                  )
                : k.end,
          ),
        );
      }
    }
    final rashis = spans(siderealMoon, 12, _moonRate, sr, nsr);
    final moonSid = siderealMoon(sr);
    final pada = ((moonSid % _nakSize) / (_nakSize / 4)).floor() + 1;

    final solar = solarDate(d);
    final (_, nextS, r) = solarMonthAt(sr);

    final result = DayPanchanga(
      date: d,
      weekday: wd,
      sunrise: sr,
      sunset: ss,
      nextSunrise: nsr,
      prevSunset: pss,
      moonrise: moon.rise,
      moonset: moon.set,
      tithis: tithis,
      nakshatras: naks,
      yogas: yogas,
      karanas: karanas,
      moonRashis: rashis,
      sunRashi: r,
      nakshatraPada: pada,
      lunarMonth: lunarMonthAt(sr),
      solar: solar,
      sankrantiToday: nextS < nsr ? nextS : null,
      kaalas: _kaalas(wd, sr, ss, nsr, pss),
    );
    _days[_key(d)] = result;
    return result;
  }

  /// [count] consecutive days starting at [from].
  List<DayPanchanga> days(DateTime from, int count) => [
    for (var i = 0; i < count; i++) day(addDays(from, i)),
  ];
}

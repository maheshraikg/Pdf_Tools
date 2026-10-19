/// Astronomical prayer-time calculation.
///
/// All results are UTC instants. The "day" is the civil date at the place;
/// events are found by iterating the sun position at the event time.
library;

import 'dart:math' as math;

import 'astro.dart';

/// Times shown in the app, in the order of the day.
enum Prayer {
  imsak,
  fajr,
  sunrise,
  ishraq,
  dhuhr,
  asr,
  maghrib,
  isha,
  tahajjud;

  /// The five obligatory prayers (with alerts, iqama and auto-silent).
  bool get isFard =>
      this == fajr ||
      this == dhuhr ||
      this == asr ||
      this == maghrib ||
      this == isha;

  static const List<Prayer> fard = [fajr, dhuhr, asr, maghrib, isha];
}

/// Shadow length used for Asr.
enum AsrMethod {
  /// Shafi'i, Maliki, Hanbali: shadow = object + noon shadow.
  shafii(1),

  /// Hanafi: shadow = 2 × object + noon shadow.
  hanafi(2);

  const AsrMethod(this.shadowFactor);
  final int shadowFactor;
}

/// How Fajr/Isha are limited when the sun does not go deep enough below the
/// horizon (high latitudes in summer).
enum HighLatitudeRule {
  none,
  middleOfNight,
  seventhOfNight,
  angleBased,

  /// The times as calculated; the angle-based part of the night only on
  /// days the angle is never reached (as the original app's tables).
  automatic,
}

/// Parameters of a calculation method.
class CalcMethod {
  const CalcMethod({
    required this.id,
    required this.name,
    required this.fajrAngle,
    this.ishaAngle,
    this.ishaMinutes,
    this.maghribMinutes = 0,
    this.dhuhrMinutes = 0,
    this.asrMinutes = 0,
    this.fajrMinutes = 0,
    this.ishaExtraMinutes = 0,
    this.ramadanIshaMinutes,
    this.maghribAngle,
  }) : assert(ishaAngle != null || ishaMinutes != null);

  final String id;
  final String name;
  final double fajrAngle;

  /// Sun depression angle for Isha, or null when Isha is [ishaMinutes]
  /// after Maghrib.
  final double? ishaAngle;
  final int? ishaMinutes;

  /// Isha minutes after Maghrib in Ramadan, if different.
  final int? ramadanIshaMinutes;

  /// Sun depression angle for Maghrib (Tehran), or null for sunset.
  final double? maghribAngle;

  /// Built-in safety margins (ihtiyat) in minutes.
  final int fajrMinutes;
  final int dhuhrMinutes;
  final int asrMinutes;
  final int maghribMinutes;
  final int ishaExtraMinutes;

  static const kerala = CalcMethod(
    id: 'kerala',
    name: 'Kerala (Samastha-style)',
    // Fitted to 69 published Kerala yearly charts: within 1 min on about
    // 9 days in 10, within 2 min on 19 in 20.
    fajrAngle: 19.8,
    ishaAngle: 18.4,
    dhuhrMinutes: 3,
    asrMinutes: 2,
    maghribMinutes: 3,
  );
  static const karachi = CalcMethod(
    id: 'karachi',
    name: 'University of Islamic Sciences, Karachi',
    fajrAngle: 18,
    ishaAngle: 18,
  );
  static const mwl = CalcMethod(
    id: 'mwl',
    name: 'Muslim World League (MWL)',
    fajrAngle: 18,
    ishaAngle: 17,
  );
  static const ummAlQura = CalcMethod(
    id: 'umm_al_qura',
    name: 'Umm Al-Qura, Makkah',
    fajrAngle: 18.5,
    ishaMinutes: 90,
  );
  static const dubai = CalcMethod(
    id: 'dubai',
    name: 'Dubai (UAE)',
    fajrAngle: 18.2,
    ishaAngle: 18.2,
    dhuhrMinutes: 3,
    asrMinutes: 3,
    maghribMinutes: 3,
  );
  static const qatar = CalcMethod(
    id: 'qatar',
    name: 'Qatar',
    fajrAngle: 18,
    ishaMinutes: 90,
  );
  static const kuwait = CalcMethod(
    id: 'kuwait',
    name: 'Kuwait',
    fajrAngle: 18,
    ishaAngle: 17.5,
  );
  static const egypt = CalcMethod(
    id: 'egypt',
    name: 'Egyptian General Authority of Survey',
    fajrAngle: 19.5,
    ishaAngle: 17.5,
  );
  static const isna = CalcMethod(
    id: 'isna',
    name: 'Islamic Society of North America (ISNA)',
    fajrAngle: 15,
    ishaAngle: 15,
  );

  static const southeastAsia = CalcMethod(
    id: 'sea',
    name: 'Southeast Asia (JAKIM, Kemenag, MUIS)',
    fajrAngle: 20,
    ishaAngle: 18,
  );

  static const tehran = CalcMethod(
    id: 'tehran',
    name: 'Institute of Geophysics, University of Tehran',
    fajrAngle: 17.7,
    ishaAngle: 14,
    maghribAngle: 4.5,
  );

  static const jafari = CalcMethod(
    id: 'jafari',
    name: 'Ithna Ashari (Shia, Jafari)',
    fajrAngle: 16,
    ishaAngle: 14,
    maghribAngle: 4,
  );

  /// The original app's methods in its order, then the regional ones.
  static const List<CalcMethod> all = [
    ummAlQura,
    jafari,
    karachi,
    isna,
    mwl,
    egypt,
    tehran,
    kerala,
    dubai,
    qatar,
    kuwait,
    southeastAsia,
  ];

  static CalcMethod byId(String? id) =>
      all.firstWhere((m) => m.id == id, orElse: () => kerala);
}

/// Everything needed to compute times for a place.
class CalcParams {
  const CalcParams({
    this.method = CalcMethod.kerala,
    this.asr = AsrMethod.shafii,
    this.highLatitude = HighLatitudeRule.automatic,
    this.adjustments = const {},
    this.imsakMinutesBeforeFajr = 10,
    this.ishraqMinutesAfterSunrise = 15,
  });

  final CalcMethod method;
  final AsrMethod asr;
  final HighLatitudeRule highLatitude;

  /// User adjustments in minutes per time (added after the method margins).
  final Map<Prayer, int> adjustments;
  final int imsakMinutesBeforeFajr;
  final int ishraqMinutesAfterSunrise;

  CalcParams copyWith({
    CalcMethod? method,
    AsrMethod? asr,
    HighLatitudeRule? highLatitude,
    Map<Prayer, int>? adjustments,
    int? imsakMinutesBeforeFajr,
    int? ishraqMinutesAfterSunrise,
  }) => CalcParams(
    method: method ?? this.method,
    asr: asr ?? this.asr,
    highLatitude: highLatitude ?? this.highLatitude,
    adjustments: adjustments ?? this.adjustments,
    imsakMinutesBeforeFajr:
        imsakMinutesBeforeFajr ?? this.imsakMinutesBeforeFajr,
    ishraqMinutesAfterSunrise:
        ishraqMinutesAfterSunrise ?? this.ishraqMinutesAfterSunrise,
  );
}

/// The six basic times of one day as UTC instants (unrounded).
class BasicTimes {
  const BasicTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha;
}

/// Computes [BasicTimes] for the civil date [year]-[month]-[day] at a place.
///
/// The formula is PrayTimes (praytimes.org 2.3) with its single pass from
/// the default times: the one the original app uses, so its world tables
/// come out the same to the minute.
///
/// [ramadan] switches the Isha interval of methods that have one for
/// Ramadan. Method margins are included; user adjustments are not.
///
/// [utcOffsetMinutes] is the place's clock offset; it picks the solar day
/// whose noon falls on that civil date. Without it, places whose clocks are
/// far from their longitude (Samoa, Kiribati: UTC+13/+14 west of the date
/// line) would get the neighbouring day.
///
/// Where the sun does not rise or set that day (polar day or night), the
/// times of the nearest latitude where it does (±65°) are used.
BasicTimes computeBasicTimes({
  required int year,
  required int month,
  required int day,
  required double latitude,
  required double longitude,
  double elevation = 0,
  CalcParams params = const CalcParams(),
  bool ramadan = false,
  int? utcOffsetMinutes,
}) {
  final m = params.method;
  final riseSet = 0.833 + 0.0347 * math.sqrt(elevation.clamp(0, 9000));
  // Whole days to move so that local noon falls on the requested date.
  final dayShift = utcOffsetMinutes == null
      ? 0
      : -24 * ((12 - longitude / 15 + utcOffsetMinutes / 60) / 24).floor();
  final jDate = julianDay(year, month, day) - longitude / 360;

  // Local solar hours; [t] is the default time of the event as a day
  // fraction.
  double midDay(double t) => _fixHour(12 - _sun(jDate + t).eqt);
  double angleTime(double angle, double t, {bool before = false}) {
    final sun = _sun(jDate + t);
    final x =
        (-sinD(angle) - sinD(sun.decl) * sinD(latitude)) /
        (cosD(sun.decl) * cosD(latitude));
    if (x.isNaN || x < -1 || x > 1) return double.nan;
    final h = acosD(x) / 15;
    return midDay(t) + (before ? -h : h);
  }

  final sunrise = angleTime(riseSet, 6 / 24, before: true);
  final sunset = angleTime(riseSet, 18 / 24);
  // Polar day or night: the times that cannot be found come from ±65°.
  final polar = (sunrise.isNaN || sunset.isNaN) && latitude.abs() > 65
      ? computeBasicTimes(
          year: year,
          month: month,
          day: day,
          latitude: latitude.sign * 65,
          longitude: longitude,
          elevation: elevation,
          params: params,
          ramadan: ramadan,
          utcOffsetMinutes: utcOffsetMinutes,
        )
      : null;
  final noon = midDay(12 / 24);
  final rise = sunrise.isNaN ? noon - 6 : sunrise;
  final set = sunset.isNaN ? noon + 6 : sunset;
  final asrDecl = _sun(jDate + 13 / 24).decl;
  var asr = angleTime(
    -atanD(1 / (params.asr.shadowFactor + tanD((latitude - asrDecl).abs()))),
    13 / 24,
  );
  if (asr.isNaN && polar == null) asr = (noon + set) / 2;
  var fajr = angleTime(m.fajrAngle, 5 / 24, before: true);
  final ishaMinutes = ramadan && m.ramadanIshaMinutes != null
      ? m.ramadanIshaMinutes
      : m.ishaMinutes;
  var isha = ishaMinutes == null ? angleTime(m.ishaAngle!, 18 / 24) : 0.0;
  var maghrib = m.maghribAngle == null
      ? set
      : angleTime(m.maghribAngle!, 18 / 24);

  // High latitudes: the part of the night (sunset → sunrise) an angle may
  // take. "Automatic" only steps in where the angle is never reached.
  final night = _fixHour(rise - set);
  double limit(double base, double t, double angle, {bool before = false}) {
    // No night to share out on a polar day or night.
    if (polar != null) return t;
    final portion = switch (params.highLatitude) {
      HighLatitudeRule.none => double.nan,
      HighLatitudeRule.middleOfNight => night / 2,
      HighLatitudeRule.seventhOfNight => night / 7,
      HighLatitudeRule.angleBased ||
      HighLatitudeRule.automatic => angle / 60 * night,
    };
    if (portion.isNaN || params.highLatitude == HighLatitudeRule.automatic) {
      if (!t.isNaN) return t;
      final p = angle / 60 * night;
      return before ? base - p : base + p;
    }
    final diff = _fixHour(before ? base - t : t - base);
    if (t.isNaN || diff > portion) {
      return before ? base - portion : base + portion;
    }
    return t;
  }

  fajr = limit(rise, fajr, m.fajrAngle, before: true);
  if (ishaMinutes == null) isha = limit(set, isha, m.ishaAngle!);
  if (m.maghribAngle != null) maghrib = limit(set, maghrib, m.maghribAngle!);
  if (polar == null) {
    if (fajr.isNaN) fajr = rise - 1.5;
    if (isha.isNaN) isha = set + 1.5;
    if (maghrib.isNaN) maghrib = set;
  }
  maghrib += m.maghribMinutes / 60;
  if (ishaMinutes != null) isha = maghrib + ishaMinutes / 60;

  final base = DateTime.utc(year, month, day);
  final toUtc = dayShift - longitude / 15;
  DateTime at(double hours, int marginMinutes, DateTime? instead) =>
      hours.isNaN && instead != null
      ? instead
      : base.add(
          Duration(
            milliseconds: ((hours + toUtc + marginMinutes / 60) * 3600000)
                .round(),
          ),
        );
  final times = BasicTimes(
    fajr: at(fajr, m.fajrMinutes, polar?.fajr),
    sunrise: at(sunrise, 0, polar?.sunrise),
    dhuhr: at(noon, m.dhuhrMinutes, null),
    asr: at(asr, m.asrMinutes, polar?.asr),
    maghrib: at(maghrib, 0, polar?.maghrib),
    isha: at(isha, m.ishaExtraMinutes, polar?.isha),
  );
  // Mixed with ±65° the day must still be in order; else all from there.
  if (polar != null) {
    final t = [
      times.fajr,
      times.sunrise,
      times.dhuhr,
      times.asr,
      times.maghrib,
      times.isha,
    ];
    for (var i = 1; i < t.length; i++) {
      if (!t[i].isAfter(t[i - 1])) return polar;
    }
  }
  return times;
}

double _fix(double a, double b) {
  final r = a - b * (a / b).floor();
  return r < 0 ? r + b : r;
}

double _fixHour(double h) => h.isNaN ? h : _fix(h, 24);

/// Sun declination and equation of time (hours), PrayTimes' short formula.
({double decl, double eqt}) _sun(double jd) {
  final d = jd - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * d, 360);
  final q = _fix(280.459 + 0.98564736 * d, 360);
  final l = _fix(q + 1.915 * sinD(g) + 0.020 * sinD(2 * g), 360);
  final e = 23.439 - 0.00000036 * d;
  final ra = atan2D(cosD(e) * sinD(l), cosD(l)) / 15;
  return (decl: asinD(sinD(e) * sinD(l)), eqt: q / 15 - _fix(ra, 24));
}

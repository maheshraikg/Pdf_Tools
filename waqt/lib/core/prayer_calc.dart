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
enum HighLatitudeRule { none, middleOfNight, seventhOfNight, angleBased }

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
  }) : assert(ishaAngle != null || ishaMinutes != null);

  final String id;
  final String name;
  final double fajrAngle;

  /// Sun depression angle for Isha, or null when Isha is [ishaMinutes]
  /// after Maghrib.
  final double? ishaAngle;
  final int? ishaMinutes;

  /// Isha minutes after Maghrib in Ramadan (Umm al-Qura), if different.
  final int? ramadanIshaMinutes;

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
    name: 'Muslim World League',
    fajrAngle: 18,
    ishaAngle: 17,
  );
  static const ummAlQura = CalcMethod(
    id: 'umm_al_qura',
    name: 'Umm al-Qura, Makkah',
    fajrAngle: 18.5,
    ishaMinutes: 90,
    ramadanIshaMinutes: 120,
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
    name: 'ISNA (North America)',
    fajrAngle: 15,
    ishaAngle: 15,
  );

  static const southeastAsia = CalcMethod(
    id: 'sea',
    name: 'Southeast Asia (JAKIM, Kemenag, MUIS)',
    fajrAngle: 20,
    ishaAngle: 18,
  );

  static const List<CalcMethod> all = [
    kerala,
    karachi,
    mwl,
    ummAlQura,
    dubai,
    qatar,
    kuwait,
    egypt,
    isna,
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
    this.highLatitude = HighLatitudeRule.angleBased,
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
/// [ramadan] switches Umm al-Qura's Isha interval. Method margins are
/// included; user adjustments are not.
BasicTimes computeBasicTimes({
  required int year,
  required int month,
  required int day,
  required double latitude,
  required double longitude,
  double elevation = 0,
  CalcParams params = const CalcParams(),
  bool ramadan = false,
}) {
  final jd0 = julianDay(year, month, day);
  final m = params.method;
  final horizon = 0.833 + 0.0347 * math.sqrt(elevation.clamp(0, 9000));

  // Hours (UTC) of solar noon and of the given hour angle, iterated so the
  // sun position is taken at the event itself.
  double noonAt(double t) {
    final eqt = sunPosition(jd0 + t / 24).equationOfTime;
    return 12 - longitude / 15 - eqt;
  }

  double? event(
    double approx,
    double Function(double dec) altitude,
    int direction,
  ) {
    var t = approx;
    for (var i = 0; i < 3; i++) {
      final dec = sunPosition(jd0 + t / 24).declination;
      final noon = noonAt(t);
      final alt = altitude(dec);
      final x =
          (sinD(alt) - sinD(latitude) * sinD(dec)) /
          (cosD(latitude) * cosD(dec));
      if (x.isNaN || x < -1 || x > 1) return null;
      t = noon + direction * acosD(x) / 15;
    }
    return t;
  }

  double noon = 12 - longitude / 15;
  for (var i = 0; i < 3; i++) {
    noon = noonAt(noon);
  }
  final sunrise = event(noon - 6, (_) => -horizon, -1) ?? noon - 6;
  final sunset = event(noon + 6, (_) => -horizon, 1) ?? noon + 6;
  final asrT =
      event(noon + 3.5, (dec) {
        final f = params.asr.shadowFactor;
        return atanD(1 / (f + tanD((latitude - dec).abs())));
      }, 1) ??
      (noon + sunset) / 2;
  var fajr = event(sunrise - 1.5, (_) => -m.fajrAngle, -1);
  double? isha;
  final ishaMinutes = ramadan && m.ramadanIshaMinutes != null
      ? m.ramadanIshaMinutes
      : m.ishaMinutes;
  if (ishaMinutes == null) {
    isha = event(sunset + 1.5, (_) => -m.ishaAngle!, 1);
  }

  // High-latitude limits, measured on the night sunset → next sunrise.
  final night = 24 - (sunset - sunrise);
  double portion(double angle) => switch (params.highLatitude) {
    HighLatitudeRule.none => double.infinity,
    HighLatitudeRule.middleOfNight => 0.5,
    HighLatitudeRule.seventhOfNight => 1 / 7,
    HighLatitudeRule.angleBased => angle / 60,
  };
  final fajrLimit = portion(m.fajrAngle) * night;
  if (fajr == null || sunrise - fajr > fajrLimit) {
    fajr = fajrLimit.isFinite ? sunrise - fajrLimit : sunrise - 1.5;
  }
  final maghrib = sunset + m.maghribMinutes / 60;
  if (ishaMinutes != null) {
    isha = maghrib + ishaMinutes / 60;
  } else {
    final ishaLimit = portion(m.ishaAngle!) * night;
    if (isha == null || isha - sunset > ishaLimit) {
      isha = ishaLimit.isFinite ? sunset + ishaLimit : sunset + 1.5;
    }
  }

  final base = DateTime.utc(year, month, day);
  DateTime at(double hours, int marginMinutes) => base.add(
    Duration(milliseconds: ((hours + marginMinutes / 60) * 3600000).round()),
  );
  return BasicTimes(
    fajr: at(fajr, m.fajrMinutes),
    sunrise: at(sunrise, 0),
    dhuhr: at(noon, m.dhuhrMinutes),
    asr: at(asrT, m.asrMinutes),
    maghrib: at(maghrib, 0),
    isha: at(isha, m.ishaExtraMinutes),
  );
}

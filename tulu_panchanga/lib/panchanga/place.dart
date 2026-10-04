/// Locations and the conventions that change panchanga results.
library;

import 'names.dart';

/// A place on Earth. [tz] is an IANA zone name; [fixedOffsetMinutes] is used
/// when no time-zone database is available (pure-Dart tools and tests) and is
/// exact for India, which has no daylight saving.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.tz = 'Asia/Kolkata',
    this.fixedOffsetMinutes = 330,
  });

  final String id;
  final Name name;
  final double lat;

  /// East longitude, degrees.
  final double lon;
  final String tz;
  final int fixedOffsetMinutes;

  Map<String, Object> toJson() => {
        'id': id,
        'en': name.en,
        'kn': name.kn,
        'lat': lat,
        'lon': lon,
        'tz': tz,
        'off': fixedOffsetMinutes,
      };

  static Place fromJson(Map<String, dynamic> j) => Place(
        id: j['id'] as String,
        name: Name(j['en'] as String, j['kn'] as String),
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
        tz: j['tz'] as String? ?? 'Asia/Kolkata',
        fixedOffsetMinutes: j['off'] as int? ?? 330,
      );

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.id == id &&
      other.lat == lat &&
      other.lon == lon &&
      other.tz == tz;

  @override
  int get hashCode => Object.hash(id, lat, lon, tz);
}

/// Preset places: Tulunadu towns first, then cities with large Tulu
/// communities. Coordinates are town centres (WGS84).
const List<Place> presetPlaces = [
  Place(
      id: 'mangaluru',
      name: Name('Mangaluru', 'ಮಂಗಳೂರು', 'ಕುಡ್ಲ'),
      lat: 12.9141,
      lon: 74.8560),
  Place(
      id: 'udupi',
      name: Name('Udupi', 'ಉಡುಪಿ', 'ಒಡಿಪು'),
      lat: 13.3409,
      lon: 74.7421),
  Place(
      id: 'kundapura',
      name: Name('Kundapura', 'ಕುಂದಾಪುರ'),
      lat: 13.6269,
      lon: 74.6907),
  Place(
      id: 'karkala',
      name: Name('Karkala', 'ಕಾರ್ಕಳ'),
      lat: 13.2140,
      lon: 74.9940),
  Place(
      id: 'moodbidri',
      name: Name('Moodbidri', 'ಮೂಡುಬಿದಿರೆ', 'ಬೆದ್ರ'),
      lat: 13.0680,
      lon: 74.9950),
  Place(
      id: 'puttur',
      name: Name('Puttur', 'ಪುತ್ತೂರು'),
      lat: 12.7593,
      lon: 75.2010),
  Place(
      id: 'bantwal',
      name: Name('Bantwal', 'ಬಂಟ್ವಾಳ'),
      lat: 12.8930,
      lon: 75.0340),
  Place(
      id: 'belthangady',
      name: Name('Belthangady', 'ಬೆಳ್ತಂಗಡಿ'),
      lat: 12.9930,
      lon: 75.3040),
  Place(
      id: 'sullia',
      name: Name('Sullia', 'ಸುಳ್ಯ'),
      lat: 12.5590,
      lon: 75.3880),
  Place(
      id: 'kasaragod',
      name: Name('Kasaragod', 'ಕಾಸರಗೋಡು'),
      lat: 12.4996,
      lon: 74.9869),
  Place(
      id: 'bengaluru',
      name: Name('Bengaluru', 'ಬೆಂಗಳೂರು'),
      lat: 12.9716,
      lon: 77.5946),
  Place(
      id: 'mumbai',
      name: Name('Mumbai', 'ಮುಂಬಯಿ', 'ಬೊಂಬಾಯಿ'),
      lat: 19.0760,
      lon: 72.8777),
  Place(
      id: 'dubai',
      name: Name('Dubai', 'ದುಬೈ'),
      lat: 25.2048,
      lon: 55.2708,
      tz: 'Asia/Dubai',
      fixedOffsetMinutes: 240),
];

Place placeById(String id) =>
    presetPlaces.firstWhere((p) => p.id == id, orElse: () => presetPlaces[0]);

/// How sunrise/sunset are defined.
enum SunriseConvention {
  /// Upper limb touching the horizon with standard refraction (−0.833°).
  /// Used by most modern printed panchangas and drikpanchang.com.
  upperLimb(-0.8333),

  /// Centre of the disc on the geometric horizon, no refraction (the
  /// traditional Surya-Siddhanta style definition).
  discCentre(0.0);

  const SunriseConvention(this.h0);
  final double h0;
}

/// Which civil day is day 1 of a solar (Tulu) month.
enum SolarMonthRule {
  /// Sankramana before sunset → that day is day 1, else the next day.
  sunset,

  /// Sankramana before the end of madhyahna (3/5 of daytime) → that day,
  /// else the next day (Kerala / Malayalam calendar rule).
  aparahna,

  /// The month always begins the day after the sankramana day.
  nextDay,
}

/// When two consecutive days both have the festival tithi during the whole
/// required kaala, which day is chosen.
enum TiePreference { first, second }

class PanchangaConfig {
  const PanchangaConfig({
    this.sunrise = SunriseConvention.upperLimb,
    this.solarMonthRule = SolarMonthRule.sunset,
    this.tiePreference = TiePreference.first,
  });

  final SunriseConvention sunrise;
  final SolarMonthRule solarMonthRule;
  final TiePreference tiePreference;

  PanchangaConfig copyWith({
    SunriseConvention? sunrise,
    SolarMonthRule? solarMonthRule,
    TiePreference? tiePreference,
  }) =>
      PanchangaConfig(
        sunrise: sunrise ?? this.sunrise,
        solarMonthRule: solarMonthRule ?? this.solarMonthRule,
        tiePreference: tiePreference ?? this.tiePreference,
      );

  @override
  bool operator ==(Object other) =>
      other is PanchangaConfig &&
      other.sunrise == sunrise &&
      other.solarMonthRule == solarMonthRule &&
      other.tiePreference == tiePreference;

  @override
  int get hashCode => Object.hash(sunrise, solarMonthRule, tiePreference);
}

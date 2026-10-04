/// Pure-Dart positional astronomy used by the panchanga engine.
///
/// * Sun: VSOP87D (Earth) — accurate to about one arc-second.
/// * Moon: Meeus, "Astronomical Algorithms" ch. 47 (truncated ELP-2000/82) —
///   about 10" in longitude, i.e. tithi/nakshatra end times good to well
///   under a minute.
/// * Nutation: IAU 1980, Meeus ch. 22 low-precision form (0.5").
/// * Ayanamsa: Lahiri (Chitrapaksha), see [lahiriAyanamsa].
///
/// All instants are Julian Days in Universal Time ("jd"); the engine converts
/// to Terrestrial Time internally with [deltaTSeconds].
library;

import 'dart:math' as math;

import 'tables.dart';

const double _deg = math.pi / 180.0;
const double _rad = 180.0 / math.pi;

/// Normalises [a] degrees to [0, 360).
double norm360(double a) {
  final r = a % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// Normalises [a] degrees to (-180, 180].
double norm180(double a) {
  final r = norm360(a);
  return r > 180.0 ? r - 360.0 : r;
}

// ---------------------------------------------------------------------------
// Time
// ---------------------------------------------------------------------------

/// Julian Day (UT) for a UTC [DateTime].
double jdFromDateTime(DateTime t) {
  final u = t.toUtc();
  return u.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
}

/// UTC [DateTime] for a Julian Day (UT), rounded to the millisecond.
DateTime dateTimeFromJd(double jd) => DateTime.fromMillisecondsSinceEpoch(
    ((jd - 2440587.5) * 86400000.0).round(),
    isUtc: true);

/// ΔT = TT − UT in seconds.
///
/// 2000–2100: yearly/decadal values matching the Swiss Ephemeris (observed
/// to 2025, its extrapolation after), so times agree with panchangas computed
/// with it. Outside that, the Espenak & Meeus (NASA) polynomials. The effect
/// on displayed times is a few seconds at most.
double deltaTSeconds(double year) {
  if (year >= 2000 && year < 2100) {
    final i = _dtYears.lastIndexWhere((y) => y <= year);
    final f = (year - _dtYears[i]) / (_dtYears[i + 1] - _dtYears[i]);
    return _dtValues[i] + (_dtValues[i + 1] - _dtValues[i]) * f;
  }
  if (year >= 2100 && year < 2150) {
    final u = (year - 1820) / 100;
    return -20 + 32 * u * u - 0.5628 * (2150 - year);
  }
  if (year >= 1986 && year < 2000) {
    final t = year - 2000;
    return 63.86 +
        0.3345 * t -
        0.060374 * t * t +
        0.0017275 * t * t * t +
        0.000651814 * t * t * t * t +
        0.00002373599 * t * t * t * t * t;
  }
  if (year >= 1961 && year < 1986) {
    final t = year - 1975;
    return 45.45 + 1.067 * t - t * t / 260 - t * t * t / 718;
  }
  if (year >= 1941 && year < 1961) {
    final t = year - 1950;
    return 29.07 + 0.407 * t - t * t / 233 + t * t * t / 2547;
  }
  if (year >= 1920 && year < 1941) {
    final t = year - 1920;
    return 21.20 + 0.84493 * t - 0.076100 * t * t + 0.0020936 * t * t * t;
  }
  if (year >= 1900 && year < 1920) {
    final t = year - 1900;
    return -2.79 +
        1.494119 * t -
        0.0598939 * t * t +
        0.0061966 * t * t * t -
        0.000197 * t * t * t * t;
  }
  final u = (year - 1820) / 100;
  return -20 + 32 * u * u;
}

const List<double> _dtYears = [
  2000, 2002, 2004, 2006, 2008, 2010, 2012, 2014, 2016, 2018, 2020, 2022, //
  2024, 2026, 2028, 2030, 2035, 2040, 2050, 2060, 2075, 2100,
];
const List<double> _dtValues = [
  63.83, 64.30, 64.57, 64.85, 65.46, 66.07, 66.60, 67.28, 68.10, 68.97, 69.36, 69.29, 69.10, 68.90, 68.80, 69.28, 70.51, 71.80, 74.58, 77.64, 82.81, 93.18,
];

/// Julian Ephemeris Day (TT) for a Julian Day (UT).
double jdeFromJd(double jd) {
  final year = 2000.0 + (jd - 2451545.0) / 365.25;
  return jd + deltaTSeconds(year) / 86400.0;
}

// ---------------------------------------------------------------------------
// Nutation and obliquity
// ---------------------------------------------------------------------------

/// Nutation in longitude and obliquity (degrees) for Julian centuries [t]
/// (TT) since J2000.
({double dPsi, double dEps}) nutation(double t) {
  final om = (125.04452 - 1934.136261 * t) * _deg;
  final ls = (280.4665 + 36000.7698 * t) * _deg;
  final lm = (218.3165 + 481267.8813 * t) * _deg;
  final dPsi = -17.20 * math.sin(om) -
      1.32 * math.sin(2 * ls) -
      0.23 * math.sin(2 * lm) +
      0.21 * math.sin(2 * om);
  final dEps = 9.20 * math.cos(om) +
      0.57 * math.cos(2 * ls) +
      0.10 * math.cos(2 * lm) -
      0.09 * math.cos(2 * om);
  return (dPsi: dPsi / 3600.0, dEps: dEps / 3600.0);
}

/// Mean obliquity of the ecliptic (degrees).
double meanObliquity(double t) =>
    23.4392911111 -
    (46.8150 * t + 0.00059 * t * t - 0.001813 * t * t * t) / 3600.0;

// ---------------------------------------------------------------------------
// Sun
// ---------------------------------------------------------------------------

double _vsop(List<List<List<double>>> series, double tau) {
  var sum = 0.0;
  var tp = 1.0;
  for (final power in series) {
    var s = 0.0;
    for (final term in power) {
      s += term[0] * math.cos(term[1] + term[2] * tau);
    }
    sum += s * tp;
    tp *= tau;
  }
  return sum * 1e-8;
}

/// Geocentric ecliptic longitude of the Sun (degrees, mean equinox of date,
/// including aberration but excluding nutation) and its distance in AU, for
/// the given Julian Ephemeris Day.
({double lon, double r}) sunMean(double jde) {
  final tau = (jde - 2451545.0) / 365250.0;
  final l = _vsop(vsopEarthL, tau) * _rad;
  final r = _vsop(vsopEarthR, tau);
  // Geocentric = heliocentric + 180°, FK5 correction −0.09033",
  // aberration −20.4898"/R.
  final lon = norm360(l + 180.0 - 0.09033 / 3600.0 - 20.4898 / 3600.0 / r);
  return (lon: lon, r: r);
}

// ---------------------------------------------------------------------------
// Moon
// ---------------------------------------------------------------------------

/// Geocentric ecliptic longitude and latitude of the Moon (degrees, mean
/// equinox of date, no nutation) and distance (km) for the given JDE.
({double lon, double lat, double dist}) moonMean(double jde) {
  final t = (jde - 2451545.0) / 36525.0;
  final t2 = t * t, t3 = t2 * t, t4 = t3 * t;
  final lp = norm360(218.3164477 +
      481267.88123421 * t -
      0.0015786 * t2 +
      t3 / 538841.0 -
      t4 / 65194000.0);
  final d = norm360(297.8501921 +
      445267.1114034 * t -
      0.0018819 * t2 +
      t3 / 545868.0 -
      t4 / 113065000.0);
  final m = norm360(
      357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000.0);
  final mp = norm360(134.9633964 +
      477198.8675055 * t +
      0.0087414 * t2 +
      t3 / 69699.0 -
      t4 / 14712000.0);
  final f = norm360(93.2720950 +
      483202.0175233 * t -
      0.0036539 * t2 -
      t3 / 3526000.0 +
      t4 / 863310000.0);
  final a1 = norm360(119.75 + 131.849 * t) * _deg;
  final a2 = norm360(53.09 + 479264.290 * t) * _deg;
  final a3 = norm360(313.45 + 481266.484 * t) * _deg;
  final e = 1.0 - 0.002516 * t - 0.0000074 * t2;
  final e2 = e * e;

  var sl = 0.0, sr = 0.0, sb = 0.0;
  for (final row in moonLR) {
    final arg = (row[0] * d + row[1] * m + row[2] * mp + row[3] * f) * _deg;
    final mm = row[1].abs();
    final k = mm == 1 ? e : (mm == 2 ? e2 : 1.0);
    sl += row[4] * k * math.sin(arg);
    sr += row[5] * k * math.cos(arg);
  }
  for (final row in moonB) {
    final arg = (row[0] * d + row[1] * m + row[2] * mp + row[3] * f) * _deg;
    final mm = row[1].abs();
    final k = mm == 1 ? e : (mm == 2 ? e2 : 1.0);
    sb += row[4] * k * math.sin(arg);
  }
  final lpr = lp * _deg, fr = f * _deg, mpr = mp * _deg;
  sl += 3958 * math.sin(a1) + 1962 * math.sin(lpr - fr) + 318 * math.sin(a2);
  sb += -2235 * math.sin(lpr) +
      382 * math.sin(a3) +
      175 * math.sin(a1 - fr) +
      175 * math.sin(a1 + fr) +
      127 * math.sin(lpr - mpr) -
      115 * math.sin(lpr + mpr);
  return (
    lon: norm360(lp + sl / 1e6),
    lat: sb / 1e6,
    dist: 385000.56 + sr / 1000.0,
  );
}

// ---------------------------------------------------------------------------
// Ayanamsa and sidereal longitudes
// ---------------------------------------------------------------------------

/// Mean Lahiri (Chitrapaksha) ayanamsa in degrees for a JDE.
///
/// Fitted to the Swiss Ephemeris `SIDM_LAHIRI` mean ayanamsa; agrees to
/// better than 0.5" over 1900–2100 (see test/astro_test.dart).
double lahiriAyanamsa(double jde) {
  final t = (jde - 2451545.0) / 36525.0;
  return 23.8570923 + 1.39688794 * t + 0.000307096 * t * t;
}

/// Tropical (mean-equinox) longitudes of Sun and Moon at Julian Day [jd] (UT).
({double sun, double moon}) tropicalSunMoon(double jd) {
  final jde = jdeFromJd(jd);
  return (sun: sunMean(jde).lon, moon: moonMean(jde).lon);
}

/// Sidereal (Lahiri) longitude of the Sun at [jd] (UT).
double siderealSun(double jd) {
  final jde = jdeFromJd(jd);
  return norm360(sunMean(jde).lon - lahiriAyanamsa(jde));
}

/// Sidereal (Lahiri) longitude of the Moon at [jd] (UT).
double siderealMoon(double jd) {
  final jde = jdeFromJd(jd);
  return norm360(moonMean(jde).lon - lahiriAyanamsa(jde));
}

/// Moon − Sun elongation (degrees, 0..360) at [jd]. Independent of ayanamsa.
double elongation(double jd) {
  final jde = jdeFromJd(jd);
  return norm360(moonMean(jde).lon - sunMean(jde).lon);
}

// ---------------------------------------------------------------------------
// Equatorial coordinates, sidereal time, rising and setting
// ---------------------------------------------------------------------------

/// Greenwich apparent sidereal time (degrees) at [jd] (UT).
double greenwichSiderealTime(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  final gmst = 280.46061837 +
      360.98564736629 * (jd - 2451545.0) +
      0.000387933 * t * t -
      t * t * t / 38710000.0;
  final tt = (jdeFromJd(jd) - 2451545.0) / 36525.0;
  final n = nutation(tt);
  final eps = meanObliquity(tt) + n.dEps;
  return norm360(gmst + n.dPsi * math.cos(eps * _deg));
}

({double ra, double dec}) _toEquatorial(double lon, double lat, double eps) {
  final l = lon * _deg, b = lat * _deg, e = eps * _deg;
  final ra = math.atan2(
      math.sin(l) * math.cos(e) - math.tan(b) * math.sin(e), math.cos(l));
  final dec = math.asin(
      math.sin(b) * math.cos(e) + math.cos(b) * math.sin(e) * math.sin(l));
  return (ra: norm360(ra * _rad), dec: dec * _rad);
}

/// Apparent right ascension / declination of the Sun at [jd] (UT).
({double ra, double dec}) sunEquatorial(double jd) {
  final jde = jdeFromJd(jd);
  final t = (jde - 2451545.0) / 36525.0;
  final n = nutation(t);
  final s = sunMean(jde);
  return _toEquatorial(s.lon + n.dPsi, 0, meanObliquity(t) + n.dEps);
}

/// Apparent RA/Dec of the Moon and its horizontal parallax (deg) at [jd].
({double ra, double dec, double parallax}) moonEquatorial(double jd) {
  final jde = jdeFromJd(jd);
  final t = (jde - 2451545.0) / 36525.0;
  final n = nutation(t);
  final m = moonMean(jde);
  final eq = _toEquatorial(m.lon + n.dPsi, m.lat, meanObliquity(t) + n.dEps);
  final par = math.asin(6378.14 / m.dist) * _rad;
  return (ra: eq.ra, dec: eq.dec, parallax: par);
}

/// Altitude (degrees) of a body with the given RA/Dec at [jd] for an observer
/// at [lat]/[lon] (east positive).
double altitude(double jd, double ra, double dec, double lat, double lon) {
  final h = (greenwichSiderealTime(jd) + lon - ra) * _deg;
  final p = lat * _deg, d = dec * _deg;
  return math.asin(math.sin(p) * math.sin(d) +
          math.cos(p) * math.cos(d) * math.cos(h)) *
      _rad;
}

/// Standard altitude used for sunrise/sunset: centre of the disc ([h0] = 0)
/// or upper limb with refraction ([h0] = −0.8333).
///
/// Finds the Sun's rising (or setting when [rising] is false) closest to the
/// initial guess [jdGuess] by iterating on the hour angle. Returns null for
/// polar day/night.
double? sunRiseSet(double jdGuess, double lat, double lon,
    {required bool rising, double h0 = -0.8333}) {
  var t = jdGuess;
  for (var i = 0; i < 8; i++) {
    final eq = sunEquatorial(t);
    final p = lat * _deg, d = eq.dec * _deg;
    final cosH0 =
        (math.sin(h0 * _deg) - math.sin(p) * math.sin(d)) /
            (math.cos(p) * math.cos(d));
    if (cosH0 < -1 || cosH0 > 1) return null;
    final h0Angle = math.acos(cosH0) * _rad;
    final target = rising ? -h0Angle : h0Angle;
    final h = norm180(greenwichSiderealTime(t) + lon - eq.ra);
    final dt = norm180(target - h) / 360.985647;
    t += dt;
    if (dt.abs() < 1e-7) break;
  }
  return t;
}

/// Moonrise and moonset within [jdStart, jdEnd), found by stepping the
/// altitude in 20-minute steps and bisecting each sign change. Either may be
/// null (the Moon does not rise or set every civil day).
({double? rise, double? set}) moonRiseSet(
    double jdStart, double jdEnd, double lat, double lon) {
  double alt(double t) {
    final m = moonEquatorial(t);
    // Upper limb with refraction, corrected for parallax.
    final h0 = 0.7275 * m.parallax - 0.5667;
    return altitude(t, m.ra, m.dec, lat, lon) - h0;
  }

  double? rise, set;
  const step = 20.0 / 1440.0;
  var t0 = jdStart;
  var a0 = alt(t0);
  while (t0 < jdEnd && (rise == null || set == null)) {
    final t1 = math.min(t0 + step, jdEnd);
    final a1 = alt(t1);
    if ((a0 < 0) != (a1 < 0)) {
      var lo = t0, hi = t1, alo = a0;
      for (var i = 0; i < 30; i++) {
        final mid = (lo + hi) / 2;
        final am = alt(mid);
        if ((am < 0) == (alo < 0)) {
          lo = mid;
          alo = am;
        } else {
          hi = mid;
        }
      }
      final tc = (lo + hi) / 2;
      if (a0 < 0) {
        rise ??= tc;
      } else {
        set ??= tc;
      }
    }
    t0 = t1;
    a0 = a1;
  }
  return (rise: rise, set: set);
}

// ---------------------------------------------------------------------------
// Searching for angle crossings
// ---------------------------------------------------------------------------

/// Newton iteration for the instant near [guess] at which the increasing
/// angle [f] (degrees, wrapping at 360) equals [target]. Converges to the
/// crossing whose angular distance from the guess is under 180°.
double crossingNear(double Function(double jd) f, double guess, double target,
    double rate) {
  var t = guess;
  const h = 1.0 / 1440.0;
  for (var i = 0; i < 50; i++) {
    final diff = norm180(target - f(t));
    var r = norm180(f(t + h) - f(t - h)) / (2 * h);
    if (r <= 0) r = rate;
    var dt = diff / r;
    final maxStep = 90.0 / rate;
    if (dt.abs() > maxStep) dt = dt.sign * maxStep;
    t += dt;
    if (dt.abs() < 1e-9) break;
  }
  return t;
}

/// First instant ≥ [jdStart] at which the increasing angle [f] reaches
/// [target]. [rate] is its approximate mean rate in degrees/day.
double nextCrossing(double Function(double jd) f, double jdStart,
    double target, double rate) {
  final togo = norm360(target - f(jdStart));
  var t = crossingNear(f, jdStart + togo / rate, target, rate);
  if (t < jdStart - 1e-7) {
    t = crossingNear(f, t + 360.0 / rate, target, rate);
  }
  return t;
}

/// Last instant ≤ [jdEnd] at which the increasing angle [f] reached [target].
double prevCrossing(double Function(double jd) f, double jdEnd, double target,
    double rate) {
  final back = norm360(f(jdEnd) - target);
  var t = crossingNear(f, jdEnd - back / rate, target, rate);
  if (t > jdEnd + 1e-7) {
    t = crossingNear(f, t - 360.0 / rate, target, rate);
  }
  return t;
}

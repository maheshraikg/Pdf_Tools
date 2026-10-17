/// Low-precision solar position (accurate to about 1 arc-minute between
/// 1950 and 2050), enough for prayer times to the minute.
library;

import 'dart:math' as math;

const double _deg = math.pi / 180.0;

double sinD(double d) => math.sin(d * _deg);
double cosD(double d) => math.cos(d * _deg);
double tanD(double d) => math.tan(d * _deg);
double asinD(double x) => math.asin(x) / _deg;
double acosD(double x) => math.acos(x) / _deg;
double atanD(double x) => math.atan(x) / _deg;
double atan2D(double y, double x) => math.atan2(y, x) / _deg;

/// Julian Day at 0h UTC of the given Gregorian date.
double julianDay(int year, int month, int day) {
  var y = year, m = month;
  if (m <= 2) {
    y -= 1;
    m += 12;
  }
  final a = (y / 100).floor();
  final b = 2 - a + (a / 4).floor();
  return (365.25 * (y + 4716)).floor() +
      (30.6001 * (m + 1)).floor() +
      day +
      b -
      1524.5;
}

/// Sun declination (degrees) and equation of time (hours) at Julian Day [jd].
({double declination, double equationOfTime}) sunPosition(double jd) {
  final d = jd - 2451545.0;
  final g = _fix(357.529 + 0.98560028 * d, 360);
  final q = _fix(280.459 + 0.98564736 * d, 360);
  final l = _fix(q + 1.915 * sinD(g) + 0.020 * sinD(2 * g), 360);
  final e = 23.439 - 0.00000036 * d;
  final ra = _fix(atan2D(cosD(e) * sinD(l), cosD(l)) / 15.0, 24);
  var eqt = q / 15.0 - ra;
  eqt = _fix(eqt + 12, 24) - 12;
  return (declination: asinD(sinD(e) * sinD(l)), equationOfTime: eqt);
}

double _fix(double a, double b) {
  final r = a - b * (a / b).floor();
  return r < 0 ? r + b : r;
}

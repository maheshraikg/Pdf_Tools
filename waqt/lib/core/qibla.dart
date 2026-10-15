/// Qibla direction and compass heading.
library;

import 'dart:math' as math;

import 'astro.dart';
import 'place.dart';

/// Great-circle initial bearing from a place to the Kaaba, in degrees
/// clockwise from true north (0–360).
double qiblaBearing(double latitude, double longitude) {
  final dLng = kaabaLongitude - longitude;
  final y = sinD(dLng);
  final x = cosD(latitude) * tanD(kaabaLatitude) - sinD(latitude) * cosD(dLng);
  return (atan2D(y, x) + 360) % 360;
}

/// Great-circle distance to the Kaaba in kilometres.
double kaabaDistanceKm(double latitude, double longitude) {
  final dLat = kaabaLatitude - latitude;
  final dLng = kaabaLongitude - longitude;
  final a =
      math.pow(sinD(dLat / 2), 2) +
      cosD(latitude) * cosD(kaabaLatitude) * math.pow(sinD(dLng / 2), 2);
  return 2 * 6371.0 * math.asin(math.sqrt(a.toDouble()));
}

/// Tilt-compensated compass heading of the phone's top edge (degrees
/// clockwise from magnetic north), from accelerometer [a] and magnetometer
/// [m] readings in the device frame. Same maths as Android's
/// `SensorManager.getRotationMatrix` + `getOrientation`. Returns null when
/// the readings are unusable (free fall, or field parallel to gravity).
double? compassHeading(
  ({double x, double y, double z}) a,
  ({double x, double y, double z}) m,
) {
  var hx = m.y * a.z - m.z * a.y;
  var hy = m.z * a.x - m.x * a.z;
  var hz = m.x * a.y - m.y * a.x;
  final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
  final normA = math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
  if (normH < 0.1 || normA < 0.1) return null;
  hx /= normH;
  hy /= normH;
  hz /= normH;
  final ax = a.x / normA, az = a.z / normA;
  final my = az * hx - ax * hz;
  return (atan2D(hy, my) + 360) % 360;
}

/// Smooths angles (degrees) without jumping at 0/360.
class AngleSmoother {
  AngleSmoother([this.alpha = 0.15]);
  final double alpha;
  double? _s, _c;

  double add(double degrees) {
    final s = sinD(degrees), c = cosD(degrees);
    _s = _s == null ? s : _s! + alpha * (s - _s!);
    _c = _c == null ? c : _c! + alpha * (c - _c!);
    return (atan2D(_s!, _c!) + 360) % 360;
  }
}

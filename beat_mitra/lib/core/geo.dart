import 'dart:math' as math;

/// Simple lat/lng pair (degrees).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'GeoPoint($lat, $lng)';
}

const double _earthRadiusM = 6371000.0;

double _rad(double d) => d * math.pi / 180.0;

/// Great-circle distance in metres.
double haversineMeters(GeoPoint a, GeoPoint b) {
  final dLat = _rad(b.lat - a.lat);
  final dLng = _rad(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) + math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Initial bearing from [a] to [b] in degrees (0 = north, clockwise).
double bearingDegrees(GeoPoint a, GeoPoint b) {
  final y = math.sin(_rad(b.lng - a.lng)) * math.cos(_rad(b.lat));
  final x =
      math.cos(_rad(a.lat)) * math.sin(_rad(b.lat)) -
      math.sin(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.cos(_rad(b.lng - a.lng));
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Angle for the on-screen arrow: target bearing relative to the phone heading.
double relativeBearing(double targetBearing, double heading) => (targetBearing - heading + 360) % 360;

/// "45 m" / "1.2 km".
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km';
}

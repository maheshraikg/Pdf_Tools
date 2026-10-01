/// Air code for a PIN or PIN series: the scheme's air rule when it has one,
/// otherwise the airport nearest to the area's head office.
library;

import 'airports.dart';
import 'directory_repo.dart';
import 'resolver.dart';
import 'scheme_repo.dart';

class AreaAir {
  const AreaAir(this.code, this.city, {this.fromScheme = false});

  final String code;
  final String city;

  /// From the scheme's air codes (else the nearest airport).
  final bool fromScheme;
}

final Map<String, AreaAir?> _cache = {};

/// PINs [lo]..[hi] (one PIN when equal). Cached per range and scheme.
Future<AreaAir?> airForRange(DirectorySource dir, ActiveScheme? scheme, int lo, int hi) async {
  final key = '${identityHashCode(scheme)}:$lo-$hi';
  if (_cache.containsKey(key)) return _cache[key];
  final offices = await dir.officesInRange(lo, hi);
  AreaAir? out;
  final rule = scheme?.airResolver.resolve(ResolveQuery(pin: offices.firstOrNull?.pincode ?? lo))?.rule;
  if (rule != null && rule.airCode.isNotEmpty) {
    out = AreaAir(rule.airCode, rule.airCode, fromScheme: true);
  } else {
    final located = offices.where((o) => o.latitude != null && o.longitude != null).toList();
    // The area's head office stands for it; else the middle of its offices.
    final head = located.where((o) => o.officeType == 'HO').firstOrNull;
    double? lat, lng;
    if (head != null) {
      lat = head.latitude;
      lng = head.longitude;
    } else if (located.isNotEmpty) {
      lat = located.map((o) => o.latitude!).reduce((a, b) => a + b) / located.length;
      lng = located.map((o) => o.longitude!).reduce((a, b) => a + b) / located.length;
    }
    if (lat != null && lng != null) {
      final a = nearestAirports(lat, lng, count: 1).first.$1;
      out = AreaAir(a.iata, a.city);
    }
  }
  if (_cache.length > 500) _cache.clear();
  return _cache[key] = out;
}

/// PIN range a typed prefix or a rule key stands for ("560" → 560000–560999).
(int, int)? pinRange(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty || d.length > 6) return null;
  return (int.parse(d.padRight(6, '0')), int.parse(d.padRight(6, '9')));
}

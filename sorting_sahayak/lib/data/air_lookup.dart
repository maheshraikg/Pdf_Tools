/// Air code for a PIN or PIN series from the scheme's air codes (the office's
/// PH sorting sheet). No guessing: a PIN with no air code shows none.
library;

import 'directory_repo.dart';
import 'resolver.dart';
import 'scheme_repo.dart';

class AreaAir {
  const AreaAir(this.code, this.city, {this.fromScheme = false});

  final String code;
  final String city;

  final bool fromScheme;
}

final Map<String, AreaAir?> _cache = {};

/// PINs [lo]..[hi] (one PIN when equal). Cached per range and scheme.
Future<AreaAir?> airForRange(DirectorySource dir, ActiveScheme? scheme, int lo, int hi) async {
  final key = '${identityHashCode(scheme)}:$lo-$hi';
  if (_cache.containsKey(key)) return _cache[key];
  AreaAir? out;
  // A typed series ("560") stands for its first real PIN.
  final pin = lo == hi ? lo : (await dir.officesInRange(lo, hi)).firstOrNull?.pincode ?? lo;
  final rule = scheme?.airResolver.resolve(ResolveQuery(pin: pin))?.rule;
  if (rule != null && hasAirCode(rule.airCode)) {
    out = AreaAir(rule.airCode, rule.stationName.isEmpty ? rule.airCode : rule.stationName, fromScheme: true);
  }
  if (_cache.length > 500) _cache.clear();
  return _cache[key] = out;
}

/// "NIL" (or empty) in an air code sheet: sent without an air code.
bool hasAirCode(String code) => code.isNotEmpty && code.toUpperCase() != 'NIL';

/// PIN range a typed prefix or a rule key stands for ("560" → 560000–560999).
(int, int)? pinRange(String digits) {
  final d = digits.replaceAll(RegExp(r'\D'), '');
  if (d.isEmpty || d.length > 6) return null;
  return (int.parse(d.padRight(6, '0')), int.parse(d.padRight(6, '9')));
}

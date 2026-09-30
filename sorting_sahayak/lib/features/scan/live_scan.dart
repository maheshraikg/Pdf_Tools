/// Helpers for the live camera scan: a PIN is accepted only when OCR reads
/// the same one on consecutive frames, and office names found on the
/// address are ranked nearest first from the sorting office.
library;

import '../../core/fuzzy.dart';
import '../../data/airports.dart' show distanceKm;
import '../../data/directory_repo.dart';
import '../../data/models/office.dart';
import '../../data/sort_engine.dart';

/// Accepts a PIN once it has been read on [needed] frames in a row, so a
/// single misread digit never shows a wrong line.
class PinStabilizer {
  PinStabilizer({this.needed = 2});

  final int needed;
  String? _last;
  int _count = 0;
  String? stable;

  /// Feeds the PIN read on one frame (null when none). Returns true when
  /// [stable] changed.
  bool add(String? pin) {
    if (pin == null) {
      _count = 0;
      _last = null;
      return false;
    }
    _count = pin == _last ? _count + 1 : 1;
    _last = pin;
    if (_count >= needed && pin != stable) {
      stable = pin;
      return true;
    }
    return false;
  }

  void reset() {
    _last = null;
    _count = 0;
    stable = null;
  }
}

typedef GeoPoint = ({double lat, double lng});

/// Location of the sorting office the scheme belongs to ("Mangaluru"),
/// used to rank offices nearest first. Prefers the HO, then any office with
/// coordinates. Null when the scheme names no office or it is not found.
Future<GeoPoint?> homePoint(DirectorySource dir, String schemeOffice) async {
  final q = schemeOffice.trim();
  if (normalizePlace(q).length < 3) return null;
  final hits = await dir.search(q, limit: 30);
  Office? pick;
  for (final h in hits) {
    final o = h.office;
    if (o.latitude == null || o.longitude == null || h.score < 0.8) continue;
    if (o.officeType == 'HO') {
      pick = o;
      break;
    }
    pick ??= o;
  }
  return pick == null ? null : (lat: pick.latitude!, lng: pick.longitude!);
}

/// Common address words that are also the name of some office somewhere
/// ("Road BO"); never searched on their own.
const _addressWords = {
  'road', 'street', 'cross', 'main', 'lane', 'near', 'opp', 'opposite', 'behind', 'house', 'home', 'building', 'floor',
  'school', 'college', 'company', 'temple', 'church', 'masjid', 'hospital', 'office', 'shop', 'stores', 'market', 'circle',
  'colony', 'layout', 'block', 'ward', 'door', 'flat', 'apartment', 'complex', 'bazar', 'bazaar', 'village', 'post',
  'district', 'taluk', 'state', 'india', 'karnataka', 'kerala', 'mobile', 'phone', 'from', 'sender',
};

class ScanOfficeHit {
  const ScanOfficeHit({required this.office, required this.result, required this.score, this.km, this.samePin = false});

  final Office office;
  final SortResult result;

  /// 0..1 similarity of the text on the address to this office's name.
  final double score;

  /// Distance from the sorting office, when both have coordinates.
  final double? km;

  /// The office carries the PIN read on the address.
  final bool samePin;
}

/// Offices whose name appears on the address. Offices with the PIN read on
/// the address come first; the rest nearest first from [home], then by how
/// well the name matched. Near-miss spellings are kept only within
/// [fuzzyKm] of [home] (OCR noise like "Car" → "Carmona" far away).
Future<List<ScanOfficeHit>> officesOnAddress(
  DirectorySource dir,
  SortEngine engine,
  List<String> places, {
  required String category,
  String? pin,
  GeoPoint? home,
  int limit = 8,
  double minScore = 0.85,
  double fuzzyKm = 100,
}) async {
  final seen = <String>{};
  final out = <ScanOfficeHit>[];
  for (final c in places.take(8)) {
    final norm = normalizePlace(c);
    if (norm.length < 4 || _addressWords.contains(norm)) continue;
    final hits = await dir.search(c, limit: 10);
    for (final h in hits) {
      if (h.score < minScore) continue;
      final o = h.office;
      final key = '${o.pincode}|${o.officeName}|${o.officeType}';
      if (!seen.add(key)) continue;
      final km = home == null || o.latitude == null || o.longitude == null ? null : distanceKm(home.lat, home.lng, o.latitude!, o.longitude!);
      final samePin = pin != null && o.pin == pin;
      final exact = h.score >= 0.99;
      if (!samePin && !exact && home != null && (km == null || km > fuzzyKm)) continue;
      out.add(ScanOfficeHit(
        office: o,
        result: engine.resolveOffice(o, category: category),
        score: h.score,
        km: km,
        samePin: samePin,
      ));
    }
  }
  out.sort(compareScanHits);
  return out.take(limit).toList();
}

int compareScanHits(ScanOfficeHit a, ScanOfficeHit b) {
  if (a.samePin != b.samePin) return a.samePin ? -1 : 1;
  final ka = a.km, kb = b.km;
  if (ka != null && kb != null && (ka - kb).abs() > 0.5) return ka.compareTo(kb);
  if (ka != null && kb == null) return -1;
  if (ka == null && kb != null) return 1;
  return b.score.compareTo(a.score);
}

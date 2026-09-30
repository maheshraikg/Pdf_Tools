/// Helpers for the live camera scan: a PIN is accepted only when OCR reads
/// the same one on consecutive frames, and office names found on the
/// address are ranked best match first.
library;

import '../../core/fuzzy.dart';
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

  /// Accepts [pin] at once (a captured photo is read carefully once).
  bool force(String pin) {
    _last = pin;
    _count = needed;
    if (pin == stable) return false;
    stable = pin;
    return true;
  }

  void reset() {
    _last = null;
    _count = 0;
    stable = null;
  }
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
  const ScanOfficeHit({
    required this.office,
    required this.result,
    required this.score,
    this.rank = 0,
    this.samePin = false,
    this.sameArea = false,
    this.support = 0,
  });

  final Office office;
  final SortResult result;

  /// 0..1 similarity of the text on the address to this office's name.
  final double score;

  /// Position of the matching text among the address candidates (0 = the
  /// line with the PIN / just above it, the most likely office line).
  final int rank;

  /// The office carries the PIN read on the address.
  final bool samePin;

  /// Same sorting district (first 3 PIN digits) as the PIN read.
  final bool sameArea;

  /// How many other names on the address point to the same sorting district
  /// ("Kankanady, Mangalore" → both 575): the right "Mangalore" among many.
  final int support;

  ScanOfficeHit withPin(String? pin) => copy(
    samePin: pin != null && office.pin == pin,
    sameArea: pin != null && office.pin.substring(0, 3) == pin.substring(0, 3),
  );

  ScanOfficeHit copy({bool? samePin, bool? sameArea, int? support}) => ScanOfficeHit(
    office: office,
    result: result,
    score: score,
    rank: rank,
    samePin: samePin ?? this.samePin,
    sameArea: sameArea ?? this.sameArea,
    support: support ?? this.support,
  );
}

/// Offices whose name appears on the address, best match first: the office
/// with the PIN read on the address, then offices in the same sorting
/// district, then by how exactly the name matched and how many other names
/// on the address agree on the area. Near-miss spellings from other areas
/// are dropped (OCR noise like "Car" → "Carmona").
Future<List<ScanOfficeHit>> officesOnAddress(
  DirectorySource dir,
  SortEngine engine,
  List<String> places, {
  required String category,
  String? pin,
  int limit = 8,
  double minScore = 0.85,
}) async {
  // Every address candidate that matched an office (not only the first).
  final ranksOf = <String, Set<int>>{};
  final out = <ScanOfficeHit>[];
  final cands = places.take(8).toList();
  for (var i = 0; i < cands.length; i++) {
    final c = cands[i];
    final norm = normalizePlace(c);
    if (norm.length < 4 || _addressWords.contains(norm)) continue;
    final hits = await dir.search(c, limit: 10);
    for (final h in hits) {
      if (h.score < minScore) continue;
      final o = h.office;
      final key = _key(o);
      final seenBefore = ranksOf.containsKey(key);
      (ranksOf[key] ??= {}).add(i);
      if (seenBefore) continue;
      final hit = ScanOfficeHit(office: o, result: engine.resolveOffice(o, category: category), score: h.score, rank: i).withPin(pin);
      if (!hit.samePin && !hit.sameArea && h.score < 0.92) continue;
      out.add(hit);
    }
  }
  // Names from different address lines that share a sorting district back
  // each other up.
  final ranksByArea = <String, Set<int>>{};
  for (final h in out) {
    (ranksByArea[h.office.pin.substring(0, 3)] ??= {}).addAll(ranksOf[_key(h.office)]!);
  }
  final ranked = [
    for (final h in out) h.copy(support: ranksByArea[h.office.pin.substring(0, 3)]!.difference(ranksOf[_key(h.office)]!).length),
  ]..sort(compareScanHits);
  return ranked.take(limit).toList();
}

String _key(Office o) => '${o.pincode}|${o.officeName}|${o.officeType}';

const _headTypes = {'HO', 'SO', 'PO'};

int compareScanHits(ScanOfficeHit a, ScanOfficeHit b) {
  if (a.samePin != b.samePin) return a.samePin ? -1 : 1;
  if (a.sameArea != b.sameArea) return a.sameArea ? -1 : 1;
  final s = b.score.compareTo(a.score);
  if ((a.score - b.score).abs() > 0.02) return s;
  if (a.support != b.support) return b.support.compareTo(a.support);
  final ha = _headTypes.contains(a.office.officeType), hb = _headTypes.contains(b.office.officeType);
  if (ha != hb) return ha ? -1 : 1;
  if (a.rank != b.rank) return a.rank.compareTo(b.rank);
  return s;
}

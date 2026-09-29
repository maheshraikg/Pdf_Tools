/// PIN ↔ place-name consistency check — the key missort-prevention feature.
library;

import '../core/fuzzy.dart';
import '../core/pin_utils.dart';
import 'directory_repo.dart';
import 'models/office.dart';

enum MismatchLevel {
  /// The place belongs to this PIN.
  match,

  /// Same district (or sorting district) but a different PIN.
  sameDistrict,

  /// Different district / state.
  different,

  /// The place name was not found in the directory.
  unknownPlace,

  /// The PIN is not in the directory.
  pinNotFound,

  /// The PIN itself is malformed.
  invalidPin,
}

class MismatchResult {
  const MismatchResult({
    required this.level,
    this.pinOffices = const [],
    this.placeOffices = const [],
    this.suggestions = const [],
  });

  final MismatchLevel level;

  /// Offices of the entered PIN.
  final List<Office> pinOffices;

  /// Best directory matches for the place name.
  final List<Office> placeOffices;

  /// Suggested offices (distinct PINs) the article probably belongs to.
  final List<Office> suggestions;
}

class MismatchChecker {
  MismatchChecker(this.directory);

  final DirectorySource directory;

  /// Minimum similarity for a place hit to count.
  static const double threshold = 0.8;

  Future<MismatchResult> check(String pin, String place) async {
    final p = PinUtils.digitsOnly(pin);
    if (!PinUtils.isValid(p)) return const MismatchResult(level: MismatchLevel.invalidPin);
    final pinOffices = await directory.officesForPin(int.parse(p));
    final hits = (await directory.search(place, limit: 60)).where((h) => h.score >= threshold).toList();
    if (hits.isEmpty) {
      return MismatchResult(
        level: pinOffices.isEmpty ? MismatchLevel.pinNotFound : MismatchLevel.unknownPlace,
        pinOffices: pinOffices,
      );
    }
    // Prefer the strongest matches: if exact/near-exact names exist, ignore
    // weaker fuzzy ones.
    final top = hits.first.score;
    final strong = hits.where((h) => h.score >= top - 0.06).map((h) => h.office).toList();
    final placeNorm = normalizePlace(place);

    if (pinOffices.isEmpty) {
      return MismatchResult(
        level: MismatchLevel.pinNotFound,
        placeOffices: strong,
        suggestions: _distinctPins(strong),
      );
    }

    final pinNum = int.parse(p);
    final pinDistricts = pinOffices.map((o) => normalizePlace(o.district)).toSet();
    final pinTaluks = pinOffices.map((o) => normalizePlace(o.taluk)).where((t) => t.isNotEmpty).toSet();
    final nameMatchesPinOffice = pinOffices.any((o) {
      final n = normalizePlace(o.officeName);
      return placeSimilarity(placeNorm, n) >= 0.9;
    });
    // The place is the PIN's own office, or one of the strong hits has this
    // PIN, or the place is the PIN's district/taluk name ("Udupi" on 576101).
    if (nameMatchesPinOffice ||
        strong.any((o) => o.pincode == pinNum) ||
        (pinDistricts.contains(placeNorm) || pinTaluks.contains(placeNorm)) &&
            strong.any((o) => o.pin.substring(0, 3) == p.substring(0, 3))) {
      return MismatchResult(level: MismatchLevel.match, pinOffices: pinOffices, placeOffices: strong);
    }
    final sameDistrict = strong
        .where((o) => pinDistricts.contains(normalizePlace(o.district)) || o.pin.substring(0, 3) == p.substring(0, 3))
        .toList();
    if (sameDistrict.isNotEmpty) {
      return MismatchResult(
        level: MismatchLevel.sameDistrict,
        pinOffices: pinOffices,
        placeOffices: strong,
        suggestions: _distinctPins(sameDistrict),
      );
    }
    return MismatchResult(
      level: MismatchLevel.different,
      pinOffices: pinOffices,
      placeOffices: strong,
      suggestions: _distinctPins(strong),
    );
  }

  List<Office> _distinctPins(List<Office> offices, {int max = 6}) {
    final seen = <int>{};
    final out = <Office>[];
    for (final o in offices) {
      if (seen.add(o.pincode)) out.add(o);
      if (out.length >= max) break;
    }
    return out;
  }
}

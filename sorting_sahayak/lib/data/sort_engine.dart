/// Turns a PIN (or a place name) into the full sorting answer: bag, air
/// label code, parcel hub route and the Air/Surface label badge.
library;

import '../core/constants.dart';
import '../core/fuzzy.dart';
import '../core/pin_utils.dart';
import 'directory_repo.dart';
import 'models/office.dart';
import 'models/scheme.dart';
import 'resolver.dart';
import 'scheme_repo.dart';

class SortResult {
  const SortResult({
    required this.digits,
    this.breakdown,
    this.offices = const [],
    this.prefixSummary,
    this.bag,
    this.bagRule,
    this.bagLevel,
    this.likelyBag,
    this.possibleBags = const [],
    this.air,
    this.hub,
    this.connectivity,
    this.connectivityDefaulted = false,
    this.category = kCatLetters,
  });

  final String digits;
  final PinBreakdown? breakdown;
  final List<Office> offices;
  final PrefixSummary? prefixSummary;

  /// Final bag (complete PIN / place).
  final Bag? bag;
  final BagRule? bagRule;
  final RuleType? bagLevel;

  /// While typing: bag from the longest prefix rule that already applies.
  final Bag? likelyBag;
  final List<Bag> possibleBags;

  final Resolution<AirCodeRule>? air;
  final Resolution<HubRule>? hub;
  final Connectivity? connectivity;

  /// True when no rule gave Air/Surface and Surface was assumed.
  final bool connectivityDefaulted;
  final String category;

  bool get complete => digits.length == 6;
  bool get valid => PinUtils.isValid(digits);
  bool get notInDirectory => complete && valid && offices.isEmpty;
}

class SortEngine {
  SortEngine(this.directory, this.scheme);

  final DirectorySource directory;
  final ActiveScheme? scheme;

  /// Resolves a (partial) PIN. Fast path: one indexed directory query.
  Future<SortResult> resolvePin(String input, {required String category, String? officeName}) async {
    final digits = PinUtils.digitsOnly(input);
    final bd = PinUtils.breakdown(digits);
    if (digits.length < 6) {
      PrefixSummary? summary;
      if (digits.length >= 3 && bd != null) summary = await directory.prefixSummary(digits);
      final s = scheme;
      Bag? likely;
      var possible = <Bag>[];
      if (s != null && digits.isNotEmpty && bd != null) {
        final p = s.bagResolver.resolvePartial(digits, category: category);
        if (p != null) likely = s.bagFor(p.rule);
        final seen = <String>{};
        for (final r in s.bagResolver.candidatesForPartial(digits, category: category)) {
          if (seen.add(r.bagCode)) possible.add(s.bagFor(r));
        }
        if (possible.length > 8) possible = possible.sublist(0, 8);
      }
      return SortResult(
        digits: digits,
        breakdown: bd,
        prefixSummary: summary,
        likelyBag: likely,
        possibleBags: possible,
        category: category,
      );
    }
    if (!PinUtils.isValid(digits)) return SortResult(digits: digits, category: category);
    final pin = int.parse(digits);
    final offices = await directory.officesForPin(pin);
    final q = ResolveQuery(
      pin: pin,
      officeNorms: [
        if (officeName != null && officeName.trim().isNotEmpty) normalizePlace(officeName),
        ...offices.map((o) => normalizePlace(o.officeName)),
      ],
      districtNorms: offices.map((o) => normalizePlace(o.district)).toSet().toList(),
      stateNorms: offices.map((o) => normalizePlace(o.state)).toSet().toList(),
      category: category,
    );
    return _resolve(digits, bd, offices, q, category);
  }

  /// Resolves an office picked from Find PIN (article without a PIN).
  SortResult resolveOffice(Office o, {required String category}) {
    final q = ResolveQuery(
      pin: o.pincode,
      officeNorms: [normalizePlace(o.officeName)],
      districtNorms: [normalizePlace(o.district)],
      stateNorms: [normalizePlace(o.state)],
      category: category,
    );
    return _resolve(o.pin, PinUtils.breakdown(o.pin), [o], q, category);
  }

  SortResult _resolve(String digits, PinBreakdown? bd, List<Office> offices, ResolveQuery q, String category) {
    final s = scheme;
    if (s == null) return SortResult(digits: digits, breakdown: bd, offices: offices, category: category);
    final bag = s.bagResolver.resolve(q);
    final parcel = isParcelCategory(category);
    final air = isAirCategory(category) ? s.airResolver.resolve(q) : null;
    final hub = parcel ? s.hubResolver.resolve(q) : null;
    Connectivity? conn;
    var defaulted = false;
    if (parcel) {
      conn = hub?.rule.connectivity ?? bag?.rule.connectivity;
      if (conn == null) {
        conn = Connectivity.surface;
        defaulted = true;
      }
    }
    return SortResult(
      digits: digits,
      breakdown: bd,
      offices: offices,
      bag: bag == null ? null : s.bagFor(bag.rule),
      bagRule: bag?.rule,
      bagLevel: bag?.level,
      air: air,
      hub: hub,
      connectivity: conn,
      connectivityDefaulted: defaulted,
      category: category,
    );
  }
}

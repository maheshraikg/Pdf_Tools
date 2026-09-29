/// Priority resolver shared by bag rules, air codes and DMSL hub rules.
///
/// Priority when several rules match:
/// exact PIN > smallest PIN range > longest prefix > office name > district
/// > state > default. Within one level, a rule limited to the requested
/// mail category beats a rule for all categories; rules for other
/// categories never match.
library;

import 'models/scheme.dart';

class ResolveQuery {
  const ResolveQuery({
    this.pin,
    this.officeNorms = const [],
    this.districtNorms = const [],
    this.stateNorms = const [],
    this.category,
  });

  final int? pin;
  final List<String> officeNorms;
  final List<String> districtNorms;
  final List<String> stateNorms;
  final String? category;
}

class Resolution<T extends Matchable> {
  const Resolution(this.rule, this.level);

  final T rule;
  final RuleType level;
}

class RuleResolver<T extends Matchable> {
  RuleResolver(Iterable<T> rules) {
    for (final r in rules) {
      final m = r.match;
      switch (m.type) {
        case RuleType.exact:
          (_exact[m.pin!] ??= []).add(r);
        case RuleType.range:
          _ranges.add(r);
        case RuleType.prefix:
          (_prefix[m.prefix!] ??= []).add(r);
        case RuleType.office:
          (_office[m.officeNorm!] ??= []).add(r);
        case RuleType.district:
          (_district[m.districtNorm!] ??= []).add(r);
        case RuleType.state:
          (_state[m.stateNorm!] ??= []).add(r);
        case RuleType.fallback:
          _defaults.add(r);
      }
      _all.add(r);
    }
    // Smallest range first so the first containing range is the best one.
    _ranges.sort((a, b) {
      final wa = a.match.pinTo! - a.match.pinFrom!;
      final wb = b.match.pinTo! - b.match.pinFrom!;
      return wa != wb ? wa.compareTo(wb) : a.match.pinFrom!.compareTo(b.match.pinFrom!);
    });
  }

  final Map<int, List<T>> _exact = {};
  final List<T> _ranges = [];
  final Map<String, List<T>> _prefix = {};
  final Map<String, List<T>> _office = {};
  final Map<String, List<T>> _district = {};
  final Map<String, List<T>> _state = {};
  final List<T> _defaults = [];
  final List<T> _all = [];

  List<T> get rules => List.unmodifiable(_all);
  bool get isEmpty => _all.isEmpty;

  /// Picks the category-specific rule over an all-categories one; null when
  /// only other categories' rules are in [list].
  T? _pick(List<T>? list, String? category) {
    if (list == null || list.isEmpty) return null;
    T? general;
    for (final r in list) {
      final c = r.category;
      if (c == null || c.isEmpty) {
        general ??= r;
      } else if (category != null && c == category) {
        return r;
      }
    }
    return general;
  }

  bool _catOk(T r, String? category) {
    final c = r.category;
    return c == null || c.isEmpty || c == category;
  }

  Resolution<T>? resolve(ResolveQuery q) {
    final cat = q.category;
    final pin = q.pin;
    if (pin != null) {
      final e = _pick(_exact[pin], cat);
      if (e != null) return Resolution(e, RuleType.exact);
      T? bestRange;
      int? bestWidth;
      for (final r in _ranges) {
        final m = r.match;
        final w = m.pinTo! - m.pinFrom!;
        if (bestWidth != null && w > bestWidth) break;
        if (pin < m.pinFrom! || pin > m.pinTo! || !_catOk(r, cat)) continue;
        if (bestRange == null) {
          bestRange = r;
          bestWidth = w;
        } else if (r.category == cat && (bestRange.category ?? '').isEmpty) {
          bestRange = r;
        }
      }
      if (bestRange != null) return Resolution(bestRange, RuleType.range);
      final s = '$pin';
      for (var len = s.length - 1; len >= 1; len--) {
        final p = _pick(_prefix[s.substring(0, len)], cat);
        if (p != null) return Resolution(p, RuleType.prefix);
      }
    }
    for (final o in q.officeNorms) {
      final r = _pick(_office[o], cat);
      if (r != null) return Resolution(r, RuleType.office);
    }
    for (final d in q.districtNorms) {
      final r = _pick(_district[d], cat);
      if (r != null) return Resolution(r, RuleType.district);
    }
    for (final st in q.stateNorms) {
      final r = _pick(_state[st], cat);
      if (r != null) return Resolution(r, RuleType.state);
    }
    final d = _pick(_defaults, cat);
    return d == null ? null : Resolution(d, RuleType.fallback);
  }

  /// For a partially typed PIN (1–5 digits): the longest prefix rule that
  /// already applies, if any.
  Resolution<T>? resolvePartial(String digits, {String? category}) {
    for (var len = digits.length; len >= 1; len--) {
      final p = _pick(_prefix[digits.substring(0, len)], category);
      if (p != null) return Resolution(p, RuleType.prefix);
    }
    return null;
  }

  /// Rules that could still apply once the partial PIN is complete
  /// (exact PINs / ranges / prefixes starting with or covering [digits]).
  List<T> candidatesForPartial(String digits, {String? category}) {
    if (digits.isEmpty) return const [];
    final lo = int.parse(digits.padRight(6, '0'));
    final hi = int.parse(digits.padRight(6, '9'));
    final out = <T>[];
    for (final e in _exact.entries) {
      if (e.key >= lo && e.key <= hi) out.addAll(e.value.where((r) => _catOk(r, category)));
    }
    for (final r in _ranges) {
      if (r.match.pinFrom! <= hi && r.match.pinTo! >= lo && _catOk(r, category)) out.add(r);
    }
    for (final e in _prefix.entries) {
      if ((e.key.startsWith(digits) || digits.startsWith(e.key))) {
        out.addAll(e.value.where((r) => _catOk(r, category)));
      }
    }
    return out;
  }
}

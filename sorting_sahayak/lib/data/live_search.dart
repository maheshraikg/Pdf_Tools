/// Live list of scheme rules for what is typed so far, like a printed
/// sorting list: "67" → 670 KANNUR, 671 KANNUR, 673 KOZHIKODE, …
/// Letters search office / district / state rules and remarks by name.
library;

import '../core/fuzzy.dart';
import 'models/scheme.dart';

/// One stop on a line / bag: position, office name and its PIN(s).
class LineStop {
  LineStop(this.position, this.name);

  final String position;
  String name;
  final List<String> pins = [];
  BagRule? officeRule;
  final List<BagRule> pinRules = [];
}

String _stripType(String s) => s.replaceAll(RegExp(r'\b(S\.?O|H\.?O|B\.?O)\b\.?', caseSensitive: false), '').trim();

/// The whole line / bag as printed in the office list: every office rule in
/// position order, each joined with the PIN rules of the same office (by
/// name, e.g. "Sullia SO" ↔ office "Sulia"), plus PIN / prefix rules that
/// have no office entry.
List<LineStop> lineRoster(List<BagRule> rules, String bagCode, {String? category}) {
  final mine = rules.where((r) => r.bagCode == bagCode && _inCategory(r, category)).toList();
  final stops = <LineStop>[];
  for (final r in mine.where((r) => r.match.type == RuleType.office)) {
    stops.add(LineStop(r.section, r.officeName ?? r.describe)..officeRule = r);
  }
  String key(String s) => normalizePlace(_stripType(s)).replaceAll(' ', '');
  // Dice similarity of letter pairs: "sulia"/"sullia", "bykampadi"/"baikampady".
  double similar(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;
    Map<String, int> grams(String s) {
      final m = <String, int>{};
      for (var i = 0; i < s.length - 1; i++) {
        final g = s.substring(i, i + 2);
        m[g] = (m[g] ?? 0) + 1;
      }
      return m;
    }

    final ga = grams(a), gb = grams(b);
    var common = 0;
    ga.forEach((g, n) {
      final m = gb[g] ?? 0;
      common += n < m ? n : m;
    });
    final total = (a.length - 1) + (b.length - 1);
    return total <= 0 ? 0 : 2 * common / total;
  }

  for (final r in mine.where((r) => r.match.type != RuleType.office)) {
    final label = r.match.type == RuleType.exact ? '${r.match.pin}' : r.describe;
    final name = r.remarks.isNotEmpty ? _stripType(r.remarks) : label;
    final k = key(name);
    LineStop? hit;
    var best = 0.0;
    // Best name match, preferring an office at the same position.
    for (final s in stops) {
      if (s.officeRule == null) continue;
      final score = similar(key(s.name), k) + (s.position.isNotEmpty && s.position == r.section ? 0.25 : 0);
      if (score > best) {
        best = score;
        hit = s;
      }
    }
    if (best < 0.6) hit = null;
    if (hit == null) {
      hit = LineStop(r.section, name);
      stops.add(hit);
    }
    hit.pins.add(label);
    hit.pinRules.add(r);
  }
  int pos(LineStop s) => int.tryParse(s.position) ?? 1 << 20;
  stops.sort((a, b) {
    final c = pos(a).compareTo(pos(b));
    if (c != 0) return c;
    final pa = a.pins.isEmpty ? '' : a.pins.first;
    final pb = b.pins.isEmpty ? '' : b.pins.first;
    return pa.compareTo(pb);
  });
  return stops;
}

class LiveMatch {
  const LiveMatch(this.rule, this.key, {this.covers = false});

  final BagRule rule;

  /// What the rule matches, as shown: "678", "574201", "560001–560099", "Sampaje".
  final String key;

  /// True when the rule already applies to everything typed (e.g. prefix
  /// "67" rule while typing "671").
  final bool covers;
}

String _key(BagRule r) {
  final m = r.match;
  return switch (m.type) {
    RuleType.exact => '${m.pin}',
    RuleType.range => '${m.pinFrom}–${m.pinTo}',
    RuleType.prefix => m.prefix ?? '',
    _ => r.describe,
  };
}

bool _inCategory(BagRule r, String? category) => r.category == null || category == null || r.category == category;

List<LiveMatch> liveMatches(List<BagRule> rules, String query, {String? category, int limit = 60}) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final digits = RegExp(r'^\d+$').hasMatch(q);
  final out = <LiveMatch>[];
  if (digits) {
    final n = int.tryParse(q.padRight(6, '0'));
    final hi = int.tryParse(q.padRight(6, '9'));
    for (final r in rules) {
      if (!_inCategory(r, category)) continue;
      final m = r.match;
      switch (m.type) {
        case RuleType.exact:
          if ('${m.pin}'.startsWith(q)) out.add(LiveMatch(r, _key(r), covers: '${m.pin}' == q));
        case RuleType.prefix:
          final p = m.prefix!;
          if (p.startsWith(q)) {
            out.add(LiveMatch(r, p, covers: p == q));
          } else if (q.startsWith(p)) {
            out.add(LiveMatch(r, p, covers: true));
          }
        case RuleType.range:
          if (n != null && hi != null && m.pinFrom! <= hi && m.pinTo! >= n) {
            out.add(LiveMatch(r, _key(r), covers: q.length == 6 && m.pinFrom! <= n && n <= m.pinTo!));
          }
        default:
          break;
      }
    }
    // Rules covering the typed digits first (longest = most specific), then
    // the rest in number order.
    out.sort((a, b) {
      if (a.covers != b.covers) return a.covers ? -1 : 1;
      if (a.covers) return b.key.length.compareTo(a.key.length);
      final c = a.key.length.compareTo(b.key.length);
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  } else {
    final nq = normalizePlace(q);
    if (nq.length < 2) return const [];
    final starts = <LiveMatch>[];
    final contains = <LiveMatch>[];
    for (final r in rules) {
      if (!_inCategory(r, category)) continue;
      final m = r.match;
      final name = switch (m.type) {
        RuleType.office => m.officeNorm ?? '',
        RuleType.district => m.districtNorm ?? '',
        RuleType.state => m.stateNorm ?? '',
        _ => '',
      };
      final remarks = normalizePlace(r.remarks);
      if (name.startsWith(nq) || remarks.startsWith(nq)) {
        starts.add(LiveMatch(r, _key(r)));
      } else if (name.contains(nq) || remarks.contains(nq) || normalizePlace(r.bagCode).contains(nq)) {
        contains.add(LiveMatch(r, _key(r)));
      }
    }
    out
      ..addAll(starts)
      ..addAll(contains);
  }
  return out.length > limit ? out.sublist(0, limit) : out;
}

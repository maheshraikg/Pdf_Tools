/// Live list of scheme rules for what is typed so far, like a printed
/// sorting list: "67" → 670 KANNUR, 671 KANNUR, 673 KOZHIKODE, …
/// Letters search office / district / state rules and remarks by name.
library;

import '../core/fuzzy.dart';
import 'models/scheme.dart';

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

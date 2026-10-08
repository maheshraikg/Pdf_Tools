/// Compares two DMSL versions PIN by PIN.
library;

import 'models/scheme.dart';
import 'resolver.dart';

class DmslChange {
  const DmslChange(this.pin, this.before, this.after);

  final int pin;
  final HubRule? before;
  final HubRule? after;

  bool get added => before == null;
  bool get removed => after == null;
}

/// PINs whose hub route (L2, L1, direct closure, connectivity) differs
/// between [oldRules] and [newRules]. The PINs checked are every explicit
/// PIN in either version, range end points, plus [universe] (normally all
/// directory PINs, so prefix / range / district rules are covered too).
/// [districtOf] maps a PIN to its normalised district / state for district
/// and state rules.
List<DmslChange> diffDmsl(
  List<HubRule> oldRules,
  List<HubRule> newRules, {
  Iterable<int> universe = const [],
  ({List<String> districts, List<String> states}) Function(int pin)? districtOf,
}) {
  final pins = <int>{...universe};
  for (final r in [...oldRules, ...newRules]) {
    final m = r.match;
    if (m.type == RuleType.exact) pins.add(m.pin!);
    if (m.type == RuleType.range) pins.addAll([m.pinFrom!, m.pinTo!]);
  }
  final a = RuleResolver(oldRules), b = RuleResolver(newRules);
  final out = <DmslChange>[];
  for (final pin in pins.toList()..sort()) {
    final ctx = districtOf?.call(pin);
    final q = ResolveQuery(pin: pin, districtNorms: ctx?.districts ?? const [], stateNorms: ctx?.states ?? const []);
    final x = a.resolve(q)?.rule, y = b.resolve(q)?.rule;
    if (x == null && y == null) continue;
    if (x?.routeKey != y?.routeKey) out.add(DmslChange(pin, x, y));
  }
  return out;
}

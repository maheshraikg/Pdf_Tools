/// Bulk sorting session logic: turning entries into bag / air code / hub /
/// Air-Surface tallies and shareable summaries.
library;

import 'package:csv/csv.dart';

import '../../core/pin_utils.dart';
import '../../data/models/scheme.dart';
import '../../data/sort_engine.dart';
import '../../data/user_repo.dart';

/// Resolves one typed / scanned PIN into a stored bulk entry.
Future<BulkEntry> makeBulkEntry(SortEngine engine, String raw, String category) async {
  final digits = PinUtils.digitsOnly(raw);
  final now = DateTime.now().millisecondsSinceEpoch;
  if (!PinUtils.isValid(digits)) return BulkEntry(raw: raw, ts: now);
  final r = await engine.resolvePin(digits, category: category);
  final hub = r.hub?.rule;
  return BulkEntry(
    raw: raw,
    pin: int.parse(digits),
    bagCode: r.bag?.code,
    bagName: r.bag?.name,
    airCode: r.air?.rule.airCode,
    l2Hub: hub == null || hub.directClosure ? null : hub.l2Hub,
    l1Hub: hub?.l1Hub,
    connectivity: r.connectivity?.label,
    ts: now,
  );
}

class BulkSummary {
  BulkSummary({
    required this.total,
    required this.byBag,
    required this.byAir,
    required this.byConnectivity,
    required this.byHub,
    required this.unresolved,
  });

  final int total;

  /// Bag code → count, in scheme bag order.
  final Map<String, int> byBag;
  final Map<String, int> byAir;
  final Map<String, int> byConnectivity;

  /// "L2 → L1" (or "→ L1 (direct)") → count.
  final Map<String, int> byHub;
  final List<BulkEntry> unresolved;

  int get resolved => total - unresolved.length;
}

Map<String, int> _count(Iterable<String?> keys) {
  final m = <String, int>{};
  for (final k in keys) {
    if (k == null || k.isEmpty) continue;
    m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

BulkSummary summarize(List<BulkEntry> entries, {List<String> bagOrder = const []}) {
  final resolved = entries.where((e) => e.resolved).toList();
  final bag = _count(resolved.map((e) => e.bagCode));
  final ordered = <String, int>{
    for (final b in bagOrder)
      if (bag.containsKey(b)) b: bag[b]!,
  };
  final rest = bag.keys.where((k) => !ordered.containsKey(k)).toList()..sort();
  for (final k in rest) {
    ordered[k] = bag[k]!;
  }
  String? hub(BulkEntry e) {
    if (e.l1Hub == null || e.l1Hub!.isEmpty) return null;
    return e.l2Hub == null || e.l2Hub!.isEmpty ? '→ ${e.l1Hub} (direct)' : '${e.l2Hub} → ${e.l1Hub}';
  }

  return BulkSummary(
    total: entries.length,
    byBag: ordered,
    byAir: _sorted(_count(entries.where((e) => e.pin != null).map((e) => e.airCode))),
    byConnectivity: _count(entries.where((e) => e.pin != null).map((e) => e.connectivity)),
    byHub: _sorted(_count(entries.where((e) => e.pin != null).map(hub))),
    unresolved: entries.where((e) => !e.resolved).toList(),
  );
}

Map<String, int> _sorted(Map<String, int> m) => Map.fromEntries(m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));

/// Plain-text tally for the manifest ("printable" text, monospace-friendly).
String summaryText(BulkSession s, BulkSummary sum, {required Map<String, Bag> bags, required Map<String, String> labels}) {
  final b = StringBuffer()
    ..writeln('${labels['title']}: ${s.name}')
    ..writeln('${labels['date']}: ${s.date}   ${labels['scheme']}: ${s.schemeName}')
    ..writeln('${labels['category']}: ${s.category}')
    ..writeln('${labels['total']}: ${sum.total}   ${labels['unresolved']}: ${sum.unresolved.length}')
    ..writeln('-' * 36);
  void section(String title, Map<String, int> m, [String Function(String)? name]) {
    if (m.isEmpty) return;
    b.writeln(title);
    for (final e in m.entries) {
      final label = name?.call(e.key) ?? e.key;
      b.writeln('  ${label.padRight(26)} ${e.value.toString().padLeft(5)}');
    }
    b.writeln('-' * 36);
  }

  section(labels['bags']!, sum.byBag, (k) => bags[k]?.label ?? k);
  section(labels['air']!, sum.byAir);
  section(labels['connectivity']!, sum.byConnectivity);
  section(labels['hubs']!, sum.byHub);
  if (sum.unresolved.isNotEmpty) {
    b.writeln(labels['unresolved']);
    for (final e in sum.unresolved) {
      b.writeln('  ${e.raw}');
    }
  }
  return b.toString();
}

/// CSV: one row per entry plus a bag tally block.
String summaryCsv(List<BulkEntry> entries, BulkSummary sum, Map<String, Bag> bags) {
  final rows = <List<Object?>>[
    ['Bag', 'Bag name', 'Count'],
    for (final e in sum.byBag.entries) [e.key, bags[e.key]?.name ?? '', e.value],
    [],
    if (sum.byAir.isNotEmpty) ...[
      ['Air code', 'Count'],
      for (final e in sum.byAir.entries) [e.key, e.value],
      [],
    ],
    if (sum.byConnectivity.isNotEmpty) ...[
      ['Connectivity', 'Count'],
      for (final e in sum.byConnectivity.entries) [e.key, e.value],
      [],
    ],
    if (sum.byHub.isNotEmpty) ...[
      ['Hub route', 'Count'],
      for (final e in sum.byHub.entries) [e.key, e.value],
      [],
    ],
    ['#', 'Entered', 'PIN', 'Bag', 'Air code', 'L2 hub', 'L1 hub', 'Connectivity', 'Time'],
    for (var i = 0; i < entries.length; i++)
      [
        i + 1, entries[i].raw, entries[i].pin, entries[i].bagCode, entries[i].airCode, entries[i].l2Hub, entries[i].l1Hub, //
        entries[i].connectivity, DateTime.fromMillisecondsSinceEpoch(entries[i].ts).toIso8601String().substring(11, 19),
      ],
  ];
  return '﻿${Csv(lineDelimiter: '\n').encode(rows)}';
}

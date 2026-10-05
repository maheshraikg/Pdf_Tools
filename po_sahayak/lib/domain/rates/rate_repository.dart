/// Reads assets/rates.json and finds the rate valid on a date.
library;

import 'dart:convert';

import 'package:decimal/decimal.dart';

import '../models/scheme.dart';

class RateEntry {
  const RateEntry(this.from, this.rate);
  final DateTime from;
  final Decimal rate;
}

class RateRepository {
  RateRepository._(this.version, this.validFrom, this._entries);

  /// Parses the rates.json format (see PLAN.md).
  factory RateRepository.fromJson(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final schemes = j['schemes'] as Map<String, dynamic>;
    final entries = <Scheme, List<RateEntry>>{};
    for (final e in schemes.entries) {
      final scheme = Scheme.fromCode(e.key);
      if (scheme == null) continue;
      final list = [
        for (final r in e.value as List)
          RateEntry(
            DateTime.parse((r as Map<String, dynamic>)['from'] as String),
            Decimal.parse(r['rate'].toString()),
          ),
      ]..sort((a, b) => b.from.compareTo(a.from));
      entries[scheme] = list;
    }
    return RateRepository._(
      j['version'] as String,
      DateTime.parse(j['validFrom'] as String),
      entries,
    );
  }

  /// e.g. "2026-Q3".
  final String version;

  /// Date the newest rate set took effect.
  final DateTime validFrom;
  final Map<Scheme, List<RateEntry>> _entries;

  /// The rate entry valid on [date], or null when rates.json has no rate
  /// that early (the user then types the rate).
  RateEntry? entryOn(Scheme s, DateTime date) {
    for (final e in _entries[s] ?? const <RateEntry>[]) {
      if (!e.from.isAfter(date)) return e;
    }
    return null;
  }

  /// The current (newest) rate.
  RateEntry current(Scheme s) => _entries[s]!.first;

  /// The rate a calculation should use: floating-rate schemes (SB, PPF, SSY)
  /// project with today's rate; the others keep the rate on [opening].
  RateEntry? rateFor(Scheme s, DateTime opening) =>
      s.rateFloats ? current(s) : entryOn(s, opening);
}

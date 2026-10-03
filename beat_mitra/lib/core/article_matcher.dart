/// Matches an article's address (OCR or typed) to saved places.
library;

import 'address_parser.dart';
import 'fuzzy.dart';

class MatchSuggestion {
  MatchSuggestion(this.placeId, this.score);
  final int placeId;
  final double score;
  @override
  String toString() => 'MatchSuggestion($placeId, ${score.toStringAsFixed(2)})';
}

/// Returns up to [limit] suggestions, best first.
///
/// The score combines the parts that were found in the address: addressee
/// name (45 %), door number (35 %), street (20 %) and area (10 %). A PIN that
/// differs from the place's PIN halves the score.
List<MatchSuggestion> matchAddress(
  ParsedAddress parsed,
  SearchIndex index, {
  String rawText = '',
  Map<int, String> pinOf = const {},
  int limit = 3,
  double minScore = 0.3,
  bool Function(int placeId)? filter,
}) {
  final candidates = <int>{};
  void add(String q) {
    if (q.trim().isEmpty) return;
    for (final h in index.search(q, limit: 30, minScore: 0.2)) {
      candidates.add(h.id);
    }
  }

  for (final n in parsed.names) {
    add(n);
  }
  if (parsed.doorNo != null) add('${parsed.doorNo} ${parsed.street ?? ''}');
  add(parsed.toQuery());
  if (parsed.isEmpty) add(rawText);

  final out = <MatchSuggestion>[];
  for (final id in candidates) {
    if (filter != null && !filter(id)) continue;
    var total = 0.0;
    var weight = 0.0;
    void part(double w, double? s) {
      if (s == null) return;
      total += w * s;
      weight += w;
    }

    if (parsed.names.isNotEmpty) {
      var best = 0.0;
      for (final n in parsed.names) {
        final s = index.fieldScore(id, 'name', n);
        if (s > best) best = s;
      }
      part(0.45, best);
    }
    if (parsed.doorNo != null) part(0.35, index.fieldScore(id, 'door', parsed.doorNo!));
    if (parsed.street != null) {
      final s1 = index.fieldScore(id, 'street', parsed.street!);
      final s2 = index.fieldScore(id, 'building', parsed.street!);
      part(0.2, s1 > s2 ? s1 : s2);
    }
    if (parsed.area != null) {
      final s1 = index.fieldScore(id, 'area', parsed.area!);
      final s2 = index.fieldScore(id, 'landmark', parsed.area!);
      part(0.1, s1 > s2 ? s1 : s2);
    }
    double score;
    if (weight == 0) {
      score = index.search(rawText, limit: 200).where((h) => h.id == id).map((h) => h.score).firstOrNull ?? 0;
    } else {
      score = total / weight;
    }
    final placePin = pinOf[id];
    if (parsed.pin != null && placePin != null && placePin.isNotEmpty && placePin != parsed.pin) score *= 0.5;
    if (score >= minScore) out.add(MatchSuggestion(id, score));
  }
  out.sort((a, b) {
    final c = b.score.compareTo(a.score);
    return c != 0 ? c : a.placeId.compareTo(b.placeId);
  });
  return out.length > limit ? out.sublist(0, limit) : out;
}

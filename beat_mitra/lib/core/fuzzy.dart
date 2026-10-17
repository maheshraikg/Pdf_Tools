/// Text normalisation, door-number normalisation and fuzzy ranking.
///
/// Everything here is pure Dart so it can be unit-tested and run fast on a
/// low-end phone (an in-memory index over 5,000 places answers in well under
/// 150 ms in release mode).
library;

import 'dart:math' as math;

import 'transliterate.dart';

/// Words that carry no meaning for matching ("No. 12", "#12", "Flat 3").
const Set<String> _stopWords = {
  'no',
  'num',
  'number',
  'flat',
  'door',
  'dno',
  'hno',
  'h',
  'd',
  'house',
  'to',
  'shri',
  'sri',
  'smt',
  'mr',
  'mrs',
  'ms',
  'dr',
  'near',
  'opp',
  'the',
  'of',
  'and',
  'c/o',
  'co',
};

/// Lowercase, transliterate Indic scripts, turn punctuation into spaces.
String normalizeText(String input) {
  var s = transliterate(input).toLowerCase();
  // "No." / "no:" -> "no"
  s = s.replaceAll(
    RegExp(
      r'[#.,:;()\[\]{}"'
      "'"
      r'!?|\\_]',
    ),
    ' ',
  );
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s;
}

/// Tokens of [input] without stop words. "/" and "-" are kept inside door
/// numbers ("12/3") but split elsewhere.
List<String> tokenize(String input) {
  final s = normalizeText(input);
  final out = <String>[];
  for (var t in s.split(' ')) {
    if (t.isEmpty) continue;
    if (!RegExp(r'^\d').hasMatch(t)) {
      // Split words joined by "-" or "/" (e.g. "hal-2nd").
      for (final part in t.split(RegExp(r'[/\-]'))) {
        if (part.isNotEmpty && !_stopWords.contains(part)) out.add(part);
      }
      continue;
    }
    t = t.replaceAll(RegExp(r'[/\-]+$'), '');
    if (t.isNotEmpty) out.add(t);
  }
  return out;
}

/// Compact form used for equality checks: lowercase latin, no spaces.
String normalizeCompact(String input) => tokenize(input).join();

final RegExp _ordinal = RegExp(r'^\d+(st|nd|rd|th)$');

/// Normalises a door number so that "12/3", "12-3", "No. 12 / 3", "#12/3"
/// compare equal ("12/3"). Ordinal words such as "3rd" (cross/main/floor)
/// are dropped: "#12 3rd" -> "12". A single letter after the number joins
/// it: "12 A" -> "12a".
String normalizeDoorNo(String input) {
  var s = transliterate(input).toLowerCase();
  s = s.replaceAll(RegExp(r'\b(h\s*\.?\s*no|d\s*\.?\s*no|door|house|flat|no|number|plot|site)\b\.?'), ' ');
  s = s.replaceAll(RegExp(r'[#:.,]'), ' ');
  s = s.replaceAll(RegExp(r'\s*[/\\\-]\s*'), '/');
  final parts = s.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  final kept = <String>[];
  for (final p in parts) {
    if (_ordinal.hasMatch(p)) continue;
    if (kept.isNotEmpty && RegExp(r'^[a-z]$').hasMatch(p) && RegExp(r'\d$').hasMatch(kept.last)) {
      kept[kept.length - 1] = '${kept.last}$p';
      continue;
    }
    if (RegExp(r'\d').hasMatch(p)) kept.add(p);
  }
  if (kept.isEmpty) return '';
  return kept.join('/').replaceAll(RegExp(r'/+'), '/').replaceAll(RegExp(r'^/|/$'), '');
}

/// Natural compare of door numbers: "2" < "10" < "10/1" < "10a" < "11".
int compareDoorNo(String a, String b) {
  final ra = RegExp(r'\d+|[^\d]+').allMatches(normalizeDoorNo(a)).map((m) => m[0]!).toList();
  final rb = RegExp(r'\d+|[^\d]+').allMatches(normalizeDoorNo(b)).map((m) => m[0]!).toList();
  for (var i = 0; i < math.min(ra.length, rb.length); i++) {
    final x = int.tryParse(ra[i]);
    final y = int.tryParse(rb[i]);
    final c = (x != null && y != null) ? x.compareTo(y) : ra[i].compareTo(rb[i]);
    if (c != 0) return c;
  }
  return ra.length.compareTo(rb.length);
}

/// Levenshtein distance; returns [max] + 1 early once the distance exceeds it.
int levenshtein(String a, String b, {int max = 1 << 30}) {
  if (a == b) return 0;
  if ((a.length - b.length).abs() > max) return max + 1;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  var cur = List<int>.filled(b.length + 1, 0);
  for (var i = 1; i <= a.length; i++) {
    cur[0] = i;
    var rowMin = cur[0];
    final ca = a.codeUnitAt(i - 1);
    for (var j = 1; j <= b.length; j++) {
      final cost = ca == b.codeUnitAt(j - 1) ? 0 : 1;
      final v = math.min(math.min(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost);
      cur[j] = v;
      if (v < rowMin) rowMin = v;
    }
    if (rowMin > max) return max + 1;
    final t = prev;
    prev = cur;
    cur = t;
  }
  return prev[b.length];
}

/// Character trigrams of " s " (padded).
Set<String> trigrams(String s) {
  final p = ' $s ';
  final out = <String>{};
  for (var i = 0; i + 3 <= p.length; i++) {
    out.add(p.substring(i, i + 3));
  }
  return out;
}

/// Dice coefficient of trigram sets.
double trigramSimilarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final ta = trigrams(a);
  final tb = trigrams(b);
  var inter = 0;
  for (final t in ta) {
    if (tb.contains(t)) inter++;
  }
  return 2 * inter / (ta.length + tb.length);
}

/// A pre-processed token (computed once when the index is built).
class IndexedToken {
  IndexedToken(this.text)
    : phonetic = phoneticKey(text),
      door = RegExp(r'^\d').hasMatch(text) ? normalizeDoorNo(text) : '';
  final String text;
  final String phonetic;
  final String door;
}

/// Similarity of one query token to one document token, 0..1.
double tokenSimilarity(IndexedToken q, IndexedToken d) {
  if (q.text == d.text) return 1.0;
  if (q.door.isNotEmpty || d.door.isNotEmpty) {
    if (q.door.isEmpty || d.door.isEmpty) return 0;
    if (q.door == d.door) return 1.0;
    // "12" matches "12/3" or "12a" well; "1" -> "12" weakly.
    if (d.door.startsWith('${q.door}/') || RegExp('^${RegExp.escape(q.door)}[a-z]\$').hasMatch(d.door)) {
      return 0.85;
    }
    if (d.door.startsWith(q.door)) return 0.5;
    return 0;
  }
  if (q.phonetic.isNotEmpty && q.phonetic == d.phonetic) return 0.95;
  if (q.text.length >= 2 && d.text.startsWith(q.text)) {
    return 0.75 + 0.15 * (q.text.length / d.text.length);
  }
  if (q.phonetic.length >= 2 && d.phonetic.startsWith(q.phonetic)) {
    return 0.7 + 0.1 * (q.phonetic.length / math.max(1, d.phonetic.length));
  }
  final ql = q.phonetic.length;
  if (ql >= 3) {
    final maxEd = ql >= 7 ? 2 : 1;
    final ed = levenshtein(q.phonetic, d.phonetic, max: maxEd);
    if (ed <= maxEd) return ed == 1 ? 0.8 : 0.65;
    final tri = trigramSimilarity(q.phonetic, d.phonetic);
    if (tri >= 0.5) return 0.6 * tri;
    if (ql >= 4 && d.text.contains(q.text)) return 0.5;
  }
  return 0;
}

/// One searchable record (a place) with weighted fields.
class SearchDoc {
  SearchDoc({required this.id, required Map<String, String> fields}) {
    for (final e in fields.entries) {
      final toks = tokenize(e.value).map(IndexedToken.new).toList();
      if (toks.isNotEmpty) this.fields[e.key] = toks;
    }
  }
  final int id;
  final Map<String, List<IndexedToken>> fields = {};
}

class SearchHit {
  SearchHit(this.id, this.score);
  final int id;
  final double score;
  @override
  String toString() => 'SearchHit($id, ${score.toStringAsFixed(3)})';
}

/// Field weights: a name or door number match beats an area match.
const Map<String, double> defaultFieldWeights = {
  'name': 1.0,
  'door': 1.0,
  'building': 0.9,
  'street': 0.85,
  'landmark': 0.8,
  'area': 0.7,
  'pin': 0.7,
  'notes': 0.4,
};

/// In-memory fuzzy index.
class SearchIndex {
  SearchIndex([Iterable<SearchDoc> docs = const []]) {
    for (final d in docs) {
      _docs[d.id] = d;
    }
  }

  final Map<int, SearchDoc> _docs = {};
  Map<String, double> weights = defaultFieldWeights;

  int get length => _docs.length;
  void put(SearchDoc d) => _docs[d.id] = d;
  void remove(int id) => _docs.remove(id);
  void clear() => _docs.clear();

  /// Ranked hits. Every query token contributes its best weighted match;
  /// a document missing a token entirely is penalised.
  List<SearchHit> search(String query, {int limit = 50, double minScore = 0.35}) {
    final qTokens = tokenize(query).map(IndexedToken.new).toList();
    if (qTokens.isEmpty) return const [];
    final hits = <SearchHit>[];
    for (final doc in _docs.values) {
      var total = 0.0;
      var missing = 0;
      for (final q in qTokens) {
        var best = 0.0;
        for (final f in doc.fields.entries) {
          final w = weights[f.key] ?? 0.5;
          if (w <= best) continue;
          for (final t in f.value) {
            final s = tokenSimilarity(q, t) * w;
            if (s > best) {
              best = s;
              if (best >= w) break;
            }
          }
        }
        if (best == 0) missing++;
        total += best;
      }
      if (missing == qTokens.length) continue;
      var score = total / qTokens.length;
      if (missing > 0) score *= 0.6;
      if (score >= minScore) hits.add(SearchHit(doc.id, score));
    }
    hits.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.id.compareTo(b.id);
    });
    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }

  /// Best match of [query] within a single field of a document (0..1).
  double fieldScore(int docId, String field, String query) {
    final doc = _docs[docId];
    final toks = doc?.fields[field];
    if (toks == null) return 0;
    final qTokens = tokenize(query).map(IndexedToken.new).toList();
    if (qTokens.isEmpty) return 0;
    var total = 0.0;
    for (final q in qTokens) {
      var best = 0.0;
      for (final t in toks) {
        best = math.max(best, tokenSimilarity(q, t));
      }
      total += best;
    }
    return total / qTokens.length;
  }

  Iterable<int> get ids => _docs.keys;
}

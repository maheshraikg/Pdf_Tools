/// Normalisation and similarity helpers for place-name search.
library;

import 'dart:math' as math;

import 'transliterate.dart';

/// Words that carry no place information in addresses / office names.
const Set<String> _noiseWords = {
  'post', 'office', 'po', 'bo', 'so', 'ho', 'gpo', 'hpo', 'spo', 'bpo', //
  'mdg', 'ndso', 'edso', 'edbo', 'tq', 'taluk', 'taluka', 'tal', 'dist', //
  'district', 'dt', 'via', 'at', 'and', 'the',
};

/// Old ↔ new spellings of renamed places, both directions resolve to the
/// first form. Public knowledge, used only to widen search.
const Map<String, List<String>> kPlaceAliases = {
  'bengaluru': ['bangalore'],
  'mangaluru': ['mangalore'],
  'mysuru': ['mysore'],
  'belagavi': ['belgaum'],
  'kalaburagi': ['gulbarga'],
  'hubballi': ['hubli'],
  'vijayapura': ['bijapur'],
  'shivamogga': ['shimoga'],
  'tumakuru': ['tumkur'],
  'ballari': ['bellary'],
  'chikkamagaluru': ['chikmagalur'],
  'hosapete': ['hospet'],
  'kolar': ['kolaru'],
  'mumbai': ['bombay'],
  'chennai': ['madras'],
  'kolkata': ['calcutta'],
  'thiruvananthapuram': ['trivandrum'],
  'kozhikode': ['calicut'],
  'kochi': ['cochin'],
  'thrissur': ['trichur'],
  'puducherry': ['pondicherry'],
  'gurugram': ['gurgaon'],
  'prayagraj': ['allahabad'],
  'varanasi': ['benares', 'banaras'],
  'vadodara': ['baroda'],
  'kanpur': ['cawnpore'],
  'tiruchirappalli': ['trichy', 'tiruchirapalli'],
  'thoothukudi': ['tuticorin'],
  'visakhapatnam': ['vizag', 'vishakhapatnam'],
};

final RegExp _nonAlnum = RegExp(r'[^a-z0-9]+');

/// Normalises a place / office name for comparison:
/// transliterates Kannada/Devanagari, lowercases, strips diacritics,
/// removes office-type suffixes ("B.O", "S.O", "Post", "P.O"), spaces, dots.
/// "Puttur S.O" → "puttur"; "ಪುತ್ತೂರು" → "puttur".
String normalizePlace(String input) {
  var s = transliterate(input).toLowerCase();
  s = _stripDiacritics(s);
  // Join dotted abbreviations: "b.o" → "bo", "p. o." → "po".
  s = s.replaceAllMapped(RegExp(r'\b([a-z])\s*\.\s*([a-z])\b\.?'), (m) => '${m[1]}${m[2]}');
  final words = s.split(_nonAlnum).where((w) => w.isNotEmpty).toList();
  // Drop noise words only when something else remains ("Post" alone stays).
  final kept = words.where((w) => !_noiseWords.contains(w)).toList();
  return (kept.isEmpty ? words : kept).join();
}

/// Splits a normalised-with-spaces version into words (for token matching).
List<String> placeWords(String input) {
  var s = _stripDiacritics(transliterate(input).toLowerCase());
  s = s.replaceAllMapped(RegExp(r'\b([a-z])\s*\.\s*([a-z])\b\.?'), (m) => '${m[1]}${m[2]}');
  return s.split(_nonAlnum).where((w) => w.isNotEmpty && !_noiseWords.contains(w)).toList();
}

/// Canonical name if [norm] is a known alias (e.g. "bangalore" → "bengaluru").
String? canonicalAlias(String norm) {
  for (final e in kPlaceAliases.entries) {
    if (e.key == norm) return null;
    if (e.value.contains(norm)) return e.key;
  }
  return null;
}

/// All spellings to search for [norm] (itself plus aliases).
List<String> aliasVariants(String norm) {
  final canon = canonicalAlias(norm) ?? norm;
  final list = kPlaceAliases[canon];
  return {norm, canon, ...?list}.toList();
}

/// A coarse phonetic key so that spelling variants collide:
/// "Puttoor", "Putur", "Puttur", "ಪುತ್ತೂರು" → "putur".
String phoneticKey(String norm) {
  var s = norm.replaceAll(RegExp(r'[^a-z]'), '');
  const pairs = [
    ['ph', 'f'], ['bh', 'b'], ['dh', 'd'], ['th', 't'], ['kh', 'k'], //
    ['gh', 'g'], ['jh', 'j'], ['sh', 's'], ['chh', 'c'], ['ch', 'c'], //
    ['ck', 'k'], ['q', 'k'], ['x', 'ks'], ['w', 'v'], ['z', 'j'], //
    ['ee', 'i'], ['oo', 'u'], ['ou', 'u'], ['aa', 'a'], ['ai', 'y'], //
    ['ay', 'y'], ['ey', 'y'], ['ie', 'i'], ['c', 'k'], ['h', ''], //
  ];
  for (final p in pairs) {
    s = s.replaceAll(p[0], p[1]);
  }
  // Collapse runs of the same letter.
  final sb = StringBuffer();
  int? last;
  for (final c in s.codeUnits) {
    if (c != last) sb.writeCharCode(c);
    last = c;
  }
  s = sb.toString();
  // Drop trailing vowels (Kannada/Hindi endings: -u, -a, -e).
  while (s.length > 3 && 'aeiouy'.contains(s[s.length - 1])) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Levenshtein distance; returns [max] + 1 early when the distance is
/// certainly above [max].
int levenshtein(String a, String b, {int? max}) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final limit = max ?? math.max(a.length, b.length);
  if ((a.length - b.length).abs() > limit) return limit + 1;
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
    if (rowMin > limit) return limit + 1;
    final t = prev;
    prev = cur;
    cur = t;
  }
  return prev[b.length];
}

/// Edit distance tolerated between phonetic keys of this length.
int maxEditsFor(int length) => length >= 10 ? 3 : length >= 6 ? 2 : length >= 3 ? 1 : 0;

Set<String> trigrams(String s) {
  final p = '  $s ';
  return {for (var i = 0; i + 3 <= p.length; i++) p.substring(i, i + 3)};
}

/// Jaccard similarity of padded trigrams (0..1).
double trigramSimilarity(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final ta = trigrams(a), tb = trigrams(b);
  final inter = ta.intersection(tb).length;
  return inter / (ta.length + tb.length - inter);
}

/// Match score of a normalised query against a normalised candidate
/// (0 = unrelated, 1 = exact). Combines exact/prefix/containment, phonetic
/// key, edit distance and trigram overlap.
double placeSimilarity(String query, String candidate, {String? queryKey, String? candidateKey}) {
  if (query.isEmpty || candidate.isEmpty) return 0;
  if (query == candidate) return 1;
  final qk = queryKey ?? phoneticKey(query);
  final ck = candidateKey ?? phoneticKey(candidate);
  var best = 0.0;
  if (candidate.startsWith(query)) {
    best = 0.9 + 0.08 * (query.length / candidate.length);
  } else if (candidate.contains(query) && query.length >= 3) {
    best = 0.75 + 0.1 * (query.length / candidate.length);
  }
  if (qk == ck) best = math.max(best, 0.93);
  if (qk.length >= 3 && ck.startsWith(qk)) {
    best = math.max(best, 0.8 + 0.1 * (qk.length / ck.length));
  }
  final allowed = maxEditsFor(math.max(qk.length, ck.length));
  if (allowed > 0) {
    final d = levenshtein(qk, ck, max: allowed);
    if (d <= allowed) best = math.max(best, 0.92 - 0.12 * d);
  }
  best = math.max(best, 0.85 * trigramSimilarity(query, candidate));
  return best.clamp(0, 1).toDouble();
}

String _stripDiacritics(String s) {
  const from = 'āáàâäãåēéèêëīíìîïōóòôöõūúùûüṅñṇṭḍṛṣśḷḥṃçý';
  const to = 'aaaaaaaeeeeeiiiiioooooouuuuunnntdrsslhmcy';
  if (!s.runes.any((r) => r > 0x7F)) return s;
  final sb = StringBuffer();
  for (final ch in s.split('')) {
    final i = from.indexOf(ch);
    sb.write(i >= 0 ? to[i] : ch);
  }
  return sb.toString();
}

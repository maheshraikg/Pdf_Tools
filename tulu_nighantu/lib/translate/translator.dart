import '../lipi/tulu_lipi.dart';
import '../models/word.dart';

/// One piece of a translation: a source chunk and the Tulu word found for it.
class TranslationPiece {
  const TranslationPiece(this.source, this.word, {this.approximate = false});

  /// The Kannada/English text this piece came from.
  final String source;

  /// The dictionary entry, or null when nothing matched.
  final Word? word;

  /// True when matched by stem only (e.g. Kannada with a case suffix).
  final bool approximate;

  bool get found => word != null;
}

/// Result of translating a Kannada or English text into Tulu.
class Translation {
  const Translation({this.phrase, this.pieces = const []});

  /// Set when the whole input matched a phrase entry.
  final Word? phrase;

  /// Word-by-word pieces (empty when [phrase] is set).
  final List<TranslationPiece> pieces;

  bool get isEmpty => phrase == null && pieces.isEmpty;

  /// Tulu in Kannada script; unknown words are kept as typed.
  String get tulu =>
      phrase?.tulu ?? pieces.map((p) => p.word?.tulu ?? p.source).join(' ');

  /// Tulu in Tulu-Tigalari script.
  String get lipi => TuluLipi.fromKannada(tulu);

  /// Romanised Tulu (unknown words shown as "?").
  String get roman =>
      phrase?.roman ?? pieces.map((p) => p.word?.roman ?? '?').join(' ');

  int get foundCount =>
      phrase != null ? 1 : pieces.where((p) => p.found).length;

  bool get complete => phrase != null || pieces.every((p) => p.found);
}

/// Offline, dictionary-based Kannada/English → Tulu translator.
///
/// It matches whole phrases first, then words (longest multi-word meaning
/// first, e.g. "elder brother"). It does not do grammar: the output is a
/// word-for-word gloss built only from verified dictionary entries.
class Translator {
  Translator(List<Word> words) {
    for (final w in words) {
      if (w.isPhrase) {
        for (final k in [_phraseKey(w.kn), _phraseKey(w.en)]) {
          if (k.isNotEmpty) _phrases.putIfAbsent(k, () => w);
        }
      }
      for (final k in _meaningKeys(w)) {
        final existing = _index[k];
        // Prefer single words over phrases for word lookups.
        if (existing == null || (existing.isPhrase && !w.isPhrase)) {
          _index[k] = w;
        }
      }
    }
    for (final k in _index.keys) {
      final n = k.split(' ').length;
      if (n > _maxWords) _maxWords = n;
    }
    for (final e in _index.entries) {
      final stem = _kannadaStem(e.key);
      if (stem != null) _stems.putIfAbsent(stem, () => e.value);
    }
  }

  final Map<String, Word> _index = {};
  final Map<String, Word> _phrases = {};
  final Map<String, Word> _stems = {};
  int _maxWords = 1;

  static const Set<String> _englishFillers = {
    'a',
    'an',
    'the',
    'is',
    'am',
    'are',
    'was',
    'to',
    'of',
    'please',
  };

  static final RegExp _punct = RegExp(r'''[.,!?;:"'“”‘’()\[\]…]''');
  static final RegExp _space = RegExp(r'\s+');

  /// Lowercases and strips punctuation and extra spaces.
  static String _norm(String s) =>
      TuluLipi.normalizeKannada(s)
          .toLowerCase()
          .replaceAll(_punct, ' ')
          .replaceAll(_space, ' ')
          .trim();

  static String _phraseKey(String s) =>
      _norm(s.replaceAll('...', '').replaceAll(RegExp(r'\([^)]*\)'), ''));

  /// Lookup keys for a word: each Kannada/English meaning part, with and
  /// without parenthetical notes ("rice (uncooked)" → both forms).
  static Iterable<String> _meaningKeys(Word w) sync* {
    for (final meaning in [w.kn, w.en]) {
      for (final part in meaning.split(RegExp(r'[;,/]'))) {
        final full = _norm(part);
        if (full.isNotEmpty) yield full;
        final bare = _norm(part.replaceAll(RegExp(r'\([^)]*\)'), ''));
        if (bare.isNotEmpty && bare != full) yield bare;
      }
    }
  }

  /// Kannada stem: the key without its final vowel sign (ನೀರು → ನೀರ), so
  /// inflected input like ನೀರನ್ನು still finds ನೀರ್.
  static String? _kannadaStem(String key) {
    if (!TuluLipi.hasKannada(key) || key.contains(' ')) return null;
    final runes = key.runes.toList();
    final last = runes.last;
    final isSign = (last >= 0x0CBE && last <= 0x0CCC) || last == 0x0CCD;
    final stem = isSign ? runes.sublist(0, runes.length - 1) : runes;
    return stem.length >= 2 ? String.fromCharCodes(stem) : null;
  }

  /// Translates [input] (Kannada or English, any mix) into Tulu.
  Translation translate(String input) {
    final whole = _phraseKey(input);
    if (whole.isEmpty) return const Translation();
    final phrase = _phrases[whole];
    if (phrase != null) return Translation(phrase: phrase);

    final tokens = whole.split(' ');
    final pieces = <TranslationPiece>[];
    var i = 0;
    while (i < tokens.length) {
      Word? hit;
      var used = 1;
      for (var n = _maxWords.clamp(1, tokens.length - i); n >= 1; n--) {
        final w = _index[tokens.sublist(i, i + n).join(' ')];
        if (w != null) {
          hit = w;
          used = n;
          break;
        }
      }
      final tok = tokens[i];
      if (hit != null) {
        pieces.add(
          TranslationPiece(tokens.sublist(i, i + used).join(' '), hit),
        );
      } else if (_englishFillers.contains(tok)) {
        // Articles and "is/are" have no separate Tulu word here; skip.
      } else {
        pieces.add(_fallback(tok));
      }
      i += used;
    }
    return Translation(pieces: pieces);
  }

  /// Plural English and inflected Kannada fallbacks.
  TranslationPiece _fallback(String tok) {
    if (!TuluLipi.hasKannada(tok)) {
      for (final base in [
        if (tok.endsWith('ies')) '${tok.substring(0, tok.length - 3)}y',
        if (tok.endsWith('es')) tok.substring(0, tok.length - 2),
        if (tok.endsWith('s')) tok.substring(0, tok.length - 1),
      ]) {
        final w = _index[base];
        if (w != null) return TranslationPiece(tok, w, approximate: true);
      }
      return TranslationPiece(tok, null);
    }
    // Longest stem that the token starts with.
    Word? best;
    var bestLen = 0;
    for (final e in _stems.entries) {
      final len = e.key.runes.length;
      if (len > bestLen && tok.startsWith(e.key)) {
        best = e.value;
        bestLen = len;
      }
    }
    return TranslationPiece(tok, best, approximate: best != null);
  }
}

/// Simple table-based transliteration of Kannada and Devanagari (Hindi,
/// Marathi) text into plain lowercase ASCII, tuned for matching place names
/// against the English spellings in the PIN directory — not a scholarly
/// romanisation. Long and short vowels map to the same letter; retroflex and
/// dental consonants map to the same letter.
library;

class _Script {
  const _Script({
    required this.consonants,
    required this.vowels,
    required this.matras,
    required this.virama,
    required this.anusvara,
    required this.visarga,
    this.chandrabindu,
    this.nukta,
    this.nuktaMap = const {},
    this.extra = const {},
  });

  final Map<int, String> consonants;
  final Map<int, String> vowels;
  final Map<int, String> matras;
  final int virama;
  final int anusvara;
  final int visarga;
  final int? chandrabindu;
  final int? nukta;
  final Map<String, String> nuktaMap;
  final Map<int, String> extra;
}

Map<int, String> _seq(int start, List<String?> values) => {
  for (var i = 0; i < values.length; i++)
    if (values[i] != null) start + i: values[i]!,
};

// Consonant order is identical in both scripts (ka..ha, 0x15..0x39 offset).
const List<String?> _consonantOrder = [
  'k', 'kh', 'g', 'gh', 'n', // ka-varga
  'ch', 'chh', 'j', 'jh', 'n', // cha-varga
  't', 'th', 'd', 'dh', 'n', // retroflex
  't', 'th', 'd', 'dh', 'n', // dental
  'n', // 0x29 (nnna, Tamil-only in Devanagari)
  'p', 'ph', 'b', 'bh', 'm', // pa-varga
  'y', 'r', 'r', 'l', 'l', 'l', 'v', // ya ra rra la lla llla va
  'sh', 'sh', 's', 'h', // sha ssa sa ha
];

final _Script _kannada = _Script(
  consonants: _seq(0x0C95, _consonantOrder)..[0x0CDE] = 'l',
  vowels: _seq(0x0C85, [
    'a', 'a', 'i', 'i', 'u', 'u', 'ru', 'lu', null, 'e', 'e', 'ai', null, //
    'o', 'o', 'au',
  ]),
  matras: _seq(0x0CBE, [
    'a', 'i', 'i', 'u', 'u', 'ru', 'ru', null, 'e', 'e', 'ai', null, //
    'o', 'o', 'au',
  ]),
  virama: 0x0CCD,
  anusvara: 0x0C82,
  visarga: 0x0C83,
);

final _Script _devanagari = _Script(
  consonants: _seq(0x0915, _consonantOrder),
  vowels: {
    ..._seq(0x0904, [
      'a', 'a', 'a', 'i', 'i', 'u', 'u', 'ri', 'li', 'e', 'e', 'e', 'ai', //
      'o', 'o', 'o', 'au',
    ]),
  },
  matras: {
    ..._seq(0x093E, [
      'a', 'i', 'i', 'u', 'u', 'ri', 'ri', 'e', 'e', 'e', 'ai', 'o', 'o', //
      'o', 'au',
    ]),
  },
  virama: 0x094D,
  anusvara: 0x0902,
  visarga: 0x0903,
  chandrabindu: 0x0901,
  nukta: 0x093C,
  nuktaMap: {'k': 'q', 'kh': 'kh', 'g': 'g', 'j': 'z', 'ph': 'f', 'd': 'r', 'dh': 'rh'},
  // Precomposed nukta letters.
  extra: {
    0x0958: 'q', 0x0959: 'kh', 0x095A: 'g', 0x095B: 'z', //
    0x095C: 'r', 0x095D: 'rh', 0x095E: 'f', 0x095F: 'y',
  },
);

bool _isLabial(String? c) => c != null && (c.startsWith('p') || c.startsWith('b') || c == 'm');

_Script? _scriptOf(int rune) {
  if (rune >= 0x0C80 && rune <= 0x0CFF) return _kannada;
  if (rune >= 0x0900 && rune <= 0x097F) return _devanagari;
  return null;
}

/// True if [text] contains any Kannada or Devanagari letter.
bool hasIndicScript(String text) => text.runes.any((r) => _scriptOf(r) != null);

/// Transliterates Kannada / Devanagari runs in [text] to lowercase ASCII;
/// other characters are kept (lowercased). Digits are left untouched — use
/// PinUtils.normalizeDigits for those.
///
/// Place-name heuristics:
/// * Devanagari: word-final inherent "a" is dropped (पुत्तूर → puttur).
/// * Kannada: a word-final "u" after r/l is dropped, since Kannada adds it to
///   names that end in a consonant in English (ಪುತ್ತೂರು → puttur,
///   ಮಂಗಳೂರು → mangalur).
String transliterate(String text) {
  final runes = text.runes.toList();
  final out = StringBuffer();
  var i = 0;
  while (i < runes.length) {
    final r = runes[i];
    final s = _scriptOf(r);
    if (s == null) {
      out.write(String.fromCharCode(r).toLowerCase());
      i++;
      continue;
    }
    // Collect one word in this script.
    final word = StringBuffer();
    while (i < runes.length && _scriptOf(runes[i]) == s) {
      i = _translitSyllable(s, runes, i, word);
    }
    out.write(_postProcessWord(s, word.toString()));
  }
  return out.toString();
}

String _postProcessWord(_Script s, String w) {
  if (identical(s, _devanagari)) {
    // Drop final inherent 'a' (marked with \u0000 during the syllable pass).
    if (w.endsWith('\u0000') && w.length > 2) {
      w = w.substring(0, w.length - 1);
    }
  } else if (w.length > 3 && (w.endsWith('ru') || w.endsWith('lu'))) {
    w = w.substring(0, w.length - 1);
  }
  return w.replaceAll('\u0000', 'a');
}

/// Transliterates the syllable starting at [i]; returns the next index.
int _translitSyllable(_Script s, List<int> runes, int i, StringBuffer out) {
  final r = runes[i];
  String? cons = s.consonants[r] ?? s.extra[r];
  if (cons != null) {
    var j = i + 1;
    if (s.nukta != null && j < runes.length && runes[j] == s.nukta) {
      cons = s.nuktaMap[cons] ?? cons;
      j++;
    }
    out.write(cons);
    if (j < runes.length) {
      final next = runes[j];
      if (next == s.virama) return j + 1;
      final m = s.matras[next];
      if (m != null) {
        out.write(m);
        return j + 1;
      }
    }
    // Inherent vowel. For Devanagari it is marked with \u0000 so the word
    // pass can drop it at the end of a word (schwa deletion).
    out.write(identical(s, _devanagari) ? '\u0000' : 'a');
    return j;
  }
  final v = s.vowels[r];
  if (v != null) {
    out.write(v);
    return i + 1;
  }
  if (r == s.anusvara || r == s.chandrabindu) {
    // Nasal: 'm' before labials, else 'n'.
    String? nextCons;
    if (i + 1 < runes.length) nextCons = s.consonants[runes[i + 1]];
    out.write(_isLabial(nextCons) ? 'm' : 'n');
    return i + 1;
  }
  if (r == s.visarga) {
    out.write('h');
    return i + 1;
  }
  // Stray matra / virama / nukta / danda / other signs: matras still carry
  // their vowel, the rest are dropped.
  final m = s.matras[r];
  if (m != null) out.write(m);
  if (r == 0x0964 || r == 0x0965) out.write(' ');
  return i + 1;
}

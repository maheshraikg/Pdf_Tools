/// English-letter (romanised) input → Kannada script, so that "mahesh"
/// becomes ಮಹೇಶ್ and then the same Tulu lipi as typing ಮಹೇಶ್.
///
/// The scheme is the common Baraha/Nudi one: a aa i ee/ii u oo/uu e ai o au,
/// k kh g gh c/ch chh j jh T Th D Dh N t th d dh n p ph/f b bh m y r l v/w
/// sh Sh s h L, M = ಂ, H = ಃ. Capital letters select the retroflex (T D N
/// L Sh) or long (A I U E O) sounds, except a capital first letter of a word
/// ("Mahesh") or a fully capitalised word ("MAHESH"), which are read as
/// ordinary letters. E/e and O/o give the same Tulu letter either way.
library;

/// True when [s] contains an English (ASCII) letter.
bool hasLatin(String s) => RegExp('[A-Za-z]').hasMatch(s);

const Map<String, String> _consonants = {
  'ksh': 'ಕ್ಷ',
  'chh': 'ಛ',
  'kh': 'ಖ',
  'gh': 'ಘ',
  'ch': 'ಚ',
  'jh': 'ಝ',
  'Th': 'ಠ',
  'Dh': 'ಢ',
  'th': 'ಥ',
  'dh': 'ಧ',
  'ph': 'ಫ',
  'bh': 'ಭ',
  'Sh': 'ಷ',
  'sh': 'ಶ',
  'k': 'ಕ',
  'g': 'ಗ',
  'c': 'ಚ',
  'j': 'ಜ',
  'T': 'ಟ',
  'D': 'ಡ',
  'N': 'ಣ',
  't': 'ತ',
  'd': 'ದ',
  'n': 'ನ',
  'p': 'ಪ',
  'f': 'ಫ',
  'b': 'ಬ',
  'm': 'ಮ',
  'y': 'ಯ',
  'r': 'ರ',
  'l': 'ಲ',
  'L': 'ಳ',
  'v': 'ವ',
  'w': 'ವ',
  's': 'ಸ',
  'h': 'ಹ',
  'z': 'ಜ',
  'q': 'ಕ',
  'x': 'ಕ್ಸ',
};

/// Vowel → (independent letter, sign after a consonant). An empty sign is
/// the inherent "a".
const Map<String, (String, String)> _vowels = {
  'aa': ('ಆ', 'ಾ'),
  'ai': ('ಐ', 'ೈ'),
  'au': ('ಔ', 'ೌ'),
  'ou': ('ಔ', 'ೌ'),
  'ee': ('ಈ', 'ೀ'),
  'ii': ('ಈ', 'ೀ'),
  'oo': ('ಊ', 'ೂ'),
  'uu': ('ಊ', 'ೂ'),
  'A': ('ಆ', 'ಾ'),
  'I': ('ಈ', 'ೀ'),
  'U': ('ಊ', 'ೂ'),
  'E': ('ಏ', 'ೇ'),
  'O': ('ಓ', 'ೋ'),
  'a': ('ಅ', ''),
  'i': ('ಇ', 'ಿ'),
  'u': ('ಉ', 'ು'),
  'e': ('ಏ', 'ೇ'),
  'o': ('ಓ', 'ೋ'),
};

const String _virama = '್';

/// Lower-cases a capitalised ("Mahesh") or all-caps ("MAHESH") word so
/// its first letter is not read as a special capital.
String _caseFold(String word) {
  if (word.length > 1 && word == word.toUpperCase()) return word.toLowerCase();
  if (word.isNotEmpty &&
      word[0] != word[0].toLowerCase() &&
      word.substring(1) == word.substring(1).toLowerCase()) {
    return word[0].toLowerCase() + word.substring(1);
  }
  return word;
}

/// Converts the English-letter parts of [input] to Kannada script; anything
/// else (Kannada, digits, punctuation) is kept as it is.
String romanToKannada(String input) {
  final out = StringBuffer();
  for (final m in RegExp(r'[A-Za-z]+|[^A-Za-z]+').allMatches(input)) {
    final part = m[0]!;
    out.write(hasLatin(part) ? _word(_caseFold(part)) : part);
  }
  return out.toString();
}

String _word(String w) {
  final out = StringBuffer();
  var pending = false; // last output is a consonant still needing a vowel
  var i = 0;
  while (i < w.length) {
    String? cons;
    (String, String)? vowel;
    var len = 0;
    for (var n = 3; n >= 1 && cons == null && vowel == null; n--) {
      if (i + n > w.length) continue;
      final t = w.substring(i, i + n);
      if (_consonants.containsKey(t)) {
        cons = _consonants[t];
        len = n;
      } else if (_vowels.containsKey(t)) {
        vowel = _vowels[t];
        len = n;
      }
    }
    if (cons != null) {
      if (pending) out.write(_virama);
      out.write(cons);
      pending = true;
    } else if (vowel != null) {
      out.write(pending ? vowel.$2 : vowel.$1);
      pending = false;
    } else {
      final ch = w[i];
      len = 1;
      if (ch == 'M') {
        out.write('ಂ');
      } else if (ch == 'H') {
        out.write('ಃ');
      } else {
        if (pending) out.write(_virama);
        out.write(ch);
      }
      pending = false;
    }
    i += len;
  }
  if (pending) out.write(_virama);
  return out.toString();
}

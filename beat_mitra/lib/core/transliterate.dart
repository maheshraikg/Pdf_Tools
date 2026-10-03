/// Table-based transliteration of Kannada and Devanagari (Hindi/Marathi)
/// text to simple Latin, plus a phonetic key used for fuzzy matching.
///
/// Both scripts follow the ISCII layout, so the same offset table works for
/// Kannada (U+0C80..U+0CFF) and Devanagari (U+0900..U+097F).
library;

const int _devaBase = 0x0900;
const int _kannBase = 0x0C80;

/// Independent vowels (offset -> latin).
const Map<int, String> _vowels = {
  0x05: 'a',
  0x06: 'aa',
  0x07: 'i',
  0x08: 'ee',
  0x09: 'u',
  0x0A: 'oo',
  0x0B: 'ri',
  0x0C: 'li',
  0x0D: 'e',
  0x0E: 'e',
  0x0F: 'e',
  0x10: 'ai',
  0x11: 'o',
  0x12: 'o',
  0x13: 'o',
  0x14: 'au',
  0x60: 'ri',
  0x61: 'li',
};

/// Consonants without the inherent vowel.
const Map<int, String> _consonants = {
  0x15: 'k',
  0x16: 'kh',
  0x17: 'g',
  0x18: 'gh',
  0x19: 'n',
  0x1A: 'ch',
  0x1B: 'chh',
  0x1C: 'j',
  0x1D: 'jh',
  0x1E: 'n',
  0x1F: 't',
  0x20: 'th',
  0x21: 'd',
  0x22: 'dh',
  0x23: 'n',
  0x24: 't',
  0x25: 'th',
  0x26: 'd',
  0x27: 'dh',
  0x28: 'n',
  0x29: 'n',
  0x2A: 'p',
  0x2B: 'ph',
  0x2C: 'b',
  0x2D: 'bh',
  0x2E: 'm',
  0x2F: 'y',
  0x30: 'r',
  0x31: 'r',
  0x32: 'l',
  0x33: 'l',
  0x34: 'l',
  0x35: 'v',
  0x36: 'sh',
  0x37: 'sh',
  0x38: 's',
  0x39: 'h',
  // Devanagari nukta letters.
  0x58: 'q',
  0x59: 'kh',
  0x5A: 'g',
  0x5B: 'z',
  0x5C: 'd',
  0x5D: 'rh',
  0x5E: 'f',
  0x5F: 'y',
};

/// Dependent vowel signs (matras).
const Map<int, String> _matras = {
  0x3E: 'aa',
  0x3F: 'i',
  0x40: 'ee',
  0x41: 'u',
  0x42: 'oo',
  0x43: 'ri',
  0x44: 'ri',
  0x45: 'e',
  0x46: 'e',
  0x47: 'e',
  0x48: 'ai',
  0x49: 'o',
  0x4A: 'o',
  0x4B: 'o',
  0x4C: 'au',
  0x62: 'li',
  0x63: 'li',
};

const int _virama = 0x4D;
const int _nukta = 0x3C;
const int _anusvara = 0x02;
const int _candrabindu = 0x01;
const int _visarga = 0x03;

enum _Script { none, deva, kann }

_Script _scriptOf(int cp) {
  if (cp >= _devaBase && cp <= 0x097F) return _Script.deva;
  if (cp >= _kannBase && cp <= 0x0CFF) return _Script.kann;
  return _Script.none;
}

/// True when [s] contains any Kannada or Devanagari character.
bool hasIndicScript(String s) {
  for (final cp in s.runes) {
    if (_scriptOf(cp) != _Script.none) return true;
  }
  return false;
}

/// Transliterates Kannada / Devanagari characters in [input] to Latin.
/// Other characters are copied unchanged. Indic digits become ASCII digits.
///
/// Hindi (Devanagari) words drop the final inherent "a" (schwa deletion),
/// so "रमेश" -> "ramesh"; Kannada keeps it ("ರಮೇಶ" -> "ramesha").
String transliterate(String input) {
  final cps = input.runes.toList();
  final out = StringBuffer();
  var i = 0;
  while (i < cps.length) {
    final cp = cps[i];
    final script = _scriptOf(cp);
    if (script == _Script.none) {
      out.writeCharCode(cp);
      i++;
      continue;
    }
    final base = script == _Script.deva ? _devaBase : _kannBase;
    final off = cp - base;

    // Digits.
    if (off >= 0x66 && off <= 0x6F) {
      out.write(off - 0x66);
      i++;
      continue;
    }
    // Kannada letter FA (U+0CDE) — treat as 'l' (ancient LLLA).
    if (script == _Script.kann && off == 0x5E) {
      out.write('l');
      i++;
      continue;
    }

    final vowel = _vowels[off];
    if (vowel != null) {
      out.write(vowel);
      i++;
      continue;
    }

    final cons = _consonants[off];
    if (cons != null) {
      out.write(cons);
      i++;
      // Skip nukta.
      if (i < cps.length && cps[i] - base == _nukta) i++;
      if (i < cps.length && _scriptOf(cps[i]) == script) {
        final nextOff = cps[i] - base;
        if (nextOff == _virama) {
          i++; // dead consonant
          continue;
        }
        final matra = _matras[nextOff];
        if (matra != null) {
          out.write(matra);
          i++;
          continue;
        }
      }
      // Inherent vowel.
      final atWordEnd = i >= cps.length || !_isIndicLetterOrSign(cps[i]);
      if (script == _Script.deva && atWordEnd && _aksharaCountBefore(cps, i) > 1) {
        // schwa deletion at word end for Hindi.
      } else {
        out.write('a');
      }
      continue;
    }

    if (off == _anusvara || off == _candrabindu) {
      // Labial assimilation: m before p/b/m, else n.
      var next = '';
      if (i + 1 < cps.length && _scriptOf(cps[i + 1]) == script) {
        next = _consonants[cps[i + 1] - base] ?? '';
      }
      out.write(next.startsWith('p') || next.startsWith('b') || next.startsWith('m') ? 'm' : 'n');
      i++;
      continue;
    }
    if (off == _visarga) {
      out.write('h');
      i++;
      continue;
    }
    // Danda, avagraha, nukta, length marks etc.: drop (danda -> space).
    if (cp == 0x0964 || cp == 0x0965) out.write(' ');
    i++;
  }
  return out.toString();
}

bool _isIndicLetterOrSign(int cp) {
  final s = _scriptOf(cp);
  if (s == _Script.none) return false;
  final off = cp - (s == _Script.deva ? _devaBase : _kannBase);
  // Exclude digits and danda.
  if (off >= 0x64 && off <= 0x6F) return false;
  return true;
}

/// Number of consonant/vowel letters in the current word up to [end].
int _aksharaCountBefore(List<int> cps, int end) {
  var count = 0;
  var j = end - 1;
  while (j >= 0 && _isIndicLetterOrSign(cps[j])) {
    final s = _scriptOf(cps[j]);
    final off = cps[j] - (s == _Script.deva ? _devaBase : _kannBase);
    if (_consonants.containsKey(off) || _vowels.containsKey(off)) count++;
    j--;
  }
  return count;
}

/// A coarse phonetic key so that spelling variants match:
/// "Ramesh", "Rameshh", "Ramesha", "ರಮೇಶ್", "रमेश" all -> "rames".
String phoneticKey(String word) {
  var s = transliterate(word).toLowerCase();
  s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (s.isEmpty) return s;
  if (RegExp(r'^[0-9]+$').hasMatch(s)) return s;
  // Long vowels first, then collapse doubled letters.
  for (final r in const [
    ['ee', 'i'],
    ['ii', 'i'],
    ['oo', 'u'],
    ['uu', 'u'],
    ['aa', 'a'],
  ]) {
    s = s.replaceAll(r[0], r[1]);
  }
  s = s.replaceAllMapped(RegExp(r'([a-z])\1+'), (m) => m[1]!);
  const rules = <List<String>>[
    ['chh', 'c'],
    ['ch', 'c'],
    ['sh', 's'],
    ['kh', 'k'],
    ['gh', 'g'],
    ['jh', 'j'],
    ['th', 't'],
    ['dh', 'd'],
    ['ph', 'f'],
    ['bh', 'b'],
    ['rh', 'r'],
    ['ck', 'k'],
    ['ou', 'u'],
    ['au', 'u'],
    ['w', 'v'],
    ['z', 'j'],
    ['q', 'k'],
    ['x', 'ks'],
    ['y', 'i'],
  ];
  for (final r in rules) {
    s = s.replaceAll(r[0], r[1]);
  }
  s = s.replaceAllMapped(RegExp(r'([a-z])\1+'), (m) => m[1]!);
  // Drop trailing inherent vowel / aspiration.
  if (s.length > 3 && (s.endsWith('a') || s.endsWith('h'))) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

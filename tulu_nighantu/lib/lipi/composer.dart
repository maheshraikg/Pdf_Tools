/// Editing rules for the in-app Tulu lipi keyboard. Text is kept in Kannada
/// script (the source for [TuluLipi.fromKannada]) and edited key by key.
library;

/// Vowel signs, yogavahas and the virama, in barakhadi order.
const List<String> kVowelSigns = [
  'ಾ',
  'ಿ',
  'ೀ',
  'ು',
  'ೂ',
  'ೃ',
  'ೆ',
  'ೈ',
  'ೊ',
  'ೌ',
  'ಂ',
  'ಃ',
  '್',
];

bool _isConsonant(int c) => (c >= 0x0C95 && c <= 0x0CB9) || c == 0x0CDE;

bool _isDependent(int c) =>
    (c >= 0x0CBE && c <= 0x0CCD) || c == 0x0C82 || c == 0x0C83;

/// The last consonant in [text] that a vowel sign could attach to, or null.
String? lastConsonant(String text) {
  final r = text.runes.toList();
  var i = r.length - 1;
  while (i >= 0 && _isDependent(r[i]) && r[i] != 0x0CCD) {
    i--;
  }
  if (i >= 0 && _isConsonant(r[i])) return String.fromCharCode(r[i]);
  return null;
}

/// Adds [sign] after the last consonant, replacing a vowel sign already
/// or virama already there (so tapping ಕ then ಾ then ಿ gives ಕಿ). Anusvara/visarga/virama are
/// appended. Without a consonant the text is unchanged.
String applySign(String text, String sign) {
  final r = text.runes.toList();
  if (r.isEmpty) return text;
  final s = sign.runes.single;
  final isVowelSign = s >= 0x0CBE && s <= 0x0CCC;
  if (!isVowelSign) {
    final last = r.last;
    if (_isConsonant(last) || (_isDependent(last) && last != 0x0CCD)) {
      if (s == 0x0CCD && _isDependent(last)) return text;
      return text + sign;
    }
    // After a virama or vowel: anusvara/visarga still allowed.
    if (s != 0x0CCD && last >= 0x0C85 && last <= 0x0C94) return text + sign;
    return text;
  }
  var end = r.length;
  while (end > 0 && r[end - 1] >= 0x0CBE && r[end - 1] <= 0x0CCD) {
    end--;
  }
  if (end == 0 || !_isConsonant(r[end - 1])) return text;
  return String.fromCharCodes(r.sublist(0, end)) + sign;
}

/// Removes the last character (one code point).
String backspace(String text) {
  final r = text.runes.toList();
  if (r.isEmpty) return text;
  return String.fromCharCodes(r.sublist(0, r.length - 1));
}

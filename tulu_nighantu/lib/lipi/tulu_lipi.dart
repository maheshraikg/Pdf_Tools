/// Kannada → Tulu-Tigalari (Unicode 16.0, U+11380–U+113FF) transliteration
/// plus the letter lists used by the Lipi and tracing screens.
library;

/// Font family used for every piece of Tulu-lipi text in the app.
///
/// Swap the font by changing the asset registered under this family name in
/// `pubspec.yaml` (or change this constant to point at a new family).
const String kTuluFontFamily = 'TuluTigalari';

/// Pure-Dart converter from Kannada script to Tulu-Tigalari script.
class TuluLipi {
  TuluLipi._();

  /// Kannada code point → Tulu-Tigalari code point.
  static const Map<int, int> _map = {
    // Independent vowels. Unicode 16 has no short E/O, so ಎ/ಏ → EE, ಒ/ಓ → OO.
    0x0C85: 0x11380, 0x0C86: 0x11381, 0x0C87: 0x11382, 0x0C88: 0x11383,
    0x0C89: 0x11384, 0x0C8A: 0x11385, 0x0C8B: 0x11386, 0x0CE0: 0x11387,
    0x0C8C: 0x11388, 0x0CE1: 0x11389, 0x0C8E: 0x1138B, 0x0C8F: 0x1138B,
    0x0C90: 0x1138E, 0x0C92: 0x11390, 0x0C93: 0x11390, 0x0C94: 0x11391,
    // Consonants.
    0x0C95: 0x11392, 0x0C96: 0x11393, 0x0C97: 0x11394, 0x0C98: 0x11395,
    0x0C99: 0x11396, 0x0C9A: 0x11397, 0x0C9B: 0x11398, 0x0C9C: 0x11399,
    0x0C9D: 0x1139A, 0x0C9E: 0x1139B, 0x0C9F: 0x1139C, 0x0CA0: 0x1139D,
    0x0CA1: 0x1139E, 0x0CA2: 0x1139F, 0x0CA3: 0x113A0, 0x0CA4: 0x113A1,
    0x0CA5: 0x113A2, 0x0CA6: 0x113A3, 0x0CA7: 0x113A4, 0x0CA8: 0x113A5,
    0x0CAA: 0x113A6, 0x0CAB: 0x113A7, 0x0CAC: 0x113A8, 0x0CAD: 0x113A9,
    0x0CAE: 0x113AA, 0x0CAF: 0x113AB, 0x0CB0: 0x113AC, 0x0CB2: 0x113AD,
    0x0CB5: 0x113AE, 0x0CB6: 0x113AF, 0x0CB7: 0x113B0, 0x0CB8: 0x113B1,
    0x0CB9: 0x113B2, 0x0CB3: 0x113B3, 0x0CB1: 0x113B4, 0x0CDE: 0x113B5,
    // Dependent vowel signs.
    0x0CBE: 0x113B8, 0x0CBF: 0x113B9, 0x0CC0: 0x113BA, 0x0CC1: 0x113BB,
    0x0CC2: 0x113BC, 0x0CC3: 0x113BD, 0x0CC4: 0x113BE, 0x0CE2: 0x113BF,
    0x0CE3: 0x113C0, 0x0CC6: 0x113C2, 0x0CC7: 0x113C2, 0x0CC8: 0x113C5,
    0x0CCA: 0x113C7, 0x0CCB: 0x113C7, 0x0CCC: 0x113C8,
    // Signs.
    0x0C81: 0x113CA, 0x0C82: 0x113CC, 0x0C83: 0x113CD, 0x0CCD: 0x113CE,
    0x0CBD: 0x113B7,
  };

  /// Decomposed sequences → precomposed vowel signs (longest first).
  static const List<(String, String)> _compositions = [
    ('ೋ', 'ೋ'),
    ('ೋ', 'ೋ'),
    ('ೊ', 'ೊ'),
    ('ೇ', 'ೇ'),
    ('ೈ', 'ೈ'),
    ('ೀ', 'ೀ'),
  ];

  /// Code points dropped after normalisation (joiners, stray length marks).
  static const Set<int> _dropped = {0x200C, 0x200D, 0x0CD5, 0x0CD6};

  /// Composes decomposed Kannada vowel signs and removes joiners.
  static String normalizeKannada(String input) {
    var s = input;
    for (final (from, to) in _compositions) {
      s = s.replaceAll(from, to);
    }
    return String.fromCharCodes(s.runes.where((r) => !_dropped.contains(r)));
  }

  /// Converts Kannada text to Tulu-Tigalari. Unmapped characters pass through.
  static String fromKannada(String input) {
    final buf = StringBuffer();
    for (final r in normalizeKannada(input).runes) {
      buf.writeCharCode(_map[r] ?? r);
    }
    return buf.toString();
  }

  /// True if [input] contains at least one Kannada-block character.
  static bool hasKannada(String input) =>
      input.runes.any((r) => r >= 0x0C80 && r <= 0x0CFF);
}

/// Groups used to organise the alphabet on the Lipi screen.
enum LetterGroup {
  vowels('ಸ್ವರಗಳು', 'Vowels'),
  yogavaha('ಯೋಗವಾಹಗಳು', 'Yogavahas'),
  ka('ಕ ವರ್ಗ', 'Ka group'),
  cha('ಚ ವರ್ಗ', 'Cha group'),
  tta('ಟ ವರ್ಗ', 'Ṭa group'),
  ta('ತ ವರ್ಗ', 'Ta group'),
  pa('ಪ ವರ್ಗ', 'Pa group'),
  avargiya('ಅವರ್ಗೀಯ', 'Other consonants');

  const LetterGroup(this.kannada, this.english);

  /// Kannada heading.
  final String kannada;

  /// English heading.
  final String english;
}

/// One letter of the Tulu alphabet.
class LipiLetter {
  const LipiLetter(this.kannada, this.roman, this.group, {String? label})
    : label = label ?? kannada;

  /// Kannada source used for conversion (e.g. ಏ for the "ಎ / ಏ" cell).
  final String kannada;

  /// Romanisation shown under the letter.
  final String roman;

  /// Alphabet group.
  final LetterGroup group;

  /// Kannada label shown to the learner.
  final String label;

  /// Tulu-Tigalari glyph(s) for this letter.
  String get tulu => TuluLipi.fromKannada(kannada);

  /// True for consonants (these get a barakhadi row).
  bool get isConsonant => group.index >= LetterGroup.ka.index;

  /// Key used to store tracing stars.
  String get starKey => 'L:$kannada';
}

/// The full alphabet in teaching order.
const List<LipiLetter> kLipiLetters = [
  LipiLetter('ಅ', 'a', LetterGroup.vowels),
  LipiLetter('ಆ', 'ā', LetterGroup.vowels),
  LipiLetter('ಇ', 'i', LetterGroup.vowels),
  LipiLetter('ಈ', 'ī', LetterGroup.vowels),
  LipiLetter('ಉ', 'u', LetterGroup.vowels),
  LipiLetter('ಊ', 'ū', LetterGroup.vowels),
  LipiLetter('ಋ', 'ṛ', LetterGroup.vowels),
  LipiLetter('ಏ', 'e / ē', LetterGroup.vowels, label: 'ಎ / ಏ'),
  LipiLetter('ಐ', 'ai', LetterGroup.vowels),
  LipiLetter('ಓ', 'o / ō', LetterGroup.vowels, label: 'ಒ / ಓ'),
  LipiLetter('ಔ', 'au', LetterGroup.vowels),
  LipiLetter('ಅಂ', 'aṁ', LetterGroup.yogavaha),
  LipiLetter('ಅಃ', 'aḥ', LetterGroup.yogavaha),
  LipiLetter('ಕ', 'ka', LetterGroup.ka),
  LipiLetter('ಖ', 'kha', LetterGroup.ka),
  LipiLetter('ಗ', 'ga', LetterGroup.ka),
  LipiLetter('ಘ', 'gha', LetterGroup.ka),
  LipiLetter('ಙ', 'ṅa', LetterGroup.ka),
  LipiLetter('ಚ', 'ca', LetterGroup.cha),
  LipiLetter('ಛ', 'cha', LetterGroup.cha),
  LipiLetter('ಜ', 'ja', LetterGroup.cha),
  LipiLetter('ಝ', 'jha', LetterGroup.cha),
  LipiLetter('ಞ', 'ña', LetterGroup.cha),
  LipiLetter('ಟ', 'ṭa', LetterGroup.tta),
  LipiLetter('ಠ', 'ṭha', LetterGroup.tta),
  LipiLetter('ಡ', 'ḍa', LetterGroup.tta),
  LipiLetter('ಢ', 'ḍha', LetterGroup.tta),
  LipiLetter('ಣ', 'ṇa', LetterGroup.tta),
  LipiLetter('ತ', 'ta', LetterGroup.ta),
  LipiLetter('ಥ', 'tha', LetterGroup.ta),
  LipiLetter('ದ', 'da', LetterGroup.ta),
  LipiLetter('ಧ', 'dha', LetterGroup.ta),
  LipiLetter('ನ', 'na', LetterGroup.ta),
  LipiLetter('ಪ', 'pa', LetterGroup.pa),
  LipiLetter('ಫ', 'pha', LetterGroup.pa),
  LipiLetter('ಬ', 'ba', LetterGroup.pa),
  LipiLetter('ಭ', 'bha', LetterGroup.pa),
  LipiLetter('ಮ', 'ma', LetterGroup.pa),
  LipiLetter('ಯ', 'ya', LetterGroup.avargiya),
  LipiLetter('ರ', 'ra', LetterGroup.avargiya),
  LipiLetter('ಲ', 'la', LetterGroup.avargiya),
  LipiLetter('ವ', 'va', LetterGroup.avargiya),
  LipiLetter('ಶ', 'śa', LetterGroup.avargiya),
  LipiLetter('ಷ', 'ṣa', LetterGroup.avargiya),
  LipiLetter('ಸ', 'sa', LetterGroup.avargiya),
  LipiLetter('ಹ', 'ha', LetterGroup.avargiya),
  LipiLetter('ಳ', 'ḷa', LetterGroup.avargiya),
];

/// Vowel signs used to build the barakhadi (ಕಾಗುಣಿತ) row of a consonant.
const List<String> kBarakhadiSigns = [
  '',
  'ಾ',
  'ಿ',
  'ೀ',
  'ು',
  'ೂ',
  'ೇ',
  'ೈ',
  'ೋ',
  'ೌ',
  'ಂ',
  'ಃ',
  '್',
];

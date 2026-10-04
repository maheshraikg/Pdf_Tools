/// Names of panchanga elements in English, Kannada and Tulu (Kannada script).
///
/// Tulu-specific forms (month names, weekdays, Amase/Punname, etc.) are listed
/// in docs/VERIFY.md for confirmation by a native speaker / priest.
library;

import '../lipi/indic.dart';

/// UI / name language. Kannada is the default (first launch).
enum Lang {
  kn('ಕನ್ನಡ', 'Kannada'),
  tcy('ತುಳು', 'Tulu'),
  en('English', 'English'),
  kok('ಕೊಂಕಣಿ', 'Konkani'),
  hi('हिन्दी', 'Hindi'),
  ml('മലയാളം', 'Malayalam'),
  te('తెలుగు', 'Telugu');

  const Lang(this.label, this.english);

  /// Name of the language in its own script.
  final String label;
  final String english;

  /// Languages written in Kannada script.
  bool get kannadaScript => this == kn || this == tcy || this == kok;

  static Lang fromCode(String? code) =>
      Lang.values.firstWhere((l) => l.name == code, orElse: () => Lang.kn);
}

/// A name in every supported language.
///
/// [sa] is the pan-Indian (Sanskrit) form in Kannada script; Hindi,
/// Malayalam and Telugu are transliterated from it unless given explicitly.
/// Konkani uses the Kannada form unless [kok] is given.
class Name {
  const Name(
    this.en,
    this.kn, [
    String? tcy,
    this.sa,
    this.kok,
    this.hi,
    this.ml,
    this.te,
  ]) : tcy = tcy ?? kn;
  final String en;
  final String kn;
  final String tcy;
  final String? sa;
  final String? kok;
  final String? hi;
  final String? ml;
  final String? te;

  String get _base => sa ?? kn;

  String of(Lang lang) => switch (lang) {
    Lang.en => en,
    Lang.kn => kn,
    Lang.tcy => tcy,
    Lang.kok => kok ?? kn,
    Lang.hi => hi ?? transliterateKannada(_base, IndicScript.devanagari),
    Lang.ml => ml ?? transliterateKannada(_base, IndicScript.malayalam),
    Lang.te => te ?? transliterateKannada(_base, IndicScript.telugu),
  };
}

List<Name> _zip(
  List<String> en,
  List<String> kn, [
  List<String>? tcy,
  List<String>? sa,
]) => [
  for (var i = 0; i < en.length; i++)
    Name(en[i], kn[i], tcy == null ? null : tcy[i], sa == null ? null : sa[i]),
];

/// Names given explicitly in every language (weekdays, Gregorian months).
List<Name> _all({
  required List<String> en,
  required List<String> kn,
  required List<String> tcy,
  required List<String> kok,
  required List<String> hi,
  required List<String> ml,
  required List<String> te,
}) => [
  for (var i = 0; i < en.length; i++)
    Name(en[i], kn[i], tcy[i], null, kok[i], hi[i], ml[i], te[i]),
];

/// Tithi names for 1–15 of a paksha (index 0 = Pratipada). Index 14 is
/// Purnima; use [amavasyaName] for Krishna 15.
final List<Name> tithiNames = _zip(
  [
    'Pratipada', 'Dwitiya', 'Tritiya', 'Chaturthi', 'Panchami', //
    'Shashthi', 'Saptami', 'Ashtami', 'Navami', 'Dashami',
    'Ekadashi', 'Dwadashi', 'Trayodashi', 'Chaturdashi', 'Purnima',
  ],
  [
    'ಪಾಡ್ಯ', 'ಬಿದಿಗೆ', 'ತದಿಗೆ', 'ಚೌತಿ', 'ಪಂಚಮಿ', //
    'ಷಷ್ಠಿ', 'ಸಪ್ತಮಿ', 'ಅಷ್ಟಮಿ', 'ನವಮಿ', 'ದಶಮಿ',
    'ಏಕಾದಶಿ', 'ದ್ವಾದಶಿ', 'ತ್ರಯೋದಶಿ', 'ಚತುರ್ದಶಿ', 'ಹುಣ್ಣಿಮೆ',
  ],
  [
    'ಪಾಡ್ಯ', 'ಬಿದಿಗೆ', 'ತದಿಗೆ', 'ಚೌತಿ', 'ಪಂಚಮಿ', //
    'ಷಷ್ಠಿ', 'ಸಪ್ತಮಿ', 'ಅಷ್ಟಮಿ', 'ನವಮಿ', 'ದಶಮಿ',
    'ಏಕಾದಶಿ', 'ದ್ವಾದಶಿ', 'ತ್ರಯೋದಶಿ', 'ಚತುರ್ದಶಿ', 'ಪುಣ್ಣಮೆ',
  ],
  [
    'ಪ್ರತಿಪದಾ', 'ದ್ವಿತೀಯಾ', 'ತೃತೀಯಾ', 'ಚತುರ್ಥೀ', 'ಪಂಚಮೀ', //
    'ಷಷ್ಠೀ', 'ಸಪ್ತಮೀ', 'ಅಷ್ಟಮೀ', 'ನವಮೀ', 'ದಶಮೀ',
    'ಏಕಾದಶೀ', 'ದ್ವಾದಶೀ', 'ತ್ರಯೋದಶೀ', 'ಚತುರ್ದಶೀ', 'ಪೂರ್ಣಿಮಾ',
  ],
);

const Name amavasyaName = Name('Amavasya', 'ಅಮಾವಾಸ್ಯೆ', 'ಅಮಾಸೆ', 'ಅಮಾವಸ್ಯಾ');

/// Name of tithi [index] (0..29: 0–14 Shukla, 15–29 Krishna).
Name tithiName(int index) =>
    index == 29 ? amavasyaName : tithiNames[index % 15];

const List<Name> pakshaNames = [
  Name('Shukla Paksha', 'ಶುಕ್ಲ ಪಕ್ಷ'),
  Name('Krishna Paksha', 'ಕೃಷ್ಣ ಪಕ್ಷ'),
];

final List<Name> nakshatraNames = _zip(
  [
    'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', //
    'Punarvasu', 'Pushya', 'Ashlesha', 'Magha', 'Purva Phalguni',
    'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha',
    'Jyeshtha', 'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana',
    'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada', 'Uttara Bhadrapada',
    'Revati',
  ],
  [
    'ಅಶ್ವಿನಿ', 'ಭರಣಿ', 'ಕೃತ್ತಿಕಾ', 'ರೋಹಿಣಿ', 'ಮೃಗಶಿರಾ', 'ಆರ್ದ್ರಾ', //
    'ಪುನರ್ವಸು', 'ಪುಷ್ಯ', 'ಆಶ್ಲೇಷಾ', 'ಮಘಾ', 'ಪೂರ್ವ ಫಲ್ಗುಣಿ',
    'ಉತ್ತರ ಫಲ್ಗುಣಿ', 'ಹಸ್ತ', 'ಚಿತ್ರಾ', 'ಸ್ವಾತಿ', 'ವಿಶಾಖಾ', 'ಅನುರಾಧಾ',
    'ಜ್ಯೇಷ್ಠಾ', 'ಮೂಲಾ', 'ಪೂರ್ವಾಷಾಢಾ', 'ಉತ್ತರಾಷಾಢಾ', 'ಶ್ರವಣ',
    'ಧನಿಷ್ಠಾ', 'ಶತಭಿಷಾ', 'ಪೂರ್ವಾಭಾದ್ರಾ', 'ಉತ್ತರಾಭಾದ್ರಾ',
    'ರೇವತಿ',
  ],
);

final List<Name> yogaNames = _zip(
  [
    'Vishkambha', 'Priti', 'Ayushman', 'Saubhagya', 'Shobhana', //
    'Atiganda', 'Sukarma', 'Dhriti', 'Shula', 'Ganda', 'Vriddhi', 'Dhruva',
    'Vyaghata', 'Harshana', 'Vajra', 'Siddhi', 'Vyatipata', 'Variyan',
    'Parigha', 'Shiva', 'Siddha', 'Sadhya', 'Shubha', 'Shukla', 'Brahma',
    'Indra', 'Vaidhriti',
  ],
  [
    'ವಿಷ್ಕಂಭ', 'ಪ್ರೀತಿ', 'ಆಯುಷ್ಮಾನ್', 'ಸೌಭಾಗ್ಯ', 'ಶೋಭನ', //
    'ಅತಿಗಂಡ', 'ಸುಕರ್ಮ', 'ಧೃತಿ', 'ಶೂಲ', 'ಗಂಡ', 'ವೃದ್ಧಿ', 'ಧ್ರುವ',
    'ವ್ಯಾಘಾತ', 'ಹರ್ಷಣ', 'ವಜ್ರ', 'ಸಿದ್ಧಿ', 'ವ್ಯತೀಪಾತ', 'ವರೀಯಾನ್',
    'ಪರಿಘ', 'ಶಿವ', 'ಸಿದ್ಧ', 'ಸಾಧ್ಯ', 'ಶುಭ', 'ಶುಕ್ಲ', 'ಬ್ರಹ್ಮ',
    'ಐಂದ್ರ', 'ವೈಧೃತಿ',
  ],
);

/// The 11 karanas: 7 movable (0–6) then Shakuni, Chatushpada, Naga,
/// Kimstughna.
final List<Name> karanaNames = _zip(
  [
    'Bava', 'Balava', 'Kaulava', 'Taitila', 'Garaja', 'Vanija', 'Vishti', //
    'Shakuni', 'Chatushpada', 'Naga', 'Kimstughna',
  ],
  [
    'ಬವ', 'ಬಾಲವ', 'ಕೌಲವ', 'ತೈತಿಲ', 'ಗರಜ', 'ವಣಿಜ', 'ವಿಷ್ಟಿ', //
    'ಶಕುನಿ', 'ಚತುಷ್ಪಾದ', 'ನಾಗ', 'ಕಿಂಸ್ತುಘ್ನ',
  ],
);

/// Karana name index for half-tithi [k] (0..59) of a lunar month.
int karanaIndex(int k) {
  if (k == 0) return 10; // Kimstughna
  if (k >= 57) return 7 + (k - 57); // Shakuni, Chatushpada, Naga
  return (k - 1) % 7;
}

/// Weekday names, index 0 = Sunday.
final List<Name> varaNames = _all(
  en: [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', //
    'Saturday',
  ],
  kn: [
    'ಭಾನುವಾರ', 'ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', //
    'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ',
  ],
  tcy: ['ಐತಾರ', 'ಸೋಮಾರ', 'ಅಂಗಾರೆ', 'ಬುದಾರ', 'ಗುರುವಾರ', 'ಸುಕ್ರಾರ', 'ಸನಿವಾರ'],
  kok: [
    'ಆಯ್ತಾರ',
    'ಸೋಮಾರ',
    'ಮಂಗ್ಳಾರ',
    'ಬುದ್ವಾರ',
    'ಬ್ರೆಸ್ತಾರ',
    'ಸುಕ್ರಾರ',
    'ಸನ್ವಾರ',
  ],
  hi: [
    'रविवार',
    'सोमवार',
    'मंगलवार',
    'बुधवार',
    'गुरुवार',
    'शुक्रवार',
    'शनिवार',
  ],
  ml: [
    'ഞായറാഴ്ച', 'തിങ്കളാഴ്ച', 'ചൊവ്വാഴ്ച', 'ബുധനാഴ്ച', 'വ്യാഴാഴ്ച', //
    'വെള്ളിയാഴ്ച', 'ശനിയാഴ്ച',
  ],
  te: [
    'ఆదివారం',
    'సోమవారం',
    'మంగళవారం',
    'బుధవారం',
    'గురువారం',
    'శుక్రవారం',
    'శనివారం',
  ],
);

/// Short weekday labels for calendar headers (index 0 = Sunday).
final List<Name> varaShort = _all(
  en: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  kn: ['ಭಾನು', 'ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'],
  tcy: ['ಐತ', 'ಸೋಮ', 'ಅಂಗ', 'ಬುದ', 'ಗುರು', 'ಸುಕ್ರ', 'ಸನಿ'],
  kok: ['ಆಯ್ತ', 'ಸೋಮ', 'ಮಂಗ್ಳ', 'ಬುದ', 'ಬ್ರೆಸ್ತ', 'ಸುಕ್ರ', 'ಸನ್'],
  hi: ['रवि', 'सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि'],
  ml: ['ഞായർ', 'തിങ്കൾ', 'ചൊവ്വ', 'ബുധൻ', 'വ്യാഴം', 'വെള്ളി', 'ശനി'],
  te: ['ఆది', 'సోమ', 'మంగళ', 'బుధ', 'గురు', 'శుక్ర', 'శని'],
);

/// Gregorian month names (index 0 = January).
final List<Name> gregorianMonthNames = _all(
  en: [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', //
    'August', 'September', 'October', 'November', 'December',
  ],
  kn: [
    'ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', //
    'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್',
  ],
  tcy: [
    'ಜನವರಿ', 'ಫೆಬ್ರವರಿ', 'ಮಾರ್ಚ್', 'ಏಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲೈ', //
    'ಆಗಸ್ಟ್', 'ಸೆಪ್ಟೆಂಬರ್', 'ಅಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್',
  ],
  kok: [
    'ಜನೆರ್', 'ಫೆಬ್ರೆರ್', 'ಮಾರ್ಚ್', 'ಎಪ್ರಿಲ್', 'ಮೇ', 'ಜೂನ್', 'ಜುಲಾಯ್', //
    'ಆಗೋಸ್ತ್', 'ಸಪ್ಟೆಂಬರ್', 'ಒಕ್ಟೋಬರ್', 'ನವೆಂಬರ್', 'ಡಿಸೆಂಬರ್',
  ],
  hi: [
    'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', //
    'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
  ],
  ml: [
    'ജനുവരി', 'ഫെബ്രുവരി', 'മാർച്ച്', 'ഏപ്രിൽ', 'മേയ്', 'ജൂൺ', 'ജൂലൈ', //
    'ഓഗസ്റ്റ്', 'സെപ്റ്റംബർ', 'ഒക്ടോബർ', 'നവംബർ', 'ഡിസംബർ',
  ],
  te: [
    'జనవరి', 'ఫిబ్రవరి', 'మార్చి', 'ఏప్రిల్', 'మే', 'జూన్', 'జూలై', //
    'ఆగస్టు', 'సెప్టెంబర్', 'అక్టోబర్', 'నవంబర్', 'డిసెంబర్',
  ],
);

final List<Name> rashiNames = _zip(
  [
    'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya', 'Tula', //
    'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena',
  ],
  [
    'ಮೇಷ', 'ವೃಷಭ', 'ಮಿಥುನ', 'ಕರ್ಕಾಟಕ', 'ಸಿಂಹ', 'ಕನ್ಯಾ', 'ತುಲಾ', //
    'ವೃಶ್ಚಿಕ', 'ಧನು', 'ಮಕರ', 'ಕುಂಭ', 'ಮೀನ',
  ],
  null,
  [
    'ಮೇಷ', 'ವೃಷಭ', 'ಮಿಥುನ', 'ಕರ್ಕ', 'ಸಿಂಹ', 'ಕನ್ಯಾ', 'ತುಲಾ', //
    'ವೃಶ್ಚಿಕ', 'ಧನು', 'ಮಕರ', 'ಕುಂಭ', 'ಮೀನ',
  ],
);

/// Chandramana (amanta) lunar month names, index 0 = Chaitra.
final List<Name> lunarMonthNames = _zip(
  [
    'Chaitra', 'Vaishakha', 'Jyeshtha', 'Ashadha', 'Shravana', //
    'Bhadrapada', 'Ashvayuja', 'Kartika', 'Margashira', 'Pushya', 'Magha',
    'Phalguna',
  ],
  [
    'ಚೈತ್ರ', 'ವೈಶಾಖ', 'ಜ್ಯೇಷ್ಠ', 'ಆಷಾಢ', 'ಶ್ರಾವಣ', //
    'ಭಾದ್ರಪದ', 'ಆಶ್ವಯುಜ', 'ಕಾರ್ತಿಕ', 'ಮಾರ್ಗಶಿರ', 'ಪುಷ್ಯ', 'ಮಾಘ',
    'ಫಾಲ್ಗುಣ',
  ],
  null,
  [
    'ಚೈತ್ರ', 'ವೈಶಾಖ', 'ಜ್ಯೇಷ್ಠ', 'ಆಷಾಢ', 'ಶ್ರಾವಣ', //
    'ಭಾದ್ರಪದ', 'ಆಶ್ವಿನ', 'ಕಾರ್ತಿಕ', 'ಮಾರ್ಗಶೀರ್ಷ', 'ಪೌಷ', 'ಮಾಘ',
    'ಫಾಲ್ಗುನ',
  ],
);

/// Tulu solar month names, index 0 = Paggu (Sun in Mesha).
final List<Name> tuluMonthNames = _zip(
  [
    'Paggu', 'Beshe', 'Kartel', 'Aati', 'Sona', 'Nirnal', 'Bontel', //
    'Jaarde', 'Perarde', 'Puyintel', 'Maayi', 'Suggi',
  ],
  [
    'ಪಗ್ಗು', 'ಬೇಸ', 'ಕಾರ್ತೆಲ್', 'ಆಟಿ', 'ಸೋಣ', 'ನಿರ್ನಾಲ್', //
    'ಬೊಂತೆಲ್', 'ಜಾರ್ದೆ', 'ಪೆರಾರ್ದೆ', 'ಪುಯಿಂತೆಲ್', 'ಮಾಯಿ', 'ಸುಗ್ಗಿ',
  ],
);

final List<Name> samvatsaraNames = _zip(
  [
    'Prabhava', 'Vibhava', 'Shukla', 'Pramoduta', 'Prajotpatti', //
    'Angirasa', 'Shrimukha', 'Bhava', 'Yuva', 'Dhatu', 'Ishvara',
    'Bahudhanya', 'Pramathi', 'Vikrama', 'Vrisha', 'Chitrabhanu',
    'Svabhanu', 'Tarana', 'Parthiva', 'Vyaya', 'Sarvajit', 'Sarvadhari',
    'Virodhi', 'Vikriti', 'Khara', 'Nandana', 'Vijaya', 'Jaya', 'Manmatha',
    'Durmukhi', 'Hevilambi', 'Vilambi', 'Vikari', 'Sharvari', 'Plava',
    'Shubhakrit', 'Shobhakrit', 'Krodhi', 'Vishvavasu', 'Parabhava',
    'Plavanga', 'Kilaka', 'Saumya', 'Sadharana', 'Virodhikrit', 'Paridhavi',
    'Pramadi', 'Ananda', 'Rakshasa', 'Nala', 'Pingala', 'Kalayukti',
    'Siddharthi', 'Raudri', 'Durmati', 'Dundubhi', 'Rudhirodgari',
    'Raktakshi', 'Krodhana', 'Akshaya',
  ],
  [
    'ಪ್ರಭವ', 'ವಿಭವ', 'ಶುಕ್ಲ', 'ಪ್ರಮೋದೂತ', 'ಪ್ರಜೋತ್ಪತ್ತಿ', //
    'ಆಂಗೀರಸ', 'ಶ್ರೀಮುಖ', 'ಭಾವ', 'ಯುವ', 'ಧಾತು', 'ಈಶ್ವರ',
    'ಬಹುಧಾನ್ಯ', 'ಪ್ರಮಾಥಿ', 'ವಿಕ್ರಮ', 'ವೃಷ', 'ಚಿತ್ರಭಾನು',
    'ಸ್ವಭಾನು', 'ತಾರಣ', 'ಪಾರ್ಥಿವ', 'ವ್ಯಯ', 'ಸರ್ವಜಿತ್', 'ಸರ್ವಧಾರಿ',
    'ವಿರೋಧಿ', 'ವಿಕೃತಿ', 'ಖರ', 'ನಂದನ', 'ವಿಜಯ', 'ಜಯ', 'ಮನ್ಮಥ',
    'ದುರ್ಮುಖಿ', 'ಹೇವಿಳಂಬಿ', 'ವಿಳಂಬಿ', 'ವಿಕಾರಿ', 'ಶಾರ್ವರಿ', 'ಪ್ಲವ',
    'ಶುಭಕೃತ್', 'ಶೋಭಕೃತ್', 'ಕ್ರೋಧಿ', 'ವಿಶ್ವಾವಸು', 'ಪರಾಭವ',
    'ಪ್ಲವಂಗ', 'ಕೀಲಕ', 'ಸೌಮ್ಯ', 'ಸಾಧಾರಣ', 'ವಿರೋಧಿಕೃತ್', 'ಪರಿಧಾವಿ',
    'ಪ್ರಮಾದಿ', 'ಆನಂದ', 'ರಾಕ್ಷಸ', 'ನಳ', 'ಪಿಂಗಳ', 'ಕಾಳಯುಕ್ತಿ',
    'ಸಿದ್ಧಾರ್ಥಿ', 'ರೌದ್ರಿ', 'ದುರ್ಮತಿ', 'ದುಂದುಭಿ', 'ರುಧಿರೋದ್ಗಾರಿ',
    'ರಕ್ತಾಕ್ಷಿ', 'ಕ್ರೋಧನ', 'ಅಕ್ಷಯ',
  ],
);

final List<Name> rituNames = _zip(
  ['Vasanta', 'Grishma', 'Varsha', 'Sharad', 'Hemanta', 'Shishira'],
  ['ವಸಂತ', 'ಗ್ರೀಷ್ಮ', 'ವರ್ಷ', 'ಶರದ್', 'ಹೇಮಂತ', 'ಶಿಶಿರ'],
);

const List<Name> ayanaNames = [
  Name('Uttarayana', 'ಉತ್ತರಾಯಣ'),
  Name('Dakshinayana', 'ದಕ್ಷಿಣಾಯನ'),
];

const Name adhikaName = Name('Adhika', 'ಅಧಿಕ');
const Name nijaName = Name('Nija', 'ನಿಜ');

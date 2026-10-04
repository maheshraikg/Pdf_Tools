/// Names of panchanga elements in English, Kannada and Tulu (Kannada script).
///
/// Tulu-specific forms (month names, weekdays, Amase/Punname, etc.) are listed
/// in docs/VERIFY.md for confirmation by a native speaker / priest.
library;

/// UI / name language.
enum Lang {
  en('English'),
  kn('ಕನ್ನಡ'),
  tcy('ತುಳು');

  const Lang(this.label);
  final String label;

  static Lang fromCode(String? code) =>
      Lang.values.firstWhere((l) => l.name == code, orElse: () => Lang.en);
}

/// A name in the three supported languages.
class Name {
  const Name(this.en, this.kn, [String? tcy]) : tcy = tcy ?? kn;
  final String en;
  final String kn;
  final String tcy;

  String of(Lang lang) => switch (lang) {
    Lang.en => en,
    Lang.kn => kn,
    Lang.tcy => tcy,
  };
}

List<Name> _zip(List<String> en, List<String> kn, [List<String>? tcy]) => [
  for (var i = 0; i < en.length; i++)
    Name(en[i], kn[i], tcy == null ? null : tcy[i]),
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
);

const Name amavasyaName = Name('Amavasya', 'ಅಮಾವಾಸ್ಯೆ', 'ಅಮಾಸೆ');

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
final List<Name> varaNames = _zip(
  [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', //
    'Saturday',
  ],
  [
    'ಭಾನುವಾರ', 'ಸೋಮವಾರ', 'ಮಂಗಳವಾರ', 'ಬುಧವಾರ', 'ಗುರುವಾರ', //
    'ಶುಕ್ರವಾರ', 'ಶನಿವಾರ',
  ],
  ['ಐತಾರ', 'ಸೋಮಾರ', 'ಅಂಗಾರೆ', 'ಬುದಾರ', 'ಗುರುವಾರ', 'ಸುಕ್ರಾರ', 'ಸನಿವಾರ'],
);

/// Short weekday labels for calendar headers (index 0 = Sunday).
final List<Name> varaShort = _zip(
  ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  ['ಭಾನು', 'ಸೋಮ', 'ಮಂಗಳ', 'ಬುಧ', 'ಗುರು', 'ಶುಕ್ರ', 'ಶನಿ'],
  ['ಐತ', 'ಸೋಮ', 'ಅಂಗ', 'ಬುದ', 'ಗುರು', 'ಸುಕ್ರ', 'ಸನಿ'],
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

/// UI strings in English, Kannada and Tulu (Kannada script).
///
/// Tulu UI words are listed in docs/VERIFY.md for a native speaker's review;
/// where no Tulu-specific word is given, the Kannada one is used (as in most
/// printed Tulu panchangas).
library;

import '../panchanga/names.dart';

class S {
  const S(this.lang);
  final Lang lang;

  String _t(String en, String kn, [String? tcy]) => switch (lang) {
    Lang.en => en,
    Lang.kn => kn,
    Lang.tcy => tcy ?? kn,
  };

  String get appTitle => _t('Tulu Panchanga', 'ತುಳು ಪಂಚಾಂಗ');
  String get today => _t('Today', 'ಇಂದು', 'ಇನಿ');
  String get calendar => _t('Calendar', 'ಕ್ಯಾಲೆಂಡರ್');
  String get festivals => _t('Festivals', 'ಹಬ್ಬಗಳು', 'ಪರ್ಬೊಲು');
  String get muhurta => _t('Muhurta', 'ಮುಹೂರ್ತ');
  String get settings => _t('Settings', 'ಸೆಟ್ಟಿಂಗ್ಸ್');

  String get sunrise => _t('Sunrise', 'ಸೂರ್ಯೋದಯ');
  String get sunset => _t('Sunset', 'ಸೂರ್ಯಾಸ್ತ');
  String get moonrise => _t('Moonrise', 'ಚಂದ್ರೋದಯ');
  String get moonset => _t('Moonset', 'ಚಂದ್ರಾಸ್ತ');
  String get noMoonrise => _t('No moonrise', 'ಚಂದ್ರೋದಯವಿಲ್ಲ');
  String get noMoonset => _t('No moonset', 'ಚಂದ್ರಾಸ್ತವಿಲ್ಲ');

  String get tithi => _t('Tithi', 'ತಿಥಿ');
  String get nakshatra => _t('Nakshatra', 'ನಕ್ಷತ್ರ');
  String get yoga => _t('Yoga', 'ಯೋಗ');
  String get karana => _t('Karana', 'ಕರಣ');
  String get vara => _t('Weekday', 'ವಾರ');
  String get paksha => _t('Paksha', 'ಪಕ್ಷ');
  String get rashi => _t('Moon sign', 'ಚಂದ್ರ ರಾಶಿ');
  String get sunSign => _t('Sun sign', 'ಸೂರ್ಯ ರಾಶಿ');
  String get pada => _t('pada', 'ಪಾದ');

  String get lunarMonth => _t('Lunar month', 'ಚಾಂದ್ರಮಾನ ಮಾಸ');
  String get tuluMonth => _t('Tulu month', 'ತುಳು ತಿಂಗಳು', 'ತುಳು ತಿಂಗೊಲು');
  String get samvatsara => _t('Samvatsara', 'ಸಂವತ್ಸರ');
  String get sauraSamvatsara =>
      _t('Samvatsara (Sauramana)', 'ಸಂವತ್ಸರ (ಸೌರಮಾನ)');
  String get shaka => _t('Shaka', 'ಶಕ');
  String get kali => _t('Kali', 'ಕಲಿ');
  String get ayana => _t('Ayana', 'ಅಯನ');
  String get ritu => _t('Ritu', 'ಋತು');
  String get sankramana => _t('Sankramana', 'ಸಂಕ್ರಮಣ');

  String get rahu => _t('Rahu kaala', 'ರಾಹು ಕಾಲ');
  String get yamaganda => _t('Yamaganda', 'ಯಮಗಂಡ');
  String get gulika => _t('Gulika kaala', 'ಗುಳಿಕ ಕಾಲ');
  String get abhijit => _t('Abhijit muhurta', 'ಅಭಿಜಿತ್ ಮುಹೂರ್ತ');
  String get brahma => _t('Brahma muhurta', 'ಬ್ರಹ್ಮ ಮುಹೂರ್ತ');
  String get durmuhurta => _t('Durmuhurta', 'ದುರ್ಮುಹೂರ್ತ');
  String get inauspicious => _t('Avoid', 'ಅಶುಭ ಕಾಲ');
  String get auspicious => _t('Good times', 'ಶುಭ ಕಾಲ');

  String get until => _t('until', 'ವರೆಗೆ', 'ಮುಟ್ಟ');
  String get nextDay => _t('next day', 'ಮರುದಿನ', 'ಎಲ್ಲೆ');
  String get untilNextSunrise =>
      _t('till next sunrise', 'ಮರುದಿನ ಸೂರ್ಯೋದಯದವರೆಗೆ', 'ಎಲ್ಲೆ ಸೂರ್ಯೋದಯ ಮುಟ್ಟ');
  String get now => _t('Now', 'ಈಗ', 'ಇತ್ತೆ');
  String get fullDetails => _t('Full details', 'ಪೂರ್ಣ ವಿವರ');
  String get share => _t('Share', 'ಹಂಚಿಕೊಳ್ಳಿ');
  String get pickDate => _t('Pick a date', 'ದಿನಾಂಕ ಆಯ್ಕೆ');
  String get festivalsToday => _t('Festivals & vratas', 'ಹಬ್ಬ ಮತ್ತು ವ್ರತಗಳು');
  String get sunMoon => _t('Sun & Moon', 'ಸೂರ್ಯ ಚಂದ್ರ');
  String get panchanga => _t('Panchanga', 'ಪಂಚಾಂಗ');
  String get yearAndMonth => _t('Year & month', 'ವರ್ಷ ಮತ್ತು ಮಾಸ');
  String get timeline => _t('Day timeline', 'ದಿನದ ಸಮಯರೇಖೆ');
  String get loading => _t('Calculating…', 'ಲೆಕ್ಕ ಹಾಕುತ್ತಿದೆ…');

  String get gregorian => _t('Gregorian', 'ಇಂಗ್ಲಿಷ್ ತಿಂಗಳು');
  String get tuluCalendar => _t('Tulu month', 'ತುಳು ತಿಂಗಳು', 'ತುಳು ತಿಂಗೊಲು');
  String get all => _t('All', 'ಎಲ್ಲಾ', 'ಮಾತ');
  String get year => _t('Year', 'ವರ್ಷ', 'ವರ್ಸ');
  String get noFestivals => _t('Nothing listed', 'ಏನೂ ಇಲ್ಲ', 'ದಾಲ ಇಜ್ಜಿ');

  String get activity => _t('Activity', 'ಕಾರ್ಯ');
  String get startDate => _t('From', 'ಇಂದ');
  String get days => _t('days', 'ದಿನಗಳು', 'ದಿನೊಕುಲು');
  String get janmaNakshatra =>
      _t('Birth star (optional)', 'ಜನ್ಮ ನಕ್ಷತ್ರ (ಐಚ್ಛಿಕ)');
  String get janmaRashi => _t('Birth rashi (optional)', 'ಜನ್ಮ ರಾಶಿ (ಐಚ್ಛಿಕ)');
  String get notSet => _t('Not set', 'ಆಯ್ಕೆ ಇಲ್ಲ');
  String get find => _t('Find muhurtas', 'ಮುಹೂರ್ತ ಹುಡುಕಿ');
  String get noMuhurta =>
      _t('No suitable window in this period.', 'ಈ ಅವಧಿಯಲ್ಲಿ ಸೂಕ್ತ ಸಮಯವಿಲ್ಲ.');
  String get muhurtaDisclaimer => _t(
    'A shortlist from simple rules (tithi, nakshatra, weekday, yoga, karana, '
        'Rahu/Yama/Gulika, durmuhurta). Always confirm with your priest.',
    'ತಿಥಿ, ನಕ್ಷತ್ರ, ವಾರ, ಯೋಗ, ಕರಣ, ರಾಹು/ಯಮ/ಗುಳಿಕ, ದುರ್ಮುಹೂರ್ತ ಆಧಾರಿತ '
        'ಪಟ್ಟಿ ಮಾತ್ರ. ನಿಮ್ಮ ಪುರೋಹಿತರಲ್ಲಿ ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ.',
  );
  String get score => _t('score', 'ಅಂಕ');

  String get language => _t('Language', 'ಭಾಷೆ', 'ಬಾಸೆ');
  String get tuluLipi => _t(
    'Show Tulu text in Tulu lipi',
    'ತುಳು ಲಿಪಿಯಲ್ಲಿ ತೋರಿಸಿ',
    'ತುಳು ಲಿಪಿಡ್ ತೋಜಾಲೆ',
  );
  String get tuluLipiHint => _t(
    'Applies when the language is Tulu (Tulu-Tigalari script).',
    'ಭಾಷೆ ತುಳು ಆಗಿರುವಾಗ ಅನ್ವಯಿಸುತ್ತದೆ.',
  );
  String get location => _t('Location', 'ಸ್ಥಳ', 'ಜಾಗೆ');
  String get customLocation => _t('Custom location', 'ಇತರ ಸ್ಥಳ');
  String get latitude => _t('Latitude', 'ಅಕ್ಷಾಂಶ');
  String get longitude => _t('Longitude (east +)', 'ರೇಖಾಂಶ (ಪೂರ್ವ +)');
  String get timeZone => _t('Time zone', 'ಸಮಯ ವಲಯ');
  String get placeName => _t('Name', 'ಹೆಸರು', 'ಪುದರ್');
  String get save => _t('Save', 'ಉಳಿಸಿ');
  String get cancel => _t('Cancel', 'ರದ್ದು');
  String get conventions => _t('Conventions', 'ಪದ್ಧತಿಗಳು');
  String get sunriseRule => _t('Sunrise definition', 'ಸೂರ್ಯೋದಯದ ವ್ಯಾಖ್ಯೆ');
  String get upperLimb =>
      _t('Upper limb + refraction (modern)', 'ಮೇಲಿನ ಅಂಚು + ವಕ್ರೀಭವನ (ಆಧುನಿಕ)');
  String get discCentre =>
      _t('Centre of disc (traditional)', 'ಬಿಂಬದ ಕೇಂದ್ರ (ಸಾಂಪ್ರದಾಯಿಕ)');
  String get monthRule =>
      _t('Tulu month day 1', 'ತುಳು ತಿಂಗಳ ಮೊದಲ ದಿನ', 'ತಿಂಗೊಲುದ ಸುರುತ ದಿನ');
  String get ruleSunset => _t(
    'Sankramana before sunset → same day',
    'ಸೂರ್ಯಾಸ್ತದ ಮೊದಲು ಸಂಕ್ರಮಣ → ಅದೇ ದಿನ',
  );
  String get ruleAparahna => _t(
    'Sankramana before 3/5 of day → same day',
    'ಹಗಲಿನ 3/5 ಮೊದಲು ಸಂಕ್ರಮಣ → ಅದೇ ದಿನ',
  );
  String get ruleNextDay =>
      _t('Always the day after sankramana', 'ಯಾವಾಗಲೂ ಸಂಕ್ರಮಣದ ಮರುದಿನ');
  String get tieRule => _t('Tithi on two days', 'ಎರಡು ದಿನ ತಿಥಿ');
  String get tieFirst => _t('Prefer first day', 'ಮೊದಲ ದಿನ');
  String get tieSecond => _t('Prefer second day', 'ಎರಡನೇ ದಿನ');
  String get theme => _t('Theme', 'ಥೀಮ್');
  String get themeSystem => _t('System', 'ಸಿಸ್ಟಂ');
  String get themeLight => _t('Light', 'ತಿಳಿ');
  String get themeDark => _t('Dark', 'ಗಾಢ');
  String get notifications => _t('Notifications', 'ಅಧಿಸೂಚನೆಗಳು');
  String get dailyNotification =>
      _t('Daily panchanga in the morning', 'ಬೆಳಿಗ್ಗೆ ದಿನದ ಪಂಚಾಂಗ');
  String get festivalReminder =>
      _t('Festival reminder the evening before', 'ಹಿಂದಿನ ಸಂಜೆ ಹಬ್ಬದ ನೆನಪು');
  String get rahuReminder =>
      _t('Alert when Rahu kaala starts', 'ರಾಹು ಕಾಲ ಆರಂಭದ ಸೂಚನೆ');
  String get notifyAt => _t('Time', 'ಸಮಯ');
  String get widgetHint => _t(
    'Add the “Tulu Panchanga” home-screen widget from your launcher.',
    'ಲಾಂಚರ್‌ನಿಂದ “ತುಳು ಪಂಚಾಂಗ” ವಿಜೆಟ್ ಸೇರಿಸಿ.',
  );
  String get about => _t('About & accuracy', 'ಮಾಹಿತಿ ಮತ್ತು ನಿಖರತೆ');
  String get aboutText => _t(
    'Calculated on the phone, offline: VSOP87 Sun, ELP/Meeus Moon, Lahiri '
        'ayanamsa (agrees with the Swiss Ephemeris to under a minute). '
        'Festival days follow the rules shown with each festival; local '
        'temples and family traditions may differ — please confirm with '
        'your priest or a printed panchanga.',
    'ಫೋನ್‌ನಲ್ಲೇ ಆಫ್‌ಲೈನ್ ಲೆಕ್ಕಾಚಾರ: VSOP87 ಸೂರ್ಯ, ELP/ಮೀಯಸ್ ಚಂದ್ರ, ಲಾಹಿರಿ '
        'ಅಯನಾಂಶ. ಹಬ್ಬದ ದಿನಗಳು ತೋರಿಸಿದ ನಿಯಮಗಳಂತೆ; ಸ್ಥಳೀಯ ಸಂಪ್ರದಾಯಗಳು '
        'ಬೇರೆ ಇರಬಹುದು — ಪುರೋಹಿತರಲ್ಲಿ ಅಥವಾ ಮುದ್ರಿತ ಪಂಚಾಂಗದಲ್ಲಿ ಖಚಿತಪಡಿಸಿ.',
  );
  String get rule => _t('Rule', 'ನಿಯಮ');
  String get confidenceLow =>
      _t('Please verify locally', 'ಸ್ಥಳೀಯವಾಗಿ ಖಚಿತಪಡಿಸಿ');
  String get adhika => _t('Adhika', 'ಅಧಿಕ');
}

/// UI strings in English, Kannada, Tulu, Konkani (Kannada script), Hindi,
/// Malayalam and Telugu.
///
/// Fallbacks when a translation is missing: Tulu and Konkani → Kannada
/// (most panchanga terms are shared), Hindi/Malayalam/Telugu → English.
/// Tulu, Konkani, Malayalam and Telugu wording is listed in docs/VERIFY.md
/// for a native speaker's review.
library;

import '../panchanga/names.dart';

class S {
  const S(this.lang);
  final Lang lang;

  String _t(
    String en,
    String kn, {
    String? tcy,
    String? kok,
    String? hi,
    String? ml,
    String? te,
  }) => switch (lang) {
    Lang.en => en,
    Lang.kn => kn,
    Lang.tcy => tcy ?? kn,
    Lang.kok => kok ?? kn,
    Lang.hi => hi ?? en,
    Lang.ml => ml ?? en,
    Lang.te => te ?? en,
  };

  String get appTitle => _t(
    'Tulu Panchanga',
    'ತುಳು ಪಂಚಾಂಗ',
    hi: 'तुलु पंचांग',
    ml: 'തുളു പഞ്ചാംഗം',
    te: 'తుళు పంచాంగం',
  );
  String get today => _t(
    'Today',
    'ಇಂದು',
    tcy: 'ಇನಿ',
    kok: 'ಆಜ್',
    hi: 'आज',
    ml: 'ഇന്ന്',
    te: 'ఈరోజు',
  );
  String get calendar => _t(
    'Calendar',
    'ಕ್ಯಾಲೆಂಡರ್',
    hi: 'कैलेंडर',
    ml: 'കലണ്ടർ',
    te: 'క్యాలెండర్',
  );
  String get festivals => _t(
    'Festivals',
    'ಹಬ್ಬಗಳು',
    tcy: 'ಪರ್ಬೊಲು',
    kok: 'ಸಣಾಂ',
    hi: 'त्योहार',
    ml: 'ഉത്സവങ്ങൾ',
    te: 'పండుగలు',
  );

  /// Shorter labels for the bottom tabs.
  String get tabFestivals => lang == Lang.ml ? 'ഉത്സവം' : festivals;
  String get tabSettings => lang == Lang.ml ? 'സെറ്റിങ്സ്' : settings;

  String get muhurta =>
      _t('Muhurta', 'ಮುಹೂರ್ತ', hi: 'मुहूर्त', ml: 'മുഹൂർത്തം', te: 'ముహూర్తం');
  String get settings => _t(
    'Settings',
    'ಸೆಟ್ಟಿಂಗ್ಸ್',
    hi: 'सेटिंग्स',
    ml: 'ക്രമീകരണം',
    te: 'సెట్టింగ్స్',
  );

  String get sunrise => _t(
    'Sunrise',
    'ಸೂರ್ಯೋದಯ',
    hi: 'सूर्योदय',
    ml: 'സൂര്യോദയം',
    te: 'సూర్యోదయం',
  );
  String get sunset => _t(
    'Sunset',
    'ಸೂರ್ಯಾಸ್ತ',
    hi: 'सूर्यास्त',
    ml: 'സൂര്യാസ്തമയം',
    te: 'సూర్యాస్తమయం',
  );
  String get moonrise => _t(
    'Moonrise',
    'ಚಂದ್ರೋದಯ',
    hi: 'चंद्रोदय',
    ml: 'ചന്ദ്രോദയം',
    te: 'చంద్రోదయం',
  );
  String get moonset => _t(
    'Moonset',
    'ಚಂದ್ರಾಸ್ತ',
    hi: 'चंद्रास्त',
    ml: 'ചന്ദ്രാസ്തമയം',
    te: 'చంద్రాస్తమయం',
  );
  String get noMoonrise => _t(
    'No moonrise',
    'ಚಂದ್ರೋದಯವಿಲ್ಲ',
    kok: 'ಚಂದ್ರೋದಯ ನಾ',
    hi: 'चंद्रोदय नहीं',
    ml: 'ചന്ദ്രോദയമില്ല',
    te: 'చంద్రోదయం లేదు',
  );
  String get noMoonset => _t(
    'No moonset',
    'ಚಂದ್ರಾಸ್ತವಿಲ್ಲ',
    kok: 'ಚಂದ್ರಾಸ್ತ ನಾ',
    hi: 'चंद्रास्त नहीं',
    ml: 'ചന്ദ്രാസ്തമയമില്ല',
    te: 'చంద్రాస్తమయం లేదు',
  );

  String get tithi => _t('Tithi', 'ತಿಥಿ', hi: 'तिथि', ml: 'തിഥി', te: 'తిథి');
  String get nakshatra =>
      _t('Nakshatra', 'ನಕ್ಷತ್ರ', hi: 'नक्षत्र', ml: 'നക്ഷത്രം', te: 'నక్షత్రం');
  String get yoga => _t('Yoga', 'ಯೋಗ', hi: 'योग', ml: 'യോഗം', te: 'యోగం');
  String get karana => _t('Karana', 'ಕರಣ', hi: 'करण', ml: 'കരണം', te: 'కరణం');
  String get vara => _t('Weekday', 'ವಾರ', hi: 'वार', ml: 'ആഴ്ച', te: 'వారం');
  String get paksha =>
      _t('Paksha', 'ಪಕ್ಷ', hi: 'पक्ष', ml: 'പക്ഷം', te: 'పక్షం');
  String get rashi => _t(
    'Moon sign',
    'ಚಂದ್ರ ರಾಶಿ',
    hi: 'चंद्र राशि',
    ml: 'ചന്ദ്ര രാശി',
    te: 'చంద్ర రాశి',
  );
  String get sunSign => _t(
    'Sun sign',
    'ಸೂರ್ಯ ರಾಶಿ',
    hi: 'सूर्य राशि',
    ml: 'സൂര്യ രാശി',
    te: 'సూర్య రాశి',
  );
  String get pada => _t('pada', 'ಪಾದ', hi: 'पाद', ml: 'പാദം', te: 'పాదం');

  String get lunarMonth => _t(
    'Lunar month',
    'ಚಾಂದ್ರಮಾನ ಮಾಸ',
    kok: 'ಚಾಂದ್ರಮಾನ ಮಹಿನೊ',
    hi: 'चांद्र मास',
    ml: 'ചാന്ദ്രമാസം',
    te: 'చాంద్రమాన మాసం',
  );
  String get tuluMonth => _t(
    'Tulu month',
    'ತುಳು ತಿಂಗಳು',
    tcy: 'ತುಳು ತಿಂಗೊಲು',
    kok: 'ತುಳು ಮಹಿನೊ',
    hi: 'तुलु मास',
    ml: 'തുളു മാസം',
    te: 'తుళు మాసం',
  );
  String get samvatsara => _t(
    'Samvatsara',
    'ಸಂವತ್ಸರ',
    hi: 'संवत्सर',
    ml: 'സംവത്സരം',
    te: 'సంవత్సరం',
  );
  String get sauraSamvatsara => _t(
    'Samvatsara (Sauramana)',
    'ಸಂವತ್ಸರ (ಸೌರಮಾನ)',
    hi: 'संवत्सर (सौरमान)',
    ml: 'സംവത്സരം (സൗരമാനം)',
    te: 'సంవత్సరం (సౌరమానం)',
  );
  String get shaka => _t('Shaka', 'ಶಕ', hi: 'शक', ml: 'ശകം', te: 'శక');
  String get kali => _t('Kali', 'ಕಲಿ', hi: 'कलि', ml: 'കലി', te: 'కలి');
  String get ayana => _t('Ayana', 'ಅಯನ', hi: 'अयन', ml: 'അയനം', te: 'ఆయనం');
  String get ritu => _t('Ritu', 'ಋತು', hi: 'ऋतु', ml: 'ഋതു', te: 'ఋతువు');
  String get sankramana => _t(
    'Sankramana',
    'ಸಂಕ್ರಮಣ',
    hi: 'संक्रांति',
    ml: 'സംക്രമം',
    te: 'సంక్రమణం',
  );

  String get rahu => _t(
    'Rahu kaala',
    'ರಾಹು ಕಾಲ',
    hi: 'राहु काल',
    ml: 'രാഹുകാലം',
    te: 'రాహు కాలం',
  );
  String get yamaganda =>
      _t('Yamaganda', 'ಯಮಗಂಡ', hi: 'यमगंड', ml: 'യമഗണ്ഡം', te: 'యమగండం');
  String get gulika => _t(
    'Gulika kaala',
    'ಗುಳಿಕ ಕಾಲ',
    hi: 'गुलिक काल',
    ml: 'ഗുളികകാലം',
    te: 'గుళిక కాలం',
  );
  String get abhijit => _t(
    'Abhijit muhurta',
    'ಅಭಿಜಿತ್ ಮುಹೂರ್ತ',
    hi: 'अभिजीत मुहूर्त',
    ml: 'അഭിജിത് മുഹൂർത്തം',
    te: 'అభిజిత్ ముహూర్తం',
  );
  String get brahma => _t(
    'Brahma muhurta',
    'ಬ್ರಹ್ಮ ಮುಹೂರ್ತ',
    hi: 'ब्रह्म मुहूर्त',
    ml: 'ബ്രഹ്മ മുഹൂർത്തം',
    te: 'బ్రహ్మ ముహూర్తం',
  );
  String get durmuhurta => _t(
    'Durmuhurta',
    'ದುರ್ಮುಹೂರ್ತ',
    hi: 'दुर्मुहूर्त',
    ml: 'ദുർമുഹൂർത്തം',
    te: 'దుర్ముహూర్తం',
  );
  String get inauspicious =>
      _t('Avoid', 'ಅಶುಭ ಕಾಲ', hi: 'अशुभ काल', ml: 'അശുഭ സമയം', te: 'అశుభ సమయం');
  String get auspicious => _t(
    'Good times',
    'ಶುಭ ಕಾಲ',
    hi: 'शुभ काल',
    ml: 'ശുഭ സമയം',
    te: 'శుభ సమయం',
  );

  String get until => _t(
    'until',
    'ವರೆಗೆ',
    tcy: 'ಮುಟ್ಟ',
    kok: 'ಪರ್ಯಾಂತ್',
    hi: 'तक',
    ml: 'വരെ',
    te: 'వరకు',
  );

  /// "until 05:40" / "05:40 ವರೆಗೆ" (word order differs).
  String untilTime(String time) =>
      lang == Lang.en ? 'until $time' : '$time $until';
  String get nextDay => _t(
    'next day',
    'ಮರುದಿನ',
    tcy: 'ಎಲ್ಲೆ',
    kok: 'ಫಾಲ್ಯಾಂ',
    hi: 'अगले दिन',
    ml: 'പിറ്റേന്ന്',
    te: 'మరుసటి రోజు',
  );
  String get untilNextSunrise => _t(
    'till next sunrise',
    'ಮರುದಿನ ಸೂರ್ಯೋದಯದವರೆಗೆ',
    tcy: 'ಎಲ್ಲೆ ಸೂರ್ಯೋದಯ ಮುಟ್ಟ',
    kok: 'ಫಾಲ್ಯಾಂ ಸೂರ್ಯೋದಯ ಪರ್ಯಾಂತ್',
    hi: 'अगले सूर्योदय तक',
    ml: 'അടുത്ത സൂര്യോദയം വരെ',
    te: 'మరుసటి సూర్యోదయం వరకు',
  );
  String get now => _t(
    'Now',
    'ಈಗ',
    tcy: 'ಇತ್ತೆ',
    kok: 'ಆತಾಂ',
    hi: 'अभी',
    ml: 'ഇപ്പോൾ',
    te: 'ఇప్పుడు',
  );
  String get fullDetails => _t(
    'Full details',
    'ಪೂರ್ಣ ವಿವರ',
    kok: 'ಸಂಪೂರ್ಣ ವಿವರ್',
    hi: 'पूरा विवरण',
    ml: 'മുഴുവൻ വിവരങ്ങൾ',
    te: 'పూర్తి వివరాలు',
  );
  String get share => _t(
    'Share',
    'ಹಂಚಿಕೊಳ್ಳಿ',
    kok: 'ವಾಂಟುನ್ ದೀ',
    hi: 'शेयर करें',
    ml: 'പങ്കിടുക',
    te: 'పంచుకోండి',
  );
  String get pickDate => _t(
    'Pick a date',
    'ದಿನಾಂಕ ಆಯ್ಕೆ',
    kok: 'ತಾರೀಕ್ ವೊಂಚ್',
    hi: 'तारीख चुनें',
    ml: 'തീയതി തിരഞ്ഞെടുക്കുക',
    te: 'తేదీ ఎంచుకోండి',
  );
  String get festivalsToday => _t(
    'Festivals & vratas',
    'ಹಬ್ಬ ಮತ್ತು ವ್ರತಗಳು',
    kok: 'ಸಣಾಂ ಆನಿ ವ್ರತಾಂ',
    hi: 'त्योहार और व्रत',
    ml: 'ഉത്സവങ്ങളും വ്രതങ്ങളും',
    te: 'పండుగలు, వ్రతాలు',
  );
  String get sunMoon => _t(
    'Sun & Moon',
    'ಸೂರ್ಯ ಚಂದ್ರ',
    kok: 'ಸೂರ್ಯ ಆನಿ ಚಂದ್ರ',
    hi: 'सूर्य और चंद्र',
    ml: 'സൂര്യനും ചന്ദ്രനും',
    te: 'సూర్య చంద్రులు',
  );
  String get panchanga =>
      _t('Panchanga', 'ಪಂಚಾಂಗ', hi: 'पंचांग', ml: 'പഞ്ചാംഗം', te: 'పంచాంగం');
  String get yearAndMonth => _t(
    'Year & month',
    'ವರ್ಷ ಮತ್ತು ಮಾಸ',
    kok: 'ವರ್ಸ್ ಆನಿ ಮಹಿನೊ',
    hi: 'वर्ष और मास',
    ml: 'വർഷവും മാസവും',
    te: 'సంవత్సరం, మాసం',
  );
  String get timeline => _t(
    'Day timeline',
    'ದಿನದ ಸಮಯರೇಖೆ',
    kok: 'ದಿಸಾಚೊ ವೇಳ್',
    hi: 'दिन की समयरेखा',
    ml: 'ദിവസത്തിന്റെ സമയരേഖ',
    te: 'రోజు సమయరేఖ',
  );
  String get loading => _t(
    'Calculating…',
    'ಲೆಕ್ಕ ಹಾಕುತ್ತಿದೆ…',
    kok: 'ಲೆಖ್ ಕರ್ತಾ…',
    hi: 'गणना हो रही है…',
    ml: 'കണക്കാക്കുന്നു…',
    te: 'లెక్కిస్తోంది…',
  );

  String get gregorian => _t(
    'Gregorian',
    'ಇಂಗ್ಲಿಷ್ ತಿಂಗಳು',
    kok: 'ಇಂಗ್ಲಿಷ್ ಮಹಿನೊ',
    hi: 'अंग्रेज़ी महीना',
    ml: 'ഇംഗ്ലീഷ് മാസം',
    te: 'ఆంగ్ల నెల',
  );
  String get tuluCalendar => _t(
    'Tulu month',
    'ತುಳು ತಿಂಗಳು',
    tcy: 'ತುಳು ತಿಂಗೊಲು',
    kok: 'ತುಳು ಮಹಿನೊ',
    hi: 'तुलु मास',
    ml: 'തുളു മാസം',
    te: 'తుళు నెల',
  );
  String get all => _t(
    'All',
    'ಎಲ್ಲಾ',
    tcy: 'ಮಾತ',
    kok: 'ಸಗ್ಳಿಂ',
    hi: 'सभी',
    ml: 'എല്ലാം',
    te: 'అన్నీ',
  );
  String get year => _t(
    'Year',
    'ವರ್ಷ',
    tcy: 'ವರ್ಸ',
    kok: 'ವರ್ಸ್',
    hi: 'वर्ष',
    ml: 'വർഷം',
    te: 'సంవత్సరం',
  );
  String get noFestivals => _t(
    'Nothing listed',
    'ಏನೂ ಇಲ್ಲ',
    tcy: 'ದಾಲ ಇಜ್ಜಿ',
    kok: 'ಕಾಂಯ್ ನಾ',
    hi: 'कुछ नहीं',
    ml: 'ഒന്നുമില്ല',
    te: 'ఏమీ లేదు',
  );

  String get activity => _t(
    'Activity',
    'ಕಾರ್ಯ',
    kok: 'ಕಾಮ್',
    hi: 'कार्य',
    ml: 'കാര്യം',
    te: 'కార్యం',
  );
  String get startDate =>
      _t('From', 'ಇಂದ', kok: 'ಥಾವ್ನ್', hi: 'से', ml: 'മുതൽ', te: 'నుండి');
  String get days => _t(
    'days',
    'ದಿನಗಳು',
    tcy: 'ದಿನೊಕುಲು',
    kok: 'ದೀಸ್',
    hi: 'दिन',
    ml: 'ദിവസം',
    te: 'రోజులు',
  );
  String get janmaNakshatra => _t(
    'Birth star (optional)',
    'ಜನ್ಮ ನಕ್ಷತ್ರ (ಐಚ್ಛಿಕ)',
    hi: 'जन्म नक्षत्र (वैकल्पिक)',
    ml: 'ജന്മനക്ഷത്രം (ഐച്ഛികം)',
    te: 'జన్మ నక్షత్రం (ఐచ్ఛికం)',
  );
  String get janmaRashi => _t(
    'Birth rashi (optional)',
    'ಜನ್ಮ ರಾಶಿ (ಐಚ್ಛಿಕ)',
    hi: 'जन्म राशि (वैकल्पिक)',
    ml: 'ജന്മരാശി (ഐച്ഛികം)',
    te: 'జన్మ రాశి (ఐచ్ఛికం)',
  );
  String get notSet => _t(
    'Not set',
    'ಆಯ್ಕೆ ಇಲ್ಲ',
    kok: 'ವೊಂಚೊಂಕ್ ನಾ',
    hi: 'चुना नहीं',
    ml: 'തിരഞ്ഞെടുത്തിട്ടില്ല',
    te: 'ఎంచుకోలేదు',
  );
  String get find => _t(
    'Find muhurtas',
    'ಮುಹೂರ್ತ ಹುಡುಕಿ',
    kok: 'ಮುಹೂರ್ತ ಸೊಧ್',
    hi: 'मुहूर्त खोजें',
    ml: 'മുഹൂർത്തം കണ്ടെത്തുക',
    te: 'ముహూర్తం వెతకండి',
  );
  String get noMuhurta => _t(
    'No suitable window in this period.',
    'ಈ ಅವಧಿಯಲ್ಲಿ ಸೂಕ್ತ ಸಮಯವಿಲ್ಲ.',
    hi: 'इस अवधि में उपयुक्त समय नहीं है।',
    ml: 'ഈ കാലയളവിൽ അനുയോജ്യമായ സമയമില്ല.',
    te: 'ఈ వ్యవధిలో అనువైన సమయం లేదు.',
  );
  String get muhurtaDisclaimer => _t(
    'A shortlist from simple rules (tithi, nakshatra, weekday, yoga, karana, '
        'Rahu/Yama/Gulika, durmuhurta). Always confirm with your priest.',
    'ತಿಥಿ, ನಕ್ಷತ್ರ, ವಾರ, ಯೋಗ, ಕರಣ, ರಾಹು/ಯಮ/ಗುಳಿಕ, ದುರ್ಮುಹೂರ್ತ ಆಧಾರಿತ '
        'ಪಟ್ಟಿ ಮಾತ್ರ. ನಿಮ್ಮ ಪುರೋಹಿತರಲ್ಲಿ ಖಚಿತಪಡಿಸಿಕೊಳ್ಳಿ.',
    hi:
        'तिथि, नक्षत्र, वार, योग, करण, राहु/यम/गुलिक और दुर्मुहूर्त के सरल '
        'नियमों से बनी सूची। अपने पुरोहित से अवश्य पुष्टि करें।',
    ml:
        'തിഥി, നക്ഷത്രം, ആഴ്ച, യോഗം, കരണം, രാഹു/യമ/ഗുളിക, ദുർമുഹൂർത്തം '
        'എന്നിവയുടെ ലളിത നിയമങ്ങളിൽ നിന്നുള്ള പട്ടിക. പുരോഹിതനോട് ഉറപ്പാക്കുക.',
    te:
        'తిథి, నక్షత్రం, వారం, యోగం, కరణం, రాహు/యమ/గుళిక, దుర్ముహూర్తం '
        'ఆధారంగా చేసిన జాబితా మాత్రమే. మీ పురోహితుడిని తప్పక సంప్రదించండి.',
  );
  String get score => _t('score', 'ಅಂಕ', hi: 'अंक', ml: 'സ്കോർ', te: 'స్కోరు');

  String get language => _t(
    'Language',
    'ಭಾಷೆ',
    tcy: 'ಬಾಸೆ',
    kok: 'ಭಾಸ್',
    hi: 'भाषा',
    ml: 'ഭാഷ',
    te: 'భాష',
  );
  String get chooseLanguage => _t(
    'Choose your language',
    'ನಿಮ್ಮ ಭಾಷೆ ಆಯ್ಕೆ ಮಾಡಿ',
    tcy: 'ಇರೆನ ಬಾಸೆ ಆಯ್ಕೆ ಮಲ್ಪುಲೆ',
    kok: 'ತುಮ್ಚಿ ಭಾಸ್ ವೊಂಚಾ',
    hi: 'अपनी भाषा चुनें',
    ml: 'നിങ്ങളുടെ ഭാഷ തിരഞ്ഞെടുക്കുക',
    te: 'మీ భాషను ఎంచుకోండి',
  );
  String get languageLater => _t(
    'You can change it any time in Settings.',
    'ಇದನ್ನು ಯಾವಾಗ ಬೇಕಾದರೂ ಸೆಟ್ಟಿಂಗ್ಸ್‌ನಲ್ಲಿ ಬದಲಿಸಬಹುದು.',
    hi: 'इसे कभी भी सेटिंग्स में बदल सकते हैं।',
    ml: 'ഇത് എപ്പോൾ വേണമെങ്കിലും ക്രമീകരണത്തിൽ മാറ്റാം.',
    te: 'దీన్ని ఎప్పుడైనా సెట్టింగ్స్‌లో మార్చవచ్చు.',
  );
  String get tuluLipi => _t(
    'Show Tulu text in Tulu lipi',
    'ತುಳು ಲಿಪಿಯಲ್ಲಿ ತೋರಿಸಿ',
    tcy: 'ತುಳು ಲಿಪಿಡ್ ತೋಜಾಲೆ',
    hi: 'तुलु पाठ तुलु लिपि में दिखाएँ',
    ml: 'തുളു വാചകം തുളു ലിപിയിൽ കാണിക്കുക',
    te: 'తుళు పాఠ్యాన్ని తుళు లిపిలో చూపించు',
  );
  String get tuluLipiHint => _t(
    'Applies when the language is Tulu (Tulu-Tigalari script).',
    'ಭಾಷೆ ತುಳು ಆಗಿರುವಾಗ ಅನ್ವಯಿಸುತ್ತದೆ.',
    hi: 'भाषा तुलु होने पर लागू (तुलु-तिगलारी लिपि)।',
    ml: 'ഭാഷ തുളു ആയിരിക്കുമ്പോൾ മാത്രം (തുളു-തിഗളാരി ലിപി).',
    te: 'భాష తుళు అయినప్పుడు వర్తిస్తుంది (తుళు-తిగళారి లిపి).',
  );
  String get location => _t(
    'Location',
    'ಸ್ಥಳ',
    tcy: 'ಜಾಗೆ',
    kok: 'ಜಾಗೊ',
    hi: 'स्थान',
    ml: 'സ്ഥലം',
    te: 'ప్రదేశం',
  );
  String get customLocation => _t(
    'Custom location',
    'ಇತರ ಸ್ಥಳ',
    kok: 'ಹೆರ್ ಜಾಗೊ',
    hi: 'अन्य स्थान',
    ml: 'മറ്റൊരു സ്ഥലം',
    te: 'ఇతర ప్రదేశం',
  );
  String get latitude =>
      _t('Latitude', 'ಅಕ್ಷಾಂಶ', hi: 'अक्षांश', ml: 'അക്ഷാംശം', te: 'అక్షాంశం');
  String get longitude => _t(
    'Longitude (east +)',
    'ರೇಖಾಂಶ (ಪೂರ್ವ +)',
    hi: 'देशांतर (पूर्व +)',
    ml: 'രേഖാംശം (കിഴക്ക് +)',
    te: 'రేఖాంశం (తూర్పు +)',
  );
  String get timeZone => _t(
    'Time zone',
    'ಸಮಯ ವಲಯ',
    hi: 'समय क्षेत्र',
    ml: 'സമയമേഖല',
    te: 'సమయ మండలం',
  );
  String get placeName => _t(
    'Name',
    'ಹೆಸರು',
    tcy: 'ಪುದರ್',
    kok: 'ನಾಂವ್',
    hi: 'नाम',
    ml: 'പേര്',
    te: 'పేరు',
  );
  String get save => _t(
    'Save',
    'ಉಳಿಸಿ',
    kok: 'ಉರಯ್',
    hi: 'सहेजें',
    ml: 'സേവ് ചെയ്യുക',
    te: 'సేవ్ చేయండి',
  );
  String get cancel => _t(
    'Cancel',
    'ರದ್ದು',
    kok: 'ರದ್ದ್',
    hi: 'रद्द करें',
    ml: 'റദ്ദാക്കുക',
    te: 'రద్దు',
  );
  String get conventions => _t(
    'Conventions',
    'ಪದ್ಧತಿಗಳು',
    hi: 'पद्धतियाँ',
    ml: 'സമ്പ്രദായങ്ങൾ',
    te: 'పద్ధతులు',
  );
  String get sunriseRule => _t(
    'Sunrise definition',
    'ಸೂರ್ಯೋದಯದ ವ್ಯಾಖ್ಯೆ',
    hi: 'सूर्योदय की परिभाषा',
    ml: 'സൂര്യോദയ നിർവചനം',
    te: 'సూర్యోదయ నిర్వచనం',
  );
  String get upperLimb => _t(
    'Upper limb + refraction (modern)',
    'ಮೇಲಿನ ಅಂಚು + ವಕ್ರೀಭವನ (ಆಧುನಿಕ)',
    hi: 'ऊपरी किनारा + अपवर्तन (आधुनिक)',
    ml: 'മുകളറ്റം + അപവർത്തനം (ആധുനികം)',
    te: 'పై అంచు + వక్రీభవనం (ఆధునికం)',
  );
  String get discCentre => _t(
    'Centre of disc (traditional)',
    'ಬಿಂಬದ ಕೇಂದ್ರ (ಸಾಂಪ್ರದಾಯಿಕ)',
    hi: 'बिंब का केंद्र (पारंपरिक)',
    ml: 'ബിംബ കേന്ദ്രം (പരമ്പരാഗതം)',
    te: 'బింబ కేంద్రం (సాంప్రదాయికం)',
  );
  String get monthRule => _t(
    'Tulu month day 1',
    'ತುಳು ತಿಂಗಳ ಮೊದಲ ದಿನ',
    tcy: 'ತಿಂಗೊಲುದ ಸುರುತ ದಿನ',
    hi: 'तुलु मास का पहला दिन',
    ml: 'തുളു മാസത്തിലെ ഒന്നാം ദിവസം',
    te: 'తుళు నెల మొదటి రోజు',
  );
  String get ruleSunset => _t(
    'Sankramana before sunset → same day',
    'ಸೂರ್ಯಾಸ್ತದ ಮೊದಲು ಸಂಕ್ರಮಣ → ಅದೇ ದಿನ',
    hi: 'सूर्यास्त से पहले संक्रांति → उसी दिन',
    ml: 'സൂര്യാസ്തമയത്തിന് മുമ്പ് സംക്രമം → അതേ ദിവസം',
    te: 'సూర్యాస్తమయానికి ముందు సంక్రమణం → అదే రోజు',
  );
  String get ruleAparahna => _t(
    'Sankramana before 3/5 of day → same day',
    'ಹಗಲಿನ 3/5 ಮೊದಲು ಸಂಕ್ರಮಣ → ಅದೇ ದಿನ',
    hi: 'दिन के 3/5 से पहले संक्रांति → उसी दिन',
    ml: 'പകലിന്റെ 3/5ന് മുമ്പ് സംക്രമം → അതേ ദിവസം',
    te: 'పగటి 3/5కు ముందు సంక్రమణం → అదే రోజు',
  );
  String get ruleNextDay => _t(
    'Always the day after sankramana',
    'ಯಾವಾಗಲೂ ಸಂಕ್ರಮಣದ ಮರುದಿನ',
    hi: 'हमेशा संक्रांति का अगला दिन',
    ml: 'എപ്പോഴും സംക്രമത്തിന്റെ പിറ്റേന്ന്',
    te: 'ఎల్లప్పుడూ సంక్రమణం తర్వాతి రోజు',
  );
  String get tieRule => _t(
    'Tithi on two days',
    'ಎರಡು ದಿನ ತಿಥಿ',
    hi: 'दो दिन तिथि',
    ml: 'രണ്ട് ദിവസം തിഥി',
    te: 'రెండు రోజుల తిథి',
  );
  String get tieFirst => _t(
    'Prefer first day',
    'ಮೊದಲ ದಿನ',
    hi: 'पहला दिन',
    ml: 'ആദ്യ ദിവസം',
    te: 'మొదటి రోజు',
  );
  String get tieSecond => _t(
    'Prefer second day',
    'ಎರಡನೇ ದಿನ',
    hi: 'दूसरा दिन',
    ml: 'രണ്ടാം ദിവസം',
    te: 'రెండవ రోజు',
  );
  String get theme => _t('Theme', 'ಥೀಮ್', hi: 'थीम', ml: 'തീം', te: 'థీమ్');
  String get themeSystem =>
      _t('System', 'ಸಿಸ್ಟಂ', hi: 'सिस्टम', ml: 'സിസ്റ്റം', te: 'సిస్టమ్');
  String get themeLight =>
      _t('Light', 'ತಿಳಿ', kok: 'ಉಜ್ವಾಡ್', hi: 'हल्का', ml: 'ലൈറ്റ്', te: 'లేత');
  String get themeDark =>
      _t('Dark', 'ಗಾಢ', kok: 'ಕಾಳೊಕ್', hi: 'गहरा', ml: 'ഡാർക്ക്', te: 'ముదురు');
  String get notifications => _t(
    'Notifications',
    'ಅಧಿಸೂಚನೆಗಳು',
    hi: 'सूचनाएँ',
    ml: 'അറിയിപ്പുകൾ',
    te: 'నోటిఫికేషన్లు',
  );
  String get dailyNotification => _t(
    'Daily panchanga in the morning',
    'ಬೆಳಿಗ್ಗೆ ದಿನದ ಪಂಚಾಂಗ',
    kok: 'ಸಕಾಳಿಂ ದಿಸಾಚೆಂ ಪಂಚಾಂಗ',
    hi: 'सुबह दैनिक पंचांग',
    ml: 'രാവിലെ ദിവസത്തെ പഞ്ചാംഗം',
    te: 'ఉదయం రోజువారీ పంచాంగం',
  );
  String get festivalReminder => _t(
    'Festival reminder the evening before',
    'ಹಿಂದಿನ ಸಂಜೆ ಹಬ್ಬದ ನೆನಪು',
    hi: 'एक शाम पहले त्योहार की याद',
    ml: 'തലേന്ന് വൈകുന്നേരം ഉത്സവ ഓർമ്മപ്പെടുത്തൽ',
    te: 'ముందు రోజు సాయంత్రం పండుగ గుర్తు',
  );
  String get rahuReminder => _t(
    'Alert when Rahu kaala starts',
    'ರಾಹು ಕಾಲ ಆರಂಭದ ಸೂಚನೆ',
    hi: 'राहु काल शुरू होने पर सूचना',
    ml: 'രാഹുകാലം തുടങ്ങുമ്പോൾ അറിയിപ്പ്',
    te: 'రాహు కాలం మొదలైనప్పుడు హెచ్చరిక',
  );
  String get notifyAt =>
      _t('Time', 'ಸಮಯ', kok: 'ವೇಳ್', hi: 'समय', ml: 'സമയം', te: 'సమయం');
  String get widgetHint => _t(
    'Add the “Tulu Panchanga” home-screen widget from your launcher.',
    'ಲಾಂಚರ್‌ನಿಂದ “ತುಳು ಪಂಚಾಂಗ” ವಿಜೆಟ್ ಸೇರಿಸಿ.',
    hi: 'लॉन्चर से “तुलु पंचांग” विजेट जोड़ें।',
    ml: 'ലോഞ്ചറിൽ നിന്ന് “തുളു പഞ്ചാംഗം” വിജറ്റ് ചേർക്കുക.',
    te: 'లాంచర్ నుండి “తుళు పంచాంగం” విడ్జెట్ జోడించండి.',
  );
  String get about => _t(
    'About & accuracy',
    'ಮಾಹಿತಿ ಮತ್ತು ನಿಖರತೆ',
    hi: 'जानकारी और सटीकता',
    ml: 'വിവരവും കൃത്യതയും',
    te: 'సమాచారం, ఖచ్చితత్వం',
  );
  String get aboutText => _t(
    'Calculated on the phone, offline: VSOP87 Sun, ELP/Meeus Moon, Lahiri '
        'ayanamsa (agrees with the Swiss Ephemeris to under a minute). '
        'Festival days follow the rules shown with each festival; local '
        'temples and family traditions may differ — please confirm with '
        'your priest or a printed panchanga.',
    'ಫೋನ್‌ನಲ್ಲೇ ಆಫ್‌ಲೈನ್ ಲೆಕ್ಕಾಚಾರ: VSOP87 ಸೂರ್ಯ, ELP/ಮೀಯಸ್ ಚಂದ್ರ, ಲಾಹಿರಿ '
        'ಅಯನಾಂಶ. ಹಬ್ಬದ ದಿನಗಳು ತೋರಿಸಿದ ನಿಯಮಗಳಂತೆ; ಸ್ಥಳೀಯ ಸಂಪ್ರದಾಯಗಳು '
        'ಬೇರೆ ಇರಬಹುದು — ಪುರೋಹಿತರಲ್ಲಿ ಅಥವಾ ಮುದ್ರಿತ ಪಂಚಾಂಗದಲ್ಲಿ ಖಚಿತಪಡಿಸಿ.',
    hi:
        'फ़ोन पर ही ऑफ़लाइन गणना: VSOP87 सूर्य, ELP/मीयस चंद्र, लाहिड़ी '
        'अयनांश। त्योहार दिखाए गए नियमों से तय होते हैं; स्थानीय परंपराएँ '
        'अलग हो सकती हैं — पुरोहित या छपे पंचांग से पुष्टि करें।',
    ml:
        'ഫോണിൽ തന്നെ ഓഫ്‌ലൈൻ കണക്കുകൂട്ടൽ: VSOP87 സൂര്യൻ, ELP/മീയസ് ചന്ദ്രൻ, '
        'ലാഹിരി അയനാംശം. ഉത്സവങ്ങൾ കാണിച്ച നിയമങ്ങൾ പ്രകാരം; പ്രാദേശിക '
        'ആചാരങ്ങൾ വ്യത്യസ്തമാകാം — പുരോഹിതനോടോ അച്ചടിച്ച പഞ്ചാംഗത്തിലോ '
        'ഉറപ്പാക്കുക.',
    te:
        'ఫోన్‌లోనే ఆఫ్‌లైన్ గణన: VSOP87 సూర్యుడు, ELP/మీయస్ చంద్రుడు, లాహిరి '
        'అయనాంశ. పండుగలు చూపిన నియమాల ప్రకారం; స్థానిక సంప్రదాయాలు '
        'వేరుగా ఉండవచ్చు — పురోహితుడు లేదా ముద్రిత పంచాంగంతో '
        'నిర్ధారించుకోండి.',
  );
  String get rule => _t('Rule', 'ನಿಯಮ', hi: 'नियम', ml: 'നിയമം', te: 'నియమం');
  String get confidenceLow => _t(
    'Please verify locally',
    'ಸ್ಥಳೀಯವಾಗಿ ಖಚಿತಪಡಿಸಿ',
    hi: 'स्थानीय रूप से पुष्टि करें',
    ml: 'പ്രാദേശികമായി ഉറപ്പാക്കുക',
    te: 'స్థానికంగా నిర్ధారించుకోండి',
  );
  String get adhika => _t('Adhika', 'ಅಧಿಕ', hi: 'अधिक', ml: 'അധിക', te: 'అధిక');

  String get listen => _t(
    'Listen',
    'ಕೇಳಿ',
    tcy: 'ಕೇಣ್ಲೆ',
    kok: 'ಆಯ್ಕಾ',
    hi: 'सुनें',
    ml: 'കേൾക്കുക',
    te: 'వినండి',
  );
  String get stopListening => _t(
    'Stop',
    'ನಿಲ್ಲಿಸಿ',
    kok: 'ರಾವಯ್',
    hi: 'रोकें',
    ml: 'നിർത്തുക',
    te: 'ఆపండి',
  );
  String get noVoice => _t(
    'No voice for this language on the phone. Install it in Settings › '
        'Text-to-speech.',
    'ಫೋನ್‌ನಲ್ಲಿ ಈ ಭಾಷೆಯ ಧ್ವನಿ ಇಲ್ಲ. ಸೆಟ್ಟಿಂಗ್ಸ್ › ಪಠ್ಯದಿಂದ ಧ್ವನಿ ಯಲ್ಲಿ '
        'ಸ್ಥಾಪಿಸಿ.',
    hi:
        'फ़ोन में इस भाषा की आवाज़ नहीं है। सेटिंग्स › टेक्स्ट-टू-स्पीच में '
        'इंस्टॉल करें।',
    ml:
        'ഫോണിൽ ഈ ഭാഷയുടെ ശബ്ദം ഇല്ല. ക്രമീകരണം › ടെക്സ്റ്റ്-ടു-സ്പീച്ചിൽ '
        'ഇൻസ്റ്റാൾ ചെയ്യുക.',
    te:
        'ఫోన్‌లో ఈ భాష స్వరం లేదు. సెట్టింగ్స్ › టెక్స్ట్-టు-స్పీచ్‌లో '
        'ఇన్‌స్టాల్ చేయండి.',
  );
  String get todayFestival => _t(
    'Today',
    'ಇಂದಿನ ಹಬ್ಬ',
    tcy: 'ಇನಿತ ಪರ್ಬ',
    kok: 'ಆಜ್‌ಚೆಂ ಸಣ್',
    hi: 'आज का त्योहार',
    ml: 'ഇന്നത്തെ ഉത്സവം',
    te: 'ఈరోజు పండుగ',
  );
  String get comingUp => _t(
    'Coming up',
    'ಮುಂದಿನ ಹಬ್ಬ',
    tcy: 'ಬರ್ಪಿನ ಪರ್ಬ',
    kok: 'ಯೆಂವ್ಚೆಂ ಸಣ್',
    hi: 'आगामी त्योहार',
    ml: 'വരുന്ന ഉത്സവം',
    te: 'రాబోయే పండుగ',
  );
  String inDays(int n) => n == 1
      ? _t(
          'tomorrow',
          'ನಾಳೆ',
          tcy: 'ಎಲ್ಲೆ',
          kok: 'ಫಾಲ್ಯಾಂ',
          hi: 'कल',
          ml: 'നാളെ',
          te: 'రేపు',
        )
      : _t(
          'in $n days',
          '$n ದಿನಗಳಲ್ಲಿ',
          tcy: '$n ದಿನೊಡು',
          kok: '$n ದಿಸಾಂನಿ',
          hi: '$n दिन में',
          ml: '$n ദിവസത്തിനുള്ളിൽ',
          te: '$n రోజుల్లో',
        );
  String get from =>
      _t('from', 'ಇಂದ', kok: 'ಥಾವ್ನ್', hi: 'से', ml: 'മുതൽ', te: 'నుండి');
  String get to => _t(
    'to',
    'ವರೆಗೆ',
    tcy: 'ಮುಟ್ಟ',
    kok: 'ಪರ್ಯಾಂತ್',
    hi: 'तक',
    ml: 'വരെ',
    te: 'వరకు',
  );
}

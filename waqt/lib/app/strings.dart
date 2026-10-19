/// UI strings. English and Malayalam are written side by side here; the
/// other languages translate the English text through the tables in
/// `lib/l10n/` (missing entries fall back to English).
library;

import '../core/alerts.dart';
import '../core/events.dart';
import '../core/prayer_calc.dart';
import '../l10n/tables.dart';
import 'settings.dart';

class S {
  const S(this.lang);
  final Lang lang;

  bool get ml => lang == Lang.ml;

  String _t(String en, String mal) => switch (lang) {
    Lang.en => en,
    Lang.ml => mal,
    _ => translations[lang]?[en] ?? en,
  };

  /// Template with {0}, {1}… placeholders.
  String _f(String en, String mal, List<Object> args) {
    var out = _t(en, mal);
    for (var i = 0; i < args.length; i++) {
      out = out.replaceAll('{$i}', '${args[i]}');
    }
    return out;
  }

  String get appTitle => _t('Azan Time', 'ബാങ്ക് സമയം');
  String get appSubtitle => _t('Prayer Times & Qibla', 'നിസ്കാര സമയം');
  String get today => _t('Today', 'ഇന്ന്');
  String get month => _t('Month', 'മാസം');
  String get qibla => _t('Qibla', 'ഖിബ്‌ല');
  String get settings => _t('Settings', 'സെറ്റിംഗ്സ്');

  String prayer(Prayer p, {bool friday = false}) => switch (p) {
    Prayer.imsak => _t('Imsak', 'ഇംസാക്'),
    Prayer.fajr => _t('Fajr', 'സുബ്ഹ്'),
    Prayer.sunrise => _t('Sunrise', 'ഉദയം'),
    Prayer.ishraq => _t('Ishraq', 'ഇശ്റാഖ്'),
    Prayer.dhuhr => friday ? _t("Jumu'ah", 'ജുമുഅ') : _t('Dhuhr', 'ളുഹ്ർ'),
    Prayer.asr => _t('Asr', 'അസ്ർ'),
    Prayer.maghrib => _t('Maghrib', 'മഗ്‌രിബ്'),
    Prayer.isha => _t('Isha', 'ഇശാ'),
    Prayer.tahajjud => _t('Tahajjud', 'തഹജ്ജുദ്'),
  };

  String get azan => _t('Azan', 'ബാങ്ക്');
  String get iqama => _t('Iqama', 'ഇഖാമത്ത്');
  String get next => _t('Next', 'അടുത്തത്');
  String inTime(String d) => _f('in {0}', '{0} കഴിഞ്ഞ്', [d]);
  String iqamaIn(String d) => _f('Iqama in {0}', 'ഇഖാമത്തിന് {0}', [d]);
  String get hoursShort => _t('h', 'മ');
  String get minutesShort => _t('m', 'മി');
  String get minutes => _t('minutes', 'മിനിറ്റ്');
  String get previousDay => _t('Previous day', 'തലേ ദിവസം');
  String get nextDay => _t('Next day', 'അടുത്ത ദിവസം');
  String get backToToday => _t('Back to today', 'ഇന്നത്തേക്ക്');
  String get fromTimetable => _t('From timetable', 'ടൈംടേബിളിൽ നിന്ന്');
  String get calculated => _t('Calculated', 'കണക്കാക്കിയത്');
  String get displayMode => _t('Mosque display', 'പള്ളി ഡിസ്‌പ്ലേ');
  String get chooseYourPlace => _t(
    'Choose your place for accurate times',
    'കൃത്യമായ സമയത്തിന് സ്ഥലം തിരഞ്ഞെടുക്കുക',
  );
  String get choose => _t('Choose', 'തിരഞ്ഞെടുക്കുക');

  // Alerts health.
  String get alertsNeedAttention =>
      _t('Alerts may be missed', 'അലേർട്ടുകൾ നഷ്ടപ്പെടാം');
  String get allowNotifications =>
      _t('Allow notifications', 'നോട്ടിഫിക്കേഷൻ അനുവദിക്കുക');
  String get allowExactAlarms =>
      _t('Allow exact alarms (on time Azan)', 'കൃത്യ സമയ അലാറം അനുവദിക്കുക');
  String get disableBatteryOptimisation => _t(
    'Turn off battery optimisation for Azan Time',
    'ബാങ്ക് സമയം ആപ്പിന് ബാറ്ററി ഒപ്റ്റിമൈസേഷൻ ഓഫാക്കുക',
  );
  String get batteryHelp => _t(
    'Some phones (Xiaomi, Oppo, Vivo, Realme, Samsung) stop apps in the '
        'background. Set Azan Time to "Unrestricted" / "No restrictions" in '
        'battery settings so Azan is never missed.',
    'ചില ഫോണുകൾ (Xiaomi, Oppo, Vivo, Realme, Samsung) പശ്ചാത്തലത്തിലുള്ള '
        'ആപ്പുകൾ നിർത്തുന്നു. ബാങ്ക് നഷ്ടപ്പെടാതിരിക്കാൻ ബാറ്ററി '
        'ക്രമീകരണത്തിൽ ബാങ്ക് സമയം ആപ്പിനെ "Unrestricted" ആക്കുക.',
  );
  String get fix => _t('Fix', 'ശരിയാക്കുക');

  // Month.
  String get date => _t('Date', 'തീയതി');

  // Qibla.
  String qiblaBearing(String deg) =>
      _f('Qibla is {0}° from North', 'ഖിബ്‌ല വടക്ക് നിന്ന് {0}°', [deg]);
  String distanceToKaaba(String km) =>
      _f('{0} km to the Kaaba', 'കഅ്ബയിലേക്ക് {0} കി.മീ', [km]);
  String get qiblaHelp => _t(
    'Hold the phone flat, away from metal and magnets. If the needle '
        'drifts, move the phone in a figure-8 to calibrate.',
    'ഫോൺ നിരപ്പായി പിടിക്കുക, ലോഹങ്ങളിൽ നിന്നും കാന്തങ്ങളിൽ നിന്നും '
        'അകറ്റി. സൂചി ശരിയല്ലെങ്കിൽ ഫോൺ 8 ആകൃതിയിൽ ചലിപ്പിക്കുക.',
  );
  String get facingQibla => _t('Facing the Qibla', 'ഖിബ്‌ലയിലേക്ക്');
  String get noCompass => _t(
    'No compass sensor on this phone. Use the bearing above with a '
        'separate compass.',
    'ഈ ഫോണിൽ കോമ്പസ് സെൻസർ ഇല്ല. മുകളിലെ ഡിഗ്രി മറ്റൊരു '
        'കോമ്പസ് ഉപയോഗിച്ച് നോക്കുക.',
  );

  // Settings.
  String get language => _t('Language', 'ഭാഷ');
  String get theme => _t('Theme', 'തീം');
  String get themeSystem => _t('System', 'സിസ്റ്റം');
  String get themeLight => _t('Light', 'ലൈറ്റ്');
  String get themeDark => _t('Dark', 'ഡാർക്ക്');
  String get use24h => _t('24-hour clock', '24 മണിക്കൂർ ക്ലോക്ക്');
  String get showExtras => _t(
    'Show Imsak, Ishraq and Tahajjud',
    'ഇംസാക്, ഇശ്റാഖ്, തഹജ്ജുദ് കാണിക്കുക',
  );
  String get location => _t('Location', 'സ്ഥലം');
  String get calculation => _t('Calculation', 'കണക്കുകൂട്ടൽ');
  String get method => _t('Method', 'രീതി');
  String get asrMethod => _t('Asr', 'അസ്ർ');
  String asrName(AsrMethod a) => switch (a) {
    AsrMethod.shafii => _t("Shafi'i (standard)", 'ശാഫിഈ'),
    AsrMethod.hanafi => _t('Hanafi', 'ഹനഫി'),
  };
  String get highLatitude => _t('High latitude rule', 'ഉയർന്ന അക്ഷാംശ നിയമം');
  String highLatName(HighLatitudeRule r) => switch (r) {
    HighLatitudeRule.none => _t('None', 'ഇല്ല'),
    HighLatitudeRule.middleOfNight => _t(
      'Middle of the night',
      'രാത്രിയുടെ പകുതി',
    ),
    HighLatitudeRule.seventhOfNight => _t(
      'One seventh of the night',
      'രാത്രിയുടെ ഏഴിലൊന്ന്',
    ),
    HighLatitudeRule.angleBased => _t(
      'Angle based (recommended)',
      'കോണ്‍ അടിസ്ഥാനം',
    ),
  };
  String get adjustments =>
      _t('Adjust times (minutes)', 'സമയം ക്രമീകരിക്കുക (മിനിറ്റ്)');
  String get adjustmentsHelp => _t(
    'Match your mosque: add or subtract minutes for each time.',
    'നിങ്ങളുടെ പള്ളിയിലെ സമയവുമായി ഒത്തുപോകാൻ ഓരോ സമയത്തിനും മിനിറ്റ് കൂട്ടുകയോ കുറയ്ക്കുകയോ ചെയ്യുക.',
  );
  String get imsakBeforeFajr =>
      _t('Imsak before Fajr', 'സുബ്ഹിന് മുമ്പ് ഇംസാക്');
  String get ishraqAfterSunrise =>
      _t('Ishraq after sunrise', 'ഉദയത്തിന് ശേഷം ഇശ്റാഖ്');
  String get hijriAdjust => _t('Hijri date correction', 'ഹിജ്റ തീയതി തിരുത്തൽ');
  String get hijriAdjustHelp => _t(
    'Kerala follows moon sighting. If the Hijri date is a day off, '
        'correct it here.',
    'കേരളം ചന്ദ്രദർശനം പിന്തുടരുന്നു. ഹിജ്റ തീയതിയിൽ ഒരു ദിവസത്തെ '
        'വ്യത്യാസമുണ്ടെങ്കിൽ ഇവിടെ തിരുത്തുക.',
  );
  String days(int n) => n.abs() == 1
      ? _f('{0} day', '{0} ദിവസം', [n])
      : _f('{0} days', '{0} ദിവസം', [n]);
  String get timetable => _t('Timetable', 'ടൈംടേബിൾ');
  String get alerts => _t('Azan & Iqama alerts', 'ബാങ്ക്, ഇഖാമത്ത് അലേർട്ടുകൾ');
  String get about => _t('About', 'വിവരങ്ങൾ');
  String get privacyNote => _t(
    'Azan Time works offline. It has no ads, no tracking and no internet '
        'permission. Your location never leaves the phone.',
    'ബാങ്ക് സമയം ഓഫ്‌ലൈനായി പ്രവർത്തിക്കുന്നു. പരസ്യങ്ങളോ ട്രാക്കിംഗോ '
        'ഇന്റർനെറ്റ് അനുമതിയോ ഇല്ല. നിങ്ങളുടെ സ്ഥലം ഫോണിന് പുറത്ത് പോകുന്നില്ല.',
  );
  String get reset => _t('Reset', 'പുനഃസജ്ജമാക്കുക');
  String get cancel => _t('Cancel', 'റദ്ദാക്കുക');
  String get ok => _t('OK', 'ശരി');
  String get save => _t('Save', 'സേവ്');

  // Place screen.
  String get searchPlaces => _t('Search places', 'സ്ഥലം തിരയുക');
  String get useMyLocation => _t('Use my location (GPS)', 'എന്റെ സ്ഥലം (GPS)');
  String get enterCoordinates =>
      _t('Enter coordinates', 'അക്ഷാംശ രേഖാംശം നൽകുക');
  String get myLocation => _t('My location', 'എന്റെ സ്ഥലം');
  String get placeName => _t('Name', 'പേര്');
  String get latitude => _t('Latitude', 'അക്ഷാംശം');
  String get longitude => _t('Longitude', 'രേഖാംശം');
  String get utcOffsetOptional => _t(
    'UTC offset, e.g. +05:30 (empty = phone time zone)',
    'UTC ഓഫ്സെറ്റ്, ഉദാ. +05:30 (ശൂന്യം = ഫോണിന്റെ സമയമേഖല)',
  );
  String get locating => _t('Finding your location…', 'സ്ഥലം കണ്ടെത്തുന്നു…');
  String get locationDenied =>
      _t('Location permission denied.', 'സ്ഥല അനുമതി നിഷേധിച്ചു.');
  String get locationDisabled => _t(
    'Location is turned off. Turn it on and try again.',
    'ലൊക്കേഷൻ ഓഫാണ്. ഓണാക്കി വീണ്ടും ശ്രമിക്കുക.',
  );
  String get locationUnavailable => _t(
    'Could not get a location. Try again outdoors, or pick a place.',
    'സ്ഥലം ലഭിച്ചില്ല. പുറത്ത് ചെന്ന് ശ്രമിക്കുക, അല്ലെങ്കിൽ ഒരു സ്ഥലം തിരഞ്ഞെടുക്കുക.',
  );
  String get invalidCoordinates =>
      _t('Enter valid coordinates.', 'ശരിയായ അക്ഷാംശ രേഖാംശം നൽകുക.');

  // Alerts screen.
  String get azanAlert => _t('Azan alert', 'ബാങ്ക് അലേർട്ട്');
  String get iqamaAlert => _t('Iqama alert', 'ഇഖാമത്ത് അലേർട്ട്');
  String get fixedIqama => _t('Fixed Iqama time', 'നിശ്ചിത ഇഖാമത്ത് സമയം');
  String get jumuahFixedIqama =>
      _t("Fixed Jumu'ah Iqama time", 'നിശ്ചിത ജുമുഅ ഇഖാമത്ത് സമയം');
  String get fixedIqamaOff => _t(
    'Off: uses the minutes after Azan',
    'ഓഫ്: ബാങ്കിന് ശേഷമുള്ള മിനിറ്റ് ഉപയോഗിക്കുന്നു',
  );
  String get fixedIqamaHelp => _t(
    'Used when it is after Azan; otherwise the minutes after Azan',
    'ബാങ്കിന് ശേഷമാണെങ്കിൽ ഉപയോഗിക്കും; അല്ലെങ്കിൽ ബാങ്കിന് ശേഷമുള്ള മിനിറ്റ്',
  );
  String get clear => _t('Clear', 'മായ്ക്കുക');
  String get iqamaAfterAzan => _t('Iqama after Azan', 'ബാങ്കിന് ശേഷം ഇഖാമത്ത്');
  String get reminderBefore =>
      _t('Reminder before Azan', 'ബാങ്കിന് മുമ്പ് ഓർമ്മപ്പെടുത്തൽ');
  String get off => _t('Off', 'ഓഫ്');
  String get jumuahIqama =>
      _t("Jumu'ah Iqama after Azan", 'ജുമുഅ: ബാങ്കിന് ശേഷം ഇഖാമത്ത്');
  String get imsakAlert => _t(
    'Imsak alert (Suhoor ends)',
    'ഇംസാക് അലേർട്ട് (അത്താഴം അവസാനിക്കുന്നു)',
  );
  String get tahajjudAlert => _t('Tahajjud alert', 'തഹജ്ജുദ് അലേർട്ട്');
  String get autoSilent =>
      _t('Auto silent during prayer', 'നിസ്കാര സമയത്ത് ഓട്ടോ സൈലന്റ്');
  String get autoSilentHelp => _t(
    'Quietens the phone from Azan until the time below after Iqama, then '
        'restores it.',
    'ബാങ്ക് മുതൽ ഇഖാമത്തിന് ശേഷം താഴെ കൊടുത്ത സമയം വരെ ഫോൺ നിശബ്ദമാക്കുന്നു, '
        'ശേഷം പഴയപടിയാക്കുന്നു.',
  );
  String get silentMode => _t('Mode', 'മോഡ്');
  String silentModeName(SilentMode m) => switch (m) {
    SilentMode.vibrate => _t('Vibrate', 'വൈബ്രേറ്റ്'),
    SilentMode.silent => _t('Silent (Do Not Disturb)', 'സൈലന്റ് (DND)'),
  };
  String get silentAfterIqama =>
      _t('Stay quiet after Iqama', 'ഇഖാമത്തിന് ശേഷം നിശബ്ദം');
  String get jumuahSilent =>
      _t("Stay quiet after Jumu'ah Iqama", 'ജുമുഅ ഇഖാമത്തിന് ശേഷം നിശബ്ദം');
  String get dndAccessNeeded => _t(
    'Silent mode needs "Do Not Disturb" access. Without it, Azan Time uses '
        'vibrate.',
    'സൈലന്റ് മോഡിന് "Do Not Disturb" അനുമതി വേണം. ഇല്ലെങ്കിൽ വൈബ്രേറ്റ് ഉപയോഗിക്കും.',
  );
  String get grant => _t('Grant', 'അനുവദിക്കുക');
  String get testAlert =>
      _t('Send a test alert', 'ടെസ്റ്റ് അലേർട്ട് അയയ്ക്കുക');
  String get alertsScheduledNote => _t(
    'Alerts are scheduled for the next 20 days. Opening Azan Time now and then '
        'keeps them going.',
    'അടുത്ത 20 ദിവസത്തേക്ക് അലേർട്ടുകൾ ക്രമീകരിച്ചിരിക്കുന്നു. '
        'ഇടയ്ക്കിടെ ബാങ്ക് സമയം തുറന്നാൽ തുടർന്നുകൊണ്ടിരിക്കും.',
  );

  // Notifications.
  String azanTitle(Prayer p, bool friday) =>
      _f('{0} – Azan time', '{0} ബാങ്കിന്റെ സമയം', [prayer(p, friday: friday)]);
  String iqamaTitle(Prayer p, bool friday) =>
      _f('{0} – Iqama', '{0} ഇഖാമത്ത്', [prayer(p, friday: friday)]);
  String reminderTitle(Prayer p, bool friday, int minutes) => _f(
    '{0} in {1} min',
    '{1} മിനിറ്റിന് ശേഷം {0}',
    [prayer(p, friday: friday), minutes],
  );
  String extraTitle(Prayer p) => switch (p) {
    Prayer.imsak => _t(
      'Imsak – Suhoor ends',
      'ഇംസാക് – അത്താഴ സമയം അവസാനിച്ചു',
    ),
    _ => _f('{0} time', '{0} സമയം', [prayer(p)]),
  };
  String get keepAlertsTitle => _t(
    'Open Azan Time to keep alerts on',
    'അലേർട്ടുകൾ തുടരാൻ ബാങ്ക് സമയം തുറക്കുക',
  );
  String get keepAlertsBody => _t(
    'Scheduled alerts end in a day. Tap to schedule the next days.',
    'ക്രമീകരിച്ച അലേർട്ടുകൾ ഒരു ദിവസത്തിനകം അവസാനിക്കും. തുടരാൻ ടാപ്പ് ചെയ്യുക.',
  );
  String get channelAzan => _t('Azan', 'ബാങ്ക്');
  String get channelIqama => _t('Iqama', 'ഇഖാമത്ത്');
  String get channelReminder => _t('Reminders', 'ഓർമ്മപ്പെടുത്തലുകൾ');

  // Timetable screen.
  String get timetableHelp => _t(
    'For times that match your mosque exactly, import its yearly chart '
        '(for example a Samastha calendar) as a CSV file. Dates the table '
        'does not cover are calculated.',
    'പള്ളിയിലെ സമയവുമായി കൃത്യമായി ഒത്തുപോകാൻ, അതിന്റെ വാർഷിക സമയപ്പട്ടിക '
        '(ഉദാ. സമസ്ത കലണ്ടർ) CSV ഫയലായി ഇറക്കുമതി ചെയ്യുക. പട്ടികയിൽ '
        'ഇല്ലാത്ത തീയതികൾ കണക്കാക്കും.',
  );
  String get importCsv => _t('Import CSV file', 'CSV ഫയൽ ഇറക്കുമതി ചെയ്യുക');
  String get pasteCsv =>
      _t('Paste CSV text', 'CSV ടെക്സ്റ്റ് പേസ്റ്റ് ചെയ്യുക');
  String get removeTimetable => _t('Remove timetable', 'ടൈംടേബിൾ നീക്കുക');
  String get useTimetable => _t('Use timetable', 'ടൈംടേബിൾ ഉപയോഗിക്കുക');
  String get noTimetable => _t('No timetable imported.', 'ടൈംടേബിൾ ഇല്ല.');
  String timetableInfo(int days, String offset) => _f(
    '{0} days of the year · UTC {1}',
    'വർഷത്തിലെ {0} ദിവസം · UTC {1}',
    [days, offset],
  );
  String get csvFormat => _t('CSV format', 'CSV ഫോർമാറ്റ്');
  String importError(String e) =>
      _f('Could not import: {0}', 'ഇറക്കുമതി പരാജയപ്പെട്ടു: {0}', [e]);
  String get imported => _t('Timetable imported', 'ടൈംടേബിൾ ഇറക്കുമതി ചെയ്തു');
  String get exportCalculated =>
      _t('Copy calculated year as CSV', 'കണക്കാക്കിയ വർഷം CSV ആയി പകർത്തുക');
  String get copied => _t('Copied', 'പകർത്തി');

  // Home-screen widget.
  String get widgetCountdown => _t('in %s', '%s കഴിഞ്ഞ്');
  String get widgetStale =>
      _t('Open Azan Time to refresh', 'പുതുക്കാൻ ബാങ്ക് സമയം തുറക്കുക');

  // Display mode.
  String get exitDisplay =>
      _t('Tap and hold to exit', 'പുറത്തുകടക്കാൻ അമർത്തിപ്പിടിക്കുക');

  /// Seconds unit in countdowns.
  String get secondsShort => _t('s', 'സെ');

  // World places.
  String nearPlace(String p) => _f('near {0}', '{0} സമീപം', [p]);
  String get worldPlaces => _t('World places', 'ലോകത്തിലെ സ്ഥലങ്ങൾ');
  String get searchWorldHint => _t(
    'Type a town or city name to search 35,000 places worldwide.',
    'ലോകമെമ്പാടുമുള്ള 35,000 സ്ഥലങ്ങളിൽ തിരയാൻ പട്ടണത്തിന്റെ പേര് ടൈപ്പ് ചെയ്യുക.',
  );
  String get geonamesCredit => _t(
    'Place data: GeoNames (CC BY 4.0)',
    'സ്ഥല വിവരങ്ങൾ: GeoNames (CC BY 4.0)',
  );

  // Azan sound.
  String get azanSoundTitle => _t('Azan sound', 'ബാങ്ക് ശബ്ദം');
  String get fajrSoundTitle => _t('Fajr Azan sound', 'സുബ്ഹ് ബാങ്ക് ശബ്ദം');
  String get sameAsOthers =>
      _t('Same as other prayers', 'മറ്റു നിസ്കാരങ്ങളുടേത് തന്നെ');
  String soundKindName(AzanSound k) => switch (k) {
    AzanSound.system => _t(
      'Phone notification sound',
      'ഫോണിലെ അറിയിപ്പ് ശബ്ദം',
    ),
    AzanSound.chime => _t('Soft chime', 'മൃദുവായ മണിനാദം'),
    AzanSound.bell => _t('Deep bell', 'ഗംഭീര മണി'),
    AzanSound.custom => _t(
      'Audio file (e.g. Azan MP3)',
      'ഓഡിയോ ഫയൽ (ഉദാ. ബാങ്ക് MP3)',
    ),
  };
  String soundName(SoundChoice c) =>
      c.sound == AzanSound.custom && c.fileName != null
      ? c.fileName!
      : soundKindName(c.sound);
  String get systemSoundHelp =>
      _t('Repeats until you dismiss it', 'നിർത്തുന്നത് വരെ ആവർത്തിക്കും');
  String get customSoundHelp => _t(
    'Pick a recorded Azan saved on your phone',
    'ഫോണിൽ സേവ് ചെയ്ത ബാങ്ക് റെക്കോർഡിംഗ് തിരഞ്ഞെടുക്കുക',
  );
  String get soundError =>
      _t('Could not use this audio file', 'ഈ ഓഡിയോ ഫയൽ ഉപയോഗിക്കാനായില്ല');
  String get playSound => _t('Play', 'പ്ലേ ചെയ്യുക');
  String get stop => _t('Stop', 'നിർത്തുക');
  String get vibrate => _t('Vibrate', 'വൈബ്രേറ്റ്');
  String get playWhenSilent => _t(
    'Play even when the phone is silent',
    'ഫോൺ സൈലന്റിലാണെങ്കിലും പ്ലേ ചെയ്യുക',
  );
  String get playWhenSilentHelp => _t(
    'Off: on silent or vibrate the Azan only shows and vibrates.',
    'ഓഫ്: സൈലന്റ്/വൈബ്രേറ്റിൽ ബാങ്ക് കാണിക്കുകയും വൈബ്രേറ്റ് ചെയ്യുകയും മാത്രം.',
  );

  // Taraweeh and Eid.
  String get specialOccasions => _t('Ramadan and Eid', 'റമളാനും പെരുന്നാളും');
  String specialTitle(SpecialEvent e) => switch (e) {
    SpecialEvent.taraweeh => _t('Taraweeh', 'തറാവീഹ്'),
    SpecialEvent.eidAlFitr => _t(
      'Eid al-Fitr prayer',
      'ചെറിയ പെരുന്നാൾ നിസ്കാരം',
    ),
    SpecialEvent.eidAlAdha => _t(
      'Eid al-Adha prayer',
      'ബലി പെരുന്നാൾ നിസ്കാരം',
    ),
  };
  String get taraweehHelp => _t(
    'Alert on Ramadan nights after the Isha Iqama',
    'റമളാൻ രാത്രികളിൽ ഇശാ ഇഖാമത്തിന് ശേഷം അറിയിപ്പ്',
  );
  String get taraweehAfterIsha =>
      _t('Minutes after Isha Iqama', 'ഇശാ ഇഖാമത്തിന് ശേഷം മിനിറ്റ്');
  String get eidAlert => _t('Eid prayer alert', 'പെരുന്നാൾ നിസ്കാര അറിയിപ്പ്');
  String get eidHelp => _t(
    'Reminds you 30 minutes before the Eid prayer (by the Hijri date)',
    'പെരുന്നാൾ നിസ്കാരത്തിന് 30 മിനിറ്റ് മുമ്പ് ഓർമിപ്പിക്കും (ഹിജ്റ തീയതി പ്രകാരം)',
  );
  String eidPrayerAt(String t) =>
      _f('Eid prayer at {0}', 'പെരുന്നാൾ നിസ്കാരം {0}-ന്', [t]);

  // Mosque display pages.
  String displayPagesSummary(int n) => n == 1
      ? _t('1 page', '1 പേജ്')
      : _f('{0} pages, rotating', '{0} പേജുകൾ, മാറിമാറി', [n]);
  String get openDisplay => _t('Open the display', 'ഡിസ്‌പ്ലേ തുറക്കുക');
  String get mosqueName => _t('Mosque name', 'പള്ളിയുടെ പേര്');
  String get mosqueNameHint =>
      _t('Shown at the top of the display', 'ഡിസ്‌പ്ലേയുടെ മുകളിൽ കാണിക്കും');
  String get nextPrayerPage => _t('Next prayer page', 'അടുത്ത നിസ്കാരം പേജ്');
  String get nextPrayerPageHelp => _t(
    'Big countdown; stays on from 5 minutes before Azan until Iqama',
    'വലിയ കൗണ്ട്ഡൗൺ; ബാങ്കിന് 5 മിനിറ്റ് മുമ്പ് മുതൽ ഇഖാമത്ത് വരെ ഇത് തന്നെ',
  );
  String get secondsPerPage => _t('Seconds per page', 'ഓരോ പേജിനും സെക്കൻഡ്');
  String get announcements => _t('Announcements', 'അറിയിപ്പുകൾ');
  String get addAnnouncement => _t('Add announcement', 'അറിയിപ്പ് ചേർക്കുക');
  String get announcementHint => _t(
    'e.g. "Please switch off your phones"',
    'ഉദാ. "ദയവായി ഫോൺ ഓഫ് ചെയ്യുക"',
  );
  String get delete => _t('Delete', 'നീക്കം ചെയ്യുക');
  String get displayPagesHelp => _t(
    'The display shows up to 7 pages: prayer times, the next prayer and 5 '
        'announcements. Tap and hold the display to exit.',
    'ഡിസ്‌പ്ലേയിൽ 7 പേജുകൾ വരെ: നിസ്കാര സമയങ്ങൾ, അടുത്ത നിസ്കാരം, 5 '
        'അറിയിപ്പുകൾ. പുറത്തുകടക്കാൻ ഡിസ്‌പ്ലേ അമർത്തിപ്പിടിക്കുക.',
  );

  // Full-screen Azan.
  String get fullScreenAzan => _t('Full-screen Azan', 'ഫുൾ സ്ക്രീൻ ബാങ്ക്');
  String get fullScreenAzanHelp => _t(
    'Shows the Azan over the lock screen with a big Stop button',
    'ലോക്ക് സ്ക്രീനിന് മുകളിൽ വലിയ നിർത്തൽ ബട്ടണോടെ ബാങ്ക് കാണിക്കും',
  );
  String get fullScreenPermission => _t(
    'Allow full-screen alerts for Azan Time',
    'ബാങ്ക് സമയം ആപ്പിന് ഫുൾ സ്ക്രീൻ അറിയിപ്പുകൾ അനുവദിക്കുക',
  );

  // Prayer tracker.
  String get tracker => _t('Prayer tracker', 'നിസ്കാര ട്രാക്കർ');
  String prayedOf(int n, int of) =>
      _f('{0} of {1} prayed today', 'ഇന്ന് {1}-ൽ {0} നിസ്കരിച്ചു', [n, of]);
  String streakDays(int n) =>
      _f('{0}-day streak', 'തുടർച്ചയായി {0} ദിവസം', [n]);
  String get tapToMarkPrayed => _t(
    "Tap a prayer's icon to mark it as prayed",
    'നിസ്കരിച്ചതായി അടയാളപ്പെടുത്താൻ ഐക്കണിൽ തൊടുക',
  );
  String get markPrayed =>
      _t('Mark as prayed', 'നിസ്കരിച്ചതായി അടയാളപ്പെടുത്തുക');
  String get streak => _t('Day streak', 'തുടർച്ച (ദിവസം)');
  String get last7Days => _t('Last 7 days', 'കഴിഞ്ഞ 7 ദിവസം');
  String get last30Days => _t('Last 30 days', 'കഴിഞ്ഞ 30 ദിവസം');
  String get week => _t('Week', 'ആഴ്ച');
  String get previousWeek => _t('Previous week', 'മുൻ ആഴ്ച');
  String get nextWeek => _t('Next week', 'അടുത്ത ആഴ്ച');
  String get excusedToday => _t('Excused today', 'ഇന്ന് ഒഴിവ്');
  String get excusedHelp => _t(
    'Pause the tracker for the day (e.g. illness or menstruation); your '
        'streak is kept.',
    'ഈ ദിവസം ട്രാക്കർ നിർത്തിവെക്കുക (ഉദാ. അസുഖം, ആർത്തവം); തുടർച്ച നഷ്ടപ്പെടില്ല.',
  );
  String get trackerPrivacy => _t(
    'Your tracker stays on this phone only.',
    'നിങ്ങളുടെ ട്രാക്കർ ഈ ഫോണിൽ മാത്രം സൂക്ഷിക്കുന്നു.',
  );

  // Tasbih.
  String get tasbih => _t('Tasbih', 'തസ്ബീഹ്');
  String get afterPrayerSet =>
      _t('After-prayer tasbih', 'നിസ്കാര ശേഷമുള്ള തസ്ബീഹ്');
  String get freeCount => _t('Free count', 'സ്വതന്ത്ര എണ്ണൽ');
  String dhikrMeaning(String id) => switch (id) {
    'subhanallah' => _t('Glory be to Allah', 'അല്ലാഹു പരിശുദ്ധനാണ്'),
    'alhamdulillah' => _t(
      'All praise is for Allah',
      'എല്ലാ സ്തുതിയും അല്ലാഹുവിനാണ്',
    ),
    'allahuakbar' => _t('Allah is the Greatest', 'അല്ലാഹു ഏറ്റവും വലിയവനാണ്'),
    'tahlil' => _t('There is no god but Allah', 'അല്ലാഹു അല്ലാതെ ആരാധ്യനില്ല'),
    'istighfar' => _t(
      "I seek Allah's forgiveness",
      'ഞാൻ അല്ലാഹുവിനോട് പാപമോചനം തേടുന്നു',
    ),
    'salawat' => _t(
      'O Allah, send blessings upon Muhammad',
      'അല്ലാഹുവേ, മുഹമ്മദ് നബിയുടെ മേൽ അനുഗ്രഹം ചൊരിയേണമേ',
    ),
    'subhanallahi_wabihamdihi' => _t(
      'Glory and praise be to Allah',
      'അല്ലാഹുവിന് പരിശുദ്ധിയും സ്തുതിയും',
    ),
    _ => '',
  };
  String get resetCounter =>
      _t('Reset the counter?', 'കൗണ്ടർ പുനഃസജ്ജമാക്കണോ?');
  String get tasbihTap =>
      _t('Tap the circle to count', 'എണ്ണാൻ വൃത്തത്തിൽ തൊടുക');
  String get rounds => _t('Rounds', 'റൗണ്ടുകൾ');
  String get todayTotal => _t('Today in total', 'ഇന്ന് ആകെ');

  // Islamic occasions.
  String eventName(IslamicEvent e) => switch (e) {
    IslamicEvent.newYear => _t('Islamic New Year', 'ഹിജ്റ പുതുവർഷം'),
    IslamicEvent.ashura => _t('Ashura', 'ആശൂറാഅ്'),
    IslamicEvent.mawlid => _t('Mawlid an-Nabi', 'നബിദിനം'),
    IslamicEvent.israMiraj => _t("Isra and Mi'raj", 'ഇസ്‌റാഉം മിഅ്റാജും'),
    IslamicEvent.midShaban => _t("Mid-Sha'ban", 'ബറാഅത്ത് രാവ്'),
    IslamicEvent.ramadanStart => _t('Ramadan begins', 'റമളാൻ ആരംഭം'),
    IslamicEvent.laylatAlQadr => _t(
      'Laylat al-Qadr (27th)',
      'ലൈലത്തുൽ ഖദ്ർ (27-ാം രാവ്)',
    ),
    IslamicEvent.eidAlFitr => _t('Eid al-Fitr', 'ചെറിയ പെരുന്നാൾ'),
    IslamicEvent.arafah => _t('Day of Arafah', 'അറഫാ ദിനം'),
    IslamicEvent.eidAlAdha => _t('Eid al-Adha', 'ബലി പെരുന്നാൾ'),
  };
  String get upcoming => _t('Upcoming', 'വരാനിരിക്കുന്നവ');
  String daysLeft(int n) => switch (n) {
    0 => _t('Today', 'ഇന്ന്'),
    1 => _t('Tomorrow', 'നാളെ'),
    _ => _f('in {0} days', '{0} ദിവസം കഴിഞ്ഞ്', [n]),
  };
  String get hijriEstimateNote => _t(
    'Dates follow the calculated Hijri calendar; the moon sighting may '
        'move them by a day (correct it in Settings).',
    'തീയതികൾ കണക്കാക്കിയ ഹിജ്റ കലണ്ടർ പ്രകാരം; ചന്ദ്രദർശനം അനുസരിച്ച് ഒരു '
        'ദിവസം മാറാം (സെറ്റിംഗ്സിൽ തിരുത്താം).',
  );

  // Ramadan.
  String get suhoorEnds => _t('Suhoor ends', 'അത്താഴം അവസാനം');
  String get iftar => _t('Iftar', 'നോമ്പ് തുറ');

  // First-run setup.
  String get back => _t('Back', 'തിരികെ');
  String get continueLabel => _t('Continue', 'തുടരുക');
  String get start => _t('Start', 'തുടങ്ങാം');
  String get welcomeTitle => _t('Assalamu alaikum!', 'അസ്സലാമു അലൈക്കും!');
  String get welcomeBody => _t(
    'Accurate prayer times, Azan and Iqama alerts, Qibla and more. No ads, '
        'no tracking, works offline. Choose your language:',
    'കൃത്യമായ നിസ്കാര സമയങ്ങൾ, ബാങ്ക്-ഇഖാമത്ത് അറിയിപ്പുകൾ, ഖിബ്‌ല എന്നിവയും '
        'മറ്റും. പരസ്യമില്ല, ട്രാക്കിംഗില്ല, ഇന്റർനെറ്റ് വേണ്ട. ഭാഷ തിരഞ്ഞെടുക്കുക:',
  );
  String get whereAreYou =>
      _t('Where do you pray?', 'നിങ്ങൾ എവിടെ നിസ്കരിക്കുന്നു?');
  String get whereAreYouHelp => _t(
    'Times depend on your place. Use GPS or search your town; the usual '
        'calculation method is set for you.',
    'സമയം സ്ഥലം അനുസരിച്ചാണ്. GPS ഉപയോഗിക്കുക അല്ലെങ്കിൽ പട്ടണം തിരയുക; '
        'സാധാരണ കണക്കുകൂട്ടൽ രീതി സ്വയം സജ്ജമാകും.',
  );
  String get choosePlace => _t('Choose your place', 'സ്ഥലം തിരഞ്ഞെടുക്കുക');
  String get changePlace => _t('Change place', 'സ്ഥലം മാറ്റുക');
  String get neverMissTitle =>
      _t('Never miss a prayer', 'ഒരു നിസ്കാരവും നഷ്ടപ്പെടരുത്');
  String get neverMissBody => _t(
    'Allow notifications and exact alarms so the Azan comes on time, even '
        'when the phone is asleep.',
    'ഫോൺ ഉറങ്ങുമ്പോഴും ബാങ്ക് കൃത്യസമയത്ത് വരാൻ അറിയിപ്പുകളും കൃത്യ '
        'അലാറങ്ങളും അനുവദിക്കുക.',
  );
  String get allowAlerts => _t('Allow alerts', 'അറിയിപ്പുകൾ അനുവദിക്കുക');
  String get moreInAlerts => _t(
    'You can pick an Azan recording, Iqama times and more later in '
        'Settings › Azan & Iqama alerts.',
    'ബാങ്ക് റെക്കോർഡിംഗ്, ഇഖാമത്ത് സമയങ്ങൾ തുടങ്ങിയവ പിന്നീട് സെറ്റിംഗ്സിൽ '
        'തിരഞ്ഞെടുക്കാം.',
  );

  // Automatic location and the phone's clock.
  String get autoLocation =>
      _t('Update location automatically', 'സ്ഥലം സ്വയം പുതുക്കുക');
  String get autoLocationHelp => _t(
    'When you open Azan Time, the place follows your phone (GPS), with the local '
        'time zone.',
    'ബാങ്ക് സമയം തുറക്കുമ്പോൾ സ്ഥലവും പ്രാദേശിക സമയമേഖലയും ഫോണിന്റെ GPS അനുസരിച്ച് മാറും.',
  );
  String locationUpdated(String p) =>
      _f('Location updated: {0}', 'സ്ഥലം പുതുക്കി: {0}', [p]);
  String get clockNotAuto => _t(
    'Set the phone\'s date & time to automatic',
    'ഫോണിലെ തീയതിയും സമയവും ഓട്ടോമാറ്റിക് ആക്കുക',
  );
  String clockOff(int minutes) => _f(
    'Your phone\'s clock is {0} min off',
    'ഫോണിലെ ക്ലോക്ക് {0} മിനിറ്റ് തെറ്റാണ്',
    [minutes],
  );
  String get clockHelp => _t(
    'Alerts follow the phone\'s clock; a wrong clock or time zone makes '
        'every time wrong.',
    'അറിയിപ്പുകൾ ഫോണിലെ ക്ലോക്ക് അനുസരിച്ചാണ്; ക്ലോക്കോ സമയമേഖലയോ തെറ്റിയാൽ '
        'എല്ലാ സമയവും തെറ്റും.',
  );

  // Mosque profiles.
  String get masjids => _t('Mosques', 'പള്ളികൾ');
  String get masjidsHelp => _t(
    'Save the Iqama times of each mosque you pray at and switch between '
        'them on the Today screen.',
    'നിങ്ങൾ നിസ്കരിക്കുന്ന ഓരോ പള്ളിയുടെയും ഇഖാമത്ത് സമയങ്ങൾ സേവ് ചെയ്ത് '
        'ഇന്ന് സ്ക്രീനിൽ മാറ്റുക.',
  );
  String masjidN(int n) => _f('Masjid {0}', 'പള്ളി {0}', [n]);
  String masjidCount(int n) => _f('{0} saved', '{0} എണ്ണം', [n]);
  String get noDescription => _t('No description', 'വിവരണമില്ല');
  String get edit => _t('Edit', 'തിരുത്തുക');
  String get addMasjid => _t('Add mosque', 'പള്ളി ചേർക്കുക');
  String editIqamaOf(String name) =>
      _f('Iqama times of {0}', '{0} ഇഖാമത്ത് സമയങ്ങൾ', [name]);
  String get masjidName => _t('Name', 'പേര്');
  String get masjidDescription =>
      _t('Description (e.g. area)', 'വിവരണം (ഉദാ. സ്ഥലം)');

  // Browse places.
  String get browsePlaces => _t('Browse places', 'സ്ഥലങ്ങൾ തിരയുക');
  String get browsePlacesHelp =>
      _t('Country › State › Place', 'രാജ്യം › സംസ്ഥാനം › സ്ഥലം');
  String get country => _t('Country', 'രാജ്യം');
  String stateOf(String country) =>
      _f('{0}: choose state', '{0}: സംസ്ഥാനം തിരഞ്ഞെടുക്കുക', [country]);
  String get filter => _t('Filter', 'ഫിൽട്ടർ');
  String get bigCity => _t('City', 'നഗരം');

  // Permanent notification.
  String get channelNextPrayer => _t('Next prayer', 'അടുത്ത നിസ്കാരം');
  String statusNextAzan(String p, String t) =>
      _f('{0} Azan at {1}', '{0} ബാങ്ക് {1}-ന്', [p, t]);
  String statusNextIqama(String p, String t) =>
      _f('{0} Iqama at {1}', '{0} ഇഖാമത്ത് {1}-ന്', [p, t]);
  String get statusNotification => _t(
    'Next prayer in notification bar',
    'അടുത്ത നിസ്കാരം നോട്ടിഫിക്കേഷൻ ബാറിൽ',
  );
  String get statusNotificationHelp => _t(
    'A permanent notification with the next Azan (with countdown) and Iqama',
    'അടുത്ത ബാങ്കും (കൗണ്ട്ഡൗണോടെ) ഇഖാമത്തും കാണിക്കുന്ന സ്ഥിര നോട്ടിഫിക്കേഷൻ',
  );

  // Display extras.
  String iqamaWasAt(String p, String t) =>
      _f('{0} Iqama was at {1}', '{0} ഇഖാമത്ത് {1}-ന് ആയിരുന്നു', [p, t]);
  String get keepScreenOn => _t(
    'Keep the screen on until I stop',
    'നിർത്തുന്നത് വരെ സ്ക്രീൻ ഓണാക്കി വെക്കുക',
  );
  String get keepScreenOnHelp => _t(
    'Off: the phone\'s screen timeout applies. The display also works on '
        'the lock screen: open it, then press the power button twice.',
    'ഓഫ്: ഫോണിലെ സ്ക്രീൻ ടൈംഔട്ട് ബാധകം. ലോക്ക് സ്ക്രീനിലും ഡിസ്‌പ്ലേ '
        'പ്രവർത്തിക്കും: തുറന്ന ശേഷം പവർ ബട്ടൺ രണ്ടുതവണ അമർത്തുക.',
  );

  String get adjustThisTime =>
      _t('Adjust this time (± minutes)', 'ഈ സമയം ക്രമീകരിക്കുക (± മിനിറ്റ്)');

  // Features of the original app: extra alerts, reminders, volumes.
  String get sunriseAlert => _t(
    'Sunrise alert (Fajr time ends)',
    'ഉദയ അലേർട്ട് (സുബ്ഹ് സമയം അവസാനിക്കുന്നു)',
  );
  String sunriseSoon(int minutes) => _f(
    '{0} min to sunrise – Fajr time ends',
    'ഉദയത്തിന് {0} മിനിറ്റ് – സുബ്ഹ് സമയം അവസാനിക്കുന്നു',
    [minutes],
  );
  String get minutesBeforeSunrise =>
      _t('Minutes before sunrise', 'ഉദയത്തിന് എത്ര മിനിറ്റ് മുമ്പ്');
  String get ishraqAlert =>
      _t('Ishraq / Duha alert', 'ഇശ്റാഖ് / ളുഹാ അലേർട്ട്');
  String get iqamaSoundTitle => _t('Iqama sound', 'ഇഖാമത്ത് ശബ്ദം');
  String get iqamaSoundDefault =>
      _t('Short notification sound', 'ചെറിയ നോട്ടിഫിക്കേഷൻ ശബ്ദം');
  String get fullScreenIqama =>
      _t('Full screen for Iqama too', 'ഇഖാമത്തിനും ഫുൾ സ്ക്രീൻ');
  String get azanVolume => _t('Azan volume', 'ബാങ്ക് വോളിയം');
  String get iqamaVolume => _t('Iqama volume', 'ഇഖാമത്ത് വോളിയം');
  String get phoneVolume => _t('Phone alarm volume', 'ഫോണിന്റെ അലാറം വോളിയം');
  String get volumeHelp => _t(
    'Pressing a volume button stops the Azan.',
    'വോളിയം ബട്ടൺ അമർത്തിയാൽ ബാങ്ക് നിൽക്കും.',
  );
  String get silentFor => _t('Silence during', 'ഈ സമയങ്ങളിൽ സൈലന്റ്');
  String get niyyahReminder =>
      _t('Ramadan Niyyah reminder', 'റമളാൻ നിയ്യത്ത് ഓർമ്മപ്പെടുത്തൽ');
  String get niyyahReminderHelp => _t(
    "Every Ramadan night after Isha: did you make the intention for tomorrow's fast?",
    'റമളാനിലെ എല്ലാ രാത്രിയും ഇശാക്ക് ശേഷം: നാളത്തെ നോമ്പിന് നിയ്യത്ത് വെച്ചോ?',
  );
  String get niyyahTitle => _t(
    "Did you make the Niyyah for tomorrow's fast?",
    'നാളത്തെ നോമ്പിന് നിയ്യത്ത് വെച്ചോ?',
  );
  String get niyyahText => _t(
    "“I intend to keep tomorrow's obligatory fast of Ramadan for the sake of Allah.”",
    '“ഈ കൊല്ലത്തെ റമളാൻ മാസത്തിലെ ഫർളായ നാളത്തെ നോമ്പ് അല്ലാഹുവിന് വേണ്ടി നോറ്റുവീട്ടുവാൻ ഞാൻ കരുതി.”',
  );
  String get fridayReminder =>
      _t('Friday night reminder', 'വെള്ളിയാഴ്ച രാവ് ഓർമ്മപ്പെടുത്തൽ');
  String get fridayReminderHelp => _t(
    "Thursday after Maghrib: Salawat, Surah Al-Kahf and getting ready for Jumu'ah",
    'വ്യാഴാഴ്ച മഗ്‌രിബിന് ശേഷം: സ്വലാത്ത്, സൂറത്തുൽ കഹ്ഫ്, ജുമുഅക്ക് ഒരുങ്ങൽ',
  );
  String get fridayTitle =>
      _t('Tonight is Friday night', 'ഇന്ന് വെള്ളിയാഴ്ച രാവാണ്');
  String get fridayText => _t(
    "Send abundant Salawat upon the Prophet ﷺ. Read Surah Al-Kahf and get ready for Jumu'ah: bath, clean clothes, go early.",
    'നബി ﷺ യുടെ മേൽ ധാരാളം സ്വലാത്ത് ചൊല്ലുക. സൂറത്തുൽ കഹ്ഫ് ഓതുക, ജുമുഅക്ക് ഒരുങ്ങുക: കുളി, വൃത്തിയുള്ള വസ്ത്രം, നേരത്തെ പള്ളിയിലേക്ക്.',
  );
  String get iDidNiyyah => _t('I did', 'നിയ്യത്ത് വെച്ചു');
  String get remindLater =>
      _t('Remind me in 30 min', '30 മിനിറ്റ് കഴിഞ്ഞ് ഓർമ്മിപ്പിക്കുക');

  // Today as a chart.
  String get eidShort => _t('Eid', 'പെരുന്നാൾ');
  String get viewChart => _t('Chart', 'ചാർട്ട്');
  String get viewCards => _t('Cards', 'കാർഡുകൾ');

  // Location settings (like the original app's).
  String get locationSettings => _t('Location settings', 'സ്ഥല ക്രമീകരണം');
  String locationSettingsOf(String masjid) =>
      _f('{0}: place and time source', '{0}: സ്ഥലവും സമയ സ്രോതസ്സും', [masjid]);
  String get automaticGps => _t('Automatic (GPS)', 'ഓട്ടോമാറ്റിക് (GPS)');
  String get automaticHelp => _t(
    'Finds your place and sets the usual method',
    'നിങ്ങളുടെ സ്ഥലം കണ്ടെത്തി സാധാരണ രീതി സജ്ജമാക്കും',
  );
  String get timeSource => _t('Time source', 'സമയ സ്രോതസ്സ്');
  String get calculatedSource =>
      _t('Calculated for this place', 'ഈ സ്ഥലത്തിന് കണക്കാക്കിയത്');
  String get chartSource =>
      _t("Mosque's yearly chart", 'പള്ളിയുടെ വാർഷിക സമയ ചാർട്ട്');
  String get chartSourceHelp => _t(
    "Exact times from your mosque's printed calendar (import once)",
    'പള്ളിയുടെ കലണ്ടറിലെ കൃത്യ സമയങ്ങൾ (ഒരിക്കൽ ഇംപോർട്ട് ചെയ്യുക)',
  );
  String get howFindPlace =>
      _t('How do you find your place?', 'സ്ഥലം എങ്ങനെ കണ്ടെത്തും?');
  String get browse => _t('Browse', 'ബ്രൗസ്');
  String get search => _t('Search', 'തിരയുക');
  String get coordinates => _t('Coordinates', 'കോർഡിനേറ്റുകൾ');
  String get state => _t('State', 'സംസ്ഥാനം');
  String get district => _t('District', 'ജില്ല');
  String get place => _t('Place', 'സ്ഥലം');
  String get all => _t('All', 'എല്ലാം');

  // Built-in charts.
  String get builtinCharts => _t('Azan Time Charts', 'ബാങ്ക് സമയ ചാർട്ടുകൾ');
  String builtinChartsHelp(int n) => _f(
    'Exact yearly charts of {0} places',
    '{0} സ്ഥലങ്ങളുടെ കൃത്യമായ വാർഷിക ചാർട്ടുകൾ',
    [n],
  );
  String get chartsCredit => _t(
    'Azan Time Charts: yearly prayer calendars of local mosques, as collected in the Niskara Samayam app (mifthi.com).',
    'ബാങ്ക് സമയ ചാർട്ടുകൾ: പ്രാദേശിക പള്ളികളുടെ വാർഷിക നിസ്കാര സമയ കലണ്ടറുകൾ, നിസ്കാര സമയം ആപ്പിൽ (mifthi.com) ശേഖരിച്ചത്.',
  );
}

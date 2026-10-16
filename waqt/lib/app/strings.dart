/// UI strings. English and Malayalam are written side by side here; the
/// other languages translate the English text through the tables in
/// `lib/l10n/` (missing entries fall back to English).
library;

import '../core/alerts.dart';
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

  String get appTitle => _t('Waqt', 'വഖ്ത്');
  String get appSubtitle => _t('Salah times', 'നിസ്കാര സമയം');
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
    'Turn off battery optimisation for Waqt',
    'വഖ്തിന് ബാറ്ററി ഒപ്റ്റിമൈസേഷൻ ഓഫാക്കുക',
  );
  String get batteryHelp => _t(
    'Some phones (Xiaomi, Oppo, Vivo, Realme, Samsung) stop apps in the '
        'background. Set Waqt to "Unrestricted" / "No restrictions" in '
        'battery settings so Azan is never missed.',
    'ചില ഫോണുകൾ (Xiaomi, Oppo, Vivo, Realme, Samsung) പശ്ചാത്തലത്തിലുള്ള '
        'ആപ്പുകൾ നിർത്തുന്നു. ബാങ്ക് നഷ്ടപ്പെടാതിരിക്കാൻ ബാറ്ററി '
        'ക്രമീകരണത്തിൽ വഖ്തിനെ "Unrestricted" ആക്കുക.',
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
    'Waqt works offline. It has no ads, no tracking and no internet '
        'permission. Your location never leaves the phone.',
    'വഖ്ത് ഓഫ്‌ലൈനായി പ്രവർത്തിക്കുന്നു. പരസ്യങ്ങളോ ട്രാക്കിംഗോ '
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
    'Silent mode needs "Do Not Disturb" access. Without it, Waqt uses '
        'vibrate.',
    'സൈലന്റ് മോഡിന് "Do Not Disturb" അനുമതി വേണം. ഇല്ലെങ്കിൽ വൈബ്രേറ്റ് ഉപയോഗിക്കും.',
  );
  String get grant => _t('Grant', 'അനുവദിക്കുക');
  String get testAlert =>
      _t('Send a test alert', 'ടെസ്റ്റ് അലേർട്ട് അയയ്ക്കുക');
  String get alertsScheduledNote => _t(
    'Alerts are scheduled for the next 20 days. Opening Waqt now and then '
        'keeps them going.',
    'അടുത്ത 20 ദിവസത്തേക്ക് അലേർട്ടുകൾ ക്രമീകരിച്ചിരിക്കുന്നു. '
        'ഇടയ്ക്കിടെ വഖ്ത് തുറന്നാൽ തുടർന്നുകൊണ്ടിരിക്കും.',
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
  String get keepAlertsTitle =>
      _t('Open Waqt to keep alerts on', 'അലേർട്ടുകൾ തുടരാൻ വഖ്ത് തുറക്കുക');
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
      _t('Open Waqt to refresh', 'പുതുക്കാൻ വഖ്ത് തുറക്കുക');

  // Display mode.
  String get exitDisplay =>
      _t('Tap and hold to exit', 'പുറത്തുകടക്കാൻ അമർത്തിപ്പിടിക്കുക');

  /// Seconds unit in countdowns.
  String get secondsShort => _t('s', 'സെ');
}

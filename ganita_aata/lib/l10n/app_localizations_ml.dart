// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'ഗണിത കളി';

  @override
  String get chooseLanguage => 'ഭാഷ തിരഞ്ഞെടുക്കുക';

  @override
  String get continueBtn => 'തുടരുക';

  @override
  String get welcome => 'സ്വാഗതം!';

  @override
  String get profileSetupTitle => 'ആരാണ് കളിക്കുന്നത്?';

  @override
  String get editProfile => 'വിവരങ്ങൾ മാറ്റുക';

  @override
  String get childName => 'കുട്ടിയുടെ ആദ്യ പേര്';

  @override
  String get nameRequired => 'ദയവായി പേര് എഴുതുക';

  @override
  String get schoolClass => 'ക്ലാസ്';

  @override
  String classN(int n) {
    return 'ക്ലാസ് $n';
  }

  @override
  String classRange(int from, int to) {
    return 'ക്ലാസ് $from–$to';
  }

  @override
  String get chooseAvatar => 'ചിത്രം തിരഞ്ഞെടുക്കുക';

  @override
  String get save => 'സേവ് ചെയ്യുക';

  @override
  String get addChild => 'കുട്ടിയെ ചേർക്കുക';

  @override
  String get switchChild => 'ആരാണ് കളിക്കുന്നത്?';

  @override
  String helloName(String name) {
    return 'നമസ്കാരം, $name!';
  }

  @override
  String get greetingSub => 'സംഖ്യകളുമായി കളിക്കാൻ തയ്യാറാണോ?';

  @override
  String get dailyChallenge => 'ഇന്നത്തെ വെല്ലുവിളി';

  @override
  String get dailyChallengeDesc => '10 കണക്കുകൾ – ഇന്ന് എല്ലാവർക്കും ഒരുപോലെ!';

  @override
  String get dailyDone => 'ഇന്നത്തേത് കഴിഞ്ഞു! നാളെ വീണ്ടും വരൂ.';

  @override
  String get start => 'തുടങ്ങുക';

  @override
  String get playAgainToday => 'വീണ്ടും കളിക്കുക';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ദിവസം', one: '1 ദിവസം');
    return '$_temp0';
  }

  @override
  String get streak => 'തുടർച്ച';

  @override
  String get coins => 'നാണയങ്ങൾ';

  @override
  String get play => 'കളിക്കാം';

  @override
  String get games => 'കളികൾ';

  @override
  String currentTopic(String topic) {
    return 'വിഷയം: $topic';
  }

  @override
  String get change => 'മാറ്റുക';

  @override
  String get gameBalloon => 'ബലൂൺ പൊട്ടിക്കൽ';

  @override
  String get gameBalloonDesc => 'ശരിയുത്തരമുള്ള ബലൂൺ പൊട്ടിക്കൂ';

  @override
  String get gameRace => 'കാർ റേസ്';

  @override
  String get gameRaceDesc => 'ശരിയുത്തരങ്ങൾ നിന്റെ കാറിനെ ഓടിക്കും';

  @override
  String get gameTreasure => 'നിധി വേട്ട';

  @override
  String get gameTreasureDesc => 'തുടർച്ചയായ 5 ശരിയുത്തരങ്ങൾ പെട്ടി തുറക്കും';

  @override
  String get gameTables => 'ഗുണനപ്പട്ടിക മാസ്റ്റർ';

  @override
  String get gameTablesDesc => '2–20 ഗുണനപ്പട്ടികകൾ പഠിക്കൂ, പരിശീലിക്കൂ';

  @override
  String get gameSpeed => 'വേഗ വെല്ലുവിളി';

  @override
  String get gameSpeedDesc => '60 സെക്കൻഡിൽ എത്ര?';

  @override
  String get levelMap => 'ലെവൽ മാപ്പ്';

  @override
  String levelN(int n) {
    return 'ലെവൽ $n';
  }

  @override
  String get locked => 'പൂട്ടിയിരിക്കുന്നു';

  @override
  String get lockedHint => 'ഇത് തുറക്കാൻ മുമ്പത്തെ വിഷയത്തിൽ 85%-ൽ കൂടുതൽ ശരിയാക്കൂ.';

  @override
  String get chooseTopic => 'വിഷയം തിരഞ്ഞെടുക്കുക';

  @override
  String get chooseGame => 'കളി തിരഞ്ഞെടുക്കുക';

  @override
  String get topic_num100 => '100 വരെയുള്ള സംഖ്യകൾ';

  @override
  String get topic_add1 => 'ഒറ്റയക്ക സങ്കലനം';

  @override
  String get topic_sub1 => 'ഒറ്റയക്ക വ്യവകലനം';

  @override
  String get topic_add2 => 'രണ്ടക്ക സങ്കലനം';

  @override
  String get topic_sub2 => 'രണ്ടക്ക വ്യവകലനം';

  @override
  String get topic_tab2_5 => '2–5 ഗുണനപ്പട്ടിക';

  @override
  String get topic_tab6_10 => '6–10 ഗുണനപ്പട്ടിക';

  @override
  String get topic_add3 => 'മൂന്നക്ക സങ്കലനം';

  @override
  String get topic_sub3 => 'മൂന്നക്ക വ്യവകലനം';

  @override
  String get topic_div1 => 'ലളിതമായ ഹരണം';

  @override
  String get topic_tab11_20 => '11–20 ഗുണനപ്പട്ടിക';

  @override
  String get topic_mul21 => 'രണ്ടക്കം × ഒറ്റയക്കം';

  @override
  String get topic_divRem => 'ശിഷ്ടത്തോടെ ഹരണം';

  @override
  String get topic_mixed => 'മിശ്ര ക്രിയകൾ';

  @override
  String get topic_squares => '1–30 വർഗങ്ങൾ';

  @override
  String get topic_cubes => '1–15 ഘനങ്ങൾ';

  @override
  String get topic_percent => 'ശതമാനം';

  @override
  String get topic_fractions => 'ലളിതമായ ഭിന്നസംഖ്യകൾ';

  @override
  String qAfter(int n) {
    return '$n-ന് ശേഷം വരുന്ന സംഖ്യ ഏത്?';
  }

  @override
  String qBefore(int n) {
    return '$n-ന് മുമ്പ് വരുന്ന സംഖ്യ ഏത്?';
  }

  @override
  String qTenMore(int n) {
    return '$n-നെക്കാൾ 10 കൂടുതൽ';
  }

  @override
  String qTenLess(int n) {
    return '$n-നെക്കാൾ 10 കുറവ്';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n-ന്റെ $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n-ന്റെ $fraction';
  }

  @override
  String get remainderShort => 'ശി';

  @override
  String get score => 'സ്കോർ';

  @override
  String secondsShort(int n) {
    return '$n സെ';
  }

  @override
  String get quitGameTitle => 'ഈ റൗണ്ട് നിർത്തണോ?';

  @override
  String get quitGameBody => 'ഈ റൗണ്ടിലെ നാണയങ്ങൾ ചേർക്കില്ല.';

  @override
  String get keepPlaying => 'കളി തുടരുക';

  @override
  String get stop => 'നിർത്തുക';

  @override
  String answerIs(String answer) {
    return 'ഉത്തരം $answer';
  }

  @override
  String get praise => 'സൂപ്പർ!|കൊള്ളാം!|മികച്ചത്!|അടിപൊളി!|നീ ഒരു താരമാണ്!|അത്ഭുതം!';

  @override
  String get encourage =>
      'വീണ്ടും ശ്രമിക്കൂ, നിനക്ക് കഴിയും!|ഏതാണ്ട് ശരി! തുടരൂ!|നല്ല ശ്രമം! ഇതാ അടുത്തത്.|നല്ല പരിശ്രമം! നീ പഠിക്കുകയാണ്!';

  @override
  String get getReady => 'തയ്യാറാകൂ!';

  @override
  String get go => 'പോകാം!';

  @override
  String get you => 'നീ';

  @override
  String get computer => 'കമ്പ്യൂട്ടർ';

  @override
  String get raceWon => 'നീ റേസ് ജയിച്ചു!';

  @override
  String get raceLost => 'നല്ല റേസ്! കുറച്ചുകൂടി പരിശീലിച്ചാൽ അടുത്ത തവണ ജയിക്കും.';

  @override
  String chestOpened(int n) {
    return 'പെട്ടി തുറന്നു! +$n നാണയങ്ങൾ';
  }

  @override
  String get chestStreakReset => 'വീണ്ടും 5 തുടങ്ങാം!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count പെട്ടികൾ തുറന്നു',
      one: '1 പെട്ടി തുറന്നു',
      zero: 'ഇതുവരെ പെട്ടിയില്ല',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'മികച്ചത്: $n';
  }

  @override
  String get newBest => 'പുതിയ റെക്കോർഡ്!';

  @override
  String get clear => 'മായ്ക്കുക';

  @override
  String get pickTable => 'ഗുണനപ്പട്ടിക തിരഞ്ഞെടുക്കുക';

  @override
  String get learn => 'പഠിക്കുക';

  @override
  String get quiz => 'ക്വിസ്';

  @override
  String tableOf(int n) {
    return '$n-ന്റെ ഗുണനപ്പട്ടിക';
  }

  @override
  String get listen => 'കേൾക്കുക';

  @override
  String get pause => 'നിർത്തുക';

  @override
  String get startQuiz => 'ക്വിസ് തുടങ്ങുക';

  @override
  String get mastered => 'പഠിച്ചു';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'റൗണ്ട് കഴിഞ്ഞു!';

  @override
  String get correctLabel => 'ശരി';

  @override
  String get practiseLabel => 'പരിശീലനത്തിന്';

  @override
  String get practiseThese => 'ഇവ പരിശീലിക്കാം';

  @override
  String coinsEarned(int n) {
    return '+$n നാണയങ്ങൾ';
  }

  @override
  String get playAgain => 'വീണ്ടും കളിക്കുക';

  @override
  String get home => 'ഹോം';

  @override
  String get resultMsg3 => 'അത്ഭുതം! നീ ഗണിതത്തിലെ താരമാണ്!';

  @override
  String get resultMsg2 => 'വളരെ നന്നായി!';

  @override
  String get resultMsg1 => 'നന്നായി! പരിശീലനം തുടരൂ!';

  @override
  String get resultMsg0 => 'നല്ല ശ്രമം! ഓരോ റൗണ്ടിലും നീ കൂടുതൽ മെച്ചപ്പെടും!';

  @override
  String get allCorrect => 'എല്ലാം ശരി!';

  @override
  String newTopicUnlocked(String topic) {
    return 'പുതിയ വിഷയം തുറന്നു: $topic';
  }

  @override
  String streakNow(String days) {
    return 'തുടർച്ചയായ ദിവസങ്ങൾ: $days';
  }

  @override
  String get shop => 'കട';

  @override
  String get avatars => 'ചിത്രങ്ങൾ';

  @override
  String get carColours => 'കാർ നിറങ്ങൾ';

  @override
  String get balloonThemes => 'ബലൂണുകൾ';

  @override
  String get buy => 'വാങ്ങുക';

  @override
  String get use => 'ഉപയോഗിക്കുക';

  @override
  String get inUse => 'ഉപയോഗത്തിൽ';

  @override
  String needMoreCoins(int n) {
    return '$n നാണയങ്ങൾ കൂടി നേടാൻ കളിക്കൂ!';
  }

  @override
  String get bought => 'ഇപ്പോൾ ഇത് നിന്റേതാണ്!';

  @override
  String get color_red => 'ചുവപ്പ്';

  @override
  String get color_blue => 'നീല';

  @override
  String get color_green => 'പച്ച';

  @override
  String get color_yellow => 'മഞ്ഞ';

  @override
  String get color_purple => 'വയലറ്റ്';

  @override
  String get color_orange => 'ഓറഞ്ച്';

  @override
  String get color_pink => 'പിങ്ക്';

  @override
  String get color_black => 'കറുപ്പ്';

  @override
  String get theme_rainbow => 'മഴവില്ല്';

  @override
  String get theme_pastel => 'ഇളം നിറങ്ങൾ';

  @override
  String get theme_ocean => 'കടൽ';

  @override
  String get theme_sunset => 'സൂര്യാസ്തമയം';

  @override
  String get theme_candy => 'മിഠായി';

  @override
  String get badges => 'ബാഡ്ജുകൾ';

  @override
  String badgeTableMaster(int n) {
    return '$n ഗുണനപ്പട്ടിക മാസ്റ്റർ';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n-ന്റെ ഗുണനപ്പട്ടികയിലെ എല്ലാ വരിയും പഠിക്കൂ';
  }

  @override
  String get badgeStreak7 => '7 ദിവസം തുടർച്ച';

  @override
  String get badgeStreak7Desc => 'തുടർച്ചയായി 7 ദിവസം ഇന്നത്തെ വെല്ലുവിളി ചെയ്യൂ';

  @override
  String get badgeStreak30 => '30 ദിവസം തുടർച്ച';

  @override
  String get badgeStreak30Desc => 'തുടർച്ചയായി 30 ദിവസം ഇന്നത്തെ വെല്ലുവിളി ചെയ്യൂ';

  @override
  String get badgeDay100 => 'ഒരു ദിവസം 100 കണക്കുകൾ';

  @override
  String get badgeDay100Desc => 'ഒരേ ദിവസം 100 കണക്കുകൾ ചെയ്യൂ';

  @override
  String get badgeSpeedStar => 'വേഗ താരം';

  @override
  String get badgeSpeedStarDesc => 'വേഗ വെല്ലുവിളിയിൽ 20-ഓ അതിലധികമോ ശരി';

  @override
  String get newBadge => 'പുതിയ ബാഡ്ജ്!';

  @override
  String get yay => 'ഹുറേ!';

  @override
  String get forParents => 'രക്ഷിതാക്കൾക്ക്';

  @override
  String get enterPin => 'രക്ഷിതാവിന്റെ PIN നൽകുക';

  @override
  String get createPin => '4 അക്ക PIN ഉണ്ടാക്കുക';

  @override
  String get confirmPin => 'അതേ PIN വീണ്ടും നൽകുക';

  @override
  String get newPin => 'പുതിയ 4 അക്ക PIN നൽകുക';

  @override
  String get pinMismatch => 'രണ്ട് PIN-ഉം വ്യത്യസ്തമായിരുന്നു. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get pinWrong => 'PIN ശരിയല്ല. വീണ്ടും ശ്രമിക്കുക.';

  @override
  String get pinForParents => 'മുതിർന്നവർക്ക് മാത്രം';

  @override
  String get pinForgot => 'PIN മറന്നോ? ഫോൺ സെറ്റിംഗ്സിൽ ഈ ആപ്പിന്റെ ഡാറ്റ മായ്ച്ചാൽ PIN-ഉം എല്ലാ പുരോഗതിയും മായും.';

  @override
  String get pinChanged => 'PIN മാറ്റി';

  @override
  String get progress => 'പുരോഗതി';

  @override
  String get totalSums => 'ചെയ്ത കണക്കുകൾ';

  @override
  String get accuracy => 'കൃത്യത';

  @override
  String get factsMastered => 'പഠിച്ച കണക്കുകൾ';

  @override
  String get daysPractised => 'പരിശീലിച്ച ദിവസങ്ങൾ';

  @override
  String get accuracyPerTopic => 'വിഷയം തിരിച്ചുള്ള കൃത്യത';

  @override
  String get speedOverTime => 'ഒരു കണക്കിന് ശരാശരി സെക്കൻഡ്';

  @override
  String get weakFacts => 'പരിശീലനം വേണ്ട കണക്കുകൾ';

  @override
  String get noWeakFacts => 'ഇപ്പോൾ ഒന്നും പ്രയാസമില്ല. കൊള്ളാം!';

  @override
  String get noDataYet => 'ഇതുവരെ പരിശീലനമില്ല.';

  @override
  String triesRight(int n, int pct) {
    return '$n ശ്രമം · $pct% ശരി';
  }

  @override
  String get settings => 'ക്രമീകരണങ്ങൾ';

  @override
  String get language => 'ഭാഷ';

  @override
  String get sound => 'ശബ്ദം';

  @override
  String get music => 'സംഗീതം';

  @override
  String get dailyReminder => 'ദിവസേനയുള്ള ഓർമ്മപ്പെടുത്തൽ';

  @override
  String get reminderTime => 'ഓർമ്മപ്പെടുത്തൽ സമയം';

  @override
  String get notificationsBlocked => 'ഫോൺ സെറ്റിംഗ്സിൽ ഈ ആപ്പിന്റെ അറിയിപ്പുകൾ ഓഫാണ്.';

  @override
  String get changePin => 'രക്ഷിതാവിന്റെ PIN മാറ്റുക';

  @override
  String get resetProgress => 'പുരോഗതി മായ്ക്കുക';

  @override
  String resetProgressBody(String name) {
    return 'ഇത് $name-ന്റെ എല്ലാ സ്കോറുകളും നാണയങ്ങളും ബാഡ്ജുകളും തുറന്ന ലെവലുകളും മായ്ക്കും.';
  }

  @override
  String get reset => 'മായ്ക്കുക';

  @override
  String get cancel => 'റദ്ദാക്കുക';

  @override
  String get progressReset => 'പുരോഗതി മായ്ച്ചു';

  @override
  String get removeChild => 'ഈ കുട്ടിയെ നീക്കം ചെയ്യുക';

  @override
  String removeChildBody(String name) {
    return '$name-നെയും അവരുടെ എല്ലാ പുരോഗതിയും ഈ ഫോണിൽ നിന്ന് നീക്കണോ?';
  }

  @override
  String get remove => 'നീക്കുക';

  @override
  String get child => 'കുട്ടി';

  @override
  String get about => 'ആപ്പിനെക്കുറിച്ച്';

  @override
  String get aboutBody =>
      '1–8 ക്ലാസുകളിലെ കുട്ടികൾക്ക് ചെറിയ, രസകരമായ റൗണ്ടുകളിൽ ഗണിതം പരിശീലിക്കാൻ ഈ ആപ്പ് സഹായിക്കുന്നു. ഇത് പൂർണ്ണമായും ഓഫ്‌ലൈനിൽ പ്രവർത്തിക്കുന്നു, പരസ്യങ്ങളില്ല, അക്കൗണ്ട് വേണ്ട. കുട്ടിയുടെ ആദ്യ പേരും ക്ലാസും മാത്രം, ഈ ഫോണിൽ മാത്രം സൂക്ഷിക്കുന്നു.';

  @override
  String version(String v) {
    return 'പതിപ്പ് $v';
  }

  @override
  String get licenses => 'ലൈസൻസുകൾ';

  @override
  String get close => 'അടയ്ക്കുക';

  @override
  String get reminderBody => 'ഇന്നത്തെ ഗണിത വെല്ലുവിളിക്കുള്ള സമയമായി!';

  @override
  String get reminderChannel => 'ദിവസേനയുള്ള ഓർമ്മപ്പെടുത്തൽ';

  @override
  String get lockedLevelSnack => 'ഈ ലെവൽ തുറക്കാൻ പരിശീലനം തുടരൂ!';

  @override
  String get hearAgain => 'വീണ്ടും കേൾക്കുക';
}

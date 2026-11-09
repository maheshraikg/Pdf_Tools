// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ಗಣಿತ ಆಟ';

  @override
  String get chooseLanguage => 'ಭಾಷೆ ಆರಿಸಿ';

  @override
  String get continueBtn => 'ಮುಂದುವರಿಸಿ';

  @override
  String get welcome => 'ಸ್ವಾಗತ!';

  @override
  String get profileSetupTitle => 'ಯಾರು ಆಡುತ್ತಿದ್ದಾರೆ?';

  @override
  String get editProfile => 'ವಿವರ ಬದಲಿಸಿ';

  @override
  String get childName => 'ಮಗುವಿನ ಹೆಸರು';

  @override
  String get nameRequired => 'ದಯವಿಟ್ಟು ಹೆಸರು ಬರೆಯಿರಿ';

  @override
  String get schoolClass => 'ತರಗತಿ';

  @override
  String classN(int n) {
    return '$nನೇ ತರಗತಿ';
  }

  @override
  String classRange(int from, int to) {
    return '$from–$toನೇ ತರಗತಿ';
  }

  @override
  String get chooseAvatar => 'ಚಿತ್ರ ಆರಿಸಿ';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get addChild => 'ಮಗುವನ್ನು ಸೇರಿಸಿ';

  @override
  String get switchChild => 'ಯಾರು ಆಡುತ್ತಿದ್ದಾರೆ?';

  @override
  String helloName(String name) {
    return 'ನಮಸ್ಕಾರ, $name!';
  }

  @override
  String get greetingSub => 'ಸಂಖ್ಯೆಗಳ ಜೊತೆ ಆಡೋಣವೇ?';

  @override
  String get dailyChallenge => 'ಇಂದಿನ ಸವಾಲು';

  @override
  String get dailyChallengeDesc => '10 ಲೆಕ್ಕಗಳು – ಇಂದು ಎಲ್ಲರಿಗೂ ಒಂದೇ!';

  @override
  String get dailyDone => 'ಇಂದಿನ ಸವಾಲು ಮುಗಿಯಿತು! ನಾಳೆ ಮತ್ತೆ ಬನ್ನಿ.';

  @override
  String get start => 'ಆರಂಭಿಸಿ';

  @override
  String get playAgainToday => 'ಮತ್ತೆ ಆಡು';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ದಿನಗಳು', one: '1 ದಿನ');
    return '$_temp0';
  }

  @override
  String get streak => 'ಸರಣಿ';

  @override
  String get coins => 'ನಾಣ್ಯಗಳು';

  @override
  String get play => 'ಆಡೋಣ';

  @override
  String get games => 'ಆಟಗಳು';

  @override
  String currentTopic(String topic) {
    return 'ವಿಷಯ: $topic';
  }

  @override
  String get change => 'ಬದಲಿಸಿ';

  @override
  String get gameBalloon => 'ಬಲೂನ್ ಒಡೆಯಿರಿ';

  @override
  String get gameBalloonDesc => 'ಸರಿ ಉತ್ತರದ ಬಲೂನ್ ಒಡೆಯಿರಿ';

  @override
  String get gameRace => 'ಕಾರ್ ಓಟ';

  @override
  String get gameRaceDesc => 'ಸರಿ ಉತ್ತರಕ್ಕೆ ನಿನ್ನ ಕಾರು ಮುಂದೆ ಓಡುತ್ತದೆ';

  @override
  String get gameTreasure => 'ನಿಧಿ ಬೇಟೆ';

  @override
  String get gameTreasureDesc => 'ಸತತ 5 ಸರಿ ಉತ್ತರಕ್ಕೆ ಪೆಟ್ಟಿಗೆ ತೆರೆಯುತ್ತದೆ';

  @override
  String get gameTables => 'ಮಗ್ಗಿ ಮಾಸ್ಟರ್';

  @override
  String get gameTablesDesc => '2–20ರ ಮಗ್ಗಿ ಕಲಿಯಿರಿ, ಅಭ್ಯಾಸ ಮಾಡಿ';

  @override
  String get gameSpeed => 'ವೇಗದ ಸವಾಲು';

  @override
  String get gameSpeedDesc => '60 ಸೆಕೆಂಡಿನಲ್ಲಿ ಎಷ್ಟು?';

  @override
  String get levelMap => 'ಹಂತಗಳ ನಕ್ಷೆ';

  @override
  String levelN(int n) {
    return 'ಹಂತ $n';
  }

  @override
  String get locked => 'ಇನ್ನೂ ತೆರೆದಿಲ್ಲ';

  @override
  String get lockedHint => 'ಹಿಂದಿನ ವಿಷಯದಲ್ಲಿ 85%ಕ್ಕಿಂತ ಹೆಚ್ಚು ಸರಿ ಉತ್ತರ ನೀಡಿದರೆ ಇದು ತೆರೆಯುತ್ತದೆ.';

  @override
  String get chooseTopic => 'ವಿಷಯ ಆರಿಸಿ';

  @override
  String get chooseGame => 'ಆಟ ಆರಿಸಿ';

  @override
  String get topic_num100 => '100ರವರೆಗಿನ ಸಂಖ್ಯೆಗಳು';

  @override
  String get topic_add1 => 'ಒಂದಂಕಿ ಸಂಕಲನ';

  @override
  String get topic_sub1 => 'ಒಂದಂಕಿ ವ್ಯವಕಲನ';

  @override
  String get topic_add2 => 'ಎರಡಂಕಿ ಸಂಕಲನ';

  @override
  String get topic_sub2 => 'ಎರಡಂಕಿ ವ್ಯವಕಲನ';

  @override
  String get topic_tab2_5 => '2–5ರ ಮಗ್ಗಿ';

  @override
  String get topic_tab6_10 => '6–10ರ ಮಗ್ಗಿ';

  @override
  String get topic_add3 => 'ಮೂರಂಕಿ ಸಂಕಲನ';

  @override
  String get topic_sub3 => 'ಮೂರಂಕಿ ವ್ಯವಕಲನ';

  @override
  String get topic_div1 => 'ಸರಳ ಭಾಗಾಕಾರ';

  @override
  String get topic_tab11_20 => '11–20ರ ಮಗ್ಗಿ';

  @override
  String get topic_mul21 => 'ಎರಡಂಕಿ × ಒಂದಂಕಿ ಗುಣಾಕಾರ';

  @override
  String get topic_divRem => 'ಶೇಷ ಸಹಿತ ಭಾಗಾಕಾರ';

  @override
  String get topic_mixed => 'ಮಿಶ್ರ ಕ್ರಿಯೆಗಳು';

  @override
  String get topic_squares => '1–30ರ ವರ್ಗಗಳು';

  @override
  String get topic_cubes => '1–15ರ ಘನಗಳು';

  @override
  String get topic_percent => 'ಶೇಕಡಾ';

  @override
  String get topic_fractions => 'ಸರಳ ಭಿನ್ನರಾಶಿಗಳು';

  @override
  String qAfter(int n) {
    return '$nರ ನಂತರ ಬರುವ ಸಂಖ್ಯೆ ಯಾವುದು?';
  }

  @override
  String qBefore(int n) {
    return '$nರ ಹಿಂದೆ ಬರುವ ಸಂಖ್ಯೆ ಯಾವುದು?';
  }

  @override
  String qTenMore(int n) {
    return '$nಕ್ಕಿಂತ 10 ಹೆಚ್ಚು';
  }

  @override
  String qTenLess(int n) {
    return '$nಕ್ಕಿಂತ 10 ಕಡಿಮೆ';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$nರ $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$nರ $fraction';
  }

  @override
  String get remainderShort => 'ಶೇ';

  @override
  String get score => 'ಅಂಕ';

  @override
  String secondsShort(int n) {
    return '$n ಸೆ';
  }

  @override
  String get quitGameTitle => 'ಈ ಸುತ್ತನ್ನು ನಿಲ್ಲಿಸಬೇಕೆ?';

  @override
  String get quitGameBody => 'ಈ ಸುತ್ತಿನ ನಾಣ್ಯಗಳು ಸೇರುವುದಿಲ್ಲ.';

  @override
  String get keepPlaying => 'ಆಟ ಮುಂದುವರಿಸಿ';

  @override
  String get stop => 'ನಿಲ್ಲಿಸಿ';

  @override
  String answerIs(String answer) {
    return 'ಉತ್ತರ $answer';
  }

  @override
  String get praise => 'ಸೂಪರ್!|ಶಭಾಷ್!|ಅದ್ಭುತ!|ತುಂಬಾ ಚೆನ್ನಾಗಿದೆ!|ನೀನು ಸ್ಟಾರ್!|ಬಹಳ ಚೆನ್ನ!';

  @override
  String get encourage =>
      'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸು, ನಿನ್ನಿಂದ ಸಾಧ್ಯ!|ಸ್ವಲ್ಪದರಲ್ಲೇ ತಪ್ಪಿತು! ಮುಂದುವರಿಸು!|ಒಳ್ಳೆಯ ಪ್ರಯತ್ನ! ಇಗೋ ಮುಂದಿನದು.|ಚೆನ್ನಾಗಿ ಪ್ರಯತ್ನಿಸಿದೆ! ನೀನು ಕಲಿಯುತ್ತಿದ್ದೀಯ!';

  @override
  String get getReady => 'ಸಿದ್ಧರಾಗಿ!';

  @override
  String get go => 'ಶುರು!';

  @override
  String get you => 'ನೀನು';

  @override
  String get computer => 'ಕಂಪ್ಯೂಟರ್';

  @override
  String get raceWon => 'ನೀನು ಓಟ ಗೆದ್ದೆ!';

  @override
  String get raceLost => 'ಒಳ್ಳೆಯ ಓಟ! ಇನ್ನಷ್ಟು ಅಭ್ಯಾಸ ಮಾಡಿದರೆ ಮುಂದಿನ ಬಾರಿ ಗೆಲ್ಲುವೆ.';

  @override
  String chestOpened(int n) {
    return 'ಪೆಟ್ಟಿಗೆ ತೆರೆಯಿತು! +$n ನಾಣ್ಯ';
  }

  @override
  String get chestStreakReset => 'ಹೊಸದಾಗಿ 5 ಶುರು ಮಾಡೋಣ!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ಪೆಟ್ಟಿಗೆ ತೆರೆಯಿತು',
      zero: 'ಇನ್ನೂ ಪೆಟ್ಟಿಗೆ ಇಲ್ಲ',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'ಅತ್ಯುತ್ತಮ: $n';
  }

  @override
  String get newBest => 'ಹೊಸ ದಾಖಲೆ!';

  @override
  String get clear => 'ಅಳಿಸು';

  @override
  String get pickTable => 'ಮಗ್ಗಿ ಆರಿಸಿ';

  @override
  String get learn => 'ಕಲಿ';

  @override
  String get quiz => 'ಪರೀಕ್ಷೆ';

  @override
  String tableOf(int n) {
    return '$nರ ಮಗ್ಗಿ';
  }

  @override
  String get listen => 'ಆಲಿಸಿ';

  @override
  String get pause => 'ನಿಲ್ಲಿಸು';

  @override
  String get startQuiz => 'ಪರೀಕ್ಷೆ ಆರಂಭಿಸಿ';

  @override
  String get mastered => 'ಕರಗತ';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'ಸುತ್ತು ಮುಗಿಯಿತು!';

  @override
  String get correctLabel => 'ಸರಿ';

  @override
  String get practiseLabel => 'ಅಭ್ಯಾಸಕ್ಕೆ';

  @override
  String get practiseThese => 'ಇವುಗಳನ್ನು ಅಭ್ಯಾಸ ಮಾಡೋಣ';

  @override
  String coinsEarned(int n) {
    return '+$n ನಾಣ್ಯಗಳು';
  }

  @override
  String get playAgain => 'ಮತ್ತೆ ಆಡು';

  @override
  String get home => 'ಮುಖಪುಟ';

  @override
  String get resultMsg3 => 'ಅದ್ಭುತ! ನೀನು ಗಣಿತದ ತಾರೆ!';

  @override
  String get resultMsg2 => 'ತುಂಬಾ ಚೆನ್ನಾಗಿ ಮಾಡಿದೆ!';

  @override
  String get resultMsg1 => 'ಒಳ್ಳೆಯ ಕೆಲಸ! ಅಭ್ಯಾಸ ಮುಂದುವರಿಸು!';

  @override
  String get resultMsg0 => 'ಒಳ್ಳೆಯ ಪ್ರಯತ್ನ! ಪ್ರತಿ ಸುತ್ತಿನಲ್ಲೂ ನೀನು ಇನ್ನೂ ಚೆನ್ನಾಗಿ ಮಾಡುವೆ!';

  @override
  String get allCorrect => 'ಎಲ್ಲವೂ ಸರಿ!';

  @override
  String newTopicUnlocked(String topic) {
    return 'ಹೊಸ ವಿಷಯ ತೆರೆಯಿತು: $topic';
  }

  @override
  String streakNow(String days) {
    return 'ದೈನಂದಿನ ಸರಣಿ: $days';
  }

  @override
  String get shop => 'ಅಂಗಡಿ';

  @override
  String get avatars => 'ಚಿತ್ರಗಳು';

  @override
  String get carColours => 'ಕಾರಿನ ಬಣ್ಣ';

  @override
  String get balloonThemes => 'ಬಲೂನ್‌ಗಳು';

  @override
  String get buy => 'ಕೊಳ್ಳಿ';

  @override
  String get use => 'ಬಳಸು';

  @override
  String get inUse => 'ಬಳಕೆಯಲ್ಲಿದೆ';

  @override
  String needMoreCoins(int n) {
    return 'ಇನ್ನೂ $n ನಾಣ್ಯ ಗಳಿಸಲು ಆಟವಾಡು!';
  }

  @override
  String get bought => 'ಈಗ ಇದು ನಿನ್ನದು!';

  @override
  String get color_red => 'ಕೆಂಪು';

  @override
  String get color_blue => 'ನೀಲಿ';

  @override
  String get color_green => 'ಹಸಿರು';

  @override
  String get color_yellow => 'ಹಳದಿ';

  @override
  String get color_purple => 'ನೇರಳೆ';

  @override
  String get color_orange => 'ಕಿತ್ತಳೆ';

  @override
  String get color_pink => 'ಗುಲಾಬಿ';

  @override
  String get color_black => 'ಕಪ್ಪು';

  @override
  String get theme_rainbow => 'ಕಾಮನಬಿಲ್ಲು';

  @override
  String get theme_pastel => 'ತಿಳಿ ಬಣ್ಣ';

  @override
  String get theme_ocean => 'ಸಮುದ್ರ';

  @override
  String get theme_sunset => 'ಸೂರ್ಯಾಸ್ತ';

  @override
  String get theme_candy => 'ಮಿಠಾಯಿ';

  @override
  String get badges => 'ಬ್ಯಾಡ್ಜ್‌ಗಳು';

  @override
  String badgeTableMaster(int n) {
    return '$nರ ಮಗ್ಗಿ ಮಾಸ್ಟರ್';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$nರ ಮಗ್ಗಿಯ ಎಲ್ಲಾ ಸಾಲುಗಳನ್ನು ಕರಗತ ಮಾಡಿಕೊ';
  }

  @override
  String get badgeStreak7 => '7 ದಿನಗಳ ಸರಣಿ';

  @override
  String get badgeStreak7Desc => 'ಸತತ 7 ದಿನ ಇಂದಿನ ಸವಾಲು ಮಾಡು';

  @override
  String get badgeStreak30 => '30 ದಿನಗಳ ಸರಣಿ';

  @override
  String get badgeStreak30Desc => 'ಸತತ 30 ದಿನ ಇಂದಿನ ಸವಾಲು ಮಾಡು';

  @override
  String get badgeDay100 => 'ಒಂದೇ ದಿನ 100 ಲೆಕ್ಕ';

  @override
  String get badgeDay100Desc => 'ಒಂದೇ ದಿನದಲ್ಲಿ 100 ಲೆಕ್ಕ ಬಿಡಿಸು';

  @override
  String get badgeSpeedStar => 'ವೇಗದ ತಾರೆ';

  @override
  String get badgeSpeedStarDesc => 'ವೇಗದ ಸವಾಲಿನಲ್ಲಿ 20 ಅಥವಾ ಹೆಚ್ಚು ಸರಿ ಉತ್ತರ';

  @override
  String get newBadge => 'ಹೊಸ ಬ್ಯಾಡ್ಜ್!';

  @override
  String get yay => 'ಹುರ್ರೇ!';

  @override
  String get forParents => 'ಪೋಷಕರಿಗೆ';

  @override
  String get enterPin => 'ಪೋಷಕರ ಪಿನ್ ನಮೂದಿಸಿ';

  @override
  String get createPin => '4 ಅಂಕಿಯ ಪೋಷಕರ ಪಿನ್ ರಚಿಸಿ';

  @override
  String get confirmPin => 'ಅದೇ ಪಿನ್ ಮತ್ತೊಮ್ಮೆ ನಮೂದಿಸಿ';

  @override
  String get newPin => 'ಹೊಸ 4 ಅಂಕಿಯ ಪಿನ್ ನಮೂದಿಸಿ';

  @override
  String get pinMismatch => 'ಎರಡು ಪಿನ್ ಬೇರೆ ಬೇರೆಯಾಗಿವೆ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get pinWrong => 'ಪಿನ್ ಸರಿಯಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get pinForParents => 'ದೊಡ್ಡವರಿಗೆ ಮಾತ್ರ';

  @override
  String get pinForgot =>
      'ಪಿನ್ ಮರೆತಿರಾ? ಫೋನ್ ಸೆಟ್ಟಿಂಗ್‌ನಲ್ಲಿ ಈ ಆಪ್‌ನ ಸಂಗ್ರಹ ಅಳಿಸಿದರೆ ಪಿನ್ ಮತ್ತು ಎಲ್ಲಾ ಪ್ರಗತಿ ಅಳಿಸಿಹೋಗುತ್ತದೆ.';

  @override
  String get pinChanged => 'ಪಿನ್ ಬದಲಾಯಿತು';

  @override
  String get progress => 'ಪ್ರಗತಿ';

  @override
  String get totalSums => 'ಬಿಡಿಸಿದ ಲೆಕ್ಕಗಳು';

  @override
  String get accuracy => 'ನಿಖರತೆ';

  @override
  String get factsMastered => 'ಕರಗತ ಲೆಕ್ಕಗಳು';

  @override
  String get daysPractised => 'ಅಭ್ಯಾಸದ ದಿನಗಳು';

  @override
  String get accuracyPerTopic => 'ವಿಷಯವಾರು ನಿಖರತೆ';

  @override
  String get speedOverTime => 'ಪ್ರತಿ ಲೆಕ್ಕಕ್ಕೆ ಸರಾಸರಿ ಸೆಕೆಂಡು';

  @override
  String get weakFacts => 'ಅಭ್ಯಾಸ ಬೇಕಾದ ಲೆಕ್ಕಗಳು';

  @override
  String get noWeakFacts => 'ಈಗ ಯಾವುದೂ ಕಷ್ಟವಿಲ್ಲ. ಶಭಾಷ್!';

  @override
  String get noDataYet => 'ಇನ್ನೂ ಅಭ್ಯಾಸ ಆಗಿಲ್ಲ.';

  @override
  String triesRight(int n, int pct) {
    return '$n ಪ್ರಯತ್ನ · $pct% ಸರಿ';
  }

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get sound => 'ಧ್ವನಿ';

  @override
  String get music => 'ಸಂಗೀತ';

  @override
  String get dailyReminder => 'ದೈನಂದಿನ ಜ್ಞಾಪನೆ';

  @override
  String get reminderTime => 'ಜ್ಞಾಪನೆಯ ಸಮಯ';

  @override
  String get notificationsBlocked => 'ಫೋನ್ ಸೆಟ್ಟಿಂಗ್‌ನಲ್ಲಿ ಈ ಆಪ್‌ನ ಅಧಿಸೂಚನೆಗಳು ಆಫ್ ಆಗಿವೆ.';

  @override
  String get changePin => 'ಪೋಷಕರ ಪಿನ್ ಬದಲಿಸಿ';

  @override
  String get resetProgress => 'ಪ್ರಗತಿ ಅಳಿಸಿ';

  @override
  String resetProgressBody(String name) {
    return 'ಇದು $name ಅವರ ಎಲ್ಲಾ ಅಂಕ, ನಾಣ್ಯ, ಬ್ಯಾಡ್ಜ್ ಮತ್ತು ತೆರೆದ ಹಂತಗಳನ್ನು ಅಳಿಸುತ್ತದೆ.';
  }

  @override
  String get reset => 'ಅಳಿಸಿ';

  @override
  String get cancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get progressReset => 'ಪ್ರಗತಿ ಅಳಿಸಲಾಯಿತು';

  @override
  String get removeChild => 'ಈ ಮಗುವನ್ನು ತೆಗೆದುಹಾಕಿ';

  @override
  String removeChildBody(String name) {
    return '$name ಮತ್ತು ಅವರ ಎಲ್ಲಾ ಪ್ರಗತಿಯನ್ನು ಈ ಫೋನಿನಿಂದ ತೆಗೆದುಹಾಕಬೇಕೆ?';
  }

  @override
  String get remove => 'ತೆಗೆದುಹಾಕಿ';

  @override
  String get child => 'ಮಗು';

  @override
  String get about => 'ಆಪ್ ಬಗ್ಗೆ';

  @override
  String get aboutBody =>
      'ಗಣಿತ ಆಟ 1–8ನೇ ತರಗತಿಯ ಮಕ್ಕಳಿಗೆ ಚಿಕ್ಕ, ಮೋಜಿನ ಸುತ್ತುಗಳಲ್ಲಿ ಗಣಿತ ಅಭ್ಯಾಸ ಮಾಡಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ. ಇದು ಸಂಪೂರ್ಣ ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕೆಲಸ ಮಾಡುತ್ತದೆ, ಜಾಹೀರಾತುಗಳಿಲ್ಲ, ಖಾತೆ ಬೇಕಿಲ್ಲ. ಮಗುವಿನ ಹೆಸರು ಮತ್ತು ತರಗತಿ ಮಾತ್ರ, ಈ ಫೋನಿನಲ್ಲಿ ಮಾತ್ರ ಉಳಿಯುತ್ತದೆ.';

  @override
  String version(String v) {
    return 'ಆವೃತ್ತಿ $v';
  }

  @override
  String get licenses => 'ಪರವಾನಗಿಗಳು';

  @override
  String get close => 'ಮುಚ್ಚಿ';

  @override
  String get reminderBody => 'ಇಂದಿನ ಗಣಿತ ಆಟದ ಸವಾಲಿನ ಸಮಯ!';

  @override
  String get reminderChannel => 'ದೈನಂದಿನ ಜ್ಞಾಪನೆ';

  @override
  String get lockedLevelSnack => 'ಈ ಹಂತ ತೆರೆಯಲು ಅಭ್ಯಾಸ ಮುಂದುವರಿಸು!';

  @override
  String get hearAgain => 'ಮತ್ತೆ ಕೇಳಿ';
}

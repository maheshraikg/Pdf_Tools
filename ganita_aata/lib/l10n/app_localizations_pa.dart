// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get appTitle => 'ਗਣਿਤ ਖੇਡ';

  @override
  String get chooseLanguage => 'ਭਾਸ਼ਾ ਚੁਣੋ';

  @override
  String get continueBtn => 'ਅੱਗੇ ਵਧੋ';

  @override
  String get welcome => 'ਜੀ ਆਇਆਂ ਨੂੰ!';

  @override
  String get profileSetupTitle => 'ਕੌਣ ਖੇਡ ਰਿਹਾ ਹੈ?';

  @override
  String get editProfile => 'ਵੇਰਵੇ ਬਦਲੋ';

  @override
  String get childName => 'ਬੱਚੇ ਦਾ ਪਹਿਲਾ ਨਾਮ';

  @override
  String get nameRequired => 'ਕਿਰਪਾ ਕਰਕੇ ਨਾਮ ਲਿਖੋ';

  @override
  String get schoolClass => 'ਜਮਾਤ';

  @override
  String classN(int n) {
    return 'ਜਮਾਤ $n';
  }

  @override
  String classRange(int from, int to) {
    return 'ਜਮਾਤ $from–$to';
  }

  @override
  String get chooseAvatar => 'ਤਸਵੀਰ ਚੁਣੋ';

  @override
  String get save => 'ਸੰਭਾਲੋ';

  @override
  String get addChild => 'ਬੱਚਾ ਜੋੜੋ';

  @override
  String get switchChild => 'ਕੌਣ ਖੇਡ ਰਿਹਾ ਹੈ?';

  @override
  String helloName(String name) {
    return 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ, $name!';
  }

  @override
  String get greetingSub => 'ਅੰਕਾਂ ਨਾਲ ਖੇਡਣ ਲਈ ਤਿਆਰ?';

  @override
  String get dailyChallenge => 'ਅੱਜ ਦੀ ਚੁਣੌਤੀ';

  @override
  String get dailyChallengeDesc => '10 ਸਵਾਲ – ਅੱਜ ਸਭ ਲਈ ਇੱਕੋ ਜਿਹੇ!';

  @override
  String get dailyDone => 'ਅੱਜ ਦਾ ਪੂਰਾ! ਕੱਲ੍ਹ ਫਿਰ ਆਉਣਾ।';

  @override
  String get start => 'ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get playAgainToday => 'ਫਿਰ ਖੇਡੋ';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ਦਿਨ', one: '1 ਦਿਨ');
    return '$_temp0';
  }

  @override
  String get streak => 'ਲਗਾਤਾਰ';

  @override
  String get coins => 'ਸਿੱਕੇ';

  @override
  String get play => 'ਖੇਡੋ';

  @override
  String get games => 'ਖੇਡਾਂ';

  @override
  String currentTopic(String topic) {
    return 'ਵਿਸ਼ਾ: $topic';
  }

  @override
  String get change => 'ਬਦਲੋ';

  @override
  String get gameBalloon => 'ਗੁਬਾਰਾ ਫੋੜੋ';

  @override
  String get gameBalloonDesc => 'ਸਹੀ ਜਵਾਬ ਵਾਲਾ ਗੁਬਾਰਾ ਫੋੜੋ';

  @override
  String get gameRace => 'ਕਾਰ ਦੌੜ';

  @override
  String get gameRaceDesc => 'ਸਹੀ ਜਵਾਬਾਂ ਨਾਲ ਤੁਹਾਡੀ ਕਾਰ ਦੌੜੇਗੀ';

  @override
  String get gameTreasure => 'ਖ਼ਜ਼ਾਨੇ ਦੀ ਖੋਜ';

  @override
  String get gameTreasureDesc => 'ਲਗਾਤਾਰ 5 ਸਹੀ ਜਵਾਬਾਂ ਨਾਲ ਸੰਦੂਕ ਖੁੱਲ੍ਹਦਾ ਹੈ';

  @override
  String get gameTables => 'ਪਹਾੜਾ ਮਾਸਟਰ';

  @override
  String get gameTablesDesc => '2–20 ਦੇ ਪਹਾੜੇ ਸਿੱਖੋ ਅਤੇ ਅਭਿਆਸ ਕਰੋ';

  @override
  String get gameSpeed => 'ਤੇਜ਼ੀ ਦੀ ਚੁਣੌਤੀ';

  @override
  String get gameSpeedDesc => '60 ਸਕਿੰਟਾਂ ਵਿੱਚ ਕਿੰਨੇ?';

  @override
  String get levelMap => 'ਪੱਧਰਾਂ ਦਾ ਨਕਸ਼ਾ';

  @override
  String levelN(int n) {
    return 'ਪੱਧਰ $n';
  }

  @override
  String get locked => 'ਬੰਦ';

  @override
  String get lockedHint => 'ਇਸ ਨੂੰ ਖੋਲ੍ਹਣ ਲਈ ਪਿਛਲੇ ਵਿਸ਼ੇ ਵਿੱਚ 85% ਤੋਂ ਵੱਧ ਸਹੀ ਕਰੋ।';

  @override
  String get chooseTopic => 'ਵਿਸ਼ਾ ਚੁਣੋ';

  @override
  String get chooseGame => 'ਖੇਡ ਚੁਣੋ';

  @override
  String get topic_num100 => '100 ਤੱਕ ਦੇ ਅੰਕ';

  @override
  String get topic_add1 => 'ਇੱਕ ਅੰਕ ਦਾ ਜੋੜ';

  @override
  String get topic_sub1 => 'ਇੱਕ ਅੰਕ ਦੀ ਘਟਾਓ';

  @override
  String get topic_add2 => 'ਦੋ ਅੰਕਾਂ ਦਾ ਜੋੜ';

  @override
  String get topic_sub2 => 'ਦੋ ਅੰਕਾਂ ਦੀ ਘਟਾਓ';

  @override
  String get topic_tab2_5 => '2–5 ਦੇ ਪਹਾੜੇ';

  @override
  String get topic_tab6_10 => '6–10 ਦੇ ਪਹਾੜੇ';

  @override
  String get topic_add3 => 'ਤਿੰਨ ਅੰਕਾਂ ਦਾ ਜੋੜ';

  @override
  String get topic_sub3 => 'ਤਿੰਨ ਅੰਕਾਂ ਦੀ ਘਟਾਓ';

  @override
  String get topic_div1 => 'ਸੌਖੀ ਵੰਡ';

  @override
  String get topic_tab11_20 => '11–20 ਦੇ ਪਹਾੜੇ';

  @override
  String get topic_mul21 => 'ਦੋ ਅੰਕ × ਇੱਕ ਅੰਕ';

  @override
  String get topic_divRem => 'ਬਾਕੀ ਨਾਲ ਵੰਡ';

  @override
  String get topic_mixed => 'ਮਿਲੀਆਂ-ਜੁਲੀਆਂ ਕਿਰਿਆਵਾਂ';

  @override
  String get topic_squares => '1–30 ਦੇ ਵਰਗ';

  @override
  String get topic_cubes => '1–15 ਦੇ ਘਣ';

  @override
  String get topic_percent => 'ਪ੍ਰਤੀਸ਼ਤ';

  @override
  String get topic_fractions => 'ਸੌਖੀਆਂ ਭਿੰਨਾਂ';

  @override
  String qAfter(int n) {
    return '$n ਤੋਂ ਬਾਅਦ ਕਿਹੜਾ ਅੰਕ ਆਉਂਦਾ ਹੈ?';
  }

  @override
  String qBefore(int n) {
    return '$n ਤੋਂ ਪਹਿਲਾਂ ਕਿਹੜਾ ਅੰਕ ਆਉਂਦਾ ਹੈ?';
  }

  @override
  String qTenMore(int n) {
    return '$n ਤੋਂ 10 ਵੱਧ';
  }

  @override
  String qTenLess(int n) {
    return '$n ਤੋਂ 10 ਘੱਟ';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n ਦਾ $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n ਦਾ $fraction';
  }

  @override
  String get remainderShort => 'ਬਾ';

  @override
  String get score => 'ਅੰਕ';

  @override
  String secondsShort(int n) {
    return '$n ਸ';
  }

  @override
  String get quitGameTitle => 'ਇਹ ਰਾਊਂਡ ਰੋਕਣਾ ਹੈ?';

  @override
  String get quitGameBody => 'ਇਸ ਰਾਊਂਡ ਦੇ ਸਿੱਕੇ ਨਹੀਂ ਜੁੜਨਗੇ।';

  @override
  String get keepPlaying => 'ਖੇਡਦੇ ਰਹੋ';

  @override
  String get stop => 'ਰੋਕੋ';

  @override
  String answerIs(String answer) {
    return 'ਜਵਾਬ ਹੈ $answer';
  }

  @override
  String get praise => 'ਸ਼ਾਬਾਸ਼!|ਬਹੁਤ ਵਧੀਆ!|ਕਮਾਲ!|ਬੱਲੇ ਬੱਲੇ!|ਤੁਸੀਂ ਤਾਂ ਸਟਾਰ ਹੋ!|ਵਾਹ!';

  @override
  String get encourage =>
      'ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ, ਤੁਸੀਂ ਕਰ ਸਕਦੇ ਹੋ!|ਬੱਸ ਥੋੜ੍ਹਾ ਜਿਹਾ! ਅੱਗੇ ਵਧੋ!|ਵਧੀਆ ਕੋਸ਼ਿਸ਼! ਇਹ ਰਿਹਾ ਅਗਲਾ।|ਚੰਗੀ ਕੋਸ਼ਿਸ਼! ਤੁਸੀਂ ਸਿੱਖ ਰਹੇ ਹੋ!';

  @override
  String get getReady => 'ਤਿਆਰ ਹੋ ਜਾਓ!';

  @override
  String get go => 'ਚੱਲੋ!';

  @override
  String get you => 'ਤੁਸੀਂ';

  @override
  String get computer => 'ਕੰਪਿਊਟਰ';

  @override
  String get raceWon => 'ਤੁਸੀਂ ਦੌੜ ਜਿੱਤ ਗਏ!';

  @override
  String get raceLost => 'ਵਧੀਆ ਦੌੜ! ਥੋੜ੍ਹਾ ਹੋਰ ਅਭਿਆਸ ਕਰੋ, ਅਗਲੀ ਵਾਰ ਜਿੱਤੋਗੇ।';

  @override
  String chestOpened(int n) {
    return 'ਸੰਦੂਕ ਖੁੱਲ੍ਹ ਗਿਆ! +$n ਸਿੱਕੇ';
  }

  @override
  String get chestStreakReset => 'ਫਿਰ 5 ਸ਼ੁਰੂ ਕਰੀਏ!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਸੰਦੂਕ ਖੁੱਲ੍ਹੇ',
      one: '1 ਸੰਦੂਕ ਖੁੱਲ੍ਹਿਆ',
      zero: 'ਅਜੇ ਕੋਈ ਸੰਦੂਕ ਨਹੀਂ',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'ਸਭ ਤੋਂ ਵਧੀਆ: $n';
  }

  @override
  String get newBest => 'ਨਵਾਂ ਰਿਕਾਰਡ!';

  @override
  String get clear => 'ਮਿਟਾਓ';

  @override
  String get pickTable => 'ਪਹਾੜਾ ਚੁਣੋ';

  @override
  String get learn => 'ਸਿੱਖੋ';

  @override
  String get quiz => 'ਕੁਇਜ਼';

  @override
  String tableOf(int n) {
    return '$n ਦਾ ਪਹਾੜਾ';
  }

  @override
  String get listen => 'ਸੁਣੋ';

  @override
  String get pause => 'ਰੋਕੋ';

  @override
  String get startQuiz => 'ਕੁਇਜ਼ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get mastered => 'ਪੱਕਾ';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'ਰਾਊਂਡ ਪੂਰਾ!';

  @override
  String get correctLabel => 'ਸਹੀ';

  @override
  String get practiseLabel => 'ਅਭਿਆਸ ਲਈ';

  @override
  String get practiseThese => 'ਆਓ ਇਹਨਾਂ ਦਾ ਅਭਿਆਸ ਕਰੀਏ';

  @override
  String coinsEarned(int n) {
    return '+$n ਸਿੱਕੇ';
  }

  @override
  String get playAgain => 'ਫਿਰ ਖੇਡੋ';

  @override
  String get home => 'ਹੋਮ';

  @override
  String get resultMsg3 => 'ਕਮਾਲ! ਤੁਸੀਂ ਗਣਿਤ ਦੇ ਤਾਰੇ ਹੋ!';

  @override
  String get resultMsg2 => 'ਬਹੁਤ ਵਧੀਆ ਕੰਮ!';

  @override
  String get resultMsg1 => 'ਵਧੀਆ! ਅਭਿਆਸ ਜਾਰੀ ਰੱਖੋ!';

  @override
  String get resultMsg0 => 'ਚੰਗੀ ਕੋਸ਼ਿਸ਼! ਹਰ ਰਾਊਂਡ ਨਾਲ ਤੁਸੀਂ ਹੋਰ ਵਧੀਆ ਹੋਵੋਗੇ!';

  @override
  String get allCorrect => 'ਸਭ ਸਹੀ!';

  @override
  String newTopicUnlocked(String topic) {
    return 'ਨਵਾਂ ਵਿਸ਼ਾ ਖੁੱਲ੍ਹਿਆ: $topic';
  }

  @override
  String streakNow(String days) {
    return 'ਲਗਾਤਾਰ ਦਿਨ: $days';
  }

  @override
  String get shop => 'ਦੁਕਾਨ';

  @override
  String get avatars => 'ਤਸਵੀਰਾਂ';

  @override
  String get carColours => 'ਕਾਰ ਦੇ ਰੰਗ';

  @override
  String get balloonThemes => 'ਗੁਬਾਰੇ';

  @override
  String get buy => 'ਖਰੀਦੋ';

  @override
  String get use => 'ਵਰਤੋ';

  @override
  String get inUse => 'ਵਰਤੋਂ ਵਿੱਚ';

  @override
  String needMoreCoins(int n) {
    return 'ਹੋਰ $n ਸਿੱਕੇ ਕਮਾਉਣ ਲਈ ਖੇਡੋ!';
  }

  @override
  String get bought => 'ਹੁਣ ਇਹ ਤੁਹਾਡਾ ਹੈ!';

  @override
  String get color_red => 'ਲਾਲ';

  @override
  String get color_blue => 'ਨੀਲਾ';

  @override
  String get color_green => 'ਹਰਾ';

  @override
  String get color_yellow => 'ਪੀਲਾ';

  @override
  String get color_purple => 'ਜਾਮਨੀ';

  @override
  String get color_orange => 'ਸੰਤਰੀ';

  @override
  String get color_pink => 'ਗੁਲਾਬੀ';

  @override
  String get color_black => 'ਕਾਲਾ';

  @override
  String get theme_rainbow => 'ਸਤਰੰਗੀ ਪੀਂਘ';

  @override
  String get theme_pastel => 'ਹਲਕੇ ਰੰਗ';

  @override
  String get theme_ocean => 'ਸਮੁੰਦਰ';

  @override
  String get theme_sunset => 'ਸੂਰਜ ਡੁੱਬਣਾ';

  @override
  String get theme_candy => 'ਟੌਫ਼ੀ';

  @override
  String get badges => 'ਬੈਜ';

  @override
  String badgeTableMaster(int n) {
    return '$n ਦਾ ਪਹਾੜਾ ਮਾਸਟਰ';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n ਦੇ ਪਹਾੜੇ ਦੀ ਹਰ ਲਾਈਨ ਪੱਕੀ ਕਰੋ';
  }

  @override
  String get badgeStreak7 => 'ਲਗਾਤਾਰ 7 ਦਿਨ';

  @override
  String get badgeStreak7Desc => 'ਲਗਾਤਾਰ 7 ਦਿਨ ਅੱਜ ਦੀ ਚੁਣੌਤੀ ਕਰੋ';

  @override
  String get badgeStreak30 => 'ਲਗਾਤਾਰ 30 ਦਿਨ';

  @override
  String get badgeStreak30Desc => 'ਲਗਾਤਾਰ 30 ਦਿਨ ਅੱਜ ਦੀ ਚੁਣੌਤੀ ਕਰੋ';

  @override
  String get badgeDay100 => 'ਇੱਕ ਦਿਨ ਵਿੱਚ 100 ਸਵਾਲ';

  @override
  String get badgeDay100Desc => 'ਇੱਕੋ ਦਿਨ ਵਿੱਚ 100 ਸਵਾਲ ਹੱਲ ਕਰੋ';

  @override
  String get badgeSpeedStar => 'ਤੇਜ਼ੀ ਦਾ ਤਾਰਾ';

  @override
  String get badgeSpeedStarDesc => 'ਤੇਜ਼ੀ ਦੀ ਚੁਣੌਤੀ ਵਿੱਚ 20 ਜਾਂ ਵੱਧ ਸਹੀ';

  @override
  String get newBadge => 'ਨਵਾਂ ਬੈਜ!';

  @override
  String get yay => 'ਹੁੱਰੇ!';

  @override
  String get forParents => 'ਮਾਪਿਆਂ ਲਈ';

  @override
  String get enterPin => 'ਮਾਪਿਆਂ ਦਾ PIN ਪਾਓ';

  @override
  String get createPin => '4 ਅੰਕਾਂ ਦਾ PIN ਬਣਾਓ';

  @override
  String get confirmPin => 'ਉਹੀ PIN ਫਿਰ ਪਾਓ';

  @override
  String get newPin => 'ਨਵਾਂ 4 ਅੰਕਾਂ ਦਾ PIN ਪਾਓ';

  @override
  String get pinMismatch => 'ਦੋਵੇਂ PIN ਵੱਖਰੇ ਸਨ। ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get pinWrong => 'PIN ਸਹੀ ਨਹੀਂ ਹੈ। ਫਿਰ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get pinForParents => 'ਸਿਰਫ਼ ਵੱਡਿਆਂ ਲਈ';

  @override
  String get pinForgot => 'PIN ਭੁੱਲ ਗਏ? ਫ਼ੋਨ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਇਸ ਐਪ ਦਾ ਡਾਟਾ ਮਿਟਾਉਣ ਨਾਲ PIN ਅਤੇ ਸਾਰੀ ਤਰੱਕੀ ਮਿਟ ਜਾਵੇਗੀ।';

  @override
  String get pinChanged => 'PIN ਬਦਲ ਗਿਆ';

  @override
  String get progress => 'ਤਰੱਕੀ';

  @override
  String get totalSums => 'ਹੱਲ ਕੀਤੇ ਸਵਾਲ';

  @override
  String get accuracy => 'ਸ਼ੁੱਧਤਾ';

  @override
  String get factsMastered => 'ਪੱਕੇ ਸਵਾਲ';

  @override
  String get daysPractised => 'ਅਭਿਆਸ ਦੇ ਦਿਨ';

  @override
  String get accuracyPerTopic => 'ਵਿਸ਼ੇ ਅਨੁਸਾਰ ਸ਼ੁੱਧਤਾ';

  @override
  String get speedOverTime => 'ਹਰ ਸਵਾਲ ਤੇ ਔਸਤ ਸਕਿੰਟ';

  @override
  String get weakFacts => 'ਅਭਿਆਸ ਵਾਲੇ ਸਵਾਲ';

  @override
  String get noWeakFacts => 'ਹੁਣ ਕੁਝ ਵੀ ਔਖਾ ਨਹੀਂ। ਸ਼ਾਬਾਸ਼!';

  @override
  String get noDataYet => 'ਅਜੇ ਅਭਿਆਸ ਨਹੀਂ ਹੋਇਆ।';

  @override
  String triesRight(int n, int pct) {
    return '$n ਕੋਸ਼ਿਸ਼ਾਂ · $pct% ਸਹੀ';
  }

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get sound => 'ਆਵਾਜ਼';

  @override
  String get music => 'ਸੰਗੀਤ';

  @override
  String get dailyReminder => 'ਰੋਜ਼ਾਨਾ ਯਾਦ';

  @override
  String get reminderTime => 'ਯਾਦ ਦਾ ਸਮਾਂ';

  @override
  String get notificationsBlocked => 'ਫ਼ੋਨ ਸੈਟਿੰਗਾਂ ਵਿੱਚ ਇਸ ਐਪ ਦੀਆਂ ਸੂਚਨਾਵਾਂ ਬੰਦ ਹਨ।';

  @override
  String get changePin => 'ਮਾਪਿਆਂ ਦਾ PIN ਬਦਲੋ';

  @override
  String get resetProgress => 'ਤਰੱਕੀ ਮਿਟਾਓ';

  @override
  String resetProgressBody(String name) {
    return 'ਇਸ ਨਾਲ $name ਦੇ ਸਾਰੇ ਅੰਕ, ਸਿੱਕੇ, ਬੈਜ ਅਤੇ ਖੁੱਲ੍ਹੇ ਪੱਧਰ ਮਿਟ ਜਾਣਗੇ।';
  }

  @override
  String get reset => 'ਮਿਟਾਓ';

  @override
  String get cancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get progressReset => 'ਤਰੱਕੀ ਮਿਟਾ ਦਿੱਤੀ';

  @override
  String get removeChild => 'ਇਸ ਬੱਚੇ ਨੂੰ ਹਟਾਓ';

  @override
  String removeChildBody(String name) {
    return '$name ਅਤੇ ਉਹਨਾਂ ਦੀ ਸਾਰੀ ਤਰੱਕੀ ਇਸ ਫ਼ੋਨ ਤੋਂ ਹਟਾਉਣੀ ਹੈ?';
  }

  @override
  String get remove => 'ਹਟਾਓ';

  @override
  String get child => 'ਬੱਚਾ';

  @override
  String get about => 'ਐਪ ਬਾਰੇ';

  @override
  String get aboutBody =>
      'ਇਹ ਐਪ ਜਮਾਤ 1–8 ਦੇ ਬੱਚਿਆਂ ਨੂੰ ਛੋਟੇ, ਮਜ਼ੇਦਾਰ ਰਾਊਂਡਾਂ ਵਿੱਚ ਗਣਿਤ ਦਾ ਅਭਿਆਸ ਕਰਨ ਵਿੱਚ ਮਦਦ ਕਰਦੀ ਹੈ। ਇਹ ਪੂਰੀ ਤਰ੍ਹਾਂ ਆਫ਼ਲਾਈਨ ਚੱਲਦੀ ਹੈ, ਇਸ਼ਤਿਹਾਰ ਨਹੀਂ ਅਤੇ ਖਾਤਾ ਨਹੀਂ ਚਾਹੀਦਾ। ਸਿਰਫ਼ ਬੱਚੇ ਦਾ ਪਹਿਲਾ ਨਾਮ ਅਤੇ ਜਮਾਤ, ਸਿਰਫ਼ ਇਸੇ ਫ਼ੋਨ ਤੇ ਰੱਖੀ ਜਾਂਦੀ ਹੈ।';

  @override
  String version(String v) {
    return 'ਵਰਜਨ $v';
  }

  @override
  String get licenses => 'ਲਾਇਸੈਂਸ';

  @override
  String get close => 'ਬੰਦ ਕਰੋ';

  @override
  String get reminderBody => 'ਅੱਜ ਦੀ ਗਣਿਤ ਚੁਣੌਤੀ ਦਾ ਸਮਾਂ ਹੋ ਗਿਆ!';

  @override
  String get reminderChannel => 'ਰੋਜ਼ਾਨਾ ਯਾਦ';

  @override
  String get lockedLevelSnack => 'ਇਹ ਪੱਧਰ ਖੋਲ੍ਹਣ ਲਈ ਅਭਿਆਸ ਕਰਦੇ ਰਹੋ!';

  @override
  String get hearAgain => 'ਫਿਰ ਸੁਣੋ';
}

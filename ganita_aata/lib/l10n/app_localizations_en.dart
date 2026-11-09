// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ganita Aata';

  @override
  String get chooseLanguage => 'Choose a language';

  @override
  String get continueBtn => 'Continue';

  @override
  String get welcome => 'Welcome!';

  @override
  String get profileSetupTitle => 'Who is playing?';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get childName => 'Child\'s first name';

  @override
  String get nameRequired => 'Please type a name';

  @override
  String get schoolClass => 'Class';

  @override
  String classN(int n) {
    return 'Class $n';
  }

  @override
  String classRange(int from, int to) {
    return 'Class $from–$to';
  }

  @override
  String get chooseAvatar => 'Choose an avatar';

  @override
  String get save => 'Save';

  @override
  String get addChild => 'Add child';

  @override
  String get switchChild => 'Who is playing?';

  @override
  String helloName(String name) {
    return 'Hello, $name!';
  }

  @override
  String get greetingSub => 'Ready to play with numbers?';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get dailyChallengeDesc => '10 sums – the same for everyone today!';

  @override
  String get dailyDone => 'Done for today! Come back tomorrow.';

  @override
  String get start => 'Start';

  @override
  String get playAgainToday => 'Play again';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count days', one: '1 day');
    return '$_temp0';
  }

  @override
  String get streak => 'Streak';

  @override
  String get coins => 'Coins';

  @override
  String get play => 'Play';

  @override
  String get games => 'Games';

  @override
  String currentTopic(String topic) {
    return 'Topic: $topic';
  }

  @override
  String get change => 'Change';

  @override
  String get gameBalloon => 'Balloon Pop';

  @override
  String get gameBalloonDesc => 'Pop the balloon with the right answer';

  @override
  String get gameRace => 'Race Car';

  @override
  String get gameRaceDesc => 'Right answers make your car zoom';

  @override
  String get gameTreasure => 'Treasure Hunt';

  @override
  String get gameTreasureDesc => '5 right in a row opens a chest';

  @override
  String get gameTables => 'Tables Master';

  @override
  String get gameTablesDesc => 'Learn and practise tables 2–20';

  @override
  String get gameSpeed => 'Speed Challenge';

  @override
  String get gameSpeedDesc => 'How many in 60 seconds?';

  @override
  String get levelMap => 'Level map';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String get locked => 'Locked';

  @override
  String get lockedHint => 'Score above 85% in the topic before this one to open it.';

  @override
  String get chooseTopic => 'Choose a topic';

  @override
  String get chooseGame => 'Choose a game';

  @override
  String get topic_num100 => 'Numbers up to 100';

  @override
  String get topic_add1 => 'Single-digit addition';

  @override
  String get topic_sub1 => 'Single-digit subtraction';

  @override
  String get topic_add2 => '2-digit addition';

  @override
  String get topic_sub2 => '2-digit subtraction';

  @override
  String get topic_tab2_5 => 'Tables 2–5';

  @override
  String get topic_tab6_10 => 'Tables 6–10';

  @override
  String get topic_add3 => '3-digit addition';

  @override
  String get topic_sub3 => '3-digit subtraction';

  @override
  String get topic_div1 => 'Simple division';

  @override
  String get topic_tab11_20 => 'Tables 11–20';

  @override
  String get topic_mul21 => '2-digit × 1-digit';

  @override
  String get topic_divRem => 'Division with remainder';

  @override
  String get topic_mixed => 'Mixed operations';

  @override
  String get topic_squares => 'Squares 1–30';

  @override
  String get topic_cubes => 'Cubes 1–15';

  @override
  String get topic_percent => 'Percentages';

  @override
  String get topic_fractions => 'Simple fractions';

  @override
  String qAfter(int n) {
    return 'What comes after $n?';
  }

  @override
  String qBefore(int n) {
    return 'What comes before $n?';
  }

  @override
  String qTenMore(int n) {
    return '10 more than $n';
  }

  @override
  String qTenLess(int n) {
    return '10 less than $n';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$p% of $n';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$fraction of $n';
  }

  @override
  String get remainderShort => 'R';

  @override
  String get score => 'Score';

  @override
  String secondsShort(int n) {
    return '${n}s';
  }

  @override
  String get quitGameTitle => 'Stop this round?';

  @override
  String get quitGameBody => 'Coins from this round will not be added.';

  @override
  String get keepPlaying => 'Keep playing';

  @override
  String get stop => 'Stop';

  @override
  String answerIs(String answer) {
    return 'The answer is $answer';
  }

  @override
  String get praise => 'Super!|Well done!|Excellent!|Great job!|You\'re a star!|Wonderful!';

  @override
  String get encourage =>
      'Try again, you can do it!|Almost! Keep going!|Good try! Here is the next one.|Nice effort! You are learning!';

  @override
  String get getReady => 'Get ready!';

  @override
  String get go => 'Go!';

  @override
  String get you => 'You';

  @override
  String get computer => 'Computer';

  @override
  String get raceWon => 'You won the race!';

  @override
  String get raceLost => 'Great race! Practise a little more to win next time.';

  @override
  String chestOpened(int n) {
    return 'Chest opened! +$n coins';
  }

  @override
  String get chestStreakReset => 'Start a new set of 5!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chests opened',
      one: '1 chest opened',
      zero: 'No chests yet',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'Best: $n';
  }

  @override
  String get newBest => 'New personal best!';

  @override
  String get clear => 'Clear';

  @override
  String get pickTable => 'Pick a table';

  @override
  String get learn => 'Learn';

  @override
  String get quiz => 'Quiz';

  @override
  String tableOf(int n) {
    return 'Table of $n';
  }

  @override
  String get listen => 'Listen';

  @override
  String get pause => 'Pause';

  @override
  String get startQuiz => 'Start quiz';

  @override
  String get mastered => 'Mastered';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'Round complete!';

  @override
  String get correctLabel => 'Correct';

  @override
  String get practiseLabel => 'To practise';

  @override
  String get practiseThese => 'Let\'s practise these';

  @override
  String coinsEarned(int n) {
    return '+$n coins';
  }

  @override
  String get playAgain => 'Play again';

  @override
  String get home => 'Home';

  @override
  String get resultMsg3 => 'Amazing! You are a maths star!';

  @override
  String get resultMsg2 => 'Great work!';

  @override
  String get resultMsg1 => 'Good job! Keep practising!';

  @override
  String get resultMsg0 => 'Good try! Every round makes you better!';

  @override
  String get allCorrect => 'All correct!';

  @override
  String newTopicUnlocked(String topic) {
    return 'New topic open: $topic';
  }

  @override
  String streakNow(String days) {
    return 'Daily streak: $days';
  }

  @override
  String get shop => 'Shop';

  @override
  String get avatars => 'Avatars';

  @override
  String get carColours => 'Car colours';

  @override
  String get balloonThemes => 'Balloons';

  @override
  String get buy => 'Buy';

  @override
  String get use => 'Use';

  @override
  String get inUse => 'In use';

  @override
  String needMoreCoins(int n) {
    return 'Play more to earn $n more coins!';
  }

  @override
  String get bought => 'Yours now!';

  @override
  String get color_red => 'Red';

  @override
  String get color_blue => 'Blue';

  @override
  String get color_green => 'Green';

  @override
  String get color_yellow => 'Yellow';

  @override
  String get color_purple => 'Purple';

  @override
  String get color_orange => 'Orange';

  @override
  String get color_pink => 'Pink';

  @override
  String get theme_rainbow => 'Rainbow';

  @override
  String get theme_pastel => 'Pastel';

  @override
  String get theme_ocean => 'Ocean';

  @override
  String get theme_sunset => 'Sunset';

  @override
  String get theme_candy => 'Candy';

  @override
  String get badges => 'Badges';

  @override
  String badgeTableMaster(int n) {
    return 'Table $n Master';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return 'Master every line of the $n table';
  }

  @override
  String get badgeStreak7 => '7-day streak';

  @override
  String get badgeStreak7Desc => 'Do the Daily Challenge 7 days in a row';

  @override
  String get badgeStreak30 => '30-day streak';

  @override
  String get badgeStreak30Desc => 'Do the Daily Challenge 30 days in a row';

  @override
  String get badgeDay100 => '100 sums in a day';

  @override
  String get badgeDay100Desc => 'Solve 100 sums in one day';

  @override
  String get badgeSpeedStar => 'Speed Star';

  @override
  String get badgeSpeedStarDesc => '20 or more right in a Speed Challenge';

  @override
  String get newBadge => 'New badge!';

  @override
  String get yay => 'Yay!';

  @override
  String get forParents => 'For parents';

  @override
  String get enterPin => 'Enter parent PIN';

  @override
  String get createPin => 'Create a 4-digit parent PIN';

  @override
  String get confirmPin => 'Enter the same PIN again';

  @override
  String get newPin => 'Enter a new 4-digit PIN';

  @override
  String get pinMismatch => 'The PINs were different. Please try again.';

  @override
  String get pinWrong => 'That PIN is not right. Please try again.';

  @override
  String get pinForParents => 'For grown-ups only';

  @override
  String get pinForgot =>
      'Forgot the PIN? Clearing this app\'s storage in phone settings resets the PIN and all progress.';

  @override
  String get pinChanged => 'PIN changed';

  @override
  String get progress => 'Progress';

  @override
  String get totalSums => 'Sums solved';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get factsMastered => 'Facts mastered';

  @override
  String get daysPractised => 'Days practised';

  @override
  String get accuracyPerTopic => 'Accuracy per topic';

  @override
  String get speedOverTime => 'Average seconds per sum';

  @override
  String get weakFacts => 'Facts to practise';

  @override
  String get noWeakFacts => 'Nothing difficult right now. Well done!';

  @override
  String get noDataYet => 'No practice yet.';

  @override
  String triesRight(int n, int pct) {
    return '$n tries · $pct% right';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get sound => 'Sound';

  @override
  String get dailyReminder => 'Daily reminder';

  @override
  String get reminderTime => 'Reminder time';

  @override
  String get notificationsBlocked => 'Notifications are turned off for this app in the phone settings.';

  @override
  String get changePin => 'Change parent PIN';

  @override
  String get resetProgress => 'Reset progress';

  @override
  String resetProgressBody(String name) {
    return 'This clears all of $name\'s scores, coins, badges and opened levels.';
  }

  @override
  String get reset => 'Reset';

  @override
  String get cancel => 'Cancel';

  @override
  String get progressReset => 'Progress cleared';

  @override
  String get removeChild => 'Remove this child';

  @override
  String removeChildBody(String name) {
    return 'Remove $name and all of their progress from this phone?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get child => 'Child';

  @override
  String get about => 'About';

  @override
  String get aboutBody =>
      'Ganita Aata helps children of Classes 1–8 practise maths in short, fun rounds. It works fully offline, has no ads and needs no account. Only the child\'s first name and class are kept, and only on this phone.';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get licenses => 'Licences';

  @override
  String get close => 'Close';

  @override
  String get reminderBody => 'Time for today\'s Ganita Aata challenge!';

  @override
  String get reminderChannel => 'Daily reminder';

  @override
  String get lockedLevelSnack => 'Keep practising to open this level!';

  @override
  String get hearAgain => 'Hear again';
}

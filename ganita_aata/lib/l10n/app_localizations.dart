import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_or.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('or'),
    Locale('pa'),
    Locale('ta'),
    Locale('te'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ganita Aata'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get chooseLanguage;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Who is playing?'**
  String get profileSetupTitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @childName.
  ///
  /// In en, this message translates to:
  /// **'Child\'s first name'**
  String get childName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please type a name'**
  String get nameRequired;

  /// No description provided for @schoolClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get schoolClass;

  /// No description provided for @classN.
  ///
  /// In en, this message translates to:
  /// **'Class {n}'**
  String classN(int n);

  /// No description provided for @classRange.
  ///
  /// In en, this message translates to:
  /// **'Class {from}–{to}'**
  String classRange(int from, int to);

  /// No description provided for @chooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get chooseAvatar;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChild;

  /// No description provided for @switchChild.
  ///
  /// In en, this message translates to:
  /// **'Who is playing?'**
  String get switchChild;

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloName(String name);

  /// No description provided for @greetingSub.
  ///
  /// In en, this message translates to:
  /// **'Ready to play with numbers?'**
  String get greetingSub;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'10 sums – the same for everyone today!'**
  String get dailyChallengeDesc;

  /// No description provided for @dailyDone.
  ///
  /// In en, this message translates to:
  /// **'Done for today! Come back tomorrow.'**
  String get dailyDone;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @playAgainToday.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgainToday;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String streakDays(int count);

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @games.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get games;

  /// No description provided for @currentTopic.
  ///
  /// In en, this message translates to:
  /// **'Topic: {topic}'**
  String currentTopic(String topic);

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @gameBalloon.
  ///
  /// In en, this message translates to:
  /// **'Balloon Pop'**
  String get gameBalloon;

  /// No description provided for @gameBalloonDesc.
  ///
  /// In en, this message translates to:
  /// **'Pop the balloon with the right answer'**
  String get gameBalloonDesc;

  /// No description provided for @gameRace.
  ///
  /// In en, this message translates to:
  /// **'Race Car'**
  String get gameRace;

  /// No description provided for @gameRaceDesc.
  ///
  /// In en, this message translates to:
  /// **'Right answers make your car zoom'**
  String get gameRaceDesc;

  /// No description provided for @gameTreasure.
  ///
  /// In en, this message translates to:
  /// **'Treasure Hunt'**
  String get gameTreasure;

  /// No description provided for @gameTreasureDesc.
  ///
  /// In en, this message translates to:
  /// **'5 right in a row opens a chest'**
  String get gameTreasureDesc;

  /// No description provided for @gameTables.
  ///
  /// In en, this message translates to:
  /// **'Tables Master'**
  String get gameTables;

  /// No description provided for @gameTablesDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn and practise tables 2–20'**
  String get gameTablesDesc;

  /// No description provided for @gameSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed Challenge'**
  String get gameSpeed;

  /// No description provided for @gameSpeedDesc.
  ///
  /// In en, this message translates to:
  /// **'How many in 60 seconds?'**
  String get gameSpeedDesc;

  /// No description provided for @levelMap.
  ///
  /// In en, this message translates to:
  /// **'Level map'**
  String get levelMap;

  /// No description provided for @levelN.
  ///
  /// In en, this message translates to:
  /// **'Level {n}'**
  String levelN(int n);

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @lockedHint.
  ///
  /// In en, this message translates to:
  /// **'Score above 85% in the topic before this one to open it.'**
  String get lockedHint;

  /// No description provided for @chooseTopic.
  ///
  /// In en, this message translates to:
  /// **'Choose a topic'**
  String get chooseTopic;

  /// No description provided for @chooseGame.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get chooseGame;

  /// No description provided for @topic_num100.
  ///
  /// In en, this message translates to:
  /// **'Numbers up to 100'**
  String get topic_num100;

  /// No description provided for @topic_add1.
  ///
  /// In en, this message translates to:
  /// **'Single-digit addition'**
  String get topic_add1;

  /// No description provided for @topic_sub1.
  ///
  /// In en, this message translates to:
  /// **'Single-digit subtraction'**
  String get topic_sub1;

  /// No description provided for @topic_add2.
  ///
  /// In en, this message translates to:
  /// **'2-digit addition'**
  String get topic_add2;

  /// No description provided for @topic_sub2.
  ///
  /// In en, this message translates to:
  /// **'2-digit subtraction'**
  String get topic_sub2;

  /// No description provided for @topic_tab2_5.
  ///
  /// In en, this message translates to:
  /// **'Tables 2–5'**
  String get topic_tab2_5;

  /// No description provided for @topic_tab6_10.
  ///
  /// In en, this message translates to:
  /// **'Tables 6–10'**
  String get topic_tab6_10;

  /// No description provided for @topic_add3.
  ///
  /// In en, this message translates to:
  /// **'3-digit addition'**
  String get topic_add3;

  /// No description provided for @topic_sub3.
  ///
  /// In en, this message translates to:
  /// **'3-digit subtraction'**
  String get topic_sub3;

  /// No description provided for @topic_div1.
  ///
  /// In en, this message translates to:
  /// **'Simple division'**
  String get topic_div1;

  /// No description provided for @topic_tab11_20.
  ///
  /// In en, this message translates to:
  /// **'Tables 11–20'**
  String get topic_tab11_20;

  /// No description provided for @topic_mul21.
  ///
  /// In en, this message translates to:
  /// **'2-digit × 1-digit'**
  String get topic_mul21;

  /// No description provided for @topic_divRem.
  ///
  /// In en, this message translates to:
  /// **'Division with remainder'**
  String get topic_divRem;

  /// No description provided for @topic_mixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed operations'**
  String get topic_mixed;

  /// No description provided for @topic_squares.
  ///
  /// In en, this message translates to:
  /// **'Squares 1–30'**
  String get topic_squares;

  /// No description provided for @topic_cubes.
  ///
  /// In en, this message translates to:
  /// **'Cubes 1–15'**
  String get topic_cubes;

  /// No description provided for @topic_percent.
  ///
  /// In en, this message translates to:
  /// **'Percentages'**
  String get topic_percent;

  /// No description provided for @topic_fractions.
  ///
  /// In en, this message translates to:
  /// **'Simple fractions'**
  String get topic_fractions;

  /// No description provided for @qAfter.
  ///
  /// In en, this message translates to:
  /// **'What comes after {n}?'**
  String qAfter(int n);

  /// No description provided for @qBefore.
  ///
  /// In en, this message translates to:
  /// **'What comes before {n}?'**
  String qBefore(int n);

  /// No description provided for @qTenMore.
  ///
  /// In en, this message translates to:
  /// **'10 more than {n}'**
  String qTenMore(int n);

  /// No description provided for @qTenLess.
  ///
  /// In en, this message translates to:
  /// **'10 less than {n}'**
  String qTenLess(int n);

  /// No description provided for @qPercentOf.
  ///
  /// In en, this message translates to:
  /// **'{p}% of {n}'**
  String qPercentOf(int p, int n);

  /// No description provided for @qFractionOf.
  ///
  /// In en, this message translates to:
  /// **'{fraction} of {n}'**
  String qFractionOf(String fraction, int n);

  /// No description provided for @remainderShort.
  ///
  /// In en, this message translates to:
  /// **'R'**
  String get remainderShort;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{n}s'**
  String secondsShort(int n);

  /// No description provided for @quitGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop this round?'**
  String get quitGameTitle;

  /// No description provided for @quitGameBody.
  ///
  /// In en, this message translates to:
  /// **'Coins from this round will not be added.'**
  String get quitGameBody;

  /// No description provided for @keepPlaying.
  ///
  /// In en, this message translates to:
  /// **'Keep playing'**
  String get keepPlaying;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @answerIs.
  ///
  /// In en, this message translates to:
  /// **'The answer is {answer}'**
  String answerIs(String answer);

  /// No description provided for @praise.
  ///
  /// In en, this message translates to:
  /// **'Super!|Well done!|Excellent!|Great job!|You\'re a star!|Wonderful!'**
  String get praise;

  /// No description provided for @encourage.
  ///
  /// In en, this message translates to:
  /// **'Try again, you can do it!|Almost! Keep going!|Good try! Here is the next one.|Nice effort! You are learning!'**
  String get encourage;

  /// No description provided for @getReady.
  ///
  /// In en, this message translates to:
  /// **'Get ready!'**
  String get getReady;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go!'**
  String get go;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @computer.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get computer;

  /// No description provided for @raceWon.
  ///
  /// In en, this message translates to:
  /// **'You won the race!'**
  String get raceWon;

  /// No description provided for @raceLost.
  ///
  /// In en, this message translates to:
  /// **'Great race! Practise a little more to win next time.'**
  String get raceLost;

  /// No description provided for @chestOpened.
  ///
  /// In en, this message translates to:
  /// **'Chest opened! +{n} coins'**
  String chestOpened(int n);

  /// No description provided for @chestStreakReset.
  ///
  /// In en, this message translates to:
  /// **'Start a new set of 5!'**
  String get chestStreakReset;

  /// No description provided for @chestsOpened.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No chests yet} =1{1 chest opened} other{{count} chests opened}}'**
  String chestsOpened(int count);

  /// No description provided for @personalBest.
  ///
  /// In en, this message translates to:
  /// **'Best: {n}'**
  String personalBest(int n);

  /// No description provided for @newBest.
  ///
  /// In en, this message translates to:
  /// **'New personal best!'**
  String get newBest;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @pickTable.
  ///
  /// In en, this message translates to:
  /// **'Pick a table'**
  String get pickTable;

  /// No description provided for @learn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learn;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @tableOf.
  ///
  /// In en, this message translates to:
  /// **'Table of {n}'**
  String tableOf(int n);

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start quiz'**
  String get startQuiz;

  /// No description provided for @mastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get mastered;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'{n} / {total}'**
  String questionOf(int n, int total);

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Round complete!'**
  String get resultTitle;

  /// No description provided for @correctLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctLabel;

  /// No description provided for @practiseLabel.
  ///
  /// In en, this message translates to:
  /// **'To practise'**
  String get practiseLabel;

  /// No description provided for @practiseThese.
  ///
  /// In en, this message translates to:
  /// **'Let\'s practise these'**
  String get practiseThese;

  /// No description provided for @coinsEarned.
  ///
  /// In en, this message translates to:
  /// **'+{n} coins'**
  String coinsEarned(int n);

  /// No description provided for @playAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @resultMsg3.
  ///
  /// In en, this message translates to:
  /// **'Amazing! You are a maths star!'**
  String get resultMsg3;

  /// No description provided for @resultMsg2.
  ///
  /// In en, this message translates to:
  /// **'Great work!'**
  String get resultMsg2;

  /// No description provided for @resultMsg1.
  ///
  /// In en, this message translates to:
  /// **'Good job! Keep practising!'**
  String get resultMsg1;

  /// No description provided for @resultMsg0.
  ///
  /// In en, this message translates to:
  /// **'Good try! Every round makes you better!'**
  String get resultMsg0;

  /// No description provided for @allCorrect.
  ///
  /// In en, this message translates to:
  /// **'All correct!'**
  String get allCorrect;

  /// No description provided for @newTopicUnlocked.
  ///
  /// In en, this message translates to:
  /// **'New topic open: {topic}'**
  String newTopicUnlocked(String topic);

  /// No description provided for @streakNow.
  ///
  /// In en, this message translates to:
  /// **'Daily streak: {days}'**
  String streakNow(String days);

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @avatars.
  ///
  /// In en, this message translates to:
  /// **'Avatars'**
  String get avatars;

  /// No description provided for @carColours.
  ///
  /// In en, this message translates to:
  /// **'Car colours'**
  String get carColours;

  /// No description provided for @balloonThemes.
  ///
  /// In en, this message translates to:
  /// **'Balloons'**
  String get balloonThemes;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @inUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get inUse;

  /// No description provided for @needMoreCoins.
  ///
  /// In en, this message translates to:
  /// **'Play more to earn {n} more coins!'**
  String needMoreCoins(int n);

  /// No description provided for @bought.
  ///
  /// In en, this message translates to:
  /// **'Yours now!'**
  String get bought;

  /// No description provided for @color_red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get color_red;

  /// No description provided for @color_blue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get color_blue;

  /// No description provided for @color_green.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get color_green;

  /// No description provided for @color_yellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get color_yellow;

  /// No description provided for @color_purple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get color_purple;

  /// No description provided for @color_orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get color_orange;

  /// No description provided for @color_pink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get color_pink;

  /// No description provided for @color_black.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get color_black;

  /// No description provided for @theme_rainbow.
  ///
  /// In en, this message translates to:
  /// **'Rainbow'**
  String get theme_rainbow;

  /// No description provided for @theme_pastel.
  ///
  /// In en, this message translates to:
  /// **'Pastel'**
  String get theme_pastel;

  /// No description provided for @theme_ocean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get theme_ocean;

  /// No description provided for @theme_sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get theme_sunset;

  /// No description provided for @theme_candy.
  ///
  /// In en, this message translates to:
  /// **'Candy'**
  String get theme_candy;

  /// No description provided for @badges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get badges;

  /// No description provided for @badgeTableMaster.
  ///
  /// In en, this message translates to:
  /// **'Table {n} Master'**
  String badgeTableMaster(int n);

  /// No description provided for @badgeTableMasterDesc.
  ///
  /// In en, this message translates to:
  /// **'Master every line of the {n} table'**
  String badgeTableMasterDesc(int n);

  /// No description provided for @badgeStreak7.
  ///
  /// In en, this message translates to:
  /// **'7-day streak'**
  String get badgeStreak7;

  /// No description provided for @badgeStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Do the Daily Challenge 7 days in a row'**
  String get badgeStreak7Desc;

  /// No description provided for @badgeStreak30.
  ///
  /// In en, this message translates to:
  /// **'30-day streak'**
  String get badgeStreak30;

  /// No description provided for @badgeStreak30Desc.
  ///
  /// In en, this message translates to:
  /// **'Do the Daily Challenge 30 days in a row'**
  String get badgeStreak30Desc;

  /// No description provided for @badgeDay100.
  ///
  /// In en, this message translates to:
  /// **'100 sums in a day'**
  String get badgeDay100;

  /// No description provided for @badgeDay100Desc.
  ///
  /// In en, this message translates to:
  /// **'Solve 100 sums in one day'**
  String get badgeDay100Desc;

  /// No description provided for @badgeSpeedStar.
  ///
  /// In en, this message translates to:
  /// **'Speed Star'**
  String get badgeSpeedStar;

  /// No description provided for @badgeSpeedStarDesc.
  ///
  /// In en, this message translates to:
  /// **'20 or more right in a Speed Challenge'**
  String get badgeSpeedStarDesc;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'New badge!'**
  String get newBadge;

  /// No description provided for @yay.
  ///
  /// In en, this message translates to:
  /// **'Yay!'**
  String get yay;

  /// No description provided for @forParents.
  ///
  /// In en, this message translates to:
  /// **'For parents'**
  String get forParents;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter parent PIN'**
  String get enterPin;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit parent PIN'**
  String get createPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the same PIN again'**
  String get confirmPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'Enter a new 4-digit PIN'**
  String get newPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs were different. Please try again.'**
  String get pinMismatch;

  /// No description provided for @pinWrong.
  ///
  /// In en, this message translates to:
  /// **'That PIN is not right. Please try again.'**
  String get pinWrong;

  /// No description provided for @pinForParents.
  ///
  /// In en, this message translates to:
  /// **'For grown-ups only'**
  String get pinForParents;

  /// No description provided for @pinForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot the PIN? Clearing this app\'s storage in phone settings resets the PIN and all progress.'**
  String get pinForgot;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get pinChanged;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @totalSums.
  ///
  /// In en, this message translates to:
  /// **'Sums solved'**
  String get totalSums;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @factsMastered.
  ///
  /// In en, this message translates to:
  /// **'Facts mastered'**
  String get factsMastered;

  /// No description provided for @daysPractised.
  ///
  /// In en, this message translates to:
  /// **'Days practised'**
  String get daysPractised;

  /// No description provided for @accuracyPerTopic.
  ///
  /// In en, this message translates to:
  /// **'Accuracy per topic'**
  String get accuracyPerTopic;

  /// No description provided for @speedOverTime.
  ///
  /// In en, this message translates to:
  /// **'Average seconds per sum'**
  String get speedOverTime;

  /// No description provided for @weakFacts.
  ///
  /// In en, this message translates to:
  /// **'Facts to practise'**
  String get weakFacts;

  /// No description provided for @noWeakFacts.
  ///
  /// In en, this message translates to:
  /// **'Nothing difficult right now. Well done!'**
  String get noWeakFacts;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No practice yet.'**
  String get noDataYet;

  /// No description provided for @triesRight.
  ///
  /// In en, this message translates to:
  /// **'{n} tries · {pct}% right'**
  String triesRight(int n, int pct);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminder;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get reminderTime;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for this app in the phone settings.'**
  String get notificationsBlocked;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change parent PIN'**
  String get changePin;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetProgressBody.
  ///
  /// In en, this message translates to:
  /// **'This clears all of {name}\'s scores, coins, badges and opened levels.'**
  String resetProgressBody(String name);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @progressReset.
  ///
  /// In en, this message translates to:
  /// **'Progress cleared'**
  String get progressReset;

  /// No description provided for @removeChild.
  ///
  /// In en, this message translates to:
  /// **'Remove this child'**
  String get removeChild;

  /// No description provided for @removeChildBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} and all of their progress from this phone?'**
  String removeChildBody(String name);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutBody.
  ///
  /// In en, this message translates to:
  /// **'Ganita Aata helps children of Classes 1–8 practise maths in short, fun rounds. It works fully offline, has no ads and needs no account. Only the child\'s first name and class are kept, and only on this phone.'**
  String get aboutBody;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {v}'**
  String version(String v);

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licenses;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @reminderBody.
  ///
  /// In en, this message translates to:
  /// **'Time for today\'s Ganita Aata challenge!'**
  String get reminderBody;

  /// No description provided for @reminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get reminderChannel;

  /// No description provided for @lockedLevelSnack.
  ///
  /// In en, this message translates to:
  /// **'Keep practising to open this level!'**
  String get lockedLevelSnack;

  /// No description provided for @hearAgain.
  ///
  /// In en, this message translates to:
  /// **'Hear again'**
  String get hearAgain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'gu', 'hi', 'kn', 'ml', 'mr', 'or', 'pa', 'ta', 'te', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'or':
      return AppLocalizationsOr();
    case 'pa':
      return AppLocalizationsPa();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

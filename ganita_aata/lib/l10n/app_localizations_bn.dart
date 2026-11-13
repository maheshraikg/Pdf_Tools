// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'অঙ্কের খেলা';

  @override
  String get chooseLanguage => 'ভাষা বেছে নাও';

  @override
  String get continueBtn => 'এগিয়ে চলো';

  @override
  String get welcome => 'স্বাগতম!';

  @override
  String get profileSetupTitle => 'কে খেলছে?';

  @override
  String get editProfile => 'তথ্য বদলাও';

  @override
  String get childName => 'শিশুর প্রথম নাম';

  @override
  String get nameRequired => 'অনুগ্রহ করে নাম লেখো';

  @override
  String get schoolClass => 'শ্রেণি';

  @override
  String classN(int n) {
    return 'শ্রেণি $n';
  }

  @override
  String classRange(int from, int to) {
    return 'শ্রেণি $from–$to';
  }

  @override
  String get chooseAvatar => 'ছবি বেছে নাও';

  @override
  String get save => 'সংরক্ষণ করো';

  @override
  String get addChild => 'শিশু যোগ করো';

  @override
  String get switchChild => 'কে খেলছে?';

  @override
  String helloName(String name) {
    return 'নমস্কার, $name!';
  }

  @override
  String get greetingSub => 'সংখ্যা নিয়ে খেলতে তৈরি?';

  @override
  String get dailyChallenge => 'আজকের চ্যালেঞ্জ';

  @override
  String get dailyChallengeDesc => '10টি অঙ্ক – আজ সবার জন্য একই!';

  @override
  String get dailyDone => 'আজকেরটা শেষ! কাল আবার এসো।';

  @override
  String get start => 'শুরু করো';

  @override
  String get playAgainToday => 'আবার খেলো';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count দিন', one: '1 দিন');
    return '$_temp0';
  }

  @override
  String get streak => 'টানা';

  @override
  String get coins => 'কয়েন';

  @override
  String get play => 'খেলো';

  @override
  String get games => 'খেলা';

  @override
  String currentTopic(String topic) {
    return 'বিষয়: $topic';
  }

  @override
  String get change => 'বদলাও';

  @override
  String get gameBalloon => 'বেলুন ফাটাও';

  @override
  String get gameBalloonDesc => 'সঠিক উত্তরের বেলুন ফাটাও';

  @override
  String get gameRace => 'গাড়ির রেস';

  @override
  String get gameRaceDesc => 'সঠিক উত্তরে তোমার গাড়ি ছুটবে';

  @override
  String get gameTreasure => 'গুপ্তধনের খোঁজ';

  @override
  String get gameTreasureDesc => 'টানা 5টি সঠিক উত্তরে সিন্দুক খোলে';

  @override
  String get gameTables => 'নামতা মাস্টার';

  @override
  String get gameTablesDesc => '2–20 এর নামতা শেখো ও অভ্যাস করো';

  @override
  String get gameSpeed => 'গতির চ্যালেঞ্জ';

  @override
  String get gameSpeedDesc => '60 সেকেন্ডে কতগুলো?';

  @override
  String get levelMap => 'লেভেলের মানচিত্র';

  @override
  String levelN(int n) {
    return 'লেভেল $n';
  }

  @override
  String get locked => 'বন্ধ';

  @override
  String get lockedHint => 'এটি খুলতে আগের বিষয়ে 85%-এর বেশি সঠিক করো।';

  @override
  String get chooseTopic => 'বিষয় বেছে নাও';

  @override
  String get chooseGame => 'খেলা বেছে নাও';

  @override
  String get topic_num100 => '100 পর্যন্ত সংখ্যা';

  @override
  String get topic_add1 => 'এক অঙ্কের যোগ';

  @override
  String get topic_sub1 => 'এক অঙ্কের বিয়োগ';

  @override
  String get topic_add2 => 'দুই অঙ্কের যোগ';

  @override
  String get topic_sub2 => 'দুই অঙ্কের বিয়োগ';

  @override
  String get topic_tab2_5 => '2–5 এর নামতা';

  @override
  String get topic_tab6_10 => '6–10 এর নামতা';

  @override
  String get topic_add3 => 'তিন অঙ্কের যোগ';

  @override
  String get topic_sub3 => 'তিন অঙ্কের বিয়োগ';

  @override
  String get topic_div1 => 'সহজ ভাগ';

  @override
  String get topic_tab11_20 => '11–20 এর নামতা';

  @override
  String get topic_mul21 => 'দুই অঙ্ক × এক অঙ্ক';

  @override
  String get topic_divRem => 'ভাগশেষ সহ ভাগ';

  @override
  String get topic_mixed => 'মিশ্র প্রক্রিয়া';

  @override
  String get topic_squares => '1–30 এর বর্গ';

  @override
  String get topic_cubes => '1–15 এর ঘন';

  @override
  String get topic_percent => 'শতকরা';

  @override
  String get topic_fractions => 'সহজ ভগ্নাংশ';

  @override
  String qAfter(int n) {
    return '$n-এর পরে কোন সংখ্যা আসে?';
  }

  @override
  String qBefore(int n) {
    return '$n-এর আগে কোন সংখ্যা আসে?';
  }

  @override
  String qTenMore(int n) {
    return '$n-এর চেয়ে 10 বেশি';
  }

  @override
  String qTenLess(int n) {
    return '$n-এর চেয়ে 10 কম';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n-এর $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n-এর $fraction';
  }

  @override
  String get remainderShort => 'ভা';

  @override
  String get score => 'স্কোর';

  @override
  String secondsShort(int n) {
    return '$n সে';
  }

  @override
  String get quitGameTitle => 'এই রাউন্ড থামাবে?';

  @override
  String get quitGameBody => 'এই রাউন্ডের কয়েন যোগ হবে না।';

  @override
  String get keepPlaying => 'খেলা চালিয়ে যাও';

  @override
  String get stop => 'থামাও';

  @override
  String answerIs(String answer) {
    return 'উত্তর হলো $answer';
  }

  @override
  String get praise => 'দারুণ!|খুব ভালো!|চমৎকার!|শাবাশ!|তুমি তো তারকা!|অসাধারণ!';

  @override
  String get encourage =>
      'আবার চেষ্টা করো, তুমি পারবে!|প্রায় হয়ে গেছে! চালিয়ে যাও!|ভালো চেষ্টা! এই নাও পরেরটা।|সুন্দর চেষ্টা! তুমি শিখছ!';

  @override
  String get getReady => 'তৈরি হও!';

  @override
  String get go => 'চলো!';

  @override
  String get you => 'তুমি';

  @override
  String get computer => 'কম্পিউটার';

  @override
  String get raceWon => 'তুমি রেস জিতেছ!';

  @override
  String get raceLost => 'দারুণ রেস! আরেকটু অভ্যাস করলে পরের বার জিতবে।';

  @override
  String chestOpened(int n) {
    return 'সিন্দুক খুলেছে! +$n কয়েন';
  }

  @override
  String get chestStreakReset => 'আবার 5 শুরু করি!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি সিন্দুক খুলেছে',
      one: '1টি সিন্দুক খুলেছে',
      zero: 'এখনও কোনো সিন্দুক নেই',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'সেরা: $n';
  }

  @override
  String get newBest => 'নতুন রেকর্ড!';

  @override
  String get clear => 'মুছে ফেলো';

  @override
  String get pickTable => 'নামতা বেছে নাও';

  @override
  String get learn => 'শেখো';

  @override
  String get quiz => 'কুইজ';

  @override
  String tableOf(int n) {
    return '$n এর নামতা';
  }

  @override
  String get listen => 'শোনো';

  @override
  String get pause => 'থামাও';

  @override
  String get startQuiz => 'কুইজ শুরু করো';

  @override
  String get mastered => 'শেখা হয়েছে';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'রাউন্ড শেষ!';

  @override
  String get correctLabel => 'সঠিক';

  @override
  String get practiseLabel => 'অভ্যাসের জন্য';

  @override
  String get practiseThese => 'চলো এগুলো অভ্যাস করি';

  @override
  String coinsEarned(int n) {
    return '+$n কয়েন';
  }

  @override
  String get playAgain => 'আবার খেলো';

  @override
  String get home => 'হোম';

  @override
  String get resultMsg3 => 'অসাধারণ! তুমি অঙ্কের তারকা!';

  @override
  String get resultMsg2 => 'খুব ভালো কাজ!';

  @override
  String get resultMsg1 => 'ভালো হয়েছে! অভ্যাস চালিয়ে যাও!';

  @override
  String get resultMsg0 => 'ভালো চেষ্টা! প্রতি রাউন্ডে তুমি আরও ভালো হবে!';

  @override
  String get allCorrect => 'সব সঠিক!';

  @override
  String newTopicUnlocked(String topic) {
    return 'নতুন বিষয় খুলেছে: $topic';
  }

  @override
  String streakNow(String days) {
    return 'টানা দিন: $days';
  }

  @override
  String get shop => 'দোকান';

  @override
  String get avatars => 'ছবি';

  @override
  String get carColours => 'গাড়ির রং';

  @override
  String get balloonThemes => 'বেলুন';

  @override
  String get buy => 'কেনো';

  @override
  String get use => 'ব্যবহার করো';

  @override
  String get inUse => 'ব্যবহার হচ্ছে';

  @override
  String needMoreCoins(int n) {
    return 'আরও $nটি কয়েন পেতে খেলো!';
  }

  @override
  String get bought => 'এখন এটা তোমার!';

  @override
  String get color_red => 'লাল';

  @override
  String get color_blue => 'নীল';

  @override
  String get color_green => 'সবুজ';

  @override
  String get color_yellow => 'হলুদ';

  @override
  String get color_purple => 'বেগুনি';

  @override
  String get color_orange => 'কমলা';

  @override
  String get color_pink => 'গোলাপি';

  @override
  String get color_black => 'কালো';

  @override
  String get theme_rainbow => 'রামধনু';

  @override
  String get theme_pastel => 'হালকা রং';

  @override
  String get theme_ocean => 'সমুদ্র';

  @override
  String get theme_sunset => 'সূর্যাস্ত';

  @override
  String get theme_candy => 'লজেন্স';

  @override
  String get badges => 'ব্যাজ';

  @override
  String badgeTableMaster(int n) {
    return '$n এর নামতা মাস্টার';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n এর নামতার প্রতিটি লাইন শেখো';
  }

  @override
  String get badgeStreak7 => 'টানা 7 দিন';

  @override
  String get badgeStreak7Desc => 'টানা 7 দিন আজকের চ্যালেঞ্জ করো';

  @override
  String get badgeStreak30 => 'টানা 30 দিন';

  @override
  String get badgeStreak30Desc => 'টানা 30 দিন আজকের চ্যালেঞ্জ করো';

  @override
  String get badgeDay100 => 'একদিনে 100টি অঙ্ক';

  @override
  String get badgeDay100Desc => 'একই দিনে 100টি অঙ্ক করো';

  @override
  String get badgeSpeedStar => 'গতির তারকা';

  @override
  String get badgeSpeedStarDesc => 'গতির চ্যালেঞ্জে 20 বা তার বেশি সঠিক';

  @override
  String get newBadge => 'নতুন ব্যাজ!';

  @override
  String get yay => 'হুররে!';

  @override
  String get forParents => 'অভিভাবকদের জন্য';

  @override
  String get enterPin => 'অভিভাবকের PIN দাও';

  @override
  String get createPin => '4 অঙ্কের PIN তৈরি করো';

  @override
  String get confirmPin => 'একই PIN আবার দাও';

  @override
  String get newPin => 'নতুন 4 অঙ্কের PIN দাও';

  @override
  String get pinMismatch => 'দুটি PIN আলাদা ছিল। আবার চেষ্টা করো।';

  @override
  String get pinWrong => 'PIN সঠিক নয়। আবার চেষ্টা করো।';

  @override
  String get pinForParents => 'শুধু বড়দের জন্য';

  @override
  String get pinForgot => 'PIN ভুলে গেছ? ফোনের সেটিংসে এই অ্যাপের ডেটা মুছলে PIN আর সব অগ্রগতি মুছে যাবে।';

  @override
  String get pinChanged => 'PIN বদলানো হয়েছে';

  @override
  String get progress => 'অগ্রগতি';

  @override
  String get totalSums => 'সমাধান করা অঙ্ক';

  @override
  String get accuracy => 'নির্ভুলতা';

  @override
  String get factsMastered => 'শেখা অঙ্ক';

  @override
  String get daysPractised => 'অভ্যাসের দিন';

  @override
  String get accuracyPerTopic => 'বিষয় অনুযায়ী নির্ভুলতা';

  @override
  String get speedOverTime => 'প্রতি অঙ্কে গড় সেকেন্ড';

  @override
  String get weakFacts => 'অভ্যাস দরকার এমন অঙ্ক';

  @override
  String get noWeakFacts => 'এখন কিছুই কঠিন নয়। শাবাশ!';

  @override
  String get noDataYet => 'এখনও অভ্যাস হয়নি।';

  @override
  String triesRight(int n, int pct) {
    return '$n বার চেষ্টা · $pct% সঠিক';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get sound => 'শব্দ';

  @override
  String get music => 'সংগীত';

  @override
  String get dailyReminder => 'রোজের রিমাইন্ডার';

  @override
  String get reminderTime => 'রিমাইন্ডারের সময়';

  @override
  String get notificationsBlocked => 'ফোনের সেটিংসে এই অ্যাপের বিজ্ঞপ্তি বন্ধ আছে।';

  @override
  String get changePin => 'অভিভাবকের PIN বদলাও';

  @override
  String get resetProgress => 'অগ্রগতি মুছে ফেলো';

  @override
  String resetProgressBody(String name) {
    return 'এতে $name-এর সব স্কোর, কয়েন, ব্যাজ আর খোলা লেভেল মুছে যাবে।';
  }

  @override
  String get reset => 'মুছে ফেলো';

  @override
  String get cancel => 'বাতিল';

  @override
  String get progressReset => 'অগ্রগতি মুছে ফেলা হয়েছে';

  @override
  String get removeChild => 'এই শিশুকে সরাও';

  @override
  String removeChildBody(String name) {
    return '$name আর তার সব অগ্রগতি এই ফোন থেকে সরাবে?';
  }

  @override
  String get remove => 'সরাও';

  @override
  String get child => 'শিশু';

  @override
  String get about => 'অ্যাপ সম্পর্কে';

  @override
  String get aboutBody =>
      'এই অ্যাপ 1–8 শ্রেণির শিশুদের ছোট, মজার রাউন্ডে অঙ্ক অভ্যাস করতে সাহায্য করে। এটি পুরোপুরি অফলাইনে চলে, বিজ্ঞাপন নেই, অ্যাকাউন্ট লাগে না। শুধু শিশুর প্রথম নাম আর শ্রেণি, শুধু এই ফোনেই রাখা হয়।';

  @override
  String version(String v) {
    return 'সংস্করণ $v';
  }

  @override
  String get licenses => 'লাইসেন্স';

  @override
  String get close => 'বন্ধ করো';

  @override
  String get reminderBody => 'আজকের অঙ্কের চ্যালেঞ্জের সময় হয়েছে!';

  @override
  String get reminderChannel => 'রোজের রিমাইন্ডার';

  @override
  String get lockedLevelSnack => 'এই লেভেল খুলতে অভ্যাস চালিয়ে যাও!';

  @override
  String get hearAgain => 'আবার শোনো';
}

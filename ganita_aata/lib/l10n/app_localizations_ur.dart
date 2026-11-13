// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ریاضی کھیل';

  @override
  String get chooseLanguage => 'زبان منتخب کریں';

  @override
  String get continueBtn => 'آگے بڑھیں';

  @override
  String get welcome => 'خوش آمدید!';

  @override
  String get profileSetupTitle => 'کون کھیل رہا ہے؟';

  @override
  String get editProfile => 'تفصیل بدلیں';

  @override
  String get childName => 'بچے کا پہلا نام';

  @override
  String get nameRequired => 'براہ کرم نام لکھیں';

  @override
  String get schoolClass => 'جماعت';

  @override
  String classN(int n) {
    return 'جماعت $n';
  }

  @override
  String classRange(int from, int to) {
    return 'جماعت $from–$to';
  }

  @override
  String get chooseAvatar => 'تصویر منتخب کریں';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get addChild => 'بچہ شامل کریں';

  @override
  String get switchChild => 'کون کھیل رہا ہے؟';

  @override
  String helloName(String name) {
    return 'السلام علیکم، $name!';
  }

  @override
  String get greetingSub => 'نمبروں کے ساتھ کھیلنے کو تیار؟';

  @override
  String get dailyChallenge => 'آج کا چیلنج';

  @override
  String get dailyChallengeDesc => '10 سوال – آج سب کے لیے ایک جیسے!';

  @override
  String get dailyDone => 'آج کا مکمل! کل پھر آنا۔';

  @override
  String get start => 'شروع کریں';

  @override
  String get playAgainToday => 'دوبارہ کھیلیں';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count دن', one: '1 دن');
    return '$_temp0';
  }

  @override
  String get streak => 'مسلسل';

  @override
  String get coins => 'سکے';

  @override
  String get play => 'کھیلیں';

  @override
  String get games => 'کھیل';

  @override
  String currentTopic(String topic) {
    return 'موضوع: $topic';
  }

  @override
  String get change => 'بدلیں';

  @override
  String get gameBalloon => 'غبارہ پھوڑو';

  @override
  String get gameBalloonDesc => 'صحیح جواب والا غبارہ پھوڑو';

  @override
  String get gameRace => 'کار ریس';

  @override
  String get gameRaceDesc => 'صحیح جواب سے تمہاری کار دوڑے گی';

  @override
  String get gameTreasure => 'خزانے کی تلاش';

  @override
  String get gameTreasureDesc => 'لگاتار 5 صحیح جواب سے صندوق کھلتا ہے';

  @override
  String get gameTables => 'پہاڑا ماسٹر';

  @override
  String get gameTablesDesc => '2–20 کے پہاڑے سیکھو اور مشق کرو';

  @override
  String get gameSpeed => 'رفتار کا چیلنج';

  @override
  String get gameSpeedDesc => '60 سیکنڈ میں کتنے؟';

  @override
  String get levelMap => 'سطحوں کا نقشہ';

  @override
  String levelN(int n) {
    return 'سطح $n';
  }

  @override
  String get locked => 'بند';

  @override
  String get lockedHint => 'اسے کھولنے کے لیے پچھلے موضوع میں 85% سے زیادہ صحیح کرو۔';

  @override
  String get chooseTopic => 'موضوع منتخب کریں';

  @override
  String get chooseGame => 'کھیل منتخب کریں';

  @override
  String get topic_num100 => '100 تک کے نمبر';

  @override
  String get topic_add1 => 'ایک ہندسے کا جمع';

  @override
  String get topic_sub1 => 'ایک ہندسے کی تفریق';

  @override
  String get topic_add2 => 'دو ہندسوں کا جمع';

  @override
  String get topic_sub2 => 'دو ہندسوں کی تفریق';

  @override
  String get topic_tab2_5 => '2–5 کے پہاڑے';

  @override
  String get topic_tab6_10 => '6–10 کے پہاڑے';

  @override
  String get topic_add3 => 'تین ہندسوں کا جمع';

  @override
  String get topic_sub3 => 'تین ہندسوں کی تفریق';

  @override
  String get topic_div1 => 'آسان تقسیم';

  @override
  String get topic_tab11_20 => '11–20 کے پہاڑے';

  @override
  String get topic_mul21 => 'دو ہندسے × ایک ہندسہ';

  @override
  String get topic_divRem => 'باقی کے ساتھ تقسیم';

  @override
  String get topic_mixed => 'ملے جلے عمل';

  @override
  String get topic_squares => '1–30 کے مربع';

  @override
  String get topic_cubes => '1–15 کے مکعب';

  @override
  String get topic_percent => 'فیصد';

  @override
  String get topic_fractions => 'آسان کسر';

  @override
  String qAfter(int n) {
    return '$n کے بعد کون سا نمبر آتا ہے؟';
  }

  @override
  String qBefore(int n) {
    return '$n سے پہلے کون سا نمبر آتا ہے؟';
  }

  @override
  String qTenMore(int n) {
    return '$n سے 10 زیادہ';
  }

  @override
  String qTenLess(int n) {
    return '$n سے 10 کم';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n کا $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n کا $fraction';
  }

  @override
  String get remainderShort => 'باقی';

  @override
  String get score => 'اسکور';

  @override
  String secondsShort(int n) {
    return '$n سیکنڈ';
  }

  @override
  String get quitGameTitle => 'یہ راؤنڈ روکیں؟';

  @override
  String get quitGameBody => 'اس راؤنڈ کے سکے نہیں جڑیں گے۔';

  @override
  String get keepPlaying => 'کھیلتے رہو';

  @override
  String get stop => 'روکیں';

  @override
  String answerIs(String answer) {
    return 'جواب ہے $answer';
  }

  @override
  String get praise => 'شاباش!|بہت خوب!|کمال!|زبردست!|تم تو اسٹار ہو!|واہ!';

  @override
  String get encourage =>
      'پھر کوشش کرو، تم کر سکتے ہو!|بس تھوڑا سا! آگے بڑھو!|اچھی کوشش! یہ رہا اگلا۔|اچھی محنت! تم سیکھ رہے ہو!';

  @override
  String get getReady => 'تیار ہو جاؤ!';

  @override
  String get go => 'چلو!';

  @override
  String get you => 'تم';

  @override
  String get computer => 'کمپیوٹر';

  @override
  String get raceWon => 'تم ریس جیت گئے!';

  @override
  String get raceLost => 'اچھی ریس! تھوڑی اور مشق کرو، اگلی بار جیتو گے۔';

  @override
  String chestOpened(int n) {
    return 'صندوق کھل گیا! +$n سکے';
  }

  @override
  String get chestStreakReset => 'پھر سے 5 شروع کریں!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صندوق کھلے',
      one: '1 صندوق کھلا',
      zero: 'ابھی کوئی صندوق نہیں',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'بہترین: $n';
  }

  @override
  String get newBest => 'نیا ریکارڈ!';

  @override
  String get clear => 'مٹائیں';

  @override
  String get pickTable => 'پہاڑا منتخب کریں';

  @override
  String get learn => 'سیکھیں';

  @override
  String get quiz => 'کوئز';

  @override
  String tableOf(int n) {
    return '$n کا پہاڑا';
  }

  @override
  String get listen => 'سنیں';

  @override
  String get pause => 'روکیں';

  @override
  String get startQuiz => 'کوئز شروع کریں';

  @override
  String get mastered => 'پکا';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'راؤنڈ مکمل!';

  @override
  String get correctLabel => 'صحیح';

  @override
  String get practiseLabel => 'مشق کے لیے';

  @override
  String get practiseThese => 'آؤ ان کی مشق کریں';

  @override
  String coinsEarned(int n) {
    return '+$n سکے';
  }

  @override
  String get playAgain => 'دوبارہ کھیلیں';

  @override
  String get home => 'ہوم';

  @override
  String get resultMsg3 => 'کمال! تم ریاضی کے ستارے ہو!';

  @override
  String get resultMsg2 => 'بہت اچھا کام!';

  @override
  String get resultMsg1 => 'شاباش! مشق جاری رکھو!';

  @override
  String get resultMsg0 => 'اچھی کوشش! ہر راؤنڈ سے تم اور بہتر بنو گے!';

  @override
  String get allCorrect => 'سب صحیح!';

  @override
  String newTopicUnlocked(String topic) {
    return 'نیا موضوع کھلا: $topic';
  }

  @override
  String streakNow(String days) {
    return 'مسلسل دن: $days';
  }

  @override
  String get shop => 'دکان';

  @override
  String get avatars => 'تصویریں';

  @override
  String get carColours => 'کار کے رنگ';

  @override
  String get balloonThemes => 'غبارے';

  @override
  String get buy => 'خریدیں';

  @override
  String get use => 'استعمال کریں';

  @override
  String get inUse => 'استعمال میں';

  @override
  String needMoreCoins(int n) {
    return 'مزید $n سکے کمانے کے لیے کھیلو!';
  }

  @override
  String get bought => 'اب یہ تمہارا ہے!';

  @override
  String get color_red => 'لال';

  @override
  String get color_blue => 'نیلا';

  @override
  String get color_green => 'ہرا';

  @override
  String get color_yellow => 'پیلا';

  @override
  String get color_purple => 'جامنی';

  @override
  String get color_orange => 'نارنجی';

  @override
  String get color_pink => 'گلابی';

  @override
  String get color_black => 'کالا';

  @override
  String get theme_rainbow => 'قوس قزح';

  @override
  String get theme_pastel => 'ہلکے رنگ';

  @override
  String get theme_ocean => 'سمندر';

  @override
  String get theme_sunset => 'غروب آفتاب';

  @override
  String get theme_candy => 'ٹافی';

  @override
  String get badges => 'بیج';

  @override
  String badgeTableMaster(int n) {
    return '$n کا پہاڑا ماسٹر';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n کے پہاڑے کی ہر لائن پکی کرو';
  }

  @override
  String get badgeStreak7 => 'مسلسل 7 دن';

  @override
  String get badgeStreak7Desc => 'مسلسل 7 دن آج کا چیلنج کرو';

  @override
  String get badgeStreak30 => 'مسلسل 30 دن';

  @override
  String get badgeStreak30Desc => 'مسلسل 30 دن آج کا چیلنج کرو';

  @override
  String get badgeDay100 => 'ایک دن میں 100 سوال';

  @override
  String get badgeDay100Desc => 'ایک ہی دن میں 100 سوال حل کرو';

  @override
  String get badgeSpeedStar => 'رفتار کا ستارہ';

  @override
  String get badgeSpeedStarDesc => 'رفتار کے چیلنج میں 20 یا زیادہ صحیح';

  @override
  String get newBadge => 'نیا بیج!';

  @override
  String get yay => 'ہرّے!';

  @override
  String get forParents => 'والدین کے لیے';

  @override
  String get enterPin => 'والدین کا PIN درج کریں';

  @override
  String get createPin => '4 ہندسوں کا PIN بنائیں';

  @override
  String get confirmPin => 'وہی PIN دوبارہ درج کریں';

  @override
  String get newPin => 'نیا 4 ہندسوں کا PIN درج کریں';

  @override
  String get pinMismatch => 'دونوں PIN مختلف تھے۔ دوبارہ کوشش کریں۔';

  @override
  String get pinWrong => 'PIN درست نہیں۔ دوبارہ کوشش کریں۔';

  @override
  String get pinForParents => 'صرف بڑوں کے لیے';

  @override
  String get pinForgot => 'PIN بھول گئے؟ فون کی سیٹنگز میں اس ایپ کا ڈیٹا مٹانے سے PIN اور ساری پیش رفت مٹ جائے گی۔';

  @override
  String get pinChanged => 'PIN بدل گیا';

  @override
  String get progress => 'پیش رفت';

  @override
  String get totalSums => 'حل کیے گئے سوال';

  @override
  String get accuracy => 'درستگی';

  @override
  String get factsMastered => 'پکے سوال';

  @override
  String get daysPractised => 'مشق کے دن';

  @override
  String get accuracyPerTopic => 'موضوع کے لحاظ سے درستگی';

  @override
  String get speedOverTime => 'ہر سوال پر اوسط سیکنڈ';

  @override
  String get weakFacts => 'مشق والے سوال';

  @override
  String get noWeakFacts => 'ابھی کچھ بھی مشکل نہیں۔ شاباش!';

  @override
  String get noDataYet => 'ابھی تک مشق نہیں ہوئی۔';

  @override
  String triesRight(int n, int pct) {
    return '$n کوششیں · $pct% صحیح';
  }

  @override
  String get settings => 'سیٹنگز';

  @override
  String get language => 'زبان';

  @override
  String get sound => 'آواز';

  @override
  String get music => 'موسیقی';

  @override
  String get dailyReminder => 'روزانہ یاد دہانی';

  @override
  String get reminderTime => 'یاد دہانی کا وقت';

  @override
  String get notificationsBlocked => 'فون کی سیٹنگز میں اس ایپ کی اطلاعات بند ہیں۔';

  @override
  String get changePin => 'والدین کا PIN بدلیں';

  @override
  String get resetProgress => 'پیش رفت مٹائیں';

  @override
  String resetProgressBody(String name) {
    return 'اس سے $name کے سارے اسکور، سکے، بیج اور کھلی سطحیں مٹ جائیں گی۔';
  }

  @override
  String get reset => 'مٹائیں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get progressReset => 'پیش رفت مٹا دی گئی';

  @override
  String get removeChild => 'اس بچے کو ہٹائیں';

  @override
  String removeChildBody(String name) {
    return '$name اور ان کی ساری پیش رفت اس فون سے ہٹائیں؟';
  }

  @override
  String get remove => 'ہٹائیں';

  @override
  String get child => 'بچہ';

  @override
  String get about => 'ایپ کے بارے میں';

  @override
  String get aboutBody =>
      'یہ ایپ جماعت 1–8 کے بچوں کو چھوٹے، مزے دار راؤنڈز میں ریاضی کی مشق کرنے میں مدد کرتی ہے۔ یہ مکمل طور پر آف لائن چلتی ہے، اشتہارات نہیں اور اکاؤنٹ کی ضرورت نہیں۔ صرف بچے کا پہلا نام اور جماعت، صرف اسی فون پر رکھی جاتی ہے۔';

  @override
  String version(String v) {
    return 'ورژن $v';
  }

  @override
  String get licenses => 'لائسنس';

  @override
  String get close => 'بند کریں';

  @override
  String get reminderBody => 'آج کے ریاضی چیلنج کا وقت ہو گیا!';

  @override
  String get reminderChannel => 'روزانہ یاد دہانی';

  @override
  String get lockedLevelSnack => 'یہ سطح کھولنے کے لیے مشق کرتے رہو!';

  @override
  String get hearAgain => 'دوبارہ سنیں';
}

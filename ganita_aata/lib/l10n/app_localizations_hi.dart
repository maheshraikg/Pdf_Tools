// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'गणित खेल';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get continueBtn => 'आगे बढ़ें';

  @override
  String get welcome => 'स्वागत है!';

  @override
  String get profileSetupTitle => 'कौन खेल रहा है?';

  @override
  String get editProfile => 'प्रोफ़ाइल बदलें';

  @override
  String get childName => 'बच्चे का पहला नाम';

  @override
  String get nameRequired => 'कृपया नाम लिखें';

  @override
  String get schoolClass => 'कक्षा';

  @override
  String classN(int n) {
    return 'कक्षा $n';
  }

  @override
  String classRange(int from, int to) {
    return 'कक्षा $from–$to';
  }

  @override
  String get chooseAvatar => 'चित्र चुनें';

  @override
  String get save => 'सहेजें';

  @override
  String get addChild => 'बच्चा जोड़ें';

  @override
  String get switchChild => 'कौन खेल रहा है?';

  @override
  String helloName(String name) {
    return 'नमस्ते, $name!';
  }

  @override
  String get greetingSub => 'संख्याओं के साथ खेलने को तैयार?';

  @override
  String get dailyChallenge => 'आज की चुनौती';

  @override
  String get dailyChallengeDesc => '10 सवाल – आज सबके लिए एक जैसे!';

  @override
  String get dailyDone => 'आज का काम पूरा! कल फिर आना।';

  @override
  String get start => 'शुरू करें';

  @override
  String get playAgainToday => 'फिर से खेलें';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count दिन', one: '1 दिन');
    return '$_temp0';
  }

  @override
  String get streak => 'लगातार';

  @override
  String get coins => 'सिक्के';

  @override
  String get play => 'खेलें';

  @override
  String get games => 'खेल';

  @override
  String currentTopic(String topic) {
    return 'विषय: $topic';
  }

  @override
  String get change => 'बदलें';

  @override
  String get gameBalloon => 'गुब्बारा फोड़ो';

  @override
  String get gameBalloonDesc => 'सही उत्तर वाला गुब्बारा फोड़ो';

  @override
  String get gameRace => 'कार रेस';

  @override
  String get gameRaceDesc => 'सही उत्तर से तुम्हारी कार दौड़ेगी';

  @override
  String get gameTreasure => 'खज़ाने की खोज';

  @override
  String get gameTreasureDesc => 'लगातार 5 सही उत्तर से संदूक खुलेगा';

  @override
  String get gameTables => 'पहाड़ा मास्टर';

  @override
  String get gameTablesDesc => '2–20 के पहाड़े सीखो और अभ्यास करो';

  @override
  String get gameSpeed => 'तेज़ी की चुनौती';

  @override
  String get gameSpeedDesc => '60 सेकंड में कितने?';

  @override
  String get levelMap => 'स्तरों का नक्शा';

  @override
  String levelN(int n) {
    return 'स्तर $n';
  }

  @override
  String get locked => 'बंद';

  @override
  String get lockedHint => 'इसे खोलने के लिए पिछले विषय में 85% से ज़्यादा सही करो।';

  @override
  String get chooseTopic => 'विषय चुनें';

  @override
  String get chooseGame => 'खेल चुनें';

  @override
  String get topic_num100 => '100 तक की संख्याएँ';

  @override
  String get topic_add1 => 'एक अंक का जोड़';

  @override
  String get topic_sub1 => 'एक अंक का घटाव';

  @override
  String get topic_add2 => 'दो अंकों का जोड़';

  @override
  String get topic_sub2 => 'दो अंकों का घटाव';

  @override
  String get topic_tab2_5 => '2–5 के पहाड़े';

  @override
  String get topic_tab6_10 => '6–10 के पहाड़े';

  @override
  String get topic_add3 => 'तीन अंकों का जोड़';

  @override
  String get topic_sub3 => 'तीन अंकों का घटाव';

  @override
  String get topic_div1 => 'सरल भाग';

  @override
  String get topic_tab11_20 => '11–20 के पहाड़े';

  @override
  String get topic_mul21 => 'दो अंक × एक अंक';

  @override
  String get topic_divRem => 'शेषफल वाला भाग';

  @override
  String get topic_mixed => 'मिश्रित संक्रियाएँ';

  @override
  String get topic_squares => '1–30 के वर्ग';

  @override
  String get topic_cubes => '1–15 के घन';

  @override
  String get topic_percent => 'प्रतिशत';

  @override
  String get topic_fractions => 'सरल भिन्न';

  @override
  String qAfter(int n) {
    return '$n के बाद कौन-सी संख्या आती है?';
  }

  @override
  String qBefore(int n) {
    return '$n से पहले कौन-सी संख्या आती है?';
  }

  @override
  String qTenMore(int n) {
    return '$n से 10 ज़्यादा';
  }

  @override
  String qTenLess(int n) {
    return '$n से 10 कम';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n का $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n का $fraction';
  }

  @override
  String get remainderShort => 'शेष';

  @override
  String get score => 'अंक';

  @override
  String secondsShort(int n) {
    return '$n से';
  }

  @override
  String get quitGameTitle => 'यह राउंड रोकें?';

  @override
  String get quitGameBody => 'इस राउंड के सिक्के नहीं जुड़ेंगे।';

  @override
  String get keepPlaying => 'खेलते रहो';

  @override
  String get stop => 'रोकें';

  @override
  String answerIs(String answer) {
    return 'उत्तर है $answer';
  }

  @override
  String get praise => 'शाबाश!|बहुत बढ़िया!|कमाल है!|बहुत अच्छे!|तुम तो स्टार हो!|वाह!';

  @override
  String get encourage =>
      'फिर से कोशिश करो, तुम कर सकते हो!|बस थोड़ा सा! आगे बढ़ो!|अच्छी कोशिश! यह रहा अगला।|बढ़िया प्रयास! तुम सीख रहे हो!';

  @override
  String get getReady => 'तैयार हो जाओ!';

  @override
  String get go => 'चलो!';

  @override
  String get you => 'तुम';

  @override
  String get computer => 'कंप्यूटर';

  @override
  String get raceWon => 'तुम रेस जीत गए!';

  @override
  String get raceLost => 'बढ़िया रेस! थोड़ा और अभ्यास करो, अगली बार जीतोगे।';

  @override
  String chestOpened(int n) {
    return 'संदूक खुल गया! +$n सिक्के';
  }

  @override
  String get chestStreakReset => 'फिर से 5 शुरू करें!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count संदूक खुले',
      one: '1 संदूक खुला',
      zero: 'अभी कोई संदूक नहीं',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'सबसे अच्छा: $n';
  }

  @override
  String get newBest => 'नया रिकॉर्ड!';

  @override
  String get clear => 'मिटाएँ';

  @override
  String get pickTable => 'पहाड़ा चुनें';

  @override
  String get learn => 'सीखें';

  @override
  String get quiz => 'क्विज़';

  @override
  String tableOf(int n) {
    return '$n का पहाड़ा';
  }

  @override
  String get listen => 'सुनें';

  @override
  String get pause => 'रोकें';

  @override
  String get startQuiz => 'क्विज़ शुरू करें';

  @override
  String get mastered => 'पक्का';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'राउंड पूरा!';

  @override
  String get correctLabel => 'सही';

  @override
  String get practiseLabel => 'अभ्यास के लिए';

  @override
  String get practiseThese => 'चलो इनका अभ्यास करें';

  @override
  String coinsEarned(int n) {
    return '+$n सिक्के';
  }

  @override
  String get playAgain => 'फिर से खेलें';

  @override
  String get home => 'होम';

  @override
  String get resultMsg3 => 'कमाल! तुम गणित के सितारे हो!';

  @override
  String get resultMsg2 => 'बहुत बढ़िया काम!';

  @override
  String get resultMsg1 => 'अच्छा किया! अभ्यास करते रहो!';

  @override
  String get resultMsg0 => 'अच्छी कोशिश! हर राउंड से तुम और अच्छे बनोगे!';

  @override
  String get allCorrect => 'सब सही!';

  @override
  String newTopicUnlocked(String topic) {
    return 'नया विषय खुला: $topic';
  }

  @override
  String streakNow(String days) {
    return 'लगातार दिन: $days';
  }

  @override
  String get shop => 'दुकान';

  @override
  String get avatars => 'चित्र';

  @override
  String get carColours => 'कार के रंग';

  @override
  String get balloonThemes => 'गुब्बारे';

  @override
  String get buy => 'खरीदें';

  @override
  String get use => 'इस्तेमाल करें';

  @override
  String get inUse => 'इस्तेमाल में';

  @override
  String needMoreCoins(int n) {
    return '$n और सिक्के कमाने के लिए खेलो!';
  }

  @override
  String get bought => 'अब यह तुम्हारा है!';

  @override
  String get color_red => 'लाल';

  @override
  String get color_blue => 'नीला';

  @override
  String get color_green => 'हरा';

  @override
  String get color_yellow => 'पीला';

  @override
  String get color_purple => 'बैंगनी';

  @override
  String get color_orange => 'नारंगी';

  @override
  String get color_pink => 'गुलाबी';

  @override
  String get color_black => 'काला';

  @override
  String get theme_rainbow => 'इंद्रधनुष';

  @override
  String get theme_pastel => 'हल्के रंग';

  @override
  String get theme_ocean => 'समुद्र';

  @override
  String get theme_sunset => 'सूर्यास्त';

  @override
  String get theme_candy => 'टॉफ़ी';

  @override
  String get badges => 'बैज';

  @override
  String badgeTableMaster(int n) {
    return '$n का पहाड़ा मास्टर';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n के पहाड़े की हर पंक्ति पक्की करो';
  }

  @override
  String get badgeStreak7 => '7 दिन लगातार';

  @override
  String get badgeStreak7Desc => 'लगातार 7 दिन आज की चुनौती पूरी करो';

  @override
  String get badgeStreak30 => '30 दिन लगातार';

  @override
  String get badgeStreak30Desc => 'लगातार 30 दिन आज की चुनौती पूरी करो';

  @override
  String get badgeDay100 => 'एक दिन में 100 सवाल';

  @override
  String get badgeDay100Desc => 'एक ही दिन में 100 सवाल हल करो';

  @override
  String get badgeSpeedStar => 'तेज़ी का सितारा';

  @override
  String get badgeSpeedStarDesc => 'तेज़ी की चुनौती में 20 या ज़्यादा सही';

  @override
  String get newBadge => 'नया बैज!';

  @override
  String get yay => 'याय!';

  @override
  String get forParents => 'माता-पिता के लिए';

  @override
  String get enterPin => 'माता-पिता का पिन डालें';

  @override
  String get createPin => '4 अंकों का पिन बनाएँ';

  @override
  String get confirmPin => 'वही पिन फिर से डालें';

  @override
  String get newPin => 'नया 4 अंकों का पिन डालें';

  @override
  String get pinMismatch => 'दोनों पिन अलग थे। फिर से कोशिश करें।';

  @override
  String get pinWrong => 'पिन सही नहीं है। फिर से कोशिश करें।';

  @override
  String get pinForParents => 'केवल बड़ों के लिए';

  @override
  String get pinForgot => 'पिन भूल गए? फ़ोन सेटिंग में इस ऐप का डेटा मिटाने से पिन और सारी प्रगति मिट जाएगी।';

  @override
  String get pinChanged => 'पिन बदल गया';

  @override
  String get progress => 'प्रगति';

  @override
  String get totalSums => 'हल किए सवाल';

  @override
  String get accuracy => 'सटीकता';

  @override
  String get factsMastered => 'पक्के सवाल';

  @override
  String get daysPractised => 'अभ्यास के दिन';

  @override
  String get accuracyPerTopic => 'विषय के अनुसार सटीकता';

  @override
  String get speedOverTime => 'हर सवाल पर औसत सेकंड';

  @override
  String get weakFacts => 'अभ्यास वाले सवाल';

  @override
  String get noWeakFacts => 'अभी कुछ भी मुश्किल नहीं। शाबाश!';

  @override
  String get noDataYet => 'अभी तक अभ्यास नहीं हुआ।';

  @override
  String triesRight(int n, int pct) {
    return '$n कोशिश · $pct% सही';
  }

  @override
  String get settings => 'सेटिंग';

  @override
  String get language => 'भाषा';

  @override
  String get sound => 'आवाज़';

  @override
  String get music => 'संगीत';

  @override
  String get dailyReminder => 'रोज़ का रिमाइंडर';

  @override
  String get reminderTime => 'रिमाइंडर का समय';

  @override
  String get notificationsBlocked => 'फ़ोन सेटिंग में इस ऐप की सूचनाएँ बंद हैं।';

  @override
  String get changePin => 'माता-पिता का पिन बदलें';

  @override
  String get resetProgress => 'प्रगति मिटाएँ';

  @override
  String resetProgressBody(String name) {
    return 'इससे $name के सारे अंक, सिक्के, बैज और खुले स्तर मिट जाएँगे।';
  }

  @override
  String get reset => 'मिटाएँ';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get progressReset => 'प्रगति मिटा दी गई';

  @override
  String get removeChild => 'इस बच्चे को हटाएँ';

  @override
  String removeChildBody(String name) {
    return '$name और उनकी सारी प्रगति इस फ़ोन से हटाएँ?';
  }

  @override
  String get remove => 'हटाएँ';

  @override
  String get child => 'बच्चा';

  @override
  String get about => 'ऐप के बारे में';

  @override
  String get aboutBody =>
      'यह ऐप कक्षा 1–8 के बच्चों को छोटे, मज़ेदार राउंड में गणित का अभ्यास कराता है। यह पूरी तरह ऑफ़लाइन चलता है, इसमें विज्ञापन नहीं हैं और खाता नहीं चाहिए। केवल बच्चे का पहला नाम और कक्षा, केवल इसी फ़ोन पर रखी जाती है।';

  @override
  String version(String v) {
    return 'संस्करण $v';
  }

  @override
  String get licenses => 'लाइसेंस';

  @override
  String get close => 'बंद करें';

  @override
  String get reminderBody => 'आज की गणित चुनौती का समय हो गया!';

  @override
  String get reminderChannel => 'रोज़ का रिमाइंडर';

  @override
  String get lockedLevelSnack => 'यह स्तर खोलने के लिए अभ्यास करते रहो!';

  @override
  String get hearAgain => 'फिर से सुनें';
}

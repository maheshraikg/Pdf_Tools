// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'गणित खेळ';

  @override
  String get chooseLanguage => 'भाषा निवडा';

  @override
  String get continueBtn => 'पुढे चला';

  @override
  String get welcome => 'स्वागत आहे!';

  @override
  String get profileSetupTitle => 'कोण खेळत आहे?';

  @override
  String get editProfile => 'माहिती बदला';

  @override
  String get childName => 'मुलाचे पहिले नाव';

  @override
  String get nameRequired => 'कृपया नाव लिहा';

  @override
  String get schoolClass => 'इयत्ता';

  @override
  String classN(int n) {
    return 'इयत्ता $n';
  }

  @override
  String classRange(int from, int to) {
    return 'इयत्ता $from–$to';
  }

  @override
  String get chooseAvatar => 'चित्र निवडा';

  @override
  String get save => 'जतन करा';

  @override
  String get addChild => 'मूल जोडा';

  @override
  String get switchChild => 'कोण खेळत आहे?';

  @override
  String helloName(String name) {
    return 'नमस्कार, $name!';
  }

  @override
  String get greetingSub => 'अंकांशी खेळायला तयार?';

  @override
  String get dailyChallenge => 'आजचे आव्हान';

  @override
  String get dailyChallengeDesc => '10 गणिते – आज सर्वांसाठी सारखी!';

  @override
  String get dailyDone => 'आजचे पूर्ण झाले! उद्या पुन्हा या.';

  @override
  String get start => 'सुरू करा';

  @override
  String get playAgainToday => 'पुन्हा खेळा';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count दिवस', one: '1 दिवस');
    return '$_temp0';
  }

  @override
  String get streak => 'सलग';

  @override
  String get coins => 'नाणी';

  @override
  String get play => 'खेळा';

  @override
  String get games => 'खेळ';

  @override
  String currentTopic(String topic) {
    return 'विषय: $topic';
  }

  @override
  String get change => 'बदला';

  @override
  String get gameBalloon => 'फुगा फोडा';

  @override
  String get gameBalloonDesc => 'बरोबर उत्तराचा फुगा फोडा';

  @override
  String get gameRace => 'कार शर्यत';

  @override
  String get gameRaceDesc => 'बरोबर उत्तराने तुझी कार धावेल';

  @override
  String get gameTreasure => 'खजिन्याचा शोध';

  @override
  String get gameTreasureDesc => 'सलग 5 बरोबर उत्तरांनी पेटी उघडते';

  @override
  String get gameTables => 'पाढे मास्टर';

  @override
  String get gameTablesDesc => '2–20 चे पाढे शिका आणि सराव करा';

  @override
  String get gameSpeed => 'वेगाचे आव्हान';

  @override
  String get gameSpeedDesc => '60 सेकंदांत किती?';

  @override
  String get levelMap => 'पातळ्यांचा नकाशा';

  @override
  String levelN(int n) {
    return 'पातळी $n';
  }

  @override
  String get locked => 'बंद';

  @override
  String get lockedHint => 'हे उघडण्यासाठी आधीच्या विषयात 85% पेक्षा जास्त बरोबर करा.';

  @override
  String get chooseTopic => 'विषय निवडा';

  @override
  String get chooseGame => 'खेळ निवडा';

  @override
  String get topic_num100 => '100 पर्यंतच्या संख्या';

  @override
  String get topic_add1 => 'एक अंकी बेरीज';

  @override
  String get topic_sub1 => 'एक अंकी वजाबाकी';

  @override
  String get topic_add2 => 'दोन अंकी बेरीज';

  @override
  String get topic_sub2 => 'दोन अंकी वजाबाकी';

  @override
  String get topic_tab2_5 => '2–5 चे पाढे';

  @override
  String get topic_tab6_10 => '6–10 चे पाढे';

  @override
  String get topic_add3 => 'तीन अंकी बेरीज';

  @override
  String get topic_sub3 => 'तीन अंकी वजाबाकी';

  @override
  String get topic_div1 => 'सोपा भागाकार';

  @override
  String get topic_tab11_20 => '11–20 चे पाढे';

  @override
  String get topic_mul21 => 'दोन अंकी × एक अंकी';

  @override
  String get topic_divRem => 'बाकीसह भागाकार';

  @override
  String get topic_mixed => 'मिश्र क्रिया';

  @override
  String get topic_squares => '1–30 चे वर्ग';

  @override
  String get topic_cubes => '1–15 चे घन';

  @override
  String get topic_percent => 'टक्केवारी';

  @override
  String get topic_fractions => 'सोपे अपूर्णांक';

  @override
  String qAfter(int n) {
    return '$n नंतर कोणती संख्या येते?';
  }

  @override
  String qBefore(int n) {
    return '$n च्या आधी कोणती संख्या येते?';
  }

  @override
  String qTenMore(int n) {
    return '$n पेक्षा 10 जास्त';
  }

  @override
  String qTenLess(int n) {
    return '$n पेक्षा 10 कमी';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n चे $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n चा $fraction';
  }

  @override
  String get remainderShort => 'बा';

  @override
  String get score => 'गुण';

  @override
  String secondsShort(int n) {
    return '$n से';
  }

  @override
  String get quitGameTitle => 'ही फेरी थांबवायची?';

  @override
  String get quitGameBody => 'या फेरीतील नाणी जोडली जाणार नाहीत.';

  @override
  String get keepPlaying => 'खेळत राहा';

  @override
  String get stop => 'थांबवा';

  @override
  String answerIs(String answer) {
    return 'उत्तर आहे $answer';
  }

  @override
  String get praise => 'शाब्बास!|खूप छान!|अप्रतिम!|मस्त!|तू तर स्टार आहेस!|वा!';

  @override
  String get encourage => 'पुन्हा प्रयत्न कर, तू करू शकतोस!|जवळजवळ! पुढे चल!|छान प्रयत्न! हे पुढचे.|छान! तू शिकत आहेस!';

  @override
  String get getReady => 'तयार व्हा!';

  @override
  String get go => 'चला!';

  @override
  String get you => 'तू';

  @override
  String get computer => 'संगणक';

  @override
  String get raceWon => 'तू शर्यत जिंकलास!';

  @override
  String get raceLost => 'छान शर्यत! थोडा अजून सराव कर, पुढच्या वेळी जिंकशील.';

  @override
  String chestOpened(int n) {
    return 'पेटी उघडली! +$n नाणी';
  }

  @override
  String get chestStreakReset => 'पुन्हा 5 सुरू करूया!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count पेट्या उघडल्या',
      one: '1 पेटी उघडली',
      zero: 'अजून पेटी नाही',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'सर्वोत्तम: $n';
  }

  @override
  String get newBest => 'नवा विक्रम!';

  @override
  String get clear => 'पुसा';

  @override
  String get pickTable => 'पाढा निवडा';

  @override
  String get learn => 'शिका';

  @override
  String get quiz => 'प्रश्नमंजुषा';

  @override
  String tableOf(int n) {
    return '$n चा पाढा';
  }

  @override
  String get listen => 'ऐका';

  @override
  String get pause => 'थांबवा';

  @override
  String get startQuiz => 'प्रश्नमंजुषा सुरू करा';

  @override
  String get mastered => 'पक्के';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'फेरी पूर्ण!';

  @override
  String get correctLabel => 'बरोबर';

  @override
  String get practiseLabel => 'सरावासाठी';

  @override
  String get practiseThese => 'यांचा सराव करूया';

  @override
  String coinsEarned(int n) {
    return '+$n नाणी';
  }

  @override
  String get playAgain => 'पुन्हा खेळा';

  @override
  String get home => 'मुख्यपृष्ठ';

  @override
  String get resultMsg3 => 'अप्रतिम! तू गणिताचा तारा आहेस!';

  @override
  String get resultMsg2 => 'खूप छान काम!';

  @override
  String get resultMsg1 => 'छान! सराव करत राहा!';

  @override
  String get resultMsg0 => 'छान प्रयत्न! प्रत्येक फेरीत तू अजून चांगला होशील!';

  @override
  String get allCorrect => 'सर्व बरोबर!';

  @override
  String newTopicUnlocked(String topic) {
    return 'नवा विषय उघडला: $topic';
  }

  @override
  String streakNow(String days) {
    return 'सलग दिवस: $days';
  }

  @override
  String get shop => 'दुकान';

  @override
  String get avatars => 'चित्रे';

  @override
  String get carColours => 'कारचे रंग';

  @override
  String get balloonThemes => 'फुगे';

  @override
  String get buy => 'विकत घ्या';

  @override
  String get use => 'वापरा';

  @override
  String get inUse => 'वापरात';

  @override
  String needMoreCoins(int n) {
    return 'अजून $n नाणी मिळवण्यासाठी खेळा!';
  }

  @override
  String get bought => 'आता हे तुझे आहे!';

  @override
  String get color_red => 'लाल';

  @override
  String get color_blue => 'निळा';

  @override
  String get color_green => 'हिरवा';

  @override
  String get color_yellow => 'पिवळा';

  @override
  String get color_purple => 'जांभळा';

  @override
  String get color_orange => 'केशरी';

  @override
  String get color_pink => 'गुलाबी';

  @override
  String get color_black => 'काळा';

  @override
  String get theme_rainbow => 'इंद्रधनुष्य';

  @override
  String get theme_pastel => 'फिके रंग';

  @override
  String get theme_ocean => 'समुद्र';

  @override
  String get theme_sunset => 'सूर्यास्त';

  @override
  String get theme_candy => 'गोळ्या';

  @override
  String get badges => 'बॅज';

  @override
  String badgeTableMaster(int n) {
    return '$n चा पाढा मास्टर';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n च्या पाढ्याची प्रत्येक ओळ पक्की कर';
  }

  @override
  String get badgeStreak7 => 'सलग 7 दिवस';

  @override
  String get badgeStreak7Desc => 'सलग 7 दिवस आजचे आव्हान पूर्ण कर';

  @override
  String get badgeStreak30 => 'सलग 30 दिवस';

  @override
  String get badgeStreak30Desc => 'सलग 30 दिवस आजचे आव्हान पूर्ण कर';

  @override
  String get badgeDay100 => 'एका दिवसात 100 गणिते';

  @override
  String get badgeDay100Desc => 'एकाच दिवसात 100 गणिते सोडव';

  @override
  String get badgeSpeedStar => 'वेगाचा तारा';

  @override
  String get badgeSpeedStarDesc => 'वेगाच्या आव्हानात 20 किंवा जास्त बरोबर';

  @override
  String get newBadge => 'नवा बॅज!';

  @override
  String get yay => 'हुर्रे!';

  @override
  String get forParents => 'पालकांसाठी';

  @override
  String get enterPin => 'पालकांचा पिन टाका';

  @override
  String get createPin => '4 अंकी पिन तयार करा';

  @override
  String get confirmPin => 'तोच पिन पुन्हा टाका';

  @override
  String get newPin => 'नवा 4 अंकी पिन टाका';

  @override
  String get pinMismatch => 'दोन्ही पिन वेगळे होते. पुन्हा प्रयत्न करा.';

  @override
  String get pinWrong => 'पिन बरोबर नाही. पुन्हा प्रयत्न करा.';

  @override
  String get pinForParents => 'फक्त मोठ्यांसाठी';

  @override
  String get pinForgot => 'पिन विसरलात? फोन सेटिंगमध्ये या ॲपचा डेटा पुसल्यास पिन आणि सर्व प्रगती पुसली जाईल.';

  @override
  String get pinChanged => 'पिन बदलला';

  @override
  String get progress => 'प्रगती';

  @override
  String get totalSums => 'सोडवलेली गणिते';

  @override
  String get accuracy => 'अचूकता';

  @override
  String get factsMastered => 'पक्की गणिते';

  @override
  String get daysPractised => 'सरावाचे दिवस';

  @override
  String get accuracyPerTopic => 'विषयानुसार अचूकता';

  @override
  String get speedOverTime => 'प्रत्येक गणिताला सरासरी सेकंद';

  @override
  String get weakFacts => 'सरावाची गणिते';

  @override
  String get noWeakFacts => 'सध्या काहीच अवघड नाही. शाब्बास!';

  @override
  String get noDataYet => 'अजून सराव झाला नाही.';

  @override
  String triesRight(int n, int pct) {
    return '$n प्रयत्न · $pct% बरोबर';
  }

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get sound => 'आवाज';

  @override
  String get music => 'संगीत';

  @override
  String get dailyReminder => 'रोजची आठवण';

  @override
  String get reminderTime => 'आठवणीची वेळ';

  @override
  String get notificationsBlocked => 'फोन सेटिंगमध्ये या ॲपच्या सूचना बंद आहेत.';

  @override
  String get changePin => 'पालकांचा पिन बदला';

  @override
  String get resetProgress => 'प्रगती पुसा';

  @override
  String resetProgressBody(String name) {
    return 'यामुळे $name चे सर्व गुण, नाणी, बॅज आणि उघडलेल्या पातळ्या पुसल्या जातील.';
  }

  @override
  String get reset => 'पुसा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get progressReset => 'प्रगती पुसली';

  @override
  String get removeChild => 'हे मूल काढा';

  @override
  String removeChildBody(String name) {
    return '$name आणि त्यांची सर्व प्रगती या फोनवरून काढायची?';
  }

  @override
  String get remove => 'काढा';

  @override
  String get child => 'मूल';

  @override
  String get about => 'ॲपबद्दल';

  @override
  String get aboutBody =>
      'हे ॲप इयत्ता 1–8 च्या मुलांना छोट्या, मजेदार फेऱ्यांमध्ये गणिताचा सराव करायला मदत करते. हे पूर्णपणे ऑफलाइन चालते, जाहिराती नाहीत आणि खाते लागत नाही. फक्त मुलाचे पहिले नाव आणि इयत्ता, फक्त याच फोनवर ठेवली जाते.';

  @override
  String version(String v) {
    return 'आवृत्ती $v';
  }

  @override
  String get licenses => 'परवाने';

  @override
  String get close => 'बंद करा';

  @override
  String get reminderBody => 'आजच्या गणित आव्हानाची वेळ झाली!';

  @override
  String get reminderChannel => 'रोजची आठवण';

  @override
  String get lockedLevelSnack => 'ही पातळी उघडण्यासाठी सराव करत राहा!';

  @override
  String get hearAgain => 'पुन्हा ऐका';
}

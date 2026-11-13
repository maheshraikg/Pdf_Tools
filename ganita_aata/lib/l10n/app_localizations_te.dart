// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'గణిత ఆట';

  @override
  String get chooseLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get continueBtn => 'కొనసాగించు';

  @override
  String get welcome => 'స్వాగతం!';

  @override
  String get profileSetupTitle => 'ఎవరు ఆడుతున్నారు?';

  @override
  String get editProfile => 'వివరాలు మార్చు';

  @override
  String get childName => 'పిల్లల మొదటి పేరు';

  @override
  String get nameRequired => 'దయచేసి పేరు రాయండి';

  @override
  String get schoolClass => 'తరగతి';

  @override
  String classN(int n) {
    return '$nవ తరగతి';
  }

  @override
  String classRange(int from, int to) {
    return '$from–$to తరగతి';
  }

  @override
  String get chooseAvatar => 'బొమ్మను ఎంచుకో';

  @override
  String get save => 'సేవ్ చేయి';

  @override
  String get addChild => 'పిల్లవాడిని జోడించు';

  @override
  String get switchChild => 'ఎవరు ఆడుతున్నారు?';

  @override
  String helloName(String name) {
    return 'నమస్తే, $name!';
  }

  @override
  String get greetingSub => 'సంఖ్యలతో ఆడటానికి సిద్ధమా?';

  @override
  String get dailyChallenge => 'నేటి సవాలు';

  @override
  String get dailyChallengeDesc => '10 లెక్కలు – ఈరోజు అందరికీ ఒకటే!';

  @override
  String get dailyDone => 'ఈరోజుది పూర్తయింది! రేపు మళ్ళీ రా.';

  @override
  String get start => 'ప్రారంభించు';

  @override
  String get playAgainToday => 'మళ్ళీ ఆడు';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count రోజులు', one: '1 రోజు');
    return '$_temp0';
  }

  @override
  String get streak => 'వరుస';

  @override
  String get coins => 'నాణేలు';

  @override
  String get play => 'ఆడు';

  @override
  String get games => 'ఆటలు';

  @override
  String currentTopic(String topic) {
    return 'అంశం: $topic';
  }

  @override
  String get change => 'మార్చు';

  @override
  String get gameBalloon => 'బెలూన్ పగలగొట్టు';

  @override
  String get gameBalloonDesc => 'సరైన జవాబు ఉన్న బెలూన్‌ను పగలగొట్టు';

  @override
  String get gameRace => 'కారు పందెం';

  @override
  String get gameRaceDesc => 'సరైన జవాబులతో నీ కారు దూసుకెళ్తుంది';

  @override
  String get gameTreasure => 'నిధి వేట';

  @override
  String get gameTreasureDesc => 'వరుసగా 5 సరైన జవాబులతో పెట్టె తెరుచుకుంటుంది';

  @override
  String get gameTables => 'ఎక్కాల మాస్టర్';

  @override
  String get gameTablesDesc => '2–20 ఎక్కాలు నేర్చుకో, సాధన చేయి';

  @override
  String get gameSpeed => 'వేగం సవాలు';

  @override
  String get gameSpeedDesc => '60 సెకన్లలో ఎన్ని?';

  @override
  String get levelMap => 'స్థాయిల పటం';

  @override
  String levelN(int n) {
    return 'స్థాయి $n';
  }

  @override
  String get locked => 'లాక్ అయింది';

  @override
  String get lockedHint => 'దీన్ని తెరవడానికి ముందు అంశంలో 85% కంటే ఎక్కువ సరిగా చేయి.';

  @override
  String get chooseTopic => 'అంశాన్ని ఎంచుకో';

  @override
  String get chooseGame => 'ఆటను ఎంచుకో';

  @override
  String get topic_num100 => '100 వరకు సంఖ్యలు';

  @override
  String get topic_add1 => 'ఒక అంకె కూడిక';

  @override
  String get topic_sub1 => 'ఒక అంకె తీసివేత';

  @override
  String get topic_add2 => 'రెండంకెల కూడిక';

  @override
  String get topic_sub2 => 'రెండంకెల తీసివేత';

  @override
  String get topic_tab2_5 => '2–5 ఎక్కాలు';

  @override
  String get topic_tab6_10 => '6–10 ఎక్కాలు';

  @override
  String get topic_add3 => 'మూడంకెల కూడిక';

  @override
  String get topic_sub3 => 'మూడంకెల తీసివేత';

  @override
  String get topic_div1 => 'సులభ భాగహారం';

  @override
  String get topic_tab11_20 => '11–20 ఎక్కాలు';

  @override
  String get topic_mul21 => 'రెండంకెలు × ఒక అంకె';

  @override
  String get topic_divRem => 'శేషంతో భాగహారం';

  @override
  String get topic_mixed => 'మిశ్రమ క్రియలు';

  @override
  String get topic_squares => '1–30 వర్గాలు';

  @override
  String get topic_cubes => '1–15 ఘనాలు';

  @override
  String get topic_percent => 'శాతాలు';

  @override
  String get topic_fractions => 'సులభ భిన్నాలు';

  @override
  String qAfter(int n) {
    return '$n తర్వాత వచ్చే సంఖ్య ఏది?';
  }

  @override
  String qBefore(int n) {
    return '$n ముందు వచ్చే సంఖ్య ఏది?';
  }

  @override
  String qTenMore(int n) {
    return '$n కంటే 10 ఎక్కువ';
  }

  @override
  String qTenLess(int n) {
    return '$n కంటే 10 తక్కువ';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n లో $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n లో $fraction';
  }

  @override
  String get remainderShort => 'శే';

  @override
  String get score => 'స్కోరు';

  @override
  String secondsShort(int n) {
    return '$n సె';
  }

  @override
  String get quitGameTitle => 'ఈ రౌండ్ ఆపాలా?';

  @override
  String get quitGameBody => 'ఈ రౌండ్ నాణేలు జోడించబడవు.';

  @override
  String get keepPlaying => 'ఆడుతూ ఉండు';

  @override
  String get stop => 'ఆపు';

  @override
  String answerIs(String answer) {
    return 'జవాబు $answer';
  }

  @override
  String get praise => 'సూపర్!|భలే!|అద్భుతం!|చాలా బాగుంది!|నువ్వు స్టార్!|వావ్!';

  @override
  String get encourage =>
      'మళ్ళీ ప్రయత్నించు, నువ్వు చేయగలవు!|దాదాపు వచ్చేసింది! కొనసాగించు!|మంచి ప్రయత్నం! ఇదిగో తర్వాతది.|బాగా ప్రయత్నించావు! నువ్వు నేర్చుకుంటున్నావు!';

  @override
  String get getReady => 'సిద్ధంగా ఉండు!';

  @override
  String get go => 'పద!';

  @override
  String get you => 'నువ్వు';

  @override
  String get computer => 'కంప్యూటర్';

  @override
  String get raceWon => 'నువ్వు పందెం గెలిచావు!';

  @override
  String get raceLost => 'మంచి పందెం! ఇంకొంచెం సాధన చేస్తే తర్వాతి సారి గెలుస్తావు.';

  @override
  String chestOpened(int n) {
    return 'పెట్టె తెరుచుకుంది! +$n నాణేలు';
  }

  @override
  String get chestStreakReset => 'మళ్ళీ 5 మొదలుపెడదాం!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count పెట్టెలు తెరుచుకున్నాయి',
      one: '1 పెట్టె తెరుచుకుంది',
      zero: 'ఇంకా పెట్టె లేదు',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'ఉత్తమం: $n';
  }

  @override
  String get newBest => 'కొత్త రికార్డు!';

  @override
  String get clear => 'తుడిచివేయి';

  @override
  String get pickTable => 'ఎక్కం ఎంచుకో';

  @override
  String get learn => 'నేర్చుకో';

  @override
  String get quiz => 'క్విజ్';

  @override
  String tableOf(int n) {
    return '$n ఎక్కం';
  }

  @override
  String get listen => 'విను';

  @override
  String get pause => 'ఆపు';

  @override
  String get startQuiz => 'క్విజ్ మొదలుపెట్టు';

  @override
  String get mastered => 'నేర్చుకున్నది';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'రౌండ్ పూర్తయింది!';

  @override
  String get correctLabel => 'సరైనవి';

  @override
  String get practiseLabel => 'సాధనకు';

  @override
  String get practiseThese => 'వీటిని సాధన చేద్దాం';

  @override
  String coinsEarned(int n) {
    return '+$n నాణేలు';
  }

  @override
  String get playAgain => 'మళ్ళీ ఆడు';

  @override
  String get home => 'హోమ్';

  @override
  String get resultMsg3 => 'అద్భుతం! నువ్వు గణిత తార!';

  @override
  String get resultMsg2 => 'చాలా బాగా చేశావు!';

  @override
  String get resultMsg1 => 'బాగుంది! సాధన కొనసాగించు!';

  @override
  String get resultMsg0 => 'మంచి ప్రయత్నం! ప్రతి రౌండ్‌తో నువ్వు ఇంకా మెరుగవుతావు!';

  @override
  String get allCorrect => 'అన్నీ సరైనవే!';

  @override
  String newTopicUnlocked(String topic) {
    return 'కొత్త అంశం తెరుచుకుంది: $topic';
  }

  @override
  String streakNow(String days) {
    return 'వరుస రోజులు: $days';
  }

  @override
  String get shop => 'దుకాణం';

  @override
  String get avatars => 'బొమ్మలు';

  @override
  String get carColours => 'కారు రంగులు';

  @override
  String get balloonThemes => 'బెలూన్లు';

  @override
  String get buy => 'కొను';

  @override
  String get use => 'వాడు';

  @override
  String get inUse => 'వాడుకలో ఉంది';

  @override
  String needMoreCoins(int n) {
    return 'ఇంకా $n నాణేలు సంపాదించడానికి ఆడు!';
  }

  @override
  String get bought => 'ఇప్పుడు ఇది నీది!';

  @override
  String get color_red => 'ఎరుపు';

  @override
  String get color_blue => 'నీలం';

  @override
  String get color_green => 'ఆకుపచ్చ';

  @override
  String get color_yellow => 'పసుపు';

  @override
  String get color_purple => 'ఊదా';

  @override
  String get color_orange => 'నారింజ';

  @override
  String get color_pink => 'గులాబీ';

  @override
  String get color_black => 'నలుపు';

  @override
  String get theme_rainbow => 'ఇంద్రధనుస్సు';

  @override
  String get theme_pastel => 'లేత రంగులు';

  @override
  String get theme_ocean => 'సముద్రం';

  @override
  String get theme_sunset => 'సూర్యాస్తమయం';

  @override
  String get theme_candy => 'మిఠాయి';

  @override
  String get badges => 'బ్యాడ్జీలు';

  @override
  String badgeTableMaster(int n) {
    return '$n ఎక్కం మాస్టర్';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n ఎక్కంలోని ప్రతి వరుస నేర్చుకో';
  }

  @override
  String get badgeStreak7 => '7 రోజుల వరుస';

  @override
  String get badgeStreak7Desc => 'వరుసగా 7 రోజులు నేటి సవాలు చేయి';

  @override
  String get badgeStreak30 => '30 రోజుల వరుస';

  @override
  String get badgeStreak30Desc => 'వరుసగా 30 రోజులు నేటి సవాలు చేయి';

  @override
  String get badgeDay100 => 'ఒకే రోజు 100 లెక్కలు';

  @override
  String get badgeDay100Desc => 'ఒకే రోజులో 100 లెక్కలు చేయి';

  @override
  String get badgeSpeedStar => 'వేగ తార';

  @override
  String get badgeSpeedStarDesc => 'వేగం సవాలులో 20 లేదా ఎక్కువ సరైనవి';

  @override
  String get newBadge => 'కొత్త బ్యాడ్జి!';

  @override
  String get yay => 'హుర్రే!';

  @override
  String get forParents => 'తల్లిదండ్రుల కోసం';

  @override
  String get enterPin => 'తల్లిదండ్రుల PIN ఇవ్వండి';

  @override
  String get createPin => '4 అంకెల PIN సృష్టించండి';

  @override
  String get confirmPin => 'అదే PIN మళ్ళీ ఇవ్వండి';

  @override
  String get newPin => 'కొత్త 4 అంకెల PIN ఇవ్వండి';

  @override
  String get pinMismatch => 'రెండు PINలు వేరుగా ఉన్నాయి. మళ్ళీ ప్రయత్నించండి.';

  @override
  String get pinWrong => 'PIN సరైనది కాదు. మళ్ళీ ప్రయత్నించండి.';

  @override
  String get pinForParents => 'పెద్దలకు మాత్రమే';

  @override
  String get pinForgot => 'PIN మర్చిపోయారా? ఫోన్ సెట్టింగ్స్‌లో ఈ యాప్ డేటా తుడిచేస్తే PIN, మొత్తం ప్రగతి పోతాయి.';

  @override
  String get pinChanged => 'PIN మారింది';

  @override
  String get progress => 'ప్రగతి';

  @override
  String get totalSums => 'చేసిన లెక్కలు';

  @override
  String get accuracy => 'ఖచ్చితత్వం';

  @override
  String get factsMastered => 'నేర్చుకున్న లెక్కలు';

  @override
  String get daysPractised => 'సాధన చేసిన రోజులు';

  @override
  String get accuracyPerTopic => 'అంశాల వారీ ఖచ్చితత్వం';

  @override
  String get speedOverTime => 'ఒక్కో లెక్కకు సగటు సెకన్లు';

  @override
  String get weakFacts => 'సాధన అవసరమైన లెక్కలు';

  @override
  String get noWeakFacts => 'ఇప్పుడు ఏదీ కష్టంగా లేదు. భలే!';

  @override
  String get noDataYet => 'ఇంకా సాధన లేదు.';

  @override
  String triesRight(int n, int pct) {
    return '$n ప్రయత్నాలు · $pct% సరైనవి';
  }

  @override
  String get settings => 'సెట్టింగ్స్';

  @override
  String get language => 'భాష';

  @override
  String get sound => 'శబ్దం';

  @override
  String get music => 'సంగీతం';

  @override
  String get dailyReminder => 'రోజువారీ గుర్తు';

  @override
  String get reminderTime => 'గుర్తు చేసే సమయం';

  @override
  String get notificationsBlocked => 'ఫోన్ సెట్టింగ్స్‌లో ఈ యాప్ నోటిఫికేషన్లు ఆఫ్‌లో ఉన్నాయి.';

  @override
  String get changePin => 'తల్లిదండ్రుల PIN మార్చు';

  @override
  String get resetProgress => 'ప్రగతిని తుడిచివేయి';

  @override
  String resetProgressBody(String name) {
    return 'ఇది $name యొక్క అన్ని స్కోర్లు, నాణేలు, బ్యాడ్జీలు, తెరిచిన స్థాయిలను తుడిచివేస్తుంది.';
  }

  @override
  String get reset => 'తుడిచివేయి';

  @override
  String get cancel => 'రద్దు';

  @override
  String get progressReset => 'ప్రగతి తుడిచివేయబడింది';

  @override
  String get removeChild => 'ఈ పిల్లవాడిని తొలగించు';

  @override
  String removeChildBody(String name) {
    return '$name ను, వారి మొత్తం ప్రగతిని ఈ ఫోన్ నుండి తొలగించాలా?';
  }

  @override
  String get remove => 'తొలగించు';

  @override
  String get child => 'పిల్లవాడు';

  @override
  String get about => 'యాప్ గురించి';

  @override
  String get aboutBody =>
      'ఈ యాప్ 1–8 తరగతుల పిల్లలు చిన్న, సరదా రౌండ్లలో గణితం సాధన చేయడానికి సహాయపడుతుంది. ఇది పూర్తిగా ఆఫ్‌లైన్‌లో పనిచేస్తుంది, ప్రకటనలు లేవు, ఖాతా అవసరం లేదు. పిల్లల మొదటి పేరు, తరగతి మాత్రమే, ఈ ఫోన్‌లో మాత్రమే ఉంటాయి.';

  @override
  String version(String v) {
    return 'వెర్షన్ $v';
  }

  @override
  String get licenses => 'లైసెన్సులు';

  @override
  String get close => 'మూసివేయి';

  @override
  String get reminderBody => 'నేటి గణిత సవాలు సమయం వచ్చింది!';

  @override
  String get reminderChannel => 'రోజువారీ గుర్తు';

  @override
  String get lockedLevelSnack => 'ఈ స్థాయిని తెరవడానికి సాధన కొనసాగించు!';

  @override
  String get hearAgain => 'మళ్ళీ విను';
}

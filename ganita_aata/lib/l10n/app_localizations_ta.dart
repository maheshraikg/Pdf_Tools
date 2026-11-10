// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'கணித ஆட்டம்';

  @override
  String get chooseLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get continueBtn => 'தொடரவும்';

  @override
  String get welcome => 'வரவேற்கிறோம்!';

  @override
  String get profileSetupTitle => 'யார் விளையாடுகிறார்கள்?';

  @override
  String get editProfile => 'விவரங்களை மாற்று';

  @override
  String get childName => 'குழந்தையின் முதல் பெயர்';

  @override
  String get nameRequired => 'தயவுசெய்து பெயரை எழுதவும்';

  @override
  String get schoolClass => 'வகுப்பு';

  @override
  String classN(int n) {
    return 'வகுப்பு $n';
  }

  @override
  String classRange(int from, int to) {
    return 'வகுப்பு $from–$to';
  }

  @override
  String get chooseAvatar => 'படத்தைத் தேர்ந்தெடு';

  @override
  String get save => 'சேமி';

  @override
  String get addChild => 'குழந்தையைச் சேர்';

  @override
  String get switchChild => 'யார் விளையாடுகிறார்கள்?';

  @override
  String helloName(String name) {
    return 'வணக்கம், $name!';
  }

  @override
  String get greetingSub => 'எண்களுடன் விளையாடத் தயாரா?';

  @override
  String get dailyChallenge => 'இன்றைய சவால்';

  @override
  String get dailyChallengeDesc => '10 கணக்குகள் – இன்று எல்லோருக்கும் ஒன்றே!';

  @override
  String get dailyDone => 'இன்று முடிந்தது! நாளை மீண்டும் வா.';

  @override
  String get start => 'தொடங்கு';

  @override
  String get playAgainToday => 'மீண்டும் விளையாடு';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count நாட்கள்', one: '1 நாள்');
    return '$_temp0';
  }

  @override
  String get streak => 'தொடர்';

  @override
  String get coins => 'நாணயங்கள்';

  @override
  String get play => 'விளையாடு';

  @override
  String get games => 'விளையாட்டுகள்';

  @override
  String currentTopic(String topic) {
    return 'தலைப்பு: $topic';
  }

  @override
  String get change => 'மாற்று';

  @override
  String get gameBalloon => 'பலூன் உடை';

  @override
  String get gameBalloonDesc => 'சரியான விடை உள்ள பலூனை உடை';

  @override
  String get gameRace => 'கார் பந்தயம்';

  @override
  String get gameRaceDesc => 'சரியான விடைகளால் உன் கார் ஓடும்';

  @override
  String get gameTreasure => 'புதையல் வேட்டை';

  @override
  String get gameTreasureDesc => 'தொடர்ந்து 5 சரியான விடைகள் பெட்டியைத் திறக்கும்';

  @override
  String get gameTables => 'வாய்ப்பாடு மாஸ்டர்';

  @override
  String get gameTablesDesc => '2–20 வாய்ப்பாடுகளைக் கற்று பயிற்சி செய்';

  @override
  String get gameSpeed => 'வேகச் சவால்';

  @override
  String get gameSpeedDesc => '60 வினாடிகளில் எத்தனை?';

  @override
  String get levelMap => 'நிலைகளின் வரைபடம்';

  @override
  String levelN(int n) {
    return 'நிலை $n';
  }

  @override
  String get locked => 'பூட்டப்பட்டது';

  @override
  String get lockedHint => 'இதைத் திறக்க முந்தைய தலைப்பில் 85%க்கு மேல் சரியாகச் செய்.';

  @override
  String get chooseTopic => 'தலைப்பைத் தேர்ந்தெடு';

  @override
  String get chooseGame => 'விளையாட்டைத் தேர்ந்தெடு';

  @override
  String get topic_num100 => '100 வரையிலான எண்கள்';

  @override
  String get topic_add1 => 'ஒரு இலக்கக் கூட்டல்';

  @override
  String get topic_sub1 => 'ஒரு இலக்கக் கழித்தல்';

  @override
  String get topic_add2 => 'இரண்டு இலக்கக் கூட்டல்';

  @override
  String get topic_sub2 => 'இரண்டு இலக்கக் கழித்தல்';

  @override
  String get topic_tab2_5 => '2–5 வாய்ப்பாடுகள்';

  @override
  String get topic_tab6_10 => '6–10 வாய்ப்பாடுகள்';

  @override
  String get topic_add3 => 'மூன்று இலக்கக் கூட்டல்';

  @override
  String get topic_sub3 => 'மூன்று இலக்கக் கழித்தல்';

  @override
  String get topic_div1 => 'எளிய வகுத்தல்';

  @override
  String get topic_tab11_20 => '11–20 வாய்ப்பாடுகள்';

  @override
  String get topic_mul21 => 'இரண்டு இலக்கம் × ஒரு இலக்கம்';

  @override
  String get topic_divRem => 'மீதியுடன் வகுத்தல்';

  @override
  String get topic_mixed => 'கலப்புச் செயல்கள்';

  @override
  String get topic_squares => '1–30 வர்க்கங்கள்';

  @override
  String get topic_cubes => '1–15 கனங்கள்';

  @override
  String get topic_percent => 'சதவீதம்';

  @override
  String get topic_fractions => 'எளிய பின்னங்கள்';

  @override
  String qAfter(int n) {
    return '$nக்குப் பிறகு வரும் எண் எது?';
  }

  @override
  String qBefore(int n) {
    return '$nக்கு முன் வரும் எண் எது?';
  }

  @override
  String qTenMore(int n) {
    return '$nஐ விட 10 அதிகம்';
  }

  @override
  String qTenLess(int n) {
    return '$nஐ விட 10 குறைவு';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$nஇன் $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$nஇன் $fraction';
  }

  @override
  String get remainderShort => 'மீ';

  @override
  String get score => 'மதிப்பெண்';

  @override
  String secondsShort(int n) {
    return '$n வி';
  }

  @override
  String get quitGameTitle => 'இந்தச் சுற்றை நிறுத்தவா?';

  @override
  String get quitGameBody => 'இந்தச் சுற்றின் நாணயங்கள் சேர்க்கப்படாது.';

  @override
  String get keepPlaying => 'தொடர்ந்து விளையாடு';

  @override
  String get stop => 'நிறுத்து';

  @override
  String answerIs(String answer) {
    return 'விடை $answer';
  }

  @override
  String get praise => 'சூப்பர்!|அருமை!|மிக நன்று!|சபாஷ்!|நீ ஒரு நட்சத்திரம்!|அற்புதம்!';

  @override
  String get encourage =>
      'மீண்டும் முயற்சி செய், உன்னால் முடியும்!|கிட்டத்தட்ட! தொடர்ந்து செய்!|நல்ல முயற்சி! இதோ அடுத்தது.|அருமையான முயற்சி! நீ கற்றுக்கொண்டிருக்கிறாய்!';

  @override
  String get getReady => 'தயாராகு!';

  @override
  String get go => 'போ!';

  @override
  String get you => 'நீ';

  @override
  String get computer => 'கணினி';

  @override
  String get raceWon => 'நீ பந்தயத்தில் வென்றாய்!';

  @override
  String get raceLost => 'நல்ல பந்தயம்! இன்னும் கொஞ்சம் பயிற்சி செய், அடுத்த முறை வெல்வாய்.';

  @override
  String chestOpened(int n) {
    return 'பெட்டி திறந்தது! +$n நாணயங்கள்';
  }

  @override
  String get chestStreakReset => 'மீண்டும் 5 தொடங்கு!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count பெட்டிகள் திறந்தன',
      one: '1 பெட்டி திறந்தது',
      zero: 'இன்னும் பெட்டி இல்லை',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'சிறந்தது: $n';
  }

  @override
  String get newBest => 'புதிய சாதனை!';

  @override
  String get clear => 'அழி';

  @override
  String get pickTable => 'வாய்ப்பாட்டைத் தேர்ந்தெடு';

  @override
  String get learn => 'கற்றுக்கொள்';

  @override
  String get quiz => 'வினாடி வினா';

  @override
  String tableOf(int n) {
    return '$n வாய்ப்பாடு';
  }

  @override
  String get listen => 'கேள்';

  @override
  String get pause => 'நிறுத்து';

  @override
  String get startQuiz => 'வினாடி வினா தொடங்கு';

  @override
  String get mastered => 'தேர்ச்சி';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'சுற்று முடிந்தது!';

  @override
  String get correctLabel => 'சரி';

  @override
  String get practiseLabel => 'பயிற்சிக்கு';

  @override
  String get practiseThese => 'இவற்றைப் பயிற்சி செய்வோம்';

  @override
  String coinsEarned(int n) {
    return '+$n நாணயங்கள்';
  }

  @override
  String get playAgain => 'மீண்டும் விளையாடு';

  @override
  String get home => 'முகப்பு';

  @override
  String get resultMsg3 => 'அற்புதம்! நீ கணித நட்சத்திரம்!';

  @override
  String get resultMsg2 => 'மிக நன்று!';

  @override
  String get resultMsg1 => 'நல்லது! தொடர்ந்து பயிற்சி செய்!';

  @override
  String get resultMsg0 => 'நல்ல முயற்சி! ஒவ்வொரு சுற்றிலும் நீ மேம்படுவாய்!';

  @override
  String get allCorrect => 'எல்லாம் சரி!';

  @override
  String newTopicUnlocked(String topic) {
    return 'புதிய தலைப்பு திறந்தது: $topic';
  }

  @override
  String streakNow(String days) {
    return 'தொடர் நாட்கள்: $days';
  }

  @override
  String get shop => 'கடை';

  @override
  String get avatars => 'படங்கள்';

  @override
  String get carColours => 'கார் நிறங்கள்';

  @override
  String get balloonThemes => 'பலூன்கள்';

  @override
  String get buy => 'வாங்கு';

  @override
  String get use => 'பயன்படுத்து';

  @override
  String get inUse => 'பயன்பாட்டில்';

  @override
  String needMoreCoins(int n) {
    return 'இன்னும் $n நாணயங்கள் பெற விளையாடு!';
  }

  @override
  String get bought => 'இப்போது இது உன்னுடையது!';

  @override
  String get color_red => 'சிவப்பு';

  @override
  String get color_blue => 'நீலம்';

  @override
  String get color_green => 'பச்சை';

  @override
  String get color_yellow => 'மஞ்சள்';

  @override
  String get color_purple => 'ஊதா';

  @override
  String get color_orange => 'ஆரஞ்சு';

  @override
  String get color_pink => 'இளஞ்சிவப்பு';

  @override
  String get color_black => 'கருப்பு';

  @override
  String get theme_rainbow => 'வானவில்';

  @override
  String get theme_pastel => 'மென் நிறங்கள்';

  @override
  String get theme_ocean => 'கடல்';

  @override
  String get theme_sunset => 'சூரிய அஸ்தமனம்';

  @override
  String get theme_candy => 'மிட்டாய்';

  @override
  String get badges => 'பதக்கங்கள்';

  @override
  String badgeTableMaster(int n) {
    return '$n வாய்ப்பாடு மாஸ்டர்';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n வாய்ப்பாட்டின் ஒவ்வொரு வரியிலும் தேர்ச்சி பெறு';
  }

  @override
  String get badgeStreak7 => '7 நாள் தொடர்';

  @override
  String get badgeStreak7Desc => 'தொடர்ந்து 7 நாட்கள் இன்றைய சவாலைச் செய்';

  @override
  String get badgeStreak30 => '30 நாள் தொடர்';

  @override
  String get badgeStreak30Desc => 'தொடர்ந்து 30 நாட்கள் இன்றைய சவாலைச் செய்';

  @override
  String get badgeDay100 => 'ஒரே நாளில் 100 கணக்குகள்';

  @override
  String get badgeDay100Desc => 'ஒரே நாளில் 100 கணக்குகளைத் தீர்';

  @override
  String get badgeSpeedStar => 'வேக நட்சத்திரம்';

  @override
  String get badgeSpeedStarDesc => 'வேகச் சவாலில் 20 அல்லது அதிகம் சரி';

  @override
  String get newBadge => 'புதிய பதக்கம்!';

  @override
  String get yay => 'ஹேய்!';

  @override
  String get forParents => 'பெற்றோருக்கு';

  @override
  String get enterPin => 'பெற்றோர் PIN-ஐ உள்ளிடவும்';

  @override
  String get createPin => '4 இலக்க PIN-ஐ உருவாக்கவும்';

  @override
  String get confirmPin => 'அதே PIN-ஐ மீண்டும் உள்ளிடவும்';

  @override
  String get newPin => 'புதிய 4 இலக்க PIN-ஐ உள்ளிடவும்';

  @override
  String get pinMismatch => 'இரண்டு PIN-களும் வேறுபட்டன. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get pinWrong => 'PIN தவறு. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get pinForParents => 'பெரியவர்களுக்கு மட்டும்';

  @override
  String get pinForgot =>
      'PIN மறந்துவிட்டதா? போன் அமைப்புகளில் இந்த ஆப்பின் தரவை அழித்தால் PIN மற்றும் எல்லா முன்னேற்றமும் அழியும்.';

  @override
  String get pinChanged => 'PIN மாற்றப்பட்டது';

  @override
  String get progress => 'முன்னேற்றம்';

  @override
  String get totalSums => 'தீர்த்த கணக்குகள்';

  @override
  String get accuracy => 'துல்லியம்';

  @override
  String get factsMastered => 'தேர்ச்சி பெற்ற கணக்குகள்';

  @override
  String get daysPractised => 'பயிற்சி நாட்கள்';

  @override
  String get accuracyPerTopic => 'தலைப்பு வாரியான துல்லியம்';

  @override
  String get speedOverTime => 'ஒரு கணக்குக்கு சராசரி வினாடிகள்';

  @override
  String get weakFacts => 'பயிற்சி தேவைப்படும் கணக்குகள்';

  @override
  String get noWeakFacts => 'இப்போது எதுவும் கடினமில்லை. சபாஷ்!';

  @override
  String get noDataYet => 'இன்னும் பயிற்சி இல்லை.';

  @override
  String triesRight(int n, int pct) {
    return '$n முயற்சி · $pct% சரி';
  }

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get sound => 'ஒலி';

  @override
  String get music => 'இசை';

  @override
  String get dailyReminder => 'தினசரி நினைவூட்டல்';

  @override
  String get reminderTime => 'நினைவூட்டல் நேரம்';

  @override
  String get notificationsBlocked => 'போன் அமைப்புகளில் இந்த ஆப்பின் அறிவிப்புகள் அணைக்கப்பட்டுள்ளன.';

  @override
  String get changePin => 'பெற்றோர் PIN-ஐ மாற்று';

  @override
  String get resetProgress => 'முன்னேற்றத்தை அழி';

  @override
  String resetProgressBody(String name) {
    return 'இது $nameஇன் எல்லா மதிப்பெண்கள், நாணயங்கள், பதக்கங்கள் மற்றும் திறந்த நிலைகளை அழிக்கும்.';
  }

  @override
  String get reset => 'அழி';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get progressReset => 'முன்னேற்றம் அழிக்கப்பட்டது';

  @override
  String get removeChild => 'இந்தக் குழந்தையை நீக்கு';

  @override
  String removeChildBody(String name) {
    return '$name மற்றும் அவர்களின் எல்லா முன்னேற்றத்தையும் இந்தப் போனிலிருந்து நீக்கவா?';
  }

  @override
  String get remove => 'நீக்கு';

  @override
  String get child => 'குழந்தை';

  @override
  String get about => 'ஆப் பற்றி';

  @override
  String get aboutBody =>
      'இந்த ஆப் 1–8 வகுப்புக் குழந்தைகள் சிறிய, வேடிக்கையான சுற்றுகளில் கணிதப் பயிற்சி செய்ய உதவுகிறது. இது முழுவதும் ஆஃப்லைனில் இயங்கும், விளம்பரங்கள் இல்லை, கணக்கு தேவையில்லை. குழந்தையின் முதல் பெயரும் வகுப்பும் மட்டும், இந்தப் போனில் மட்டும் சேமிக்கப்படும்.';

  @override
  String version(String v) {
    return 'பதிப்பு $v';
  }

  @override
  String get licenses => 'உரிமங்கள்';

  @override
  String get close => 'மூடு';

  @override
  String get reminderBody => 'இன்றைய கணிதச் சவாலுக்கான நேரம்!';

  @override
  String get reminderChannel => 'தினசரி நினைவூட்டல்';

  @override
  String get lockedLevelSnack => 'இந்த நிலையைத் திறக்கத் தொடர்ந்து பயிற்சி செய்!';

  @override
  String get hearAgain => 'மீண்டும் கேள்';
}

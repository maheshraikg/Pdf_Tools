// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'ગણિત રમત';

  @override
  String get chooseLanguage => 'ભાષા પસંદ કરો';

  @override
  String get continueBtn => 'આગળ વધો';

  @override
  String get welcome => 'સ્વાગત છે!';

  @override
  String get profileSetupTitle => 'કોણ રમે છે?';

  @override
  String get editProfile => 'વિગતો બદલો';

  @override
  String get childName => 'બાળકનું પહેલું નામ';

  @override
  String get nameRequired => 'કૃપા કરી નામ લખો';

  @override
  String get schoolClass => 'ધોરણ';

  @override
  String classN(int n) {
    return 'ધોરણ $n';
  }

  @override
  String classRange(int from, int to) {
    return 'ધોરણ $from–$to';
  }

  @override
  String get chooseAvatar => 'ચિત્ર પસંદ કરો';

  @override
  String get save => 'સાચવો';

  @override
  String get addChild => 'બાળક ઉમેરો';

  @override
  String get switchChild => 'કોણ રમે છે?';

  @override
  String helloName(String name) {
    return 'નમસ્તે, $name!';
  }

  @override
  String get greetingSub => 'સંખ્યાઓ સાથે રમવા તૈયાર?';

  @override
  String get dailyChallenge => 'આજની ચેલેન્જ';

  @override
  String get dailyChallengeDesc => '10 દાખલા – આજે બધા માટે સરખા!';

  @override
  String get dailyDone => 'આજનું પૂરું! કાલે ફરી આવજો.';

  @override
  String get start => 'શરૂ કરો';

  @override
  String get playAgainToday => 'ફરી રમો';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count દિવસ', one: '1 દિવસ');
    return '$_temp0';
  }

  @override
  String get streak => 'સળંગ';

  @override
  String get coins => 'સિક્કા';

  @override
  String get play => 'રમો';

  @override
  String get games => 'રમતો';

  @override
  String currentTopic(String topic) {
    return 'વિષય: $topic';
  }

  @override
  String get change => 'બદલો';

  @override
  String get gameBalloon => 'ફુગ્ગો ફોડો';

  @override
  String get gameBalloonDesc => 'સાચા જવાબવાળો ફુગ્ગો ફોડો';

  @override
  String get gameRace => 'કાર રેસ';

  @override
  String get gameRaceDesc => 'સાચા જવાબથી તારી કાર દોડશે';

  @override
  String get gameTreasure => 'ખજાનાની શોધ';

  @override
  String get gameTreasureDesc => 'સળંગ 5 સાચા જવાબથી પેટી ખૂલે છે';

  @override
  String get gameTables => 'ઘડિયા માસ્ટર';

  @override
  String get gameTablesDesc => '2–20 ના ઘડિયા શીખો અને મહાવરો કરો';

  @override
  String get gameSpeed => 'ઝડપ ચેલેન્જ';

  @override
  String get gameSpeedDesc => '60 સેકન્ડમાં કેટલા?';

  @override
  String get levelMap => 'સ્તરોનો નકશો';

  @override
  String levelN(int n) {
    return 'સ્તર $n';
  }

  @override
  String get locked => 'બંધ';

  @override
  String get lockedHint => 'આ ખોલવા પાછલા વિષયમાં 85% થી વધુ સાચું કરો.';

  @override
  String get chooseTopic => 'વિષય પસંદ કરો';

  @override
  String get chooseGame => 'રમત પસંદ કરો';

  @override
  String get topic_num100 => '100 સુધીની સંખ્યાઓ';

  @override
  String get topic_add1 => 'એક અંકનો સરવાળો';

  @override
  String get topic_sub1 => 'એક અંકની બાદબાકી';

  @override
  String get topic_add2 => 'બે અંકનો સરવાળો';

  @override
  String get topic_sub2 => 'બે અંકની બાદબાકી';

  @override
  String get topic_tab2_5 => '2–5 ના ઘડિયા';

  @override
  String get topic_tab6_10 => '6–10 ના ઘડિયા';

  @override
  String get topic_add3 => 'ત્રણ અંકનો સરવાળો';

  @override
  String get topic_sub3 => 'ત્રણ અંકની બાદબાકી';

  @override
  String get topic_div1 => 'સરળ ભાગાકાર';

  @override
  String get topic_tab11_20 => '11–20 ના ઘડિયા';

  @override
  String get topic_mul21 => 'બે અંક × એક અંક';

  @override
  String get topic_divRem => 'શેષ સાથે ભાગાકાર';

  @override
  String get topic_mixed => 'મિશ્ર ક્રિયાઓ';

  @override
  String get topic_squares => '1–30 ના વર્ગ';

  @override
  String get topic_cubes => '1–15 ના ઘન';

  @override
  String get topic_percent => 'ટકા';

  @override
  String get topic_fractions => 'સરળ અપૂર્ણાંક';

  @override
  String qAfter(int n) {
    return '$n પછી કઈ સંખ્યા આવે?';
  }

  @override
  String qBefore(int n) {
    return '$n પહેલાં કઈ સંખ્યા આવે?';
  }

  @override
  String qTenMore(int n) {
    return '$n કરતાં 10 વધુ';
  }

  @override
  String qTenLess(int n) {
    return '$n કરતાં 10 ઓછા';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n ના $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n નો $fraction';
  }

  @override
  String get remainderShort => 'શે';

  @override
  String get score => 'ગુણ';

  @override
  String secondsShort(int n) {
    return '$n સે';
  }

  @override
  String get quitGameTitle => 'આ રાઉન્ડ બંધ કરવો છે?';

  @override
  String get quitGameBody => 'આ રાઉન્ડના સિક્કા ઉમેરાશે નહીં.';

  @override
  String get keepPlaying => 'રમતા રહો';

  @override
  String get stop => 'બંધ કરો';

  @override
  String answerIs(String answer) {
    return 'જવાબ છે $answer';
  }

  @override
  String get praise => 'શાબાશ!|ખૂબ સરસ!|અદ્ભુત!|મજા આવી!|તું તો સ્ટાર છે!|વાહ!';

  @override
  String get encourage =>
      'ફરી પ્રયત્ન કર, તું કરી શકે છે!|લગભગ! આગળ વધ!|સારો પ્રયત્ન! આ રહ્યો બીજો.|સરસ પ્રયત્ન! તું શીખી રહ્યો છે!';

  @override
  String get getReady => 'તૈયાર થાઓ!';

  @override
  String get go => 'ચાલો!';

  @override
  String get you => 'તું';

  @override
  String get computer => 'કમ્પ્યુટર';

  @override
  String get raceWon => 'તું રેસ જીતી ગયો!';

  @override
  String get raceLost => 'સરસ રેસ! થોડો વધુ મહાવરો કર, આવતી વખતે જીતીશ.';

  @override
  String chestOpened(int n) {
    return 'પેટી ખૂલી! +$n સિક્કા';
  }

  @override
  String get chestStreakReset => 'ફરી 5 શરૂ કરીએ!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count પેટીઓ ખૂલી',
      one: '1 પેટી ખૂલી',
      zero: 'હજુ કોઈ પેટી નથી',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'શ્રેષ્ઠ: $n';
  }

  @override
  String get newBest => 'નવો રેકોર્ડ!';

  @override
  String get clear => 'ભૂંસો';

  @override
  String get pickTable => 'ઘડિયો પસંદ કરો';

  @override
  String get learn => 'શીખો';

  @override
  String get quiz => 'ક્વિઝ';

  @override
  String tableOf(int n) {
    return '$n નો ઘડિયો';
  }

  @override
  String get listen => 'સાંભળો';

  @override
  String get pause => 'રોકો';

  @override
  String get startQuiz => 'ક્વિઝ શરૂ કરો';

  @override
  String get mastered => 'પાકું';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'રાઉન્ડ પૂરો!';

  @override
  String get correctLabel => 'સાચા';

  @override
  String get practiseLabel => 'મહાવરા માટે';

  @override
  String get practiseThese => 'ચાલો આનો મહાવરો કરીએ';

  @override
  String coinsEarned(int n) {
    return '+$n સિક્કા';
  }

  @override
  String get playAgain => 'ફરી રમો';

  @override
  String get home => 'હોમ';

  @override
  String get resultMsg3 => 'અદ્ભુત! તું ગણિતનો તારો છે!';

  @override
  String get resultMsg2 => 'ખૂબ સરસ કામ!';

  @override
  String get resultMsg1 => 'સરસ! મહાવરો ચાલુ રાખ!';

  @override
  String get resultMsg0 => 'સારો પ્રયત્ન! દરેક રાઉન્ડમાં તું વધુ સારો બનીશ!';

  @override
  String get allCorrect => 'બધા સાચા!';

  @override
  String newTopicUnlocked(String topic) {
    return 'નવો વિષય ખૂલ્યો: $topic';
  }

  @override
  String streakNow(String days) {
    return 'સળંગ દિવસ: $days';
  }

  @override
  String get shop => 'દુકાન';

  @override
  String get avatars => 'ચિત્રો';

  @override
  String get carColours => 'કારના રંગ';

  @override
  String get balloonThemes => 'ફુગ્ગા';

  @override
  String get buy => 'ખરીદો';

  @override
  String get use => 'વાપરો';

  @override
  String get inUse => 'વપરાશમાં';

  @override
  String needMoreCoins(int n) {
    return 'વધુ $n સિક્કા મેળવવા રમો!';
  }

  @override
  String get bought => 'હવે આ તારું છે!';

  @override
  String get color_red => 'લાલ';

  @override
  String get color_blue => 'વાદળી';

  @override
  String get color_green => 'લીલો';

  @override
  String get color_yellow => 'પીળો';

  @override
  String get color_purple => 'જાંબલી';

  @override
  String get color_orange => 'નારંગી';

  @override
  String get color_pink => 'ગુલાબી';

  @override
  String get color_black => 'કાળો';

  @override
  String get theme_rainbow => 'મેઘધનુષ';

  @override
  String get theme_pastel => 'આછા રંગ';

  @override
  String get theme_ocean => 'સમુદ્ર';

  @override
  String get theme_sunset => 'સૂર્યાસ્ત';

  @override
  String get theme_candy => 'ચોકલેટ';

  @override
  String get badges => 'બેજ';

  @override
  String badgeTableMaster(int n) {
    return '$n નો ઘડિયો માસ્ટર';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n ના ઘડિયાની દરેક લીટી પાકી કર';
  }

  @override
  String get badgeStreak7 => 'સળંગ 7 દિવસ';

  @override
  String get badgeStreak7Desc => 'સળંગ 7 દિવસ આજની ચેલેન્જ કર';

  @override
  String get badgeStreak30 => 'સળંગ 30 દિવસ';

  @override
  String get badgeStreak30Desc => 'સળંગ 30 દિવસ આજની ચેલેન્જ કર';

  @override
  String get badgeDay100 => 'એક દિવસમાં 100 દાખલા';

  @override
  String get badgeDay100Desc => 'એક જ દિવસમાં 100 દાખલા ગણ';

  @override
  String get badgeSpeedStar => 'ઝડપનો તારો';

  @override
  String get badgeSpeedStarDesc => 'ઝડપ ચેલેન્જમાં 20 કે વધુ સાચા';

  @override
  String get newBadge => 'નવો બેજ!';

  @override
  String get yay => 'હુર્રે!';

  @override
  String get forParents => 'વાલીઓ માટે';

  @override
  String get enterPin => 'વાલીનો PIN નાખો';

  @override
  String get createPin => '4 અંકનો PIN બનાવો';

  @override
  String get confirmPin => 'એ જ PIN ફરી નાખો';

  @override
  String get newPin => 'નવો 4 અંકનો PIN નાખો';

  @override
  String get pinMismatch => 'બંને PIN અલગ હતા. ફરી પ્રયત્ન કરો.';

  @override
  String get pinWrong => 'PIN સાચો નથી. ફરી પ્રયત્ન કરો.';

  @override
  String get pinForParents => 'ફક્ત મોટાઓ માટે';

  @override
  String get pinForgot => 'PIN ભૂલી ગયા? ફોન સેટિંગ્સમાં આ એપનો ડેટા ભૂંસવાથી PIN અને બધી પ્રગતિ ભૂંસાઈ જશે.';

  @override
  String get pinChanged => 'PIN બદલાયો';

  @override
  String get progress => 'પ્રગતિ';

  @override
  String get totalSums => 'ગણેલા દાખલા';

  @override
  String get accuracy => 'ચોકસાઈ';

  @override
  String get factsMastered => 'પાકા દાખલા';

  @override
  String get daysPractised => 'મહાવરાના દિવસ';

  @override
  String get accuracyPerTopic => 'વિષય મુજબ ચોકસાઈ';

  @override
  String get speedOverTime => 'દરેક દાખલે સરેરાશ સેકન્ડ';

  @override
  String get weakFacts => 'મહાવરો જોઈએ એવા દાખલા';

  @override
  String get noWeakFacts => 'હમણાં કંઈ અઘરું નથી. શાબાશ!';

  @override
  String get noDataYet => 'હજુ મહાવરો થયો નથી.';

  @override
  String triesRight(int n, int pct) {
    return '$n પ્રયત્ન · $pct% સાચા';
  }

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get language => 'ભાષા';

  @override
  String get sound => 'અવાજ';

  @override
  String get music => 'સંગીત';

  @override
  String get dailyReminder => 'રોજનું રીમાઇન્ડર';

  @override
  String get reminderTime => 'રીમાઇન્ડરનો સમય';

  @override
  String get notificationsBlocked => 'ફોન સેટિંગ્સમાં આ એપની સૂચનાઓ બંધ છે.';

  @override
  String get changePin => 'વાલીનો PIN બદલો';

  @override
  String get resetProgress => 'પ્રગતિ ભૂંસો';

  @override
  String resetProgressBody(String name) {
    return 'આનાથી $name ના બધા ગુણ, સિક્કા, બેજ અને ખૂલેલા સ્તર ભૂંસાઈ જશે.';
  }

  @override
  String get reset => 'ભૂંસો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get progressReset => 'પ્રગતિ ભૂંસાઈ';

  @override
  String get removeChild => 'આ બાળકને દૂર કરો';

  @override
  String removeChildBody(String name) {
    return '$name અને તેમની બધી પ્રગતિ આ ફોનમાંથી દૂર કરવી છે?';
  }

  @override
  String get remove => 'દૂર કરો';

  @override
  String get child => 'બાળક';

  @override
  String get about => 'એપ વિશે';

  @override
  String get aboutBody =>
      'આ એપ ધોરણ 1–8 ના બાળકોને નાના, મજેદાર રાઉન્ડમાં ગણિતનો મહાવરો કરવામાં મદદ કરે છે. તે સંપૂર્ણ ઑફલાઇન ચાલે છે, જાહેરાતો નથી અને ખાતું જોઈતું નથી. ફક્ત બાળકનું પહેલું નામ અને ધોરણ, ફક્ત આ ફોનમાં જ રહે છે.';

  @override
  String version(String v) {
    return 'આવૃત્તિ $v';
  }

  @override
  String get licenses => 'લાઇસન્સ';

  @override
  String get close => 'બંધ કરો';

  @override
  String get reminderBody => 'આજની ગણિત ચેલેન્જનો સમય થયો!';

  @override
  String get reminderChannel => 'રોજનું રીમાઇન્ડર';

  @override
  String get lockedLevelSnack => 'આ સ્તર ખોલવા મહાવરો ચાલુ રાખ!';

  @override
  String get hearAgain => 'ફરી સાંભળો';
}

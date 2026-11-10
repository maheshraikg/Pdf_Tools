// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oriya (`or`).
class AppLocalizationsOr extends AppLocalizations {
  AppLocalizationsOr([String locale = 'or']) : super(locale);

  @override
  String get appTitle => 'ଗଣିତ ଖେଳ';

  @override
  String get chooseLanguage => 'ଭାଷା ବାଛନ୍ତୁ';

  @override
  String get continueBtn => 'ଆଗକୁ ଚାଲ';

  @override
  String get welcome => 'ସ୍ୱାଗତ!';

  @override
  String get profileSetupTitle => 'କିଏ ଖେଳୁଛି?';

  @override
  String get editProfile => 'ବିବରଣୀ ବଦଳାଅ';

  @override
  String get childName => 'ପିଲାର ପ୍ରଥମ ନାମ';

  @override
  String get nameRequired => 'ଦୟାକରି ନାମ ଲେଖନ୍ତୁ';

  @override
  String get schoolClass => 'ଶ୍ରେଣୀ';

  @override
  String classN(int n) {
    return 'ଶ୍ରେଣୀ $n';
  }

  @override
  String classRange(int from, int to) {
    return 'ଶ୍ରେଣୀ $from–$to';
  }

  @override
  String get chooseAvatar => 'ଛବି ବାଛ';

  @override
  String get save => 'ସେଭ୍ କର';

  @override
  String get addChild => 'ପିଲା ଯୋଡ଼';

  @override
  String get switchChild => 'କିଏ ଖେଳୁଛି?';

  @override
  String helloName(String name) {
    return 'ନମସ୍କାର, $name!';
  }

  @override
  String get greetingSub => 'ସଂଖ୍ୟା ସହ ଖେଳିବାକୁ ପ୍ରସ୍ତୁତ?';

  @override
  String get dailyChallenge => 'ଆଜିର ଚ୍ୟାଲେଞ୍ଜ';

  @override
  String get dailyChallengeDesc => '10ଟି ଅଙ୍କ – ଆଜି ସମସ୍ତଙ୍କ ପାଇଁ ସମାନ!';

  @override
  String get dailyDone => 'ଆଜିର ସରିଗଲା! କାଲି ପୁଣି ଆସ।';

  @override
  String get start => 'ଆରମ୍ଭ କର';

  @override
  String get playAgainToday => 'ପୁଣି ଖେଳ';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count ଦିନ', one: '1 ଦିନ');
    return '$_temp0';
  }

  @override
  String get streak => 'ଲଗାତାର';

  @override
  String get coins => 'ମୁଦ୍ରା';

  @override
  String get play => 'ଖେଳ';

  @override
  String get games => 'ଖେଳଗୁଡ଼ିକ';

  @override
  String currentTopic(String topic) {
    return 'ବିଷୟ: $topic';
  }

  @override
  String get change => 'ବଦଳାଅ';

  @override
  String get gameBalloon => 'ବେଲୁନ ଫଟାଅ';

  @override
  String get gameBalloonDesc => 'ଠିକ୍ ଉତ୍ତର ଥିବା ବେଲୁନ ଫଟାଅ';

  @override
  String get gameRace => 'କାର ଦୌଡ଼';

  @override
  String get gameRaceDesc => 'ଠିକ୍ ଉତ୍ତରରେ ତୁମ କାର ଦୌଡ଼ିବ';

  @override
  String get gameTreasure => 'ଧନ ଖୋଜା';

  @override
  String get gameTreasureDesc => 'ଲଗାତାର 5ଟି ଠିକ୍ ଉତ୍ତରରେ ପେଡ଼ି ଖୋଲେ';

  @override
  String get gameTables => 'ଗଣିତ ପାଣ୍ଠି ମାଷ୍ଟର';

  @override
  String get gameTablesDesc => '2–20 ପାଣ୍ଠି ଶିଖ ଓ ଅଭ୍ୟାସ କର';

  @override
  String get gameSpeed => 'ବେଗ ଚ୍ୟାଲେଞ୍ଜ';

  @override
  String get gameSpeedDesc => '60 ସେକେଣ୍ଡରେ କେତେ?';

  @override
  String get levelMap => 'ସ୍ତରର ମାନଚିତ୍ର';

  @override
  String levelN(int n) {
    return 'ସ୍ତର $n';
  }

  @override
  String get locked => 'ବନ୍ଦ';

  @override
  String get lockedHint => 'ଏହାକୁ ଖୋଲିବାକୁ ପୂର୍ବ ବିଷୟରେ 85%ରୁ ଅଧିକ ଠିକ୍ କର।';

  @override
  String get chooseTopic => 'ବିଷୟ ବାଛ';

  @override
  String get chooseGame => 'ଖେଳ ବାଛ';

  @override
  String get topic_num100 => '100 ପର୍ଯ୍ୟନ୍ତ ସଂଖ୍ୟା';

  @override
  String get topic_add1 => 'ଏକ ଅଙ୍କ ଯୋଗ';

  @override
  String get topic_sub1 => 'ଏକ ଅଙ୍କ ବିୟୋଗ';

  @override
  String get topic_add2 => 'ଦୁଇ ଅଙ୍କ ଯୋଗ';

  @override
  String get topic_sub2 => 'ଦୁଇ ଅଙ୍କ ବିୟୋଗ';

  @override
  String get topic_tab2_5 => '2–5 ପାଣ୍ଠି';

  @override
  String get topic_tab6_10 => '6–10 ପାଣ୍ଠି';

  @override
  String get topic_add3 => 'ତିନି ଅଙ୍କ ଯୋଗ';

  @override
  String get topic_sub3 => 'ତିନି ଅଙ୍କ ବିୟୋଗ';

  @override
  String get topic_div1 => 'ସରଳ ହରଣ';

  @override
  String get topic_tab11_20 => '11–20 ପାଣ୍ଠି';

  @override
  String get topic_mul21 => 'ଦୁଇ ଅଙ୍କ × ଏକ ଅଙ୍କ';

  @override
  String get topic_divRem => 'ଭାଗଶେଷ ସହ ହରଣ';

  @override
  String get topic_mixed => 'ମିଶ୍ରିତ ପ୍ରକ୍ରିୟା';

  @override
  String get topic_squares => '1–30 ବର୍ଗ';

  @override
  String get topic_cubes => '1–15 ଘନ';

  @override
  String get topic_percent => 'ଶତକଡ଼ା';

  @override
  String get topic_fractions => 'ସରଳ ଭଗ୍ନାଂଶ';

  @override
  String qAfter(int n) {
    return '$n ପରେ କେଉଁ ସଂଖ୍ୟା ଆସେ?';
  }

  @override
  String qBefore(int n) {
    return '$n ପୂର୍ବରୁ କେଉଁ ସଂଖ୍ୟା ଆସେ?';
  }

  @override
  String qTenMore(int n) {
    return '$n ଠାରୁ 10 ଅଧିକ';
  }

  @override
  String qTenLess(int n) {
    return '$n ଠାରୁ 10 କମ୍';
  }

  @override
  String qPercentOf(int p, int n) {
    return '$n ର $p%';
  }

  @override
  String qFractionOf(String fraction, int n) {
    return '$n ର $fraction';
  }

  @override
  String get remainderShort => 'ଶେ';

  @override
  String get score => 'ସ୍କୋର';

  @override
  String secondsShort(int n) {
    return '$n ସେ';
  }

  @override
  String get quitGameTitle => 'ଏହି ରାଉଣ୍ଡ ବନ୍ଦ କରିବ?';

  @override
  String get quitGameBody => 'ଏହି ରାଉଣ୍ଡର ମୁଦ୍ରା ଯୋଡ଼ାଯିବ ନାହିଁ।';

  @override
  String get keepPlaying => 'ଖେଳ ଜାରି ରଖ';

  @override
  String get stop => 'ବନ୍ଦ କର';

  @override
  String answerIs(String answer) {
    return 'ଉତ୍ତର ହେଲା $answer';
  }

  @override
  String get praise => 'ବାହା!|ବହୁତ ଭଲ!|ଚମତ୍କାର!|ଶାବାଶ!|ତୁମେ ତ ତାରକା!|ଅଦ୍ଭୁତ!';

  @override
  String get encourage =>
      'ପୁଣି ଚେଷ୍ଟା କର, ତୁମେ ପାରିବ!|ପ୍ରାୟ ହୋଇଗଲା! ଆଗେଇ ଚାଲ!|ଭଲ ଚେଷ୍ଟା! ଏଇ ନିଅ ପରବର୍ତ୍ତୀ।|ସୁନ୍ଦର ଚେଷ୍ଟା! ତୁମେ ଶିଖୁଛ!';

  @override
  String get getReady => 'ପ୍ରସ୍ତୁତ ହୁଅ!';

  @override
  String get go => 'ଚାଲ!';

  @override
  String get you => 'ତୁମେ';

  @override
  String get computer => 'କମ୍ପ୍ୟୁଟର';

  @override
  String get raceWon => 'ତୁମେ ଦୌଡ଼ ଜିତିଲ!';

  @override
  String get raceLost => 'ଭଲ ଦୌଡ଼! ଆଉ ଟିକେ ଅଭ୍ୟାସ କଲେ ପରଥର ଜିତିବ।';

  @override
  String chestOpened(int n) {
    return 'ପେଡ଼ି ଖୋଲିଲା! +$n ମୁଦ୍ରା';
  }

  @override
  String get chestStreakReset => 'ପୁଣି 5 ଆରମ୍ଭ କରିବା!';

  @override
  String chestsOpened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countଟି ପେଡ଼ି ଖୋଲିଲା',
      one: '1ଟି ପେଡ଼ି ଖୋଲିଲା',
      zero: 'ଏପର୍ଯ୍ୟନ୍ତ ପେଡ଼ି ନାହିଁ',
    );
    return '$_temp0';
  }

  @override
  String personalBest(int n) {
    return 'ସର୍ବୋତ୍ତମ: $n';
  }

  @override
  String get newBest => 'ନୂଆ ରେକର୍ଡ!';

  @override
  String get clear => 'ଲିଭାଅ';

  @override
  String get pickTable => 'ପାଣ୍ଠି ବାଛ';

  @override
  String get learn => 'ଶିଖ';

  @override
  String get quiz => 'କୁଇଜ୍';

  @override
  String tableOf(int n) {
    return '$n ପାଣ୍ଠି';
  }

  @override
  String get listen => 'ଶୁଣ';

  @override
  String get pause => 'ରଖ';

  @override
  String get startQuiz => 'କୁଇଜ୍ ଆରମ୍ଭ କର';

  @override
  String get mastered => 'ଶିଖିସାରିଛ';

  @override
  String questionOf(int n, int total) {
    return '$n / $total';
  }

  @override
  String get resultTitle => 'ରାଉଣ୍ଡ ସରିଲା!';

  @override
  String get correctLabel => 'ଠିକ୍';

  @override
  String get practiseLabel => 'ଅଭ୍ୟାସ ପାଇଁ';

  @override
  String get practiseThese => 'ଏଗୁଡ଼ିକ ଅଭ୍ୟାସ କରିବା';

  @override
  String coinsEarned(int n) {
    return '+$n ମୁଦ୍ରା';
  }

  @override
  String get playAgain => 'ପୁଣି ଖେଳ';

  @override
  String get home => 'ମୂଳ ପୃଷ୍ଠା';

  @override
  String get resultMsg3 => 'ଅଦ୍ଭୁତ! ତୁମେ ଗଣିତର ତାରକା!';

  @override
  String get resultMsg2 => 'ବହୁତ ଭଲ କାମ!';

  @override
  String get resultMsg1 => 'ଭଲ! ଅଭ୍ୟାସ ଜାରି ରଖ!';

  @override
  String get resultMsg0 => 'ଭଲ ଚେଷ୍ଟା! ପ୍ରତି ରାଉଣ୍ଡରେ ତୁମେ ଆହୁରି ଭଲ ହେବ!';

  @override
  String get allCorrect => 'ସବୁ ଠିକ୍!';

  @override
  String newTopicUnlocked(String topic) {
    return 'ନୂଆ ବିଷୟ ଖୋଲିଲା: $topic';
  }

  @override
  String streakNow(String days) {
    return 'ଲଗାତାର ଦିନ: $days';
  }

  @override
  String get shop => 'ଦୋକାନ';

  @override
  String get avatars => 'ଛବି';

  @override
  String get carColours => 'କାରର ରଙ୍ଗ';

  @override
  String get balloonThemes => 'ବେଲୁନ';

  @override
  String get buy => 'କିଣ';

  @override
  String get use => 'ବ୍ୟବହାର କର';

  @override
  String get inUse => 'ବ୍ୟବହାରରେ';

  @override
  String needMoreCoins(int n) {
    return 'ଆଉ $nଟି ମୁଦ୍ରା ପାଇବାକୁ ଖେଳ!';
  }

  @override
  String get bought => 'ଏବେ ଏହା ତୁମର!';

  @override
  String get color_red => 'ନାଲି';

  @override
  String get color_blue => 'ନୀଳ';

  @override
  String get color_green => 'ସବୁଜ';

  @override
  String get color_yellow => 'ହଳଦିଆ';

  @override
  String get color_purple => 'ବାଇଗଣି';

  @override
  String get color_orange => 'କମଳା';

  @override
  String get color_pink => 'ଗୋଲାପୀ';

  @override
  String get color_black => 'କଳା';

  @override
  String get theme_rainbow => 'ଇନ୍ଦ୍ରଧନୁ';

  @override
  String get theme_pastel => 'ହାଲୁକା ରଙ୍ଗ';

  @override
  String get theme_ocean => 'ସମୁଦ୍ର';

  @override
  String get theme_sunset => 'ସୂର୍ଯ୍ୟାସ୍ତ';

  @override
  String get theme_candy => 'ଲଜେନ୍ସ';

  @override
  String get badges => 'ବ୍ୟାଜ୍';

  @override
  String badgeTableMaster(int n) {
    return '$n ପାଣ୍ଠି ମାଷ୍ଟର';
  }

  @override
  String badgeTableMasterDesc(int n) {
    return '$n ପାଣ୍ଠିର ପ୍ରତ୍ୟେକ ଧାଡ଼ି ଶିଖ';
  }

  @override
  String get badgeStreak7 => 'ଲଗାତାର 7 ଦିନ';

  @override
  String get badgeStreak7Desc => 'ଲଗାତାର 7 ଦିନ ଆଜିର ଚ୍ୟାଲେଞ୍ଜ କର';

  @override
  String get badgeStreak30 => 'ଲଗାତାର 30 ଦିନ';

  @override
  String get badgeStreak30Desc => 'ଲଗାତାର 30 ଦିନ ଆଜିର ଚ୍ୟାଲେଞ୍ଜ କର';

  @override
  String get badgeDay100 => 'ଦିନକରେ 100ଟି ଅଙ୍କ';

  @override
  String get badgeDay100Desc => 'ଗୋଟିଏ ଦିନରେ 100ଟି ଅଙ୍କ କର';

  @override
  String get badgeSpeedStar => 'ବେଗର ତାରକା';

  @override
  String get badgeSpeedStarDesc => 'ବେଗ ଚ୍ୟାଲେଞ୍ଜରେ 20 ବା ଅଧିକ ଠିକ୍';

  @override
  String get newBadge => 'ନୂଆ ବ୍ୟାଜ୍!';

  @override
  String get yay => 'ହୁରେ!';

  @override
  String get forParents => 'ଅଭିଭାବକଙ୍କ ପାଇଁ';

  @override
  String get enterPin => 'ଅଭିଭାବକଙ୍କ PIN ଦିଅନ୍ତୁ';

  @override
  String get createPin => '4 ଅଙ୍କର PIN ତିଆରି କରନ୍ତୁ';

  @override
  String get confirmPin => 'ସେହି PIN ପୁଣି ଦିଅନ୍ତୁ';

  @override
  String get newPin => 'ନୂଆ 4 ଅଙ୍କର PIN ଦିଅନ୍ତୁ';

  @override
  String get pinMismatch => 'ଦୁଇଟି PIN ଅଲଗା ଥିଲା। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।';

  @override
  String get pinWrong => 'PIN ଠିକ୍ ନୁହେଁ। ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।';

  @override
  String get pinForParents => 'କେବଳ ବଡ଼ମାନଙ୍କ ପାଇଁ';

  @override
  String get pinForgot => 'PIN ଭୁଲିଗଲେ? ଫୋନ ସେଟିଂସରେ ଏହି ଆପର ଡାଟା ଲିଭାଇଲେ PIN ଓ ସମସ୍ତ ପ୍ରଗତି ଲିଭିଯିବ।';

  @override
  String get pinChanged => 'PIN ବଦଳିଲା';

  @override
  String get progress => 'ପ୍ରଗତି';

  @override
  String get totalSums => 'ସମାଧାନ ହୋଇଥିବା ଅଙ୍କ';

  @override
  String get accuracy => 'ସଠିକତା';

  @override
  String get factsMastered => 'ଶିଖିଥିବା ଅଙ୍କ';

  @override
  String get daysPractised => 'ଅଭ୍ୟାସ ଦିନ';

  @override
  String get accuracyPerTopic => 'ବିଷୟ ଅନୁସାରେ ସଠିକତା';

  @override
  String get speedOverTime => 'ପ୍ରତି ଅଙ୍କରେ ହାରାହାରି ସେକେଣ୍ଡ';

  @override
  String get weakFacts => 'ଅଭ୍ୟାସ ଦରକାର ଥିବା ଅଙ୍କ';

  @override
  String get noWeakFacts => 'ଏବେ କିଛି କଠିନ ନାହିଁ। ଶାବାଶ!';

  @override
  String get noDataYet => 'ଏପର୍ଯ୍ୟନ୍ତ ଅଭ୍ୟାସ ହୋଇନାହିଁ।';

  @override
  String triesRight(int n, int pct) {
    return '$n ଚେଷ୍ଟା · $pct% ଠିକ୍';
  }

  @override
  String get settings => 'ସେଟିଂସ';

  @override
  String get language => 'ଭାଷା';

  @override
  String get sound => 'ଶବ୍ଦ';

  @override
  String get music => 'ସଙ୍ଗୀତ';

  @override
  String get dailyReminder => 'ଦୈନିକ ସ୍ମାରକ';

  @override
  String get reminderTime => 'ସ୍ମାରକ ସମୟ';

  @override
  String get notificationsBlocked => 'ଫୋନ ସେଟିଂସରେ ଏହି ଆପର ବିଜ୍ଞପ୍ତି ବନ୍ଦ ଅଛି।';

  @override
  String get changePin => 'ଅଭିଭାବକଙ୍କ PIN ବଦଳାନ୍ତୁ';

  @override
  String get resetProgress => 'ପ୍ରଗତି ଲିଭାନ୍ତୁ';

  @override
  String resetProgressBody(String name) {
    return 'ଏହା $nameଙ୍କ ସମସ୍ତ ସ୍କୋର, ମୁଦ୍ରା, ବ୍ୟାଜ୍ ଓ ଖୋଲିଥିବା ସ୍ତର ଲିଭାଇଦେବ।';
  }

  @override
  String get reset => 'ଲିଭାନ୍ତୁ';

  @override
  String get cancel => 'ବାତିଲ୍';

  @override
  String get progressReset => 'ପ୍ରଗତି ଲିଭାଗଲା';

  @override
  String get removeChild => 'ଏହି ପିଲାକୁ ହଟାନ୍ତୁ';

  @override
  String removeChildBody(String name) {
    return '$name ଓ ତାଙ୍କର ସମସ୍ତ ପ୍ରଗତି ଏହି ଫୋନରୁ ହଟାଇବେ?';
  }

  @override
  String get remove => 'ହଟାନ୍ତୁ';

  @override
  String get child => 'ପିଲା';

  @override
  String get about => 'ଆପ ବିଷୟରେ';

  @override
  String get aboutBody =>
      'ଏହି ଆପ 1–8 ଶ୍ରେଣୀର ପିଲାମାନଙ୍କୁ ଛୋଟ, ମଜାଦାର ରାଉଣ୍ଡରେ ଗଣିତ ଅଭ୍ୟାସ କରିବାରେ ସାହାଯ୍ୟ କରେ। ଏହା ସମ୍ପୂର୍ଣ୍ଣ ଅଫଲାଇନରେ ଚାଲେ, ବିଜ୍ଞାପନ ନାହିଁ ଓ ଆକାଉଣ୍ଟ ଦରକାର ନାହିଁ। କେବଳ ପିଲାର ପ୍ରଥମ ନାମ ଓ ଶ୍ରେଣୀ, କେବଳ ଏହି ଫୋନରେ ରଖାଯାଏ।';

  @override
  String version(String v) {
    return 'ସଂସ୍କରଣ $v';
  }

  @override
  String get licenses => 'ଲାଇସେନ୍ସ';

  @override
  String get close => 'ବନ୍ଦ କରନ୍ତୁ';

  @override
  String get reminderBody => 'ଆଜିର ଗଣିତ ଚ୍ୟାଲେଞ୍ଜର ସମୟ ହେଲା!';

  @override
  String get reminderChannel => 'ଦୈନିକ ସ୍ମାରକ';

  @override
  String get lockedLevelSnack => 'ଏହି ସ୍ତର ଖୋଲିବାକୁ ଅଭ୍ୟାସ ଜାରି ରଖ!';

  @override
  String get hearAgain => 'ପୁଣି ଶୁଣ';
}

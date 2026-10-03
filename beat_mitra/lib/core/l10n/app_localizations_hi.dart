// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'बीट मित्र';

  @override
  String get appTagline => 'आपकी बीट का साथी';

  @override
  String get welcomeTitle => 'स्वागत है';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get next => 'आगे';

  @override
  String get iUnderstand => 'मैं समझ गया';

  @override
  String get disclaimer =>
      'डाकियों के लिए स्वतंत्र सहायक टूल। यह डाक विभाग का आधिकारिक ऐप नहीं है। ग्राहकों की जानकारी के बारे में अपने कार्यालय के नियमों का पालन करें।';

  @override
  String get privacyTitle => 'गोपनीयता';

  @override
  String get privacyOnDevice => 'नाम और पते केवल इसी फ़ोन में रहते हैं।';

  @override
  String get privacyEncrypted => 'सारा डेटा और फ़ोटो एन्क्रिप्टेड हैं और आपके PIN से सुरक्षित हैं।';

  @override
  String get privacyNoCloud => 'न इंटरनेट, न क्लाउड, न लॉगिन, न विज्ञापन।';

  @override
  String get privacyNoAnalytics => 'कोई एनालिटिक्स या क्रैश रिपोर्टिंग नहीं।';

  @override
  String get privacyMap =>
      'वैकल्पिक ऑनलाइन नक्शा शुरू में बंद रहता है और केवल OpenStreetMap से नक्शे की तस्वीरें लाता है।';

  @override
  String get privacyBackupAdvice => 'डेटा केवल इसी फ़ोन में है: हर हफ़्ते एन्क्रिप्टेड बैकअप बनाएँ।';

  @override
  String get freeTools => 'केवल मुफ़्त और ओपन टूल से बना। पूरी तरह ऑफ़लाइन चलता है।';

  @override
  String get createPin => '4 अंकों का PIN बनाएँ';

  @override
  String get confirmPin => 'PIN फिर से डालें';

  @override
  String get pinMismatch => 'PIN मेल नहीं खाए। फिर कोशिश करें।';

  @override
  String get enterPin => 'PIN डालें';

  @override
  String get enterOldPin => 'मौजूदा PIN डालें';

  @override
  String get wrongPin => 'गलत PIN';

  @override
  String get tooManyTries => 'बहुत बार गलत। 30 सेकंड रुकें।';

  @override
  String get useFingerprint => 'फ़िंगरप्रिंट / चेहरे से खोलें';

  @override
  String get unlockReason => 'बीट मित्र खोलें';

  @override
  String get biometricUnavailable => 'इस फ़ोन पर उपलब्ध नहीं';

  @override
  String get pinChanged => 'PIN बदल गया';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get saved => 'सहेजा गया';

  @override
  String get delete => 'हटाएँ';

  @override
  String get edit => 'बदलें';

  @override
  String get add => 'जोड़ें';

  @override
  String get remove => 'हटाएँ';

  @override
  String get done => 'हो गया';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get select => 'चुनें';

  @override
  String get share => 'शेयर करें';

  @override
  String get title => 'शीर्षक';

  @override
  String get note => 'नोट';

  @override
  String get notes => 'नोट्स';

  @override
  String get noteOptional => 'नोट (वैकल्पिक)';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get help => 'मदद';

  @override
  String get about => 'जानकारी';

  @override
  String get voiceInput => 'बोलें';

  @override
  String get voiceStop => 'सुनना बंद करें';

  @override
  String get voiceNotHeard => 'सुनाई नहीं दिया। फिर कोशिश करें या टाइप करें।';

  @override
  String get somethingWrong => 'कुछ गड़बड़ हुई';

  @override
  String get switchBeat => 'बीट बदलें';

  @override
  String get noBeatYet => 'अभी कोई बीट नहीं। शुरू करने के लिए अपनी बीट बनाएँ।';

  @override
  String get createBeat => 'बीट बनाएँ';

  @override
  String get editBeat => 'बीट बदलें';

  @override
  String get deleteBeat => 'बीट हटाएँ';

  @override
  String deleteBeatConfirm(int count) {
    return 'इस बीट को इसकी $count जगहों, गलियों और फ़ोटो के साथ हटाएँ?';
  }

  @override
  String get beats => 'बीट';

  @override
  String get beatName => 'बीट का नाम';

  @override
  String get beatNameHint => 'जैसे बीट 7 / रिलीफ़ बीट 3';

  @override
  String get office => 'डाकघर';

  @override
  String get addHere => 'यहाँ जोड़ें';

  @override
  String get searchHint => 'नाम, मकान नं., गली, निशानी, PIN…';

  @override
  String get search => 'खोजें';

  @override
  String get todaysArticles => 'आज की डाक';

  @override
  String pendingDoneCount(int pending, int done) {
    return '$pending बाँटनी हैं · $done हो गईं';
  }

  @override
  String get routeAndRun => 'रास्ता और वितरण';

  @override
  String get nearby => 'आस-पास की जगहें';

  @override
  String get daySummary => 'दिन का सारांश';

  @override
  String get beatAndStreets => 'बीट और गलियाँ';

  @override
  String get learnBeat => 'बीट सीखें';

  @override
  String get handoverBackup => 'सौंपना और बैकअप';

  @override
  String get map => 'नक्शा';

  @override
  String get backupReminder => 'पिछले 7 दिनों में बैकअप नहीं। डेटा केवल इसी फ़ोन में है — अभी बैकअप लें।';

  @override
  String get streets => 'गलियाँ';

  @override
  String get streetsHelp => 'गलियों को अपने रोज़ के चलने के क्रम में लगाने के लिए ≡ खींचें।';

  @override
  String get noStreets => 'अभी कोई गली नहीं। अपनी बीट की गलियाँ जोड़ें।';

  @override
  String get addStreet => 'गली जोड़ें';

  @override
  String get editStreet => 'गली बदलें';

  @override
  String get deleteStreet => 'गली हटाएँ';

  @override
  String get deleteStreetConfirm => 'यह गली हटाएँ? इसकी जगहें बिना गली के बनी रहेंगी।';

  @override
  String get streetName => 'गली का नाम';

  @override
  String get streetNameHint => 'जैसे 4th क्रॉस, गली नं. 3, शास्त्री नगर';

  @override
  String get area => 'इलाका';

  @override
  String get crossMainNote => 'क्रॉस / मेन नोट';

  @override
  String placesCount(int count) {
    return 'जगहें: $count';
  }

  @override
  String get noPlaces => 'अभी कोई जगह नहीं। बीट पर चलते हुए हर दरवाज़े पर “यहाँ जोड़ें” दबाएँ।';

  @override
  String get noStreet => 'बिना गली';

  @override
  String get areaNotes => 'इलाके के नोट';

  @override
  String get areaNote => 'इलाके का नोट';

  @override
  String get areaNoteHint => 'जैसे झील की ओर क्रॉस नंबर बढ़ते हैं';

  @override
  String get addAreaNote => 'इलाके का नोट जोड़ें';

  @override
  String get noAreaNotes => 'यहाँ नंबर कैसे चलते हैं, छोटे रास्ते, समय… लिखें';

  @override
  String get addPlace => 'जगह जोड़ें';

  @override
  String get editPlace => 'जगह बदलें';

  @override
  String get deletePlace => 'जगह हटाएँ';

  @override
  String get deletePlaceConfirm => 'यह जगह, इसके नाम और फ़ोटो हटाएँ?';

  @override
  String get placeDeleted => 'यह जगह हटा दी गई।';

  @override
  String get placeNeedsSomething => 'मकान नं., इमारत, नाम या निशानी डालें।';

  @override
  String get doorNo => 'मकान नं.';

  @override
  String get pickStreet => 'गली चुनें';

  @override
  String get searchStreet => 'गली खोजें';

  @override
  String get newStreet => 'नई गली';

  @override
  String newStreetNamed(String name) {
    return 'नई गली “$name”';
  }

  @override
  String get addressees => 'इस जगह के नाम';

  @override
  String get addressee => 'पाने वाला';

  @override
  String get addName => 'नाम जोड़ें';

  @override
  String get name => 'नाम';

  @override
  String get aliases => 'दूसरी वर्तनी / नाम';

  @override
  String get aliasesHelp => 'कॉमा से अलग करें';

  @override
  String get phoneOptional => 'फ़ोन (वैकल्पिक)';

  @override
  String get noteFlat => 'नोट (फ़्लैट, मंज़िल…)';

  @override
  String get landmark => 'निशानी';

  @override
  String get building => 'इमारत';

  @override
  String get floorFlat => 'मंज़िल / फ़्लैट';

  @override
  String get notesHint => 'नोट: कुत्ता, गेट, मंज़िल, समय';

  @override
  String get quickDog => 'कुत्ता';

  @override
  String get quickGate => 'गेट बंद';

  @override
  String get quickUpstairs => 'ऊपर';

  @override
  String get quickMorning => 'केवल सुबह';

  @override
  String get quickEvening => 'केवल शाम';

  @override
  String get deliveryPref => 'डिलीवरी पसंद';

  @override
  String get prefSecurity => 'गार्ड को दें';

  @override
  String get prefNeighbour => 'पड़ोसी को दें';

  @override
  String get prefLetterBox => 'लेटर बॉक्स';

  @override
  String get prefShop => 'नीचे की दुकान';

  @override
  String get pin => 'पिन कोड';

  @override
  String get placeHouse => 'घर';

  @override
  String get placeShop => 'दुकान';

  @override
  String get placeOffice => 'दफ़्तर';

  @override
  String get placeApartment => 'अपार्टमेंट';

  @override
  String get placeOther => 'अन्य';

  @override
  String get maxPhotos => 'हर जगह के लिए 3 फ़ोटो तक';

  @override
  String photoCount(int count) {
    return 'फ़ोटो $count/3';
  }

  @override
  String get cameraError => 'कैमरा उपलब्ध नहीं';

  @override
  String get possibleDuplicates => 'पास में पहले से सहेजी गई — वही जगह?';

  @override
  String get openIt => 'खोलें';

  @override
  String get gpsOff => 'लोकेशन बंद है। चालू करें।';

  @override
  String get gpsDenied => 'लोकेशन की अनुमति चाहिए।';

  @override
  String get openSettings => 'सेटिंग';

  @override
  String get gpsWaiting => 'GPS मिल रहा है…';

  @override
  String gpsAccuracy(int acc, int want) {
    return 'GPS सटीकता $acc मी (≤ $want मी चाहिए)';
  }

  @override
  String gpsAccuracyShort(int acc) {
    return '± $acc मी';
  }

  @override
  String get gpsUseNow => 'यही लोकेशन लें';

  @override
  String gpsSaved(int acc) {
    return 'लोकेशन सहेजी (± $acc मी)';
  }

  @override
  String get gpsRetake => 'फिर से';

  @override
  String get gpsNotSet => 'लोकेशन नहीं सहेजी';

  @override
  String get gpsCapture => 'GPS लें';

  @override
  String get updateGpsHere => 'पिन मेरी अभी की जगह पर लाएँ';

  @override
  String updateGpsConfirm(int acc) {
    return 'अपनी अभी की लोकेशन (± $acc मी) इस जगह के लिए सहेजें?';
  }

  @override
  String get mergeDuplicate => 'डुप्लिकेट मिलाएँ';

  @override
  String get pickDuplicate => 'डुप्लिकेट चुनें';

  @override
  String get mergeIntoThis => 'इस जगह में मिलाएँ';

  @override
  String get mergeConfirm => 'डुप्लिकेट के नाम, फ़ोटो और डाक यहाँ आ जाएँगे, फिर वह हट जाएगी।';

  @override
  String get merged => 'मिला दिया';

  @override
  String get navigate => 'रास्ता दिखाएँ';

  @override
  String get googleMaps => 'गूगल मैप्स';

  @override
  String get call => 'कॉल';

  @override
  String distanceAway(String distance) {
    return '$distance दूर';
  }

  @override
  String get searchTips =>
      'नाम, मकान नं. (12/3), गली, निशानी या PIN लिखें या बोलें। कन्नड़, हिंदी, अंग्रेज़ी सब चलेगा।';

  @override
  String get noResults => 'कुछ नहीं मिला। कम अक्षर या मकान नं. आज़माएँ।';

  @override
  String get allBeats => 'सभी बीट';

  @override
  String get placeHasNoGps => 'इस जगह की GPS लोकेशन नहीं है। दरवाज़े पर बदलकर जोड़ें।';

  @override
  String get arrived => 'आप पहुँच गए';

  @override
  String get noCompass => 'कम्पास नहीं: चलते समय तीर दिशा दिखाएगा।';

  @override
  String get noNearby => 'आपके पास कोई सहेजी जगह नहीं।';

  @override
  String get scanBarcode => 'बारकोड स्कैन';

  @override
  String get scanAddress => 'पता स्कैन';

  @override
  String get typeIn => 'टाइप करें';

  @override
  String get torch => 'टॉर्च';

  @override
  String scannedCount(int count) {
    return 'स्कैन हुए: $count';
  }

  @override
  String addedCount(int count) {
    return '$count डाक जोड़ी गईं';
  }

  @override
  String get articleValid => 'सही आर्टिकल नंबर';

  @override
  String get articleBadCheck => 'चेक अंक मेल नहीं खाता — नंबर जाँचें';

  @override
  String get articleOtherFormat => 'दूसरा फ़ॉर्मेट (चलेगा)';

  @override
  String get articleInvalid => 'बहुत छोटा / सही नहीं';

  @override
  String get articleNo => 'आर्टिकल नंबर';

  @override
  String get articleNoOptional => 'साधारण पत्रों के लिए वैकल्पिक';

  @override
  String get addArticle => 'डाक जोड़ें';

  @override
  String get editArticle => 'डाक';

  @override
  String get deleteArticle => 'डाक हटाएँ';

  @override
  String get deleteArticleConfirm => 'यह डाक आज की सूची से हटाएँ?';

  @override
  String get duplicateArticle => 'पहले से जोड़ी गई';

  @override
  String duplicateArticleBody(String number) {
    return '$number पहले से आज की सूची में है। फिर जोड़ें?';
  }

  @override
  String get typeLetter => 'पत्र';

  @override
  String get typeRegistered => 'रजिस्टर्ड';

  @override
  String get typeSpeedPost => 'स्पीड पोस्ट';

  @override
  String get typeParcel => 'पार्सल';

  @override
  String get typeMoneyOrder => 'मनी ऑर्डर';

  @override
  String get typeOther => 'अन्य';

  @override
  String get type => 'प्रकार';

  @override
  String get needsSignature => 'हस्ताक्षर / OTP चाहिए';

  @override
  String get addressText => 'पता (जैसा लिखा है)';

  @override
  String get findMatch => 'मिलान खोजें';

  @override
  String get place => 'जगह';

  @override
  String get suggestions => 'सुझाव — सही वाले पर दबाएँ';

  @override
  String get thisOne => 'यही';

  @override
  String get noMatchFound => 'कोई सहेजी जगह मेल नहीं खाती। खोजें या नई जगह जोड़ें।';

  @override
  String get searchPlace => 'जगह खोजें';

  @override
  String get addNewPlace => 'नई जगह जोड़ें';

  @override
  String get pickPlace => 'जगह चुनें';

  @override
  String get unlink => 'जोड़ हटाएँ';

  @override
  String get ocrFailed => 'लिखावट पढ़ी नहीं जा सकी';

  @override
  String get ocrNothing => 'कोई लिखावट नहीं मिली। अच्छी रोशनी में पास से पकड़ें।';

  @override
  String carryPrompt(int count) {
    return 'पिछले दिन के $count दोबारा प्रयास';
  }

  @override
  String carriedCount(int count) {
    return '$count दोबारा प्रयास जोड़े गए';
  }

  @override
  String todayCounts(int total, int pending, int unmatched) {
    return '$total डाक · $pending बाकी · $unmatched बिना जगह';
  }

  @override
  String get noArticlesToday => 'अभी कोई डाक नहीं। बारकोड या पता स्कैन करें, या टाइप करें।';

  @override
  String get unmatched => 'बिना जगह — जगह से जोड़ें';

  @override
  String get matched => 'जुड़ी हुई';

  @override
  String get planRoute => 'रास्ता बनाएँ';

  @override
  String get reattempt => 'दोबारा प्रयास';

  @override
  String get statusPending => 'बाकी';

  @override
  String get statusDelivered => 'बाँटी गई';

  @override
  String get statusNotDelivered => 'नहीं बँटी';

  @override
  String get routePlan => 'रास्ते की योजना';

  @override
  String get modeShortest => 'सबसे छोटा';

  @override
  String get modeStreet => 'गली क्रम';

  @override
  String routeSummary(int stops, String distance) {
    return '$stops पड़ाव · लगभग $distance';
  }

  @override
  String startFrom(String where) {
    return 'शुरुआत: $where';
  }

  @override
  String get startUnknown => 'शुरुआत की जगह पता नहीं (GPS नहीं)';

  @override
  String get startOffice => 'डाकघर';

  @override
  String get startCurrent => 'मेरी अभी की जगह';

  @override
  String unmatchedNotInRoute(int count) {
    return '$count बिना जगह की डाक रास्ते में नहीं हैं';
  }

  @override
  String get replan => 'फिर से बनाएँ';

  @override
  String allUnmatched(int count) {
    return '$count डाक अभी जगहों से नहीं जुड़ी। आज की डाक में जोड़ें।';
  }

  @override
  String get nothingToDeliver => 'आज बाँटने के लिए कुछ बाकी नहीं।';

  @override
  String articlesCount(int count) {
    return '$count डाक';
  }

  @override
  String get noGps => 'GPS नहीं';

  @override
  String get startRun => 'वितरण शुरू करें';

  @override
  String get run => 'वितरण';

  @override
  String stopsDone(int done, int total) {
    return '$total में से $done पड़ाव';
  }

  @override
  String get nextStop => 'अगला पड़ाव';

  @override
  String get delivered => 'बाँट दी';

  @override
  String get notDelivered => 'नहीं बँटी';

  @override
  String get skip => 'छोड़ें';

  @override
  String get whyNotDelivered => 'क्यों नहीं बँटी?';

  @override
  String get reasonDoorLocked => 'दरवाज़ा बंद';

  @override
  String get reasonAbsent => 'पाने वाला नहीं मिला';

  @override
  String get reasonLeft => 'छोड़ गए / शिफ़्ट';

  @override
  String get reasonRefused => 'लेने से मना';

  @override
  String get reasonWrongAddress => 'गलत / अधूरा पता';

  @override
  String get reasonUnclaimed => 'किसी ने नहीं लिया';

  @override
  String get reasonOther => 'अन्य';

  @override
  String get runFinished => 'सारे पड़ाव पूरे। शाबाश!';

  @override
  String ttsNext(String where) {
    return 'अगला: नंबर $where';
  }

  @override
  String get history => 'इतिहास';

  @override
  String get noArticlesThatDay => 'इस दिन कोई डाक नहीं।';

  @override
  String get notDeliveredList => 'जो नहीं बँटी';

  @override
  String carryToTomorrow(int count) {
    return '$count दोबारा प्रयास अगले दिन में जोड़ें';
  }

  @override
  String summaryTotals(int total, int delivered, int notDelivered, int pending) {
    return 'कुल $total: बँटी $delivered, नहीं बँटी $notDelivered, बाकी $pending';
  }

  @override
  String summaryTypeLine(String type, int delivered, int total) {
    return '$type: $delivered/$total बँटी';
  }

  @override
  String distanceLine(String planned, String recorded) {
    return 'योजना का रास्ता $planned · दर्ज $recorded';
  }

  @override
  String learnedPercent(int percent) {
    return '$percent% जगहें सीख लीं';
  }

  @override
  String learnedOf(int learned, int total) {
    return '$total में से $learned जगहें';
  }

  @override
  String get weakStreets => 'अभ्यास वाली गलियाँ';

  @override
  String get quizPhoto => 'फ़ोटो → जगह';

  @override
  String get quizPhotoSub => 'घर की फ़ोटो देखें, मकान नं. और गली चुनें';

  @override
  String get quizName => 'नाम → मकान नं.';

  @override
  String get quizNameSub => 'यह व्यक्ति कहाँ रहता है?';

  @override
  String get quizDoor => 'मकान नं. → निशानी';

  @override
  String get quizDoorSub => 'इस दरवाज़े के पास कौन-सी निशानी है?';

  @override
  String get walkMode => 'चलते-चलते';

  @override
  String get walkModeSub => 'बीट पर चलें; ऐप सबसे पास के घर के बारे में पूछेगा';

  @override
  String get resetProgress => 'सीखने की प्रगति रीसेट करें';

  @override
  String get resetProgressConfirm => 'इस बीट को शून्य से सीखना शुरू करें?';

  @override
  String get qWhichPlace => 'यह कौन-सी जगह है?';

  @override
  String qWhereLives(String name) {
    return '$name की डाक कहाँ जाती है?';
  }

  @override
  String qLandmarkOf(String place) {
    return '$place के पास की निशानी?';
  }

  @override
  String get qWhoLivesHere => 'यहाँ किसकी डाक आती है?';

  @override
  String get correct => 'सही!';

  @override
  String wrongAnswer(String answer) {
    return 'उत्तर: $answer';
  }

  @override
  String scoreLine(int right, int total) {
    return 'स्कोर $right/$total';
  }

  @override
  String get notEnoughForQuiz => 'अभ्यास के लिए और जगहें (फ़ोटो, नाम, निशानी के साथ) जोड़ें।';

  @override
  String nearestPlace(String distance) {
    return 'सबसे पास की सहेजी जगह · $distance';
  }

  @override
  String get walkHint => 'जिस घर का जवाब नहीं दिया, उसके पास (40 मी के भीतर) जाएँ।';

  @override
  String get handover => 'रिलीफ़ डाकिये को सौंपें';

  @override
  String get handoverHelp => 'बीट को पासवर्ड-सुरक्षित एन्क्रिप्टेड फ़ाइल बनाकर भेजें। पासवर्ड अलग से (फ़ोन पर) बताएँ।';

  @override
  String get handoverExport => 'बीट निर्यात करें';

  @override
  String get handoverShareText => 'बीट मित्र बीट फ़ाइल। बीट मित्र → सौंपना और बैकअप → आयात में खोलें।';

  @override
  String get chooseBeats => 'शामिल बीट';

  @override
  String get includePhones => 'फ़ोन नंबर शामिल करें';

  @override
  String get createAndShare => 'बनाएँ और भेजें';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordAgain => 'पासवर्ड दोबारा';

  @override
  String get passwordHelp => 'कम से कम 6 अक्षर। इसके बिना फ़ाइल नहीं खुलेगी।';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 6 अक्षर का हो';

  @override
  String get passwordMismatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get importBeat => 'बीट फ़ाइल आयात करें';

  @override
  String get enterFilePassword => 'फ़ाइल का पासवर्ड';

  @override
  String get wrongPassword => 'गलत पासवर्ड';

  @override
  String get notBeatMitraFile => 'यह बीट मित्र फ़ाइल नहीं है';

  @override
  String importDone(int beats, int places, int photos) {
    return '$beats बीट, $places जगहें, $photos फ़ोटो आयात हुए';
  }

  @override
  String get thisIsHandover => 'यह बीट फ़ाइल है: इसकी बीट आपकी बीट में जुड़ेंगी।';

  @override
  String get fullBackup => 'पूरा बैकअप';

  @override
  String get fullBackupHelp =>
      'सब कुछ (बीट, जगहें, फ़ोटो, इतिहास) एक एन्क्रिप्टेड फ़ाइल में। पेन ड्राइव, SD कार्ड या कंप्यूटर में रखें।';

  @override
  String get backupAdvice => 'डेटा केवल इसी फ़ोन में है। फ़ोन खोने पर केवल बैकअप ही बचाएगा।';

  @override
  String get neverBackedUp => 'कभी बैकअप नहीं लिया';

  @override
  String lastBackup(String when) {
    return 'पिछला बैकअप: $when';
  }

  @override
  String get backupNow => 'अभी बैकअप लें';

  @override
  String get chooseLocation => 'कहाँ सहेजें चुनें';

  @override
  String get backupSaved => 'बैकअप सहेजा गया';

  @override
  String get restoreBackup => 'बैकअप वापस लाएँ';

  @override
  String get restore => 'वापस लाएँ';

  @override
  String get restoreConfirm => 'इस फ़ोन का सारा मौजूदा डेटा बैकअप से बदल जाएगा। जारी रखें?';

  @override
  String get display => 'डिस्प्ले';

  @override
  String get language => 'भाषा';

  @override
  String get deviceLanguage => 'फ़ोन की भाषा';

  @override
  String get theme => 'थीम';

  @override
  String get themeSystem => 'फ़ोन जैसा';

  @override
  String get themeLight => 'हल्का';

  @override
  String get themeDark => 'गहरा';

  @override
  String get sunlightMode => 'धूप मोड';

  @override
  String get sunlightModeSub => 'तेज़ धूप के लिए ज़्यादा कंट्रास्ट';

  @override
  String get textSize => 'अक्षर का आकार';

  @override
  String get textNormal => 'सामान्य';

  @override
  String get textLarge => 'बड़ा';

  @override
  String get textXL => 'बहुत बड़ा';

  @override
  String get security => 'सुरक्षा';

  @override
  String get changePin => 'PIN बदलें';

  @override
  String get autoLock => 'अपने-आप लॉक';

  @override
  String get lockImmediately => 'तुरंत';

  @override
  String lockAfterMin(int minutes) {
    return '$minutes मिनट बाद';
  }

  @override
  String get blockScreenshots => 'स्क्रीनशॉट रोकें';

  @override
  String get blockScreenshotsSub => 'हाल के ऐप में भी छिपाता है';

  @override
  String get gpsAndRoute => 'GPS और रास्ता';

  @override
  String get gpsThreshold => 'ज़रूरी GPS सटीकता';

  @override
  String get startPoint => 'रास्ते की शुरुआत';

  @override
  String get setOfficeHere => 'डाकघर = जहाँ मैं अभी हूँ';

  @override
  String get vibrateNear => 'जगह के 20 मी में कंपन';

  @override
  String get ttsSetting => 'अगला पड़ाव बोलकर बताएँ';

  @override
  String get ttsSettingSub => 'फ़ोन की टेक्स्ट-टू-स्पीच से';

  @override
  String get dataSection => 'डेटा';

  @override
  String get historyRetention => 'वितरण इतिहास रखें';

  @override
  String daysCount(int days) {
    return '$days दिन';
  }

  @override
  String oldDeleted(int count) {
    return '$count पुरानी डाक हटाई गई';
  }

  @override
  String get onlineMap => 'ऑनलाइन नक्शा (OpenStreetMap)';

  @override
  String get onlineMapSub => 'शुरू में बंद। केवल नक्शे की तस्वीरों के लिए इंटरनेट।';

  @override
  String get onlineMapConfirm =>
      'देखते समय नक्शा OpenStreetMap से तस्वीरें लाता है। आपके नाम और पते कभी नहीं भेजे जाते। चालू करें?';

  @override
  String get mapNotInBuild => 'यह ऑफ़लाइन संस्करण है (इंटरनेट अनुमति नहीं)। ऑनलाइन नक्शे के लिए “map” संस्करण लगाएँ।';

  @override
  String get deleteAll => 'सारा डेटा हटाएँ';

  @override
  String get deleteAllConfirm1 =>
      'यह इस फ़ोन से सारी बीट, जगहें, फ़ोटो, नाम और इतिहास हटा देगा। वापस नहीं आएगा। पहले बैकअप लें।';

  @override
  String get deleteAllConfirm2 => 'पुष्टि के लिए DELETE लिखें';

  @override
  String get notDeleted => 'कुछ नहीं हटाया गया';

  @override
  String get helpAndAbout => 'मदद और जानकारी';

  @override
  String get licences => 'ओपन-सोर्स लाइसेंस';

  @override
  String get help1Title => 'अपनी बीट और गलियाँ बनाएँ';

  @override
  String get help1Body => 'हर गली जोड़ें और उन्हें अपने रोज़ के चलने के क्रम में खींचकर लगाएँ।';

  @override
  String get help2Title => 'हर दरवाज़े पर “यहाँ जोड़ें”';

  @override
  String get help2Body => 'GPS सहेजा जाता है, 1–3 फ़ोटो लें, फिर मकान नं., गली, नाम (बोलकर) और “कुत्ता” जैसे नोट।';

  @override
  String get help3Title => 'कुछ भी खोजें';

  @override
  String get help3Body => 'नाम, मकान नं., गली या निशानी लिखें या बोलें। छोटी गलतियाँ चलेंगी।';

  @override
  String get help4Title => 'तीर के पीछे चलें';

  @override
  String get help4Body => 'रास्ता दिखाएँ — बड़ा तीर और घर तक मीटर; इंटरनेट नहीं चाहिए। पास आने पर फ़ोन काँपता है।';

  @override
  String get help5Title => 'आज की डाक जोड़ें';

  @override
  String get help5Body => 'बारकोड स्कैन करें या पते की फ़ोटो लें — ऐप मिलता घर सुझाएगा। एक टैप में पक्का करें।';

  @override
  String get help6Title => 'योजना बनाएँ और बाँटें';

  @override
  String get help6Body => 'रास्ता बनाएँ, फिर हर पड़ाव पर ✅ बाँट दी या ❌ नहीं बँटी दबाएँ।';

  @override
  String get help7Title => 'दिन का सारांश';

  @override
  String get help7Body => 'गिनती और कारण देखें, दोबारा प्रयास अगले दिन में जोड़ें और सारांश भेजें।';

  @override
  String get help8Title => 'नई बीट सीखें';

  @override
  String get help8Body => 'फ़ोटो और नाम कार्ड से अभ्यास करें, या चलते समय चलते-चलते मोड लें।';

  @override
  String get help9Title => 'सौंपना और बैकअप';

  @override
  String get help9Body => 'अपनी बीट रिलीफ़ डाकिये को एन्क्रिप्टेड फ़ाइल में दें। हर हफ़्ते पूरा बैकअप लें।';

  @override
  String get helpKannadaOcr =>
      'ध्यान दें: फ़ोन का टेक्स्ट रीडर अंग्रेज़ी और हिंदी (देवनागरी) छपाई पढ़ता है, कन्नड़ लिपि नहीं। कन्नड़ पतों के लिए नाम या मकान नं. से खोजें — कन्नड़ टाइपिंग और बोलकर खोज चलती है।';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'सॉर्टिंग सहायक';

  @override
  String get navSort => 'सॉर्ट';

  @override
  String get navFindPin => 'पिन खोजें';

  @override
  String get navBulk => 'बल्क';

  @override
  String get navLearn => 'अभ्यास';

  @override
  String get navMore => 'और';

  @override
  String get disclaimer =>
      'डाक कर्मचारियों के लिए स्वतंत्र सहायक टूल। यह डाक विभाग का आधिकारिक ऐप नहीं है।';

  @override
  String get dataCredit =>
      'पिन डेटा: data.gov.in, भारत सरकार, ओपन गवर्नमेंट डेटा लाइसेंस';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get close => 'बंद करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get share => 'शेयर करें';

  @override
  String get search => 'खोजें';

  @override
  String get next => 'आगे';

  @override
  String get back => 'पीछे';

  @override
  String get done => 'हो गया';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String error(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String confirmDelete(String name) {
    return '\"$name\" हटाएं?';
  }

  @override
  String get sampleBadge => 'नमूना – असली नहीं';

  @override
  String get noActiveScheme =>
      'कोई सॉर्टिंग स्कीम सक्रिय नहीं है। और → स्कीम में अपने कार्यालय की स्कीम आयात करें (या नमूना उपयोग करें)।';

  @override
  String get useSample => 'नमूना स्कीम उपयोग करें';

  @override
  String get about => 'परिचय';

  @override
  String get aboutSub => 'अस्वीकरण, गोपनीयता, डेटा स्रोत, संस्करण';

  @override
  String get active => 'सक्रिय';

  @override
  String get schemes => 'सॉर्टिंग स्कीम';

  @override
  String get schemesSub => 'आयात, बनाएं, निर्यात, सक्रिय स्कीम चुनें';

  @override
  String get pinDirectory => 'पिन निर्देशिका';

  @override
  String get pinDirectorySub =>
      'ऑफ़लाइन अखिल भारतीय डाकघर सूची, CSV से अपडेट करें';

  @override
  String get favourites => 'पसंदीदा';

  @override
  String get favouritesSub => 'सहेजे गए डाकघर और पिन';

  @override
  String get airportCodes => 'हवाई अड्डा कोड';

  @override
  String get airportCodesSub =>
      'सार्वजनिक IATA कोड संदर्भ (सॉर्टिंग नियम नहीं)';

  @override
  String get airportDisclaimer =>
      'केवल सार्वजनिक संदर्भ। एयर लेबल कोड हमेशा आपके कार्यालय की आयात की गई एयर कोड शीट से आते हैं।';

  @override
  String get airportSearchHint => 'शहर, हवाई अड्डा, कोड या राज्य';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get settingsSub => 'भाषा, थीम, कीपैड, पढ़कर सुनाना, कंपन';

  @override
  String get help => 'सहायता';

  @override
  String get helpSub => 'संक्षिप्त मार्गदर्शिका';

  @override
  String get preparingDirectory => 'ऑफ़लाइन पिन निर्देशिका तैयार हो रही है…';

  @override
  String get language => 'भाषा';

  @override
  String get languageDevice => 'डिवाइस की भाषा';

  @override
  String get theme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'हल्की';

  @override
  String get themeDark => 'गहरी';

  @override
  String get keypadSize => 'कीपैड का आकार';

  @override
  String get ttsSetting => 'बैग / एयर कोड पढ़कर सुनाएं';

  @override
  String get ttsSettingSub =>
      'फ़ोन की ऑफ़लाइन टेक्स्ट-टू-स्पीच आवाज़ का उपयोग करता है';

  @override
  String get hapticsSetting => 'हर परिणाम पर कंपन';

  @override
  String get mismatchFieldSetting => '\"पते पर स्थान\" फ़ील्ड दिखाएं';

  @override
  String get mismatchFieldSettingSub =>
      'वस्तु पर लिखे शहर/डाकघर से पिन की जाँच करता है';

  @override
  String get defaultScanMode => 'डिफ़ॉल्ट स्कैन लिपि';

  @override
  String get scriptLatin => 'अंग्रेज़ी (लैटिन)';

  @override
  String get scriptDevanagari => 'हिन्दी (देवनागरी)';

  @override
  String get categories => 'डाक श्रेणियाँ';

  @override
  String get categoriesSub => 'सॉर्ट स्क्रीन पर टॉगल के रूप में दिखती हैं';

  @override
  String get addCategory => 'श्रेणी जोड़ें';

  @override
  String get catLetters => 'साधारण/पत्र';

  @override
  String get catParcel => 'पार्सल (सतही)';

  @override
  String get catAirParcel => 'एयर पार्सल';

  @override
  String get catSpeedPost => 'स्पीड पोस्ट';

  @override
  String versionN(String version) {
    return 'संस्करण $version';
  }

  @override
  String get privacyTitle => 'गोपनीयता';

  @override
  String get privacyText =>
      'सब कुछ ऑफ़लाइन काम करता है। कोई लॉगिन नहीं, कोई विज्ञापन नहीं, कोई एनालिटिक्स नहीं, कोई इंटरनेट अनुमति नहीं। कैमरा स्कैन फ़ोन पर ही प्रोसेस होता है और फ़ोटो तुरंत हटा दी जाती है — कुछ भी सहेजा या अपलोड नहीं किया जाता। आपकी स्कीम, सत्र और प्रगति केवल इसी फ़ोन पर रहते हैं।';

  @override
  String get dataTitle => 'डेटा';

  @override
  String get schemeDataNote =>
      'सॉर्टिंग स्कीम, एयर कोड शीट और DMSL विभागीय दस्तावेज़ हैं: ऐप में कोई शामिल नहीं है। हर उपयोगकर्ता अपनी फ़ाइल आयात करता है; साथ दिया गया नमूना नकली है।';

  @override
  String get licenceTitle => 'लाइसेंस';

  @override
  String get licenceText =>
      'मुफ़्त ऐप। हवाई अड्डा कोड सार्वजनिक IATA जानकारी हैं।';

  @override
  String get openSourceLicences => 'ओपन-सोर्स लाइसेंस';

  @override
  String get none => 'कोई नहीं';

  @override
  String get unknown => 'अज्ञात';

  @override
  String get notSet => 'सेट नहीं';

  @override
  String get note => 'नोट';

  @override
  String get date => 'तारीख़';

  @override
  String get total => 'कुल';

  @override
  String totalN(int count) {
    return 'कुल: $count';
  }

  @override
  String get start => 'शुरू करें';

  @override
  String get summary => 'सारांश';

  @override
  String get again => 'फिर से';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get sheet => 'शीट';

  @override
  String get validate => 'जाँचें';

  @override
  String get enterPin => 'पिन दर्ज करें';

  @override
  String get backspace => 'अंतिम अंक हटाएं';

  @override
  String get voiceInput => 'आवाज़ से इनपुट';

  @override
  String get scanAddress => 'पता स्कैन करें';

  @override
  String get checkPlace => 'पिन बनाम स्थान जाँच';

  @override
  String get placeOnAddress => 'पते पर लिखा शहर / डाकघर';

  @override
  String get recentLookups => 'हाल की खोजें';

  @override
  String get sortHint => 'कीपैड पर पिन टाइप करें। टाइप करते ही बैग दिखेगा।';

  @override
  String get bag => 'बैग';

  @override
  String get bags => 'बैग';

  @override
  String get section => 'अनुभाग';

  @override
  String matchedBy(String type, String key) {
    return '$type से मिला: $key';
  }

  @override
  String get likelyBag => 'संभावित बैग (उपसर्ग से)';

  @override
  String get possibleBags => 'संभावित बैग';

  @override
  String sortingDistrictN(String code) {
    return 'सॉर्टिंग ज़िला $code';
  }

  @override
  String get prefixNotInDirectory =>
      'इस उपसर्ग वाले डाकघर निर्देशिका में नहीं हैं';

  @override
  String get pinNotInDirectory => 'पिन निर्देशिका में नहीं है – पता जाँचें';

  @override
  String get invalidPin => 'अमान्य पिन (6 अंक, पहला अंक 1–9)';

  @override
  String get noBagRule =>
      'इस पिन के लिए कोई बैग नियम नहीं – पर्यवेक्षक से पूछें';

  @override
  String deliveryOfficesN(int count) {
    return 'वितरण डाकघर: $count';
  }

  @override
  String andMore(int count) {
    return '…और $count अन्य';
  }

  @override
  String get delivery => 'वितरण';

  @override
  String get nonDelivery => 'गैर-वितरण';

  @override
  String get typeHO => 'प्रधान डाकघर';

  @override
  String get typeSO => 'उप डाकघर';

  @override
  String get typeBO => 'शाखा डाकघर';

  @override
  String get typePO => 'डाकघर';

  @override
  String get pinStructure => 'पिन संरचना';

  @override
  String get pinZone => 'डाक क्षेत्र';

  @override
  String get pinCircle => 'डाक सर्किल';

  @override
  String get pinSortingDistrict => 'सॉर्टिंग ज़िला';

  @override
  String get pinSortingDistrictHelp => 'पहले 3 अंक';

  @override
  String get pinDeliveryOffice => 'वितरण डाकघर';

  @override
  String get pinDeliveryOfficeHelp => 'अंतिम 3 अंक';

  @override
  String get airLabelCode => 'एयर लेबल कोड';

  @override
  String get noAirCode => 'कोई एयर कोड नहीं – पर्यवेक्षक से पूछें';

  @override
  String get readAloud => 'पढ़कर सुनाएं';

  @override
  String get via => 'होकर';

  @override
  String get badgeAir => 'एयर AIR';

  @override
  String get badgeSurface => 'सतही SURFACE';

  @override
  String labelBadge(String text) {
    return 'लेबल रंग: $text';
  }

  @override
  String get labelBadgeShort => 'लेबल';

  @override
  String get connectivityDefaulted =>
      'नियम में कनेक्टिविटी नहीं दी गई – सतही माना गया। पर्यवेक्षक से पूछें।';

  @override
  String get connAir => 'एयर';

  @override
  String get connSurface => 'सतही';

  @override
  String get hubRoute => 'पार्सल हब मार्ग';

  @override
  String directToL1(String hub) {
    return 'सीधे L1 हब को: $hub';
  }

  @override
  String get noDmsl => 'इस स्कीम के लिए कोई DMSL आयात नहीं';

  @override
  String get noHubRoute => 'DMSL में इस पिन के लिए कोई हब नियम नहीं';

  @override
  String dmslVersionLabel(String version) {
    return 'DMSL $version';
  }

  @override
  String get labelView => 'लेबल दृश्य';

  @override
  String get shareImage => 'चित्र के रूप में शेयर करें';

  @override
  String get shareText => 'टेक्स्ट के रूप में शेयर करें';

  @override
  String get listening => 'सुन रहा है…';

  @override
  String get sayPin => 'पिन के अंक बोलें';

  @override
  String get voiceUnavailable => 'इस फ़ोन पर आवाज़ पहचान उपलब्ध नहीं है';

  @override
  String get unresolved => 'अनसुलझा';

  @override
  String get findPinHint => 'डाकघर, गाँव, शहर, तहसील या ज़िला';

  @override
  String get findPinTip =>
      'अंग्रेज़ी, कन्नड़ या हिन्दी में टाइप करें। वर्तनी की गलती चलेगी: \"Puttoor\", \"Putur\" और \"पुत्तूर\" सभी Puttur ढूंढते हैं।';

  @override
  String get allStates => 'सभी राज्य';

  @override
  String get allDistricts => 'सभी ज़िले';

  @override
  String get deliveryOnly => 'केवल वितरण डाकघर';

  @override
  String get noResults => 'कोई मिलता डाकघर नहीं मिला';

  @override
  String get taluk => 'तहसील';

  @override
  String get division => 'मंडल';

  @override
  String get sortThisPin => 'इस पिन को सॉर्ट करें';

  @override
  String get copyPin => 'पिन कॉपी करें';

  @override
  String get addFavourite => 'पसंदीदा में जोड़ें';

  @override
  String get removeFavourite => 'पसंदीदा से हटाएं';

  @override
  String get noFavourites => 'अभी कोई पसंदीदा नहीं। पिन खोजें से डाकघर जोड़ें।';

  @override
  String get mismatchChecker => 'पिन ↔ स्थान जाँच';

  @override
  String get mismatchCheckerSub => 'गलत सॉर्टिंग से पहले गलत पिन पकड़ें';

  @override
  String get mmMatch => '✅ स्थान इस पिन से मेल खाता है';

  @override
  String get mmSameDistrict => '⚠️ वही ज़िला, पर पिन अलग है';

  @override
  String get mmDifferent =>
      '❌ स्थान दूसरे ज़िले/राज्य में है – पिन शायद गलत है';

  @override
  String get mmUnknownPlace => 'स्थान निर्देशिका में नहीं मिला – वर्तनी जाँचें';

  @override
  String mmPinIs(String pin, String office) {
    return 'पिन $pin: $office';
  }

  @override
  String mmPlaceIs(String place, String district) {
    return '\"$place\" $district में है';
  }

  @override
  String get suggestedPins => 'सुझाए गए पिन:';

  @override
  String get scanHint =>
      'पते (पिन सहित) की ओर करें और कैप्चर दबाएं। कुछ भी सहेजा नहीं जाता।';

  @override
  String get capture => 'कैप्चर';

  @override
  String get torch => 'टॉर्च';

  @override
  String get scanScript => 'टेक्स्ट लिपि';

  @override
  String cameraUnavailable(String error) {
    return 'कैमरा उपलब्ध नहीं: $error';
  }

  @override
  String get noPinDetected =>
      'टेक्स्ट में पिन नहीं मिला – टाइप करें या स्थान खोजें';

  @override
  String get detectedPin => 'पहचाना गया पिन (गलत हो तो सुधारें)';

  @override
  String get detectedPlace => 'पहचाना गया शहर / डाकघर';

  @override
  String get useThisPin => 'यह पिन उपयोग करें';

  @override
  String get addToBulk => 'बल्क गिनती में जोड़ें';

  @override
  String get scanAgain => 'फिर से स्कैन';

  @override
  String get scanPrivacy =>
      'टेक्स्ट फ़ोन पर ML Kit से पढ़ा जाता है। पढ़ते ही फ़ोटो हटा दी जाती है। ML Kit अंग्रेज़ी और हिन्दी लिपि पढ़ता है; कन्नड़ पतों के लिए पिन अंक उपयोग होते हैं और स्थान हाथ से खोज सकते हैं।';

  @override
  String get noOpenSession =>
      'कोई बल्क सत्र चालू नहीं – बल्क टैब में शुरू करें';

  @override
  String addedToBulk(String bag) {
    return 'जोड़ा गया: $bag';
  }

  @override
  String get bulkTitle => 'बल्क सॉर्टिंग';

  @override
  String get bulkEmpty =>
      'बैग-वार वस्तुएं गिनें: सत्र शुरू करें, पिन जल्दी दर्ज करें, फिर गिनती शेयर करें।';

  @override
  String get startSession => 'सत्र शुरू करें';

  @override
  String get sessionName => 'सत्र का नाम';

  @override
  String sessionDefaultName(String time) {
    return 'सत्र $time';
  }

  @override
  String get scheme => 'स्कीम';

  @override
  String get inProgress => 'चालू';

  @override
  String get undoLast => 'अंतिम पूर्ववत करें';

  @override
  String get endSession => 'समाप्त';

  @override
  String unresolvedEntries(int count) {
    return 'अनसुलझे / अमान्य: $count (सुधारने के लिए दबाएं)';
  }

  @override
  String fixEntry(String raw) {
    return '\"$raw\" सुधारें';
  }

  @override
  String get shareCsv => 'CSV शेयर करें';

  @override
  String get sharePrintable => 'प्रिंट योग्य टेक्स्ट फ़ाइल शेयर करें';

  @override
  String get continueSession => 'गिनती जारी रखें';

  @override
  String get learnNeedsScheme =>
      'अभ्यास सक्रिय स्कीम का उपयोग करता है। अपने कार्यालय की स्कीम आयात करें या नमूना आज़माएं।';

  @override
  String get learnFromScheme => 'प्रश्न इसी स्कीम से आते हैं';

  @override
  String get flashcards => 'बैग फ़्लैशकार्ड';

  @override
  String get flashcardsSub => 'पिन → कौन-सा बैग? अंतराल पुनरावृत्ति';

  @override
  String get timedQuiz => 'समयबद्ध सॉर्टिंग क्विज़';

  @override
  String get timedQuizSub => '20 वस्तुएं, 4 विकल्प, अंक और गति';

  @override
  String get airFlashcards => 'एयर कोड फ़्लैशकार्ड';

  @override
  String get airFlashcardsSub => 'पिन / ज़िला → एयर कोड';

  @override
  String get airQuiz => 'एयर कोड क्विज़';

  @override
  String get airQuizSub => 'आयातित एयर कोड शीट चाहिए';

  @override
  String get hubFlashcards => 'पार्सल हब फ़्लैशकार्ड';

  @override
  String get hubFlashcardsSub => 'पिन → सक्रिय DMSL से L2 / L1 हब';

  @override
  String get weakAreas => 'कमज़ोर क्षेत्र';

  @override
  String get weakAreasSub =>
      'बैग और पिन श्रृंखला जिनमें सबसे ज़्यादा गलती होती है';

  @override
  String get pinBasics => 'पिन की मूल बातें';

  @override
  String get pinBasicsSub => 'क्षेत्र, सर्किल, सॉर्टिंग ज़िला, वितरण डाकघर';

  @override
  String get noCards =>
      'कोई कार्ड नहीं: स्कीम में इस अभ्यास के लिए अभी नियम नहीं हैं।';

  @override
  String flashDone(int known, int unknown) {
    return 'दौर पूरा! पता था: $known, नहीं पता: $unknown';
  }

  @override
  String leitnerBox(int box) {
    return '5 में से बॉक्स $box';
  }

  @override
  String get qWhichBagPin => 'इस पिन के लिए कौन-सा बैग';

  @override
  String get qWhichBagPlace => 'इसके लिए कौन-सा बैग';

  @override
  String get qWhichAirCode => 'इसके लिए कौन-सा एयर कोड';

  @override
  String get qWhichHub => 'इस पिन के लिए कौन-सा पार्सल हब मार्ग';

  @override
  String get answer => 'उत्तर';

  @override
  String get tapToFlip => 'पलटने के लिए कार्ड दबाएं';

  @override
  String get showAnswer => 'उत्तर दिखाएं';

  @override
  String get knewIt => 'मुझे पता था';

  @override
  String get didntKnow => 'नहीं पता था';

  @override
  String scoreN(int score) {
    return 'अंक $score';
  }

  @override
  String quizScore(int score, int total) {
    return '$score / $total';
  }

  @override
  String quizStats(int seconds, String apm) {
    return '$seconds से · प्रति मिनट $apm वस्तुएं';
  }

  @override
  String get history => 'अंक इतिहास';

  @override
  String get historyNeedsMore => 'चार्ट देखने के लिए एक और क्विज़ दें';

  @override
  String get noWeakAreas => 'अभी कोई गलती दर्ज नहीं – पहले अभ्यास करें।';

  @override
  String get weakBags => 'सबसे ज़्यादा गलत बैग';

  @override
  String get weakPrefixes => 'सबसे ज़्यादा गलत पिन श्रृंखला';

  @override
  String wrongTimes(int count) {
    return '$count बार गलत';
  }

  @override
  String quizzesTaken(int count) {
    return 'दिए गए क्विज़: $count';
  }

  @override
  String averageScore(int percent) {
    return 'औसत अंक: $percent%';
  }

  @override
  String get resetProgress => 'प्रगति रीसेट करें';

  @override
  String get resetProgressConfirm =>
      'क्विज़ इतिहास, गलतियाँ और फ़्लैशकार्ड बॉक्स हटाएं?';

  @override
  String get pinBasicsIntro =>
      'पिन (पोस्टल इंडेक्स नंबर) में 6 अंक होते हैं। हर भाग बताता है कि वस्तु कहाँ जानी है:';

  @override
  String get pinBasicsDigits =>
      'अंक 1 = डाक क्षेत्र। अंक 1–2 = डाक सर्किल। अंक 1–3 = सॉर्टिंग ज़िला (डाक संभालने वाला सॉर्टिंग कार्यालय)। अंतिम 3 अंक = वितरण डाकघर। उदाहरण 574201: 5 = दक्षिणी क्षेत्र, 57 = कर्नाटक, 574 = सॉर्टिंग ज़िला, 201 = वितरण डाकघर।';

  @override
  String get pinZones => 'क्षेत्र (पहला अंक)';

  @override
  String get circleTable => 'सर्किल (पहले दो अंक)';

  @override
  String get pinBasicsNote =>
      'सर्किल सीमाएँ अनुमानित हैं; कुछ छोटे सर्किल पड़ोसियों के अंक साझा करते हैं (ऊपर सूची देखें)। हमेशा अपने कार्यालय की सॉर्टिंग स्कीम का पालन करें।';

  @override
  String get noSchemes =>
      'अभी कोई स्कीम नहीं। अपने कार्यालय की सॉर्टिंग स्कीम (Excel/CSV) आयात करें, नई बनाएं, या नमूना आज़माएं।';

  @override
  String get schemesPrivacy =>
      'स्कीम विभागीय दस्तावेज़ हैं: ये इसी फ़ोन पर रहती हैं। केवल अपनी टीम के साथ शेयर करें।';

  @override
  String get importScheme => 'स्कीम आयात करें';

  @override
  String get importSchemeSub => 'Excel (.xlsx) या CSV';

  @override
  String get importAirCodes => 'एयर कोड शीट आयात करें';

  @override
  String get importDmsl => 'DMSL आयात करें (पार्सल हब)';

  @override
  String get createManually => 'ऐप में स्कीम बनाएं';

  @override
  String get installSample => 'नमूना स्कीम जोड़ें (असली नहीं)';

  @override
  String get downloadTemplate => 'टेम्पलेट डाउनलोड करें';

  @override
  String get downloadSampleFile => 'नमूना स्कीम फ़ाइल सहेजें';

  @override
  String get templateSaved => 'सहेजा गया';

  @override
  String get newScheme => 'नई स्कीम';

  @override
  String get schemeName => 'स्कीम का नाम';

  @override
  String get officeName => 'कार्यालय';

  @override
  String get setActive => 'सक्रिय करें';

  @override
  String get exportXlsx => 'Excel के रूप में निर्यात / शेयर';

  @override
  String get exportCsv => 'CSV के रूप में निर्यात / शेयर';

  @override
  String get rules => 'नियम';

  @override
  String get airCodes => 'एयर कोड';

  @override
  String rulesCount(int count) {
    return '$count नियम';
  }

  @override
  String get filterRules => 'नियम फ़िल्टर करें';

  @override
  String get addRule => 'नियम जोड़ें';

  @override
  String get editRule => 'नियम संपादित करें';

  @override
  String get addBag => 'बैग जोड़ें';

  @override
  String get editBag => 'बैग संपादित करें';

  @override
  String deleteBagConfirm(String code) {
    return 'बैग $code और उसके सभी नियम हटाएं?';
  }

  @override
  String get invalidRuleKey =>
      'इस नियम प्रकार के लिए पिन / रेंज / उपसर्ग / नाम जाँचें';

  @override
  String get allCategories => 'सभी श्रेणियाँ';

  @override
  String get noAirCodes =>
      'कोई एयर कोड नहीं। अपने कार्यालय की एयर कोड शीट आयात करें (एयर पार्सल मोड कोड बड़े अक्षरों में दिखाता है)।';

  @override
  String get dmslHelp =>
      'ड्यू मेल सॉर्टिंग लिस्ट पिन को L2 → L1 पार्सल हब से जोड़ती है। हब सूचियाँ बदलती हैं (जैसे 7 अक्टूबर 2026 पुनर्गठन), इसलिए हर नया संस्करण आयात करें; सक्रिय करने के लिए संस्करण दबाएं।';

  @override
  String validFromDate(String date) {
    return '$date से मान्य';
  }

  @override
  String get compareWithPrevious => 'पिछले संस्करण से बदलाव';

  @override
  String get dmslChanges => 'DMSL बदलाव';

  @override
  String dmslCompare(String from, String to) {
    return '$from → $to';
  }

  @override
  String dmslChangedCount(int count) {
    return '$count पिन का हब बदला';
  }

  @override
  String get dmslNoChanges => 'इन संस्करणों के बीच किसी पिन का हब नहीं बदला।';

  @override
  String get practiseChanged => 'केवल बदले हुए पिन का अभ्यास करें';

  @override
  String get dmslVersionName => 'संस्करण का नाम';

  @override
  String get validFrom => 'से मान्य';

  @override
  String get stepFile => 'फ़ाइल';

  @override
  String get stepPreview => 'पूर्वावलोकन';

  @override
  String get stepMapping => 'कॉलम';

  @override
  String get stepReport => 'जाँचें और सहेजें';

  @override
  String get chooseFile => 'Excel / CSV फ़ाइल चुनें';

  @override
  String get importSchemeHelp =>
      'हर नियम के लिए एक पंक्ति। कॉलम (किसी भी क्रम में, अंग्रेज़ी/कन्नड़/हिन्दी शीर्षक): PIN, PIN From, PIN To, Prefix, Office, District, State, Bag No, Bag Name, Section, Remarks, Category, Connectivity (Air/Surface), Colour। बिना पिन/डाकघर/ज़िले वाली पंक्ति \"बाकी सब\" (डिफ़ॉल्ट) बैग है।';

  @override
  String get importAirHelp =>
      'कॉलम: PIN, PIN From, PIN To, Prefix, District, State, Air Code, Station, Via, Remarks। कोड हवाई अड्डा सूची से जाँचे जाते हैं; अज्ञात कोड चेतावनी के साथ रखे जाते हैं।';

  @override
  String get importDmslHelp =>
      'कॉलम: PIN / PIN From / PIN To / Prefix / Office, L2 Hub, L1 Hub, Direct closure (Y/N), Connectivity (Air/Surface), Remarks। आयात के बाद दिखेगा कि किन पिन का हब बदला।';

  @override
  String get importPrivacy => 'फ़ाइल केवल फ़ोन पर पढ़ी जाती है।';

  @override
  String get headerRow => 'शीर्षक पंक्ति';

  @override
  String previewRows(int shown, int total) {
    return '$total में से $shown पंक्तियाँ';
  }

  @override
  String get mappingHelp =>
      'जाँचें कि हर फ़ील्ड किस कॉलम में है। शीर्षकों से अपने-आप पहचाना गया; गलत हो तो बदलें।';

  @override
  String get notMapped => '— फ़ाइल में नहीं —';

  @override
  String reportRulesOk(int count) {
    return '$count नियम तैयार';
  }

  @override
  String reportSummary(int errors, int warnings) {
    return '$errors पंक्तियाँ छोड़ी गईं · $warnings चेतावनियाँ';
  }

  @override
  String bagsFound(int count) {
    return '$count बैग मिले';
  }

  @override
  String get airReplaceNote =>
      'सहेजने से इस स्कीम की मौजूदा एयर कोड तालिका बदल जाएगी।';

  @override
  String rowN(int row) {
    return 'पंक्ति $row';
  }

  @override
  String saveRules(int count) {
    return '$count सहेजें';
  }

  @override
  String importSaved(int count) {
    return '$count नियम आयात हुए';
  }

  @override
  String get issueBadPin => 'गलत पिन / रेंज / उपसर्ग';

  @override
  String get issueNoBag => 'पंक्ति में बैग / कोड / हब नहीं';

  @override
  String get issueNoMatch => 'पिन / डाकघर / ज़िला नहीं';

  @override
  String get issueDuplicate => 'दोहराए गए नियम';

  @override
  String get issueConflict => 'परस्पर विरोधी नियम (एक ही कुंजी, अलग परिणाम)';

  @override
  String get issueOverlap => 'एक-दूसरे पर चढ़ती पिन रेंज';

  @override
  String get issueNested => 'अंदर की रेंज (छोटी जीतती है)';

  @override
  String get issueUnknownAir =>
      'हवाई अड्डा सूची में न होने वाले एयर कोड (रखे गए)';

  @override
  String get issueNoConnectivity => 'कनेक्टिविटी खाली (सतही माना गया)';

  @override
  String get issueDefault => '\"बाकी सब\" मानी गई पंक्तियाँ';

  @override
  String get issueBadColour => 'अज्ञात रंग';

  @override
  String get ruleExact => 'सटीक पिन';

  @override
  String get ruleRange => 'पिन रेंज';

  @override
  String get rulePrefix => 'उपसर्ग';

  @override
  String get ruleOffice => 'डाकघर का नाम';

  @override
  String get ruleDistrict => 'ज़िला';

  @override
  String get ruleState => 'राज्य';

  @override
  String get ruleDefault => 'बाकी सब (डिफ़ॉल्ट)';

  @override
  String get fType => 'नियम प्रकार';

  @override
  String get fPin => 'पिन';

  @override
  String get fPinFrom => 'पिन से';

  @override
  String get fPinTo => 'पिन तक';

  @override
  String get fPrefix => 'उपसर्ग (पहले 1–5 अंक)';

  @override
  String get fOffice => 'डाकघर';

  @override
  String get fDistrict => 'ज़िला';

  @override
  String get fState => 'राज्य';

  @override
  String get fBagCode => 'बैग नं. / कोड';

  @override
  String get fBagName => 'बैग का नाम';

  @override
  String get fSection => 'अनुभाग';

  @override
  String get fRemarks => 'टिप्पणी';

  @override
  String get fCategory => 'डाक श्रेणी';

  @override
  String get fConnectivity => 'कनेक्टिविटी (एयर/सतही)';

  @override
  String get fColour => 'बैग का रंग';

  @override
  String get fAirCode => 'एयर कोड';

  @override
  String get fStation => 'एयर स्टेशन';

  @override
  String get fVia => 'होकर हब';

  @override
  String get fL2Hub => 'L2 हब';

  @override
  String get fL1Hub => 'L1 हब';

  @override
  String get fDirect => 'सीधा बंद (Y/N)';

  @override
  String get dirSource => 'स्रोत';

  @override
  String get dirRows => 'डाकघर';

  @override
  String get dirFileDate => 'डेटा फ़ाइल तारीख़';

  @override
  String get dirBuilt => 'बनाने की तारीख़';

  @override
  String get dirStateFilter => 'राज्य फ़िल्टर';

  @override
  String get dirSearchIndex => 'खोज इंडेक्स';

  @override
  String get dirPlaceholderWarning =>
      'यह केवल एक छोटी परीक्षण निर्देशिका है। नीचे data.gov.in से पूरी \"All India Pincode Directory\" CSV आयात करें।';

  @override
  String get dirUpdateHelp =>
      'data.gov.in से नई \"All India Pincode Directory\" CSV डाउनलोड करें, इस फ़ोन पर कॉपी करें, फिर यहाँ आयात करें। पूरे भारत के लिए राज्य खाली छोड़ें।';

  @override
  String get dirStateOnly => 'केवल यह राज्य (वैकल्पिक)';

  @override
  String get updateDirectory => 'CSV से पिन निर्देशिका अपडेट करें';

  @override
  String get dirParsing => 'CSV पढ़ी और साफ़ की जा रही है…';

  @override
  String get dirWriting => 'ऑफ़लाइन डेटाबेस बन रहा है…';

  @override
  String directoryUpdated(int count) {
    return 'निर्देशिका अपडेट: $count डाकघर';
  }

  @override
  String get help1Title => 'अपनी स्कीम आयात करें';

  @override
  String get help1 =>
      'और → सॉर्टिंग स्कीम → जोड़ें। अपने कार्यालय की Excel/CSV चुनें, कॉलम जाँचें और सहेजें। फ़ाइल नहीं है? टेम्पलेट डाउनलोड करें या नमूना स्कीम (नकली डेटा) आज़माएं।';

  @override
  String get help2Title => 'पिन से सॉर्ट करें';

  @override
  String get help2 =>
      'बड़े कीपैड पर पिन टाइप करें। 3 अंकों के बाद सॉर्टिंग ज़िला और संभावित बैग; 6 अंकों के बाद अंतिम बैग उसके रंग में। अगला अंक टाइप करते ही नया पिन शुरू। साफ़ करने के लिए ⌫ देर तक दबाएं।';

  @override
  String get help3Title => 'पार्सल और एयर पार्सल';

  @override
  String get help3 =>
      'ऊपर डाक श्रेणी चुनें। एयर पार्सल मोड में एयर लेबल कोड बहुत बड़े अक्षरों में, पीला AIR / नीला SURFACE बैज, L2 → L1 हब मार्ग और बैग दिखता है। बड़ा लेबल दिखाने या शेयर करने के लिए \"लेबल दृश्य\" उपयोग करें।';

  @override
  String get help4Title => 'वस्तु पर पिन नहीं?';

  @override
  String get help4 =>
      'पिन खोजें: डाकघर, गाँव, शहर, तहसील या ज़िला अंग्रेज़ी, कन्नड़ या हिन्दी में टाइप करें। वर्तनी की गलतियाँ चलती हैं। हर परिणाम उसका बैग दिखाता है।';

  @override
  String get help5Title => 'गलत पिन पकड़ें';

  @override
  String get help5 =>
      'स्थान जाँच चालू करें (सॉर्ट पर ✓ आइकन) और वस्तु पर लिखा शहर टाइप करें। ✅ मेल, ⚠️ वही ज़िला पर अलग पिन, ❌ अलग ज़िला/राज्य – सुझाए गए पिन के साथ।';

  @override
  String get help6Title => 'पता स्कैन करें';

  @override
  String get help6 =>
      'स्कैन आइकन दबाएं, कैमरा पते की ओर करें और कैप्चर करें। पिन और शहर फ़ोन पर ही पढ़े जाते हैं; फ़ोटो तुरंत हटा दी जाती है।';

  @override
  String get help7Title => 'बैग-वार वस्तुएं गिनें';

  @override
  String get help7 =>
      'बल्क → सत्र शुरू करें। पिन एक के बाद एक दर्ज करें; हर एक अपने बैग का रंग चमकाकर गिनती में जुड़ता है। अंतिम प्रविष्टि पूर्ववत करें, अनसुलझी सुधारें, फिर मैनिफ़ेस्ट से मिलान के लिए सारांश शेयर करें।';

  @override
  String get help8Title => 'अभ्यास करें';

  @override
  String get help8 =>
      'अभ्यास: अंतराल पुनरावृत्ति वाले फ़्लैशकार्ड, 20 वस्तुओं का समयबद्ध क्विज़, कमज़ोर क्षेत्र और पिन की मूल बातें। नए DMSL के बाद केवल वे पिन अभ्यास करें जिनका हब बदला।';
}

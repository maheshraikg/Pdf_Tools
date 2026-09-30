// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PO Sorting';

  @override
  String get navSort => 'Sort';

  @override
  String get navFindPin => 'Find PIN';

  @override
  String get navBulk => 'Bulk';

  @override
  String get navLearn => 'Learn';

  @override
  String get navMore => 'More';

  @override
  String get disclaimer =>
      'Independent helper tool for postal staff. Not an official Department of Posts app.';

  @override
  String get dataCredit =>
      'PIN data: data.gov.in, Government of India, Open Government Data Licence';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get clear => 'Clear';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get share => 'Share';

  @override
  String get search => 'Search';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get undo => 'Undo';

  @override
  String get loading => 'Loading…';

  @override
  String error(String message) {
    return 'Error: $message';
  }

  @override
  String confirmDelete(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get sampleBadge => 'SAMPLE – not real';

  @override
  String get noActiveScheme =>
      'No sorting scheme active. Import your office\'s scheme in More → Schemes (or use the sample).';

  @override
  String get useSample => 'Use sample scheme';

  @override
  String get about => 'About';

  @override
  String get aboutSub => 'Disclaimer, privacy, data source, version';

  @override
  String get active => 'Active';

  @override
  String get schemes => 'Sorting schemes';

  @override
  String get schemesSub => 'Import, create, export, choose active scheme';

  @override
  String get pinDirectory => 'PIN directory';

  @override
  String get pinDirectorySub =>
      'Offline all-India office list, update from CSV';

  @override
  String get favourites => 'Favourites';

  @override
  String get favouritesSub => 'Saved offices and PINs';

  @override
  String get airportCodes => 'Airport codes';

  @override
  String get airportCodesSub =>
      'Public IATA code reference (not sorting rules)';

  @override
  String get airportDisclaimer =>
      'Public reference only. Air label codes always come from your office\'s imported air code sheet.';

  @override
  String get airportSearchHint => 'City, airport, code or state';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSub => 'Language, theme, keypad, read-out, haptics';

  @override
  String get help => 'Help';

  @override
  String get helpSub => 'Short guide';

  @override
  String get preparingDirectory => 'Preparing offline PIN directory…';

  @override
  String get language => 'Language';

  @override
  String get languageDevice => 'Device language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get keypadSize => 'Keypad size';

  @override
  String get ttsSetting => 'Read out bag / air code';

  @override
  String get ttsSettingSub => 'Uses the phone\'s offline text-to-speech voice';

  @override
  String get hapticsSetting => 'Vibrate on each result';

  @override
  String get mismatchFieldSetting => 'Show \"place on address\" field';

  @override
  String get mismatchFieldSettingSub =>
      'Checks PIN against the city/office written on the article';

  @override
  String get categories => 'Mail categories';

  @override
  String get categoriesSub => 'Shown as the toggle on the Sort screen';

  @override
  String get addCategory => 'Add category';

  @override
  String get catLetters => 'Ordinary/Letters';

  @override
  String get catParcel => 'Parcel (surface)';

  @override
  String get catAirParcel => 'Air Parcel';

  @override
  String get catSpeedPost => 'Speed Post';

  @override
  String versionN(String version) {
    return 'Version $version';
  }

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyText =>
      'Everything works offline. No login, no ads, no analytics, no internet permission. Camera scans are processed on the phone and the photo is deleted immediately — nothing is stored or uploaded. Your schemes, sessions and progress stay only on this phone.';

  @override
  String get dataTitle => 'Data';

  @override
  String get schemeDataNote =>
      'The app comes with a default Mangaluru TD / Non-TD scheme compiled from sorting lists shared by postal staff. You can edit or delete it, restore it, or import your own file. The SAMPLE scheme is fake demo data.';

  @override
  String get licenceTitle => 'Licence';

  @override
  String get licenceText =>
      'Free app. Airport codes are public IATA information.';

  @override
  String get openSourceLicences => 'Open-source licences';

  @override
  String get none => 'None';

  @override
  String get unknown => 'Unknown';

  @override
  String get notSet => 'Not set';

  @override
  String get note => 'Note';

  @override
  String get date => 'Date';

  @override
  String get total => 'Total';

  @override
  String totalN(int count) {
    return 'Total: $count';
  }

  @override
  String get start => 'Start';

  @override
  String get summary => 'Summary';

  @override
  String get again => 'Again';

  @override
  String get rename => 'Rename';

  @override
  String get sheet => 'Sheet';

  @override
  String get validate => 'Check';

  @override
  String get catTD => 'TD';

  @override
  String get catNonTD => 'Non-TD';

  @override
  String otherModeHint(String mode, String bag) {
    return 'This PIN is in $mode: $bag';
  }

  @override
  String get navAir => 'Air';

  @override
  String get airFinderTitle => 'Air code finder';

  @override
  String get airSearchHint => 'PIN, city or code (IXE)';

  @override
  String get airFinderHelp =>
      'Type a 6-digit PIN to get the air code, or search by city, airport or 3-letter code.';

  @override
  String allAirports(int count) {
    return 'All airports ($count)';
  }

  @override
  String get fromYourScheme => 'From your office\'s air code list';

  @override
  String get nearestAirport => 'Nearest airport';

  @override
  String kmAway(String km) {
    return '$km km';
  }

  @override
  String get airRefNote =>
      'Reference only (nearest airport to the post office). Import your office\'s air code list to use its codes.';

  @override
  String get otherNearbyAirports => 'Other nearby airports';

  @override
  String get yourAirCodes => 'Your air code list';

  @override
  String airportsInState(String state) {
    return 'Airports in $state';
  }

  @override
  String get typeFullPinForAir => 'Type all 6 digits of the PIN';

  @override
  String get noAirportFound => 'No airport found';

  @override
  String get postOfficesFound => 'Post offices';

  @override
  String get soLabel => 'SO';

  @override
  String get noLineInScheme =>
      'No line / bag in your scheme – tap to see the PIN';

  @override
  String showAllN(int count) {
    return 'Show all $count';
  }

  @override
  String get addOffice => 'Add office';

  @override
  String get openThisPin => 'Open this PIN';

  @override
  String get restoreDefault => 'Restore default Mangaluru scheme';

  @override
  String get defaultRestored => 'Default scheme restored';

  @override
  String get legalTitle => 'Disclaimer & privacy policy';

  @override
  String get legalSub => 'Independent tool · not an official app · offline';

  @override
  String get acceptLegal => 'I understand';

  @override
  String get readFullPolicy => 'Read full policy';

  @override
  String get legalH1 => 'Independent tool';

  @override
  String get legal1 =>
      'PO Sorting is an independent helper tool made for postal staff. It is not an official app of the Department of Posts / India Post, and it is not endorsed by, affiliated with or connected to the Department of Posts, the Ministry of Communications or the Government of India.';

  @override
  String get legalH2 => 'No official branding';

  @override
  String get legal2 =>
      'The app does not use the India Post name, logo, colours or branding. Post office names and PIN codes are used only as public reference data.';

  @override
  String get legalH3 => 'No warranty';

  @override
  String get legal3 =>
      'Sorting data, PIN details and airport codes are provided “as is” for convenience and may be outdated or wrong. Always follow your office\'s official sorting instructions, circulars and DMSL. The developer is not responsible for any mis-sort, delay, loss or other consequence of using this app.';

  @override
  String get legalH4 => 'Your responsibility';

  @override
  String get legal4 =>
      'You are responsible for the data you import, edit or share, and for following your department\'s rules on sharing internal documents.';

  @override
  String get legalH5 => 'Privacy';

  @override
  String get legal5 =>
      'The app works fully offline. It has no internet permission, no login, no ads, no analytics and no tracking. Camera scans are processed on the phone and deleted immediately; nothing is uploaded. Your schemes, favourites and settings stay only on your phone and are removed when you uninstall the app.';

  @override
  String get legalH6 => 'Open data';

  @override
  String get legal6 =>
      'PIN directory: data.gov.in, Government of India, Open Government Data Licence – India. Airport codes are public IATA codes. The default Mangaluru scheme was compiled from lists shared by postal staff and may differ from your office\'s current scheme.';

  @override
  String get legalH7 => 'Changes';

  @override
  String get legal7 =>
      'This policy may be updated with new versions of the app. By using the app you agree to this disclaimer and policy.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get backspace => 'Delete last digit';

  @override
  String get voiceInput => 'Voice input';

  @override
  String get scanAddress => 'Scan address';

  @override
  String get checkPlace => 'PIN vs place check';

  @override
  String get placeOnAddress => 'City / office on the address';

  @override
  String get recentLookups => 'Recent lookups';

  @override
  String get sortHint =>
      'Type a PIN on the keypad. The bag appears as you type.';

  @override
  String get bag => 'Line / Bag';

  @override
  String get bags => 'Lines / Bags';

  @override
  String get section => 'Position';

  @override
  String matchedBy(String type, String key) {
    return 'Matched by $type: $key';
  }

  @override
  String get likelyBag => 'Likely bag (from prefix)';

  @override
  String get possibleBags => 'Possible bags';

  @override
  String sortingDistrictN(String code) {
    return 'Sorting district $code';
  }

  @override
  String get prefixNotInDirectory =>
      'No offices with this prefix in the directory';

  @override
  String get pinNotInDirectory => 'PIN not in directory – check the address';

  @override
  String get invalidPin => 'Invalid PIN (6 digits, first digit 1–9)';

  @override
  String get noBagRule => 'No bag rule for this PIN – check with supervisor';

  @override
  String deliveryOfficesN(int count) {
    return 'Delivery office(s): $count';
  }

  @override
  String andMore(int count) {
    return '…and $count more';
  }

  @override
  String get delivery => 'Delivery';

  @override
  String get nonDelivery => 'Non-delivery';

  @override
  String get typeHO => 'Head Office';

  @override
  String get typeSO => 'Sub Office';

  @override
  String get typeBO => 'Branch Office';

  @override
  String get typePO => 'Post Office';

  @override
  String get pinStructure => 'PIN structure';

  @override
  String get pinZone => 'Postal zone';

  @override
  String get pinCircle => 'Postal circle';

  @override
  String get pinSortingDistrict => 'Sorting district';

  @override
  String get pinSortingDistrictHelp => 'first 3 digits';

  @override
  String get pinDeliveryOffice => 'Delivery post office';

  @override
  String get pinDeliveryOfficeHelp => 'last 3 digits';

  @override
  String get airLabelCode => 'Air label code';

  @override
  String get noAirCode => 'No air code – check with supervisor';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get via => 'Via';

  @override
  String get badgeAir => 'AIR';

  @override
  String get badgeSurface => 'SURFACE';

  @override
  String labelBadge(String text) {
    return 'Label colour: $text';
  }

  @override
  String get labelBadgeShort => 'Label';

  @override
  String get connectivityDefaulted =>
      'Connectivity not given in the rule – assumed Surface. Check with supervisor.';

  @override
  String get connAir => 'Air';

  @override
  String get connSurface => 'Surface';

  @override
  String get hubRoute => 'Parcel hub route';

  @override
  String directToL1(String hub) {
    return 'Direct to L1 hub: $hub';
  }

  @override
  String get noDmsl => 'No DMSL imported for this scheme';

  @override
  String get noHubRoute => 'No hub rule for this PIN in the DMSL';

  @override
  String dmslVersionLabel(String version) {
    return 'DMSL $version';
  }

  @override
  String get labelView => 'Label view';

  @override
  String get shareImage => 'Share as image';

  @override
  String get shareText => 'Share as text';

  @override
  String get listening => 'Listening…';

  @override
  String get sayPin => 'Say the PIN digits';

  @override
  String get voiceUnavailable =>
      'Speech recognition is not available on this phone';

  @override
  String get unresolved => 'Unresolved';

  @override
  String get noSchemeShort => 'No sorting scheme yet';

  @override
  String get importShort => 'Import';

  @override
  String get sampleShort => 'Sample';

  @override
  String get pinHint => 'Type PIN';

  @override
  String get officeNameHint => 'Office / line name';

  @override
  String get switchKeyboard => 'Numbers / letters keyboard';

  @override
  String get noMatchingRules => 'No rule in your scheme starts with this';

  @override
  String get findPinHint => 'Office, village, city, taluk or district';

  @override
  String get findPinTip =>
      'Type in English, ಕನ್ನಡ or हिन्दी. Spelling mistakes are fine: \"Puttoor\", \"Putur\" and \"ಪುತ್ತೂರು\" all find Puttur.';

  @override
  String get allStates => 'All states';

  @override
  String get allDistricts => 'All districts';

  @override
  String get deliveryOnly => 'Delivery offices only';

  @override
  String get noResults => 'No matching office found';

  @override
  String get taluk => 'Taluk';

  @override
  String get division => 'Division';

  @override
  String get sortThisPin => 'Sort this PIN';

  @override
  String get copyPin => 'Copy PIN';

  @override
  String get addFavourite => 'Add to favourites';

  @override
  String get removeFavourite => 'Remove from favourites';

  @override
  String get noFavourites => 'No favourites yet. Add offices from Find PIN.';

  @override
  String get mismatchChecker => 'PIN ↔ place check';

  @override
  String get mismatchCheckerSub => 'Catch wrong PINs before missorting';

  @override
  String get mmMatch => '✅ Place matches this PIN';

  @override
  String get mmSameDistrict => '⚠️ Same district, but a different PIN';

  @override
  String get mmDifferent =>
      '❌ Place is in a different district/state – likely wrong PIN';

  @override
  String get mmUnknownPlace =>
      'Place not found in the directory – check spelling';

  @override
  String mmPinIs(String pin, String office) {
    return 'PIN $pin is $office';
  }

  @override
  String mmPlaceIs(String place, String district) {
    return '\"$place\" is in $district';
  }

  @override
  String get suggestedPins => 'Suggested PINs:';

  @override
  String get scanHint =>
      'Point at the address (with the PIN) and tap capture. Nothing is saved.';

  @override
  String get capture => 'Capture';

  @override
  String get torch => 'Torch';

  @override
  String cameraUnavailable(String error) {
    return 'Camera not available: $error';
  }

  @override
  String get noPinDetected =>
      'No PIN found in the text – type it or search the place';

  @override
  String get detectedPin => 'Detected PIN (edit if wrong)';

  @override
  String get detectedPlace => 'Detected city / office';

  @override
  String get useThisPin => 'Use this PIN';

  @override
  String get addToBulk => 'Add to bulk count';

  @override
  String get scanAgain => 'Scan again';

  @override
  String get scanPrivacy =>
      'Text is read on the phone with ML Kit (English / Latin script). The photo is deleted right after reading. For Kannada or Hindi addresses the PIN digits are used and you can search the place by hand.';

  @override
  String get noOpenSession =>
      'No bulk session in progress – start one in the Bulk tab';

  @override
  String addedToBulk(String bag) {
    return 'Added: $bag';
  }

  @override
  String get bulkTitle => 'Bulk sorting';

  @override
  String get bulkEmpty =>
      'Count articles bag-wise: start a session, enter PINs quickly, then share the tally.';

  @override
  String get startSession => 'Start session';

  @override
  String get sessionName => 'Session name';

  @override
  String sessionDefaultName(String time) {
    return 'Session $time';
  }

  @override
  String get scheme => 'Scheme';

  @override
  String get inProgress => 'in progress';

  @override
  String get undoLast => 'Undo last';

  @override
  String get endSession => 'End';

  @override
  String unresolvedEntries(int count) {
    return 'Unresolved / invalid: $count (tap to fix)';
  }

  @override
  String fixEntry(String raw) {
    return 'Fix \"$raw\"';
  }

  @override
  String get shareCsv => 'Share CSV';

  @override
  String get sharePrintable => 'Share printable text file';

  @override
  String get continueSession => 'Continue counting';

  @override
  String get learnNeedsScheme =>
      'Practice uses the active scheme. Import your office scheme, or try the sample.';

  @override
  String get learnFromScheme => 'Questions come from this scheme';

  @override
  String get flashcards => 'Bag flashcards';

  @override
  String get flashcardsSub => 'PIN → which bag? Spaced repetition';

  @override
  String get timedQuiz => 'Timed sorting quiz';

  @override
  String get timedQuizSub => '20 articles, 4 choices, score and speed';

  @override
  String get airFlashcards => 'Air code flashcards';

  @override
  String get airFlashcardsSub => 'PIN / district → air code';

  @override
  String get airQuiz => 'Air code quiz';

  @override
  String get airQuizSub => 'Needs an imported air code sheet';

  @override
  String get hubFlashcards => 'Parcel hub flashcards';

  @override
  String get hubFlashcardsSub => 'PIN → L2 / L1 hub from the active DMSL';

  @override
  String get weakAreas => 'Weak areas';

  @override
  String get weakAreasSub => 'Bags and PIN series you get wrong most';

  @override
  String get pinBasics => 'PIN basics';

  @override
  String get pinBasicsSub => 'Zone, circle, sorting district, delivery office';

  @override
  String get noCards =>
      'No cards: the scheme has no rules for this practice yet.';

  @override
  String flashDone(int known, int unknown) {
    return 'Round done! Knew: $known, didn\'t know: $unknown';
  }

  @override
  String leitnerBox(int box) {
    return 'Box $box of 5';
  }

  @override
  String get qWhichBagPin => 'Which bag for PIN';

  @override
  String get qWhichBagPlace => 'Which bag for';

  @override
  String get qWhichAirCode => 'Which air code for';

  @override
  String get qWhichHub => 'Which parcel hub route for PIN';

  @override
  String get answer => 'Answer';

  @override
  String get tapToFlip => 'Tap the card to flip';

  @override
  String get showAnswer => 'Show answer';

  @override
  String get knewIt => 'I knew it';

  @override
  String get didntKnow => 'Didn\'t know';

  @override
  String scoreN(int score) {
    return 'Score $score';
  }

  @override
  String quizScore(int score, int total) {
    return '$score / $total';
  }

  @override
  String quizStats(int seconds, String apm) {
    return '$seconds s · $apm articles per minute';
  }

  @override
  String get history => 'Score history';

  @override
  String get historyNeedsMore => 'Take one more quiz to see a chart';

  @override
  String get noWeakAreas => 'No mistakes recorded yet – practise first.';

  @override
  String get weakBags => 'Bags most often wrong';

  @override
  String get weakPrefixes => 'PIN series most often wrong';

  @override
  String wrongTimes(int count) {
    return 'Wrong $count times';
  }

  @override
  String quizzesTaken(int count) {
    return 'Quizzes taken: $count';
  }

  @override
  String averageScore(int percent) {
    return 'Average score: $percent%';
  }

  @override
  String get resetProgress => 'Reset progress';

  @override
  String get resetProgressConfirm =>
      'Delete quiz history, mistakes and flashcard boxes?';

  @override
  String get pinBasicsIntro =>
      'A PIN (Postal Index Number) has 6 digits. Each part narrows down where the article goes:';

  @override
  String get pinBasicsDigits =>
      'Digit 1 = postal zone/region. Digits 1–2 = postal circle. Digits 1–3 = sorting district (the sorting office handling the mail). Last 3 digits = the delivery post office. Example 574201: 5 = Southern zone, 57 = Karnataka, 574 = sorting district, 201 = delivery office.';

  @override
  String get pinZones => 'Zones (first digit)';

  @override
  String get circleTable => 'Circles (first two digits)';

  @override
  String get pinBasicsNote =>
      'Circle boundaries are approximate; some small circles share digits with neighbours (see the list above). Always follow your office\'s sorting scheme.';

  @override
  String get noSchemes =>
      'No schemes yet. Import your office\'s sorting scheme (Excel/CSV), create one, or try the SAMPLE.';

  @override
  String get schemesPrivacy =>
      'Schemes are department documents: they stay on this phone. Share only with your team.';

  @override
  String get importScheme => 'Import scheme';

  @override
  String get importSchemeSub => 'Excel (.xlsx) or CSV';

  @override
  String get importAirCodes => 'Import air code sheet';

  @override
  String get importDmsl => 'Import DMSL (parcel hubs)';

  @override
  String get createManually => 'Create scheme in the app';

  @override
  String get installSample => 'Add SAMPLE scheme (not real)';

  @override
  String get downloadTemplate => 'Download template';

  @override
  String get downloadSampleFile => 'Save SAMPLE scheme file';

  @override
  String get templateSaved => 'Saved';

  @override
  String get newScheme => 'New scheme';

  @override
  String get schemeName => 'Scheme name';

  @override
  String get officeName => 'Office';

  @override
  String get setActive => 'Set as active';

  @override
  String get exportXlsx => 'Export / share as Excel';

  @override
  String get exportCsv => 'Export / share as CSV';

  @override
  String get rules => 'Rules';

  @override
  String get airCodes => 'Air codes';

  @override
  String rulesCount(int count) {
    return '$count rules';
  }

  @override
  String get filterRules => 'Filter rules';

  @override
  String get addRule => 'Add rule';

  @override
  String get editRule => 'Edit rule';

  @override
  String get addBag => 'Add bag';

  @override
  String get editBag => 'Edit bag';

  @override
  String deleteBagConfirm(String code) {
    return 'Delete bag $code and all its rules?';
  }

  @override
  String get invalidRuleKey =>
      'Check the PIN / range / prefix / name for this rule type';

  @override
  String get allCategories => 'All categories';

  @override
  String get noAirCodes =>
      'No air codes. Import your office\'s air code sheet (Air Parcel mode shows the code in big letters).';

  @override
  String get dmslHelp =>
      'The Due Mail Sorting List maps PINs to L2 → L1 parcel hubs. Hub lists change (e.g. 7 Oct 2026 rationalisation), so import each new version; tap a version to make it active.';

  @override
  String validFromDate(String date) {
    return 'valid from $date';
  }

  @override
  String get compareWithPrevious => 'Changes vs previous version';

  @override
  String get dmslChanges => 'DMSL changes';

  @override
  String dmslCompare(String from, String to) {
    return '$from → $to';
  }

  @override
  String dmslChangedCount(int count) {
    return '$count PINs changed hub';
  }

  @override
  String get dmslNoChanges => 'No PIN changed hub between these versions.';

  @override
  String get practiseChanged => 'Practise only the changed PINs';

  @override
  String get dmslVersionName => 'Version name';

  @override
  String get validFrom => 'Valid from';

  @override
  String get stepFile => 'File';

  @override
  String get stepPreview => 'Preview';

  @override
  String get stepMapping => 'Columns';

  @override
  String get stepReport => 'Check & save';

  @override
  String get chooseFile => 'Choose Excel / CSV file';

  @override
  String get importSchemeHelp =>
      'One row per rule. Columns (any order, English/Kannada/Hindi headers): PIN, PIN From, PIN To, Prefix, Office, District, State, Bag No, Bag Name, Section, Remarks, Category, Connectivity (Air/Surface), Colour. A row with no PIN/office/district is the \"All other\" (default) bag.';

  @override
  String get importAirHelp =>
      'Columns: PIN, PIN From, PIN To, Prefix, District, State, Air Code, Station, Via, Remarks. Codes are checked against the airport list; unknown codes are kept with a warning.';

  @override
  String get importDmslHelp =>
      'Columns: PIN / PIN From / PIN To / Prefix / Office, L2 Hub, L1 Hub, Direct closure (Y/N), Connectivity (Air/Surface), Remarks. After import you see which PINs changed hub.';

  @override
  String get importPrivacy => 'The file is read on the phone only.';

  @override
  String get headerRow => 'Header row';

  @override
  String previewRows(int shown, int total) {
    return 'Showing $shown of $total rows';
  }

  @override
  String get mappingHelp =>
      'Check which column holds each field. Auto-detected from the headers; change if wrong.';

  @override
  String get notMapped => '— not in file —';

  @override
  String reportRulesOk(int count) {
    return '$count rules ready';
  }

  @override
  String reportSummary(int errors, int warnings) {
    return '$errors rows skipped · $warnings warnings';
  }

  @override
  String bagsFound(int count) {
    return '$count bags found';
  }

  @override
  String get airReplaceNote =>
      'Saving replaces this scheme\'s current air code table.';

  @override
  String rowN(int row) {
    return 'Row $row';
  }

  @override
  String saveRules(int count) {
    return 'Save $count';
  }

  @override
  String importSaved(int count) {
    return 'Imported $count rules';
  }

  @override
  String get issueBadPin => 'Bad PIN / range / prefix';

  @override
  String get issueNoBag => 'Row has no bag / code / hub';

  @override
  String get issueNoMatch => 'No PIN / office / district';

  @override
  String get issueDuplicate => 'Duplicate rules';

  @override
  String get issueConflict => 'Conflicting rules (same key, different result)';

  @override
  String get issueOverlap => 'Overlapping PIN ranges';

  @override
  String get issueNested => 'Nested ranges (smaller wins)';

  @override
  String get issueUnknownAir => 'Air codes not in airport list (kept)';

  @override
  String get issueNoConnectivity => 'Connectivity blank (Surface assumed)';

  @override
  String get issueDefault => 'Rows treated as \"All other\"';

  @override
  String get issueBadColour => 'Unknown colours';

  @override
  String get ruleExact => 'Exact PIN';

  @override
  String get ruleRange => 'PIN range';

  @override
  String get rulePrefix => 'Prefix';

  @override
  String get ruleOffice => 'Office name';

  @override
  String get ruleDistrict => 'District';

  @override
  String get ruleState => 'State';

  @override
  String get ruleDefault => 'All other (default)';

  @override
  String get fType => 'Rule type';

  @override
  String get fPin => 'PIN';

  @override
  String get fPinFrom => 'PIN from';

  @override
  String get fPinTo => 'PIN to';

  @override
  String get fPrefix => 'Prefix (first 1–5 digits)';

  @override
  String get fOffice => 'Office';

  @override
  String get fDistrict => 'District';

  @override
  String get fState => 'State';

  @override
  String get fBagCode => 'Line / bag (e.g. Puttur Line, BANGALORE)';

  @override
  String get fBagName => 'Extra name (e.g. state)';

  @override
  String get fSection => 'Position / section no.';

  @override
  String get fRemarks => 'Remarks';

  @override
  String get fCategory => 'Mail category';

  @override
  String get fConnectivity => 'Connectivity (Air/Surface)';

  @override
  String get fColour => 'Bag colour';

  @override
  String get fAirCode => 'Air code';

  @override
  String get fStation => 'Air station';

  @override
  String get fVia => 'Via hub';

  @override
  String get fL2Hub => 'L2 hub';

  @override
  String get fL1Hub => 'L1 hub';

  @override
  String get fDirect => 'Direct closure (Y/N)';

  @override
  String get changeBagHere => 'Change line / bag for this PIN';

  @override
  String editRuleX(String rule) {
    return 'Edit rule: $rule';
  }

  @override
  String get savedSortingUpdated => 'Saved – sorting updated';

  @override
  String get moveRules => 'Move rules to another line / bag';

  @override
  String moveRulesTitle(int count, String bag) {
    return 'Move $count rules from $bag';
  }

  @override
  String get moveTo => 'New bag / line';

  @override
  String get removeOldBag => 'Remove the empty old bag';

  @override
  String rulesMoved(int count, String bag) {
    return '$count rules moved to $bag';
  }

  @override
  String get move => 'Move';

  @override
  String get dirSource => 'Source';

  @override
  String get dirRows => 'Offices';

  @override
  String get dirFileDate => 'Data file date';

  @override
  String get dirBuilt => 'Built on';

  @override
  String get dirStateFilter => 'State filter';

  @override
  String get dirSearchIndex => 'Search index';

  @override
  String get dirPlaceholderWarning =>
      'This is only a small test directory. Import the full \"All India Pincode Directory\" CSV from data.gov.in below.';

  @override
  String get dirUpdateHelp =>
      'Download the newer \"All India Pincode Directory\" CSV from data.gov.in on any computer or phone, copy it to this phone, then import it here. Leave the state empty for all of India.';

  @override
  String get dirStateOnly => 'Only this state (optional)';

  @override
  String get updateDirectory => 'Update PIN directory from CSV';

  @override
  String get dirParsing => 'Reading and cleaning the CSV…';

  @override
  String get dirWriting => 'Building the offline database…';

  @override
  String directoryUpdated(int count) {
    return 'Directory updated: $count offices';
  }

  @override
  String get help1Title => 'Import your scheme';

  @override
  String get help1 =>
      'More → Sorting schemes → Add. Pick your office\'s Excel/CSV, check the columns and save. No file yet? Download the template, or try the SAMPLE scheme (fake data).';

  @override
  String get help2Title => 'Sort by PIN';

  @override
  String get help2 =>
      'Type the PIN on the big keypad. After 3 digits you see the sorting district and likely bag; after 6 digits the final bag in its colour. Typing the next digit starts a new PIN. Long-press ⌫ to clear.';

  @override
  String get help3Title => 'TD and Non-TD';

  @override
  String get help3 =>
      'Choose TD or Non-TD at the top of the Sort screen. Each rule in your scheme can be marked TD or Non-TD in the Category column (blank = both). If a PIN only has a rule in the other mode, the app tells you which mode and bag.';

  @override
  String get help4Title => 'No PIN on the article?';

  @override
  String get help4 =>
      'Find PIN: type the office, village, city, taluk or district in English, Kannada or Hindi. Spelling mistakes are tolerated. Each result shows its bag.';

  @override
  String get help5Title => 'Catch wrong PINs';

  @override
  String get help5 =>
      'Turn on the place check (✓ icon on Sort) and type the city written on the article. ✅ match, ⚠️ same district but different PIN, ❌ different district/state – with suggested PINs.';

  @override
  String get help6Title => 'Scan the address';

  @override
  String get help6 =>
      'Tap the scan icon, point the camera at the address and capture. The PIN and city are read on the phone; the photo is deleted immediately.';

  @override
  String get help7Title => 'Count articles per bag';

  @override
  String get help7 =>
      'Bulk → Start session. Enter PINs one after another; each one flashes its bag colour and adds to the count. Undo the last entry, fix unresolved ones, then share the summary to tally with the manifest.';

  @override
  String get help8Title => 'Practise';

  @override
  String get help8 =>
      'Learn: flashcards with spaced repetition, a timed 20-article quiz, weak areas, and a PIN basics lesson. After a new DMSL, practise only the PINs whose hub changed.';

  @override
  String get help9Title => 'Sorting changed? Edit it';

  @override
  String get help9 =>
      'On the Sort screen tap “Change bag for this PIN” to fix one PIN. For bigger changes open More → Schemes → your scheme: edit, add or delete rules, and in Bags use “Move rules to another bag” when an office moves to a new line. Export the scheme to share it with colleagues.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Beat Mitra';

  @override
  String get appTagline => 'Your helper for the delivery beat';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get next => 'Next';

  @override
  String get iUnderstand => 'I understand';

  @override
  String get disclaimer =>
      'Independent helper tool for postmen. Not an official Department of Posts app. Follow your office\'s rules on customer information.';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacyOnDevice => 'Names and addresses stay only on this phone.';

  @override
  String get privacyEncrypted => 'All data and photos are encrypted and protected by your PIN.';

  @override
  String get privacyNoCloud => 'No internet, no cloud, no login, no ads.';

  @override
  String get privacyNoAnalytics => 'No analytics or crash reporting.';

  @override
  String get privacyMap => 'The optional online map is OFF by default and only loads map pictures from OpenStreetMap.';

  @override
  String get privacyBackupAdvice => 'Data is only on this phone: make an encrypted backup every week.';

  @override
  String get freeTools => 'Built only with free and open tools. Works fully offline.';

  @override
  String get createPin => 'Create a 4-digit PIN';

  @override
  String get confirmPin => 'Enter the PIN again';

  @override
  String get pinMismatch => 'PINs did not match. Try again.';

  @override
  String get enterPin => 'Enter PIN';

  @override
  String get enterOldPin => 'Enter current PIN';

  @override
  String get wrongPin => 'Wrong PIN';

  @override
  String get tooManyTries => 'Too many tries. Wait 30 seconds.';

  @override
  String get useFingerprint => 'Unlock with fingerprint / face';

  @override
  String get unlockReason => 'Unlock Beat Mitra';

  @override
  String get biometricUnavailable => 'Not available on this phone';

  @override
  String get pinChanged => 'PIN changed';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get done => 'Done';

  @override
  String get clear => 'Clear';

  @override
  String get select => 'Select';

  @override
  String get share => 'Share';

  @override
  String get title => 'Title';

  @override
  String get note => 'Note';

  @override
  String get notes => 'Notes';

  @override
  String get noteOptional => 'Note (optional)';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get voiceInput => 'Speak';

  @override
  String get voiceStop => 'Stop listening';

  @override
  String get voiceNotHeard => 'Could not hear. Try again or type.';

  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get switchBeat => 'Switch beat';

  @override
  String get noBeatYet => 'No beat yet. Create your beat to start.';

  @override
  String get createBeat => 'Create beat';

  @override
  String get editBeat => 'Edit beat';

  @override
  String get deleteBeat => 'Delete beat';

  @override
  String deleteBeatConfirm(int count) {
    return 'Delete this beat with its $count places, streets and photos?';
  }

  @override
  String get beats => 'Beats';

  @override
  String get beatName => 'Beat name';

  @override
  String get beatNameHint => 'e.g. Beat 7 / Relief beat 3';

  @override
  String get office => 'Post office';

  @override
  String get addHere => 'Add here';

  @override
  String get searchHint => 'Name, door no., street, landmark, PIN…';

  @override
  String get search => 'Search';

  @override
  String get todaysArticles => 'Today\'s articles';

  @override
  String pendingDoneCount(int pending, int done) {
    return '$pending to deliver · $done done';
  }

  @override
  String get routeAndRun => 'Route & delivery';

  @override
  String get nearby => 'Nearby places';

  @override
  String get daySummary => 'Day summary';

  @override
  String get beatAndStreets => 'Beat & streets';

  @override
  String get learnBeat => 'Learn the beat';

  @override
  String get handoverBackup => 'Handover & backup';

  @override
  String get map => 'Map';

  @override
  String get backupReminder => 'No backup in the last 7 days. Your data is only on this phone — back up now.';

  @override
  String get streets => 'Streets';

  @override
  String get streetsHelp => 'Drag ≡ to put streets in your usual walking order.';

  @override
  String get noStreets => 'No streets yet. Add the streets of your beat.';

  @override
  String get addStreet => 'Add street';

  @override
  String get editStreet => 'Edit street';

  @override
  String get deleteStreet => 'Delete street';

  @override
  String get deleteStreetConfirm => 'Delete this street? Its places stay, without a street.';

  @override
  String get streetName => 'Street name';

  @override
  String get streetNameHint => 'e.g. 4th Cross, 2nd Main, HAL 2nd Stage';

  @override
  String get area => 'Area';

  @override
  String get crossMainNote => 'Cross / main note';

  @override
  String placesCount(int count) {
    return 'Places: $count';
  }

  @override
  String get noPlaces => 'No places yet. Walk your beat and tap “Add here” at each door.';

  @override
  String get noStreet => 'No street';

  @override
  String get areaNotes => 'Area notes';

  @override
  String get areaNote => 'Area note';

  @override
  String get areaNoteHint => 'e.g. cross numbers increase towards the lake';

  @override
  String get addAreaNote => 'Add area note';

  @override
  String get noAreaNotes => 'Write how numbering works here, short cuts, timings…';

  @override
  String get addPlace => 'Add place';

  @override
  String get editPlace => 'Edit place';

  @override
  String get deletePlace => 'Delete place';

  @override
  String get deletePlaceConfirm => 'Delete this place, its names and photos?';

  @override
  String get placeDeleted => 'This place was deleted.';

  @override
  String get placeNeedsSomething => 'Enter a door no., building, name or landmark.';

  @override
  String get doorNo => 'Door no.';

  @override
  String get pickStreet => 'Choose street';

  @override
  String get searchStreet => 'Search street';

  @override
  String get newStreet => 'New street';

  @override
  String newStreetNamed(String name) {
    return 'New street “$name”';
  }

  @override
  String get addressees => 'Names at this place';

  @override
  String get addressee => 'Addressee';

  @override
  String get addName => 'Add name';

  @override
  String get name => 'Name';

  @override
  String get aliases => 'Other spellings / names';

  @override
  String get aliasesHelp => 'Separate with commas';

  @override
  String get phoneOptional => 'Phone (optional)';

  @override
  String get noteFlat => 'Note (flat, floor…)';

  @override
  String get landmark => 'Landmark';

  @override
  String get building => 'Building';

  @override
  String get floorFlat => 'Floor / flat';

  @override
  String get notesHint => 'Notes: dog, gate, floor, timing';

  @override
  String get quickDog => 'Dog';

  @override
  String get quickGate => 'Gate locked';

  @override
  String get quickUpstairs => 'Upstairs';

  @override
  String get quickMorning => 'Morning only';

  @override
  String get quickEvening => 'Evening only';

  @override
  String get deliveryPref => 'Delivery preference';

  @override
  String get prefSecurity => 'Leave with security';

  @override
  String get prefNeighbour => 'Leave with neighbour';

  @override
  String get prefLetterBox => 'Letter box';

  @override
  String get prefShop => 'Shop below';

  @override
  String get pin => 'PIN code';

  @override
  String get placeHouse => 'House';

  @override
  String get placeShop => 'Shop';

  @override
  String get placeOffice => 'Office';

  @override
  String get placeApartment => 'Apartment';

  @override
  String get placeOther => 'Other';

  @override
  String get maxPhotos => 'Up to 3 photos per place';

  @override
  String photoCount(int count) {
    return 'Photo $count/3';
  }

  @override
  String get cameraError => 'Camera not available';

  @override
  String get possibleDuplicates => 'Already saved close by — same place?';

  @override
  String get openIt => 'Open';

  @override
  String get gpsOff => 'Location is off. Turn it on.';

  @override
  String get gpsDenied => 'Location permission is needed.';

  @override
  String get openSettings => 'Settings';

  @override
  String get gpsWaiting => 'Getting GPS…';

  @override
  String gpsAccuracy(int acc, int want) {
    return 'GPS accuracy $acc m (want ≤ $want m)';
  }

  @override
  String gpsAccuracyShort(int acc) {
    return '± $acc m';
  }

  @override
  String get gpsUseNow => 'Use this location';

  @override
  String gpsSaved(int acc) {
    return 'Location saved (± $acc m)';
  }

  @override
  String get gpsRetake => 'Again';

  @override
  String get gpsNotSet => 'No location saved';

  @override
  String get gpsCapture => 'Get GPS';

  @override
  String get updateGpsHere => 'Move pin to my current location';

  @override
  String updateGpsConfirm(int acc) {
    return 'Save your current location (± $acc m) for this place?';
  }

  @override
  String get mergeDuplicate => 'Merge a duplicate';

  @override
  String get pickDuplicate => 'Pick the duplicate';

  @override
  String get mergeIntoThis => 'Merge into this place';

  @override
  String get mergeConfirm => 'Names, photos and articles of the duplicate move here, then it is deleted.';

  @override
  String get merged => 'Merged';

  @override
  String get navigate => 'Navigate';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get call => 'Call';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get searchTips =>
      'Type or speak a name, door no. (12/3), street, landmark or PIN. Kannada, Hindi and English spellings all work.';

  @override
  String get noResults => 'Nothing found. Try fewer letters or the door no.';

  @override
  String get allBeats => 'All beats';

  @override
  String get placeHasNoGps => 'This place has no GPS location yet. Edit it at the door to add one.';

  @override
  String get arrived => 'You are here';

  @override
  String get noCompass => 'No compass: arrow shows direction when walking.';

  @override
  String get noNearby => 'No saved places near you.';

  @override
  String get scanBarcode => 'Scan barcode';

  @override
  String get scanAddress => 'Scan address';

  @override
  String get typeIn => 'Type';

  @override
  String get torch => 'Torch';

  @override
  String scannedCount(int count) {
    return 'Scanned: $count';
  }

  @override
  String addedCount(int count) {
    return 'Added $count articles';
  }

  @override
  String get articleValid => 'Valid article number';

  @override
  String get articleBadCheck => 'Check digit does not match — please check the number';

  @override
  String get articleOtherFormat => 'Other format (allowed)';

  @override
  String get articleInvalid => 'Too short / not valid';

  @override
  String get articleNo => 'Article number';

  @override
  String get articleNoOptional => 'Optional for ordinary letters';

  @override
  String get addArticle => 'Add article';

  @override
  String get editArticle => 'Article';

  @override
  String get deleteArticle => 'Delete article';

  @override
  String get deleteArticleConfirm => 'Delete this article from today\'s list?';

  @override
  String get duplicateArticle => 'Already added';

  @override
  String duplicateArticleBody(String number) {
    return '$number is already in today\'s list. Add again?';
  }

  @override
  String get typeLetter => 'Letter';

  @override
  String get typeRegistered => 'Registered';

  @override
  String get typeSpeedPost => 'Speed Post';

  @override
  String get typeParcel => 'Parcel';

  @override
  String get typeMoneyOrder => 'Money order';

  @override
  String get typeOther => 'Other';

  @override
  String get type => 'Type';

  @override
  String get needsSignature => 'Needs signature / OTP';

  @override
  String get addressText => 'Address (as written)';

  @override
  String get findMatch => 'Find match';

  @override
  String get place => 'Place';

  @override
  String get suggestions => 'Suggestions — tap the right one';

  @override
  String get thisOne => 'This one';

  @override
  String get noMatchFound => 'No saved place matches. Search or add a new place.';

  @override
  String get searchPlace => 'Search place';

  @override
  String get addNewPlace => 'Add new place';

  @override
  String get pickPlace => 'Pick the place';

  @override
  String get unlink => 'Unlink';

  @override
  String get ocrFailed => 'Could not read the text';

  @override
  String get ocrNothing => 'No text found. Hold the camera closer, in good light.';

  @override
  String carryPrompt(int count) {
    return '$count re-attempts from the last day';
  }

  @override
  String carriedCount(int count) {
    return '$count re-attempts added';
  }

  @override
  String todayCounts(int total, int pending, int unmatched) {
    return '$total articles · $pending pending · $unmatched unmatched';
  }

  @override
  String get noArticlesToday => 'No articles yet. Scan barcodes or addresses, or type them in.';

  @override
  String get unmatched => 'Unmatched — link to a place';

  @override
  String get matched => 'Matched';

  @override
  String get planRoute => 'Plan route';

  @override
  String get reattempt => 'Re-attempt';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusNotDelivered => 'Not delivered';

  @override
  String get routePlan => 'Route plan';

  @override
  String get modeShortest => 'Shortest';

  @override
  String get modeStreet => 'Street order';

  @override
  String routeSummary(int stops, String distance) {
    return '$stops stops · about $distance';
  }

  @override
  String startFrom(String where) {
    return 'Start: $where';
  }

  @override
  String get startUnknown => 'Start point unknown (no GPS)';

  @override
  String get startOffice => 'Post office';

  @override
  String get startCurrent => 'My current location';

  @override
  String unmatchedNotInRoute(int count) {
    return '$count unmatched articles are not in the route';
  }

  @override
  String get replan => 'Plan again';

  @override
  String allUnmatched(int count) {
    return '$count articles are not linked to places yet. Link them in Today\'s articles.';
  }

  @override
  String get nothingToDeliver => 'Nothing pending to deliver today.';

  @override
  String articlesCount(int count) {
    return '$count articles';
  }

  @override
  String get noGps => 'no GPS';

  @override
  String get startRun => 'Start delivery';

  @override
  String get run => 'Delivery';

  @override
  String stopsDone(int done, int total) {
    return '$done of $total stops';
  }

  @override
  String get nextStop => 'NEXT STOP';

  @override
  String get delivered => 'Delivered';

  @override
  String get notDelivered => 'Not delivered';

  @override
  String get skip => 'Skip';

  @override
  String get whyNotDelivered => 'Why not delivered?';

  @override
  String get reasonDoorLocked => 'Door locked';

  @override
  String get reasonAbsent => 'Addressee not available';

  @override
  String get reasonLeft => 'Left / shifted';

  @override
  String get reasonRefused => 'Refused';

  @override
  String get reasonWrongAddress => 'Wrong / insufficient address';

  @override
  String get reasonUnclaimed => 'Unclaimed';

  @override
  String get reasonOther => 'Other';

  @override
  String get runFinished => 'All stops done. Well done!';

  @override
  String ttsNext(String where) {
    return 'Next: number $where';
  }

  @override
  String get history => 'History';

  @override
  String get noArticlesThatDay => 'No articles on this day.';

  @override
  String get notDeliveredList => 'Not delivered';

  @override
  String carryToTomorrow(int count) {
    return 'Carry $count re-attempts to next day';
  }

  @override
  String summaryTotals(int total, int delivered, int notDelivered, int pending) {
    return 'Total $total: delivered $delivered, not delivered $notDelivered, pending $pending';
  }

  @override
  String summaryTypeLine(String type, int delivered, int total) {
    return '$type: $delivered/$total delivered';
  }

  @override
  String distanceLine(String planned, String recorded) {
    return 'Planned route $planned · recorded $recorded';
  }

  @override
  String learnedPercent(int percent) {
    return '$percent% of places learned';
  }

  @override
  String learnedOf(int learned, int total) {
    return '$learned of $total places';
  }

  @override
  String get weakStreets => 'Streets to practise';

  @override
  String get quizPhoto => 'Photo → place';

  @override
  String get quizPhotoSub => 'See the house photo, pick the door no. and street';

  @override
  String get quizName => 'Name → door no.';

  @override
  String get quizNameSub => 'Where does this person live?';

  @override
  String get quizDoor => 'Door no. → landmark';

  @override
  String get quizDoorSub => 'What landmark is near this door?';

  @override
  String get walkMode => 'Walk mode';

  @override
  String get walkModeSub => 'Walk the beat; the app quizzes you about the nearest house';

  @override
  String get resetProgress => 'Reset learning progress';

  @override
  String get resetProgressConfirm => 'Start learning this beat from zero?';

  @override
  String get qWhichPlace => 'Which place is this?';

  @override
  String qWhereLives(String name) {
    return 'Where does $name get mail?';
  }

  @override
  String qLandmarkOf(String place) {
    return 'Landmark near $place?';
  }

  @override
  String get qWhoLivesHere => 'Who gets mail here?';

  @override
  String get correct => 'Correct!';

  @override
  String wrongAnswer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String scoreLine(int right, int total) {
    return 'Score $right/$total';
  }

  @override
  String get notEnoughForQuiz => 'Add more places (with photos, names, landmarks) to practise.';

  @override
  String nearestPlace(String distance) {
    return 'Nearest saved place · $distance';
  }

  @override
  String get walkHint => 'Walk closer (within 40 m) to a house you have not answered yet.';

  @override
  String get handover => 'Handover to a relief postman';

  @override
  String get handoverHelp =>
      'Export a beat as a password-protected encrypted file and share it. Tell the password separately (by phone, not in the same message).';

  @override
  String get handoverExport => 'Export beat';

  @override
  String get handoverShareText => 'Beat Mitra beat file. Open it in Beat Mitra → Handover & backup → Import.';

  @override
  String get chooseBeats => 'Beats to include';

  @override
  String get includePhones => 'Include phone numbers';

  @override
  String get createAndShare => 'Create & share';

  @override
  String get password => 'Password';

  @override
  String get passwordAgain => 'Password again';

  @override
  String get passwordHelp => 'At least 6 characters. Without it the file cannot be opened.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get importBeat => 'Import a beat file';

  @override
  String get enterFilePassword => 'Password of the file';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get notBeatMitraFile => 'This is not a Beat Mitra file';

  @override
  String importDone(int beats, int places, int photos) {
    return 'Imported $beats beats, $places places, $photos photos';
  }

  @override
  String get thisIsHandover => 'This is a beat file: its beats are added to yours.';

  @override
  String get fullBackup => 'Full backup';

  @override
  String get fullBackupHelp =>
      'Everything (beats, places, photos, history) in one encrypted file. Save it to a pen drive, SD card or computer.';

  @override
  String get backupAdvice => 'Data lives only on this phone. If the phone is lost, only a backup can bring it back.';

  @override
  String get neverBackedUp => 'Never backed up';

  @override
  String lastBackup(String when) {
    return 'Last backup: $when';
  }

  @override
  String get backupNow => 'Back up now';

  @override
  String get chooseLocation => 'Choose where to save';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String get restoreBackup => 'Restore a backup';

  @override
  String get restore => 'Restore';

  @override
  String get restoreConfirm => 'All current data on this phone will be replaced by the backup. Continue?';

  @override
  String get display => 'Display';

  @override
  String get language => 'Language';

  @override
  String get deviceLanguage => 'Phone language';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sunlightMode => 'Sunlight mode';

  @override
  String get sunlightModeSub => 'Extra contrast for bright sun';

  @override
  String get textSize => 'Text size';

  @override
  String get textNormal => 'Normal';

  @override
  String get textLarge => 'Large';

  @override
  String get textXL => 'Extra large';

  @override
  String get security => 'Security';

  @override
  String get changePin => 'Change PIN';

  @override
  String get autoLock => 'Auto-lock';

  @override
  String get lockImmediately => 'Immediately';

  @override
  String lockAfterMin(int minutes) {
    return 'After $minutes min';
  }

  @override
  String get blockScreenshots => 'Block screenshots';

  @override
  String get blockScreenshotsSub => 'Also hides the app in recent apps';

  @override
  String get gpsAndRoute => 'GPS & route';

  @override
  String get gpsThreshold => 'GPS accuracy needed';

  @override
  String get startPoint => 'Route start point';

  @override
  String get setOfficeHere => 'Post office = where I am now';

  @override
  String get vibrateNear => 'Vibrate within 20 m of the place';

  @override
  String get ttsSetting => 'Read out next stop';

  @override
  String get ttsSettingSub => 'Uses the phone\'s text-to-speech';

  @override
  String get dataSection => 'Data';

  @override
  String get historyRetention => 'Keep delivery history';

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String oldDeleted(int count) {
    return '$count old articles deleted';
  }

  @override
  String get onlineMap => 'Online map (OpenStreetMap)';

  @override
  String get onlineMapSub => 'Off by default. Needs internet only for map pictures.';

  @override
  String get onlineMapConfirm =>
      'The map downloads map pictures from OpenStreetMap while you look at it. Your names and addresses are never sent. Turn on?';

  @override
  String get mapNotInBuild =>
      'This is the offline build (no internet permission). Install the “map” build to use the online map.';

  @override
  String get deleteAll => 'Delete all data';

  @override
  String get deleteAllConfirm1 =>
      'This deletes all beats, places, photos, names and history from this phone. It cannot be undone. Make a backup first.';

  @override
  String get deleteAllConfirm2 => 'Type DELETE to confirm';

  @override
  String get notDeleted => 'Nothing was deleted';

  @override
  String get helpAndAbout => 'Help & about';

  @override
  String get licences => 'Open-source licences';

  @override
  String get help1Title => 'Create your beat and streets';

  @override
  String get help1Body => 'Add each street and drag them into the order you usually walk.';

  @override
  String get help2Title => '“Add here” at each door';

  @override
  String get help2Body =>
      'GPS is saved, take 1–3 photos, then the door no., street, names (speak them) and notes like “dog”.';

  @override
  String get help3Title => 'Search anything';

  @override
  String get help3Body => 'Type or speak a name, door no., street or landmark. Small spelling mistakes are fine.';

  @override
  String get help4Title => 'Follow the arrow';

  @override
  String get help4Body =>
      'Navigate shows a big arrow and metres to the house — no internet needed. The phone vibrates when you are close.';

  @override
  String get help5Title => 'Add today\'s articles';

  @override
  String get help5Body =>
      'Scan the barcode, or photograph the address — the app suggests the matching house. Confirm with one tap.';

  @override
  String get help6Title => 'Plan and deliver';

  @override
  String get help6Body => 'Plan the route, then press ✅ Delivered or ❌ Not delivered at each stop.';

  @override
  String get help7Title => 'Day summary';

  @override
  String get help7Body => 'See counts and reasons, carry re-attempts to the next day and share the summary text.';

  @override
  String get help8Title => 'Learn a new beat';

  @override
  String get help8Body => 'Practise with photo and name cards, or use walk mode while walking the beat.';

  @override
  String get help9Title => 'Handover and backup';

  @override
  String get help9Body => 'Give your beat to a relief postman as an encrypted file. Make a full backup every week.';

  @override
  String get helpKannadaOcr =>
      'Note: the on-device text reader understands English and Hindi (Devanagari) print, but not Kannada script. For Kannada addresses, search by name or door no. — Kannada typing and voice search work.';
}

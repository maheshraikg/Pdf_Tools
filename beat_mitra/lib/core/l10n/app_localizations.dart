import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('hi'), Locale('kn')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Beat Mitra'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your helper for the delivery beat'**
  String get appTagline;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @iUnderstand.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get iUnderstand;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Independent helper tool for postmen. Not an official Department of Posts app. Follow your office\'s rules on customer information.'**
  String get disclaimer;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Names and addresses stay only on this phone.'**
  String get privacyOnDevice;

  /// No description provided for @privacyEncrypted.
  ///
  /// In en, this message translates to:
  /// **'All data and photos are encrypted and protected by your PIN.'**
  String get privacyEncrypted;

  /// No description provided for @privacyNoCloud.
  ///
  /// In en, this message translates to:
  /// **'No internet, no cloud, no login, no ads.'**
  String get privacyNoCloud;

  /// No description provided for @privacyNoAnalytics.
  ///
  /// In en, this message translates to:
  /// **'No analytics or crash reporting.'**
  String get privacyNoAnalytics;

  /// No description provided for @privacyMap.
  ///
  /// In en, this message translates to:
  /// **'The optional online map is OFF by default and only loads map pictures from OpenStreetMap.'**
  String get privacyMap;

  /// No description provided for @privacyBackupAdvice.
  ///
  /// In en, this message translates to:
  /// **'Data is only on this phone: make an encrypted backup every week.'**
  String get privacyBackupAdvice;

  /// No description provided for @freeTools.
  ///
  /// In en, this message translates to:
  /// **'Built only with free and open tools. Works fully offline.'**
  String get freeTools;

  /// No description provided for @createPin.
  ///
  /// In en, this message translates to:
  /// **'Create a 4-digit PIN'**
  String get createPin;

  /// No description provided for @confirmPin.
  ///
  /// In en, this message translates to:
  /// **'Enter the PIN again'**
  String get confirmPin;

  /// No description provided for @pinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs did not match. Try again.'**
  String get pinMismatch;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @enterOldPin.
  ///
  /// In en, this message translates to:
  /// **'Enter current PIN'**
  String get enterOldPin;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get wrongPin;

  /// No description provided for @tooManyTries.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait 30 seconds.'**
  String get tooManyTries;

  /// No description provided for @useFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint / face'**
  String get useFingerprint;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Beat Mitra'**
  String get unlockReason;

  /// No description provided for @biometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this phone'**
  String get biometricUnavailable;

  /// No description provided for @pinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get pinChanged;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get voiceInput;

  /// No description provided for @voiceStop.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get voiceStop;

  /// No description provided for @voiceNotHeard.
  ///
  /// In en, this message translates to:
  /// **'Could not hear. Try again or type.'**
  String get voiceNotHeard;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWrong;

  /// No description provided for @switchBeat.
  ///
  /// In en, this message translates to:
  /// **'Switch beat'**
  String get switchBeat;

  /// No description provided for @noBeatYet.
  ///
  /// In en, this message translates to:
  /// **'No beat yet. Create your beat to start.'**
  String get noBeatYet;

  /// No description provided for @createBeat.
  ///
  /// In en, this message translates to:
  /// **'Create beat'**
  String get createBeat;

  /// No description provided for @editBeat.
  ///
  /// In en, this message translates to:
  /// **'Edit beat'**
  String get editBeat;

  /// No description provided for @deleteBeat.
  ///
  /// In en, this message translates to:
  /// **'Delete beat'**
  String get deleteBeat;

  /// No description provided for @deleteBeatConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this beat with its {count} places, streets and photos?'**
  String deleteBeatConfirm(int count);

  /// No description provided for @beats.
  ///
  /// In en, this message translates to:
  /// **'Beats'**
  String get beats;

  /// No description provided for @beatName.
  ///
  /// In en, this message translates to:
  /// **'Beat name'**
  String get beatName;

  /// No description provided for @beatNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Beat 7 / Relief beat 3'**
  String get beatNameHint;

  /// No description provided for @office.
  ///
  /// In en, this message translates to:
  /// **'Post office'**
  String get office;

  /// No description provided for @addHere.
  ///
  /// In en, this message translates to:
  /// **'Add here'**
  String get addHere;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, door no., street, landmark, PIN…'**
  String get searchHint;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @todaysArticles.
  ///
  /// In en, this message translates to:
  /// **'Today\'s articles'**
  String get todaysArticles;

  /// No description provided for @pendingDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{pending} to deliver · {done} done'**
  String pendingDoneCount(int pending, int done);

  /// No description provided for @routeAndRun.
  ///
  /// In en, this message translates to:
  /// **'Route & delivery'**
  String get routeAndRun;

  /// No description provided for @nearby.
  ///
  /// In en, this message translates to:
  /// **'Nearby places'**
  String get nearby;

  /// No description provided for @daySummary.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get daySummary;

  /// No description provided for @beatAndStreets.
  ///
  /// In en, this message translates to:
  /// **'Beat & streets'**
  String get beatAndStreets;

  /// No description provided for @learnBeat.
  ///
  /// In en, this message translates to:
  /// **'Learn the beat'**
  String get learnBeat;

  /// No description provided for @handoverBackup.
  ///
  /// In en, this message translates to:
  /// **'Handover & backup'**
  String get handoverBackup;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @backupReminder.
  ///
  /// In en, this message translates to:
  /// **'No backup in the last 7 days. Your data is only on this phone — back up now.'**
  String get backupReminder;

  /// No description provided for @streets.
  ///
  /// In en, this message translates to:
  /// **'Streets'**
  String get streets;

  /// No description provided for @streetsHelp.
  ///
  /// In en, this message translates to:
  /// **'Drag ≡ to put streets in your usual walking order.'**
  String get streetsHelp;

  /// No description provided for @noStreets.
  ///
  /// In en, this message translates to:
  /// **'No streets yet. Add the streets of your beat.'**
  String get noStreets;

  /// No description provided for @addStreet.
  ///
  /// In en, this message translates to:
  /// **'Add street'**
  String get addStreet;

  /// No description provided for @editStreet.
  ///
  /// In en, this message translates to:
  /// **'Edit street'**
  String get editStreet;

  /// No description provided for @deleteStreet.
  ///
  /// In en, this message translates to:
  /// **'Delete street'**
  String get deleteStreet;

  /// No description provided for @deleteStreetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this street? Its places stay, without a street.'**
  String get deleteStreetConfirm;

  /// No description provided for @streetName.
  ///
  /// In en, this message translates to:
  /// **'Street name'**
  String get streetName;

  /// No description provided for @streetNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 4th Cross, 2nd Main, HAL 2nd Stage'**
  String get streetNameHint;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @crossMainNote.
  ///
  /// In en, this message translates to:
  /// **'Cross / main note'**
  String get crossMainNote;

  /// No description provided for @placesCount.
  ///
  /// In en, this message translates to:
  /// **'Places: {count}'**
  String placesCount(int count);

  /// No description provided for @noPlaces.
  ///
  /// In en, this message translates to:
  /// **'No places yet. Walk your beat and tap “Add here” at each door.'**
  String get noPlaces;

  /// No description provided for @noStreet.
  ///
  /// In en, this message translates to:
  /// **'No street'**
  String get noStreet;

  /// No description provided for @areaNotes.
  ///
  /// In en, this message translates to:
  /// **'Area notes'**
  String get areaNotes;

  /// No description provided for @areaNote.
  ///
  /// In en, this message translates to:
  /// **'Area note'**
  String get areaNote;

  /// No description provided for @areaNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. cross numbers increase towards the lake'**
  String get areaNoteHint;

  /// No description provided for @addAreaNote.
  ///
  /// In en, this message translates to:
  /// **'Add area note'**
  String get addAreaNote;

  /// No description provided for @noAreaNotes.
  ///
  /// In en, this message translates to:
  /// **'Write how numbering works here, short cuts, timings…'**
  String get noAreaNotes;

  /// No description provided for @addPlace.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlace;

  /// No description provided for @editPlace.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlace;

  /// No description provided for @deletePlace.
  ///
  /// In en, this message translates to:
  /// **'Delete place'**
  String get deletePlace;

  /// No description provided for @deletePlaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this place, its names and photos?'**
  String get deletePlaceConfirm;

  /// No description provided for @placeDeleted.
  ///
  /// In en, this message translates to:
  /// **'This place was deleted.'**
  String get placeDeleted;

  /// No description provided for @placeNeedsSomething.
  ///
  /// In en, this message translates to:
  /// **'Enter a door no., building, name or landmark.'**
  String get placeNeedsSomething;

  /// No description provided for @doorNo.
  ///
  /// In en, this message translates to:
  /// **'Door no.'**
  String get doorNo;

  /// No description provided for @pickStreet.
  ///
  /// In en, this message translates to:
  /// **'Choose street'**
  String get pickStreet;

  /// No description provided for @searchStreet.
  ///
  /// In en, this message translates to:
  /// **'Search street'**
  String get searchStreet;

  /// No description provided for @newStreet.
  ///
  /// In en, this message translates to:
  /// **'New street'**
  String get newStreet;

  /// No description provided for @newStreetNamed.
  ///
  /// In en, this message translates to:
  /// **'New street “{name}”'**
  String newStreetNamed(String name);

  /// No description provided for @addressees.
  ///
  /// In en, this message translates to:
  /// **'Names at this place'**
  String get addressees;

  /// No description provided for @addressee.
  ///
  /// In en, this message translates to:
  /// **'Addressee'**
  String get addressee;

  /// No description provided for @addName.
  ///
  /// In en, this message translates to:
  /// **'Add name'**
  String get addName;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @aliases.
  ///
  /// In en, this message translates to:
  /// **'Other spellings / names'**
  String get aliases;

  /// No description provided for @aliasesHelp.
  ///
  /// In en, this message translates to:
  /// **'Separate with commas'**
  String get aliasesHelp;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @noteFlat.
  ///
  /// In en, this message translates to:
  /// **'Note (flat, floor…)'**
  String get noteFlat;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @floorFlat.
  ///
  /// In en, this message translates to:
  /// **'Floor / flat'**
  String get floorFlat;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes: dog, gate, floor, timing'**
  String get notesHint;

  /// No description provided for @quickDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get quickDog;

  /// No description provided for @quickGate.
  ///
  /// In en, this message translates to:
  /// **'Gate locked'**
  String get quickGate;

  /// No description provided for @quickUpstairs.
  ///
  /// In en, this message translates to:
  /// **'Upstairs'**
  String get quickUpstairs;

  /// No description provided for @quickMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning only'**
  String get quickMorning;

  /// No description provided for @quickEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening only'**
  String get quickEvening;

  /// No description provided for @deliveryPref.
  ///
  /// In en, this message translates to:
  /// **'Delivery preference'**
  String get deliveryPref;

  /// No description provided for @prefSecurity.
  ///
  /// In en, this message translates to:
  /// **'Leave with security'**
  String get prefSecurity;

  /// No description provided for @prefNeighbour.
  ///
  /// In en, this message translates to:
  /// **'Leave with neighbour'**
  String get prefNeighbour;

  /// No description provided for @prefLetterBox.
  ///
  /// In en, this message translates to:
  /// **'Letter box'**
  String get prefLetterBox;

  /// No description provided for @prefShop.
  ///
  /// In en, this message translates to:
  /// **'Shop below'**
  String get prefShop;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN code'**
  String get pin;

  /// No description provided for @placeHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get placeHouse;

  /// No description provided for @placeShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get placeShop;

  /// No description provided for @placeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get placeOffice;

  /// No description provided for @placeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get placeApartment;

  /// No description provided for @placeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get placeOther;

  /// No description provided for @maxPhotos.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 photos per place'**
  String get maxPhotos;

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'Photo {count}/3'**
  String photoCount(int count);

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera not available'**
  String get cameraError;

  /// No description provided for @possibleDuplicates.
  ///
  /// In en, this message translates to:
  /// **'Already saved close by — same place?'**
  String get possibleDuplicates;

  /// No description provided for @openIt.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openIt;

  /// No description provided for @gpsOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Turn it on.'**
  String get gpsOff;

  /// No description provided for @gpsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed.'**
  String get gpsDenied;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @gpsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Getting GPS…'**
  String get gpsWaiting;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy {acc} m (want ≤ {want} m)'**
  String gpsAccuracy(int acc, int want);

  /// No description provided for @gpsAccuracyShort.
  ///
  /// In en, this message translates to:
  /// **'± {acc} m'**
  String gpsAccuracyShort(int acc);

  /// No description provided for @gpsUseNow.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get gpsUseNow;

  /// No description provided for @gpsSaved.
  ///
  /// In en, this message translates to:
  /// **'Location saved (± {acc} m)'**
  String gpsSaved(int acc);

  /// No description provided for @gpsRetake.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get gpsRetake;

  /// No description provided for @gpsNotSet.
  ///
  /// In en, this message translates to:
  /// **'No location saved'**
  String get gpsNotSet;

  /// No description provided for @gpsCapture.
  ///
  /// In en, this message translates to:
  /// **'Get GPS'**
  String get gpsCapture;

  /// No description provided for @updateGpsHere.
  ///
  /// In en, this message translates to:
  /// **'Move pin to my current location'**
  String get updateGpsHere;

  /// No description provided for @updateGpsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save your current location (± {acc} m) for this place?'**
  String updateGpsConfirm(int acc);

  /// No description provided for @mergeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Merge a duplicate'**
  String get mergeDuplicate;

  /// No description provided for @pickDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Pick the duplicate'**
  String get pickDuplicate;

  /// No description provided for @mergeIntoThis.
  ///
  /// In en, this message translates to:
  /// **'Merge into this place'**
  String get mergeIntoThis;

  /// No description provided for @mergeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Names, photos and articles of the duplicate move here, then it is deleted.'**
  String get mergeConfirm;

  /// No description provided for @merged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get merged;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @googleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get googleMaps;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @searchTips.
  ///
  /// In en, this message translates to:
  /// **'Type or speak a name, door no. (12/3), street, landmark or PIN. Kannada, Hindi and English spellings all work.'**
  String get searchTips;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Try fewer letters or the door no.'**
  String get noResults;

  /// No description provided for @allBeats.
  ///
  /// In en, this message translates to:
  /// **'All beats'**
  String get allBeats;

  /// No description provided for @placeHasNoGps.
  ///
  /// In en, this message translates to:
  /// **'This place has no GPS location yet. Edit it at the door to add one.'**
  String get placeHasNoGps;

  /// No description provided for @arrived.
  ///
  /// In en, this message translates to:
  /// **'You are here'**
  String get arrived;

  /// No description provided for @noCompass.
  ///
  /// In en, this message translates to:
  /// **'No compass: arrow shows direction when walking.'**
  String get noCompass;

  /// No description provided for @noNearby.
  ///
  /// In en, this message translates to:
  /// **'No saved places near you.'**
  String get noNearby;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcode;

  /// No description provided for @scanAddress.
  ///
  /// In en, this message translates to:
  /// **'Scan address'**
  String get scanAddress;

  /// No description provided for @typeIn.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeIn;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get torch;

  /// No description provided for @scannedCount.
  ///
  /// In en, this message translates to:
  /// **'Scanned: {count}'**
  String scannedCount(int count);

  /// No description provided for @addedCount.
  ///
  /// In en, this message translates to:
  /// **'Added {count} articles'**
  String addedCount(int count);

  /// No description provided for @articleValid.
  ///
  /// In en, this message translates to:
  /// **'Valid article number'**
  String get articleValid;

  /// No description provided for @articleBadCheck.
  ///
  /// In en, this message translates to:
  /// **'Check digit does not match — please check the number'**
  String get articleBadCheck;

  /// No description provided for @articleOtherFormat.
  ///
  /// In en, this message translates to:
  /// **'Other format (allowed)'**
  String get articleOtherFormat;

  /// No description provided for @articleInvalid.
  ///
  /// In en, this message translates to:
  /// **'Too short / not valid'**
  String get articleInvalid;

  /// No description provided for @articleNo.
  ///
  /// In en, this message translates to:
  /// **'Article number'**
  String get articleNo;

  /// No description provided for @articleNoOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional for ordinary letters'**
  String get articleNoOptional;

  /// No description provided for @addArticle.
  ///
  /// In en, this message translates to:
  /// **'Add article'**
  String get addArticle;

  /// No description provided for @editArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get editArticle;

  /// No description provided for @deleteArticle.
  ///
  /// In en, this message translates to:
  /// **'Delete article'**
  String get deleteArticle;

  /// No description provided for @deleteArticleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this article from today\'s list?'**
  String get deleteArticleConfirm;

  /// No description provided for @duplicateArticle.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get duplicateArticle;

  /// No description provided for @duplicateArticleBody.
  ///
  /// In en, this message translates to:
  /// **'{number} is already in today\'s list. Add again?'**
  String duplicateArticleBody(String number);

  /// No description provided for @typeLetter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get typeLetter;

  /// No description provided for @typeRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get typeRegistered;

  /// No description provided for @typeSpeedPost.
  ///
  /// In en, this message translates to:
  /// **'Speed Post'**
  String get typeSpeedPost;

  /// No description provided for @typeParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel'**
  String get typeParcel;

  /// No description provided for @typeMoneyOrder.
  ///
  /// In en, this message translates to:
  /// **'Money order'**
  String get typeMoneyOrder;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @needsSignature.
  ///
  /// In en, this message translates to:
  /// **'Needs signature / OTP'**
  String get needsSignature;

  /// No description provided for @addressText.
  ///
  /// In en, this message translates to:
  /// **'Address (as written)'**
  String get addressText;

  /// No description provided for @findMatch.
  ///
  /// In en, this message translates to:
  /// **'Find match'**
  String get findMatch;

  /// No description provided for @place.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get place;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions — tap the right one'**
  String get suggestions;

  /// No description provided for @thisOne.
  ///
  /// In en, this message translates to:
  /// **'This one'**
  String get thisOne;

  /// No description provided for @noMatchFound.
  ///
  /// In en, this message translates to:
  /// **'No saved place matches. Search or add a new place.'**
  String get noMatchFound;

  /// No description provided for @searchPlace.
  ///
  /// In en, this message translates to:
  /// **'Search place'**
  String get searchPlace;

  /// No description provided for @addNewPlace.
  ///
  /// In en, this message translates to:
  /// **'Add new place'**
  String get addNewPlace;

  /// No description provided for @pickPlace.
  ///
  /// In en, this message translates to:
  /// **'Pick the place'**
  String get pickPlace;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the text'**
  String get ocrFailed;

  /// No description provided for @ocrNothing.
  ///
  /// In en, this message translates to:
  /// **'No text found. Hold the camera closer, in good light.'**
  String get ocrNothing;

  /// No description provided for @carryPrompt.
  ///
  /// In en, this message translates to:
  /// **'{count} re-attempts from the last day'**
  String carryPrompt(int count);

  /// No description provided for @carriedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} re-attempts added'**
  String carriedCount(int count);

  /// No description provided for @todayCounts.
  ///
  /// In en, this message translates to:
  /// **'{total} articles · {pending} pending · {unmatched} unmatched'**
  String todayCounts(int total, int pending, int unmatched);

  /// No description provided for @noArticlesToday.
  ///
  /// In en, this message translates to:
  /// **'No articles yet. Scan barcodes or addresses, or type them in.'**
  String get noArticlesToday;

  /// No description provided for @unmatched.
  ///
  /// In en, this message translates to:
  /// **'Unmatched — link to a place'**
  String get unmatched;

  /// No description provided for @matched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get matched;

  /// No description provided for @planRoute.
  ///
  /// In en, this message translates to:
  /// **'Plan route'**
  String get planRoute;

  /// No description provided for @reattempt.
  ///
  /// In en, this message translates to:
  /// **'Re-attempt'**
  String get reattempt;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusNotDelivered.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get statusNotDelivered;

  /// No description provided for @routePlan.
  ///
  /// In en, this message translates to:
  /// **'Route plan'**
  String get routePlan;

  /// No description provided for @modeShortest.
  ///
  /// In en, this message translates to:
  /// **'Shortest'**
  String get modeShortest;

  /// No description provided for @modeStreet.
  ///
  /// In en, this message translates to:
  /// **'Street order'**
  String get modeStreet;

  /// No description provided for @routeSummary.
  ///
  /// In en, this message translates to:
  /// **'{stops} stops · about {distance}'**
  String routeSummary(int stops, String distance);

  /// No description provided for @startFrom.
  ///
  /// In en, this message translates to:
  /// **'Start: {where}'**
  String startFrom(String where);

  /// No description provided for @startUnknown.
  ///
  /// In en, this message translates to:
  /// **'Start point unknown (no GPS)'**
  String get startUnknown;

  /// No description provided for @startOffice.
  ///
  /// In en, this message translates to:
  /// **'Post office'**
  String get startOffice;

  /// No description provided for @startCurrent.
  ///
  /// In en, this message translates to:
  /// **'My current location'**
  String get startCurrent;

  /// No description provided for @unmatchedNotInRoute.
  ///
  /// In en, this message translates to:
  /// **'{count} unmatched articles are not in the route'**
  String unmatchedNotInRoute(int count);

  /// No description provided for @replan.
  ///
  /// In en, this message translates to:
  /// **'Plan again'**
  String get replan;

  /// No description provided for @allUnmatched.
  ///
  /// In en, this message translates to:
  /// **'{count} articles are not linked to places yet. Link them in Today\'s articles.'**
  String allUnmatched(int count);

  /// No description provided for @nothingToDeliver.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending to deliver today.'**
  String get nothingToDeliver;

  /// No description provided for @articlesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} articles'**
  String articlesCount(int count);

  /// No description provided for @noGps.
  ///
  /// In en, this message translates to:
  /// **'no GPS'**
  String get noGps;

  /// No description provided for @startRun.
  ///
  /// In en, this message translates to:
  /// **'Start delivery'**
  String get startRun;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get run;

  /// No description provided for @stopsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} stops'**
  String stopsDone(int done, int total);

  /// No description provided for @nextStop.
  ///
  /// In en, this message translates to:
  /// **'NEXT STOP'**
  String get nextStop;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @notDelivered.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get notDelivered;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @whyNotDelivered.
  ///
  /// In en, this message translates to:
  /// **'Why not delivered?'**
  String get whyNotDelivered;

  /// No description provided for @reasonDoorLocked.
  ///
  /// In en, this message translates to:
  /// **'Door locked'**
  String get reasonDoorLocked;

  /// No description provided for @reasonAbsent.
  ///
  /// In en, this message translates to:
  /// **'Addressee not available'**
  String get reasonAbsent;

  /// No description provided for @reasonLeft.
  ///
  /// In en, this message translates to:
  /// **'Left / shifted'**
  String get reasonLeft;

  /// No description provided for @reasonRefused.
  ///
  /// In en, this message translates to:
  /// **'Refused'**
  String get reasonRefused;

  /// No description provided for @reasonWrongAddress.
  ///
  /// In en, this message translates to:
  /// **'Wrong / insufficient address'**
  String get reasonWrongAddress;

  /// No description provided for @reasonUnclaimed.
  ///
  /// In en, this message translates to:
  /// **'Unclaimed'**
  String get reasonUnclaimed;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @runFinished.
  ///
  /// In en, this message translates to:
  /// **'All stops done. Well done!'**
  String get runFinished;

  /// No description provided for @ttsNext.
  ///
  /// In en, this message translates to:
  /// **'Next: number {where}'**
  String ttsNext(String where);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noArticlesThatDay.
  ///
  /// In en, this message translates to:
  /// **'No articles on this day.'**
  String get noArticlesThatDay;

  /// No description provided for @notDeliveredList.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get notDeliveredList;

  /// No description provided for @carryToTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Carry {count} re-attempts to next day'**
  String carryToTomorrow(int count);

  /// No description provided for @summaryTotals.
  ///
  /// In en, this message translates to:
  /// **'Total {total}: delivered {delivered}, not delivered {notDelivered}, pending {pending}'**
  String summaryTotals(int total, int delivered, int notDelivered, int pending);

  /// No description provided for @summaryTypeLine.
  ///
  /// In en, this message translates to:
  /// **'{type}: {delivered}/{total} delivered'**
  String summaryTypeLine(String type, int delivered, int total);

  /// No description provided for @distanceLine.
  ///
  /// In en, this message translates to:
  /// **'Planned route {planned} · recorded {recorded}'**
  String distanceLine(String planned, String recorded);

  /// No description provided for @learnedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of places learned'**
  String learnedPercent(int percent);

  /// No description provided for @learnedOf.
  ///
  /// In en, this message translates to:
  /// **'{learned} of {total} places'**
  String learnedOf(int learned, int total);

  /// No description provided for @weakStreets.
  ///
  /// In en, this message translates to:
  /// **'Streets to practise'**
  String get weakStreets;

  /// No description provided for @quizPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo → place'**
  String get quizPhoto;

  /// No description provided for @quizPhotoSub.
  ///
  /// In en, this message translates to:
  /// **'See the house photo, pick the door no. and street'**
  String get quizPhotoSub;

  /// No description provided for @quizName.
  ///
  /// In en, this message translates to:
  /// **'Name → door no.'**
  String get quizName;

  /// No description provided for @quizNameSub.
  ///
  /// In en, this message translates to:
  /// **'Where does this person live?'**
  String get quizNameSub;

  /// No description provided for @quizDoor.
  ///
  /// In en, this message translates to:
  /// **'Door no. → landmark'**
  String get quizDoor;

  /// No description provided for @quizDoorSub.
  ///
  /// In en, this message translates to:
  /// **'What landmark is near this door?'**
  String get quizDoorSub;

  /// No description provided for @walkMode.
  ///
  /// In en, this message translates to:
  /// **'Walk mode'**
  String get walkMode;

  /// No description provided for @walkModeSub.
  ///
  /// In en, this message translates to:
  /// **'Walk the beat; the app quizzes you about the nearest house'**
  String get walkModeSub;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset learning progress'**
  String get resetProgress;

  /// No description provided for @resetProgressConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start learning this beat from zero?'**
  String get resetProgressConfirm;

  /// No description provided for @qWhichPlace.
  ///
  /// In en, this message translates to:
  /// **'Which place is this?'**
  String get qWhichPlace;

  /// No description provided for @qWhereLives.
  ///
  /// In en, this message translates to:
  /// **'Where does {name} get mail?'**
  String qWhereLives(String name);

  /// No description provided for @qLandmarkOf.
  ///
  /// In en, this message translates to:
  /// **'Landmark near {place}?'**
  String qLandmarkOf(String place);

  /// No description provided for @qWhoLivesHere.
  ///
  /// In en, this message translates to:
  /// **'Who gets mail here?'**
  String get qWhoLivesHere;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get correct;

  /// No description provided for @wrongAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer: {answer}'**
  String wrongAnswer(String answer);

  /// No description provided for @scoreLine.
  ///
  /// In en, this message translates to:
  /// **'Score {right}/{total}'**
  String scoreLine(int right, int total);

  /// No description provided for @notEnoughForQuiz.
  ///
  /// In en, this message translates to:
  /// **'Add more places (with photos, names, landmarks) to practise.'**
  String get notEnoughForQuiz;

  /// No description provided for @nearestPlace.
  ///
  /// In en, this message translates to:
  /// **'Nearest saved place · {distance}'**
  String nearestPlace(String distance);

  /// No description provided for @walkHint.
  ///
  /// In en, this message translates to:
  /// **'Walk closer (within 40 m) to a house you have not answered yet.'**
  String get walkHint;

  /// No description provided for @handover.
  ///
  /// In en, this message translates to:
  /// **'Handover to a relief postman'**
  String get handover;

  /// No description provided for @handoverHelp.
  ///
  /// In en, this message translates to:
  /// **'Export a beat as a password-protected encrypted file and share it. Tell the password separately (by phone, not in the same message).'**
  String get handoverHelp;

  /// No description provided for @handoverExport.
  ///
  /// In en, this message translates to:
  /// **'Export beat'**
  String get handoverExport;

  /// No description provided for @handoverShareText.
  ///
  /// In en, this message translates to:
  /// **'Beat Mitra beat file. Open it in Beat Mitra → Handover & backup → Import.'**
  String get handoverShareText;

  /// No description provided for @chooseBeats.
  ///
  /// In en, this message translates to:
  /// **'Beats to include'**
  String get chooseBeats;

  /// No description provided for @includePhones.
  ///
  /// In en, this message translates to:
  /// **'Include phone numbers'**
  String get includePhones;

  /// No description provided for @createAndShare.
  ///
  /// In en, this message translates to:
  /// **'Create & share'**
  String get createAndShare;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordAgain.
  ///
  /// In en, this message translates to:
  /// **'Password again'**
  String get passwordAgain;

  /// No description provided for @passwordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters. Without it the file cannot be opened.'**
  String get passwordHelp;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @importBeat.
  ///
  /// In en, this message translates to:
  /// **'Import a beat file'**
  String get importBeat;

  /// No description provided for @enterFilePassword.
  ///
  /// In en, this message translates to:
  /// **'Password of the file'**
  String get enterFilePassword;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get wrongPassword;

  /// No description provided for @notBeatMitraFile.
  ///
  /// In en, this message translates to:
  /// **'This is not a Beat Mitra file'**
  String get notBeatMitraFile;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported {beats} beats, {places} places, {photos} photos'**
  String importDone(int beats, int places, int photos);

  /// No description provided for @thisIsHandover.
  ///
  /// In en, this message translates to:
  /// **'This is a beat file: its beats are added to yours.'**
  String get thisIsHandover;

  /// No description provided for @fullBackup.
  ///
  /// In en, this message translates to:
  /// **'Full backup'**
  String get fullBackup;

  /// No description provided for @fullBackupHelp.
  ///
  /// In en, this message translates to:
  /// **'Everything (beats, places, photos, history) in one encrypted file. Save it to a pen drive, SD card or computer.'**
  String get fullBackupHelp;

  /// No description provided for @backupAdvice.
  ///
  /// In en, this message translates to:
  /// **'Data lives only on this phone. If the phone is lost, only a backup can bring it back.'**
  String get backupAdvice;

  /// No description provided for @neverBackedUp.
  ///
  /// In en, this message translates to:
  /// **'Never backed up'**
  String get neverBackedUp;

  /// No description provided for @lastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {when}'**
  String lastBackup(String when);

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @chooseLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose where to save'**
  String get chooseLocation;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore a backup'**
  String get restoreBackup;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @restoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'All current data on this phone will be replaced by the backup. Continue?'**
  String get restoreConfirm;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @deviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Phone language'**
  String get deviceLanguage;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sunlightMode.
  ///
  /// In en, this message translates to:
  /// **'Sunlight mode'**
  String get sunlightMode;

  /// No description provided for @sunlightModeSub.
  ///
  /// In en, this message translates to:
  /// **'Extra contrast for bright sun'**
  String get sunlightModeSub;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get textSize;

  /// No description provided for @textNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get textNormal;

  /// No description provided for @textLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get textLarge;

  /// No description provided for @textXL.
  ///
  /// In en, this message translates to:
  /// **'Extra large'**
  String get textXL;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @autoLock.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get autoLock;

  /// No description provided for @lockImmediately.
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get lockImmediately;

  /// No description provided for @lockAfterMin.
  ///
  /// In en, this message translates to:
  /// **'After {minutes} min'**
  String lockAfterMin(int minutes);

  /// No description provided for @blockScreenshots.
  ///
  /// In en, this message translates to:
  /// **'Block screenshots'**
  String get blockScreenshots;

  /// No description provided for @blockScreenshotsSub.
  ///
  /// In en, this message translates to:
  /// **'Also hides the app in recent apps'**
  String get blockScreenshotsSub;

  /// No description provided for @gpsAndRoute.
  ///
  /// In en, this message translates to:
  /// **'GPS & route'**
  String get gpsAndRoute;

  /// No description provided for @gpsThreshold.
  ///
  /// In en, this message translates to:
  /// **'GPS accuracy needed'**
  String get gpsThreshold;

  /// No description provided for @startPoint.
  ///
  /// In en, this message translates to:
  /// **'Route start point'**
  String get startPoint;

  /// No description provided for @setOfficeHere.
  ///
  /// In en, this message translates to:
  /// **'Post office = where I am now'**
  String get setOfficeHere;

  /// No description provided for @vibrateNear.
  ///
  /// In en, this message translates to:
  /// **'Vibrate within 20 m of the place'**
  String get vibrateNear;

  /// No description provided for @ttsSetting.
  ///
  /// In en, this message translates to:
  /// **'Read out next stop'**
  String get ttsSetting;

  /// No description provided for @ttsSettingSub.
  ///
  /// In en, this message translates to:
  /// **'Uses the phone\'s text-to-speech'**
  String get ttsSettingSub;

  /// No description provided for @dataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataSection;

  /// No description provided for @historyRetention.
  ///
  /// In en, this message translates to:
  /// **'Keep delivery history'**
  String get historyRetention;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysCount(int days);

  /// No description provided for @oldDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} old articles deleted'**
  String oldDeleted(int count);

  /// No description provided for @onlineMap.
  ///
  /// In en, this message translates to:
  /// **'Online map (OpenStreetMap)'**
  String get onlineMap;

  /// No description provided for @onlineMapSub.
  ///
  /// In en, this message translates to:
  /// **'Off by default. Needs internet only for map pictures.'**
  String get onlineMapSub;

  /// No description provided for @onlineMapConfirm.
  ///
  /// In en, this message translates to:
  /// **'The map downloads map pictures from OpenStreetMap while you look at it. Your names and addresses are never sent. Turn on?'**
  String get onlineMapConfirm;

  /// No description provided for @mapNotInBuild.
  ///
  /// In en, this message translates to:
  /// **'This is the offline build (no internet permission). Install the “map” build to use the online map.'**
  String get mapNotInBuild;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get deleteAll;

  /// No description provided for @deleteAllConfirm1.
  ///
  /// In en, this message translates to:
  /// **'This deletes all beats, places, photos, names and history from this phone. It cannot be undone. Make a backup first.'**
  String get deleteAllConfirm1;

  /// No description provided for @deleteAllConfirm2.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get deleteAllConfirm2;

  /// No description provided for @notDeleted.
  ///
  /// In en, this message translates to:
  /// **'Nothing was deleted'**
  String get notDeleted;

  /// No description provided for @helpAndAbout.
  ///
  /// In en, this message translates to:
  /// **'Help & about'**
  String get helpAndAbout;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licences;

  /// No description provided for @help1Title.
  ///
  /// In en, this message translates to:
  /// **'Create your beat and streets'**
  String get help1Title;

  /// No description provided for @help1Body.
  ///
  /// In en, this message translates to:
  /// **'Add each street and drag them into the order you usually walk.'**
  String get help1Body;

  /// No description provided for @help2Title.
  ///
  /// In en, this message translates to:
  /// **'“Add here” at each door'**
  String get help2Title;

  /// No description provided for @help2Body.
  ///
  /// In en, this message translates to:
  /// **'GPS is saved, take 1–3 photos, then the door no., street, names (speak them) and notes like “dog”.'**
  String get help2Body;

  /// No description provided for @help3Title.
  ///
  /// In en, this message translates to:
  /// **'Search anything'**
  String get help3Title;

  /// No description provided for @help3Body.
  ///
  /// In en, this message translates to:
  /// **'Type or speak a name, door no., street or landmark. Small spelling mistakes are fine.'**
  String get help3Body;

  /// No description provided for @help4Title.
  ///
  /// In en, this message translates to:
  /// **'Follow the arrow'**
  String get help4Title;

  /// No description provided for @help4Body.
  ///
  /// In en, this message translates to:
  /// **'Navigate shows a big arrow and metres to the house — no internet needed. The phone vibrates when you are close.'**
  String get help4Body;

  /// No description provided for @help5Title.
  ///
  /// In en, this message translates to:
  /// **'Add today\'s articles'**
  String get help5Title;

  /// No description provided for @help5Body.
  ///
  /// In en, this message translates to:
  /// **'Scan the barcode, or photograph the address — the app suggests the matching house. Confirm with one tap.'**
  String get help5Body;

  /// No description provided for @help6Title.
  ///
  /// In en, this message translates to:
  /// **'Plan and deliver'**
  String get help6Title;

  /// No description provided for @help6Body.
  ///
  /// In en, this message translates to:
  /// **'Plan the route, then press ✅ Delivered or ❌ Not delivered at each stop.'**
  String get help6Body;

  /// No description provided for @help7Title.
  ///
  /// In en, this message translates to:
  /// **'Day summary'**
  String get help7Title;

  /// No description provided for @help7Body.
  ///
  /// In en, this message translates to:
  /// **'See counts and reasons, carry re-attempts to the next day and share the summary text.'**
  String get help7Body;

  /// No description provided for @help8Title.
  ///
  /// In en, this message translates to:
  /// **'Learn a new beat'**
  String get help8Title;

  /// No description provided for @help8Body.
  ///
  /// In en, this message translates to:
  /// **'Practise with photo and name cards, or use walk mode while walking the beat.'**
  String get help8Body;

  /// No description provided for @help9Title.
  ///
  /// In en, this message translates to:
  /// **'Handover and backup'**
  String get help9Title;

  /// No description provided for @help9Body.
  ///
  /// In en, this message translates to:
  /// **'Give your beat to a relief postman as an encrypted file. Make a full backup every week.'**
  String get help9Body;

  /// No description provided for @helpKannadaOcr.
  ///
  /// In en, this message translates to:
  /// **'Note: the on-device text reader understands English and Hindi (Devanagari) print, but not Kannada script. For Kannada addresses, search by name or door no. — Kannada typing and voice search work.'**
  String get helpKannadaOcr;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

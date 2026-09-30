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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PO Sorting'**
  String get appTitle;

  /// No description provided for @navSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get navSort;

  /// No description provided for @navFindPin.
  ///
  /// In en, this message translates to:
  /// **'Find PIN'**
  String get navFindPin;

  /// No description provided for @navBulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get navBulk;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @disclaimer.
  ///
  /// In en, this message translates to:
  /// **'Independent helper tool for postal staff. Not an official Department of Posts app.'**
  String get disclaimer;

  /// No description provided for @dataCredit.
  ///
  /// In en, this message translates to:
  /// **'PIN data: data.gov.in, Government of India, Open Government Data Licence'**
  String get dataCredit;

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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String error(String message);

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String confirmDelete(String name);

  /// No description provided for @sampleBadge.
  ///
  /// In en, this message translates to:
  /// **'SAMPLE – not real'**
  String get sampleBadge;

  /// No description provided for @noActiveScheme.
  ///
  /// In en, this message translates to:
  /// **'No sorting scheme active. Import your office\'s scheme in More → Schemes (or use the sample).'**
  String get noActiveScheme;

  /// No description provided for @useSample.
  ///
  /// In en, this message translates to:
  /// **'Use sample scheme'**
  String get useSample;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutSub.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer, privacy, data source, version'**
  String get aboutSub;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @schemes.
  ///
  /// In en, this message translates to:
  /// **'Sorting schemes'**
  String get schemes;

  /// No description provided for @schemesSub.
  ///
  /// In en, this message translates to:
  /// **'Import, create, export, choose active scheme'**
  String get schemesSub;

  /// No description provided for @pinDirectory.
  ///
  /// In en, this message translates to:
  /// **'PIN directory'**
  String get pinDirectory;

  /// No description provided for @pinDirectorySub.
  ///
  /// In en, this message translates to:
  /// **'Offline all-India office list, update from CSV'**
  String get pinDirectorySub;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @favouritesSub.
  ///
  /// In en, this message translates to:
  /// **'Saved offices and PINs'**
  String get favouritesSub;

  /// No description provided for @airportCodes.
  ///
  /// In en, this message translates to:
  /// **'Airport codes'**
  String get airportCodes;

  /// No description provided for @airportCodesSub.
  ///
  /// In en, this message translates to:
  /// **'Public IATA code reference (not sorting rules)'**
  String get airportCodesSub;

  /// No description provided for @airportDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Public reference only. Air label codes always come from your office\'s imported air code sheet.'**
  String get airportDisclaimer;

  /// No description provided for @airportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'City, airport, code or state'**
  String get airportSearchHint;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSub.
  ///
  /// In en, this message translates to:
  /// **'Language, theme, keypad, read-out, haptics'**
  String get settingsSub;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSub.
  ///
  /// In en, this message translates to:
  /// **'Short guide'**
  String get helpSub;

  /// No description provided for @preparingDirectory.
  ///
  /// In en, this message translates to:
  /// **'Preparing offline PIN directory…'**
  String get preparingDirectory;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageDevice;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
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

  /// No description provided for @keypadSize.
  ///
  /// In en, this message translates to:
  /// **'Keypad size'**
  String get keypadSize;

  /// No description provided for @ttsSetting.
  ///
  /// In en, this message translates to:
  /// **'Read out bag / air code'**
  String get ttsSetting;

  /// No description provided for @ttsSettingSub.
  ///
  /// In en, this message translates to:
  /// **'Uses the phone\'s offline text-to-speech voice'**
  String get ttsSettingSub;

  /// No description provided for @hapticsSetting.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on each result'**
  String get hapticsSetting;

  /// No description provided for @mismatchFieldSetting.
  ///
  /// In en, this message translates to:
  /// **'Show \"place on address\" field'**
  String get mismatchFieldSetting;

  /// No description provided for @mismatchFieldSettingSub.
  ///
  /// In en, this message translates to:
  /// **'Checks PIN against the city/office written on the article'**
  String get mismatchFieldSettingSub;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Mail categories'**
  String get categories;

  /// No description provided for @categoriesSub.
  ///
  /// In en, this message translates to:
  /// **'Shown as the toggle on the Sort screen'**
  String get categoriesSub;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get addCategory;

  /// No description provided for @catLetters.
  ///
  /// In en, this message translates to:
  /// **'Ordinary/Letters'**
  String get catLetters;

  /// No description provided for @catParcel.
  ///
  /// In en, this message translates to:
  /// **'Parcel (surface)'**
  String get catParcel;

  /// No description provided for @catAirParcel.
  ///
  /// In en, this message translates to:
  /// **'Air Parcel'**
  String get catAirParcel;

  /// No description provided for @catSpeedPost.
  ///
  /// In en, this message translates to:
  /// **'Speed Post'**
  String get catSpeedPost;

  /// No description provided for @versionN.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionN(String version);

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyTitle;

  /// No description provided for @privacyText.
  ///
  /// In en, this message translates to:
  /// **'Everything works offline. No login, no ads, no analytics, no internet permission. Camera scans are processed on the phone and the photo is deleted immediately — nothing is stored or uploaded. Your schemes, sessions and progress stay only on this phone.'**
  String get privacyText;

  /// No description provided for @dataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dataTitle;

  /// No description provided for @schemeDataNote.
  ///
  /// In en, this message translates to:
  /// **'The app comes with a default Mangaluru TD / Non-TD scheme compiled from sorting lists shared by postal staff. You can edit or delete it, restore it, or import your own file. The SAMPLE scheme is fake demo data.'**
  String get schemeDataNote;

  /// No description provided for @licenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get licenceTitle;

  /// No description provided for @licenceText.
  ///
  /// In en, this message translates to:
  /// **'Free app. Airport codes are public IATA information.'**
  String get licenceText;

  /// No description provided for @openSourceLicences.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openSourceLicences;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @totalN.
  ///
  /// In en, this message translates to:
  /// **'Total: {count}'**
  String totalN(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get again;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @sheet.
  ///
  /// In en, this message translates to:
  /// **'Sheet'**
  String get sheet;

  /// No description provided for @validate.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get validate;

  /// No description provided for @catTD.
  ///
  /// In en, this message translates to:
  /// **'TD'**
  String get catTD;

  /// No description provided for @catNonTD.
  ///
  /// In en, this message translates to:
  /// **'Non-TD'**
  String get catNonTD;

  /// No description provided for @otherModeHint.
  ///
  /// In en, this message translates to:
  /// **'This PIN is in {mode}: {bag}'**
  String otherModeHint(String mode, String bag);

  /// No description provided for @navAir.
  ///
  /// In en, this message translates to:
  /// **'Air'**
  String get navAir;

  /// No description provided for @airFinderTitle.
  ///
  /// In en, this message translates to:
  /// **'Air code finder'**
  String get airFinderTitle;

  /// No description provided for @airSearchHint.
  ///
  /// In en, this message translates to:
  /// **'PIN, city or code (IXE)'**
  String get airSearchHint;

  /// No description provided for @airFinderHelp.
  ///
  /// In en, this message translates to:
  /// **'Type a 6-digit PIN to get the air code, or search by city, airport or 3-letter code.'**
  String get airFinderHelp;

  /// No description provided for @allAirports.
  ///
  /// In en, this message translates to:
  /// **'All airports ({count})'**
  String allAirports(int count);

  /// No description provided for @fromYourScheme.
  ///
  /// In en, this message translates to:
  /// **'From your office\'s air code list'**
  String get fromYourScheme;

  /// No description provided for @nearestAirport.
  ///
  /// In en, this message translates to:
  /// **'Nearest airport'**
  String get nearestAirport;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kmAway(String km);

  /// No description provided for @airRefNote.
  ///
  /// In en, this message translates to:
  /// **'Reference only (nearest airport to the post office). Import your office\'s air code list to use its codes.'**
  String get airRefNote;

  /// No description provided for @otherNearbyAirports.
  ///
  /// In en, this message translates to:
  /// **'Other nearby airports'**
  String get otherNearbyAirports;

  /// No description provided for @yourAirCodes.
  ///
  /// In en, this message translates to:
  /// **'Your air code list'**
  String get yourAirCodes;

  /// No description provided for @airportsInState.
  ///
  /// In en, this message translates to:
  /// **'Airports in {state}'**
  String airportsInState(String state);

  /// No description provided for @typeFullPinForAir.
  ///
  /// In en, this message translates to:
  /// **'Type all 6 digits of the PIN'**
  String get typeFullPinForAir;

  /// No description provided for @noAirportFound.
  ///
  /// In en, this message translates to:
  /// **'No airport found'**
  String get noAirportFound;

  /// No description provided for @restoreDefault.
  ///
  /// In en, this message translates to:
  /// **'Restore default Mangaluru scheme'**
  String get restoreDefault;

  /// No description provided for @defaultRestored.
  ///
  /// In en, this message translates to:
  /// **'Default scheme restored'**
  String get defaultRestored;

  /// No description provided for @legalTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer & privacy policy'**
  String get legalTitle;

  /// No description provided for @legalSub.
  ///
  /// In en, this message translates to:
  /// **'Independent tool · not an official app · offline'**
  String get legalSub;

  /// No description provided for @acceptLegal.
  ///
  /// In en, this message translates to:
  /// **'I understand'**
  String get acceptLegal;

  /// No description provided for @readFullPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read full policy'**
  String get readFullPolicy;

  /// No description provided for @legalH1.
  ///
  /// In en, this message translates to:
  /// **'Independent tool'**
  String get legalH1;

  /// No description provided for @legal1.
  ///
  /// In en, this message translates to:
  /// **'PO Sorting is an independent helper tool made for postal staff. It is not an official app of the Department of Posts / India Post, and it is not endorsed by, affiliated with or connected to the Department of Posts, the Ministry of Communications or the Government of India.'**
  String get legal1;

  /// No description provided for @legalH2.
  ///
  /// In en, this message translates to:
  /// **'No official branding'**
  String get legalH2;

  /// No description provided for @legal2.
  ///
  /// In en, this message translates to:
  /// **'The app does not use the India Post name, logo, colours or branding. Post office names and PIN codes are used only as public reference data.'**
  String get legal2;

  /// No description provided for @legalH3.
  ///
  /// In en, this message translates to:
  /// **'No warranty'**
  String get legalH3;

  /// No description provided for @legal3.
  ///
  /// In en, this message translates to:
  /// **'Sorting data, PIN details and airport codes are provided “as is” for convenience and may be outdated or wrong. Always follow your office\'s official sorting instructions, circulars and DMSL. The developer is not responsible for any mis-sort, delay, loss or other consequence of using this app.'**
  String get legal3;

  /// No description provided for @legalH4.
  ///
  /// In en, this message translates to:
  /// **'Your responsibility'**
  String get legalH4;

  /// No description provided for @legal4.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for the data you import, edit or share, and for following your department\'s rules on sharing internal documents.'**
  String get legal4;

  /// No description provided for @legalH5.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get legalH5;

  /// No description provided for @legal5.
  ///
  /// In en, this message translates to:
  /// **'The app works fully offline. It has no internet permission, no login, no ads, no analytics and no tracking. Camera scans are processed on the phone and deleted immediately; nothing is uploaded. Your schemes, favourites and settings stay only on your phone and are removed when you uninstall the app.'**
  String get legal5;

  /// No description provided for @legalH6.
  ///
  /// In en, this message translates to:
  /// **'Open data'**
  String get legalH6;

  /// No description provided for @legal6.
  ///
  /// In en, this message translates to:
  /// **'PIN directory: data.gov.in, Government of India, Open Government Data Licence – India. Airport codes are public IATA codes. The default Mangaluru scheme was compiled from lists shared by postal staff and may differ from your office\'s current scheme.'**
  String get legal6;

  /// No description provided for @legalH7.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get legalH7;

  /// No description provided for @legal7.
  ///
  /// In en, this message translates to:
  /// **'This policy may be updated with new versions of the app. By using the app you agree to this disclaimer and policy.'**
  String get legal7;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @backspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last digit'**
  String get backspace;

  /// No description provided for @voiceInput.
  ///
  /// In en, this message translates to:
  /// **'Voice input'**
  String get voiceInput;

  /// No description provided for @scanAddress.
  ///
  /// In en, this message translates to:
  /// **'Scan address'**
  String get scanAddress;

  /// No description provided for @checkPlace.
  ///
  /// In en, this message translates to:
  /// **'PIN vs place check'**
  String get checkPlace;

  /// No description provided for @placeOnAddress.
  ///
  /// In en, this message translates to:
  /// **'City / office on the address'**
  String get placeOnAddress;

  /// No description provided for @recentLookups.
  ///
  /// In en, this message translates to:
  /// **'Recent lookups'**
  String get recentLookups;

  /// No description provided for @sortHint.
  ///
  /// In en, this message translates to:
  /// **'Type a PIN on the keypad. The bag appears as you type.'**
  String get sortHint;

  /// No description provided for @bag.
  ///
  /// In en, this message translates to:
  /// **'Line / Bag'**
  String get bag;

  /// No description provided for @bags.
  ///
  /// In en, this message translates to:
  /// **'Lines / Bags'**
  String get bags;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @matchedBy.
  ///
  /// In en, this message translates to:
  /// **'Matched by {type}: {key}'**
  String matchedBy(String type, String key);

  /// No description provided for @likelyBag.
  ///
  /// In en, this message translates to:
  /// **'Likely bag (from prefix)'**
  String get likelyBag;

  /// No description provided for @possibleBags.
  ///
  /// In en, this message translates to:
  /// **'Possible bags'**
  String get possibleBags;

  /// No description provided for @sortingDistrictN.
  ///
  /// In en, this message translates to:
  /// **'Sorting district {code}'**
  String sortingDistrictN(String code);

  /// No description provided for @prefixNotInDirectory.
  ///
  /// In en, this message translates to:
  /// **'No offices with this prefix in the directory'**
  String get prefixNotInDirectory;

  /// No description provided for @pinNotInDirectory.
  ///
  /// In en, this message translates to:
  /// **'PIN not in directory – check the address'**
  String get pinNotInDirectory;

  /// No description provided for @invalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN (6 digits, first digit 1–9)'**
  String get invalidPin;

  /// No description provided for @noBagRule.
  ///
  /// In en, this message translates to:
  /// **'No bag rule for this PIN – check with supervisor'**
  String get noBagRule;

  /// No description provided for @deliveryOfficesN.
  ///
  /// In en, this message translates to:
  /// **'Delivery office(s): {count}'**
  String deliveryOfficesN(int count);

  /// No description provided for @andMore.
  ///
  /// In en, this message translates to:
  /// **'…and {count} more'**
  String andMore(int count);

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @nonDelivery.
  ///
  /// In en, this message translates to:
  /// **'Non-delivery'**
  String get nonDelivery;

  /// No description provided for @typeHO.
  ///
  /// In en, this message translates to:
  /// **'Head Office'**
  String get typeHO;

  /// No description provided for @typeSO.
  ///
  /// In en, this message translates to:
  /// **'Sub Office'**
  String get typeSO;

  /// No description provided for @typeBO.
  ///
  /// In en, this message translates to:
  /// **'Branch Office'**
  String get typeBO;

  /// No description provided for @typePO.
  ///
  /// In en, this message translates to:
  /// **'Post Office'**
  String get typePO;

  /// No description provided for @pinStructure.
  ///
  /// In en, this message translates to:
  /// **'PIN structure'**
  String get pinStructure;

  /// No description provided for @pinZone.
  ///
  /// In en, this message translates to:
  /// **'Postal zone'**
  String get pinZone;

  /// No description provided for @pinCircle.
  ///
  /// In en, this message translates to:
  /// **'Postal circle'**
  String get pinCircle;

  /// No description provided for @pinSortingDistrict.
  ///
  /// In en, this message translates to:
  /// **'Sorting district'**
  String get pinSortingDistrict;

  /// No description provided for @pinSortingDistrictHelp.
  ///
  /// In en, this message translates to:
  /// **'first 3 digits'**
  String get pinSortingDistrictHelp;

  /// No description provided for @pinDeliveryOffice.
  ///
  /// In en, this message translates to:
  /// **'Delivery post office'**
  String get pinDeliveryOffice;

  /// No description provided for @pinDeliveryOfficeHelp.
  ///
  /// In en, this message translates to:
  /// **'last 3 digits'**
  String get pinDeliveryOfficeHelp;

  /// No description provided for @airLabelCode.
  ///
  /// In en, this message translates to:
  /// **'Air label code'**
  String get airLabelCode;

  /// No description provided for @noAirCode.
  ///
  /// In en, this message translates to:
  /// **'No air code – check with supervisor'**
  String get noAirCode;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @via.
  ///
  /// In en, this message translates to:
  /// **'Via'**
  String get via;

  /// No description provided for @badgeAir.
  ///
  /// In en, this message translates to:
  /// **'AIR'**
  String get badgeAir;

  /// No description provided for @badgeSurface.
  ///
  /// In en, this message translates to:
  /// **'SURFACE'**
  String get badgeSurface;

  /// No description provided for @labelBadge.
  ///
  /// In en, this message translates to:
  /// **'Label colour: {text}'**
  String labelBadge(String text);

  /// No description provided for @labelBadgeShort.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelBadgeShort;

  /// No description provided for @connectivityDefaulted.
  ///
  /// In en, this message translates to:
  /// **'Connectivity not given in the rule – assumed Surface. Check with supervisor.'**
  String get connectivityDefaulted;

  /// No description provided for @connAir.
  ///
  /// In en, this message translates to:
  /// **'Air'**
  String get connAir;

  /// No description provided for @connSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get connSurface;

  /// No description provided for @hubRoute.
  ///
  /// In en, this message translates to:
  /// **'Parcel hub route'**
  String get hubRoute;

  /// No description provided for @directToL1.
  ///
  /// In en, this message translates to:
  /// **'Direct to L1 hub: {hub}'**
  String directToL1(String hub);

  /// No description provided for @noDmsl.
  ///
  /// In en, this message translates to:
  /// **'No DMSL imported for this scheme'**
  String get noDmsl;

  /// No description provided for @noHubRoute.
  ///
  /// In en, this message translates to:
  /// **'No hub rule for this PIN in the DMSL'**
  String get noHubRoute;

  /// No description provided for @dmslVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'DMSL {version}'**
  String dmslVersionLabel(String version);

  /// No description provided for @labelView.
  ///
  /// In en, this message translates to:
  /// **'Label view'**
  String get labelView;

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get shareImage;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'Share as text'**
  String get shareText;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @sayPin.
  ///
  /// In en, this message translates to:
  /// **'Say the PIN digits'**
  String get sayPin;

  /// No description provided for @voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this phone'**
  String get voiceUnavailable;

  /// No description provided for @unresolved.
  ///
  /// In en, this message translates to:
  /// **'Unresolved'**
  String get unresolved;

  /// No description provided for @noSchemeShort.
  ///
  /// In en, this message translates to:
  /// **'No sorting scheme yet'**
  String get noSchemeShort;

  /// No description provided for @importShort.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importShort;

  /// No description provided for @sampleShort.
  ///
  /// In en, this message translates to:
  /// **'Sample'**
  String get sampleShort;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'Type PIN'**
  String get pinHint;

  /// No description provided for @officeNameHint.
  ///
  /// In en, this message translates to:
  /// **'Office / line name'**
  String get officeNameHint;

  /// No description provided for @switchKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Numbers / letters keyboard'**
  String get switchKeyboard;

  /// No description provided for @noMatchingRules.
  ///
  /// In en, this message translates to:
  /// **'No rule in your scheme starts with this'**
  String get noMatchingRules;

  /// No description provided for @findPinHint.
  ///
  /// In en, this message translates to:
  /// **'Office, village, city, taluk or district'**
  String get findPinHint;

  /// No description provided for @findPinTip.
  ///
  /// In en, this message translates to:
  /// **'Type in English, ಕನ್ನಡ or हिन्दी. Spelling mistakes are fine: \"Puttoor\", \"Putur\" and \"ಪುತ್ತೂರು\" all find Puttur.'**
  String get findPinTip;

  /// No description provided for @allStates.
  ///
  /// In en, this message translates to:
  /// **'All states'**
  String get allStates;

  /// No description provided for @allDistricts.
  ///
  /// In en, this message translates to:
  /// **'All districts'**
  String get allDistricts;

  /// No description provided for @deliveryOnly.
  ///
  /// In en, this message translates to:
  /// **'Delivery offices only'**
  String get deliveryOnly;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No matching office found'**
  String get noResults;

  /// No description provided for @taluk.
  ///
  /// In en, this message translates to:
  /// **'Taluk'**
  String get taluk;

  /// No description provided for @division.
  ///
  /// In en, this message translates to:
  /// **'Division'**
  String get division;

  /// No description provided for @sortThisPin.
  ///
  /// In en, this message translates to:
  /// **'Sort this PIN'**
  String get sortThisPin;

  /// No description provided for @copyPin.
  ///
  /// In en, this message translates to:
  /// **'Copy PIN'**
  String get copyPin;

  /// No description provided for @addFavourite.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get addFavourite;

  /// No description provided for @removeFavourite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get removeFavourite;

  /// No description provided for @noFavourites.
  ///
  /// In en, this message translates to:
  /// **'No favourites yet. Add offices from Find PIN.'**
  String get noFavourites;

  /// No description provided for @mismatchChecker.
  ///
  /// In en, this message translates to:
  /// **'PIN ↔ place check'**
  String get mismatchChecker;

  /// No description provided for @mismatchCheckerSub.
  ///
  /// In en, this message translates to:
  /// **'Catch wrong PINs before missorting'**
  String get mismatchCheckerSub;

  /// No description provided for @mmMatch.
  ///
  /// In en, this message translates to:
  /// **'✅ Place matches this PIN'**
  String get mmMatch;

  /// No description provided for @mmSameDistrict.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Same district, but a different PIN'**
  String get mmSameDistrict;

  /// No description provided for @mmDifferent.
  ///
  /// In en, this message translates to:
  /// **'❌ Place is in a different district/state – likely wrong PIN'**
  String get mmDifferent;

  /// No description provided for @mmUnknownPlace.
  ///
  /// In en, this message translates to:
  /// **'Place not found in the directory – check spelling'**
  String get mmUnknownPlace;

  /// No description provided for @mmPinIs.
  ///
  /// In en, this message translates to:
  /// **'PIN {pin} is {office}'**
  String mmPinIs(String pin, String office);

  /// No description provided for @mmPlaceIs.
  ///
  /// In en, this message translates to:
  /// **'\"{place}\" is in {district}'**
  String mmPlaceIs(String place, String district);

  /// No description provided for @suggestedPins.
  ///
  /// In en, this message translates to:
  /// **'Suggested PINs:'**
  String get suggestedPins;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point at the address (with the PIN) and tap capture. Nothing is saved.'**
  String get scanHint;

  /// No description provided for @capture.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get capture;

  /// No description provided for @torch.
  ///
  /// In en, this message translates to:
  /// **'Torch'**
  String get torch;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available: {error}'**
  String cameraUnavailable(String error);

  /// No description provided for @noPinDetected.
  ///
  /// In en, this message translates to:
  /// **'No PIN found in the text – type it or search the place'**
  String get noPinDetected;

  /// No description provided for @detectedPin.
  ///
  /// In en, this message translates to:
  /// **'Detected PIN (edit if wrong)'**
  String get detectedPin;

  /// No description provided for @detectedPlace.
  ///
  /// In en, this message translates to:
  /// **'Detected city / office'**
  String get detectedPlace;

  /// No description provided for @useThisPin.
  ///
  /// In en, this message translates to:
  /// **'Use this PIN'**
  String get useThisPin;

  /// No description provided for @addToBulk.
  ///
  /// In en, this message translates to:
  /// **'Add to bulk count'**
  String get addToBulk;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan again'**
  String get scanAgain;

  /// No description provided for @scanPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Text is read on the phone with ML Kit (English / Latin script). The photo is deleted right after reading. For Kannada or Hindi addresses the PIN digits are used and you can search the place by hand.'**
  String get scanPrivacy;

  /// No description provided for @noOpenSession.
  ///
  /// In en, this message translates to:
  /// **'No bulk session in progress – start one in the Bulk tab'**
  String get noOpenSession;

  /// No description provided for @addedToBulk.
  ///
  /// In en, this message translates to:
  /// **'Added: {bag}'**
  String addedToBulk(String bag);

  /// No description provided for @bulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk sorting'**
  String get bulkTitle;

  /// No description provided for @bulkEmpty.
  ///
  /// In en, this message translates to:
  /// **'Count articles bag-wise: start a session, enter PINs quickly, then share the tally.'**
  String get bulkEmpty;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get startSession;

  /// No description provided for @sessionName.
  ///
  /// In en, this message translates to:
  /// **'Session name'**
  String get sessionName;

  /// No description provided for @sessionDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Session {time}'**
  String sessionDefaultName(String time);

  /// No description provided for @scheme.
  ///
  /// In en, this message translates to:
  /// **'Scheme'**
  String get scheme;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get inProgress;

  /// No description provided for @undoLast.
  ///
  /// In en, this message translates to:
  /// **'Undo last'**
  String get undoLast;

  /// No description provided for @endSession.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endSession;

  /// No description provided for @unresolvedEntries.
  ///
  /// In en, this message translates to:
  /// **'Unresolved / invalid: {count} (tap to fix)'**
  String unresolvedEntries(int count);

  /// No description provided for @fixEntry.
  ///
  /// In en, this message translates to:
  /// **'Fix \"{raw}\"'**
  String fixEntry(String raw);

  /// No description provided for @shareCsv.
  ///
  /// In en, this message translates to:
  /// **'Share CSV'**
  String get shareCsv;

  /// No description provided for @sharePrintable.
  ///
  /// In en, this message translates to:
  /// **'Share printable text file'**
  String get sharePrintable;

  /// No description provided for @continueSession.
  ///
  /// In en, this message translates to:
  /// **'Continue counting'**
  String get continueSession;

  /// No description provided for @learnNeedsScheme.
  ///
  /// In en, this message translates to:
  /// **'Practice uses the active scheme. Import your office scheme, or try the sample.'**
  String get learnNeedsScheme;

  /// No description provided for @learnFromScheme.
  ///
  /// In en, this message translates to:
  /// **'Questions come from this scheme'**
  String get learnFromScheme;

  /// No description provided for @flashcards.
  ///
  /// In en, this message translates to:
  /// **'Bag flashcards'**
  String get flashcards;

  /// No description provided for @flashcardsSub.
  ///
  /// In en, this message translates to:
  /// **'PIN → which bag? Spaced repetition'**
  String get flashcardsSub;

  /// No description provided for @timedQuiz.
  ///
  /// In en, this message translates to:
  /// **'Timed sorting quiz'**
  String get timedQuiz;

  /// No description provided for @timedQuizSub.
  ///
  /// In en, this message translates to:
  /// **'20 articles, 4 choices, score and speed'**
  String get timedQuizSub;

  /// No description provided for @airFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Air code flashcards'**
  String get airFlashcards;

  /// No description provided for @airFlashcardsSub.
  ///
  /// In en, this message translates to:
  /// **'PIN / district → air code'**
  String get airFlashcardsSub;

  /// No description provided for @airQuiz.
  ///
  /// In en, this message translates to:
  /// **'Air code quiz'**
  String get airQuiz;

  /// No description provided for @airQuizSub.
  ///
  /// In en, this message translates to:
  /// **'Needs an imported air code sheet'**
  String get airQuizSub;

  /// No description provided for @hubFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Parcel hub flashcards'**
  String get hubFlashcards;

  /// No description provided for @hubFlashcardsSub.
  ///
  /// In en, this message translates to:
  /// **'PIN → L2 / L1 hub from the active DMSL'**
  String get hubFlashcardsSub;

  /// No description provided for @weakAreas.
  ///
  /// In en, this message translates to:
  /// **'Weak areas'**
  String get weakAreas;

  /// No description provided for @weakAreasSub.
  ///
  /// In en, this message translates to:
  /// **'Bags and PIN series you get wrong most'**
  String get weakAreasSub;

  /// No description provided for @pinBasics.
  ///
  /// In en, this message translates to:
  /// **'PIN basics'**
  String get pinBasics;

  /// No description provided for @pinBasicsSub.
  ///
  /// In en, this message translates to:
  /// **'Zone, circle, sorting district, delivery office'**
  String get pinBasicsSub;

  /// No description provided for @noCards.
  ///
  /// In en, this message translates to:
  /// **'No cards: the scheme has no rules for this practice yet.'**
  String get noCards;

  /// No description provided for @flashDone.
  ///
  /// In en, this message translates to:
  /// **'Round done! Knew: {known}, didn\'t know: {unknown}'**
  String flashDone(int known, int unknown);

  /// No description provided for @leitnerBox.
  ///
  /// In en, this message translates to:
  /// **'Box {box} of 5'**
  String leitnerBox(int box);

  /// No description provided for @qWhichBagPin.
  ///
  /// In en, this message translates to:
  /// **'Which bag for PIN'**
  String get qWhichBagPin;

  /// No description provided for @qWhichBagPlace.
  ///
  /// In en, this message translates to:
  /// **'Which bag for'**
  String get qWhichBagPlace;

  /// No description provided for @qWhichAirCode.
  ///
  /// In en, this message translates to:
  /// **'Which air code for'**
  String get qWhichAirCode;

  /// No description provided for @qWhichHub.
  ///
  /// In en, this message translates to:
  /// **'Which parcel hub route for PIN'**
  String get qWhichHub;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @tapToFlip.
  ///
  /// In en, this message translates to:
  /// **'Tap the card to flip'**
  String get tapToFlip;

  /// No description provided for @showAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get showAnswer;

  /// No description provided for @knewIt.
  ///
  /// In en, this message translates to:
  /// **'I knew it'**
  String get knewIt;

  /// No description provided for @didntKnow.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t know'**
  String get didntKnow;

  /// No description provided for @scoreN.
  ///
  /// In en, this message translates to:
  /// **'Score {score}'**
  String scoreN(int score);

  /// No description provided for @quizScore.
  ///
  /// In en, this message translates to:
  /// **'{score} / {total}'**
  String quizScore(int score, int total);

  /// No description provided for @quizStats.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s · {apm} articles per minute'**
  String quizStats(int seconds, String apm);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Score history'**
  String get history;

  /// No description provided for @historyNeedsMore.
  ///
  /// In en, this message translates to:
  /// **'Take one more quiz to see a chart'**
  String get historyNeedsMore;

  /// No description provided for @noWeakAreas.
  ///
  /// In en, this message translates to:
  /// **'No mistakes recorded yet – practise first.'**
  String get noWeakAreas;

  /// No description provided for @weakBags.
  ///
  /// In en, this message translates to:
  /// **'Bags most often wrong'**
  String get weakBags;

  /// No description provided for @weakPrefixes.
  ///
  /// In en, this message translates to:
  /// **'PIN series most often wrong'**
  String get weakPrefixes;

  /// No description provided for @wrongTimes.
  ///
  /// In en, this message translates to:
  /// **'Wrong {count} times'**
  String wrongTimes(int count);

  /// No description provided for @quizzesTaken.
  ///
  /// In en, this message translates to:
  /// **'Quizzes taken: {count}'**
  String quizzesTaken(int count);

  /// No description provided for @averageScore.
  ///
  /// In en, this message translates to:
  /// **'Average score: {percent}%'**
  String averageScore(int percent);

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset progress'**
  String get resetProgress;

  /// No description provided for @resetProgressConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete quiz history, mistakes and flashcard boxes?'**
  String get resetProgressConfirm;

  /// No description provided for @pinBasicsIntro.
  ///
  /// In en, this message translates to:
  /// **'A PIN (Postal Index Number) has 6 digits. Each part narrows down where the article goes:'**
  String get pinBasicsIntro;

  /// No description provided for @pinBasicsDigits.
  ///
  /// In en, this message translates to:
  /// **'Digit 1 = postal zone/region. Digits 1–2 = postal circle. Digits 1–3 = sorting district (the sorting office handling the mail). Last 3 digits = the delivery post office. Example 574201: 5 = Southern zone, 57 = Karnataka, 574 = sorting district, 201 = delivery office.'**
  String get pinBasicsDigits;

  /// No description provided for @pinZones.
  ///
  /// In en, this message translates to:
  /// **'Zones (first digit)'**
  String get pinZones;

  /// No description provided for @circleTable.
  ///
  /// In en, this message translates to:
  /// **'Circles (first two digits)'**
  String get circleTable;

  /// No description provided for @pinBasicsNote.
  ///
  /// In en, this message translates to:
  /// **'Circle boundaries are approximate; some small circles share digits with neighbours (see the list above). Always follow your office\'s sorting scheme.'**
  String get pinBasicsNote;

  /// No description provided for @noSchemes.
  ///
  /// In en, this message translates to:
  /// **'No schemes yet. Import your office\'s sorting scheme (Excel/CSV), create one, or try the SAMPLE.'**
  String get noSchemes;

  /// No description provided for @schemesPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Schemes are department documents: they stay on this phone. Share only with your team.'**
  String get schemesPrivacy;

  /// No description provided for @importScheme.
  ///
  /// In en, this message translates to:
  /// **'Import scheme'**
  String get importScheme;

  /// No description provided for @importSchemeSub.
  ///
  /// In en, this message translates to:
  /// **'Excel (.xlsx) or CSV'**
  String get importSchemeSub;

  /// No description provided for @importAirCodes.
  ///
  /// In en, this message translates to:
  /// **'Import air code sheet'**
  String get importAirCodes;

  /// No description provided for @importDmsl.
  ///
  /// In en, this message translates to:
  /// **'Import DMSL (parcel hubs)'**
  String get importDmsl;

  /// No description provided for @createManually.
  ///
  /// In en, this message translates to:
  /// **'Create scheme in the app'**
  String get createManually;

  /// No description provided for @installSample.
  ///
  /// In en, this message translates to:
  /// **'Add SAMPLE scheme (not real)'**
  String get installSample;

  /// No description provided for @downloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download template'**
  String get downloadTemplate;

  /// No description provided for @downloadSampleFile.
  ///
  /// In en, this message translates to:
  /// **'Save SAMPLE scheme file'**
  String get downloadSampleFile;

  /// No description provided for @templateSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get templateSaved;

  /// No description provided for @newScheme.
  ///
  /// In en, this message translates to:
  /// **'New scheme'**
  String get newScheme;

  /// No description provided for @schemeName.
  ///
  /// In en, this message translates to:
  /// **'Scheme name'**
  String get schemeName;

  /// No description provided for @officeName.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get officeName;

  /// No description provided for @setActive.
  ///
  /// In en, this message translates to:
  /// **'Set as active'**
  String get setActive;

  /// No description provided for @exportXlsx.
  ///
  /// In en, this message translates to:
  /// **'Export / share as Excel'**
  String get exportXlsx;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export / share as CSV'**
  String get exportCsv;

  /// No description provided for @rules.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get rules;

  /// No description provided for @airCodes.
  ///
  /// In en, this message translates to:
  /// **'Air codes'**
  String get airCodes;

  /// No description provided for @rulesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} rules'**
  String rulesCount(int count);

  /// No description provided for @filterRules.
  ///
  /// In en, this message translates to:
  /// **'Filter rules'**
  String get filterRules;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get addRule;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit rule'**
  String get editRule;

  /// No description provided for @addBag.
  ///
  /// In en, this message translates to:
  /// **'Add bag'**
  String get addBag;

  /// No description provided for @editBag.
  ///
  /// In en, this message translates to:
  /// **'Edit bag'**
  String get editBag;

  /// No description provided for @deleteBagConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete bag {code} and all its rules?'**
  String deleteBagConfirm(String code);

  /// No description provided for @invalidRuleKey.
  ///
  /// In en, this message translates to:
  /// **'Check the PIN / range / prefix / name for this rule type'**
  String get invalidRuleKey;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @noAirCodes.
  ///
  /// In en, this message translates to:
  /// **'No air codes. Import your office\'s air code sheet (Air Parcel mode shows the code in big letters).'**
  String get noAirCodes;

  /// No description provided for @dmslHelp.
  ///
  /// In en, this message translates to:
  /// **'The Due Mail Sorting List maps PINs to L2 → L1 parcel hubs. Hub lists change (e.g. 7 Oct 2026 rationalisation), so import each new version; tap a version to make it active.'**
  String get dmslHelp;

  /// No description provided for @validFromDate.
  ///
  /// In en, this message translates to:
  /// **'valid from {date}'**
  String validFromDate(String date);

  /// No description provided for @compareWithPrevious.
  ///
  /// In en, this message translates to:
  /// **'Changes vs previous version'**
  String get compareWithPrevious;

  /// No description provided for @dmslChanges.
  ///
  /// In en, this message translates to:
  /// **'DMSL changes'**
  String get dmslChanges;

  /// No description provided for @dmslCompare.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}'**
  String dmslCompare(String from, String to);

  /// No description provided for @dmslChangedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} PINs changed hub'**
  String dmslChangedCount(int count);

  /// No description provided for @dmslNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No PIN changed hub between these versions.'**
  String get dmslNoChanges;

  /// No description provided for @practiseChanged.
  ///
  /// In en, this message translates to:
  /// **'Practise only the changed PINs'**
  String get practiseChanged;

  /// No description provided for @dmslVersionName.
  ///
  /// In en, this message translates to:
  /// **'Version name'**
  String get dmslVersionName;

  /// No description provided for @validFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get validFrom;

  /// No description provided for @stepFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get stepFile;

  /// No description provided for @stepPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get stepPreview;

  /// No description provided for @stepMapping.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get stepMapping;

  /// No description provided for @stepReport.
  ///
  /// In en, this message translates to:
  /// **'Check & save'**
  String get stepReport;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose Excel / CSV file'**
  String get chooseFile;

  /// No description provided for @importSchemeHelp.
  ///
  /// In en, this message translates to:
  /// **'One row per rule. Columns (any order, English/Kannada/Hindi headers): PIN, PIN From, PIN To, Prefix, Office, District, State, Bag No, Bag Name, Section, Remarks, Category, Connectivity (Air/Surface), Colour. A row with no PIN/office/district is the \"All other\" (default) bag.'**
  String get importSchemeHelp;

  /// No description provided for @importAirHelp.
  ///
  /// In en, this message translates to:
  /// **'Columns: PIN, PIN From, PIN To, Prefix, District, State, Air Code, Station, Via, Remarks. Codes are checked against the airport list; unknown codes are kept with a warning.'**
  String get importAirHelp;

  /// No description provided for @importDmslHelp.
  ///
  /// In en, this message translates to:
  /// **'Columns: PIN / PIN From / PIN To / Prefix / Office, L2 Hub, L1 Hub, Direct closure (Y/N), Connectivity (Air/Surface), Remarks. After import you see which PINs changed hub.'**
  String get importDmslHelp;

  /// No description provided for @importPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The file is read on the phone only.'**
  String get importPrivacy;

  /// No description provided for @headerRow.
  ///
  /// In en, this message translates to:
  /// **'Header row'**
  String get headerRow;

  /// No description provided for @previewRows.
  ///
  /// In en, this message translates to:
  /// **'Showing {shown} of {total} rows'**
  String previewRows(int shown, int total);

  /// No description provided for @mappingHelp.
  ///
  /// In en, this message translates to:
  /// **'Check which column holds each field. Auto-detected from the headers; change if wrong.'**
  String get mappingHelp;

  /// No description provided for @notMapped.
  ///
  /// In en, this message translates to:
  /// **'— not in file —'**
  String get notMapped;

  /// No description provided for @reportRulesOk.
  ///
  /// In en, this message translates to:
  /// **'{count} rules ready'**
  String reportRulesOk(int count);

  /// No description provided for @reportSummary.
  ///
  /// In en, this message translates to:
  /// **'{errors} rows skipped · {warnings} warnings'**
  String reportSummary(int errors, int warnings);

  /// No description provided for @bagsFound.
  ///
  /// In en, this message translates to:
  /// **'{count} bags found'**
  String bagsFound(int count);

  /// No description provided for @airReplaceNote.
  ///
  /// In en, this message translates to:
  /// **'Saving replaces this scheme\'s current air code table.'**
  String get airReplaceNote;

  /// No description provided for @rowN.
  ///
  /// In en, this message translates to:
  /// **'Row {row}'**
  String rowN(int row);

  /// No description provided for @saveRules.
  ///
  /// In en, this message translates to:
  /// **'Save {count}'**
  String saveRules(int count);

  /// No description provided for @importSaved.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} rules'**
  String importSaved(int count);

  /// No description provided for @issueBadPin.
  ///
  /// In en, this message translates to:
  /// **'Bad PIN / range / prefix'**
  String get issueBadPin;

  /// No description provided for @issueNoBag.
  ///
  /// In en, this message translates to:
  /// **'Row has no bag / code / hub'**
  String get issueNoBag;

  /// No description provided for @issueNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No PIN / office / district'**
  String get issueNoMatch;

  /// No description provided for @issueDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate rules'**
  String get issueDuplicate;

  /// No description provided for @issueConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflicting rules (same key, different result)'**
  String get issueConflict;

  /// No description provided for @issueOverlap.
  ///
  /// In en, this message translates to:
  /// **'Overlapping PIN ranges'**
  String get issueOverlap;

  /// No description provided for @issueNested.
  ///
  /// In en, this message translates to:
  /// **'Nested ranges (smaller wins)'**
  String get issueNested;

  /// No description provided for @issueUnknownAir.
  ///
  /// In en, this message translates to:
  /// **'Air codes not in airport list (kept)'**
  String get issueUnknownAir;

  /// No description provided for @issueNoConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity blank (Surface assumed)'**
  String get issueNoConnectivity;

  /// No description provided for @issueDefault.
  ///
  /// In en, this message translates to:
  /// **'Rows treated as \"All other\"'**
  String get issueDefault;

  /// No description provided for @issueBadColour.
  ///
  /// In en, this message translates to:
  /// **'Unknown colours'**
  String get issueBadColour;

  /// No description provided for @ruleExact.
  ///
  /// In en, this message translates to:
  /// **'Exact PIN'**
  String get ruleExact;

  /// No description provided for @ruleRange.
  ///
  /// In en, this message translates to:
  /// **'PIN range'**
  String get ruleRange;

  /// No description provided for @rulePrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix'**
  String get rulePrefix;

  /// No description provided for @ruleOffice.
  ///
  /// In en, this message translates to:
  /// **'Office name'**
  String get ruleOffice;

  /// No description provided for @ruleDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get ruleDistrict;

  /// No description provided for @ruleState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get ruleState;

  /// No description provided for @ruleDefault.
  ///
  /// In en, this message translates to:
  /// **'All other (default)'**
  String get ruleDefault;

  /// No description provided for @fType.
  ///
  /// In en, this message translates to:
  /// **'Rule type'**
  String get fType;

  /// No description provided for @fPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get fPin;

  /// No description provided for @fPinFrom.
  ///
  /// In en, this message translates to:
  /// **'PIN from'**
  String get fPinFrom;

  /// No description provided for @fPinTo.
  ///
  /// In en, this message translates to:
  /// **'PIN to'**
  String get fPinTo;

  /// No description provided for @fPrefix.
  ///
  /// In en, this message translates to:
  /// **'Prefix (first 1–5 digits)'**
  String get fPrefix;

  /// No description provided for @fOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get fOffice;

  /// No description provided for @fDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get fDistrict;

  /// No description provided for @fState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get fState;

  /// No description provided for @fBagCode.
  ///
  /// In en, this message translates to:
  /// **'Line / bag (e.g. Puttur Line, BANGALORE)'**
  String get fBagCode;

  /// No description provided for @fBagName.
  ///
  /// In en, this message translates to:
  /// **'Extra name (e.g. state)'**
  String get fBagName;

  /// No description provided for @fSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get fSection;

  /// No description provided for @fRemarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get fRemarks;

  /// No description provided for @fCategory.
  ///
  /// In en, this message translates to:
  /// **'Mail category'**
  String get fCategory;

  /// No description provided for @fConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity (Air/Surface)'**
  String get fConnectivity;

  /// No description provided for @fColour.
  ///
  /// In en, this message translates to:
  /// **'Bag colour'**
  String get fColour;

  /// No description provided for @fAirCode.
  ///
  /// In en, this message translates to:
  /// **'Air code'**
  String get fAirCode;

  /// No description provided for @fStation.
  ///
  /// In en, this message translates to:
  /// **'Air station'**
  String get fStation;

  /// No description provided for @fVia.
  ///
  /// In en, this message translates to:
  /// **'Via hub'**
  String get fVia;

  /// No description provided for @fL2Hub.
  ///
  /// In en, this message translates to:
  /// **'L2 hub'**
  String get fL2Hub;

  /// No description provided for @fL1Hub.
  ///
  /// In en, this message translates to:
  /// **'L1 hub'**
  String get fL1Hub;

  /// No description provided for @fDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct closure (Y/N)'**
  String get fDirect;

  /// No description provided for @changeBagHere.
  ///
  /// In en, this message translates to:
  /// **'Change line / bag for this PIN'**
  String get changeBagHere;

  /// No description provided for @editRuleX.
  ///
  /// In en, this message translates to:
  /// **'Edit rule: {rule}'**
  String editRuleX(String rule);

  /// No description provided for @savedSortingUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved – sorting updated'**
  String get savedSortingUpdated;

  /// No description provided for @moveRules.
  ///
  /// In en, this message translates to:
  /// **'Move rules to another line / bag'**
  String get moveRules;

  /// No description provided for @moveRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {count} rules from {bag}'**
  String moveRulesTitle(int count, String bag);

  /// No description provided for @moveTo.
  ///
  /// In en, this message translates to:
  /// **'New bag / line'**
  String get moveTo;

  /// No description provided for @removeOldBag.
  ///
  /// In en, this message translates to:
  /// **'Remove the empty old bag'**
  String get removeOldBag;

  /// No description provided for @rulesMoved.
  ///
  /// In en, this message translates to:
  /// **'{count} rules moved to {bag}'**
  String rulesMoved(int count, String bag);

  /// No description provided for @move.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get move;

  /// No description provided for @dirSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get dirSource;

  /// No description provided for @dirRows.
  ///
  /// In en, this message translates to:
  /// **'Offices'**
  String get dirRows;

  /// No description provided for @dirFileDate.
  ///
  /// In en, this message translates to:
  /// **'Data file date'**
  String get dirFileDate;

  /// No description provided for @dirBuilt.
  ///
  /// In en, this message translates to:
  /// **'Built on'**
  String get dirBuilt;

  /// No description provided for @dirStateFilter.
  ///
  /// In en, this message translates to:
  /// **'State filter'**
  String get dirStateFilter;

  /// No description provided for @dirSearchIndex.
  ///
  /// In en, this message translates to:
  /// **'Search index'**
  String get dirSearchIndex;

  /// No description provided for @dirPlaceholderWarning.
  ///
  /// In en, this message translates to:
  /// **'This is only a small test directory. Import the full \"All India Pincode Directory\" CSV from data.gov.in below.'**
  String get dirPlaceholderWarning;

  /// No description provided for @dirUpdateHelp.
  ///
  /// In en, this message translates to:
  /// **'Download the newer \"All India Pincode Directory\" CSV from data.gov.in on any computer or phone, copy it to this phone, then import it here. Leave the state empty for all of India.'**
  String get dirUpdateHelp;

  /// No description provided for @dirStateOnly.
  ///
  /// In en, this message translates to:
  /// **'Only this state (optional)'**
  String get dirStateOnly;

  /// No description provided for @updateDirectory.
  ///
  /// In en, this message translates to:
  /// **'Update PIN directory from CSV'**
  String get updateDirectory;

  /// No description provided for @dirParsing.
  ///
  /// In en, this message translates to:
  /// **'Reading and cleaning the CSV…'**
  String get dirParsing;

  /// No description provided for @dirWriting.
  ///
  /// In en, this message translates to:
  /// **'Building the offline database…'**
  String get dirWriting;

  /// No description provided for @directoryUpdated.
  ///
  /// In en, this message translates to:
  /// **'Directory updated: {count} offices'**
  String directoryUpdated(int count);

  /// No description provided for @help1Title.
  ///
  /// In en, this message translates to:
  /// **'Import your scheme'**
  String get help1Title;

  /// No description provided for @help1.
  ///
  /// In en, this message translates to:
  /// **'More → Sorting schemes → Add. Pick your office\'s Excel/CSV, check the columns and save. No file yet? Download the template, or try the SAMPLE scheme (fake data).'**
  String get help1;

  /// No description provided for @help2Title.
  ///
  /// In en, this message translates to:
  /// **'Sort by PIN'**
  String get help2Title;

  /// No description provided for @help2.
  ///
  /// In en, this message translates to:
  /// **'Type the PIN on the big keypad. After 3 digits you see the sorting district and likely bag; after 6 digits the final bag in its colour. Typing the next digit starts a new PIN. Long-press ⌫ to clear.'**
  String get help2;

  /// No description provided for @help3Title.
  ///
  /// In en, this message translates to:
  /// **'TD and Non-TD'**
  String get help3Title;

  /// No description provided for @help3.
  ///
  /// In en, this message translates to:
  /// **'Choose TD or Non-TD at the top of the Sort screen. Each rule in your scheme can be marked TD or Non-TD in the Category column (blank = both). If a PIN only has a rule in the other mode, the app tells you which mode and bag.'**
  String get help3;

  /// No description provided for @help4Title.
  ///
  /// In en, this message translates to:
  /// **'No PIN on the article?'**
  String get help4Title;

  /// No description provided for @help4.
  ///
  /// In en, this message translates to:
  /// **'Find PIN: type the office, village, city, taluk or district in English, Kannada or Hindi. Spelling mistakes are tolerated. Each result shows its bag.'**
  String get help4;

  /// No description provided for @help5Title.
  ///
  /// In en, this message translates to:
  /// **'Catch wrong PINs'**
  String get help5Title;

  /// No description provided for @help5.
  ///
  /// In en, this message translates to:
  /// **'Turn on the place check (✓ icon on Sort) and type the city written on the article. ✅ match, ⚠️ same district but different PIN, ❌ different district/state – with suggested PINs.'**
  String get help5;

  /// No description provided for @help6Title.
  ///
  /// In en, this message translates to:
  /// **'Scan the address'**
  String get help6Title;

  /// No description provided for @help6.
  ///
  /// In en, this message translates to:
  /// **'Tap the scan icon, point the camera at the address and capture. The PIN and city are read on the phone; the photo is deleted immediately.'**
  String get help6;

  /// No description provided for @help7Title.
  ///
  /// In en, this message translates to:
  /// **'Count articles per bag'**
  String get help7Title;

  /// No description provided for @help7.
  ///
  /// In en, this message translates to:
  /// **'Bulk → Start session. Enter PINs one after another; each one flashes its bag colour and adds to the count. Undo the last entry, fix unresolved ones, then share the summary to tally with the manifest.'**
  String get help7;

  /// No description provided for @help8Title.
  ///
  /// In en, this message translates to:
  /// **'Practise'**
  String get help8Title;

  /// No description provided for @help8.
  ///
  /// In en, this message translates to:
  /// **'Learn: flashcards with spaced repetition, a timed 20-article quiz, weak areas, and a PIN basics lesson. After a new DMSL, practise only the PINs whose hub changed.'**
  String get help8;

  /// No description provided for @help9Title.
  ///
  /// In en, this message translates to:
  /// **'Sorting changed? Edit it'**
  String get help9Title;

  /// No description provided for @help9.
  ///
  /// In en, this message translates to:
  /// **'On the Sort screen tap “Change bag for this PIN” to fix one PIN. For bigger changes open More → Schemes → your scheme: edit, add or delete rules, and in Bags use “Move rules to another bag” when an office moves to a new line. Export the scheme to share it with colleagues.'**
  String get help9;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'kn'].contains(locale.languageCode);

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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('kn'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In kn, this message translates to:
  /// **'KSPSTADK'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In kn, this message translates to:
  /// **'ಶಿಕ್ಷಕರ ಸೇವೆಯೇ ಸಂಘದ ಗುರಿ'**
  String get appSubtitle;

  /// No description provided for @navHome.
  ///
  /// In kn, this message translates to:
  /// **'ಮುಖಪುಟ'**
  String get navHome;

  /// No description provided for @navBrowse.
  ///
  /// In kn, this message translates to:
  /// **'ವಿಭಾಗಗಳು'**
  String get navBrowse;

  /// No description provided for @navDownloads.
  ///
  /// In kn, this message translates to:
  /// **'ಡೌನ್‌ಲೋಡ್'**
  String get navDownloads;

  /// No description provided for @navSearch.
  ///
  /// In kn, this message translates to:
  /// **'ಹುಡುಕಿ'**
  String get navSearch;

  /// No description provided for @navMore.
  ///
  /// In kn, this message translates to:
  /// **'ಇನ್ನಷ್ಟು'**
  String get navMore;

  /// No description provided for @greeting.
  ///
  /// In kn, this message translates to:
  /// **'ನಮಸ್ಕಾರ, ಶಿಕ್ಷಕರೇ 🙏'**
  String get greeting;

  /// No description provided for @homeTagline.
  ///
  /// In kn, this message translates to:
  /// **'ಅಧ್ಯಯನ ಸಾಮಗ್ರಿ, LBA ಪ್ರಶ್ನಾ ಕೋಶ, ಆದೇಶಗಳು — ಒಂದೇ ಕಡೆ'**
  String get homeTagline;

  /// No description provided for @searchHint.
  ///
  /// In kn, this message translates to:
  /// **'ಪೋಸ್ಟ್, ಪಾಠ, ವಿಷಯ ಹುಡುಕಿ…'**
  String get searchHint;

  /// No description provided for @latest.
  ///
  /// In kn, this message translates to:
  /// **'ಇತ್ತೀಚಿನವು'**
  String get latest;

  /// No description provided for @quickAccess.
  ///
  /// In kn, this message translates to:
  /// **'ತ್ವರಿತ ಪ್ರವೇಶ'**
  String get quickAccess;

  /// No description provided for @classes.
  ///
  /// In kn, this message translates to:
  /// **'ತರಗತಿಗಳು'**
  String get classes;

  /// No description provided for @continueReading.
  ///
  /// In kn, this message translates to:
  /// **'ಓದು ಮುಂದುವರಿಸಿ'**
  String get continueReading;

  /// No description provided for @popularDownloads.
  ///
  /// In kn, this message translates to:
  /// **'ಜನಪ್ರಿಯ ಡೌನ್‌ಲೋಡ್‌ಗಳು'**
  String get popularDownloads;

  /// No description provided for @seeAll.
  ///
  /// In kn, this message translates to:
  /// **'ಎಲ್ಲಾ ನೋಡಿ'**
  String get seeAll;

  /// No description provided for @joinTitle.
  ///
  /// In kn, this message translates to:
  /// **'ಶಿಕ್ಷಕರ ಗುಂಪಿಗೆ ಸೇರಿ'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In kn, this message translates to:
  /// **'ಹೊಸ ಮಾಹಿತಿ ತಕ್ಷಣ ನಿಮ್ಮ ಮೊಬೈಲ್‌ಗೆ'**
  String get joinSubtitle;

  /// No description provided for @joinWhatsapp.
  ///
  /// In kn, this message translates to:
  /// **'WhatsApp ಗುಂಪು'**
  String get joinWhatsapp;

  /// No description provided for @joinTelegram.
  ///
  /// In kn, this message translates to:
  /// **'Telegram ಚಾನೆಲ್'**
  String get joinTelegram;

  /// No description provided for @offlineBanner.
  ///
  /// In kn, this message translates to:
  /// **'ಇಂಟರ್ನೆಟ್ ಇಲ್ಲ — ಉಳಿಸಿದ ವಿಷಯ ತೋರಿಸಲಾಗುತ್ತಿದೆ'**
  String get offlineBanner;

  /// No description provided for @retry.
  ///
  /// In kn, this message translates to:
  /// **'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In kn, this message translates to:
  /// **'ಏನೋ ತಪ್ಪಾಗಿದೆ. ದಯವಿಟ್ಟು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In kn, this message translates to:
  /// **'ಇಂಟರ್ನೆಟ್ ಸಂಪರ್ಕ ಇಲ್ಲ'**
  String get errorOffline;

  /// No description provided for @errorOfflineHint.
  ///
  /// In kn, this message translates to:
  /// **'ಸಂಪರ್ಕ ಪರಿಶೀಲಿಸಿ ಮತ್ತು ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ. ಉಳಿಸಿದ ಪೋಸ್ಟ್‌ಗಳು ಮತ್ತು PDF ಗಳು ಆಫ್‌ಲೈನ್‌ನಲ್ಲೂ ಲಭ್ಯ.'**
  String get errorOfflineHint;

  /// No description provided for @emptyPosts.
  ///
  /// In kn, this message translates to:
  /// **'ಇಲ್ಲಿ ಇನ್ನೂ ಯಾವುದೇ ಪೋಸ್ಟ್ ಇಲ್ಲ'**
  String get emptyPosts;

  /// No description provided for @share.
  ///
  /// In kn, this message translates to:
  /// **'ಹಂಚಿಕೊಳ್ಳಿ'**
  String get share;

  /// No description provided for @bookmark.
  ///
  /// In kn, this message translates to:
  /// **'ಉಳಿಸಿ'**
  String get bookmark;

  /// No description provided for @bookmarked.
  ///
  /// In kn, this message translates to:
  /// **'ಉಳಿಸಲಾಗಿದೆ'**
  String get bookmarked;

  /// No description provided for @bookmarkAdded.
  ///
  /// In kn, this message translates to:
  /// **'ಬುಕ್‌ಮಾರ್ಕ್‌ಗೆ ಸೇರಿಸಲಾಗಿದೆ — ಆಫ್‌ಲೈನ್‌ನಲ್ಲೂ ಓದಬಹುದು'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In kn, this message translates to:
  /// **'ಬುಕ್‌ಮಾರ್ಕ್ ತೆಗೆಯಲಾಗಿದೆ'**
  String get bookmarkRemoved;

  /// No description provided for @relatedPosts.
  ///
  /// In kn, this message translates to:
  /// **'ಇವುಗಳನ್ನೂ ಓದಿ'**
  String get relatedPosts;

  /// No description provided for @questions.
  ///
  /// In kn, this message translates to:
  /// **'ಪ್ರಶ್ನೆಗಳು'**
  String get questions;

  /// No description provided for @answers.
  ///
  /// In kn, this message translates to:
  /// **'ಉತ್ತರಗಳು'**
  String get answers;

  /// No description provided for @open.
  ///
  /// In kn, this message translates to:
  /// **'ತೆರೆಯಿರಿ'**
  String get open;

  /// No description provided for @download.
  ///
  /// In kn, this message translates to:
  /// **'ಡೌನ್‌ಲೋಡ್'**
  String get download;

  /// No description provided for @downloading.
  ///
  /// In kn, this message translates to:
  /// **'ಡೌನ್‌ಲೋಡ್ ಆಗುತ್ತಿದೆ…'**
  String get downloading;

  /// No description provided for @savedOffline.
  ///
  /// In kn, this message translates to:
  /// **'ಆಫ್‌ಲೈನ್‌ಗೆ ಉಳಿಸಲಾಗಿದೆ'**
  String get savedOffline;

  /// No description provided for @downloadFailed.
  ///
  /// In kn, this message translates to:
  /// **'ಡೌನ್‌ಲೋಡ್ ವಿಫಲವಾಗಿದೆ'**
  String get downloadFailed;

  /// No description provided for @downloadNotPublic.
  ///
  /// In kn, this message translates to:
  /// **'ಈ ಫೈಲ್ ಸಾರ್ವಜನಿಕವಾಗಿಲ್ಲ ಅಥವಾ ತುಂಬಾ ದೊಡ್ಡದು. ಬ್ರೌಸರ್‌ನಲ್ಲಿ ತೆರೆಯಿರಿ.'**
  String get downloadNotPublic;

  /// No description provided for @openInBrowser.
  ///
  /// In kn, this message translates to:
  /// **'ಬ್ರೌಸರ್‌ನಲ್ಲಿ ತೆರೆಯಿರಿ'**
  String get openInBrowser;

  /// No description provided for @playVideo.
  ///
  /// In kn, this message translates to:
  /// **'ವಿಡಿಯೋ ನೋಡಿ'**
  String get playVideo;

  /// No description provided for @openTool.
  ///
  /// In kn, this message translates to:
  /// **'ಉಪಕರಣ ತೆರೆಯಿರಿ'**
  String get openTool;

  /// No description provided for @interactiveNotice.
  ///
  /// In kn, this message translates to:
  /// **'ಈ ಪುಟದಲ್ಲಿ ಆನ್‌ಲೈನ್ ಉಪಕರಣವಿದೆ. ಬಳಸಲು ಕೆಳಗಿನ ಬಟನ್ ಒತ್ತಿರಿ.'**
  String get interactiveNotice;

  /// No description provided for @files.
  ///
  /// In kn, this message translates to:
  /// **'ಫೈಲ್‌ಗಳು'**
  String get files;

  /// No description provided for @allSubjects.
  ///
  /// In kn, this message translates to:
  /// **'ಎಲ್ಲಾ ವಿಷಯಗಳು'**
  String get allSubjects;

  /// No description provided for @subjects.
  ///
  /// In kn, this message translates to:
  /// **'ವಿಷಯಗಳು'**
  String get subjects;

  /// No description provided for @allPosts.
  ///
  /// In kn, this message translates to:
  /// **'ಎಲ್ಲಾ ಪೋಸ್ಟ್‌ಗಳು'**
  String get allPosts;

  /// No description provided for @allCategories.
  ///
  /// In kn, this message translates to:
  /// **'ಎಲ್ಲಾ ವಿಭಾಗಗಳು'**
  String get allCategories;

  /// No description provided for @sections.
  ///
  /// In kn, this message translates to:
  /// **'ವಿಭಾಗಗಳು'**
  String get sections;

  /// No description provided for @moreCategories.
  ///
  /// In kn, this message translates to:
  /// **'ಇತರ ವಿಭಾಗಗಳು'**
  String get moreCategories;

  /// No description provided for @other.
  ///
  /// In kn, this message translates to:
  /// **'ಇತರೆ'**
  String get other;

  /// No description provided for @myDownloads.
  ///
  /// In kn, this message translates to:
  /// **'ನನ್ನ ಡೌನ್‌ಲೋಡ್‌ಗಳು'**
  String get myDownloads;

  /// No description provided for @delete.
  ///
  /// In kn, this message translates to:
  /// **'ಅಳಿಸಿ'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In kn, this message translates to:
  /// **'ರದ್ದುಮಾಡಿ'**
  String get cancel;

  /// No description provided for @noDownloads.
  ///
  /// In kn, this message translates to:
  /// **'ಇನ್ನೂ ಯಾವುದೇ ಡೌನ್‌ಲೋಡ್ ಇಲ್ಲ'**
  String get noDownloads;

  /// No description provided for @noDownloadsHint.
  ///
  /// In kn, this message translates to:
  /// **'ಯಾವುದೇ ಪೋಸ್ಟ್‌ನಲ್ಲಿ PDF ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ — ಇಲ್ಲಿ ಇಂಟರ್ನೆಟ್ ಇಲ್ಲದೆಯೂ ಸಿಗುತ್ತದೆ.'**
  String get noDownloadsHint;

  /// No description provided for @searchDownloads.
  ///
  /// In kn, this message translates to:
  /// **'ಡೌನ್‌ಲೋಡ್‌ಗಳಲ್ಲಿ ಹುಡುಕಿ'**
  String get searchDownloads;

  /// No description provided for @recentSearches.
  ///
  /// In kn, this message translates to:
  /// **'ಇತ್ತೀಚಿನ ಹುಡುಕಾಟಗಳು'**
  String get recentSearches;

  /// No description provided for @clear.
  ///
  /// In kn, this message translates to:
  /// **'ಅಳಿಸಿ'**
  String get clear;

  /// No description provided for @filterAll.
  ///
  /// In kn, this message translates to:
  /// **'ಎಲ್ಲಾ'**
  String get filterAll;

  /// No description provided for @noResults.
  ///
  /// In kn, this message translates to:
  /// **'ಯಾವುದೇ ಫಲಿತಾಂಶ ಸಿಗಲಿಲ್ಲ'**
  String get noResults;

  /// No description provided for @searchPrompt.
  ///
  /// In kn, this message translates to:
  /// **'ತರಗತಿ, ವಿಷಯ ಅಥವಾ ಪಾಠದ ಹೆಸರು ಟೈಪ್ ಮಾಡಿ'**
  String get searchPrompt;

  /// No description provided for @bookmarks.
  ///
  /// In kn, this message translates to:
  /// **'ಬುಕ್‌ಮಾರ್ಕ್‌ಗಳು'**
  String get bookmarks;

  /// No description provided for @noBookmarks.
  ///
  /// In kn, this message translates to:
  /// **'ಉಳಿಸಿದ ಪೋಸ್ಟ್‌ಗಳಿಲ್ಲ'**
  String get noBookmarks;

  /// No description provided for @noBookmarksHint.
  ///
  /// In kn, this message translates to:
  /// **'ಪೋಸ್ಟ್‌ನಲ್ಲಿ 🔖 ಒತ್ತಿ — ಆಫ್‌ಲೈನ್‌ನಲ್ಲೂ ಓದಬಹುದು.'**
  String get noBookmarksHint;

  /// No description provided for @quizzes.
  ///
  /// In kn, this message translates to:
  /// **'ರಸಪ್ರಶ್ನೆಗಳು'**
  String get quizzes;

  /// No description provided for @tools.
  ///
  /// In kn, this message translates to:
  /// **'KSPSTADK ಉಪಕರಣಗಳು'**
  String get tools;

  /// No description provided for @toolsSubtitle.
  ///
  /// In kn, this message translates to:
  /// **'ಉಚಿತ ಶಾಲಾ ಆನ್‌ಲೈನ್ ಉಪಕರಣಗಳು'**
  String get toolsSubtitle;

  /// No description provided for @notifications.
  ///
  /// In kn, this message translates to:
  /// **'ಅಧಿಸೂಚನೆಗಳು'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In kn, this message translates to:
  /// **'ಇನ್ನೂ ಯಾವುದೇ ಅಧಿಸೂಚನೆ ಇಲ್ಲ'**
  String get noNotifications;

  /// No description provided for @noNotificationsHint.
  ///
  /// In kn, this message translates to:
  /// **'ಹೊಸ ಪೋಸ್ಟ್ ಪ್ರಕಟವಾದಾಗ ಇಲ್ಲಿ ಕಾಣಿಸುತ್ತದೆ.'**
  String get noNotificationsHint;

  /// No description provided for @settings.
  ///
  /// In kn, this message translates to:
  /// **'ಸೆಟ್ಟಿಂಗ್‌ಗಳು'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In kn, this message translates to:
  /// **'ಭಾಷೆ'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In kn, this message translates to:
  /// **'ಥೀಮ್'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In kn, this message translates to:
  /// **'ಸಿಸ್ಟಮ್'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In kn, this message translates to:
  /// **'ಬೆಳಕು'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In kn, this message translates to:
  /// **'ಕತ್ತಲೆ'**
  String get themeDark;

  /// No description provided for @notificationTopics.
  ///
  /// In kn, this message translates to:
  /// **'ಅಧಿಸೂಚನೆ ವಿಷಯಗಳು'**
  String get notificationTopics;

  /// No description provided for @notificationsUnavailable.
  ///
  /// In kn, this message translates to:
  /// **'ಅಧಿಸೂಚನೆಗಳನ್ನು ಇನ್ನೂ ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿಲ್ಲ'**
  String get notificationsUnavailable;

  /// No description provided for @topicAll.
  ///
  /// In kn, this message translates to:
  /// **'ಎಲ್ಲಾ ಹೊಸ ಪೋಸ್ಟ್‌ಗಳು'**
  String get topicAll;

  /// No description provided for @topicLba.
  ///
  /// In kn, this message translates to:
  /// **'LBA ಪ್ರಶ್ನಾ ಕೋಶ'**
  String get topicLba;

  /// No description provided for @topicInfo.
  ///
  /// In kn, this message translates to:
  /// **'ಮಾಹಿತಿ / ಆದೇಶ / ಸುತ್ತೋಲೆ'**
  String get topicInfo;

  /// No description provided for @topicStudy.
  ///
  /// In kn, this message translates to:
  /// **'ಅಧ್ಯಯನ ಸಾಮಗ್ರಿ'**
  String get topicStudy;

  /// No description provided for @topicQuiz.
  ///
  /// In kn, this message translates to:
  /// **'ರಸಪ್ರಶ್ನೆ'**
  String get topicQuiz;

  /// No description provided for @clearCache.
  ///
  /// In kn, this message translates to:
  /// **'ಕ್ಯಾಶ್ ಅಳಿಸಿ'**
  String get clearCache;

  /// No description provided for @cacheCleared.
  ///
  /// In kn, this message translates to:
  /// **'ಕ್ಯಾಶ್ ಅಳಿಸಲಾಗಿದೆ'**
  String get cacheCleared;

  /// No description provided for @storage.
  ///
  /// In kn, this message translates to:
  /// **'ಸಂಗ್ರಹಣೆ'**
  String get storage;

  /// No description provided for @rateApp.
  ///
  /// In kn, this message translates to:
  /// **'ಆ್ಯಪ್‌ಗೆ ರೇಟಿಂಗ್ ನೀಡಿ'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In kn, this message translates to:
  /// **'ಆ್ಯಪ್ ಹಂಚಿಕೊಳ್ಳಿ'**
  String get shareApp;

  /// No description provided for @about.
  ///
  /// In kn, this message translates to:
  /// **'KSPSTADK ಬಗ್ಗೆ'**
  String get about;

  /// No description provided for @contact.
  ///
  /// In kn, this message translates to:
  /// **'ಸಂಪರ್ಕಿಸಿ'**
  String get contact;

  /// No description provided for @privacyPolicy.
  ///
  /// In kn, this message translates to:
  /// **'ಗೌಪ್ಯತಾ ನೀತಿ'**
  String get privacyPolicy;

  /// No description provided for @licences.
  ///
  /// In kn, this message translates to:
  /// **'ಮುಕ್ತ ಮೂಲ ಪರವಾನಗಿಗಳು'**
  String get licences;

  /// No description provided for @appearance.
  ///
  /// In kn, this message translates to:
  /// **'ನೋಟ'**
  String get appearance;

  /// No description provided for @general.
  ///
  /// In kn, this message translates to:
  /// **'ಸಾಮಾನ್ಯ'**
  String get general;

  /// No description provided for @nightMode.
  ///
  /// In kn, this message translates to:
  /// **'ರಾತ್ರಿ ಮೋಡ್'**
  String get nightMode;

  /// No description provided for @goToPage.
  ///
  /// In kn, this message translates to:
  /// **'ಪುಟಕ್ಕೆ ಹೋಗಿ'**
  String get goToPage;

  /// No description provided for @go.
  ///
  /// In kn, this message translates to:
  /// **'ಹೋಗಿ'**
  String get go;

  /// No description provided for @pdfLoadFailed.
  ///
  /// In kn, this message translates to:
  /// **'PDF ತೆರೆಯಲು ಆಗಲಿಲ್ಲ'**
  String get pdfLoadFailed;

  /// No description provided for @viewOnSite.
  ///
  /// In kn, this message translates to:
  /// **'ವೆಬ್‌ಸೈಟ್‌ನಲ್ಲಿ ನೋಡಿ'**
  String get viewOnSite;

  /// No description provided for @saveOffline.
  ///
  /// In kn, this message translates to:
  /// **'ಆಫ್‌ಲೈನ್‌ಗೆ ಉಳಿಸಿ'**
  String get saveOffline;

  /// No description provided for @kannada.
  ///
  /// In kn, this message translates to:
  /// **'ಕನ್ನಡ'**
  String get kannada;

  /// No description provided for @english.
  ///
  /// In kn, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @today.
  ///
  /// In kn, this message translates to:
  /// **'ಇಂದು'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In kn, this message translates to:
  /// **'ನಿನ್ನೆ'**
  String get yesterday;

  /// No description provided for @contentWarning.
  ///
  /// In kn, this message translates to:
  /// **'ಈ ಆ್ಯಪ್ ಯಾವುದೇ ಸರ್ಕಾರಿ ಸಂಸ್ಥೆಯೊಂದಿಗೆ ಸಂಬಂಧ ಹೊಂದಿಲ್ಲ. ಮಾಹಿತಿ kspstadk.com ನಿಂದ.'**
  String get contentWarning;

  /// No description provided for @aboutText.
  ///
  /// In kn, this message translates to:
  /// **'KSPSTADK — ಕರ್ನಾಟಕದ ಶಿಕ್ಷಕರಿಗಾಗಿ ಅಧ್ಯಯನ ಸಾಮಗ್ರಿ, LBA ಪ್ರಶ್ನಾ ಕೋಶಗಳು, PDF ಗಳು, ಆದೇಶಗಳು ಮತ್ತು ರಸಪ್ರಶ್ನೆಗಳ ಕನ್ನಡ ತಾಣ. ಈ ಆ್ಯಪ್ kspstadk.com ನ ವಿಷಯವನ್ನು ನೇರವಾಗಿ ತೋರಿಸುತ್ತದೆ.'**
  String get aboutText;

  /// No description provided for @updatedAgo.
  ///
  /// In kn, this message translates to:
  /// **'ಕೊನೆಯ ನವೀಕರಣ: {time}'**
  String updatedAgo(String time);

  /// No description provided for @readingTime.
  ///
  /// In kn, this message translates to:
  /// **'{minutes} ನಿಮಿಷ ಓದು'**
  String readingTime(int minutes);

  /// No description provided for @classN.
  ///
  /// In kn, this message translates to:
  /// **'{n} ನೇ ತರಗತಿ'**
  String classN(int n);

  /// No description provided for @postsCount.
  ///
  /// In kn, this message translates to:
  /// **'{count} ಪೋಸ್ಟ್‌ಗಳು'**
  String postsCount(int count);

  /// No description provided for @filesCount.
  ///
  /// In kn, this message translates to:
  /// **'{count} ಫೈಲ್‌ಗಳು'**
  String filesCount(int count);

  /// No description provided for @storageUsed.
  ///
  /// In kn, this message translates to:
  /// **'ಬಳಸಿದ ಸ್ಥಳ: {size}'**
  String storageUsed(String size);

  /// No description provided for @deleteConfirm.
  ///
  /// In kn, this message translates to:
  /// **'\"{name}\" ಅಳಿಸಬೇಕೇ?'**
  String deleteConfirm(String name);

  /// No description provided for @pageOf.
  ///
  /// In kn, this message translates to:
  /// **'{page} / {total}'**
  String pageOf(int page, int total);

  /// No description provided for @shareAppText.
  ///
  /// In kn, this message translates to:
  /// **'ಶಿಕ್ಷಕರಿಗಾಗಿ KSPSTADK ಆ್ಯಪ್ — ಅಧ್ಯಯನ ಸಾಮಗ್ರಿ, LBA ಪ್ರಶ್ನಾ ಕೋಶ, ಆದೇಶಗಳು: {url}'**
  String shareAppText(String url);

  /// No description provided for @sharePostText.
  ///
  /// In kn, this message translates to:
  /// **'{title}\n\nಇನ್ನಷ್ಟು ಓದಿ 👉 {url}\n\n— KSPSTADK'**
  String sharePostText(String title, String url);

  /// No description provided for @lessonN.
  ///
  /// In kn, this message translates to:
  /// **'ಪಾಠ {n}'**
  String lessonN(String n);

  /// No description provided for @version.
  ///
  /// In kn, this message translates to:
  /// **'ಆವೃತ್ತಿ {version}'**
  String version(String version);
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
      <String>['en', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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

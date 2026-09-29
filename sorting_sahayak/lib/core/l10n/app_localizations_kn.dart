// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get appTitle => 'ಸಾರ್ಟಿಂಗ್ ಸಹಾಯಕ';

  @override
  String get navSort => 'ಸಾರ್ಟ್';

  @override
  String get navFindPin => 'ಪಿನ್ ಹುಡುಕಿ';

  @override
  String get navBulk => 'ಗುಂಪು';

  @override
  String get navLearn => 'ಅಭ್ಯಾಸ';

  @override
  String get navMore => 'ಇನ್ನಷ್ಟು';

  @override
  String get disclaimer =>
      'ಅಂಚೆ ಸಿಬ್ಬಂದಿಗಾಗಿ ಸ್ವತಂತ್ರ ಸಹಾಯಕ ಸಾಧನ. ಇದು ಅಂಚೆ ಇಲಾಖೆಯ ಅಧಿಕೃತ ಆ್ಯಪ್ ಅಲ್ಲ.';

  @override
  String get dataCredit =>
      'ಪಿನ್ ಮಾಹಿತಿ: data.gov.in, ಭಾರತ ಸರ್ಕಾರ, ಓಪನ್ ಗವರ್ನ್‌ಮೆಂಟ್ ಡೇಟಾ ಲೈಸೆನ್ಸ್';

  @override
  String get ok => 'ಸರಿ';

  @override
  String get cancel => 'ರದ್ದುಮಾಡಿ';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get delete => 'ಅಳಿಸಿ';

  @override
  String get edit => 'ತಿದ್ದು';

  @override
  String get add => 'ಸೇರಿಸಿ';

  @override
  String get close => 'ಮುಚ್ಚಿ';

  @override
  String get clear => 'ಅಳಿಸು';

  @override
  String get copy => 'ನಕಲಿಸಿ';

  @override
  String get copied => 'ನಕಲಿಸಲಾಗಿದೆ';

  @override
  String get share => 'ಹಂಚಿಕೊಳ್ಳಿ';

  @override
  String get search => 'ಹುಡುಕಿ';

  @override
  String get next => 'ಮುಂದೆ';

  @override
  String get back => 'ಹಿಂದೆ';

  @override
  String get done => 'ಮುಗಿದಿದೆ';

  @override
  String get yes => 'ಹೌದು';

  @override
  String get no => 'ಇಲ್ಲ';

  @override
  String get undo => 'ರದ್ದುಗೊಳಿಸು';

  @override
  String get loading => 'ಲೋಡ್ ಆಗುತ್ತಿದೆ…';

  @override
  String error(String message) {
    return 'ದೋಷ: $message';
  }

  @override
  String confirmDelete(String name) {
    return '\"$name\" ಅಳಿಸಬೇಕೆ?';
  }

  @override
  String get sampleBadge => 'ಮಾದರಿ – ನೈಜವಲ್ಲ';

  @override
  String get noActiveScheme =>
      'ಯಾವುದೇ ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್ ಸಕ್ರಿಯವಾಗಿಲ್ಲ. ಇನ್ನಷ್ಟು → ಸ್ಕೀಮ್‌ಗಳಲ್ಲಿ ನಿಮ್ಮ ಕಚೇರಿಯ ಸ್ಕೀಮ್ ಆಮದು ಮಾಡಿ (ಅಥವಾ ಮಾದರಿ ಬಳಸಿ).';

  @override
  String get useSample => 'ಮಾದರಿ ಸ್ಕೀಮ್ ಬಳಸಿ';

  @override
  String get about => 'ಬಗ್ಗೆ';

  @override
  String get aboutSub => 'ಹಕ್ಕು ನಿರಾಕರಣೆ, ಗೌಪ್ಯತೆ, ಮಾಹಿತಿ ಮೂಲ, ಆವೃತ್ತಿ';

  @override
  String get active => 'ಸಕ್ರಿಯ';

  @override
  String get schemes => 'ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್‌ಗಳು';

  @override
  String get schemesSub => 'ಆಮದು, ರಚನೆ, ರಫ್ತು, ಸಕ್ರಿಯ ಸ್ಕೀಮ್ ಆಯ್ಕೆ';

  @override
  String get pinDirectory => 'ಪಿನ್ ಡೈರೆಕ್ಟರಿ';

  @override
  String get pinDirectorySub =>
      'ಆಫ್‌ಲೈನ್ ಅಖಿಲ ಭಾರತ ಕಚೇರಿ ಪಟ್ಟಿ, CSV ಯಿಂದ ನವೀಕರಿಸಿ';

  @override
  String get favourites => 'ಮೆಚ್ಚಿನವು';

  @override
  String get favouritesSub => 'ಉಳಿಸಿದ ಕಚೇರಿಗಳು ಮತ್ತು ಪಿನ್‌ಗಳು';

  @override
  String get airportCodes => 'ವಿಮಾನ ನಿಲ್ದಾಣ ಕೋಡ್‌ಗಳು';

  @override
  String get airportCodesSub =>
      'ಸಾರ್ವಜನಿಕ IATA ಕೋಡ್ ಉಲ್ಲೇಖ (ಸಾರ್ಟಿಂಗ್ ನಿಯಮಗಳಲ್ಲ)';

  @override
  String get airportDisclaimer =>
      'ಸಾರ್ವಜನಿಕ ಉಲ್ಲೇಖ ಮಾತ್ರ. ವಾಯು ಲೇಬಲ್ ಕೋಡ್‌ಗಳು ಯಾವಾಗಲೂ ನಿಮ್ಮ ಕಚೇರಿಯ ಆಮದು ಮಾಡಿದ ಏರ್ ಕೋಡ್ ಶೀಟ್‌ನಿಂದ ಬರುತ್ತವೆ.';

  @override
  String get airportSearchHint => 'ನಗರ, ನಿಲ್ದಾಣ, ಕೋಡ್ ಅಥವಾ ರಾಜ್ಯ';

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್‌ಗಳು';

  @override
  String get settingsSub => 'ಭಾಷೆ, ಥೀಮ್, ಕೀಪ್ಯಾಡ್, ಓದುವಿಕೆ, ಕಂಪನ';

  @override
  String get help => 'ಸಹಾಯ';

  @override
  String get helpSub => 'ಸಂಕ್ಷಿಪ್ತ ಮಾರ್ಗದರ್ಶಿ';

  @override
  String get preparingDirectory =>
      'ಆಫ್‌ಲೈನ್ ಪಿನ್ ಡೈರೆಕ್ಟರಿ ಸಿದ್ಧಪಡಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get languageDevice => 'ಸಾಧನದ ಭಾಷೆ';

  @override
  String get theme => 'ಥೀಮ್';

  @override
  String get themeSystem => 'ಸಿಸ್ಟಮ್';

  @override
  String get themeLight => 'ಬೆಳಕು';

  @override
  String get themeDark => 'ಗಾಢ';

  @override
  String get keypadSize => 'ಕೀಪ್ಯಾಡ್ ಗಾತ್ರ';

  @override
  String get ttsSetting => 'ಚೀಲ / ಏರ್ ಕೋಡ್ ಓದಿ ಹೇಳು';

  @override
  String get ttsSettingSub => 'ಫೋನಿನ ಆಫ್‌ಲೈನ್ ಪಠ್ಯ-ಧ್ವನಿ ಬಳಸುತ್ತದೆ';

  @override
  String get hapticsSetting => 'ಪ್ರತಿ ಫಲಿತಾಂಶಕ್ಕೆ ಕಂಪನ';

  @override
  String get mismatchFieldSetting => '\"ವಿಳಾಸದ ಸ್ಥಳ\" ಕ್ಷೇತ್ರ ತೋರಿಸು';

  @override
  String get mismatchFieldSettingSub =>
      'ವಸ್ತುವಿನ ಮೇಲೆ ಬರೆದ ನಗರ/ಕಚೇರಿಯೊಂದಿಗೆ ಪಿನ್ ಪರಿಶೀಲಿಸುತ್ತದೆ';

  @override
  String get defaultScanMode => 'ಡೀಫಾಲ್ಟ್ ಸ್ಕ್ಯಾನ್ ಲಿಪಿ';

  @override
  String get scriptLatin => 'ಇಂಗ್ಲಿಷ್ (ಲ್ಯಾಟಿನ್)';

  @override
  String get scriptDevanagari => 'ಹಿಂದಿ (ದೇವನಾಗರಿ)';

  @override
  String get categories => 'ಅಂಚೆ ವರ್ಗಗಳು';

  @override
  String get categoriesSub => 'ಸಾರ್ಟ್ ಪರದೆಯ ಟಾಗಲ್‌ನಲ್ಲಿ ತೋರಿಸಲಾಗುತ್ತದೆ';

  @override
  String get addCategory => 'ವರ್ಗ ಸೇರಿಸಿ';

  @override
  String get catLetters => 'ಸಾಮಾನ್ಯ/ಪತ್ರಗಳು';

  @override
  String get catParcel => 'ಪಾರ್ಸೆಲ್ (ಭೂ ಮಾರ್ಗ)';

  @override
  String get catAirParcel => 'ಏರ್ ಪಾರ್ಸೆಲ್';

  @override
  String get catSpeedPost => 'ಸ್ಪೀಡ್ ಪೋಸ್ಟ್';

  @override
  String versionN(String version) {
    return 'ಆವೃತ್ತಿ $version';
  }

  @override
  String get privacyTitle => 'ಗೌಪ್ಯತೆ';

  @override
  String get privacyText =>
      'ಎಲ್ಲವೂ ಆಫ್‌ಲೈನ್‌ನಲ್ಲಿ ಕೆಲಸ ಮಾಡುತ್ತದೆ. ಲಾಗಿನ್ ಇಲ್ಲ, ಜಾಹೀರಾತು ಇಲ್ಲ, ವಿಶ್ಲೇಷಣೆ ಇಲ್ಲ, ಇಂಟರ್ನೆಟ್ ಅನುಮತಿ ಇಲ್ಲ. ಕ್ಯಾಮೆರಾ ಸ್ಕ್ಯಾನ್ ಫೋನಿನಲ್ಲೇ ಸಂಸ್ಕರಿಸಲಾಗುತ್ತದೆ ಮತ್ತು ಫೋಟೋ ತಕ್ಷಣ ಅಳಿಸಲಾಗುತ್ತದೆ — ಏನನ್ನೂ ಉಳಿಸುವುದಿಲ್ಲ ಅಥವಾ ಅಪ್‌ಲೋಡ್ ಮಾಡುವುದಿಲ್ಲ. ನಿಮ್ಮ ಸ್ಕೀಮ್‌ಗಳು, ಸೆಷನ್‌ಗಳು ಮತ್ತು ಪ್ರಗತಿ ಈ ಫೋನಿನಲ್ಲೇ ಇರುತ್ತವೆ.';

  @override
  String get dataTitle => 'ಮಾಹಿತಿ';

  @override
  String get schemeDataNote =>
      'ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್, ಏರ್ ಕೋಡ್ ಶೀಟ್ ಮತ್ತು DMSL ಇಲಾಖೆಯ ದಾಖಲೆಗಳು: ಆ್ಯಪ್‌ನಲ್ಲಿ ಯಾವುದೂ ಇಲ್ಲ. ಪ್ರತಿ ಬಳಕೆದಾರರು ತಮ್ಮದೇ ಫೈಲ್ ಆಮದು ಮಾಡುತ್ತಾರೆ; ಜೊತೆಗಿರುವ ಮಾದರಿ ನಕಲಿ.';

  @override
  String get licenceTitle => 'ಪರವಾನಗಿ';

  @override
  String get licenceText =>
      'ಉಚಿತ ಆ್ಯಪ್. ವಿಮಾನ ನಿಲ್ದಾಣ ಕೋಡ್‌ಗಳು ಸಾರ್ವಜನಿಕ IATA ಮಾಹಿತಿ.';

  @override
  String get openSourceLicences => 'ಮುಕ್ತ ಮೂಲ ಪರವಾನಗಿಗಳು';

  @override
  String get none => 'ಯಾವುದೂ ಇಲ್ಲ';

  @override
  String get unknown => 'ಗೊತ್ತಿಲ್ಲ';

  @override
  String get notSet => 'ಹೊಂದಿಸಿಲ್ಲ';

  @override
  String get note => 'ಟಿಪ್ಪಣಿ';

  @override
  String get date => 'ದಿನಾಂಕ';

  @override
  String get total => 'ಒಟ್ಟು';

  @override
  String totalN(int count) {
    return 'ಒಟ್ಟು: $count';
  }

  @override
  String get start => 'ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get summary => 'ಸಾರಾಂಶ';

  @override
  String get again => 'ಮತ್ತೆ';

  @override
  String get rename => 'ಮರುನಾಮಕರಣ';

  @override
  String get sheet => 'ಶೀಟ್';

  @override
  String get validate => 'ಪರಿಶೀಲಿಸಿ';

  @override
  String get enterPin => 'ಪಿನ್ ನಮೂದಿಸಿ';

  @override
  String get backspace => 'ಕೊನೆಯ ಅಂಕಿ ಅಳಿಸಿ';

  @override
  String get voiceInput => 'ಧ್ವನಿ ಇನ್‌ಪುಟ್';

  @override
  String get scanAddress => 'ವಿಳಾಸ ಸ್ಕ್ಯಾನ್';

  @override
  String get checkPlace => 'ಪಿನ್ - ಸ್ಥಳ ಪರಿಶೀಲನೆ';

  @override
  String get placeOnAddress => 'ವಿಳಾಸದಲ್ಲಿರುವ ನಗರ / ಕಚೇರಿ';

  @override
  String get recentLookups => 'ಇತ್ತೀಚಿನ ಹುಡುಕಾಟಗಳು';

  @override
  String get sortHint =>
      'ಕೀಪ್ಯಾಡ್‌ನಲ್ಲಿ ಪಿನ್ ಟೈಪ್ ಮಾಡಿ. ಟೈಪ್ ಮಾಡುತ್ತಿದ್ದಂತೆ ಚೀಲ ಕಾಣಿಸುತ್ತದೆ.';

  @override
  String get bag => 'ಚೀಲ';

  @override
  String get bags => 'ಚೀಲಗಳು';

  @override
  String get section => 'ವಿಭಾಗ';

  @override
  String matchedBy(String type, String key) {
    return '$type ಮೂಲಕ ಹೊಂದಿಕೆ: $key';
  }

  @override
  String get likelyBag => 'ಸಂಭವನೀಯ ಚೀಲ (ಪೂರ್ವಪ್ರತ್ಯಯದಿಂದ)';

  @override
  String get possibleBags => 'ಸಾಧ್ಯವಿರುವ ಚೀಲಗಳು';

  @override
  String sortingDistrictN(String code) {
    return 'ಸಾರ್ಟಿಂಗ್ ಜಿಲ್ಲೆ $code';
  }

  @override
  String get prefixNotInDirectory =>
      'ಈ ಪೂರ್ವಪ್ರತ್ಯಯದ ಕಚೇರಿಗಳು ಡೈರೆಕ್ಟರಿಯಲ್ಲಿಲ್ಲ';

  @override
  String get pinNotInDirectory => 'ಪಿನ್ ಡೈರೆಕ್ಟರಿಯಲ್ಲಿಲ್ಲ – ವಿಳಾಸ ಪರಿಶೀಲಿಸಿ';

  @override
  String get invalidPin => 'ಅಮಾನ್ಯ ಪಿನ್ (6 ಅಂಕಿಗಳು, ಮೊದಲ ಅಂಕಿ 1–9)';

  @override
  String get noBagRule => 'ಈ ಪಿನ್‌ಗೆ ಚೀಲ ನಿಯಮವಿಲ್ಲ – ಮೇಲ್ವಿಚಾರಕರನ್ನು ಕೇಳಿ';

  @override
  String deliveryOfficesN(int count) {
    return 'ವಿತರಣಾ ಕಚೇರಿ(ಗಳು): $count';
  }

  @override
  String andMore(int count) {
    return '…ಮತ್ತು ಇನ್ನೂ $count';
  }

  @override
  String get delivery => 'ವಿತರಣೆ';

  @override
  String get nonDelivery => 'ವಿತರಣೆಯಿಲ್ಲ';

  @override
  String get typeHO => 'ಪ್ರಧಾನ ಕಚೇರಿ';

  @override
  String get typeSO => 'ಉಪ ಕಚೇರಿ';

  @override
  String get typeBO => 'ಶಾಖಾ ಕಚೇರಿ';

  @override
  String get typePO => 'ಅಂಚೆ ಕಚೇರಿ';

  @override
  String get pinStructure => 'ಪಿನ್ ರಚನೆ';

  @override
  String get pinZone => 'ಅಂಚೆ ವಲಯ';

  @override
  String get pinCircle => 'ಅಂಚೆ ವೃತ್ತ';

  @override
  String get pinSortingDistrict => 'ಸಾರ್ಟಿಂಗ್ ಜಿಲ್ಲೆ';

  @override
  String get pinSortingDistrictHelp => 'ಮೊದಲ 3 ಅಂಕಿಗಳು';

  @override
  String get pinDeliveryOffice => 'ವಿತರಣಾ ಅಂಚೆ ಕಚೇರಿ';

  @override
  String get pinDeliveryOfficeHelp => 'ಕೊನೆಯ 3 ಅಂಕಿಗಳು';

  @override
  String get airLabelCode => 'ವಾಯು ಲೇಬಲ್ ಕೋಡ್';

  @override
  String get noAirCode => 'ಏರ್ ಕೋಡ್ ಇಲ್ಲ – ಮೇಲ್ವಿಚಾರಕರನ್ನು ಕೇಳಿ';

  @override
  String get readAloud => 'ಗಟ್ಟಿಯಾಗಿ ಓದು';

  @override
  String get via => 'ಮೂಲಕ';

  @override
  String get badgeAir => 'ವಾಯು AIR';

  @override
  String get badgeSurface => 'ಭೂ SURFACE';

  @override
  String labelBadge(String text) {
    return 'ಲೇಬಲ್ ಬಣ್ಣ: $text';
  }

  @override
  String get labelBadgeShort => 'ಲೇಬಲ್';

  @override
  String get connectivityDefaulted =>
      'ನಿಯಮದಲ್ಲಿ ಸಂಪರ್ಕ ನೀಡಿಲ್ಲ – ಭೂ ಮಾರ್ಗ ಎಂದು ಊಹಿಸಲಾಗಿದೆ. ಮೇಲ್ವಿಚಾರಕರನ್ನು ಕೇಳಿ.';

  @override
  String get connAir => 'ವಾಯು';

  @override
  String get connSurface => 'ಭೂ ಮಾರ್ಗ';

  @override
  String get hubRoute => 'ಪಾರ್ಸೆಲ್ ಹಬ್ ಮಾರ್ಗ';

  @override
  String directToL1(String hub) {
    return 'ನೇರವಾಗಿ L1 ಹಬ್‌ಗೆ: $hub';
  }

  @override
  String get noDmsl => 'ಈ ಸ್ಕೀಮ್‌ಗೆ DMSL ಆಮದು ಮಾಡಿಲ್ಲ';

  @override
  String get noHubRoute => 'DMSL ನಲ್ಲಿ ಈ ಪಿನ್‌ಗೆ ಹಬ್ ನಿಯಮವಿಲ್ಲ';

  @override
  String dmslVersionLabel(String version) {
    return 'DMSL $version';
  }

  @override
  String get labelView => 'ಲೇಬಲ್ ನೋಟ';

  @override
  String get shareImage => 'ಚಿತ್ರವಾಗಿ ಹಂಚಿ';

  @override
  String get shareText => 'ಪಠ್ಯವಾಗಿ ಹಂಚಿ';

  @override
  String get listening => 'ಕೇಳುತ್ತಿದೆ…';

  @override
  String get sayPin => 'ಪಿನ್ ಅಂಕಿಗಳನ್ನು ಹೇಳಿ';

  @override
  String get voiceUnavailable => 'ಈ ಫೋನಿನಲ್ಲಿ ಧ್ವನಿ ಗುರುತಿಸುವಿಕೆ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get unresolved => 'ಪರಿಹರಿಸದ';

  @override
  String get findPinHint => 'ಕಚೇರಿ, ಗ್ರಾಮ, ನಗರ, ತಾಲ್ಲೂಕು ಅಥವಾ ಜಿಲ್ಲೆ';

  @override
  String get findPinTip =>
      'ಇಂಗ್ಲಿಷ್, ಕನ್ನಡ ಅಥವಾ ಹಿಂದಿಯಲ್ಲಿ ಟೈಪ್ ಮಾಡಿ. ಕಾಗುಣಿತ ತಪ್ಪಾದರೂ ಪರವಾಗಿಲ್ಲ: \"Puttoor\", \"Putur\", \"ಪುತ್ತೂರು\" ಎಲ್ಲವೂ ಪುತ್ತೂರನ್ನು ಹುಡುಕುತ್ತವೆ.';

  @override
  String get allStates => 'ಎಲ್ಲಾ ರಾಜ್ಯಗಳು';

  @override
  String get allDistricts => 'ಎಲ್ಲಾ ಜಿಲ್ಲೆಗಳು';

  @override
  String get deliveryOnly => 'ವಿತರಣಾ ಕಚೇರಿಗಳು ಮಾತ್ರ';

  @override
  String get noResults => 'ಹೊಂದುವ ಕಚೇರಿ ಸಿಗಲಿಲ್ಲ';

  @override
  String get taluk => 'ತಾಲ್ಲೂಕು';

  @override
  String get division => 'ವಿಭಾಗ';

  @override
  String get sortThisPin => 'ಈ ಪಿನ್ ಸಾರ್ಟ್ ಮಾಡಿ';

  @override
  String get copyPin => 'ಪಿನ್ ನಕಲಿಸಿ';

  @override
  String get addFavourite => 'ಮೆಚ್ಚಿನವುಗಳಿಗೆ ಸೇರಿಸಿ';

  @override
  String get removeFavourite => 'ಮೆಚ್ಚಿನವುಗಳಿಂದ ತೆಗೆದುಹಾಕಿ';

  @override
  String get noFavourites =>
      'ಇನ್ನೂ ಮೆಚ್ಚಿನವು ಇಲ್ಲ. ಪಿನ್ ಹುಡುಕಿ ಪರದೆಯಿಂದ ಕಚೇರಿಗಳನ್ನು ಸೇರಿಸಿ.';

  @override
  String get mismatchChecker => 'ಪಿನ್ ↔ ಸ್ಥಳ ಪರಿಶೀಲನೆ';

  @override
  String get mismatchCheckerSub =>
      'ತಪ್ಪು ಸಾರ್ಟಿಂಗ್ ಮೊದಲು ತಪ್ಪು ಪಿನ್ ಪತ್ತೆಹಚ್ಚಿ';

  @override
  String get mmMatch => '✅ ಸ್ಥಳ ಈ ಪಿನ್‌ಗೆ ಹೊಂದುತ್ತದೆ';

  @override
  String get mmSameDistrict => '⚠️ ಅದೇ ಜಿಲ್ಲೆ, ಆದರೆ ಬೇರೆ ಪಿನ್';

  @override
  String get mmDifferent =>
      '❌ ಸ್ಥಳ ಬೇರೆ ಜಿಲ್ಲೆ/ರಾಜ್ಯದಲ್ಲಿದೆ – ಪಿನ್ ತಪ್ಪಾಗಿರಬಹುದು';

  @override
  String get mmUnknownPlace =>
      'ಸ್ಥಳ ಡೈರೆಕ್ಟರಿಯಲ್ಲಿ ಸಿಗಲಿಲ್ಲ – ಕಾಗುಣಿತ ಪರಿಶೀಲಿಸಿ';

  @override
  String mmPinIs(String pin, String office) {
    return 'ಪಿನ್ $pin: $office';
  }

  @override
  String mmPlaceIs(String place, String district) {
    return '\"$place\" ಇರುವುದು $district ನಲ್ಲಿ';
  }

  @override
  String get suggestedPins => 'ಸೂಚಿಸಿದ ಪಿನ್‌ಗಳು:';

  @override
  String get scanHint =>
      'ವಿಳಾಸದ ಕಡೆ (ಪಿನ್ ಸಹಿತ) ಹಿಡಿದು ಕ್ಯಾಪ್ಚರ್ ಒತ್ತಿ. ಏನನ್ನೂ ಉಳಿಸುವುದಿಲ್ಲ.';

  @override
  String get capture => 'ಕ್ಯಾಪ್ಚರ್';

  @override
  String get torch => 'ಟಾರ್ಚ್';

  @override
  String get scanScript => 'ಪಠ್ಯ ಲಿಪಿ';

  @override
  String cameraUnavailable(String error) {
    return 'ಕ್ಯಾಮೆರಾ ಲಭ್ಯವಿಲ್ಲ: $error';
  }

  @override
  String get noPinDetected =>
      'ಪಠ್ಯದಲ್ಲಿ ಪಿನ್ ಸಿಗಲಿಲ್ಲ – ಟೈಪ್ ಮಾಡಿ ಅಥವಾ ಸ್ಥಳ ಹುಡುಕಿ';

  @override
  String get detectedPin => 'ಪತ್ತೆಯಾದ ಪಿನ್ (ತಪ್ಪಾದರೆ ತಿದ್ದಿ)';

  @override
  String get detectedPlace => 'ಪತ್ತೆಯಾದ ನಗರ / ಕಚೇರಿ';

  @override
  String get useThisPin => 'ಈ ಪಿನ್ ಬಳಸಿ';

  @override
  String get addToBulk => 'ಗುಂಪು ಎಣಿಕೆಗೆ ಸೇರಿಸಿ';

  @override
  String get scanAgain => 'ಮತ್ತೆ ಸ್ಕ್ಯಾನ್';

  @override
  String get scanPrivacy =>
      'ಪಠ್ಯವನ್ನು ಫೋನಿನಲ್ಲೇ ML Kit ಮೂಲಕ ಓದಲಾಗುತ್ತದೆ. ಓದಿದ ತಕ್ಷಣ ಫೋಟೋ ಅಳಿಸಲಾಗುತ್ತದೆ. ML Kit ಇಂಗ್ಲಿಷ್ ಮತ್ತು ಹಿಂದಿ ಲಿಪಿ ಓದುತ್ತದೆ; ಕನ್ನಡ ವಿಳಾಸಗಳಿಗೆ ಪಿನ್ ಅಂಕಿಗಳನ್ನು ಬಳಸಲಾಗುತ್ತದೆ ಮತ್ತು ಸ್ಥಳವನ್ನು ಕೈಯಿಂದ ಹುಡುಕಬಹುದು.';

  @override
  String get noOpenSession =>
      'ಯಾವುದೇ ಗುಂಪು ಸೆಷನ್ ನಡೆಯುತ್ತಿಲ್ಲ – ಗುಂಪು ಟ್ಯಾಬ್‌ನಲ್ಲಿ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String addedToBulk(String bag) {
    return 'ಸೇರಿಸಲಾಗಿದೆ: $bag';
  }

  @override
  String get bulkTitle => 'ಗುಂಪು ಸಾರ್ಟಿಂಗ್';

  @override
  String get bulkEmpty =>
      'ಚೀಲವಾರು ವಸ್ತುಗಳನ್ನು ಎಣಿಸಿ: ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ, ಪಿನ್‌ಗಳನ್ನು ವೇಗವಾಗಿ ನಮೂದಿಸಿ, ನಂತರ ಎಣಿಕೆ ಹಂಚಿಕೊಳ್ಳಿ.';

  @override
  String get startSession => 'ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get sessionName => 'ಸೆಷನ್ ಹೆಸರು';

  @override
  String sessionDefaultName(String time) {
    return 'ಸೆಷನ್ $time';
  }

  @override
  String get scheme => 'ಸ್ಕೀಮ್';

  @override
  String get inProgress => 'ನಡೆಯುತ್ತಿದೆ';

  @override
  String get undoLast => 'ಕೊನೆಯದನ್ನು ರದ್ದುಮಾಡಿ';

  @override
  String get endSession => 'ಮುಗಿಸಿ';

  @override
  String unresolvedEntries(int count) {
    return 'ಪರಿಹರಿಸದ / ಅಮಾನ್ಯ: $count (ಸರಿಪಡಿಸಲು ಒತ್ತಿ)';
  }

  @override
  String fixEntry(String raw) {
    return '\"$raw\" ಸರಿಪಡಿಸಿ';
  }

  @override
  String get shareCsv => 'CSV ಹಂಚಿ';

  @override
  String get sharePrintable => 'ಮುದ್ರಿಸಬಹುದಾದ ಪಠ್ಯ ಫೈಲ್ ಹಂಚಿ';

  @override
  String get continueSession => 'ಎಣಿಕೆ ಮುಂದುವರಿಸಿ';

  @override
  String get learnNeedsScheme =>
      'ಅಭ್ಯಾಸವು ಸಕ್ರಿಯ ಸ್ಕೀಮ್ ಬಳಸುತ್ತದೆ. ನಿಮ್ಮ ಕಚೇರಿಯ ಸ್ಕೀಮ್ ಆಮದು ಮಾಡಿ ಅಥವಾ ಮಾದರಿ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get learnFromScheme => 'ಪ್ರಶ್ನೆಗಳು ಈ ಸ್ಕೀಮ್‌ನಿಂದ ಬರುತ್ತವೆ';

  @override
  String get flashcards => 'ಚೀಲ ಫ್ಲ್ಯಾಶ್‌ಕಾರ್ಡ್‌ಗಳು';

  @override
  String get flashcardsSub => 'ಪಿನ್ → ಯಾವ ಚೀಲ? ಅಂತರದ ಪುನರಾವರ್ತನೆ';

  @override
  String get timedQuiz => 'ಸಮಯದ ಸಾರ್ಟಿಂಗ್ ರಸಪ್ರಶ್ನೆ';

  @override
  String get timedQuizSub => '20 ವಸ್ತುಗಳು, 4 ಆಯ್ಕೆಗಳು, ಅಂಕ ಮತ್ತು ವೇಗ';

  @override
  String get airFlashcards => 'ಏರ್ ಕೋಡ್ ಫ್ಲ್ಯಾಶ್‌ಕಾರ್ಡ್‌ಗಳು';

  @override
  String get airFlashcardsSub => 'ಪಿನ್ / ಜಿಲ್ಲೆ → ಏರ್ ಕೋಡ್';

  @override
  String get airQuiz => 'ಏರ್ ಕೋಡ್ ರಸಪ್ರಶ್ನೆ';

  @override
  String get airQuizSub => 'ಆಮದು ಮಾಡಿದ ಏರ್ ಕೋಡ್ ಶೀಟ್ ಬೇಕು';

  @override
  String get hubFlashcards => 'ಪಾರ್ಸೆಲ್ ಹಬ್ ಫ್ಲ್ಯಾಶ್‌ಕಾರ್ಡ್‌ಗಳು';

  @override
  String get hubFlashcardsSub => 'ಪಿನ್ → ಸಕ್ರಿಯ DMSL ನಿಂದ L2 / L1 ಹಬ್';

  @override
  String get weakAreas => 'ದುರ್ಬಲ ಭಾಗಗಳು';

  @override
  String get weakAreasSub => 'ನೀವು ಹೆಚ್ಚು ತಪ್ಪುವ ಚೀಲಗಳು ಮತ್ತು ಪಿನ್ ಸರಣಿಗಳು';

  @override
  String get pinBasics => 'ಪಿನ್ ಮೂಲಭೂತಗಳು';

  @override
  String get pinBasicsSub => 'ವಲಯ, ವೃತ್ತ, ಸಾರ್ಟಿಂಗ್ ಜಿಲ್ಲೆ, ವಿತರಣಾ ಕಚೇರಿ';

  @override
  String get noCards =>
      'ಕಾರ್ಡ್‌ಗಳಿಲ್ಲ: ಈ ಅಭ್ಯಾಸಕ್ಕೆ ಸ್ಕೀಮ್‌ನಲ್ಲಿ ಇನ್ನೂ ನಿಯಮಗಳಿಲ್ಲ.';

  @override
  String flashDone(int known, int unknown) {
    return 'ಸುತ್ತು ಮುಗಿಯಿತು! ತಿಳಿದವು: $known, ತಿಳಿಯದವು: $unknown';
  }

  @override
  String leitnerBox(int box) {
    return '5 ರಲ್ಲಿ ಪೆಟ್ಟಿಗೆ $box';
  }

  @override
  String get qWhichBagPin => 'ಈ ಪಿನ್‌ಗೆ ಯಾವ ಚೀಲ';

  @override
  String get qWhichBagPlace => 'ಇದಕ್ಕೆ ಯಾವ ಚೀಲ';

  @override
  String get qWhichAirCode => 'ಇದಕ್ಕೆ ಯಾವ ಏರ್ ಕೋಡ್';

  @override
  String get qWhichHub => 'ಈ ಪಿನ್‌ಗೆ ಯಾವ ಪಾರ್ಸೆಲ್ ಹಬ್ ಮಾರ್ಗ';

  @override
  String get answer => 'ಉತ್ತರ';

  @override
  String get tapToFlip => 'ತಿರುಗಿಸಲು ಕಾರ್ಡ್ ಒತ್ತಿ';

  @override
  String get showAnswer => 'ಉತ್ತರ ತೋರಿಸು';

  @override
  String get knewIt => 'ನನಗೆ ಗೊತ್ತಿತ್ತು';

  @override
  String get didntKnow => 'ಗೊತ್ತಿರಲಿಲ್ಲ';

  @override
  String scoreN(int score) {
    return 'ಅಂಕ $score';
  }

  @override
  String quizScore(int score, int total) {
    return '$score / $total';
  }

  @override
  String quizStats(int seconds, String apm) {
    return '$seconds ಸೆ · ನಿಮಿಷಕ್ಕೆ $apm ವಸ್ತುಗಳು';
  }

  @override
  String get history => 'ಅಂಕಗಳ ಇತಿಹಾಸ';

  @override
  String get historyNeedsMore => 'ಚಾರ್ಟ್ ನೋಡಲು ಇನ್ನೊಂದು ರಸಪ್ರಶ್ನೆ ಆಡಿ';

  @override
  String get noWeakAreas => 'ಇನ್ನೂ ತಪ್ಪುಗಳು ದಾಖಲಾಗಿಲ್ಲ – ಮೊದಲು ಅಭ್ಯಾಸ ಮಾಡಿ.';

  @override
  String get weakBags => 'ಹೆಚ್ಚು ತಪ್ಪಾದ ಚೀಲಗಳು';

  @override
  String get weakPrefixes => 'ಹೆಚ್ಚು ತಪ್ಪಾದ ಪಿನ್ ಸರಣಿಗಳು';

  @override
  String wrongTimes(int count) {
    return '$count ಬಾರಿ ತಪ್ಪು';
  }

  @override
  String quizzesTaken(int count) {
    return 'ಆಡಿದ ರಸಪ್ರಶ್ನೆಗಳು: $count';
  }

  @override
  String averageScore(int percent) {
    return 'ಸರಾಸರಿ ಅಂಕ: $percent%';
  }

  @override
  String get resetProgress => 'ಪ್ರಗತಿ ಮರುಹೊಂದಿಸಿ';

  @override
  String get resetProgressConfirm =>
      'ರಸಪ್ರಶ್ನೆ ಇತಿಹಾಸ, ತಪ್ಪುಗಳು ಮತ್ತು ಫ್ಲ್ಯಾಶ್‌ಕಾರ್ಡ್ ಪೆಟ್ಟಿಗೆಗಳನ್ನು ಅಳಿಸಬೇಕೆ?';

  @override
  String get pinBasicsIntro =>
      'ಪಿನ್ (ಅಂಚೆ ಸೂಚ್ಯಂಕ ಸಂಖ್ಯೆ) 6 ಅಂಕಿಗಳನ್ನು ಹೊಂದಿದೆ. ಪ್ರತಿ ಭಾಗವು ವಸ್ತು ಎಲ್ಲಿಗೆ ಹೋಗಬೇಕೆಂದು ಸೂಚಿಸುತ್ತದೆ:';

  @override
  String get pinBasicsDigits =>
      'ಅಂಕಿ 1 = ಅಂಚೆ ವಲಯ. ಅಂಕಿ 1–2 = ಅಂಚೆ ವೃತ್ತ. ಅಂಕಿ 1–3 = ಸಾರ್ಟಿಂಗ್ ಜಿಲ್ಲೆ (ಅಂಚೆ ನಿರ್ವಹಿಸುವ ಸಾರ್ಟಿಂಗ್ ಕಚೇರಿ). ಕೊನೆಯ 3 ಅಂಕಿ = ವಿತರಣಾ ಅಂಚೆ ಕಚೇರಿ. ಉದಾಹರಣೆ 574201: 5 = ದಕ್ಷಿಣ ವಲಯ, 57 = ಕರ್ನಾಟಕ, 574 = ಸಾರ್ಟಿಂಗ್ ಜಿಲ್ಲೆ, 201 = ವಿತರಣಾ ಕಚೇರಿ.';

  @override
  String get pinZones => 'ವಲಯಗಳು (ಮೊದಲ ಅಂಕಿ)';

  @override
  String get circleTable => 'ವೃತ್ತಗಳು (ಮೊದಲ ಎರಡು ಅಂಕಿಗಳು)';

  @override
  String get pinBasicsNote =>
      'ವೃತ್ತದ ಗಡಿಗಳು ಅಂದಾಜು; ಕೆಲವು ಸಣ್ಣ ವೃತ್ತಗಳು ನೆರೆಯವರೊಂದಿಗೆ ಅಂಕಿ ಹಂಚಿಕೊಳ್ಳುತ್ತವೆ (ಮೇಲಿನ ಪಟ್ಟಿ ನೋಡಿ). ಯಾವಾಗಲೂ ನಿಮ್ಮ ಕಚೇರಿಯ ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್ ಅನುಸರಿಸಿ.';

  @override
  String get noSchemes =>
      'ಇನ್ನೂ ಸ್ಕೀಮ್‌ಗಳಿಲ್ಲ. ನಿಮ್ಮ ಕಚೇರಿಯ ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್ (Excel/CSV) ಆಮದು ಮಾಡಿ, ಹೊಸದು ರಚಿಸಿ ಅಥವಾ ಮಾದರಿ ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get schemesPrivacy =>
      'ಸ್ಕೀಮ್‌ಗಳು ಇಲಾಖೆಯ ದಾಖಲೆಗಳು: ಅವು ಈ ಫೋನಿನಲ್ಲೇ ಇರುತ್ತವೆ. ನಿಮ್ಮ ತಂಡದೊಂದಿಗೆ ಮಾತ್ರ ಹಂಚಿ.';

  @override
  String get importScheme => 'ಸ್ಕೀಮ್ ಆಮದು';

  @override
  String get importSchemeSub => 'Excel (.xlsx) ಅಥವಾ CSV';

  @override
  String get importAirCodes => 'ಏರ್ ಕೋಡ್ ಶೀಟ್ ಆಮದು';

  @override
  String get importDmsl => 'DMSL ಆಮದು (ಪಾರ್ಸೆಲ್ ಹಬ್‌ಗಳು)';

  @override
  String get createManually => 'ಆ್ಯಪ್‌ನಲ್ಲಿ ಸ್ಕೀಮ್ ರಚಿಸಿ';

  @override
  String get installSample => 'ಮಾದರಿ ಸ್ಕೀಮ್ ಸೇರಿಸಿ (ನೈಜವಲ್ಲ)';

  @override
  String get downloadTemplate => 'ಟೆಂಪ್ಲೇಟ್ ಡೌನ್‌ಲೋಡ್';

  @override
  String get downloadSampleFile => 'ಮಾದರಿ ಸ್ಕೀಮ್ ಫೈಲ್ ಉಳಿಸಿ';

  @override
  String get templateSaved => 'ಉಳಿಸಲಾಗಿದೆ';

  @override
  String get newScheme => 'ಹೊಸ ಸ್ಕೀಮ್';

  @override
  String get schemeName => 'ಸ್ಕೀಮ್ ಹೆಸರು';

  @override
  String get officeName => 'ಕಚೇರಿ';

  @override
  String get setActive => 'ಸಕ್ರಿಯಗೊಳಿಸಿ';

  @override
  String get exportXlsx => 'Excel ಆಗಿ ರಫ್ತು / ಹಂಚಿ';

  @override
  String get exportCsv => 'CSV ಆಗಿ ರಫ್ತು / ಹಂಚಿ';

  @override
  String get rules => 'ನಿಯಮಗಳು';

  @override
  String get airCodes => 'ಏರ್ ಕೋಡ್‌ಗಳು';

  @override
  String rulesCount(int count) {
    return '$count ನಿಯಮಗಳು';
  }

  @override
  String get filterRules => 'ನಿಯಮಗಳನ್ನು ಫಿಲ್ಟರ್ ಮಾಡಿ';

  @override
  String get addRule => 'ನಿಯಮ ಸೇರಿಸಿ';

  @override
  String get editRule => 'ನಿಯಮ ತಿದ್ದು';

  @override
  String get addBag => 'ಚೀಲ ಸೇರಿಸಿ';

  @override
  String get editBag => 'ಚೀಲ ತಿದ್ದು';

  @override
  String deleteBagConfirm(String code) {
    return 'ಚೀಲ $code ಮತ್ತು ಅದರ ಎಲ್ಲಾ ನಿಯಮಗಳನ್ನು ಅಳಿಸಬೇಕೆ?';
  }

  @override
  String get invalidRuleKey =>
      'ಈ ನಿಯಮ ಪ್ರಕಾರಕ್ಕೆ ಪಿನ್ / ಶ್ರೇಣಿ / ಪೂರ್ವಪ್ರತ್ಯಯ / ಹೆಸರು ಪರಿಶೀಲಿಸಿ';

  @override
  String get allCategories => 'ಎಲ್ಲಾ ವರ್ಗಗಳು';

  @override
  String get noAirCodes =>
      'ಏರ್ ಕೋಡ್‌ಗಳಿಲ್ಲ. ನಿಮ್ಮ ಕಚೇರಿಯ ಏರ್ ಕೋಡ್ ಶೀಟ್ ಆಮದು ಮಾಡಿ (ಏರ್ ಪಾರ್ಸೆಲ್ ಮೋಡ್ ಕೋಡ್ ಅನ್ನು ದೊಡ್ಡ ಅಕ್ಷರಗಳಲ್ಲಿ ತೋರಿಸುತ್ತದೆ).';

  @override
  String get dmslHelp =>
      'ಡ್ಯೂ ಮೇಲ್ ಸಾರ್ಟಿಂಗ್ ಲಿಸ್ಟ್ ಪಿನ್‌ಗಳನ್ನು L2 → L1 ಪಾರ್ಸೆಲ್ ಹಬ್‌ಗಳಿಗೆ ಜೋಡಿಸುತ್ತದೆ. ಹಬ್ ಪಟ್ಟಿಗಳು ಬದಲಾಗುತ್ತವೆ (ಉದಾ. 7 ಅಕ್ಟೋಬರ್ 2026 ಪುನರ್ರಚನೆ), ಆದ್ದರಿಂದ ಪ್ರತಿ ಹೊಸ ಆವೃತ್ತಿಯನ್ನು ಆಮದು ಮಾಡಿ; ಸಕ್ರಿಯಗೊಳಿಸಲು ಆವೃತ್ತಿಯನ್ನು ಒತ್ತಿ.';

  @override
  String validFromDate(String date) {
    return '$date ರಿಂದ ಮಾನ್ಯ';
  }

  @override
  String get compareWithPrevious => 'ಹಿಂದಿನ ಆವೃತ್ತಿಗೆ ಹೋಲಿಸಿದ ಬದಲಾವಣೆಗಳು';

  @override
  String get dmslChanges => 'DMSL ಬದಲಾವಣೆಗಳು';

  @override
  String dmslCompare(String from, String to) {
    return '$from → $to';
  }

  @override
  String dmslChangedCount(int count) {
    return '$count ಪಿನ್‌ಗಳ ಹಬ್ ಬದಲಾಗಿದೆ';
  }

  @override
  String get dmslNoChanges => 'ಈ ಆವೃತ್ತಿಗಳ ನಡುವೆ ಯಾವ ಪಿನ್‌ನ ಹಬ್ ಬದಲಾಗಿಲ್ಲ.';

  @override
  String get practiseChanged => 'ಬದಲಾದ ಪಿನ್‌ಗಳನ್ನು ಮಾತ್ರ ಅಭ್ಯಾಸ ಮಾಡಿ';

  @override
  String get dmslVersionName => 'ಆವೃತ್ತಿಯ ಹೆಸರು';

  @override
  String get validFrom => 'ಇಂದ ಮಾನ್ಯ';

  @override
  String get stepFile => 'ಫೈಲ್';

  @override
  String get stepPreview => 'ಮುನ್ನೋಟ';

  @override
  String get stepMapping => 'ಕಾಲಂಗಳು';

  @override
  String get stepReport => 'ಪರಿಶೀಲಿಸಿ ಉಳಿಸಿ';

  @override
  String get chooseFile => 'Excel / CSV ಫೈಲ್ ಆಯ್ಕೆಮಾಡಿ';

  @override
  String get importSchemeHelp =>
      'ಪ್ರತಿ ನಿಯಮಕ್ಕೆ ಒಂದು ಸಾಲು. ಕಾಲಂಗಳು (ಯಾವ ಕ್ರಮದಲ್ಲಾದರೂ, ಇಂಗ್ಲಿಷ್/ಕನ್ನಡ/ಹಿಂದಿ ಶೀರ್ಷಿಕೆ): PIN, PIN From, PIN To, Prefix, Office, District, State, Bag No, Bag Name, Section, Remarks, Category, Connectivity (Air/Surface), Colour. ಪಿನ್/ಕಚೇರಿ/ಜಿಲ್ಲೆ ಇಲ್ಲದ ಸಾಲು \"ಇತರೆ ಎಲ್ಲ\" (ಡೀಫಾಲ್ಟ್) ಚೀಲ.';

  @override
  String get importAirHelp =>
      'ಕಾಲಂಗಳು: PIN, PIN From, PIN To, Prefix, District, State, Air Code, Station, Via, Remarks. ಕೋಡ್‌ಗಳನ್ನು ವಿಮಾನ ನಿಲ್ದಾಣ ಪಟ್ಟಿಯೊಂದಿಗೆ ಪರಿಶೀಲಿಸಲಾಗುತ್ತದೆ; ಗೊತ್ತಿಲ್ಲದ ಕೋಡ್‌ಗಳನ್ನು ಎಚ್ಚರಿಕೆಯೊಂದಿಗೆ ಉಳಿಸಲಾಗುತ್ತದೆ.';

  @override
  String get importDmslHelp =>
      'ಕಾಲಂಗಳು: PIN / PIN From / PIN To / Prefix / Office, L2 Hub, L1 Hub, Direct closure (Y/N), Connectivity (Air/Surface), Remarks. ಆಮದಿನ ನಂತರ ಯಾವ ಪಿನ್‌ಗಳ ಹಬ್ ಬದಲಾಗಿದೆ ಎಂದು ನೋಡುತ್ತೀರಿ.';

  @override
  String get importPrivacy => 'ಫೈಲ್ ಅನ್ನು ಫೋನಿನಲ್ಲೇ ಓದಲಾಗುತ್ತದೆ.';

  @override
  String get headerRow => 'ಶೀರ್ಷಿಕೆ ಸಾಲು';

  @override
  String previewRows(int shown, int total) {
    return '$total ಸಾಲುಗಳಲ್ಲಿ $shown ತೋರಿಸಲಾಗಿದೆ';
  }

  @override
  String get mappingHelp =>
      'ಪ್ರತಿ ಕ್ಷೇತ್ರ ಯಾವ ಕಾಲಂನಲ್ಲಿದೆ ಎಂದು ಪರಿಶೀಲಿಸಿ. ಶೀರ್ಷಿಕೆಗಳಿಂದ ಸ್ವಯಂ ಪತ್ತೆ; ತಪ್ಪಾದರೆ ಬದಲಿಸಿ.';

  @override
  String get notMapped => '— ಫೈಲ್‌ನಲ್ಲಿಲ್ಲ —';

  @override
  String reportRulesOk(int count) {
    return '$count ನಿಯಮಗಳು ಸಿದ್ಧ';
  }

  @override
  String reportSummary(int errors, int warnings) {
    return '$errors ಸಾಲುಗಳನ್ನು ಬಿಡಲಾಗಿದೆ · $warnings ಎಚ್ಚರಿಕೆಗಳು';
  }

  @override
  String bagsFound(int count) {
    return '$count ಚೀಲಗಳು ಸಿಕ್ಕಿವೆ';
  }

  @override
  String get airReplaceNote =>
      'ಉಳಿಸಿದರೆ ಈ ಸ್ಕೀಮ್‌ನ ಈಗಿನ ಏರ್ ಕೋಡ್ ಪಟ್ಟಿ ಬದಲಾಗುತ್ತದೆ.';

  @override
  String rowN(int row) {
    return 'ಸಾಲು $row';
  }

  @override
  String saveRules(int count) {
    return '$count ಉಳಿಸಿ';
  }

  @override
  String importSaved(int count) {
    return '$count ನಿಯಮಗಳನ್ನು ಆಮದು ಮಾಡಲಾಗಿದೆ';
  }

  @override
  String get issueBadPin => 'ತಪ್ಪು ಪಿನ್ / ಶ್ರೇಣಿ / ಪೂರ್ವಪ್ರತ್ಯಯ';

  @override
  String get issueNoBag => 'ಸಾಲಿನಲ್ಲಿ ಚೀಲ / ಕೋಡ್ / ಹಬ್ ಇಲ್ಲ';

  @override
  String get issueNoMatch => 'ಪಿನ್ / ಕಚೇರಿ / ಜಿಲ್ಲೆ ಇಲ್ಲ';

  @override
  String get issueDuplicate => 'ನಕಲಿ ನಿಯಮಗಳು';

  @override
  String get issueConflict => 'ಸಂಘರ್ಷದ ನಿಯಮಗಳು (ಅದೇ ಕೀ, ಬೇರೆ ಫಲಿತಾಂಶ)';

  @override
  String get issueOverlap => 'ಅತಿಕ್ರಮಿಸುವ ಪಿನ್ ಶ್ರೇಣಿಗಳು';

  @override
  String get issueNested => 'ಒಳಗೊಂಡ ಶ್ರೇಣಿಗಳು (ಚಿಕ್ಕದು ಗೆಲ್ಲುತ್ತದೆ)';

  @override
  String get issueUnknownAir =>
      'ನಿಲ್ದಾಣ ಪಟ್ಟಿಯಲ್ಲಿಲ್ಲದ ಏರ್ ಕೋಡ್‌ಗಳು (ಉಳಿಸಲಾಗಿದೆ)';

  @override
  String get issueNoConnectivity => 'ಸಂಪರ್ಕ ಖಾಲಿ (ಭೂ ಮಾರ್ಗ ಊಹಿಸಲಾಗಿದೆ)';

  @override
  String get issueDefault => '\"ಇತರೆ ಎಲ್ಲ\" ಎಂದು ಪರಿಗಣಿಸಿದ ಸಾಲುಗಳು';

  @override
  String get issueBadColour => 'ಗೊತ್ತಿಲ್ಲದ ಬಣ್ಣಗಳು';

  @override
  String get ruleExact => 'ನಿಖರ ಪಿನ್';

  @override
  String get ruleRange => 'ಪಿನ್ ಶ್ರೇಣಿ';

  @override
  String get rulePrefix => 'ಪೂರ್ವಪ್ರತ್ಯಯ';

  @override
  String get ruleOffice => 'ಕಚೇರಿ ಹೆಸರು';

  @override
  String get ruleDistrict => 'ಜಿಲ್ಲೆ';

  @override
  String get ruleState => 'ರಾಜ್ಯ';

  @override
  String get ruleDefault => 'ಇತರೆ ಎಲ್ಲ (ಡೀಫಾಲ್ಟ್)';

  @override
  String get fType => 'ನಿಯಮ ಪ್ರಕಾರ';

  @override
  String get fPin => 'ಪಿನ್';

  @override
  String get fPinFrom => 'ಪಿನ್ ಇಂದ';

  @override
  String get fPinTo => 'ಪಿನ್ ವರೆಗೆ';

  @override
  String get fPrefix => 'ಪೂರ್ವಪ್ರತ್ಯಯ (ಮೊದಲ 1–5 ಅಂಕಿಗಳು)';

  @override
  String get fOffice => 'ಕಚೇರಿ';

  @override
  String get fDistrict => 'ಜಿಲ್ಲೆ';

  @override
  String get fState => 'ರಾಜ್ಯ';

  @override
  String get fBagCode => 'ಚೀಲ ಸಂಖ್ಯೆ / ಕೋಡ್';

  @override
  String get fBagName => 'ಚೀಲದ ಹೆಸರು';

  @override
  String get fSection => 'ವಿಭಾಗ';

  @override
  String get fRemarks => 'ಷರಾ';

  @override
  String get fCategory => 'ಅಂಚೆ ವರ್ಗ';

  @override
  String get fConnectivity => 'ಸಂಪರ್ಕ (ವಾಯು/ಭೂ)';

  @override
  String get fColour => 'ಚೀಲದ ಬಣ್ಣ';

  @override
  String get fAirCode => 'ಏರ್ ಕೋಡ್';

  @override
  String get fStation => 'ವಾಯು ನಿಲ್ದಾಣ';

  @override
  String get fVia => 'ಮೂಲಕ ಹಬ್';

  @override
  String get fL2Hub => 'L2 ಹಬ್';

  @override
  String get fL1Hub => 'L1 ಹಬ್';

  @override
  String get fDirect => 'ನೇರ ಮುಚ್ಚುವಿಕೆ (Y/N)';

  @override
  String get dirSource => 'ಮೂಲ';

  @override
  String get dirRows => 'ಕಚೇರಿಗಳು';

  @override
  String get dirFileDate => 'ಮಾಹಿತಿ ಫೈಲ್ ದಿನಾಂಕ';

  @override
  String get dirBuilt => 'ನಿರ್ಮಿಸಿದ ದಿನಾಂಕ';

  @override
  String get dirStateFilter => 'ರಾಜ್ಯ ಫಿಲ್ಟರ್';

  @override
  String get dirSearchIndex => 'ಹುಡುಕಾಟ ಸೂಚ್ಯಂಕ';

  @override
  String get dirPlaceholderWarning =>
      'ಇದು ಕೇವಲ ಸಣ್ಣ ಪರೀಕ್ಷಾ ಡೈರೆಕ್ಟರಿ. ಕೆಳಗೆ data.gov.in ನ ಪೂರ್ಣ \"All India Pincode Directory\" CSV ಆಮದು ಮಾಡಿ.';

  @override
  String get dirUpdateHelp =>
      'data.gov.in ನಿಂದ ಹೊಸ \"All India Pincode Directory\" CSV ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ, ಈ ಫೋನಿಗೆ ನಕಲಿಸಿ, ನಂತರ ಇಲ್ಲಿ ಆಮದು ಮಾಡಿ. ಇಡೀ ಭಾರತಕ್ಕೆ ರಾಜ್ಯವನ್ನು ಖಾಲಿ ಬಿಡಿ.';

  @override
  String get dirStateOnly => 'ಈ ರಾಜ್ಯ ಮಾತ್ರ (ಐಚ್ಛಿಕ)';

  @override
  String get updateDirectory => 'CSV ಯಿಂದ ಪಿನ್ ಡೈರೆಕ್ಟರಿ ನವೀಕರಿಸಿ';

  @override
  String get dirParsing => 'CSV ಓದಿ ಸ್ವಚ್ಛಗೊಳಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String get dirWriting => 'ಆಫ್‌ಲೈನ್ ಡೇಟಾಬೇಸ್ ನಿರ್ಮಿಸಲಾಗುತ್ತಿದೆ…';

  @override
  String directoryUpdated(int count) {
    return 'ಡೈರೆಕ್ಟರಿ ನವೀಕರಿಸಲಾಗಿದೆ: $count ಕಚೇರಿಗಳು';
  }

  @override
  String get help1Title => 'ನಿಮ್ಮ ಸ್ಕೀಮ್ ಆಮದು ಮಾಡಿ';

  @override
  String get help1 =>
      'ಇನ್ನಷ್ಟು → ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್‌ಗಳು → ಸೇರಿಸಿ. ನಿಮ್ಮ ಕಚೇರಿಯ Excel/CSV ಆಯ್ಕೆಮಾಡಿ, ಕಾಲಂಗಳನ್ನು ಪರಿಶೀಲಿಸಿ ಉಳಿಸಿ. ಫೈಲ್ ಇಲ್ಲವೇ? ಟೆಂಪ್ಲೇಟ್ ಡೌನ್‌ಲೋಡ್ ಮಾಡಿ ಅಥವಾ ಮಾದರಿ ಸ್ಕೀಮ್ (ನಕಲಿ ಮಾಹಿತಿ) ಪ್ರಯತ್ನಿಸಿ.';

  @override
  String get help2Title => 'ಪಿನ್ ಮೂಲಕ ಸಾರ್ಟ್';

  @override
  String get help2 =>
      'ದೊಡ್ಡ ಕೀಪ್ಯಾಡ್‌ನಲ್ಲಿ ಪಿನ್ ಟೈಪ್ ಮಾಡಿ. 3 ಅಂಕಿಗಳ ನಂತರ ಸಾರ್ಟಿಂಗ್ ಜಿಲ್ಲೆ ಮತ್ತು ಸಂಭವನೀಯ ಚೀಲ; 6 ಅಂಕಿಗಳ ನಂತರ ಅಂತಿಮ ಚೀಲ ಅದರ ಬಣ್ಣದಲ್ಲಿ. ಮುಂದಿನ ಅಂಕಿ ಟೈಪ್ ಮಾಡಿದರೆ ಹೊಸ ಪಿನ್ ಪ್ರಾರಂಭ. ಅಳಿಸಲು ⌫ ದೀರ್ಘವಾಗಿ ಒತ್ತಿ.';

  @override
  String get help3Title => 'ಪಾರ್ಸೆಲ್ ಮತ್ತು ಏರ್ ಪಾರ್ಸೆಲ್';

  @override
  String get help3 =>
      'ಮೇಲ್ಭಾಗದಲ್ಲಿ ಅಂಚೆ ವರ್ಗ ಆಯ್ಕೆಮಾಡಿ. ಏರ್ ಪಾರ್ಸೆಲ್ ಮೋಡ್‌ನಲ್ಲಿ ವಾಯು ಲೇಬಲ್ ಕೋಡ್ ದೊಡ್ಡ ಅಕ್ಷರಗಳಲ್ಲಿ, ಹಳದಿ AIR / ನೀಲಿ SURFACE ಬ್ಯಾಡ್ಜ್, L2 → L1 ಹಬ್ ಮಾರ್ಗ ಮತ್ತು ಚೀಲ ತೋರಿಸಲಾಗುತ್ತದೆ. ದೊಡ್ಡ ಲೇಬಲ್ ತೋರಿಸಲು ಅಥವಾ ಹಂಚಲು \"ಲೇಬಲ್ ನೋಟ\" ಬಳಸಿ.';

  @override
  String get help4Title => 'ವಸ್ತುವಿನಲ್ಲಿ ಪಿನ್ ಇಲ್ಲವೇ?';

  @override
  String get help4 =>
      'ಪಿನ್ ಹುಡುಕಿ: ಕಚೇರಿ, ಗ್ರಾಮ, ನಗರ, ತಾಲ್ಲೂಕು ಅಥವಾ ಜಿಲ್ಲೆಯನ್ನು ಇಂಗ್ಲಿಷ್, ಕನ್ನಡ ಅಥವಾ ಹಿಂದಿಯಲ್ಲಿ ಟೈಪ್ ಮಾಡಿ. ಕಾಗುಣಿತ ತಪ್ಪುಗಳನ್ನು ಸಹಿಸುತ್ತದೆ. ಪ್ರತಿ ಫಲಿತಾಂಶ ಅದರ ಚೀಲ ತೋರಿಸುತ್ತದೆ.';

  @override
  String get help5Title => 'ತಪ್ಪು ಪಿನ್ ಪತ್ತೆಹಚ್ಚಿ';

  @override
  String get help5 =>
      'ಸ್ಥಳ ಪರಿಶೀಲನೆ ಆನ್ ಮಾಡಿ (ಸಾರ್ಟ್‌ನಲ್ಲಿ ✓ ಐಕಾನ್) ಮತ್ತು ವಸ್ತುವಿನ ಮೇಲೆ ಬರೆದ ನಗರ ಟೈಪ್ ಮಾಡಿ. ✅ ಹೊಂದಿಕೆ, ⚠️ ಅದೇ ಜಿಲ್ಲೆ ಆದರೆ ಬೇರೆ ಪಿನ್, ❌ ಬೇರೆ ಜಿಲ್ಲೆ/ರಾಜ್ಯ – ಸೂಚಿಸಿದ ಪಿನ್‌ಗಳೊಂದಿಗೆ.';

  @override
  String get help6Title => 'ವಿಳಾಸ ಸ್ಕ್ಯಾನ್ ಮಾಡಿ';

  @override
  String get help6 =>
      'ಸ್ಕ್ಯಾನ್ ಐಕಾನ್ ಒತ್ತಿ, ಕ್ಯಾಮೆರಾವನ್ನು ವಿಳಾಸದ ಕಡೆ ಹಿಡಿದು ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿ. ಪಿನ್ ಮತ್ತು ನಗರವನ್ನು ಫೋನಿನಲ್ಲೇ ಓದಲಾಗುತ್ತದೆ; ಫೋಟೋ ತಕ್ಷಣ ಅಳಿಸಲಾಗುತ್ತದೆ.';

  @override
  String get help7Title => 'ಚೀಲವಾರು ವಸ್ತುಗಳನ್ನು ಎಣಿಸಿ';

  @override
  String get help7 =>
      'ಗುಂಪು → ಸೆಷನ್ ಪ್ರಾರಂಭಿಸಿ. ಪಿನ್‌ಗಳನ್ನು ಒಂದರ ನಂತರ ಒಂದು ನಮೂದಿಸಿ; ಪ್ರತಿಯೊಂದೂ ಅದರ ಚೀಲದ ಬಣ್ಣ ಮಿಂಚಿಸಿ ಎಣಿಕೆಗೆ ಸೇರುತ್ತದೆ. ಕೊನೆಯದನ್ನು ರದ್ದುಮಾಡಿ, ಪರಿಹರಿಸದವನ್ನು ಸರಿಪಡಿಸಿ, ನಂತರ ಮ್ಯಾನಿಫೆಸ್ಟ್‌ನೊಂದಿಗೆ ತಾಳೆ ಮಾಡಲು ಸಾರಾಂಶ ಹಂಚಿ.';

  @override
  String get help8Title => 'ಅಭ್ಯಾಸ ಮಾಡಿ';

  @override
  String get help8 =>
      'ಅಭ್ಯಾಸ: ಅಂತರದ ಪುನರಾವರ್ತನೆಯ ಫ್ಲ್ಯಾಶ್‌ಕಾರ್ಡ್‌ಗಳು, 20 ವಸ್ತುಗಳ ಸಮಯದ ರಸಪ್ರಶ್ನೆ, ದುರ್ಬಲ ಭಾಗಗಳು ಮತ್ತು ಪಿನ್ ಮೂಲಭೂತ ಪಾಠ. ಹೊಸ DMSL ನಂತರ ಹಬ್ ಬದಲಾದ ಪಿನ್‌ಗಳನ್ನು ಮಾತ್ರ ಅಭ್ಯಾಸ ಮಾಡಿ.';
}

/// App-wide constants.
library;

const String kAppNameEn = 'PO Sorting';
const String kAppNameKn = 'ಪಿಒ ಸಾರ್ಟಿಂಗ್';
const String kAppVersion = '1.0.0';

/// Shown verbatim on the About screen (plus translations).
const String kDisclaimerEn =
    'Independent helper tool for postal staff. Not an official Department of Posts app.';

const String kDataCreditEn =
    'PIN data: data.gov.in, Government of India, Open Government Data Licence';

/// Built-in sorting modes: TD and Non-TD. Users can add more in
/// Settings → Categories (e.g. "Air Parcel", which turns on air codes and
/// parcel hub routes).
const String kCatTD = 'TD';
const String kCatNonTD = 'Non-TD';
const List<String> kBuiltInCategories = [kCatTD, kCatNonTD];

/// Optional custom categories understood by the parcel / air features.
const String kCatLetters = 'Ordinary/Letters';
const String kCatParcel = 'Parcel (surface)';
const String kCatAirParcel = 'Air Parcel';
const String kCatSpeedPost = 'Speed Post';

/// Categories where parcel hub routes (DMSL) and the Air/Surface badge apply.
/// Custom categories count as parcel / air when their name says so.
bool isParcelCategory(String c) =>
    c == kCatParcel || c == kCatAirParcel || c == kCatSpeedPost || c.toLowerCase().contains('parcel');
bool isAirCategory(String c) => c == kCatAirParcel || RegExp(r'\bair\b', caseSensitive: false).hasMatch(c);

/// Marker placed in every sample file / sample scheme name.
const String kSampleMarker = 'SAMPLE – not real';

const int kRecentLimit = 20;

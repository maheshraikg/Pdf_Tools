/// Languages the app speaks. Add a language by adding an ARB file
/// (lib/l10n/app_<code>.arb), audio in assets/audio/<code>/ and a row here.
class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;
}

class Languages {
  Languages._();

  /// Kannada first: it is the default.
  static const all = <AppLanguage>[
    AppLanguage('kn', 'ಕನ್ನಡ', 'Kannada'),
    AppLanguage('en', 'English', 'English'),
    AppLanguage('hi', 'हिन्दी', 'Hindi'),
    AppLanguage('mr', 'मराठी', 'Marathi'),
    AppLanguage('ta', 'தமிழ்', 'Tamil'),
    AppLanguage('te', 'తెలుగు', 'Telugu'),
    AppLanguage('ml', 'മലയാളം', 'Malayalam'),
    AppLanguage('bn', 'বাংলা', 'Bengali'),
    AppLanguage('gu', 'ગુજરાતી', 'Gujarati'),
    AppLanguage('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
    AppLanguage('or', 'ଓଡ଼ିଆ', 'Odia'),
    AppLanguage('ur', 'اردو', 'Urdu'),
  ];

  static AppLanguage byCode(String code) => all.firstWhere((l) => l.code == code, orElse: () => all.first);
}

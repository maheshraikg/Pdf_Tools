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
}

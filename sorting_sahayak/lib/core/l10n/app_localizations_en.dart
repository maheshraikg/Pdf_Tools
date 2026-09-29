// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sorting Sahayak';

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
}

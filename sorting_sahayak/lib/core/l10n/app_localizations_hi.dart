// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'सॉर्टिंग सहायक';

  @override
  String get navSort => 'सॉर्ट';

  @override
  String get navFindPin => 'पिन खोजें';

  @override
  String get navBulk => 'बल्क';

  @override
  String get navLearn => 'अभ्यास';

  @override
  String get navMore => 'और';

  @override
  String get disclaimer =>
      'डाक कर्मचारियों के लिए स्वतंत्र सहायक टूल। यह डाक विभाग का आधिकारिक ऐप नहीं है।';

  @override
  String get dataCredit =>
      'पिन डेटा: data.gov.in, भारत सरकार, ओपन गवर्नमेंट डेटा लाइसेंस';

  @override
  String get ok => 'ठीक है';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सहेजें';

  @override
  String get delete => 'हटाएं';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get close => 'बंद करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get copied => 'कॉपी हो गया';

  @override
  String get share => 'शेयर करें';

  @override
  String get search => 'खोजें';

  @override
  String get next => 'आगे';

  @override
  String get back => 'पीछे';

  @override
  String get done => 'हो गया';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get loading => 'लोड हो रहा है…';

  @override
  String error(String message) {
    return 'त्रुटि: $message';
  }

  @override
  String confirmDelete(String name) {
    return '\"$name\" हटाएं?';
  }

  @override
  String get sampleBadge => 'नमूना – असली नहीं';

  @override
  String get noActiveScheme =>
      'कोई सॉर्टिंग स्कीम सक्रिय नहीं है। और → स्कीम में अपने कार्यालय की स्कीम आयात करें (या नमूना उपयोग करें)।';

  @override
  String get useSample => 'नमूना स्कीम उपयोग करें';
}

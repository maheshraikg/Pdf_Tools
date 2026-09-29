/// Converts spoken digits (English, Kannada, Hindi words or numerals) from
/// the speech recogniser into a digit string.
library;

import 'pin_utils.dart';

const Map<String, String> _words = {
  // English
  'zero': '0', 'oh': '0', 'o': '0', 'one': '1', 'two': '2', 'to': '2', 'too': '2', 'three': '3', //
  'four': '4', 'for': '4', 'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
  // Kannada
  'ಸೊನ್ನೆ': '0', 'ಶೂನ್ಯ': '0', 'ಒಂದು': '1', 'ಎರಡು': '2', 'ಮೂರು': '3', 'ನಾಲ್ಕು': '4', //
  'ಐದು': '5', 'ಆರು': '6', 'ಏಳು': '7', 'ಎಂಟು': '8', 'ಒಂಬತ್ತು': '9',
  // Hindi
  'शून्य': '0', 'जीरो': '0', 'ज़ीरो': '0', 'एक': '1', 'दो': '2', 'तीन': '3', 'चार': '4', //
  'पांच': '5', 'पाँच': '5', 'छह': '6', 'छः': '6', 'छे': '6', 'सात': '7', 'आठ': '8', 'नौ': '9',
};

const Map<String, int> _repeat = {'double': 2, 'triple': 3, 'ಡಬಲ್': 2, 'डबल': 2};

/// "five seven four two zero one" → "574201"; "ಐದು ಏಳು ನಾಲ್ಕು ೨೦೧" → "574201";
/// "574 double 0 1" → "574001".
String spokenToDigits(String text) {
  final tokens = PinUtils.normalizeDigits(text.toLowerCase()).split(RegExp(r'[\s,.\-]+')).where((t) => t.isNotEmpty);
  final out = StringBuffer();
  var times = 1;
  for (final t in tokens) {
    if (_repeat.containsKey(t)) {
      times = _repeat[t]!;
      continue;
    }
    String? d;
    if (RegExp(r'^\d+$').hasMatch(t)) {
      d = t;
    } else {
      d = _words[t];
    }
    if (d == null) {
      times = 1;
      continue;
    }
    if (times > 1 && d.isNotEmpty) {
      out.write(d[0] * times);
      out.write(d.substring(1));
    } else {
      out.write(d);
    }
    times = 1;
  }
  return out.toString();
}

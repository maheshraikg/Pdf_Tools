/// PIN code helpers: validation, structure breakdown and extraction from
/// free text (OCR output, typed addresses, voice transcripts).
library;

/// Postal zone (first digit). 9 is the Army Postal Service.
const Map<int, String> kPinZones = {
  1: 'Northern (Delhi, Haryana, Punjab, Himachal, J&K, Ladakh)',
  2: 'Northern (Uttar Pradesh, Uttarakhand)',
  3: 'Western (Rajasthan, Gujarat)',
  4: 'Western (Maharashtra, Goa, Madhya Pradesh, Chhattisgarh)',
  5: 'Southern (Andhra Pradesh, Telangana, Karnataka)',
  6: 'Southern (Tamil Nadu, Kerala, Puducherry, Lakshadweep)',
  7: 'Eastern (West Bengal, Odisha, Assam, North East, Sikkim, A&N)',
  8: 'Eastern (Bihar, Jharkhand)',
  9: 'Army Postal Service (APS / FPO)',
};

/// First two digits of a PIN → postal circle. Some circles share digit
/// pairs with neighbours (e.g. Goa 403 inside Maharashtra's 40–44); those are
/// refined by [circleForPin] when three digits are available.
final Map<int, String> kPinCircles = {
  11: 'Delhi',
  12: 'Haryana',
  13: 'Haryana',
  14: 'Punjab',
  15: 'Punjab',
  16: 'Punjab / Chandigarh',
  17: 'Himachal Pradesh',
  18: 'Jammu & Kashmir',
  19: 'Jammu & Kashmir / Ladakh',
  for (var i = 20; i <= 23; i++) i: 'Uttar Pradesh',
  24: 'Uttar Pradesh / Uttarakhand',
  25: 'Uttar Pradesh',
  26: 'Uttarakhand / Uttar Pradesh',
  27: 'Uttar Pradesh',
  28: 'Uttar Pradesh',
  for (var i = 30; i <= 34; i++) i: 'Rajasthan',
  for (var i = 36; i <= 39; i++) i: 'Gujarat',
  for (var i = 40; i <= 44; i++) i: 'Maharashtra',
  for (var i = 45; i <= 48; i++) i: 'Madhya Pradesh',
  49: 'Chhattisgarh',
  50: 'Telangana',
  51: 'Andhra Pradesh',
  52: 'Andhra Pradesh',
  53: 'Andhra Pradesh',
  for (var i = 56; i <= 59; i++) i: 'Karnataka',
  for (var i = 60; i <= 64; i++) i: 'Tamil Nadu',
  for (var i = 67; i <= 69; i++) i: 'Kerala',
  for (var i = 70; i <= 74; i++) i: 'West Bengal',
  for (var i = 75; i <= 77; i++) i: 'Odisha',
  78: 'Assam',
  79: 'North East',
  80: 'Bihar',
  81: 'Bihar / Jharkhand',
  82: 'Bihar / Jharkhand',
  83: 'Jharkhand',
  84: 'Bihar',
  85: 'Bihar',
  for (var i = 90; i <= 99; i++) i: 'Army Postal Service',
};

/// Three-digit refinements where a smaller circle sits inside a bigger one.
const Map<String, String> kPinCircleOverrides = {
  '403': 'Goa',
  '160': 'Chandigarh',
  '194': 'Ladakh',
  '737': 'Sikkim',
  '744': 'Andaman & Nicobar',
  '682': 'Kerala / Lakshadweep',
  '605': 'Puducherry / Tamil Nadu',
  '396': 'Gujarat / Dadra & Nagar Haveli, Daman & Diu',
};

class PinBreakdown {
  const PinBreakdown({
    required this.digits,
    this.zoneDigit,
    this.zoneName,
    this.circleCode,
    this.circleName,
    this.sortingDistrict,
    this.deliveryOffice,
  });

  /// The (possibly partial) digits the breakdown was computed from.
  final String digits;
  final String? zoneDigit;
  final String? zoneName;

  /// First two digits.
  final String? circleCode;
  final String? circleName;

  /// First three digits.
  final String? sortingDistrict;

  /// Last three digits (only when all six are known).
  final String? deliveryOffice;

  bool get isComplete => digits.length == 6;
}

class PinUtils {
  PinUtils._();

  static final RegExp _validPin = RegExp(r'^[1-9][0-9]{5}$');

  /// True for exactly six ASCII digits, the first one 1–9.
  static bool isValid(String? pin) => pin != null && _validPin.hasMatch(pin);

  /// True when [partial] could still become a valid PIN (0–6 digits, no
  /// leading zero).
  static bool isValidPrefix(String partial) =>
      RegExp(r'^([1-9][0-9]{0,5})?$').hasMatch(partial);

  /// Converts Kannada (೦–೯) and Devanagari (०–९) digits to ASCII 0–9.
  static String normalizeDigits(String input) {
    final sb = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x0CE6 && rune <= 0x0CEF) {
        sb.writeCharCode(0x30 + rune - 0x0CE6);
      } else if (rune >= 0x0966 && rune <= 0x096F) {
        sb.writeCharCode(0x30 + rune - 0x0966);
      } else if (rune >= 0xFF10 && rune <= 0xFF19) {
        // Full-width digits sometimes come out of OCR / keyboards.
        sb.writeCharCode(0x30 + rune - 0xFF10);
      } else {
        sb.writeCharCode(rune);
      }
    }
    return sb.toString();
  }

  static String? circleForPin(String digits) {
    if (digits.length >= 3) {
      final o = kPinCircleOverrides[digits.substring(0, 3)];
      if (o != null) return o;
    }
    if (digits.length < 2) return null;
    return kPinCircles[int.parse(digits.substring(0, 2))];
  }

  /// Breaks a partial or complete PIN into its parts. Returns null when the
  /// input is empty or not a valid prefix.
  static PinBreakdown? breakdown(String input) {
    final d = normalizeDigits(input).replaceAll(RegExp(r'\s'), '');
    if (d.isEmpty || !isValidPrefix(d)) return null;
    final zone = d.substring(0, 1);
    return PinBreakdown(
      digits: d,
      zoneDigit: zone,
      zoneName: kPinZones[int.parse(zone)],
      circleCode: d.length >= 2 ? d.substring(0, 2) : null,
      circleName: circleForPin(d),
      sortingDistrict: d.length >= 3 ? d.substring(0, 3) : null,
      deliveryOffice: d.length == 6 ? d.substring(3) : null,
    );
  }

  // Characters OCR commonly confuses with digits.
  static const Map<String, String> _ocrFix = {
    'O': '0', 'o': '0', 'D': '0', 'Q': '0', //
    'I': '1', 'l': '1', '|': '1', 'i': '1', //
    'S': '5', 's': '5', //
    'B': '8', //
    'Z': '2', 'z': '2', //
  };

  static const String _dl = r'0-9OoDQIl|iSsBZz';

  /// A 3+3 digit-like group, optionally split by a space/dash/dot, not glued
  /// to other letters/digits.
  static final RegExp _candidate = RegExp(
    '(?<![A-Za-z0-9])([$_dl]{3})[ \\t\\-–.]{0,3}([$_dl]{3})(?![A-Za-z0-9])',
  );

  static final RegExp _pinLabel = RegExp(
    r'(?<![A-Za-z])(p\.?\s?i\.?\s?n\.?(\s?code)?|pincode|postal\s?code|ಪಿನ್(\s?ಕೋಡ್)?|पिन(\s?कोड)?)\s*(no\.?)?\s*[:\-–.#]?\s*',
    caseSensitive: false,
  );

  /// Extracts valid PINs from arbitrary text, most likely first (PINs right
  /// after a "PIN" label are ranked first, then by position). Handles
  /// "574 201", "574-201", "PIN:574201", Kannada/Devanagari digits, and OCR
  /// confusions (O→0, I/l→1, S→5, B→8) inside six-character digit-like
  /// tokens that already contain at least three real digits.
  static List<String> extractPins(String text) {
    var t = normalizeDigits(text);
    // Mark labelled positions, then drop the label so "PIN574201" works.
    t = t.replaceAll(_pinLabel, ' \u0001 ');
    final found = <({String pin, bool labelled, int pos})>[];
    for (final m in _candidate.allMatches(t)) {
      final raw = '${m.group(1)}${m.group(2)}';
      final realDigits = raw.replaceAll(RegExp(r'[^0-9]'), '').length;
      if (realDigits < 3) continue;
      final fixed = raw.split('').map((c) => _ocrFix[c] ?? c).join();
      if (!isValid(fixed)) continue;
      final before = t.substring(0, m.start).trimRight();
      final isLabelled = before.endsWith('\u0001');
      found.add((pin: fixed, labelled: isLabelled, pos: m.start));
    }
    found.sort((a, b) {
      if (a.labelled != b.labelled) return a.labelled ? -1 : 1;
      return a.pos.compareTo(b.pos);
    });
    final out = <String>[];
    for (final f in found) {
      if (!out.contains(f.pin)) out.add(f.pin);
    }
    return out;
  }

  /// Keeps only digits (after digit normalisation), useful for keypad/voice
  /// input such as "five seven four" already converted to digits.
  static String digitsOnly(String input) =>
      normalizeDigits(input).replaceAll(RegExp(r'[^0-9]'), '');
}

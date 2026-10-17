/// Heuristic parser for addresses read by OCR (English / Hindi) or typed.
///
/// It extracts the parts that matter for matching a mail article to a saved
/// place: addressee names, door number, street, area, landmark, PIN, phone
/// and an article number if the label was photographed too.
library;

import 'article_number.dart';
import 'fuzzy.dart';
import 'transliterate.dart';

class ParsedAddress {
  ParsedAddress({
    this.names = const [],
    this.doorNo,
    this.street,
    this.area,
    this.landmark,
    this.pin,
    this.phone,
    this.articleNo,
    this.lines = const [],
  });

  final List<String> names;
  final String? doorNo;
  final String? street;
  final String? area;
  final String? landmark;
  final String? pin;
  final String? phone;
  final String? articleNo;
  final List<String> lines;

  bool get isEmpty => names.isEmpty && doorNo == null && street == null && pin == null && area == null;

  /// Single-line text suitable for a general fuzzy search.
  String toQuery() => [...names, ?doorNo, ?street, ?area].join(' ');

  @override
  String toString() =>
      'ParsedAddress(names: $names, door: $doorNo, street: $street, area: $area, '
      'landmark: $landmark, pin: $pin, phone: $phone, article: $articleNo)';
}

final _pinRe = RegExp(r'(?<!\d)([1-9]\d{2})\s?(\d{3})(?!\d)');
final _phoneRe = RegExp(r'(?<!\d)(?:\+?91[\s-]?)?([6-9]\d{4})[\s-]?(\d{5})(?!\d)');
final _articleRe = RegExp(r'\b([A-Z]{2})\s?(\d{3})\s?(\d{3})\s?(\d{3})\s?([A-Z]{2})\b');

/// Salutations and "to" lines (English + Hindi), compared after transliteration.
const _toLineKeys = {'to', 'sevamen', 'seveme', 'sevame', 'prati', 'shriman', 'kke', 'ige'};

bool _isToLine(String latin) => _toLineKeys.contains(latin.replaceAll(RegExp(r'[^a-z]'), '').replaceAll('aa', 'a'));
final _honorific = RegExp(
  r'^(shri|sri|smt|shrimati|kumari|kum|mr|mrs|ms|miss|dr|prof|m/s|sushri)\b\.?\s*',
  caseSensitive: false,
);
final _careOf = RegExp(r'^(c/o|c\.o\.|care of|d/o|s/o|w/o)\s*', caseSensitive: false);

final _doorRe = RegExp(
  r'(?:^|\b)(?:h\.?\s*no|d\.?\s*no|door\s*no|house\s*no|flat\s*no|plot\s*no|site\s*no|no|makaan\s*n|makan\s*n|mkan\s*n|m\.?\s*n|naan|nan|ghar\s*n)\.?\s*[:.]?\s*'
  r'(\d+[a-z]?(?:\s*[/\-]\s*\d+[a-z]?)*)',
  caseSensitive: false,
);
final _hashDoorRe = RegExp(r'#\s*(\d+[a-z]?(?:\s*[/\-]\s*\d+[a-z]?)*)', caseSensitive: false);
final _leadingDoorRe = RegExp(r'^(\d+[a-zA-Z]?(?:\s*[/\-]\s*\d+[a-zA-Z]?)*)\s*[,\s]');

/// Words that mark a street line.
final _streetWords = RegExp(
  r'\b(cross|main|road|rd|street|st|lane|marg|path|gali|galee|gully|avenue|ave|block|sector|phase|stage|layout|extension|extn|colony|circle|chowk|ward|mohalla|nagar|bazaar|bazar|pet|halli|palya|puram|pura)\b',
  caseSensitive: false,
);
final _primaryStreetWords = RegExp(
  r'\b(cross|main|road|rd|street|lane|marg|gali|galee|gully|avenue)\b',
  caseSensitive: false,
);
final _landmarkRe = RegExp(
  r'\b(near|opp|opposite|behind|beside|next to|pas|ke paas|ke pass|samne|saamne|saamane)\b\.?\s*',
  caseSensitive: false,
);
final _cityWords = RegExp(
  r'\b(bengaluru|bangalore|mysuru|mysore|mumbai|delhi|new delhi|jaipur|hubli|hubballi|mangaluru|mangalore|chennai|hyderabad|pune|kolkata|lucknow|patna|bhopal|dist|district|taluk|tq|state|karnataka|rajasthan|india|post|po|h\.o|s\.o|head office)\b',
  caseSensitive: false,
);
final _articleTypeLine = RegExp(
  r'^(speed post|registered|regd|parcel|money order|ems|book post|ssp|rpad)\b',
  caseSensitive: false,
);

/// Parses OCR text / a typed address into its parts.
ParsedAddress parseAddress(String text) {
  final rawLines = text.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  String? articleNo;
  final upper = text.toUpperCase();
  for (final m in _articleRe.allMatches(upper)) {
    final candidate = '${m[1]}${m[2]}${m[3]}${m[4]}${m[5]}';
    if (isS10ArticleNumber(candidate)) {
      articleNo = candidate;
      break;
    }
  }

  String? pin;
  String? phone;
  String? doorNo;
  String? landmark;
  final names = <String>[];
  final streetParts = <String>[];
  final areaParts = <String>[];
  final lines = <String>[];

  var nameLinesAllowed = true;
  for (final original in rawLines) {
    var line = original;
    final latin = transliterate(line).toLowerCase().trim();
    // Skip label noise.
    if (_articleTypeLine.hasMatch(latin)) continue;
    if (articleNo != null && line.toUpperCase().replaceAll(' ', '').contains(articleNo)) continue;
    if (_isToLine(latin)) continue;
    lines.add(line);

    // Phone.
    final pm = _phoneRe.firstMatch(transliterate(line));
    if (pm != null && phone == null) {
      phone = '${pm[1]}${pm[2]}';
      line = line.replaceFirst(RegExp(r'(ph|phone|mob|mobile|mo|tel|फोन|मो)\.?\s*[:.]?\s*', caseSensitive: false), '');
      line = transliterate(line).replaceFirst(pm[0]!, '').trim();
      if (line.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').isEmpty) continue;
    }

    // PIN.
    final latinLine = transliterate(line);
    final pinMatch = _pinRe.allMatches(latinLine).lastOrNull;
    if (pinMatch != null) {
      pin ??= '${pinMatch[1]}${pinMatch[2]}';
      final rest = latinLine.replaceFirst(pinMatch[0]!, '').replaceAll(RegExp(r'[\s,\-:]+$'), '').trim();
      final restClean = rest.replaceAll(_cityWords, '').replaceAll(RegExp(r'[^A-Za-z]'), '');
      if (restClean.isEmpty) continue;
      // Area before the PIN ("Jayanagar 560011") is kept unless it is just a city.
      if (_cityWords.hasMatch(rest) && rest.split(RegExp(r'\s+')).length <= 2) continue;
      line = original.replaceAll(RegExp(r'[\-–]?\s*[1-9]\d{2}\s?\d{3}\s*$'), '').trim();
      line = line.replaceAll(RegExp(r'[1-9]\d{2}\s?\d{3}'), '').replaceAll(RegExp(r'[\s,\-:]+$'), '').trim();
      if (transliterate(line).replaceAll(_cityWords, '').replaceAll(RegExp(r'[^A-Za-z]'), '').isEmpty) continue;
    }

    // Landmark.
    final lmLatin = transliterate(line);
    final lm = _landmarkRe.firstMatch(lmLatin);
    if (lm != null && landmark == null && !RegExp(r'\d').hasMatch(lmLatin.substring(0, lm.start))) {
      var lmText = lmLatin.substring(lm.end).replaceAll(RegExp(r'^[\s,:]+|[\s,.]+$'), '');
      if (lmText.isEmpty && lm.start > 0) {
        // Hindi / Kannada put the marker last: "मंदिर के पास".
        lmText = hasIndicScript(line)
            ? line.replaceAll(RegExp(r'[\s,]*(के\s*पास|के\s*सामने|ಹತ್ತಿರ|ಎದುರು)[\s.,]*$'), '').trim()
            : lmLatin.substring(0, lm.start).trim();
      }
      landmark = lmText.isEmpty ? null : lmText;
      nameLinesAllowed = false;
      continue;
    }

    // Door number.
    var consumedDoor = false;
    final dLatin = transliterate(line);
    final dm = _doorRe.firstMatch(dLatin) ?? _hashDoorRe.firstMatch(dLatin);
    final leading = _leadingDoorRe.firstMatch('$dLatin ');
    if (doorNo == null && (dm != null || leading != null)) {
      final m = dm ?? leading!;
      final candidate = normalizeDoorNo(m[1]!);
      if (candidate.isNotEmpty && !_isOrdinalAt(dLatin, m.end)) {
        doorNo = candidate;
        consumedDoor = true;
        var rest = dLatin.replaceFirst(m[0]!, ' ');
        rest = rest.replaceAll(RegExp(r'^[\s,:\-]+|[\s,:\-]+$'), '');
        line = rest;
        nameLinesAllowed = false;
        if (line.isEmpty) continue;
      }
    }

    final lineLatin = transliterate(line).toLowerCase();
    final isStreet = _streetWords.hasMatch(lineLatin);
    final hasDigits = RegExp(r'\d').hasMatch(lineLatin);

    if (nameLinesAllowed && !consumedDoor && !hasDigits && !isStreet && names.length < 3) {
      final cleaned = _cleanName(line);
      if (cleaned.isNotEmpty) {
        names.add(cleaned);
        continue;
      }
    }
    nameLinesAllowed = false;

    if (isStreet) {
      if (_primaryStreetWords.hasMatch(lineLatin) || streetParts.isEmpty && consumedDoor) {
        streetParts.add(_tidy(consumedDoor ? _maybeOriginal(original, line) : line));
      } else {
        areaParts.add(_tidy(line));
      }
    } else if (consumedDoor) {
      streetParts.add(_tidy(_maybeOriginal(original, line)));
    } else {
      final t = _tidy(line);
      if (t.isNotEmpty && !_cityWords.hasMatch(transliterate(t).toLowerCase())) areaParts.add(t);
    }
  }

  // If no street words were found, treat the first area part as the street.
  if (streetParts.isEmpty && areaParts.length > 1) streetParts.add(areaParts.removeAt(0));

  return ParsedAddress(
    names: names,
    doorNo: doorNo,
    street: streetParts.isEmpty ? null : streetParts.join(', '),
    area: areaParts.isEmpty ? null : areaParts.join(', '),
    landmark: landmark,
    pin: pin,
    phone: phone,
    articleNo: articleNo,
    lines: lines,
  );
}

bool _isOrdinalAt(String s, int end) => RegExp(r'^(st|nd|rd|th)\b', caseSensitive: false).hasMatch(s.substring(end));

String _cleanName(String line) {
  var s = line.trim();
  s = s.replaceFirst(_careOf, '');
  // Remove honorifics in Latin and Devanagari / Kannada forms.
  s = s.replaceFirst(RegExp(r'^(श्रीमती|श्री|सुश्री|कुमारी|डॉ\.?|ಶ್ರೀಮತಿ|ಶ್ರೀ|ಕುಮಾರಿ)\s*'), '');
  s = s.replaceFirst(_honorific, '');
  s = s.replaceAll(RegExp(r'^[\s,.:]+|[\s,.:]+$'), '');
  return s;
}

String _tidy(String s) => s.replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'^[\s,:\-]+|[\s,:\-.]+$'), '');

/// After removing the door number we work on a transliterated copy; if the
/// original line was Latin anyway keep it, otherwise keep the original script.
String _maybeOriginal(String original, String transliteratedRest) {
  if (!hasIndicScript(original)) return transliteratedRest;
  // Remove a leading door-number phrase from the original line.
  final cut = original.replaceFirst(RegExp(r'^.*?[0-9०-९೦-೯]+(?:\s*[/\-]\s*[0-9०-९೦-೯]+)*\s*[,]?\s*'), '');
  return cut.isEmpty ? transliteratedRest : cut;
}

/// Pulls PIN and place-name candidates out of OCR text.
library;

import '../../core/fuzzy.dart';
import '../../core/pin_utils.dart';
import '../../data/directory_repo.dart';

class AddressCandidates {
  const AddressCandidates(this.pins, this.places);

  final List<String> pins;

  /// Most likely first: lines just above / on the PIN line, then others.
  final List<String> places;
}

final RegExp _junk = RegExp(r'(p\.?\s?i\.?\s?n\.?(\s?code)?|pincode|ಪಿನ್|पिन|dist\.?|district|tq\.?|taluk|post|p\.o\.?|via|to|at)\s*[:\-.]?', caseSensitive: false);

String _clean(String line) => PinUtils.normalizeDigits(line)
    .replaceAll(RegExp(r'[0-9OIlSB]{3}[\s\-]?[0-9OIlSB]{3}'), ' ')
    .replaceAll(_junk, ' ')
    // Keep letters and their vowel signs (Devanagari / Kannada matras).
    .replaceAll(RegExp(r'[^\p{L}\p{M}\s]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

AddressCandidates parseAddress(String text) {
  final lines = text.split(RegExp(r'[\r\n]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  final pins = PinUtils.extractPins(text);
  var pinLine = -1;
  if (pins.isNotEmpty) {
    for (var i = 0; i < lines.length; i++) {
      if (PinUtils.extractPins(lines[i]).contains(pins.first)) {
        pinLine = i;
        break;
      }
    }
  }
  final order = <int>[];
  if (pinLine >= 0) {
    order.addAll([pinLine, pinLine - 1, pinLine - 2, pinLine - 3, pinLine + 1].where((i) => i >= 0 && i < lines.length));
  }
  for (var i = lines.length - 1; i >= 0; i--) {
    if (!order.contains(i)) order.add(i);
  }
  final out = <String>[];
  void add(String s) {
    final t = s.trim();
    if (t.length >= 3 && !out.contains(t)) out.add(t);
  }

  for (final i in order) {
    final c = _clean(lines[i]);
    if (c.isEmpty) continue;
    // Whole line, then its last two words / last word (city usually last).
    add(c);
    final words = c.split(' ');
    if (words.length > 1) {
      add(words.sublist(words.length - 2).join(' '));
      add(words.last);
      add(words.first);
    }
  }
  return AddressCandidates(pins, out.take(15).toList());
}

/// The candidate that best matches a directory office/district, or null.
Future<({String place, double score})?> bestPlace(DirectorySource dir, List<String> candidates, {String? pin}) async {
  ({String place, double score})? best;
  for (final c in candidates.take(10)) {
    if (normalizePlace(c).length < 3) continue;
    final hits = await dir.search(c, limit: 5);
    if (hits.isEmpty) continue;
    var s = hits.first.score;
    // Prefer places that agree with the PIN.
    if (pin != null && hits.any((h) => h.office.pin.substring(0, 3) == pin.substring(0, 3))) s += 0.05;
    if (s >= 0.8 && (best == null || s > best.score)) best = (place: c, score: s);
    if (s >= 1.0) break;
  }
  return best;
}

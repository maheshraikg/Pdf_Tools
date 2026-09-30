/// Pulls PIN and place-name candidates out of OCR text.
library;

import '../../core/fuzzy.dart';
import '../../core/pin_utils.dart';
import '../../data/directory_repo.dart';

class AddressCandidates {
  const AddressCandidates(this.pins, this.places, [this.postNames = const []]);

  final List<String> pins;

  /// Most likely first: lines just above / on the PIN line, then others.
  final List<String> places;

  /// Names written with "post" / "P.O." ("Sulkeri Post", "PO: Kabaka"):
  /// the delivery office the writer meant.
  final List<String> postNames;
}

// "Sulkeri post", "Kabaka P.O.", "Ujire (PO)", "ಸುಲ್ಕೇರಿ ಅಂಚೆ", "करोल बाग डाकघर".
final RegExp _postAfter = RegExp(
  r'([\p{L}\p{M}]{3,}(?:\s[\p{L}\p{M}]{3,})?)\s*[(\-,]?\s*(?:post\b|p\s?\.\s?o\b\.?|po\b|ಅಂಚೆ|डाकघर|डाक)',
  caseSensitive: false,
  unicode: true,
);
// "PO: Kabaka", "Post - Sulkeri", "P.O. Ujire".
final RegExp _postBefore = RegExp(
  r'(?:^|\s)(?:post|p\s?\.\s?o\.?|po)\s*[:\-.]\s*([\p{L}\p{M}]{3,}(?:\s[\p{L}\p{M}]{3,})?)',
  caseSensitive: false,
  unicode: true,
);

const _notOffice = {'head', 'sub', 'branch', 'the', 'near', 'via', 'dist', 'district', 'taluk'};

List<String> _postNames(List<String> lines) {
  final out = <String>[];
  void add(String? raw) {
    final t = (raw ?? '').trim();
    if (t.isEmpty) return;
    final words = t.split(RegExp(r'\s+')).where((w) => !_notOffice.contains(w.toLowerCase())).toList();
    if (words.isEmpty) return;
    for (final w in [words.join(' '), words.last]) {
      if (w.length >= 3 && !out.contains(w)) out.add(w);
    }
  }

  for (final line in lines) {
    for (final m in _postAfter.allMatches(line)) {
      add(m.group(1));
    }
    for (final m in _postBefore.allMatches(line)) {
      add(m.group(1));
    }
  }
  return out;
}

final RegExp _junk = RegExp(
  r'(?<![\p{L}\p{M}])(p\.?\s?i\.?\s?n\.?(\s?code)?|pincode|dist\.?|district|tq\.?|taluk|post|p\.o\.?|po|via|to|at)(?![\p{L}\p{M}])\s*[:\-.]?|ಪಿನ್|पिन|ಅಂಚೆ|डाकघर',
  caseSensitive: false,
  unicode: true,
);

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
  final posts = _postNames(lines);
  // A name written with "post" is the most likely office: search it first.
  final places = [...posts, ...out.where((p) => !posts.contains(p))];
  return AddressCandidates(pins, places.take(15).toList(), posts);
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

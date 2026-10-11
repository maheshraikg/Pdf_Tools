/// Kannada-script → Devanagari / Malayalam / Telugu transliteration.
///
/// The Brahmi-derived scripts share one Unicode layout, so most letters map
/// by a fixed offset; the exceptions below cover short/long e and o (Hindi
/// has no short e/o), ಳ (Hindi uses ल), ಱ and ೞ.
library;

import 'tulu_lipi.dart';

enum IndicScript { devanagari, malayalam, telugu }

const int _knStart = 0x0C80, _knEnd = 0x0CFF;

final Map<String, String> _cache = {};

String transliterateKannada(String input, IndicScript to) {
  final key = '${to.index}$input';
  final hit = _cache[key];
  if (hit != null) return hit;
  final buf = StringBuffer();
  for (final r in TuluLipi.normalizeKannada(input).runes) {
    if (r < _knStart || r > _knEnd) {
      buf.writeCharCode(r);
      continue;
    }
    buf.writeCharCode(_map(r, to));
  }
  final out = buf.toString();
  if (_cache.length > 4000) _cache.clear();
  return _cache[key] = out;
}

int _map(int r, IndicScript to) {
  switch (to) {
    case IndicScript.devanagari:
      return switch (r) {
        0x0C8E => 0x090F, // ಎ → ए
        0x0C92 => 0x0913, // ಒ → ओ
        0x0CC6 => 0x0947, // ೆ → े
        0x0CCA => 0x094B, // ೊ → ो
        0x0CB3 => 0x0932, // ಳ → ल (Hindi)
        0x0CB1 => 0x0930, // ಱ → र
        0x0CDE => 0x0933, // ೞ → ळ
        _ => r - 0x0380,
      };
    case IndicScript.malayalam:
      return switch (r) {
        0x0CDE => 0x0D34, // ೞ → ഴ
        _ => r + 0x0080,
      };
    case IndicScript.telugu:
      return switch (r) {
        0x0CDE => 0x0C33, // ೞ → ళ
        _ => r - 0x0080,
      };
  }
}

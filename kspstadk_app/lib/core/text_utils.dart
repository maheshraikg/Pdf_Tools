import 'package:html/parser.dart' as html_parser;

/// Decodes HTML entities (`&#8211;`, `&amp;`, `&nbsp;` …) and strips tags.
String plainText(String? html) {
  if (html == null || html.isEmpty) return '';
  final text = html_parser.parseFragment(html).text ?? '';
  return text.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Excerpt without WordPress' "Read more" container and ellipsis entity.
String cleanExcerpt(String? html) {
  if (html == null) return '';
  final noMore = html.replaceAll(
      RegExp(r'<p class="read-more-container">.*?</p>', dotAll: true), '');
  return plainText(noMore).replaceAll(RegExp(r'\s*…\s*$'), '…');
}

/// Reading time in whole minutes (min 1). Kannada words are longer than
/// English ones, so 180 words/min is a fair middle.
int readingMinutes(String html) {
  final words = plainText(html).split(' ').where((w) => w.isNotEmpty).length;
  return (words / 180).ceil().clamp(1, 120);
}

const _kannadaDigits = ['೦', '೧', '೨', '೩', '೪', '೫', '೬', '೭', '೮', '೯'];

/// Replaces ASCII digits with Kannada digits (used sparingly in the UI).
String kannadaDigits(String s) =>
    s.replaceAllMapped(RegExp(r'\d'), (m) => _kannadaDigits[int.parse(m[0]!)]);

/// Human readable byte size.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

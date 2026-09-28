import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_nighantu/lipi/tulu_lipi.dart';

void main() {
  group('TuluLipi.fromKannada', () {
    test('single consonant', () {
      expect(TuluLipi.fromKannada('ಕ'), '\u{11392}');
    });

    test('consonant + vowel sign', () {
      expect(TuluLipi.fromKannada('ಕಾ'), '\u{11392}\u{113B8}');
    });

    test('anusvara', () {
      expect(TuluLipi.fromKannada('ಅಂ'), '\u{11380}\u{113CC}');
    });

    test('virama', () {
      expect(TuluLipi.fromKannada('ಕ್'), '\u{11392}\u{113CE}');
    });

    test('decomposed ಕೊ equals precomposed ಕೊ', () {
      expect(TuluLipi.fromKannada('ಕೊ'), TuluLipi.fromKannada('ಕೊ'));
      expect(TuluLipi.fromKannada('ಕೊ'), '\u{11392}\u{113C7}');
    });

    test('non-Kannada passes through', () {
      expect(TuluLipi.fromKannada('abc 12'), 'abc 12');
    });

    test('joiners are dropped', () {
      expect(TuluLipi.fromKannada('ಕ್‍ಕ'), '\u{11392}\u{113CE}\u{11392}');
    });

    test('never emits unassigned code points', () {
      const unassigned = {0x1138A, 0x1138C, 0x1138D, 0x1138F};
      final out = TuluLipi.fromKannada('ಅಆಇಈಉಊಋಎಏಐಒಓಔ');
      expect(out.runes.where(unassigned.contains), isEmpty);
    });

    test('every consonant maps to one code point in 0x11392–0x113B5', () {
      final consonants = kLipiLetters.where((l) => l.isConsonant).toList();
      expect(consonants.length, 34);
      for (final l in consonants) {
        final runes = TuluLipi.fromKannada(l.kannada).runes.toList();
        expect(runes.length, 1, reason: l.kannada);
        expect(
          runes.single,
          inInclusiveRange(0x11392, 0x113B5),
          reason: l.kannada,
        );
      }
    });
  });

  test('hasKannada', () {
    expect(TuluLipi.hasKannada('ತುಳು'), isTrue);
    expect(TuluLipi.hasKannada('tulu 123'), isFalse);
  });
}

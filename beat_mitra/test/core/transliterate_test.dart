import 'package:beat_mitra/core/transliterate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transliterate', () {
    test('Kannada names', () {
      expect(transliterate('ರಮೇಶ್'), 'ramesh');
      expect(transliterate('ರಮೇಶ'), 'ramesha');
      expect(transliterate('ಲಕ್ಷ್ಮಿ'), 'lakshmi');
      expect(transliterate('ಶಂಕರ್'), 'shankar');
      expect(transliterate('ಸಂಪತ್'), 'sampat');
      expect(transliterate('ಗೌರಿ'), 'gauri');
      expect(transliterate('ಕೃಷ್ಣ'), 'krishna');
    });

    test('Devanagari names with schwa deletion', () {
      expect(transliterate('रमेश'), 'ramesh');
      expect(transliterate('राम'), 'raam');
      expect(transliterate('सुनीता शर्मा'), 'suneetaa sharmaa');
      expect(transliterate('क'), 'ka');
    });

    test('Indic digits become ASCII', () {
      expect(transliterate('೧೨/೩'), '12/3');
      expect(transliterate('४५'), '45');
    });

    test('Latin text unchanged', () {
      expect(transliterate('No. 12, 4th Cross'), 'No. 12, 4th Cross');
    });

    test('hasIndicScript', () {
      expect(hasIndicScript('Ramesh'), isFalse);
      expect(hasIndicScript('ರಮೇಶ್'), isTrue);
      expect(hasIndicScript('रमेश'), isTrue);
    });
  });

  group('phoneticKey', () {
    test('spelling variants and scripts collapse to the same key', () {
      final k = phoneticKey('Ramesh');
      expect(phoneticKey('ರಮೇಶ್'), k);
      expect(phoneticKey('रमेश'), k);
      expect(phoneticKey('Rameshh'), k);
      expect(phoneticKey('Ramesha'), k);
      expect(phoneticKey('ರಮೇಶ'), k);
    });

    test('vowel length and aspiration variants', () {
      expect(phoneticKey('Sreenivas'), phoneticKey('Srinivas'));
      expect(phoneticKey('Lakshmi'), phoneticKey('ಲಕ್ಷ್ಮಿ'));
      expect(phoneticKey('Sunita'), phoneticKey('सुनीता'));
      expect(phoneticKey('Sharma'), phoneticKey('शर्मा'));
      expect(phoneticKey('Vasanth'), phoneticKey('Wasant'));
    });

    test('numbers are kept', () {
      expect(phoneticKey('560038'), '560038');
    });
  });
}

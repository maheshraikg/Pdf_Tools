import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/transliterate.dart';

void main() {
  test('Kannada place names', () {
    expect(transliterate('ಪುತ್ತೂರು'), 'puttur');
    expect(transliterate('ಮಂಗಳೂರು'), 'mangalur');
    expect(transliterate('ಉಡುಪಿ'), 'udupi');
    expect(transliterate('ಕಾರ್ಕಳ'), 'karkala');
    expect(transliterate('ಸುಳ್ಯ'), 'sulya');
    expect(transliterate('ಹಾಸನ'), 'hasana');
    expect(transliterate('ಮೈಸೂರು'), 'maisur');
    expect(transliterate('ಕುಂದಾಪುರ'), 'kundapura');
    expect(transliterate('ಶಿವಮೊಗ್ಗ'), 'shivamogga');
    expect(transliterate('ಚಿಕ್ಕಮಗಳೂರು'), 'chikkamagalur');
  });

  test('anusvara becomes m before labials', () {
    expect(transliterate('ಸಂಪಾಜೆ'), 'sampaje');
    expect(transliterate('ಅಂಬಾ'), 'amba');
  });

  test('Devanagari place names with final schwa deletion', () {
    expect(transliterate('पुत्तूर'), 'puttur');
    expect(transliterate('दिल्ली'), 'dilli');
    expect(transliterate('मुंबई'), 'mumbai');
    expect(transliterate('बेंगलूरु'), 'bengaluru');
    expect(transliterate('पटना'), 'patana');
    expect(transliterate('नागपुर'), 'nagapur');
    expect(transliterate('ग़ाज़ियाबाद'), 'gaziyabad');
  });

  test('mixed text keeps Latin and spaces', () {
    expect(transliterate('Puttur ಪುತ್ತೂರು'), 'puttur puttur');
    expect(transliterate('ABC 123'), 'abc 123');
    expect(hasIndicScript('ಪುತ್ತೂರು'), isTrue);
    expect(hasIndicScript('Puttur'), isFalse);
  });
}

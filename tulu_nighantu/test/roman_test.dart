import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_nighantu/lipi/roman.dart';
import 'package:tulu_nighantu/lipi/tulu_lipi.dart';

void main() {
  test('English letters become Kannada', () {
    expect(romanToKannada('mahesh'), 'ಮಹೇಶ್');
    expect(romanToKannada('Mahesh'), 'ಮಹೇಶ್');
    expect(romanToKannada('MAHESH'), 'ಮಹೇಶ್');
    expect(romanToKannada('tuLu'), 'ತುಳು');
    expect(romanToKannada('kanndaa'), 'ಕನ್ನ್ದಾ');
    expect(romanToKannada('raama'), 'ರಾಮ');
    expect(romanToKannada('krishna'), 'ಕ್ರಿಶ್ನ');
    expect(romanToKannada('ai'), 'ಐ');
    expect(romanToKannada('kaMbaLa'), 'ಕಂಬಳ');
    expect(romanToKannada('jai tuLunaaD'), 'ಜೈ ತುಳುನಾಡ್');
    expect(romanToKannada('ಮಹೇಶ್ 2026!'), 'ಮಹೇಶ್ 2026!');
  });

  test('same Tulu lipi for ಮಹೇಶ್ and mahesh', () {
    expect(
      TuluLipi.fromKannada(romanToKannada('mahesh')),
      TuluLipi.fromKannada('ಮಹೇಶ್'),
    );
    expect(hasLatin('ಮಹೇಶ್'), isFalse);
    expect(hasLatin('mahesh'), isTrue);
  });
}

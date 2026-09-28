import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_nighantu/app_state.dart';

void main() {
  final state = AppState.instance
    ..loadFromJson(File('assets/data/words.json').readAsStringSync());
  final t = state.translator;

  test('whole phrase in English and Kannada', () {
    expect(t.translate('How are you?').tulu, 'ಎಂಚ ಉಲ್ಲರ್?');
    expect(t.translate('ನಿಮ್ಮ ಹೆಸರು ಏನು?').tulu, 'ಈರೆನ ಪುದರ್ ದಾದ?');
    expect(t.translate('what is your name').phrase, isNotNull);
  });

  test('word by word with multi-word meanings', () {
    final r = t.translate('elder brother and mother');
    expect(r.pieces.first.word!.tulu, 'ಅಣ್ಣೆ');
    expect(r.tulu, startsWith('ಅಣ್ಣೆ'));
    expect(r.pieces.any((p) => !p.found), isTrue); // "and" is unknown
    expect(r.complete, isFalse);
  });

  test('English articles are skipped, plurals matched', () {
    final r = t.translate('the dogs');
    expect(r.pieces.single.word!.tulu, 'ನಾಯಿ');
    expect(r.pieces.single.approximate, isTrue);
  });

  test('Kannada words and inflected forms', () {
    expect(t.translate('ನೀರು').tulu, 'ನೀರ್');
    final r = t.translate('ನೀರನ್ನು ಕುಡಿ');
    expect(r.pieces.first.word!.tulu, 'ನೀರ್');
    expect(r.pieces.first.approximate, isTrue);
    expect(r.pieces.last.word!.tulu, 'ಪರ್');
  });

  test('empty input', () {
    expect(t.translate('  ').isEmpty, isTrue);
  });
}

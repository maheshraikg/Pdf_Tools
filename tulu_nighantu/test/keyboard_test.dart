import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_nighantu/lipi/composer.dart';
import 'package:tulu_nighantu/screens/tulu_keyboard_screen.dart';

void main() {
  test('vowel signs attach to and replace on the last consonant', () {
    expect(applySign('ಕ', 'ಾ'), 'ಕಾ');
    expect(applySign('ಕಾ', 'ಿ'), 'ಕಿ');
    expect(applySign('ಕ್', 'ು'), 'ಕು');
    expect(applySign('ಕ', '್'), 'ಕ್');
    expect(applySign('ಕ್', '್'), 'ಕ್');
    expect(applySign('ಕಾ', 'ಂ'), 'ಕಾಂ');
    expect(applySign('ಅ', 'ಂ'), 'ಅಂ');
    expect(applySign('', 'ಾ'), '');
    expect(applySign('ಅ', 'ಾ'), 'ಅ');
    expect(applySign('ಕ ', 'ಾ'), 'ಕ ');
  });

  test('last consonant and backspace', () {
    expect(lastConsonant('ತುಳು'), 'ಳ');
    expect(lastConsonant('ಕ್'), isNull);
    expect(lastConsonant('ಅ'), isNull);
    expect(backspace('ಕಾ'), 'ಕ');
    expect(backspace(''), '');
  });

  testWidgets('keys build a word and the screen fits a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MaterialApp(home: TuluKeyboardScreen()));
    final list = find.byType(Scrollable).first;
    Future<void> tapKey(String label) async {
      final key = find.text(label);
      // Start from the top: the sign row sits above the letter keys.
      tester.state<ScrollableState>(list).position.jumpTo(0);
      await tester.pump();
      await tester.scrollUntilVisible(key, 120, scrollable: list);
      await tester.ensureVisible(key);
      await tester.pumpAndSettle();
      await tester.tap(key);
      await tester.pump();
    }

    await tapKey('ತ');
    await tapKey('ತು');
    await tapKey('ಳ');
    await tapKey('ಳು');
    tester.state<ScrollableState>(list).position.jumpTo(0);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'ತುಳು',
    );
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  test('ottakshara joins to the previous consonant', () {
    expect(addOttu('ಕ', 'ತ'), 'ಕ್ತ');
    expect(addOttu('ಕ್', 'ತ'), 'ಕ್ತ');
    expect(addOttu('ಕಾ', 'ತ'), 'ಕಾ');
    expect(addOttu('', 'ತ'), '');
    expect(kKeyboardPage1.length, 28);
    expect(kKeyboardPage2.length, 28);
    expect(kKeyboardConsonants.length, 34);
  });

  testWidgets('docked keys type a word and fit a small phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const MaterialApp(home: TuluKeyboardScreen()));
    Future<void> tap(String label) async {
      await tester.tap(find.text(label).last);
      await tester.pump();
    }

    String text() => tester
        .widget<TextField>(
          find.byKey(const ValueKey('keyboard-text'), skipOffstage: false),
        )
        .controller!
        .text;

    await tap('ತ ಯ');
    await tap('ತ');
    await tap('ತು');
    await tap('ಳ');
    await tap('ಳು');
    expect(text(), 'ತುಳು');

    // Ottakshara page: ಕ + ್ತ → ಕ್ತ.
    await tap('ಅ ಕ');
    await tap('ಕ');
    await tap('್ಕ');
    await tap('್ತ');
    expect(text(), 'ತುಳುಕ್ತ');
    await tester.tap(find.byKey(const ValueKey('keyboard-backspace')));
    await tester.pump();
    expect(text(), 'ತುಳುಕ್');

    // The phone keyboard can be chosen instead; the keys then hide.
    await tester.tap(find.byIcon(Icons.keyboard_alt_outlined));
    await tester.pump();
    expect(find.text('ತ ಯ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system keyboard setup card follows the phone status', (
    tester,
  ) async {
    const channel = MethodChannel('tulu_nighantu/keyboard');
    var status = {'enabled': false, 'selected': false};
    final calls = <String>[];
    Map? saved;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'setPrefs') saved = call.arguments as Map;
      if (call.method == 'getPrefs') {
        return {'vibrate': true, 'sound': false, 'stickerLabel': true};
      }
      return call.method == 'status' ? status : null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: TuluKeyboardScreen(showSystemKeyboardSetup: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('every app'), findsOneWidget);
    await tester.tap(find.text('ಆನ್ ಮಾಡಿ · Turn on'));
    await tester.pump();
    expect(calls, contains('openSettings'));

    // Back from Settings with the keyboard on and chosen.
    status = {'enabled': true, 'selected': true};
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('ಆನ್ ಮಾಡಿ · Turn on'), findsNothing);
    expect(find.byIcon(Icons.check), findsNWidgets(2));

    // Settings are shown once the keyboard is on and saved when changed.
    await tester.ensureVisible(find.textContaining('Key sound'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Key sound'));
    await tester.pumpAndSettle();
    expect(saved, {'vibrate': true, 'sound': true, 'stickerLabel': true});
  });
}

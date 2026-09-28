import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/lipi/stroke_guide.dart';
import 'package:tulu_nighantu/lipi/tulu_lipi.dart';
import 'package:tulu_nighantu/screens/trace_screen.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.loadFromJson(
      File('assets/data/words.json').readAsStringSync(),
    );
    StrokeGuide.loadFromJson(
      File('assets/data/strokes.json').readAsStringSync(),
    );
  });

  test('every alphabet letter has a normalised pen path', () {
    for (final l in kLipiLetters) {
      final strokes = StrokeGuide.forLetter(l.kannada);
      expect(strokes, isNotNull, reason: l.kannada);
      expect(strokes, isNotEmpty, reason: l.kannada);
      for (final s in strokes!) {
        for (final p in s) {
          expect(p.dx, inInclusiveRange(0, 1));
          expect(p.dy, inInclusiveRange(0, 1));
        }
      }
    }
  });

  test('mapToRect scales into the box', () {
    final m = StrokeGuide.mapToRect([
      [const Offset(0, 0), const Offset(1, 1)],
    ], const Rect.fromLTWH(10, 20, 100, 50));
    expect(m.single, [const Offset(10, 20), const Offset(110, 70)]);
  });

  testWidgets('letters open on the Watch tutorial and animate', (tester) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: TraceScreen.letters(startIndex: 13)),
    );
    // Ink bounds are computed from an offscreen image.
    await tester.runAsync(
      () => GlyphScorer.inkBounds(kLipiLetters[13].tulu, 379),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Your turn'), findsOneWidget);
    expect(find.textContaining('Replay'), findsOneWidget);

    await tester.tap(find.textContaining('Your turn'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check'), findsOneWidget);
  });

  testWidgets('listen without a TTS engine shows a hint, not a crash', (
    tester,
  ) async {
    phone(tester);
    await tester.pumpWidget(
      MaterialApp(home: TraceScreen.letters(startIndex: 13)),
    );
    await tester.tap(find.byTooltip('ಕೇಳಿ · Listen'));
    // The missing-plugin error arrives asynchronously.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No Kannada voice'), findsOneWidget);
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/main.dart';
import 'package:tulu_nighantu/screens/add_word_screen.dart';
import 'package:tulu_nighantu/screens/trace_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.loadFromJson(
      File('assets/data/words.json').readAsStringSync(),
    );
  });

  testWidgets('app shows dictionary and switches tabs', (tester) async {
    await tester.pumpWidget(const TuluNighantuApp());
    expect(find.text('ತುಳು ನಿಘಂಟು'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'zzzzqq');
    await tester.pump();
    expect(find.text('No match – try another spelling'), findsOneWidget);

    await tester.tap(find.text('ಲಿಪಿ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('letters practised'), findsOneWidget);

    await tester.tap(find.text('ಬದಲಿಸಿ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Translate to Tulu'), findsOneWidget);
    await tester.tap(find.text('ಲಿಪಿ · Script'));
    await tester.pumpAndSettle();
    expect(find.text('ಕನ್ನಡ · Kannada'), findsOneWidget);

    await tester.tap(find.text('ಉಳಿಸಿದವು'));
    await tester.pumpAndSettle();
    final font = find.text('Font: Mallige (SIL OFL 1.1)');
    await tester.scrollUntilVisible(
      font,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
    expect(font, findsOneWidget);
  });

  testWidgets('typing a search ignores a previously selected category', (
    tester,
  ) async {
    await tester.pumpWidget(const TuluNighantuApp());
    await tester.tap(find.textContaining('Family'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'hand');
    await tester.pump();
    expect(find.text('No match – try another spelling'), findsNothing);
    expect(find.text('hand · ಕೈ'), findsOneWidget);
  });

  testWidgets('translate tab turns an English phrase into Tulu', (
    tester,
  ) async {
    await tester.pumpWidget(const TuluNighantuApp());
    await tester.tap(find.text('ಬದಲಿಸಿ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(TextField).hitTestable(),
        matching: find.byType(EditableText),
      ),
      'How are you?',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Phrase found'), findsOneWidget);
    expect(find.text('ಎಂಚ ಉಲ್ಲರ್?'), findsWidgets);
  });

  testWidgets('missing word can be added from search and is then found', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const TuluNighantuApp());
    await tester.enterText(find.byType(TextField), 'qwertyking');
    await tester.pump();
    await tester.tap(find.textContaining('Add "qwertyking"'));
    await tester.pumpAndSettle();
    // English meaning is prefilled from the search.
    expect(find.text('qwertyking'), findsWidgets);
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'ತುಳು ಪದ (ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ) · Tulu word *',
      ),
      'ಪರೀಕ್ಷೆ',
    );
    await tester.tap(find.text('ಸೇರಿಸಿ · Save word'));
    await tester.pumpAndSettle();
    expect(find.text('No match – try another spelling'), findsNothing);
    expect(find.textContaining('yours'), findsOneWidget);
    AppState.instance.deleteCustomWord(AppState.instance.customWords.last.id);
  });

  testWidgets('add-word form fits a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1480);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(360, 740),
          textScaler: TextScaler.linear(1.4),
        ),
        child: MaterialApp(home: AddWordScreen(prefill: 'king')),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dictionary fits a small phone with large text', (tester) async {
    tester.view.physicalSize = const Size(720, 1480);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 740),
          textScaler: TextScaler.linear(1.4),
        ),
        child: const TuluNighantuApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('translate view fits a small phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1480);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 740),
          textScaler: TextScaler.linear(1.4),
        ),
        child: const TuluNighantuApp(),
      ),
    );
    await tester.tap(find.text('ಬದಲಿಸಿ'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(TextField).hitTestable(),
        matching: find.byType(EditableText),
      ),
      'my elder brother drinks water',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('words found'), findsOneWidget);
  });

  testWidgets('scorer: empty strokes score zero, scribbling over the '
      'whole canvas gives full coverage but low precision', (tester) async {
    await tester.runAsync(() async {
      final empty = await GlyphScorer.score('\u{11392}', 300, []);
      expect(empty.stars, 0);

      final scribble = <List<Offset>>[
        for (var y = 0.0; y <= 300; y += 8) [Offset(0, y), Offset(300, y)],
      ];
      final r = await GlyphScorer.score('\u{11392}', 300, scribble);
      expect(r.coverage, greaterThan(0.95));
      expect(r.precision, lessThan(1));
    });
  });

  test('stars thresholds', () {
    expect(const TraceResult(0, 0, 0.85).stars, 3);
    expect(const TraceResult(0, 0, 0.65).stars, 2);
    expect(const TraceResult(0, 0, 0.45).stars, 1);
    expect(const TraceResult(0, 0, 0.2).stars, 0);
  });
}

import 'dart:io';

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/audio/speaker.dart';
import 'package:tulu_nighantu/learn/charts.dart';
import 'package:tulu_nighantu/learn/culture.dart';
import 'package:tulu_nighantu/learn/quiz.dart';
import 'package:tulu_nighantu/lipi/tulu_lipi.dart';
import 'package:tulu_nighantu/screens/charts_screen.dart';
import 'package:tulu_nighantu/screens/culture_screen.dart';
import 'package:tulu_nighantu/screens/quiz_screen.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.loadFromJson(
      File('assets/data/words.json').readAsStringSync(),
    );
  });

  /// A phone-sized screen with large text.
  void smallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  test('charts: numbers sorted, every item converts to Tulu lipi', () {
    final charts = buildCharts(AppState.instance.words);
    expect(
      charts.map((c) => c.id),
      containsAll(['numbers', 'days', 'months', 'dirs']),
    );
    final numbers = charts.firstWhere((c) => c.id == 'numbers').items;
    final values = numbers.map(numberValue).toList();
    expect(values.first, 1);
    expect(values, orderedEquals([...values]..sort()));
    expect(kDays, hasLength(7));
    expect(kMonths, hasLength(12));
    for (final c in charts) {
      expect(c.items, isNotEmpty, reason: c.id);
      for (final w in c.items) {
        expect(TuluLipi.hasKannada(w.lipi), isFalse, reason: w.tulu);
        expect(w.lipi, isNotEmpty);
      }
    }
  });

  testWidgets('charts open and fit a small phone with large text', (
    tester,
  ) async {
    smallPhone(tester);
    await tester.pumpWidget(const MaterialApp(home: ChartsScreen()));
    expect(find.textContaining('Days of the week'), findsOneWidget);
    await tester.tap(find.textContaining('Days of the week'));
    await tester.pumpAndSettle();
    expect(find.text('ಐತಾರ'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('quiz: 10 mixed questions, each with 4 distinct options', () {
    final q = buildQuiz(AppState.instance.words, random: Random(1));
    expect(q, hasLength(10));
    expect(q.map((x) => x.kind).toSet(), QuizKind.values.toSet());
    for (final x in q) {
      expect(x.options, hasLength(4));
      expect(x.options.toSet(), hasLength(4), reason: x.options.join('|'));
      expect(x.answer, inInclusiveRange(0, 3));
    }
  });

  test('streak counts consecutive days and resets after a gap', () {
    var s = const Streak();
    s = s.practisedOn(DateTime(2026, 10, 1));
    s = s.practisedOn(DateTime(2026, 10, 1));
    s = s.practisedOn(DateTime(2026, 10, 2));
    expect(s.current, 2);
    expect(s.activeOn(DateTime(2026, 10, 3)), 2);
    expect(s.activeOn(DateTime(2026, 10, 4)), 0);
    s = s.practisedOn(DateTime(2026, 10, 5));
    expect(s.current, 1);
    expect(s.best, 2);
    // Month boundary.
    s = const Streak(current: 3, best: 3, lastDay: '2026-09-30');
    expect(s.practisedOn(DateTime(2026, 10, 1)).current, 4);
    expect(Streak.fromJson(s.toJson()).lastDay, '2026-09-30');
  });

  testWidgets('quiz can be played to the end on a small phone', (tester) async {
    smallPhone(tester);
    await tester.pumpWidget(MaterialApp(home: QuizScreen(random: Random(2))));
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 10; i++) {
      final option = find.byKey(const ValueKey('quiz-option-0'));
      await tester.scrollUntilVisible(option, 120, scrollable: list);
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pump();
      final next = find.byKey(const ValueKey('quiz-next'));
      await tester.scrollUntilVisible(next, 120, scrollable: list);
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pump();
    }
    expect(find.textContaining('/ 10'), findsWidgets);
    expect(find.textContaining('Play again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  CultureData culture() =>
      CultureData.fromJson(File('assets/data/culture.json').readAsStringSync());

  test('culture data: unique ids, Tulu lipi for every festival', () {
    final d = culture();
    expect(d.festivals.length, greaterThanOrEqualTo(8));
    expect(d.festivals.map((f) => f.id).toSet(), hasLength(d.festivals.length));
    for (final f in d.festivals) {
      expect(TuluLipi.hasKannada(f.lipi), isFalse, reason: f.tulu);
      expect(f.about, isNotEmpty);
    }
  });

  testWidgets('culture screen fits a small phone with large text', (
    tester,
  ) async {
    smallPhone(tester);
    await tester.pumpWidget(MaterialApp(home: CultureScreen(data: culture())));
    await tester.pumpAndSettle();
    expect(find.text('Bisu – Tulu New Year'), findsOneWidget);
    await tester.tap(find.textContaining('Proverbs'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Proverbs coming soon'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('recordings are looked up by Kannada-script text', () {
    Speaker.instance.debugSetRecordings({'ನೀರ್': 'r_abc.m4a'});
    expect(Speaker.instance.recordingFor(' ನೀರ್ '), 'r_abc.m4a');
    expect(Speaker.instance.recordingFor('ಕ'), isNull);
    Speaker.instance.debugSetRecordings(const {});
  });

  test('bundled recordings index is valid and its files exist', () {
    final j = jsonDecode(
      File('assets/audio/index.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final f in (j['files'] as Map).values) {
      expect(File('assets/audio/$f').existsSync(), isTrue, reason: '$f');
    }
  });
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/learn/charts.dart';
import 'package:tulu_nighantu/lipi/tulu_lipi.dart';
import 'package:tulu_nighantu/screens/charts_screen.dart';

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
}

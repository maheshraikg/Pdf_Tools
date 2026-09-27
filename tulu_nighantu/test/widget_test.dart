import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tulu_nighantu/app_state.dart';
import 'package:tulu_nighantu/main.dart';
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
    expect(find.textContaining('Copy Tulu text'), findsOneWidget);

    await tester.tap(find.text('ಉಳಿಸಿದವು'));
    await tester.pumpAndSettle();
    expect(find.text('Font: Mallige (SIL OFL 1.1)'), findsOneWidget);
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

// End-to-end navigation through the real app shell (pushed routes must
// reach AppScope).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/main.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('app shell: schemes, find → sort, learn, bulk', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(SortingSahayakApp(settings: h.settings, open: () async => h.services));
    await settle(tester);
    expect(find.text('Sort'), findsWidgets);

    // More → Sorting schemes (pushed route).
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sorting schemes'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('SAMPLE – not real – demo scheme'), findsOneWidget);
    // Open the editor (another pushed route) and check tabs.
    await tester.tap(find.textContaining('SAMPLE – not real – demo scheme'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rules ('), findsOneWidget);
    expect(find.textContaining('Air codes (0)'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Find PIN → result sheet → "Sort this PIN" switches to the Sort tab.
    await tester.tap(find.text('Find PIN'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Sullia');
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester, rounds: 6);
    await tester.tap(find.text('Sullia SO'));
    await settle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort this PIN'));
    await settle(tester, rounds: 6);
    await tester.pumpAndSettle();
    expect(find.text('Bag 14'), findsWidgets);

    // Learn → flashcards (pushed route using services).
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bag flashcards'));
    await settle(tester, rounds: 6);
    await tester.pumpAndSettle();
    expect(find.text('Show answer'), findsOneWidget);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I knew it'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 / '), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Bulk: start a session, count two PINs, undo one.
    await tester.tap(find.text('Bulk'));
    await settle(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start session').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await settle(tester);
    await tester.pumpAndSettle();
    Future<void> type(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.byKey(ValueKey('key_$d')));
        await tester.pump();
      }
      await settle(tester, rounds: 6);
    }

    await type('574201');
    await type('576101');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Total: 2'), findsOneWidget);
    expect(find.text('Bag 12: 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Undo last'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('Total: 1'), findsOneWidget);
    await tester.tap(find.text('End'));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Bag 12 – Puttur Line'), findsOneWidget);
  });
}

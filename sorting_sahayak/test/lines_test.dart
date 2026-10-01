import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/data/models/scheme.dart';
import 'package:sorting_sahayak/features/lines/lines_screen.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('Non-TD prefix line lists its real PINs and offices', (tester) async {
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const LineDetailScreen(code: 'NT-61', category: kCatNonTD)));
    await settle(tester, rounds: 6);
    expect(find.text('671xxx'), findsOneWidget);
    expect(find.text('Kasargod'), findsWidgets);
    expect(find.text('2 PINs – tap to see all'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('area_671xxx')));
    await tester.pumpAndSettle();
    expect(find.text('671121'), findsOneWidget);
    expect(find.text('671543'), findsOneWidget);
    expect(find.text('Kasaragod HO'), findsOneWidget);
  });

  testWidgets('remove a PIN series from a Non-TD line; add buttons open the rule dialog', (tester) async {
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const LineDetailScreen(code: 'NT-61', category: kCatNonTD)));
    await settle(tester, rounds: 6);
    expect(find.byKey(const ValueKey('line_add_office')), findsOneWidget);
    expect(find.byKey(const ValueKey('line_add_pin')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('remove_671xxx')));
    await tester.pumpAndSettle();
    expect(find.text('Remove 671xxx from NT-61?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirm_remove')));
    await settle(tester, rounds: 6);
    await tester.pumpAndSettle();
    expect(find.text('671xxx'), findsNothing);
    final left = h.services.active!.rules.where((r) => r.bagCode == 'NT-61').toList();
    expect(left.map((r) => r.match.type), [RuleType.office]);
    // The office row can be removed too.
    await tester.tap(find.byKey(const ValueKey('remove_Kasaragod')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_remove')));
    await settle(tester, rounds: 6);
    await tester.pumpAndSettle();
    expect(h.services.active!.rules.where((r) => r.bagCode == 'NT-61'), isEmpty);

    await tester.tap(find.byKey(const ValueKey('line_add_pin')));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

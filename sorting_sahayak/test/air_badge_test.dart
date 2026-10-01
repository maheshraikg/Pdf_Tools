import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/features/lookup/sort_screen.dart';

import 'helpers/app_harness.dart';

void main() {
  testWidgets('line card and full PIN card show the air code', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    // Typing a series: nearest airport to its offices (Puttur area → IXE).
    await tester.enterText(find.byKey(const ValueKey('pin_field')), '574');
    await settle(tester, rounds: 6);
    expect(find.byKey(const ValueKey('air_IXE')), findsWidgets);
    // Full PIN: on the bag card.
    await tester.enterText(find.byKey(const ValueKey('pin_field')), '574239');
    await settle(tester, rounds: 6);
    expect(find.byKey(const ValueKey('air_IXE')), findsOneWidget);
  });
}

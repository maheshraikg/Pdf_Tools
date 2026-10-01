import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
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
}

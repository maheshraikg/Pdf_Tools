import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/core/widgets.dart';
import 'package:sorting_sahayak/features/find_pin/find_pin_screen.dart';
import 'package:sorting_sahayak/features/lookup/sort_screen.dart';

import 'helpers/app_harness.dart';

Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('key_$d')));
    await tester.pump();
  }
  await settle(tester);
}

void main() {
  testWidgets('Sort screen: live result while typing, final bag, offices, breakdown', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);

    await typePin(tester, '576');
    expect(find.text('Sorting district 576'), findsOneWidget);
    expect(find.text('Likely bag (from prefix)'), findsOneWidget);
    expect(find.text('Bag 20'), findsWidgets);

    await typePin(tester, '101');
    expect(find.text('Bag 21'), findsWidgets);
    expect(find.text('Udupi HO'), findsWidgets);
    expect(find.textContaining('Udupi, Karnataka'), findsWidgets);
    expect(find.text('PIN structure'), findsOneWidget);

    // Next digit starts a new PIN; not-in-directory warning.
    await typePin(tester, '574999');
    expect(find.text('PIN not in directory – check the address'), findsOneWidget);

    // Backspace and clear.
    await tester.tap(find.byKey(const ValueKey('key_⌫')));
    await settle(tester);
    expect(find.text('PIN not in directory – check the address'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('key_C')));
    await settle(tester);
    expect(find.text('Recent lookups'), findsOneWidget);
    expect(find.text('576101'), findsOneWidget);
  });

  testWidgets('Sort screen: Air Parcel mode shows air code, AIR badge, hub route', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, parcelExtras: true, prefs: {'category': kCatAirParcel});
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await typePin(tester, '560001');
    expect(find.text('BLR'), findsOneWidget);
    expect(find.text('Air label code'), findsOneWidget);
    final badge = tester.widget<ConnectivityBadge>(find.byType(ConnectivityBadge));
    expect(badge.connectivity.label, 'Air');
    expect(find.text('AIR'), findsOneWidget);
    expect(find.textContaining('Direct to L1 hub: Bengaluru L1 (demo)'), findsOneWidget);

    // No air code → clear warning; Surface badge from DMSL.
    await typePin(tester, '574201');
    expect(find.text('No air code – check with supervisor'), findsOneWidget);
    expect(find.text('SURFACE'), findsOneWidget);
    expect(find.textContaining('L2: Puttur L2 (demo)'), findsOneWidget);

    // Switch to TD: no air code card; TD bag shown.
    await tester.tap(find.byKey(const ValueKey('mode_TD')));
    await settle(tester);
    expect(find.text('Air label code'), findsNothing);
    expect(find.text('No air code – check with supervisor'), findsNothing);
    expect(h.settings.category, kCatTD);
    expect(find.text('Bag 12'), findsWidgets);
    // Non-TD PIN in TD mode names the other mode.
    await typePin(tester, '560001');
    expect(find.text('This PIN is in Non-TD: NT-40 – Bengaluru'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('mode_Non-TD')));
    await settle(tester);
    expect(find.text('NT-40'), findsWidgets);
  });

  testWidgets('Sort screen: Kannada UI and no-scheme warning', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, sample: false);
    await tester.pumpWidget(h.wrap(const SortScreen(), locale: const Locale('kn')));
    await settle(tester);
    expect(find.text('ಸಾರ್ಟ್'), findsOneWidget);
    expect(find.text('ಇನ್ನೂ ಸಾರ್ಟಿಂಗ್ ಸ್ಕೀಮ್ ಇಲ್ಲ'), findsOneWidget);
    expect(find.text('TD'), findsOneWidget);
    expect(find.text('ನಾನ್-TD'), findsOneWidget);
  });

  testWidgets('Find PIN: fuzzy / Kannada search shows offices with bags', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const FindPinScreen()));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'Puttoor');
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester);
    expect(find.text('Puttur SO'), findsWidgets);
    expect(find.textContaining('574201'), findsWidgets);
    expect(find.textContaining('Bag: Bag 12 – Puttur Line'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'ಪುತ್ತೂರು');
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester);
    expect(find.text('Puttur SO'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'zzqxw');
    await tester.pump(const Duration(milliseconds: 200));
    await settle(tester);
    expect(find.text('No matching office found'), findsOneWidget);
  });

  testWidgets('Find PIN: mismatch checker', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const FindPinScreen()));
    await settle(tester);
    await tester.tap(find.text('PIN ↔ place check'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '574201');
    await tester.enterText(fields.at(2), 'Manipal');
    await settle(tester, rounds: 10);
    expect(find.textContaining('different district/state'), findsOneWidget);
    expect(find.textContaining('576104 · Manipal'), findsOneWidget);
    await tester.enterText(fields.at(2), 'Puttur');
    await settle(tester, rounds: 10);
    expect(find.text('✅ Place matches this PIN'), findsOneWidget);
  });
}

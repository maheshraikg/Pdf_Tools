import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/core/widgets.dart';
import 'package:sorting_sahayak/features/find_pin/find_pin_screen.dart';
import 'package:sorting_sahayak/features/lookup/sort_screen.dart';

import 'helpers/app_harness.dart';

Future<void> typePin(WidgetTester tester, String pin) async {
  final field = find.byKey(const ValueKey('pin_field'));
  final current = tester.widget<TextField>(field).controller!.text;
  await tester.enterText(field, current + pin);
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

    // Partial PIN: live list of matching rules, like a printed sorting list.
    await typePin(tester, '576');
    expect(find.text('Bag 20'), findsWidgets);
    expect(find.text('576101'), findsWidgets);
    expect(find.text('Bag 21'), findsWidgets);
    expect(find.byKey(const ValueKey('key_1')), findsNothing, reason: 'no in-app keypad');

    await typePin(tester, '101');
    expect(find.text('Bag 21'), findsWidgets);
    expect(find.text('Udupi HO'), findsWidgets);
    expect(find.textContaining('Udupi, Karnataka'), findsWidgets);
    expect(find.text('PIN structure'), findsOneWidget);

    // Next digit starts a new PIN; not-in-directory warning.
    await typePin(tester, '574999');
    expect(find.text('PIN not in directory – check the address'), findsOneWidget);

    // Backspace and clear.
    await tester.enterText(find.byKey(const ValueKey('pin_field')), '57499');
    await settle(tester);
    expect(find.text('PIN not in directory – check the address'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('clear_field')));
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

  testWidgets('Sort screen: office name search lists TD lines', (tester) async {
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('kb_toggle')));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('pin_field')), 'sull');
    await settle(tester);
    expect(find.text('Sullia'), findsWidgets);
    expect(find.text('Bag 14'), findsWidgets);
  });

  testWidgets('Sort screen: line box shows all offices, office box, add office', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, sample: false);
    await tester.runAsync(() async {
      final id = await installDefaultScheme(h.services.schemes, (p) async => File(p).readAsBytesSync());
      await h.services.schemes.setActive(id);
      await h.services.reloadActive();
    });
    h.settings.category = kCatTD;
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('kb_toggle')));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('pin_field')), 'belm');
    await settle(tester);
    // More than 24 entries on Belman Line: "Show all" reveals the rest.
    final showAll = find.byKey(const ValueKey('show_all'));
    expect(showAll, findsOneWidget);
    await tester.ensureVisible(showAll);
    await tester.pumpAndSettle();
    await tester.tap(showAll);
    await settle(tester);
    expect(find.byKey(const ValueKey('show_all')), findsNothing);
    // Tapping an office opens its box with line and section.
    await tester.ensureVisible(find.text('Kulur').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kulur').first);
    await tester.pumpAndSettle();
    expect(find.text('Belman Line'), findsWidgets);
    expect(find.text('16'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    // "+ Add office" opens the rule form on this line, type Office.
    await tester.ensureVisible(find.byKey(const ValueKey('add_office')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_office')));
    await settle(tester);
    await tester.pumpAndSettle();
    expect(find.text('Add rule'), findsOneWidget);
    expect(tester.widgetList<TextField>(find.byType(TextField)).any((f) => f.controller?.text == 'Belman Line'), isTrue);
    expect(find.text('Office'), findsWidgets);
  });

  testWidgets('Sort screen: typing a BO name shows PIN, SO and line', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, sample: false);
    await tester.runAsync(() async {
      final id = await installDefaultScheme(h.services.schemes, (p) async => File(p).readAsBytesSync());
      await h.services.schemes.setActive(id);
      await h.services.reloadActive();
    });
    h.settings.category = kCatTD;
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('kb_toggle')));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('pin_field')), 'kabaka');
    await settle(tester, rounds: 8);
    expect(find.text('Post offices'), findsOneWidget);
    expect(find.text('Kabaka BO'), findsOneWidget);
    expect(find.textContaining('574220'), findsWidgets);
    expect(find.text('Puttur Line'), findsWidgets);
    // Tap opens the PIN with the full result.
    await tester.tap(find.text('Kabaka BO'));
    await settle(tester, rounds: 6);
    expect(tester.widget<TextField>(find.byKey(const ValueKey('pin_field'))).controller!.text, '574220');
  });

  testWidgets('Sort screen: change bag for this PIN updates the result', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await typePin(tester, '574201');
    expect(find.text('Bag 12'), findsWidgets);

    await tester.ensureVisible(find.byKey(const ValueKey('change_bag')));
    await tester.tap(find.byKey(const ValueKey('change_bag')));
    await settle(tester);
    // PIN and current bag are pre-filled.
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.any((f) => f.controller?.text == '574201'), isTrue);
    final bagField = find.byWidgetPredicate((w) => w is TextField && w.controller?.text == 'Bag 12');
    await tester.enterText(bagField, 'Bag 77');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Saved – sorting updated'), findsOneWidget);
    expect(find.text('Bag 77'), findsWidgets);
  });

  testWidgets('Sort screen: Kannada UI and no-scheme warning', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester, sample: false);
    await tester.pumpWidget(h.wrap(const SortScreen(), locale: const Locale('kn')));
    await settle(tester);
    expect(find.text('ಪಿಒ ಸಾರ್ಟಿಂಗ್'), findsOneWidget);
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

  testWidgets('Sort screen: typed PIN + typed place runs the address check', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final h = await Harness.create(tester);
    await tester.pumpWidget(h.wrap(const SortScreen()));
    await settle(tester);
    await tester.tap(find.byTooltip('PIN vs place check'));
    await tester.pumpAndSettle();
    // Place first, no PIN yet: a hint says the PIN is needed.
    await tester.enterText(find.widgetWithText(TextField, 'City / office on the address'), 'Manipal');
    await tester.pump();
    expect(find.byKey(const ValueKey('place_needs_pin')), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('pin_field')), '574201');
    await settle(tester, rounds: 6);
    await tester.enterText(find.widgetWithText(TextField, 'City / office on the address'), 'Manipal');
    await settle(tester, rounds: 10);
    expect(find.textContaining('different district/state'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'City / office on the address'), 'Puttur');
    await settle(tester, rounds: 10);
    expect(find.text('✅ Place matches this PIN'), findsOneWidget);
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

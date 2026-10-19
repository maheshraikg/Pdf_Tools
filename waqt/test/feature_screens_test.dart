import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/scope.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/duas.dart';
import 'package:waqt/screens/duas_screen.dart';
import 'package:waqt/screens/ramadan_screen.dart';

Future<void> _pump(WidgetTester tester, AppSettings s, Widget screen) async {
  await tester.pumpWidget(
    AppScope(
      settings: s,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  test('every dua has Arabic, meaning and a count', () {
    for (final d in duas) {
      expect(d.arabic, isNotEmpty, reason: d.title);
      expect(d.meaning, isNotEmpty, reason: d.title);
      expect(d.times, greaterThan(0));
    }
    for (final g in DuaGroup.values) {
      expect(duas.where((d) => d.group == g), isNotEmpty);
    }
  });

  test('the coming Ramadan is 29 or 30 days of Ramadan', () {
    final s = AppSettings.memory();
    final days = ramadanDays(s);
    expect(days.length, inInclusiveRange(29, 30));
    expect(days.every((d) => d.hijri.isRamadan), isTrue);
    expect(days.first.hijri.day, 1);
  });

  testWidgets('duas: tap counts up to the number of times', (tester) async {
    final s = AppSettings.memory();
    await _pump(tester, s, const DuasScreen(initial: DuaGroup.morningEvening));
    expect(find.text('Ayat al-Kursi'), findsOneWidget);
    // "Protection" is said 3 times.
    await tester.scrollUntilVisible(
      find.text('Protection'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    final card = find.ancestor(
      of: find.text('Protection'),
      matching: find.byType(DuaCard),
    );
    await tester.ensureVisible(card);
    final button = find.descendant(
      of: card,
      matching: find.text('Tap to count'),
    );
    await Scrollable.ensureVisible(tester.element(button), alignment: 0.5);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      await tester.tap(
        find.descendant(of: card, matching: find.textContaining(' / 3')),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(
      find.descendant(of: card, matching: find.text('3 / 3')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
  });

  testWidgets('Ramadan page shows the timetable and duas', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppSettings.memory();
    await _pump(tester, s, const RamadanScreen());
    expect(find.textContaining('Ramadan in'), findsOneWidget);
    expect(find.text('RAMADAN TIMETABLE'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Laylat al-Qadr'), 300);
    expect(find.text('Breaking the fast'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

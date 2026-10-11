import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/app/settings.dart';
import 'package:tulu_panchanga/art/festival_art.dart';
import 'package:tulu_panchanga/lipi/tulu_lipi.dart';
import 'package:tulu_panchanga/main.dart';
import 'package:tulu_panchanga/panchanga/names.dart';

Future<AppSettings> pumpApp(WidgetTester tester, {Lang lang = Lang.en}) async {
  final settings = AppSettings.memory()..lang = lang;
  await tester.binding.setSurfaceSize(const Size(420, 900));
  await tester.pumpWidget(
    TuluPanchangaApp(settings: settings, background: false, splash: false),
  );
  await tester.pump();
  return settings;
}

/// Lets background isolates finish, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
}

void main() {
  testWidgets('Today screen shows panchanga and timeline', (tester) async {
    await pumpApp(tester);
    expect(find.text('Tulu Panchanga'), findsWidgets);
    expect(find.text('Day timeline'), findsOneWidget);
    expect(find.text('Tithi'), findsWidgets);
    expect(find.text('Rahu kaala'), findsWidgets);
    expect(find.text('Mangaluru'), findsOneWidget);

    // Next day.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await tester.pump();
    expect(find.byIcon(Icons.today_rounded), findsOneWidget);
  });

  testWidgets('tabs: calendar, festivals, muhurta, settings', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.calendar_month_outlined).last);
    await tester.pump();
    await settle(tester);
    expect(find.text('Sun'), findsOneWidget);

    await tester.tap(find.text('Tulu month').first);
    await tester.pump();
    await settle(tester);
    expect(find.textContaining('('), findsWidgets);

    await tester.tap(find.byIcon(Icons.celebration_outlined).last);
    await tester.pump();
    await settle(tester);
    expect(find.text('Festivals'), findsWidgets);
    expect(find.byType(FestivalArt), findsWidgets);

    await tester.tap(find.byIcon(Icons.access_time).last);
    await tester.pump();
    expect(find.text('Find muhurtas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined).last);
    await tester.pump();
    expect(find.text('Language'), findsOneWidget);
  });

  testWidgets('Tulu language with lipi toggle renders Tulu-Tigalari', (
    tester,
  ) async {
    final settings = await pumpApp(tester, lang: Lang.tcy);
    expect(find.text('ಇನಿ'), findsWidgets);
    settings.tuluLipi = true;
    await settings.update((_) {});
    await tester.pump();
    bool hasTuluRun(InlineSpan? span) {
      var found = false;
      span?.visitChildren((c) {
        if (c is TextSpan &&
            c.style?.fontFamily == kTuluFontFamily &&
            (c.text ?? '').runes.any((r) => r >= 0x11380 && r <= 0x113FF)) {
          found = true;
        }
        return !found;
      });
      return found;
    }

    final lipi = find.byWidgetPredicate(
      (w) => w is Text && hasTuluRun(w.textSpan),
    );
    expect(lipi, findsWidgets);
  });

  testWidgets('Kannada UI', (tester) async {
    await pumpApp(tester, lang: Lang.kn);
    expect(find.text('ತುಳು ಪಂಚಾಂಗ'), findsWidgets);
    expect(find.text('ರಾಹು ಕಾಲ'), findsWidgets);
  });
}

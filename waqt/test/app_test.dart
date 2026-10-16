import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/scope.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/app/strings.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/main.dart';
import 'package:waqt/screens/alerts_screen.dart';
import 'package:waqt/screens/display_screen.dart';
import 'package:waqt/screens/place_screen.dart';
import 'package:waqt/screens/timetable_screen.dart';
import 'package:waqt/screens/today_screen.dart';

Future<void> _pumpApp(WidgetTester tester, AppSettings settings) async {
  await tester.pumpWidget(WaqtApp(settings: settings, background: false));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Pushes [screen] inside the app scope.
Future<void> _pumpScreen(
  WidgetTester tester,
  AppSettings settings,
  Widget screen,
) async {
  await tester.pumpWidget(
    AppScope(
      settings: settings,
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() {
    // Small phone.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  for (final lang in Lang.values) {
    testWidgets('all tabs render ($lang)', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 720 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final settings = AppSettings.memory()..lang = lang;
      final s = settings;
      await _pumpApp(tester, settings);

      final str = S(s.lang);
      expect(find.text(str.prayer(Prayer.fajr)), findsWidgets);
      // Arabic and Urdu lay out right-to-left.
      expect(
        Directionality.of(tester.element(find.byType(TodayScreen))),
        lang.rtl ? TextDirection.rtl : TextDirection.ltr,
      );

      for (final icon in [
        Icons.calendar_month_outlined,
        Icons.explore_outlined,
        Icons.settings_outlined,
        Icons.access_time,
      ]) {
        await tester.tap(find.byIcon(icon));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
      }
      await _dispose(tester);
    });
  }

  testWidgets('day navigation and place card', (tester) async {
    final settings = AppSettings.memory();
    await _pumpApp(tester, settings);
    expect(find.text('Choose your place for accurate times'), findsOneWidget);
    final next = find.descendant(
      of: find.byType(TodayScreen),
      matching: find.byIcon(Icons.chevron_right),
    );
    // Centre it: at the very top edge the tap would land on the hero.
    final ctx = tester.element(next);
    Scrollable.ensureVisible(ctx, alignment: 0.5);
    await tester.pump();
    await tester.tap(next);
    await tester.pump();
    expect(find.text('Back to today'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('picking a place applies its method', (tester) async {
    final settings = AppSettings.memory();
    await _pumpScreen(tester, settings, const PlaceScreen());
    await tester.enterText(find.byType(TextField), 'dub');
    await tester.pump();
    await tester.tap(find.text('Dubai'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(settings.place.id, 'dubai');
    expect(settings.method, CalcMethod.dubai);
    expect(settings.placeChosen, isTrue);
    await _dispose(tester);
  });

  testWidgets('alerts screen toggles settings', (tester) async {
    final settings = AppSettings.memory();
    await _pumpScreen(tester, settings, const AlertsScreen());
    await tester.scrollUntilVisible(
      find.text('Auto silent during prayer'),
      200,
    );
    await tester.tap(find.text('Auto silent during prayer'));
    await tester.pump();
    expect(settings.alerts.silentEnabled, isTrue);
    expect(find.text('Stay quiet after Iqama'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('timetable paste import', (tester) async {
    final settings = AppSettings.memory();
    await _pumpScreen(tester, settings, const TimetableScreen());
    await tester.tap(find.text('Paste CSV text'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '# name: Masjid Test\n'
      'date,fajr,sunrise,dhuhr,asr,maghrib,isha\n'
      '01-01,05:28,06:51,12:36,15:51,18:17,19:32\n',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(settings.timetableEnabled, isTrue);
    expect(settings.timetable?.name, 'Masjid Test');
    expect(find.text('Masjid Test'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('display mode renders in landscape and portrait', (tester) async {
    final settings = AppSettings.memory();
    for (final size in const [Size(1920, 1080), Size(1080, 1920)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.5;
      await _pumpScreen(
        tester,
        settings,
        const DisplayScreen(keepAwake: false),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Iqama'), findsWidgets);
    }
    tester.view.reset();
    await _dispose(tester);
  });
}

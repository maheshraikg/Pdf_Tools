import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/city_data.dart';
import 'package:waqt/app/scope.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/app/strings.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/main.dart';
import 'package:waqt/screens/alerts_screen.dart';
import 'package:waqt/screens/display_screen.dart';
import 'package:waqt/screens/display_settings_screen.dart';
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
    final settings = AppSettings.memory()..displayNextPage = false;
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

  testWidgets('display pages rotate and lock for the Iqama countdown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.reset);
    final settings = AppSettings.memory()
      ..mosqueName = 'Masjid Test'
      ..displaySeconds = 10
      ..announcements = ['Please switch off your phones'];
    // Friday 16 Oct 2026, 13:30 in Kozhikode: after Jumu'ah, before Asr.
    var now = DateTime.utc(2026, 10, 16, 8, 0);
    await _pumpScreen(
      tester,
      settings,
      DisplayScreen(keepAwake: false, clock: () => now),
    );
    expect(find.text('Masjid Test'), findsOneWidget);
    expect(find.text('Iqama'), findsWidgets); // times page
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('NEXT'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Please switch off your phones'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Between Asr Azan and Iqama the countdown page stays.
    final asr = settings.calculator.day(2026, 10, 16)[Prayer.asr];
    now = asr.add(const Duration(minutes: 2));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('IQAMA'), findsOneWidget);
    }
    await _dispose(tester);
  });

  testWidgets('alerts screen offers Azan sounds and Ramadan/Eid alerts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = AppSettings.memory();
    await _pumpScreen(tester, settings, const AlertsScreen());
    await tester.scrollUntilVisible(find.text('Fajr Azan sound'), 200);
    await tester.tap(find.text('Azan sound').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soft chime'));
    await tester.pumpAndSettle();
    expect(settings.alerts.azanSound.sound.name, 'chime');
    expect(find.text('Vibrate'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Eid prayer alert'), 200);
    await Scrollable.ensureVisible(
      tester.element(find.text('Eid prayer alert')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eid prayer alert'));
    await tester.pumpAndSettle();
    expect(settings.alerts.eidAlert, isTrue);
    expect(find.text('Eid al-Fitr prayer'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('display settings: add an announcement', (tester) async {
    final settings = AppSettings.memory();
    await _pumpScreen(tester, settings, const DisplaySettingsScreen());
    await tester.tap(find.text('Add announcement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Jumuah khutbah 12:30');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(settings.announcements, ['Jumuah khutbah 12:30']);
    expect(settings.displayPageCount, 3);
    expect(find.text('Jumuah khutbah 12:30'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('place search finds world cities', (tester) async {
    final settings = AppSettings.memory();
    debugResetCities();
    final cities = await tester.runAsync(loadCities);
    expect(cities, isNotEmpty);
    await _pumpScreen(tester, settings, const PlaceScreen());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'london');
    await tester.pump();
    expect(find.text('World places'.toUpperCase()), findsOneWidget);
    await tester.tap(find.text('London').first);
    await tester.pumpAndSettle();
    expect(settings.place.timeZone, 'Europe/London');
    expect(settings.method.id, 'mwl');
    await _dispose(tester);
  });
}

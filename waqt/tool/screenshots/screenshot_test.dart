// Renders the main screens to PNG for visual review (not part of CI).
//
//   flutter test tool/screenshots/screenshot_test.dart
//
// Needs Roboto (from the Flutter SDK cache) and Noto Sans for Malayalam,
// Arabic, Devanagari, Tamil, Kannada and Bengali
// (apt install fonts-noto-core). Output: docs/screenshots/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/city_data.dart';
import 'package:waqt/app/scope.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/main.dart';
import 'package:waqt/screens/alerts_screen.dart';
import 'package:waqt/screens/display_screen.dart';
import 'package:waqt/screens/place_screen.dart';
import 'package:waqt/screens/share_screen.dart';
import 'package:waqt/ui/sky_scene.dart';
import 'package:waqt/screens/tracker_screen.dart';
import 'package:waqt/screens/onboarding_screen.dart';
import 'package:waqt/core/tracker.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/core/alerts.dart';

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$sdk/bin/cache/artifacts/material_fonts';
  const noto = '/usr/share/fonts/truetype/noto';

  setUpAll(() async {
    await loadFont('Roboto', [
      '$mf/Roboto-Regular.ttf',
      '$mf/Roboto-Medium.ttf',
      '$mf/Roboto-Bold.ttf',
      '$mf/Roboto-Light.ttf',
    ]);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    const scripts = [
      'Malayalam',
      'Arabic',
      'Devanagari',
      'Tamil',
      'Kannada',
      'Bengali',
    ];
    for (final sc in scripts) {
      await loadFont('Noto$sc', [
        '$noto/NotoSans$sc-Regular.ttf',
        '$noto/NotoSans$sc-Bold.ttf',
      ]);
    }
    debugFontFallback = [for (final sc in scripts) 'Noto$sc'];
    Directory('docs/screenshots').createSync(recursive: true);
  });

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('docs/screenshots/$name.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  AppSettings settingsFor(Lang lang) {
    final st = AppSettings.memory()
      ..lang = lang
      ..placeChosen = true;
    // A few days of ticked prayers for the tracker.
    final today = st.today;
    for (var i = 1; i <= 6; i++) {
      for (final p in Prayer.fard) {
        if (i == 4 && p == Prayer.fajr) continue;
        st.log.toggle(today.subtract(Duration(days: i)), p);
      }
    }
    st.log.toggle(today, Prayer.fajr);
    st.log.toggle(today, Prayer.dhuhr);
    for (var i = 0; i < 21; i++) {
      st.tasbih.tap(dateKey(today));
    }
    return st;
  }

  for (final lang in [Lang.en, Lang.ml]) {
    testWidgets('screens ${lang.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 860));
      final key = GlobalKey();
      final settings = settingsFor(lang);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: WaqtApp(settings: settings, background: false),
        ),
      );
      await shot(tester, key, '${lang.name}_1_today');
      for (final (icon, name) in [
        (Icons.calendar_month_outlined, '2_month'),
        (Icons.explore_outlined, '3_qibla'),
        (Icons.radio_button_checked_outlined, '11_tasbih'),
        (Icons.settings_outlined, '4_settings'),
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pump();
        await shot(tester, key, '${lang.name}_$name');
      }
      await tester.pumpWidget(const SizedBox());

      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: AppScope(
            settings: settings,
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: const AlertsScreen(),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      await shot(tester, key, '${lang.name}_5_alerts');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  testWidgets('today in every language', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final key = GlobalKey();
    for (final lang in Lang.values.where((l) => l != Lang.en && l != Lang.ml)) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: WaqtApp(settings: settingsFor(lang), background: false),
        ),
      );
      await shot(tester, key, 'lang_${lang.code}_today');
      await tester.pumpWidget(const SizedBox());
    }
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('display mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          settings: settingsFor(Lang.en),
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: const DisplayScreen(keepAwake: false),
          ),
        ),
      ),
    );
    await shot(tester, key, 'en_6_display');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('display pages', (tester) async {
    await tester.binding.setSurfaceSize(const Size(960, 540));
    final key = GlobalKey();
    final settings = settingsFor(Lang.en)
      ..mosqueName = 'Masjid Al-Noor, Kozhikode'
      ..displaySeconds = 10
      ..announcements = [
        "Jumu'ah khutbah starts at 12:30.\nPlease switch off your phones.",
      ];
    // Friday 16 Oct 2026, 15:10 in Kozhikode (before Asr).
    final now = DateTime.utc(2026, 10, 16, 9, 40);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          settings: settings,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: DisplayScreen(keepAwake: false, clock: () => now),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 11));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, key, 'en_7_display_next');
    await tester.pump(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 1));
    await shot(tester, key, 'en_8_display_announcement');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('azan sound and places', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final key = GlobalKey();
    final settings = settingsFor(Lang.en)
      ..alerts = const AlertConfig(
        azanSound: SoundChoice(
          AzanSound.custom,
          path: 'file:/azan.mp3',
          fileName: 'Azan Makkah.mp3',
        ),
        fajrSound: SoundChoice(AzanSound.chime),
        taraweehAlert: true,
        eidAlert: true,
      );
    Widget wrap(Widget home) => RepaintBoundary(
      key: key,
      child: AppScope(
        settings: settings,
        child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
      ),
    );
    await tester.pumpWidget(wrap(const AlertsScreen()));
    await tester.scrollUntilVisible(find.text('Fajr Azan sound'), 300);
    await Scrollable.ensureVisible(
      tester.element(find.text('Fajr Azan sound')),
      alignment: 0.2,
    );
    await tester.pumpAndSettle();
    await shot(tester, key, 'en_9_azan_sound');
    await tester.pumpWidget(const SizedBox());

    debugResetCities();
    await tester.runAsync(loadCities);
    await tester.pumpWidget(wrap(const PlaceScreen()));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'tir');
    await tester.pump();
    await shot(tester, key, 'en_10_places');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tracker and setup', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final key = GlobalKey();
    final settings = settingsFor(Lang.en);
    Widget wrap(Widget home) => RepaintBoundary(
      key: key,
      child: AppScope(
        settings: settings,
        child: MaterialApp(theme: buildTheme(Brightness.light), home: home),
      ),
    );
    await tester.pumpWidget(wrap(const TrackerScreen()));
    await shot(tester, key, 'en_12_tracker');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(wrap(const OnboardingScreen()));
    // Asset images decode asynchronously in tests.
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(OnboardingScreen));
      await precacheImage(const AssetImage('assets/app_icon.png'), ctx);
    });
    await tester.pump();
    await shot(tester, key, 'en_13_setup');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('share poster', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final key = GlobalKey();
    final settings = settingsFor(Lang.en);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          settings: settings,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: ShareScreen(date: settings.today),
          ),
        ),
      ),
    );
    await shot(tester, key, 'en_12_share');
    // Small phone, large text.
    await tester.binding.setSurfaceSize(const Size(360, 720));
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          settings: settings..lang = Lang.kn,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: ShareScreen(date: settings.today),
          ),
        ),
      ),
    );
    await shot(tester, key, 'kn_12_share_small');
    settings.lang = Lang.en;
    await tester.binding.setSurfaceSize(const Size(400, 860));
    for (final l in [Lang.kn, Lang.ml, Lang.ar]) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: AppScope(
            settings: settings,
            child: MaterialApp(
              theme: buildTheme(Brightness.light),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 360,
                    child: PrayerPoster(
                      day: settings.calculator.day(2026, 10, 23),
                      lang: l,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/app_icon.png'),
          tester.element(find.byType(PrayerPoster)),
        ),
      );
      await tester.pump();
      await shot(tester, key, 'share_poster_${l.code}');
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('sky phases', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1300));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Column(
          children: [
            for (final p in SkyPhase.values)
              SizedBox(
                height: 260,
                width: 400,
                child: SkyScene(phase: p, child: const SizedBox.expand()),
              ),
          ],
        ),
      ),
    );
    await shot(tester, key, 'sky_phases');
  });
}

// Renders the main screens to PNG for visual review (not part of CI).
//
//   flutter test tool/screenshots/screenshot_test.dart
//
// Needs Roboto (from the Flutter SDK cache) and Noto Sans Malayalam
// (apt install fonts-noto-core). Output: docs/screenshots/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/scope.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/main.dart';
import 'package:waqt/screens/alerts_screen.dart';
import 'package:waqt/screens/display_screen.dart';

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
    await loadFont('NotoMalayalam', [
      '$noto/NotoSansMalayalam-Regular.ttf',
      '$noto/NotoSansMalayalam-Bold.ttf',
    ]);
    debugFontFallback = ['NotoMalayalam'];
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

  AppSettings settingsFor(Lang lang) => AppSettings.memory()
    ..lang = lang
    ..placeChosen = true;

  for (final lang in Lang.values) {
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
}

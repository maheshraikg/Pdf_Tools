// Renders the main screens to PNG for visual review (not part of CI).
//
//   flutter test tool/screenshots/screenshot_test.dart
//
// Needs Roboto (from the Flutter SDK cache) and Noto Sans Kannada
// (apt install fonts-noto-core). Output: docs/screenshots/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/app/settings.dart';
import 'package:tulu_panchanga/main.dart';
import 'package:tulu_panchanga/panchanga/names.dart';

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
    ]);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    await loadFont('NotoKannada', [
      '$noto/NotoSansKannada-Regular.ttf',
      '$noto/NotoSansKannada-Bold.ttf',
    ]);
    await loadFont('TuluTigalari', ['assets/fonts/mallige_v1.4.ttf']);
    await loadFont('DejaVu', [
      '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    ]);
    debugFontFallback = ['NotoKannada', 'DejaVu'];
    Directory('docs/screenshots').createSync(recursive: true);
  });

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('docs/screenshots/$name.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final lang in [Lang.en, Lang.kn, Lang.tcy]) {
    testWidgets('screens ${lang.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 860));
      final key = GlobalKey();
      final settings = AppSettings.memory()
        ..lang = lang
        ..tuluLipi = false;
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: TuluPanchangaApp(settings: settings, background: false),
        ),
      );
      await settle(tester);
      await shot(tester, key, '${lang.name}_1_today');
      if (lang == Lang.en) {
        // Mahalaya Amavasya (10 Oct 2026) is six days after 4 Oct.
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
          await tester.pump(const Duration(milliseconds: 400));
        }
        await settle(tester);
        await tester.pump(const Duration(seconds: 1));
        await shot(tester, key, 'en_1b_festival_day');
        await tester.tap(find.text('Mahalaya Amavasya').first);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await shot(tester, key, 'en_1c_festival_sheet');
        Navigator.of(tester.element(find.text('Mahalaya Amavasya').last)).pop();
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byIcon(Icons.today_rounded));
        await tester.pump(const Duration(seconds: 1));
      }

      for (final (icon, name) in [
        (Icons.calendar_month_outlined, '2_calendar'),
        (Icons.celebration_outlined, '3_festivals'),
        (Icons.access_time, '4_muhurta'),
        (Icons.settings_outlined, '5_settings'),
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pump();
        await settle(tester);
        if (name == '4_muhurta') {
          await tester.tap(find.byIcon(Icons.search));
          await tester.pump();
          await settle(tester);
        }
        await shot(tester, key, '${lang.name}_$name');
      }
      if (lang == Lang.tcy) {
        await tester.tap(find.byIcon(Icons.calendar_month_outlined).last);
        await tester.pump();
        await tester.tap(find.text('ತುಳು ತಿಂಗೊಲು').first);
        await tester.pump();
        await settle(tester);
        await shot(tester, key, 'tcy_6_tulu_month');
        settings.tuluLipi = true;
        await settings.update((_) {});
        await tester.tap(find.byIcon(Icons.wb_sunny_outlined).last);
        await tester.pump();
        await settle(tester);
        await shot(tester, key, 'tcy_7_today_lipi');
      }
    });
  }
}

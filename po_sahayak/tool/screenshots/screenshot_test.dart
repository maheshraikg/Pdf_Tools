// Renders the main screens to PNG for visual review (not part of CI).
//
//   flutter test tool/screenshots/screenshot_test.dart
//
// Needs Roboto (from the Flutter SDK cache) and Noto Sans Kannada
// (apt install fonts-noto-core). Output: docs/screenshots/*.png
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:io';
import 'dart:ui' as ui;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/app/settings.dart';
import 'package:po_sahayak/app/theme.dart';
import 'package:po_sahayak/data/saved_account_repository.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/domain/rates/rate_repository.dart';
import 'package:po_sahayak/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      '$mf/Roboto-Black.ttf',
    ]);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    await loadFont('NotoKannada', [
      '$noto/NotoSansKannada-Regular.ttf',
      '$noto/NotoSansKannada-Bold.ttf',
    ]);
    debugFontFallback = ['NotoKannada'];
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  }

  for (final lang in ['en', 'kn', 'dark', 'big', 'bigkn']) {
    testWidgets('screens $lang', (tester) async {
      final big = lang.startsWith('big');
      await tester.binding.setSurfaceSize(
        big ? const Size(360, 780) : const Size(400, 860),
      );
      if (big) {
        // A phone with a large system font, like the one in the bug report.
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }
      SharedPreferences.setMockInitialValues({
        'lang': lang == 'kn' || lang == 'bigkn' ? 'kn' : 'en',
        if (lang == 'dark') 'theme': 'dark',
      });
      final settings = await AppSettings.load();
      final accounts = await SavedAccountRepository.load();
      final rates = RateRepository.fromJson(
        File('assets/rates.json').readAsStringSync(),
      );
      if (lang == 'en' || lang == 'dark' || lang == 'big') {
        await accounts.add(
          'Amma SCSS',
          CalcInput(
            scheme: Scheme.scss,
            amount: Decimal.fromInt(1500000),
            opening: DateTime(2022, 6, 1),
            rate: Decimal.parse('8.0'),
          ),
        );
        await accounts.add(
          'Ravi RD',
          CalcInput(
            scheme: Scheme.rd,
            amount: Decimal.fromInt(5000),
            opening: DateTime(2024, 2, 10),
            rate: Decimal.parse('6.7'),
          ),
        );
      }
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: PoSahayakApp(
            settings: settings,
            rates: rates,
            accounts: accounts,
            background: false,
          ),
        ),
      );
      await settle(tester);
      await shot(tester, key, '${lang}_1_home');

      await tester.scrollUntilVisible(
        find.text('TD5'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('TD5'));
      await settle(tester);
      await tester.enterText(find.byType(TextFormField).first, '100000');
      await settle(tester);
      await shot(tester, key, '${lang}_2_calculator');

      await tester.tap(find.byIcon(Icons.calculate_rounded));
      await settle(tester);
      await shot(tester, key, '${lang}_3_result');
      await tester.drag(find.byType(ListView).last, const Offset(0, -620));
      await settle(tester);
      await shot(tester, key, '${lang}_4_result_charts');
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.popUntil((r) => r.isFirst);
      await settle(tester);

      for (final (icon, name) in [
        (Icons.leaderboard_outlined, '5_compare'),
        (Icons.account_balance_wallet_outlined, '6_accounts'),
        (Icons.support_agent_outlined, '7_staff'),
        (Icons.settings_outlined, '8_settings'),
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await settle(tester);
        await shot(tester, key, '${lang}_$name');
      }
    });
  }
}

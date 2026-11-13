// Records animation frames of Home and a Daily Challenge answer to PNGs
// (assembled into docs/preview.gif by tool/screenshots/make_gif.py).
//
//   flutter test tool/screenshots/animation_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/app_store.dart';
import 'package:ganita_aata/games/daily_challenge_game.dart';
import 'package:ganita_aata/main.dart';
import 'package:ganita_aata/screens/home_screen.dart';
import 'package:ganita_aata/services/app_state.dart';
import 'package:ganita_aata/services/audio_service.dart';
import 'package:ganita_aata/services/notification_service.dart';
import 'package:ganita_aata/widgets/answer_grid.dart';
import 'package:ganita_aata/widgets/app_theme.dart';

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    if (!File(p).existsSync()) continue;
    loader.addFont(Future.value(ByteData.view(File(p).readAsBytesSync().buffer)));
  }
  await loader.load();
}

void main() {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$sdk/bin/cache/artifacts/material_fonts';
  const out = 'build/anim';

  setUpAll(() async {
    await loadFont('NotoSansKannada', ['assets/fonts/NotoSansKannada-Regular.ttf', 'assets/fonts/NotoSansKannada-Bold.ttf']);
    await loadFont('Baloo', ['assets/fonts/BalooTamma2-500.ttf', 'assets/fonts/BalooTamma2-700.ttf', 'assets/fonts/BalooTamma2-800.ttf']);
    await loadFont('Roboto', ['$mf/Roboto-Regular.ttf', '$mf/Roboto-Bold.ttf']);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    debugFontFallback = ['Roboto'];
    Directory(out).createSync(recursive: true);
  });

  AppState makeApp() {
    final app = AppState(
      store: MemoryAppStore(),
      audio: SilentAudioService(),
      notifications: NoopNotificationService(),
      clock: () => DateTime(2026, 11, 9, 10),
    );
    app.setLanguage('en');
    app.createProfile(name: 'Ananya', schoolClass: 3, avatar: 'av_parrot');
    app.active!.coins = 135;
    return app;
  }

  var frame = 0;
  Future<void> capture(WidgetTester tester, GlobalKey key, int frames, {int ms = 80}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(Duration(milliseconds: ms));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$out/f_${(frame++).toString().padLeft(4, '0')}.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
  }

  testWidgets('record', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    final key = GlobalKey();
    final app = makeApp();
    // Warm up images.
    await tester.pumpWidget(RepaintBoundary(key: key, child: GanitaAataApp(state: app, home: const SizedBox())));
    await tester.pumpWidget(RepaintBoundary(key: key, child: GanitaAataApp(state: app, home: const HomeScreen())));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await tester.pump();
    }
    await capture(tester, key, 26);
    // Daily Challenge: answer two sums right, one gently wrong.
    await tester.pumpWidget(RepaintBoundary(key: key, child: GanitaAataApp(state: app, home: const DailyChallengeGame())));
    final qs = app.dailyQuestions;
    await capture(tester, key, 10);
    for (var n = 0; n < 3; n++) {
      final ans = n == 2 ? qs[n].answer.value + 1 : qs[n].answer.value;
      final f = find.descendant(of: find.byType(AnswerGrid), matching: find.text('$ans'));
      await tester.tap(f.evaluate().isEmpty ? find.byKey(const ValueKey('answer_0')) : f);
      await capture(tester, key, n == 2 ? 26 : 14);
    }
  });
}

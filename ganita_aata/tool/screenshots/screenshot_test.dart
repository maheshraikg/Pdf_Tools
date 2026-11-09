// Renders the main screens to PNG for visual review (not part of CI).
//
//   flutter test tool/screenshots/screenshot_test.dart
//
// Needs Roboto + Material icons (Flutter SDK cache) and, for avatars,
// Noto Color Emoji (apt install fonts-noto-color-emoji).
// Output: docs/screenshots/<lang>_<n>_<screen>.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/app_store.dart';
import 'package:ganita_aata/games/balloon_pop_game.dart';
import 'package:ganita_aata/games/race_car_game.dart';
import 'package:ganita_aata/games/speed_challenge_game.dart';
import 'package:ganita_aata/games/tables_master_screen.dart';
import 'package:ganita_aata/games/treasure_hunt_game.dart';
import 'package:ganita_aata/main.dart';
import 'package:ganita_aata/models/game_result.dart';
import 'package:ganita_aata/models/question.dart';
import 'package:ganita_aata/screens/home_screen.dart';
import 'package:ganita_aata/screens/level_map_screen.dart';
import 'package:ganita_aata/screens/progress_screen.dart';
import 'package:ganita_aata/screens/result_screen.dart';
import 'package:ganita_aata/screens/settings_screen.dart';
import 'package:ganita_aata/screens/shop_screen.dart';
import 'package:ganita_aata/services/app_state.dart';
import 'package:ganita_aata/services/audio_service.dart';
import 'package:ganita_aata/services/notification_service.dart';
import 'package:ganita_aata/widgets/motion.dart';
import 'package:ganita_aata/widgets/app_theme.dart';

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    if (!File(p).existsSync()) continue;
    final bytes = File(p).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  setUpAll(() => motionEnabled = false);

  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$sdk/bin/cache/artifacts/material_fonts';

  setUpAll(() async {
    await loadFont('NotoSansKannada', ['assets/fonts/NotoSansKannada-Regular.ttf', 'assets/fonts/NotoSansKannada-Bold.ttf']);
    await loadFont('Baloo', ['assets/fonts/BalooTamma2-500.ttf', 'assets/fonts/BalooTamma2-700.ttf', 'assets/fonts/BalooTamma2-800.ttf']);
    await loadFont('Roboto', ['$mf/Roboto-Regular.ttf', '$mf/Roboto-Medium.ttf', '$mf/Roboto-Bold.ttf']);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    await loadFont('NotoColorEmoji', ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf']);
    debugFontFallback = ['Roboto', 'NotoColorEmoji'];
    Directory('docs/screenshots').createSync(recursive: true);
  });

  AppState makeApp(String lang) {
    final now = DateTime(2026, 11, 9, 10);
    final app = AppState(
      store: MemoryAppStore(),
      audio: SilentAudioService(),
      notifications: NoopNotificationService(),
      clock: () => now,
    );
    app.setLanguage(lang);
    app.createProfile(name: lang == 'kn' ? 'ಅನನ್ಯ' : 'Ananya', schoolClass: 4, avatar: 'av_parrot');
    app.active!
      ..coins = 135
      ..streak = 4
      ..lastDailyDate = '2026-11-08'
      ..badges.addAll(['speed_star', 'table_2', 'table_5', 'streak_7']);
    // Some history for the progress screen.
    for (final t in ['add2', 'sub2', 'tab2_5', 'tab6_10']) {
      for (var i = 0; i < 30; i++) {
        app.recordAnswer(app.nextQuestion(t), i % 5 != 0, 2500 + (i % 7) * 400);
      }
    }
    return app;
  }

  Future<void> shot(WidgetTester tester, GlobalKey key, String name) async {
    await tester.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('docs/screenshots/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'levels': () => const LevelMapScreen(),
    'balloon': () => const BalloonPopGame(topicId: 'tab6_10'),
    'race': () => const RaceCarGame(topicId: 'tab6_10'),
    'treasure': () => const TreasureHuntGame(topicId: 'add3'),
    'speed': () => const SpeedChallengeGame(topicId: 'div1'),
    'tables': () => const TableLearnScreen(table: 7),
    'result': () => ResultScreen(
          result: GameResult(
            mode: GameMode.balloon,
            topicId: 'tab6_10',
            items: [
              for (var b = 1; b <= 10; b++)
                QuestionResult(
                  question: Question.fromParts('tab6_10', Op.mul, 7, b),
                  given: Answer(7 * b),
                  correct: b != 8 && b != 6,
                  timeMs: 3000,
                ),
            ],
          ),
          summary: const RoundSummary(stars: 2, coins: 8, unlockedTopics: ['add3']),
          onReplay: (_) {},
        ),
    'shop': () => const ShopScreen(),
    'progress': () => const ProgressScreen(),
    'settings': () => const SettingsScreen(),
  };

  for (final lang in ['kn', 'en']) {
    var n = 0;
    for (final e in screens.entries) {
      final idx = ++n;
      testWidgets('$lang ${e.key}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(400, 860));
        final key = GlobalKey();
        final app = makeApp(lang);
        await tester.pumpWidget(RepaintBoundary(key: key, child: GanitaAataApp(state: app, home: e.value())));
        final waits = e.key == 'race' ? 16 : (e.key == 'balloon' ? 10 : 3);
        for (var i = 0; i < waits; i++) {
          await tester.pump(const Duration(milliseconds: 300));
        }
        // Let asset images decode (real async I/O), then repaint.
        for (var i = 0; i < 6; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await shot(tester, key, '${lang}_${idx.toString().padLeft(2, '0')}_${e.key}');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

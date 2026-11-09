// Renders every screen in both languages on a small, low-end phone size
// (360 × 640 dp) with large text. Any overflow fails the test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/app_store.dart';
import 'package:ganita_aata/games/balloon_pop_game.dart';
import 'package:ganita_aata/games/daily_challenge_game.dart';
import 'package:ganita_aata/games/race_car_game.dart';
import 'package:ganita_aata/games/speed_challenge_game.dart';
import 'package:ganita_aata/games/tables_master_screen.dart';
import 'package:ganita_aata/games/treasure_hunt_game.dart';
import 'package:ganita_aata/main.dart';
import 'package:ganita_aata/models/game_result.dart';
import 'package:ganita_aata/models/question.dart';
import 'package:ganita_aata/screens/badges_screen.dart';
import 'package:ganita_aata/screens/home_screen.dart';
import 'package:ganita_aata/screens/language_screen.dart';
import 'package:ganita_aata/screens/level_map_screen.dart';
import 'package:ganita_aata/screens/pin_screen.dart';
import 'package:ganita_aata/screens/profile_setup_screen.dart';
import 'package:ganita_aata/screens/progress_screen.dart';
import 'package:ganita_aata/screens/result_screen.dart';
import 'package:ganita_aata/screens/settings_screen.dart';
import 'package:ganita_aata/screens/shop_screen.dart';
import 'package:ganita_aata/services/app_state.dart';
import 'package:ganita_aata/services/audio_service.dart';
import 'package:ganita_aata/services/notification_service.dart';

void main() {
  AppState makeApp(String lang) {
    final app = AppState(
      store: MemoryAppStore(),
      audio: SilentAudioService(),
      notifications: NoopNotificationService(),
      clock: () => DateTime(2026, 11, 9, 10),
    );
    app.setLanguage(lang);
    app.createProfile(name: 'Lakshminarayana', schoolClass: 5, avatar: 'av_tiger');
    app.active!.coins = 12345;
    for (var i = 0; i < 40; i++) {
      final q = app.nextQuestion(i.isEven ? 'tab11_20' : 'divRem');
      app.recordAnswer(q, i % 3 != 0, 3000 + i * 50);
    }
    return app;
  }

  final screens = <String, Widget Function()>{
    'language': () => const LanguageScreen(),
    'profile': () => const ProfileSetupScreen(),
    'home': () => const HomeScreen(),
    'levels': () => const LevelMapScreen(),
    'shop': () => const ShopScreen(),
    'badges': () => const BadgesScreen(),
    'pin': () => const PinScreen(mode: PinMode.verify),
    'settings': () => const SettingsScreen(),
    'progress': () => const ProgressScreen(),
    'tables': () => const TablesMasterScreen(),
    'learn': () => const TableLearnScreen(table: 17),
    'quiz': () => const TableQuizGame(table: 19),
    'balloon': () => const BalloonPopGame(topicId: 'divRem'),
    'race': () => const RaceCarGame(topicId: 'tab11_20'),
    'treasure': () => const TreasureHuntGame(topicId: 'divRem'),
    'speed': () => const SpeedChallengeGame(topicId: 'divRem'),
    'daily': () => const DailyChallengeGame(),
    'result': () => ResultScreen(
      result: GameResult(
        mode: GameMode.race,
        topicId: 'divRem',
        raceWon: false,
        items: [
          for (var i = 0; i < 6; i++)
            QuestionResult(
              question: Question.fromParts('divRem', Op.divRem, 97 + i, 8),
              given: const Answer(1, 1),
              correct: i.isEven,
              timeMs: 4000,
            ),
        ],
      ),
      summary: const RoundSummary(stars: 1, coins: 3, unlockedTopics: ['fractions'], streak: 12),
      onReplay: (_) {},
    ),
  };

  for (final lang in ['kn', 'en']) {
    for (final e in screens.entries) {
      testWidgets('$lang ${e.key} fits a small phone', (tester) async {
        tester.view.physicalSize = const Size(720, 1280);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.reset);
        final app = makeApp(lang);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.15)),
            child: GanitaAataApp(state: app, home: e.value()),
          ),
        );
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 500));
        }
        expect(tester.takeException(), isNull);
        // Leave timed games cleanly.
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}

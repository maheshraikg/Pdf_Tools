import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/app_store.dart';
import 'package:ganita_aata/data/shop_catalog.dart';
import 'package:ganita_aata/engine/rewards.dart';
import 'package:ganita_aata/models/game_result.dart';
import 'package:ganita_aata/models/question.dart';
import 'package:ganita_aata/services/app_state.dart';
import 'package:ganita_aata/services/audio_service.dart';
import 'package:ganita_aata/services/notification_service.dart';

void main() {
  group('stars and coins', () {
    test('star thresholds 50/75/90%', () {
      expect(Rewards.stars(0, 0), 0);
      expect(Rewards.stars(4, 10), 0);
      expect(Rewards.stars(5, 10), 1);
      expect(Rewards.stars(7, 10), 1);
      expect(Rewards.stars(3, 4), 2);
      expect(Rewards.stars(8, 10), 2);
      expect(Rewards.stars(9, 10), 3);
      expect(Rewards.stars(10, 10), 3);
    });

    test('1 coin per correct answer plus a 3-star bonus', () {
      expect(Rewards.coins(7, 1), 7);
      expect(Rewards.coins(9, 3), 9 + Rewards.threeStarBonus);
    });
  });

  group('streak', () {
    final d = DateTime(2026, 11, 9);
    test('first completion starts at 1', () {
      expect(Streak.afterCompletion(streak: 0, lastDay: null, today: d), 1);
    });
    test('consecutive days add up, gaps restart, same day does not count twice', () {
      expect(Streak.afterCompletion(streak: 4, lastDay: d, today: d.add(const Duration(days: 1))), 5);
      expect(Streak.afterCompletion(streak: 4, lastDay: d, today: d.add(const Duration(days: 2))), 1);
      expect(Streak.afterCompletion(streak: 4, lastDay: d, today: DateTime(2026, 11, 9, 22)), isNull);
      // Across a month end.
      expect(Streak.afterCompletion(streak: 2, lastDay: DateTime(2026, 11, 30), today: DateTime(2026, 12, 1)), 3);
    });
    test('shown streak drops to 0 after a missed day', () {
      expect(Streak.current(streak: 6, lastDay: d, today: d), 6);
      expect(Streak.current(streak: 6, lastDay: d, today: d.add(const Duration(days: 1))), 6);
      expect(Streak.current(streak: 6, lastDay: d, today: d.add(const Duration(days: 2))), 0);
    });
  });

  group('app state', () {
    late DateTime now;
    late AppState app;

    setUp(() {
      now = DateTime(2026, 11, 9, 10);
      app = AppState(
        store: MemoryAppStore(),
        audio: SilentAudioService(),
        notifications: NoopNotificationService(),
        clock: () => now,
      );
      app.createProfile(name: 'Asha', schoolClass: 4, avatar: 'av_monkey');
    });

    GameResult round(GameMode mode, int correct, int total, {String topic = 'tab6_10'}) {
      final items = <QuestionResult>[];
      for (var i = 0; i < total; i++) {
        final q = Question.fromParts(topic, Op.mul, 7, (i % 10) + 1);
        final ok = i < correct;
        app.recordAnswer(q, ok, 2000);
        items.add(QuestionResult(question: q, given: q.answer, correct: ok, timeMs: 2000));
      }
      return GameResult(mode: mode, topicId: topic, items: items);
    }

    test('new child starts at the level for their class', () {
      expect(app.active!.currentTopic, 'tab6_10');
      expect(app.isLevelUnlocked(3), isTrue);
      expect(app.isLevelUnlocked(4), isFalse);
      expect(app.dailyLevel, 3);
    });

    test('round rewards coins and stars', () {
      final s = app.finishRound(round(GameMode.balloon, 10, 10));
      expect(s.stars, 3);
      expect(s.coins, 10 + Rewards.threeStarBonus);
      expect(app.active!.coins, s.coins);
    });

    test('daily challenge increases the streak once per day', () {
      app.beginRound();
      var s = app.finishRound(round(GameMode.daily, 8, 10));
      expect(s.streak, 1);
      expect(app.dailyDoneToday, isTrue);
      s = app.finishRound(round(GameMode.daily, 8, 10));
      expect(s.streak, isNull);
      now = now.add(const Duration(days: 1));
      expect(app.dailyDoneToday, isFalse);
      s = app.finishRound(round(GameMode.daily, 8, 10));
      expect(s.streak, 2);
      expect(app.currentStreak, 2);
    });

    test('7-day streak badge', () {
      for (var i = 0; i < 7; i++) {
        final s = app.finishRound(round(GameMode.daily, 10, 10));
        if (i < 6) expect(s.newBadges, isNot(contains(Badges.streak7)));
        if (i == 6) expect(s.newBadges, contains(Badges.streak7));
        now = now.add(const Duration(days: 1));
      }
    });

    test('speed star, table master and 100-a-day badges', () {
      final speed = app.finishRound(round(GameMode.speed, 20, 22));
      expect(speed.newBadges, contains(Badges.speedStar));
      expect(speed.best, 20);
      // 30 fast correct answers on table 7 (3 per line) master it.
      final t = app.finishRound(round(GameMode.tables, 30, 30));
      expect(t.newBadges, contains(Badges.table(7)));
      final big = app.finishRound(round(GameMode.balloon, 40, 50));
      expect(big.newBadges, contains(Badges.day100));
      // Not awarded twice.
      expect(app.finishRound(round(GameMode.speed, 21, 21)).newBadges, isEmpty);
    });

    test('topic unlock is reported in the round summary and saved', () {
      app.beginRound();
      final s = app.finishRound(round(GameMode.treasure, 30, 30));
      expect(s.unlockedTopics, ['add3']);
      expect(app.isUnlocked('add3'), isTrue);
    });

    test('shop: buy needs coins, equips, and free items are owned', () {
      final lion = ShopCatalog.byId('av_giraffe');
      expect(app.buy(lion), isFalse);
      app.active!.coins = 100;
      expect(app.buy(lion), isTrue);
      expect(app.active!.coins, 100 - lion.price);
      expect(app.active!.avatar, 'av_giraffe');
      expect(app.owns(ShopCatalog.byId('car_red')), isTrue);
      expect(app.buy(lion), isFalse); // already owned
    });

    test('PIN is stored hashed and checked', () {
      expect(app.hasPin, isFalse);
      app.setPin('2468');
      expect(app.checkPin('2468'), isTrue);
      expect(app.checkPin('1234'), isFalse);
      final stored = (app.store as MemoryAppStore).settings;
      expect(stored.values.contains('2468'), isFalse);
    });

    test('reset clears progress for the active child only', () async {
      app.active!.coins = 50;
      app.finishRound(round(GameMode.balloon, 5, 10));
      final asha = app.active!;
      app.createProfile(name: 'Ravi', schoolClass: 2, avatar: 'av_rabbit');
      app.finishRound(round(GameMode.balloon, 5, 10, topic: 'tab2_5'));
      app.switchProfile(asha);
      await app.resetProgress();
      expect(app.active!.coins, 0);
      expect(app.engine.totalSums, 0);
      final ravi = app.profiles.firstWhere((p) => p.name == 'Ravi');
      app.switchProfile(ravi);
      expect(app.engine.totalSums, 10);
      expect(ravi.coins, greaterThan(0));
    });

    test('settings persist', () {
      app.setLanguage('en');
      app.setSound(false);
      final again = AppState(store: app.store, audio: SilentAudioService(), notifications: NoopNotificationService());
      expect(again.lang, 'en');
      expect(again.soundOn, isFalse);
      expect(again.active!.name, 'Asha');
    });
  });
}

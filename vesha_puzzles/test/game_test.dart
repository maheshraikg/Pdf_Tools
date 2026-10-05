import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesha_puzzles/app/scope.dart';
import 'package:vesha_puzzles/app/storage.dart';
import 'package:vesha_puzzles/game/achievements.dart';
import 'package:vesha_puzzles/game/audio.dart';
import 'package:vesha_puzzles/game/daily.dart';
import 'package:vesha_puzzles/game/progress.dart';
import 'package:vesha_puzzles/game/saves.dart';
import 'package:vesha_puzzles/jigsaw/board.dart';
import 'package:vesha_puzzles/jigsaw/cut.dart';
import 'package:vesha_puzzles/monetization/ads.dart';
import 'package:vesha_puzzles/packs/content.dart';
import 'package:vesha_puzzles/packs/loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Content content;
  setUpAll(() async => content = await ContentLoader(rootBundle).load());

  AppState app(DateTime now, [MemoryStore? store]) => AppState(
    store: store ?? MemoryStore(),
    content: content,
    audio: AudioService(enabled: false),
    clock: () => now,
  );

  Completion done(
    String id, {
    int hints = 0,
    Difficulty d = Difficulty.medium,
    int ms = 400000,
    DateTime? when,
    bool daily = false,
  }) => Completion(
    puzzleId: id,
    difficulty: d,
    ms: ms,
    hints: hints,
    when: when ?? DateTime(2026, 10, 5),
    daily: daily,
  );

  group('progress', () {
    test('stars from hints', () {
      expect(starsFor(hints: 0), 3);
      expect(starsFor(hints: 2), 2);
      expect(starsFor(hints: 3), 1);
    });

    test('best time and stars per difficulty', () {
      final p = Progress();
      expect(p.record(done('a', ms: 5000, hints: 3)), isTrue);
      expect(p.record(done('a', ms: 7000, hints: 0)), isFalse);
      expect(p.records['a']!.bestMs['medium'], 5000);
      expect(p.records['a']!.stars['medium'], 3);
      expect(p.records['a']!.completions, 2);
      expect(p.noHintFinishes, 1);
    });

    test('daily streak counts back from today or yesterday', () {
      final p = Progress()
        ..dailyDone.addAll(['20261001', '20261002', '20261003', '20260920']);
      expect(p.dailyStreak(DateTime(2026, 10, 3)), 3);
      expect(p.dailyStreak(DateTime(2026, 10, 4)), 3); // today not played yet
      expect(p.dailyStreak(DateTime(2026, 10, 5)), 0);
      expect(p.bestDailyStreak(), 3);
    });

    test('streak crosses month and year ends', () {
      final p = Progress()..dailyDone.addAll(['20261231', '20270101']);
      expect(p.dailyStreak(DateTime(2027, 1, 1)), 2);
    });

    test('json round trip', () {
      final p = Progress()
        ..record(done('a', hints: 1))
        ..storiesRead.add('a')
        ..achievements['first_puzzle'] = '20261005'
        ..looksSaved = 2;
      final q = Progress.fromJson(p.toJson());
      expect(q.records['a']!.stars['medium'], 2);
      expect(q.storiesRead, {'a'});
      expect(q.achievements, {'first_puzzle': '20261005'});
      expect(q.looksSaved, 2);
    });
  });

  group('daily', () {
    test('same date gives same pick; cycles through every puzzle', () {
      final a = dailyFor(DateTime(2026, 10, 5, 8), content.allPuzzles)!;
      final b = dailyFor(DateTime(2026, 10, 5, 23), content.allPuzzles)!;
      expect(a.puzzle.id, b.puzzle.id);
      expect(a.seed, 20261005);
      final n = content.allPuzzles.length;
      final seen = {
        for (var i = 0; i < n; i++)
          dailyFor(DateTime(2026, 1, 1 + i), content.allPuzzles)!.puzzle.id,
      };
      expect(seen.length, n);
    });

    test('difficulty by weekday', () {
      expect(
        dailyDifficulty(DateTime(2026, 10, 5)),
        Difficulty.medium,
      ); // Monday
      expect(dailyDifficulty(DateTime(2026, 10, 9)), Difficulty.hard); // Friday
      expect(
        dailyDifficulty(DateTime(2026, 10, 11)),
        Difficulty.easy,
      ); // Sunday
    });
  });

  group('achievements & app state', () {
    test('first completion unlocks first_puzzle and no_hints once', () {
      final s = app(DateTime(2026, 10, 5));
      final r = s.complete(done('y01_raja_vesha'));
      expect(r.achievements, containsAll(['first_puzzle', 'no_hints']));
      expect(
        s.complete(done('y01_raja_vesha')).achievements,
        isNot(contains('first_puzzle')),
      );
    });

    test('finishing a whole pack unlocks the pack achievement', () {
      final s = app(DateTime(2026, 10, 5));
      final ids = content.pack('karavali')!.puzzles.map((p) => p.id).toList();
      List<String> last = [];
      for (final id in ids) {
        last = s.complete(done(id, hints: 4)).achievements;
      }
      expect(last, contains('pack_karavali'));
      expect(s.progress.achievements, isNot(contains('no_hints')));
    });

    test('event badge only for featured puzzles during the event', () {
      final s = app(DateTime(2026, 10, 15));
      expect(s.eventsFeaturing('c01_pili_vesha'), ['navaratri_pili']);
      expect(s.eventsFeaturing('c04_mallige'), isEmpty);
      final r = s.complete(
        Completion(
          puzzleId: 'c01_pili_vesha',
          difficulty: Difficulty.easy,
          ms: 1000,
          hints: 0,
          when: DateTime(2026, 10, 15),
          eventIds: s.eventsFeaturing('c01_pili_vesha'),
        ),
      );
      expect(r.achievements, contains('event_badge'));
      expect(
        app(DateTime(2026, 11, 1)).eventsFeaturing('c01_pili_vesha'),
        isEmpty,
      );
    });

    test('unlocking: first three free, then sequential', () {
      final s = app(DateTime(2026, 10, 5));
      final y = content.pack('yakshagana')!.puzzles;
      expect(s.isUnlocked(y[2]), isTrue);
      expect(s.isUnlocked(y[3]), isFalse);
      s.complete(done(y[2].id));
      expect(s.isUnlocked(y[3]), isTrue);
      expect(s.isUnlocked(y[4]), isFalse);
    });

    test('progress and settings persist through the store', () {
      final store = MemoryStore();
      final s = app(DateTime(2026, 10, 5), store)
        ..complete(done('y01_raja_vesha'));
      s.updateSettings((x) => x.sfx = false);
      final t = app(DateTime(2026, 10, 6), store);
      expect(t.progress.completed('y01_raja_vesha'), isTrue);
      expect(t.settings.sfx, isFalse);
    });

    test('reset keeps settings', () async {
      final store = MemoryStore();
      final s = app(DateTime(2026, 10, 5), store)
        ..complete(done('y01_raja_vesha'));
      s.updateSettings((x) => x.music = true);
      await s.resetProgress();
      final t = app(DateTime(2026, 10, 5), store);
      expect(t.progress.totalCompletions, 0);
      expect(t.settings.music, isTrue);
    });

    test('achievement list ids are unique', () {
      final ids = achievementsFor(content).map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('saves', () {
    test('save, load, fraction, delete, daily prune', () async {
      final store = MemoryStore();
      final saves = SaveStore(store);
      final b = JigsawBoard(cut: JigsawCut.generate(2, 2, 1), cellH: 100)
        ..placePiece(0);
      await saves.save(
        SavedGame(
          key: 'p',
          puzzleId: 'p',
          difficulty: Difficulty.hard,
          board: b.toJson(),
          elapsedMs: 1234,
          hints: 1,
          moves: 3,
          savedAt: DateTime(2026),
        ),
      );
      await saves.save(
        SavedGame(
          key: 'daily-20261001',
          puzzleId: 'p',
          difficulty: Difficulty.easy,
          board: b.toJson(),
          elapsedMs: 1,
          hints: 0,
          moves: 0,
          savedAt: DateTime(2026),
        ),
      );
      final g = saves.load('p')!;
      expect(g.difficulty, Difficulty.hard);
      expect(g.elapsedMs, 1234);
      expect(g.fraction, 0.25);
      await saves.pruneDaily('20261005');
      expect(saves.has('daily-20261001'), isFalse);
      expect(saves.has('p'), isTrue);
      await saves.delete('p');
      expect(saves.load('p'), isNull);
    });

    test('corrupt save is ignored', () async {
      final store = MemoryStore()..data['save.x'] = '{not json';
      expect(SaveStore(store).load('x'), isNull);
    });
  });

  test('ads policy: off by default build flag', () {
    expect(
      shouldShowInterstitial(
        completionsSoFar: 3,
        supporter: false,
        daysSinceInstall: 5,
      ),
      isFalse,
    );
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/curriculum.dart';
import 'package:ganita_aata/data/progress_store.dart';
import 'package:ganita_aata/engine/adaptive_engine.dart';
import 'package:ganita_aata/models/question.dart';

void main() {
  late MemoryProgressStore store;
  late DateTime now;

  AdaptiveEngine engine({Set<String>? unlocked, int seed = 1}) => AdaptiveEngine(
    profileId: 'p1',
    store: store,
    unlocked: unlocked ?? {'tab6_10'},
    random: Random(seed),
    clock: () => now,
  );

  final q78 = Question.fromParts('tab6_10', Op.mul, 7, 8);

  setUp(() {
    store = MemoryProgressStore();
    now = DateTime(2026, 11, 9, 10);
  });

  group('mastery', () {
    test('3 fast correct answers in a row master a fact', () {
      final e = engine();
      expect(e.record(q78, true, 3000).newlyMastered, isFalse);
      expect(e.record(q78, true, 5000).newlyMastered, isFalse);
      expect(e.isMastered(q78.factKey), isFalse);
      expect(e.record(q78, true, 4000).newlyMastered, isTrue);
      expect(e.isMastered(q78.factKey), isTrue);
    });

    test('a slow correct answer restarts the run', () {
      final e = engine();
      e.record(q78, true, 2000);
      e.record(q78, true, 2000);
      e.record(q78, true, 5001); // too slow
      expect(e.isMastered(q78.factKey), isFalse);
      e.record(q78, true, 2000);
      e.record(q78, true, 2000);
      expect(e.isMastered(q78.factKey), isFalse);
      e.record(q78, true, 2000);
      expect(e.isMastered(q78.factKey), isTrue);
    });

    test('a wrong answer breaks the run and removes mastery', () {
      final e = engine();
      e.record(q78, true, 1000);
      e.record(q78, true, 1000);
      e.record(q78, false, 1000);
      e.record(q78, true, 1000);
      expect(e.isMastered(q78.factKey), isFalse);
      e.record(q78, true, 1000);
      e.record(q78, true, 1000);
      expect(e.isMastered(q78.factKey), isTrue);
      e.record(q78, false, 1000);
      expect(e.isMastered(q78.factKey), isFalse);
    });

    test('mastery and stats are saved and reloaded', () {
      final e = engine();
      for (var i = 0; i < 3; i++) {
        e.record(q78, true, 1000);
      }
      final again = engine();
      expect(again.isMastered(q78.factKey), isTrue);
      expect(again.facts[q78.factKey]!.attempts, 3);
      expect(again.sumsOn(now), 3);
      expect(store.log['p1']!.length, 3);
    });

    test('a table is mastered when all 10 lines are', () {
      final e = engine();
      for (var b = 1; b <= 10; b++) {
        expect(e.isTableMastered(7), isFalse);
        for (var i = 0; i < 3; i++) {
          e.record(Question.fromParts('tab6_10', Op.mul, 7, b), true, 1500);
        }
      }
      expect(e.isTableMastered(7), isTrue);
      expect(e.isTableMastered(8), isFalse);
    });
  });

  group('selection', () {
    test('weak facts appear more often; mastered facts still appear', () {
      final e = engine(seed: 42);
      final q76 = Question.fromParts('tab6_10', Op.mul, 7, 6);
      // Master every fact in the topic except 7 × 8 and 7 × 6.
      for (var t = 6; t <= 10; t++) {
        for (var b = 1; b <= 10; b++) {
          final q = Question.fromParts('tab6_10', Op.mul, t, b);
          if (q.factKey == q78.factKey || q.factKey == q76.factKey) continue;
          for (var i = 0; i < 3; i++) {
            e.record(q, true, 1000);
          }
        }
      }
      e.record(q78, false, 8000);
      e.record(q78, false, 8000);
      e.record(q76, false, 8000);
      e.record(q76, false, 8000);

      final counts = <String, int>{};
      const n = 6000;
      for (var i = 0; i < n; i++) {
        final q = e.next('tab6_10');
        counts[q.factKey] = (counts[q.factKey] ?? 0) + 1;
      }
      final weak = (counts[q78.factKey] ?? 0);
      final mastered = counts.entries
          .where((x) => x.key != q78.factKey && x.key != q76.factKey)
          .map((x) => x.value)
          .toList();
      final avgMastered = mastered.reduce((a, b) => a + b) / mastered.length;
      expect(weak, greaterThan(avgMastered * 5), reason: 'weak=$weak avgMastered=$avgMastered');
      // Every mastered fact is still asked now and then for revision.
      expect(mastered.length, 48);
      expect(mastered.every((c) => c > 0), isTrue);
    });

    test('weight ordering: wrong > unseen > learning > mastered', () {
      expect(AdaptiveEngine.weight(null), 2.0);
      final e = engine();
      e.record(q78, false, 1000);
      final wrong = AdaptiveEngine.weight(e.facts[q78.factKey]);
      final q2 = Question.fromParts('tab6_10', Op.mul, 6, 2);
      for (var i = 0; i < 3; i++) {
        e.record(q2, true, 1000);
      }
      final mastered = AdaptiveEngine.weight(e.facts[q2.factKey]);
      expect(wrong, greaterThan(2.0));
      expect(mastered, lessThan(1.0));
      expect(mastered, greaterThan(0));
    });

    test('does not ask the same fact twice in a row', () {
      final e = engine();
      String? last;
      for (var i = 0; i < 500; i++) {
        final q = e.next('squares');
        expect(q.factKey, isNot(last));
        last = q.factKey;
      }
    });

    test('open-ended topics re-ask wrongly answered sums', () {
      final e = engine(unlocked: {'add3'});
      final hard = Question.fromParts('add3', Op.add, 478, 365);
      e.record(hard, false, 9000);
      var seen = 0;
      for (var i = 0; i < 400; i++) {
        if (e.next('add3').factKey == hard.factKey) seen++;
      }
      expect(seen, greaterThan(40)); // ~30% of the time, minus no-repeat.
    });

    test('weak facts list is weakest first and excludes mastered', () {
      final e = engine();
      final q2 = Question.fromParts('tab6_10', Op.mul, 6, 2);
      e.record(q78, false, 1000);
      e.record(q78, false, 1000);
      e.record(q2, false, 1000);
      e.record(q2, true, 1000);
      e.record(q2, false, 1000);
      final weak = e.weakFacts();
      expect(weak.map((f) => f.key), [q78.factKey, q2.factKey]);
      for (var i = 0; i < 3; i++) {
        e.record(q78, true, 1000);
      }
      expect(e.weakFacts().map((f) => f.key), [q2.factKey]);
    });
  });

  group('unlocking', () {
    test('above 85% over the last 30 unlocks the next topic', () {
      final unlocked = {'tab6_10'};
      final e = engine(unlocked: unlocked);
      String? got;
      // 26/30 = 86.7% correct.
      for (var i = 0; i < 30; i++) {
        final o = e.record(e.next('tab6_10'), i % 8 != 0 || i == 0 ? true : false, 2000);
        if (o.unlockedTopic != null) got = o.unlockedTopic;
      }
      expect(got, Curriculum.nextTopic('tab6_10')!.id);
      expect(unlocked, contains('add3'));
    });

    test('needs a full window of 30 answers', () {
      final unlocked = {'tab6_10'};
      final e = engine(unlocked: unlocked);
      for (var i = 0; i < 29; i++) {
        expect(e.record(e.next('tab6_10'), true, 1000).unlockedTopic, isNull);
      }
      expect(unlocked, {'tab6_10'});
      expect(e.record(e.next('tab6_10'), true, 1000).unlockedTopic, 'add3');
    });

    test('85% exactly or lower does not unlock', () {
      final unlocked = {'tab6_10'};
      final e = engine(unlocked: unlocked);
      // 25/30 = 83%.
      for (var i = 0; i < 60; i++) {
        e.record(e.next('tab6_10'), i % 6 != 0, 1000);
      }
      expect(unlocked, {'tab6_10'});
    });

    test('a locked topic does not unlock the next one', () {
      final unlocked = <String>{'num100'};
      final e = engine(unlocked: unlocked);
      for (var i = 0; i < 40; i++) {
        e.record(e.next('tab6_10'), true, 1000);
      }
      expect(unlocked, {'num100'});
    });

    test('last topic unlocks nothing', () {
      final last = Curriculum.topics.last.id;
      final e = engine(unlocked: {last});
      for (var i = 0; i < 40; i++) {
        expect(e.record(e.next(last), true, 1000).unlockedTopic, isNull);
      }
    });
  });

  test('daily totals and reset', () async {
    final e = engine();
    e.record(q78, true, 2000);
    now = now.add(const Duration(days: 1));
    e.record(q78, false, 4000);
    expect(e.days.length, 2);
    expect(e.totalSums, 2);
    expect(e.totalCorrect, 1);
    await e.reset();
    expect(engine().totalSums, 0);
  });

  test('initial unlocks follow the class', () {
    expect(Curriculum.initialUnlocked(1), {'num100'});
    expect(Curriculum.initialUnlocked(4), {'num100', 'add1', 'sub1', 'add2', 'sub2', 'tab2_5', 'tab6_10'});
    expect(Curriculum.initialUnlocked(8).contains('mixed'), isTrue);
    expect(Curriculum.levelForClass(7), 5);
  });
}

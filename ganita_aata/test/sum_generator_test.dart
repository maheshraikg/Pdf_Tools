import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/curriculum.dart';
import 'package:ganita_aata/engine/sum_generator.dart';
import 'package:ganita_aata/models/question.dart';

void main() {
  const samples = 3000;

  group('answers', () {
    for (final topic in Curriculum.topics) {
      test('${topic.id}: never negative and arithmetically correct', () {
        final gen = SumGenerator(Random(topic.id.hashCode));
        for (var i = 0; i < samples; i++) {
          final q = gen.generate(topic.id);
          expect(q.answer.isNegative, isFalse, reason: '$q');
          expect(q.a, greaterThanOrEqualTo(0));
          expect(q.topicId, topic.id);
          // Rebuilding from the fact key gives the same sum.
          expect(Question.fromKey(topic.id, q.factKey)!.answer, q.answer);
        }
      });
    }

    test('no negative answers in Levels 1–3 (including all listed facts)', () {
      for (final t in Curriculum.topics.where((t) => t.level <= 3)) {
        for (final q in SumGenerator.allFacts(t.id) ?? const <Question>[]) {
          expect(q.answer.value, greaterThanOrEqualTo(0), reason: '$q');
        }
      }
    });

    test('division divides exactly except in division with remainder', () {
      final gen = SumGenerator(Random(7));
      for (final t in Curriculum.topics) {
        for (var i = 0; i < samples; i++) {
          final q = gen.generate(t.id);
          if (q.op == Op.div) {
            expect(q.a % q.b, 0, reason: '$q');
            expect(t.id, isNot('divRem'));
          }
          if (q.op == Op.divRem) {
            expect(t.id, 'divRem');
            expect(q.answer.remainder, inInclusiveRange(1, q.b - 1));
            expect(q.answer.value * q.b + q.answer.remainder!, q.a);
          }
          if (q.op == Op.fracOf) expect(q.c % q.b, 0, reason: '$q');
          if (q.op == Op.percent) expect(q.a * q.b % 100, 0, reason: '$q');
        }
      }
    });

    test('levels follow the syllabus ranges', () {
      final gen = SumGenerator(Random(3));
      for (var i = 0; i < samples; i++) {
        final a1 = gen.generate('add1');
        expect([a1.a, a1.b].every((n) => n >= 1 && n <= 9), isTrue);
        final s1 = gen.generate('sub1');
        expect(s1.b, inInclusiveRange(1, 9));
        expect(s1.answer.value, inInclusiveRange(0, 9));
        final n = gen.generate('num100');
        expect(n.answer.value, inInclusiveRange(0, 100));
        final t = gen.generate('tab2_5');
        expect(t.a, inInclusiveRange(2, 5));
        expect(t.b, inInclusiveRange(1, 10));
        final t3 = gen.generate('tab11_20');
        expect(t3.a, inInclusiveRange(11, 20));
        final m = gen.generate('mul21');
        expect(m.a, inInclusiveRange(10, 99));
        expect(m.b, inInclusiveRange(1, 9));
        expect(gen.generate('squares').a, inInclusiveRange(1, 30));
        expect(gen.generate('cubes').a, inInclusiveRange(1, 15));
        final a3 = gen.generate('add3');
        expect([a3.a, a3.b].every((n) => n >= 100 && n <= 999), isTrue);
      }
    });
  });

  group('multiple-choice options', () {
    for (final topic in Curriculum.topics) {
      test('${topic.id}: 4 unique options, one correct, none negative', () {
        final gen = SumGenerator(Random(topic.id.length * 31));
        for (var i = 0; i < samples; i++) {
          final q = gen.generate(topic.id);
          final opts = gen.options(q);
          expect(opts.length, 4);
          expect(opts.toSet().length, 4, reason: '$q → $opts');
          expect(opts.where((o) => o == q.answer).length, 1);
          expect(opts.any((o) => o.isNegative), isFalse, reason: '$q → $opts');
          if (q.op == Op.divRem) {
            expect(opts.every((o) => o.remainder != null && o.remainder! < q.b), isTrue);
          }
        }
      });
    }

    test('wrong options are close to the answer', () {
      final gen = SumGenerator(Random(11));
      for (var i = 0; i < samples; i++) {
        final q = gen.generate('add2');
        for (final w in gen.wrongOptions(q)) {
          expect((w.value - q.answer.value).abs(), lessThanOrEqualTo(10), reason: '$q → $w');
        }
        final t = gen.generate('tab6_10');
        for (final w in gen.wrongOptions(t)) {
          // A neighbouring table value or within 10.
          expect((w.value - t.answer.value).abs(), lessThanOrEqualTo(max(10, max(t.a, t.b))), reason: '$t → $w');
        }
      }
    });

    test('options for answer 0 and 1 stay non-negative and unique', () {
      final gen = SumGenerator(Random(1));
      for (final q in [
        Question.fromParts('sub1', Op.sub, 5, 5),
        Question.fromParts('sub1', Op.sub, 1, 0),
        Question.fromParts('num100', Op.before, 1),
        Question.fromParts('divRem', Op.divRem, 3, 2),
      ]) {
        final w = gen.wrongOptions(q);
        expect(w.length, 3);
        expect(w.toSet().length, 3);
        expect(w.any((a) => a.isNegative || a == q.answer), isFalse, reason: '$q → $w');
      }
    });
  });

  group('daily challenge', () {
    test('same 10 sums for the same day and level', () {
      final d = DateTime(2026, 11, 9);
      final a = SumGenerator.dailyChallenge(d, 3).map((q) => q.factKey).toList();
      final b = SumGenerator.dailyChallenge(DateTime(2026, 11, 9, 18, 30), 3).map((q) => q.factKey).toList();
      expect(a.length, 10);
      expect(a, b);
      expect(a.toSet().length, 10);
    });

    test('differs between days and levels', () {
      final d = DateTime(2026, 11, 9);
      final a = SumGenerator.dailyChallenge(d, 2).map((q) => q.factKey).toList();
      expect(SumGenerator.dailyChallenge(d.add(const Duration(days: 1)), 2).map((q) => q.factKey).toList(), isNot(a));
      expect(SumGenerator.dailyChallenge(d, 4).map((q) => q.factKey).toList(), isNot(a));
    });

    test('uses only topics of its level', () {
      for (var lvl = 1; lvl <= 5; lvl++) {
        final ids = Curriculum.level(lvl).topics.map((t) => t.id).toSet();
        for (final q in SumGenerator.dailyChallenge(DateTime(2027, 1, 1), lvl)) {
          expect(ids.contains(q.topicId), isTrue);
        }
      }
    });
  });

  test('every topic of a table level lists 10 lines per table', () {
    expect(SumGenerator.allFacts('tab2_5')!.length, 40);
    expect(SumGenerator.allFacts('tab11_20')!.length, 100);
    expect(SumGenerator.allFacts('add3'), isNull);
  });
}

import 'dart:math';

import '../data/curriculum.dart';
import '../models/question.dart';
import '../models/topic.dart';

/// Makes sums for every topic on the fly; there is no fixed question bank.
///
/// Rules (see test/sum_generator_test.dart):
/// * answers are never negative (Levels 1–3 by design, and every other level
///   too);
/// * division divides exactly, except in the "division with remainder" topic;
/// * multiple-choice options are 3 believable wrong answers, all different
///   from each other and from the correct answer.
class SumGenerator {
  SumGenerator([Random? random]) : _rng = random ?? Random();

  final Random _rng;

  int _r(int min, int max) => min + _rng.nextInt(max - min + 1);
  T _pick<T>(List<T> list) => list[_rng.nextInt(list.length)];

  /// A fresh random question for [topicId].
  Question generate(String topicId) {
    final topic = Curriculum.topic(topicId);
    final id = topic.id;
    switch (id) {
      case 'num100':
        switch (_rng.nextInt(4)) {
          case 0:
            return Question.fromParts(id, Op.after, _r(0, 99));
          case 1:
            return Question.fromParts(id, Op.before, _r(1, 100));
          case 2:
            return Question.fromParts(id, Op.tenMore, _r(0, 90));
          default:
            return Question.fromParts(id, Op.tenLess, _r(10, 100));
        }
      case 'add1':
        return Question.fromParts(id, Op.add, _r(1, 9), _r(1, 9));
      case 'sub1':
        final b = _r(1, 9);
        return Question.fromParts(id, Op.sub, b + _r(0, 9), b);
      case 'add2':
        return Question.fromParts(id, Op.add, _r(10, 99), _r(10, 99));
      case 'sub2':
        final a = _r(10, 99);
        return Question.fromParts(id, Op.sub, a, _r(10, a));
      case 'add3':
        return Question.fromParts(id, Op.add, _r(100, 899), _r(100, 899));
      case 'sub3':
        final a = _r(100, 999);
        return Question.fromParts(id, Op.sub, a, _r(100, a));
      case 'div1':
        final d = _r(2, 10);
        return Question.fromParts(id, Op.div, d * _r(1, 10), d);
      case 'mul21':
        return Question.fromParts(id, Op.mul, _r(11, 99), _r(2, 9));
      case 'divRem':
        final d = _r(2, 9);
        return Question.fromParts(id, Op.divRem, d * _r(1, 12) + _r(1, d - 1), d);
      case 'mixed':
        return _mixed(id);
      case 'squares':
        return Question.fromParts(id, Op.square, _r(1, 30));
      case 'cubes':
        return Question.fromParts(id, Op.cube, _r(1, 15));
      case 'percent':
        final p = _pick(const [5, 10, 20, 25, 30, 40, 50, 60, 75, 80, 90]);
        final step = 100 ~/ _gcd(p, 100);
        return Question.fromParts(id, Op.percent, p, step * _r(1, max(1, 400 ~/ step)));
      case 'fractions':
        if (_rng.nextBool()) {
          final den = _r(2, 10);
          return Question.fromParts(id, Op.fracOf, _r(1, den - 1), den, den * _r(1, 10));
        }
        final den = _r(3, 12);
        final a = _r(1, den - 2);
        return Question.fromParts(id, Op.fracAdd, a, _r(1, den - 1 - a), den);
      default:
        // Table topics.
        if (topic.isTables) {
          return Question.fromParts(id, Op.mul, _pick(topic.tables!), _r(1, 10));
        }
        return Question.fromParts(id, Op.add, _r(1, 9), _r(1, 9));
    }
  }

  Question _mixed(String id) {
    switch (_rng.nextInt(6)) {
      case 0:
        return Question.fromParts(id, Op.add, _r(10, 999), _r(10, 999));
      case 1:
        final a = _r(50, 999);
        return Question.fromParts(id, Op.sub, a, _r(10, a));
      case 2:
        return Question.fromParts(id, Op.mul, _r(2, 25), _r(2, 12));
      case 3:
        final d = _r(2, 12);
        return Question.fromParts(id, Op.div, d * _r(2, 15), d);
      case 4:
        return Question.fromParts(id, Op.addMul, _r(1, 20), _r(2, 9), _r(2, 9));
      default:
        final a = _r(2, 9), b = _r(2, 9);
        return Question.fromParts(id, Op.mulSub, a, b, _r(1, a * b));
    }
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  /// Every fact in a topic, when the topic is small enough to list (tables,
  /// single-digit sums, squares…). Null for open-ended topics such as 3-digit
  /// addition, where questions are generated fresh each time.
  static List<Question>? allFacts(String topicId) {
    final Topic topic = Curriculum.topic(topicId);
    final id = topic.id;
    if (topic.isTables) {
      return [
        for (final t in topic.tables!)
          for (var b = 1; b <= 10; b++) Question.fromParts(id, Op.mul, t, b),
      ];
    }
    switch (id) {
      case 'add1':
        return [
          for (var a = 1; a <= 9; a++)
            for (var b = 1; b <= 9; b++) Question.fromParts(id, Op.add, a, b),
        ];
      case 'sub1':
        return [
          for (var b = 1; b <= 9; b++)
            for (var d = 0; d <= 9; d++) Question.fromParts(id, Op.sub, b + d, b),
        ];
      case 'div1':
        return [
          for (var d = 2; d <= 10; d++)
            for (var q = 1; q <= 10; q++) Question.fromParts(id, Op.div, d * q, d),
        ];
      case 'squares':
        return [for (var a = 1; a <= 30; a++) Question.fromParts(id, Op.square, a)];
      case 'cubes':
        return [for (var a = 1; a <= 15; a++) Question.fromParts(id, Op.cube, a)];
      default:
        return null;
    }
  }

  /// Four shuffled choices: the correct answer and 3 close wrong answers.
  List<Answer> options(Question q) {
    final wrong = wrongOptions(q);
    final all = [q.answer, ...wrong]..shuffle(_rng);
    return all;
  }

  /// Exactly 3 distinct, non-negative wrong answers close to the right one.
  List<Answer> wrongOptions(Question q) {
    final correct = q.answer;
    final picked = <Answer>[];
    void tryAdd(Answer a) {
      if (picked.length >= 3 || a.isNegative || a == correct || picked.contains(a)) return;
      if (q.op == Op.divRem && (a.remainder! >= q.b)) return;
      picked.add(a);
    }

    final v = correct.value;
    if (q.op == Op.divRem) {
      final r = correct.remainder!;
      final cands = [
        Answer(v, r + 1),
        Answer(v, r - 1),
        Answer(v + 1, r),
        Answer(v - 1, r),
        Answer(v + 1, 0),
        Answer(v, 0),
        Answer(v, q.b - 1),
        Answer(v + 2, r),
      ]..shuffle(_rng);
      cands.forEach(tryAdd);
      for (var k = 1; picked.length < 3; k++) {
        tryAdd(Answer(v + k, r));
      }
      return picked;
    }

    final cands = <int>[];
    switch (q.op) {
      case Op.mul:
        cands.addAll([(q.a + 1) * q.b, (q.a - 1) * q.b, q.a * (q.b + 1), q.a * (q.b - 1), v + 10, v - 10]);
      case Op.square:
        cands.addAll([(q.a + 1) * (q.a + 1), (q.a - 1) * (q.a - 1), q.a * 2, v + 10, v - 10]);
      case Op.cube:
        cands.addAll([(q.a + 1) * (q.a + 1) * (q.a + 1), (q.a - 1) * (q.a - 1) * (q.a - 1), q.a * q.a, q.a * 3]);
      case Op.div:
        cands.addAll([v + 1, v - 1, v + 2, q.b]);
      case Op.add:
      case Op.sub:
        cands.addAll([v + 1, v - 1, v + 10, v - 10, v + 2, v - 2]);
      case Op.percent:
        final tenth = max(1, q.b ~/ 10);
        cands.addAll([v + tenth, v - tenth, v * 2, v + 5, v - 5, q.b - v]);
      case Op.fracOf:
        cands.addAll([q.c ~/ q.b, v + q.c ~/ q.b, v - q.c ~/ q.b, v + 1, v - 1]);
      case Op.addMul:
        cands.addAll([(q.a + q.b) * q.c, v + q.c, v - q.c, v + 1, v - 1]);
      case Op.mulSub:
        cands.addAll([q.a * (q.b - q.c), v + 1, v - 1, v + q.a, v - q.a]);
      default:
        cands.addAll([v + 1, v - 1, v + 2, v - 2, v + 10, v - 10]);
    }
    cands.shuffle(_rng);
    for (final c in cands) {
      tryAdd(Answer(c));
    }
    // Fallback: nearest unused numbers, alternating above and below.
    for (var k = 1; picked.length < 3; k++) {
      tryAdd(Answer(v + k));
      tryAdd(Answer(v - k));
    }
    return picked;
  }

  /// The 10 Daily Challenge sums: the same for everyone at [level] on [day].
  static List<Question> dailyChallenge(DateTime day, int level, {int count = 10}) {
    final seed = (day.year * 10000 + day.month * 100 + day.day) * 10 + level;
    final gen = SumGenerator(Random(seed));
    final topics = Curriculum.level(level).topics;
    final out = <Question>[];
    final seen = <String>{};
    var guard = 0;
    while (out.length < count && guard++ < 500) {
      final q = gen.generate(topics[out.length % topics.length].id);
      if (seen.add(q.factKey)) out.add(q);
    }
    return out;
  }
}

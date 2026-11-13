import 'dart:math';

import '../data/curriculum.dart';
import '../data/progress_store.dart';
import '../models/question.dart';
import '../models/stats.dart';
import 'sum_generator.dart';

/// What changed after one answer.
class AnswerOutcome {
  const AnswerOutcome({this.newlyMastered = false, this.unlockedTopic});

  final bool newlyMastered;

  /// Id of a topic unlocked by this answer, if any.
  final String? unlockedTopic;
}

/// Tracks every answer and decides what to ask next.
///
/// * Each maths fact has a [FactStat]. A fact is *mastered* after
///   [masteryStreak] correct answers in a row, each within [fastAnswerMs].
///   A wrong answer removes mastery; a slow correct answer restarts the run.
/// * [next] picks facts by weighted random: weak facts are picked more,
///   unseen facts normally, mastered facts rarely (for revision).
/// * When accuracy on an unlocked topic is above [unlockAccuracy] over its
///   last [TopicStat.window] answers, the next topic is unlocked.
class AdaptiveEngine {
  AdaptiveEngine({
    required this.profileId,
    required this.store,
    required this.unlocked,
    Random? random,
    DateTime Function()? clock,
  }) : _rng = random ?? Random(),
       _clock = clock ?? DateTime.now {
    _gen = SumGenerator(_rng);
    facts = store.loadFacts(profileId);
    topics = store.loadTopics(profileId);
    days = store.loadDays(profileId);
  }

  static const fastAnswerMs = 5000;
  static const masteryStreak = 3;
  static const unlockAccuracy = 0.85;

  /// Chance of re-asking a weak fact in open-ended topics.
  static const weakRepeatChance = 0.3;

  /// Chance of a mastered fact as revision in open-ended topics.
  static const revisionChance = 0.05;

  final String profileId;
  final ProgressStore store;

  /// The child's unlocked topic ids. Shared with the profile; the caller
  /// saves the profile when [AnswerOutcome.unlockedTopic] is set.
  final Set<String> unlocked;

  final Random _rng;
  final DateTime Function() _clock;
  late final SumGenerator _gen;

  late final Map<String, FactStat> facts;
  late final Map<String, TopicStat> topics;
  late final Map<String, DayStat> days;

  String? _lastKey;

  SumGenerator get generator => _gen;

  /// Records one answer and updates mastery, topic and daily statistics.
  AnswerOutcome record(Question q, bool correct, int timeMs) {
    final now = _clock();
    final f = facts[q.factKey] ??= FactStat(key: q.factKey, topicId: q.topicId);
    final wasMastered = f.mastered;
    f.attempts++;
    f.totalTimeMs += timeMs;
    f.lastSeenMs = now.millisecondsSinceEpoch;
    f.lastCorrect = correct;
    if (correct) {
      f.correct++;
      if (timeMs <= fastAnswerMs) {
        f.streak++;
        if (f.streak >= masteryStreak) f.mastered = true;
      } else {
        f.streak = 0;
      }
    } else {
      f.streak = 0;
      f.mastered = false;
    }
    store.saveFact(profileId, f);

    final t = topics[q.topicId] ??= TopicStat(topicId: q.topicId);
    t.add(correct, timeMs);
    store.saveTopic(profileId, t);

    final dk = dayKey(now);
    final d = days[dk] ??= DayStat(date: dk);
    d.sums++;
    if (correct) d.correct++;
    d.totalTimeMs += timeMs;
    store.saveDay(profileId, d);

    store.appendLog(
      profileId,
      AnswerRecord(
        factKey: q.factKey,
        topicId: q.topicId,
        expression: q.expression,
        correct: correct,
        timeMs: timeMs,
        at: now,
      ),
    );

    return AnswerOutcome(newlyMastered: !wasMastered && f.mastered, unlockedTopic: _checkUnlock(t));
  }

  String? _checkUnlock(TopicStat t) {
    if (!unlocked.contains(t.topicId)) return null;
    if (t.recent.length < TopicStat.window || t.recentAccuracy <= unlockAccuracy) return null;
    final next = Curriculum.nextTopic(t.topicId);
    if (next == null || unlocked.contains(next.id)) return null;
    unlocked.add(next.id);
    return next.id;
  }

  /// Selection weight of a fact: higher means asked more often.
  static double weight(FactStat? f) {
    if (f == null || f.attempts == 0) return 2.0; // not seen yet
    if (f.mastered) return 0.3; // still revised now and then
    var w = 1.0 + 3.0 * (1 - f.accuracy);
    if (!f.lastCorrect) w += 2.0;
    w -= 0.25 * f.streak;
    return max(0.5, w);
  }

  /// The next question for [topicId].
  Question next(String topicId) {
    final all = SumGenerator.allFacts(topicId);
    final Question q;
    if (all != null) {
      q = _weightedPick(all);
    } else {
      q = _openEnded(topicId);
    }
    _lastKey = q.factKey;
    return q;
  }

  Question _weightedPick(List<Question> all) {
    final pool = all.length > 1 ? all.where((q) => q.factKey != _lastKey).toList() : all;
    final weights = [for (final q in pool) weight(facts[q.factKey])];
    final total = weights.fold<double>(0, (a, b) => a + b);
    var x = _rng.nextDouble() * total;
    for (var i = 0; i < pool.length; i++) {
      x -= weights[i];
      if (x <= 0) return pool[i];
    }
    return pool.last;
  }

  Question _openEnded(String topicId) {
    final mine = facts.values.where((f) => f.topicId == topicId && f.key != _lastKey);
    final roll = _rng.nextDouble();
    if (roll < weakRepeatChance) {
      final weak = mine.where((f) => !f.mastered && !f.lastCorrect).toList();
      if (weak.isNotEmpty) {
        final q = Question.fromKey(topicId, weak[_rng.nextInt(weak.length)].key);
        if (q != null) return q;
      }
    } else if (roll < weakRepeatChance + revisionChance) {
      final done = mine.where((f) => f.mastered).toList();
      if (done.isNotEmpty) {
        final q = Question.fromKey(topicId, done[_rng.nextInt(done.length)].key);
        if (q != null) return q;
      }
    }
    var q = _gen.generate(topicId);
    for (var i = 0; i < 5 && q.factKey == _lastKey; i++) {
      q = _gen.generate(topicId);
    }
    return q;
  }

  /// Facts the child finds hard, weakest first.
  List<FactStat> weakFacts({int limit = 20}) {
    final list = facts.values.where((f) => f.isWeak).toList()
      ..sort((a, b) {
        final c = a.accuracy.compareTo(b.accuracy);
        return c != 0 ? c : b.attempts.compareTo(a.attempts);
      });
    return list.take(limit).toList();
  }

  bool isMastered(String factKey) => facts[factKey]?.mastered ?? false;

  /// True when every line (×1 … ×10) of table [n] is mastered.
  bool isTableMastered(int n) {
    for (var b = 1; b <= 10; b++) {
      if (!isMastered('mul:$n:$b:0')) return false;
    }
    return true;
  }

  int sumsOn(DateTime day) => days[dayKey(day)]?.sums ?? 0;

  int get totalSums => days.values.fold(0, (a, d) => a + d.sums);

  int get totalCorrect => days.values.fold(0, (a, d) => a + d.correct);

  Future<void> reset() async {
    facts.clear();
    topics.clear();
    days.clear();
    await store.clear(profileId);
  }
}

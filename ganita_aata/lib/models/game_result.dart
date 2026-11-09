import 'question.dart';

enum GameMode { balloon, race, treasure, tables, speed, daily }

/// One answered (or missed) sum in a round.
class QuestionResult {
  const QuestionResult({required this.question, required this.given, required this.correct, required this.timeMs});

  final Question question;

  /// Null when time ran out before an answer.
  final Answer? given;
  final bool correct;
  final int timeMs;
}

/// Everything a finished round reports back.
class GameResult {
  GameResult({
    required this.mode,
    required this.topicId,
    required this.items,
    this.chests = 0,
    this.raceWon,
    this.table,
  });

  final GameMode mode;
  final String topicId;
  final List<QuestionResult> items;

  /// Treasure Hunt chests opened.
  final int chests;

  /// Race Car outcome.
  final bool? raceWon;

  /// Tables Master table.
  final int? table;

  int get correct => items.where((i) => i.correct).length;
  int get total => items.length;
  List<QuestionResult> get mistakes => items.where((i) => !i.correct).toList();
}

/// What the result screen shows after rewards are applied.
class RoundSummary {
  const RoundSummary({
    required this.stars,
    required this.coins,
    this.newBadges = const [],
    this.unlockedTopics = const [],
    this.newBest = false,
    this.best,
    this.streak,
  });

  final int stars;
  final int coins;
  final List<String> newBadges;
  final List<String> unlockedTopics;
  final bool newBest;
  final int? best;

  /// Set when the Daily Challenge streak was updated.
  final int? streak;
}

/// Daily puzzle: the same picture, cut and difficulty for everyone on a
/// given date, computed offline.
library;

import '../jigsaw/cut.dart';
import '../packs/content.dart';
import 'progress.dart';

class DailyPick {
  const DailyPick(this.date, this.puzzle, this.difficulty, this.seed);
  final DateTime date;
  final PuzzleDef puzzle;
  final Difficulty difficulty;
  final int seed;

  String get saveKey => 'daily-${dayKey(date)}';
}

/// Weekday difficulty: gentle at the start of the week, harder on Friday
/// and Saturday, easy on Sunday for families.
Difficulty dailyDifficulty(DateTime d) => switch (d.weekday) {
  DateTime.friday || DateTime.saturday => Difficulty.hard,
  DateTime.sunday => Difficulty.easy,
  _ => Difficulty.medium,
};

DailyPick? dailyFor(DateTime date, Iterable<PuzzleDef> puzzles) {
  final all = puzzles.toList()..sort((a, b) => a.id.compareTo(b.id));
  if (all.isEmpty) return null;
  final day = DateTime.utc(date.year, date.month, date.day);
  final n = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  // Walk through all puzzles in a scrambled but full cycle.
  final step = _coprimeStep(all.length);
  final idx = (n * step + 7) % all.length;
  final seed = int.parse(dayKey(date));
  return DailyPick(
    DateTime(date.year, date.month, date.day),
    all[idx],
    dailyDifficulty(date),
    seed,
  );
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

int _coprimeStep(int n) {
  for (var s = (n * 0.618).floor(); s > 1; s--) {
    if (_gcd(s, n) == 1) return s;
  }
  return 1;
}

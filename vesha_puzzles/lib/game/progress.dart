/// Player progress: completions, best times, stars, daily streak, stories
/// read, achievements and event badges.
library;

import '../jigsaw/cut.dart';

class PuzzleRecord {
  PuzzleRecord();
  int completions = 0;

  /// difficulty name → best time in ms.
  final Map<String, int> bestMs = {};

  /// difficulty name → best stars (1..3).
  final Map<String, int> stars = {};

  int get bestStars => stars.values.fold(0, (a, b) => a > b ? a : b);

  Map<String, Object?> toJson() => {'n': completions, 't': bestMs, 's': stars};

  factory PuzzleRecord.fromJson(Map json) {
    final r = PuzzleRecord()..completions = (json['n'] as num?)?.toInt() ?? 0;
    (json['t'] as Map? ?? const {}).forEach((k, v) => r.bestMs['$k'] = (v as num).toInt());
    (json['s'] as Map? ?? const {}).forEach((k, v) => r.stars['$k'] = (v as num).toInt());
    return r;
  }
}

/// Stars for a finished puzzle.
int starsFor({required int hints}) => hints == 0 ? 3 : (hints <= 2 ? 2 : 1);

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

DateTime? parseDayKey(String k) {
  if (k.length != 8) return null;
  final y = int.tryParse(k.substring(0, 4));
  final m = int.tryParse(k.substring(4, 6));
  final d = int.tryParse(k.substring(6, 8));
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

class Completion {
  const Completion({
    required this.puzzleId,
    required this.difficulty,
    required this.ms,
    required this.hints,
    required this.when,
    this.daily = false,
    this.eventIds = const [],
  });

  final String puzzleId;
  final Difficulty difficulty;
  final int ms;
  final int hints;
  final DateTime when;
  final bool daily;

  /// Active events this puzzle was featured in.
  final List<String> eventIds;

  int get stars => starsFor(hints: hints);
}

class Progress {
  Progress();

  final Map<String, PuzzleRecord> records = {};
  final Set<String> dailyDone = {}; // day keys
  final Set<String> storiesRead = {};
  final Set<String> eventBadges = {};
  final Map<String, String> achievements = {}; // id → day key unlocked
  int looksSaved = 0;
  int hintsUsed = 0;
  int noHintFinishes = 0;
  int expertFinishes = 0;
  int fastFinishes = 0;

  int get totalCompletions => records.values.fold(0, (a, r) => a + r.completions);
  int get distinctCompleted => records.values.where((r) => r.completions > 0).length;
  bool completed(String puzzleId) => (records[puzzleId]?.completions ?? 0) > 0;

  /// Applies a finished game. Returns true if it is a new best time.
  bool record(Completion c) {
    final r = records.putIfAbsent(c.puzzleId, PuzzleRecord.new);
    r.completions++;
    final d = c.difficulty.name;
    final best = r.bestMs[d];
    final isBest = best == null || c.ms < best;
    if (isBest) r.bestMs[d] = c.ms;
    if ((r.stars[d] ?? 0) < c.stars) r.stars[d] = c.stars;
    hintsUsed += c.hints;
    if (c.hints == 0) noHintFinishes++;
    if (c.difficulty == Difficulty.expert) expertFinishes++;
    if (c.difficulty.index >= Difficulty.medium.index && c.ms < 5 * 60 * 1000) {
      fastFinishes++;
    }
    if (c.daily) dailyDone.add(dayKey(c.when));
    eventBadges.addAll(c.eventIds);
    return isBest;
  }

  /// Consecutive days with a finished daily puzzle, ending today (or
  /// yesterday, so a streak is not lost before today's puzzle is played).
  int dailyStreak(DateTime today) {
    var d = DateTime(today.year, today.month, today.day);
    if (!dailyDone.contains(dayKey(d))) {
      d = DateTime(d.year, d.month, d.day - 1);
    }
    var n = 0;
    while (dailyDone.contains(dayKey(d))) {
      n++;
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  int bestDailyStreak() {
    final days = dailyDone.map(parseDayKey).whereType<DateTime>().toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  Map<String, Object?> toJson() => {
    'records': {for (final e in records.entries) e.key: e.value.toJson()},
    'daily': dailyDone.toList(),
    'stories': storiesRead.toList(),
    'events': eventBadges.toList(),
    'ach': achievements,
    'looks': looksSaved,
    'hints': hintsUsed,
    'noHint': noHintFinishes,
    'expert': expertFinishes,
    'fast': fastFinishes,
  };

  factory Progress.fromJson(Map json) {
    final p = Progress();
    (json['records'] as Map? ?? const {}).forEach(
      (k, v) => p.records['$k'] = PuzzleRecord.fromJson(v as Map),
    );
    p.dailyDone.addAll([for (final s in json['daily'] as List? ?? const []) '$s']);
    p.storiesRead.addAll([for (final s in json['stories'] as List? ?? const []) '$s']);
    p.eventBadges.addAll([for (final s in json['events'] as List? ?? const []) '$s']);
    (json['ach'] as Map? ?? const {}).forEach((k, v) => p.achievements['$k'] = '$v');
    int i(String k) => (json[k] as num?)?.toInt() ?? 0;
    p
      ..looksSaved = i('looks')
      ..hintsUsed = i('hints')
      ..noHintFinishes = i('noHint')
      ..expertFinishes = i('expert')
      ..fastFinishes = i('fast');
    return p;
  }
}

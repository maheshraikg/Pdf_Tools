/// Per-fact learning state, e.g. for "7 × 8".
class FactStat {
  FactStat({
    required this.key,
    required this.topicId,
    this.attempts = 0,
    this.correct = 0,
    this.streak = 0,
    this.mastered = false,
    this.lastCorrect = true,
    this.lastSeenMs = 0,
    this.totalTimeMs = 0,
  });

  final String key;
  final String topicId;
  int attempts;
  int correct;

  /// Correct answers in a row, each within the fast-answer limit.
  int streak;
  bool mastered;
  bool lastCorrect;
  int lastSeenMs;
  int totalTimeMs;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  /// 0 (mastered) … 1 (struggling). Used for the parent's weak-facts list.
  bool get isWeak => !mastered && attempts >= 2 && (accuracy < 0.7 || !lastCorrect);

  Map<String, dynamic> toJson() => {
    'k': key,
    't': topicId,
    'n': attempts,
    'c': correct,
    's': streak,
    'm': mastered,
    'l': lastCorrect,
    'ts': lastSeenMs,
    'ms': totalTimeMs,
  };

  factory FactStat.fromJson(Map<String, dynamic> j) => FactStat(
    key: j['k'] as String,
    topicId: j['t'] as String,
    attempts: j['n'] as int? ?? 0,
    correct: j['c'] as int? ?? 0,
    streak: j['s'] as int? ?? 0,
    mastered: j['m'] as bool? ?? false,
    lastCorrect: j['l'] as bool? ?? true,
    lastSeenMs: j['ts'] as int? ?? 0,
    totalTimeMs: j['ms'] as int? ?? 0,
  );
}

/// Per-topic totals plus the last 30 results (for unlocking).
class TopicStat {
  TopicStat({required this.topicId, List<bool>? recent, this.attempts = 0, this.correct = 0, this.totalTimeMs = 0})
    : recent = recent ?? [];

  static const window = 30;

  final String topicId;
  final List<bool> recent;
  int attempts;
  int correct;
  int totalTimeMs;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  double get recentAccuracy => recent.isEmpty ? 0 : recent.where((r) => r).length / recent.length;

  void add(bool isCorrect, int timeMs) {
    attempts++;
    if (isCorrect) correct++;
    totalTimeMs += timeMs;
    recent.add(isCorrect);
    while (recent.length > window) {
      recent.removeAt(0);
    }
  }

  Map<String, dynamic> toJson() => {
    't': topicId,
    'r': recent.map((b) => b ? 1 : 0).join(),
    'n': attempts,
    'c': correct,
    'ms': totalTimeMs,
  };

  factory TopicStat.fromJson(Map<String, dynamic> j) => TopicStat(
    topicId: j['t'] as String,
    recent: (j['r'] as String? ?? '').split('').where((s) => s.isNotEmpty).map((s) => s == '1').toList(),
    attempts: j['n'] as int? ?? 0,
    correct: j['c'] as int? ?? 0,
    totalTimeMs: j['ms'] as int? ?? 0,
  );
}

/// Totals for one calendar day.
class DayStat {
  DayStat({required this.date, this.sums = 0, this.correct = 0, this.totalTimeMs = 0});

  /// yyyy-mm-dd
  final String date;
  int sums;
  int correct;
  int totalTimeMs;

  double get avgSeconds => sums == 0 ? 0 : totalTimeMs / sums / 1000;

  Map<String, dynamic> toJson() => {'d': date, 'n': sums, 'c': correct, 'ms': totalTimeMs};

  factory DayStat.fromJson(Map<String, dynamic> j) => DayStat(
    date: j['d'] as String,
    sums: j['n'] as int? ?? 0,
    correct: j['c'] as int? ?? 0,
    totalTimeMs: j['ms'] as int? ?? 0,
  );
}

/// One answered sum, as written to the answer log.
class AnswerRecord {
  AnswerRecord({
    required this.factKey,
    required this.topicId,
    required this.expression,
    required this.correct,
    required this.timeMs,
    required this.at,
  });

  final String factKey;
  final String topicId;
  final String expression;
  final bool correct;
  final int timeMs;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'k': factKey,
    't': topicId,
    'q': expression,
    'c': correct,
    'ms': timeMs,
    'at': at.millisecondsSinceEpoch,
  };
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDayKey(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

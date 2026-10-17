/// Prayer tracker: which fard prayers were prayed on each day, days marked
/// as excused (e.g. menstruation or illness) and the resulting streak.
library;

import 'prayer_calc.dart';

/// "2026-10-16".
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class PrayerLog {
  PrayerLog({Map<String, int>? done, Set<String>? excused})
    : _done = done ?? {},
      _excused = excused ?? {};

  /// Bit i set = Prayer.fard[i] prayed.
  final Map<String, int> _done;
  final Set<String> _excused;

  /// Days kept (older entries are dropped when saving).
  static const int keepDays = 400;

  static int _bit(Prayer p) => 1 << Prayer.fard.indexOf(p);

  bool prayed(DateTime day, Prayer p) =>
      (_done[dateKey(day)] ?? 0) & _bit(p) != 0;

  void toggle(DateTime day, Prayer p) {
    final k = dateKey(day);
    final v = (_done[k] ?? 0) ^ _bit(p);
    if (v == 0) {
      _done.remove(k);
    } else {
      _done[k] = v;
    }
  }

  int count(DateTime day) {
    var v = _done[dateKey(day)] ?? 0, n = 0;
    while (v != 0) {
      n += v & 1;
      v >>= 1;
    }
    return n;
  }

  bool excused(DateTime day) => _excused.contains(dateKey(day));

  void setExcused(DateTime day, bool on) =>
      on ? _excused.add(dateKey(day)) : _excused.remove(dateKey(day));

  bool complete(DateTime day) => count(day) == Prayer.fard.length;

  /// Consecutive complete (or excused) days up to [today]; today counts
  /// once it is complete, and an unfinished today does not break it.
  int streak(DateTime today) {
    var d = DateTime.utc(today.year, today.month, today.day);
    if (!complete(d) && !excused(d)) d = d.subtract(const Duration(days: 1));
    var n = 0;
    while (complete(d) || excused(d)) {
      if (complete(d)) n++;
      d = d.subtract(const Duration(days: 1));
      if (n > keepDays * 2) break;
    }
    return n;
  }

  /// Prayers prayed and possible over the [days] days ending on [today]
  /// (excused days left out).
  (int prayed, int possible) total(DateTime today, int days) {
    var prayed = 0, possible = 0;
    for (var i = 0; i < days; i++) {
      final d = DateTime.utc(today.year, today.month, today.day - i);
      if (excused(d)) continue;
      prayed += count(d);
      possible += Prayer.fard.length;
    }
    return (prayed, possible);
  }

  Map<String, dynamic> toJson(DateTime today) {
    final oldest = dateKey(
      DateTime.utc(today.year, today.month, today.day - keepDays),
    );
    return {
      'done': {
        for (final e in _done.entries)
          if (e.key.compareTo(oldest) >= 0) e.key: e.value,
      },
      'excused': [
        for (final k in _excused)
          if (k.compareTo(oldest) >= 0) k,
      ],
    };
  }

  factory PrayerLog.fromJson(Map<String, dynamic> j) => PrayerLog(
    done: {
      for (final e in ((j['done'] as Map?) ?? const {}).entries)
        if (e.value is int) e.key as String: e.value as int,
    },
    excused: {
      for (final k in (j['excused'] as List?) ?? const [])
        if (k is String) k,
    },
  );
}

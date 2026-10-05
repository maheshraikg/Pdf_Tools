/// Achievement definitions and evaluation.
library;

import '../packs/content.dart';
import 'progress.dart';

class Achievement {
  const Achievement(this.id, this.icon, this.goal, this.value);
  final String id;

  /// Material icon code point name used by the UI.
  final String icon;

  /// Target count.
  final int goal;

  /// Current count for [p].
  final int Function(Progress p, Content c, DateTime today) value;

  bool unlocked(Progress p, Content c, DateTime today) =>
      value(p, c, today) >= goal;
}

int _packDone(Progress p, Content c, String packId) =>
    c.pack(packId)?.puzzles.where((z) => p.completed(z.id)).length ?? 0;

int _packSize(Content c, String packId) =>
    c.pack(packId)?.puzzles.length ?? 1 << 30;

/// All achievements, in display order. Goals that depend on content
/// (whole packs) are computed so that they stay correct when packs grow.
List<Achievement> achievementsFor(Content c) => [
  Achievement('first_puzzle', 'extension', 1, (p, _, _) => p.distinctCompleted),
  Achievement(
    'five_puzzles',
    'collections',
    5,
    (p, _, _) => p.distinctCompleted,
  ),
  Achievement(
    'all_puzzles',
    'workspace_premium',
    c.allPuzzles.length,
    (p, c, _) => c.allPuzzles.where((z) => p.completed(z.id)).length,
  ),
  for (final pack in c.packs)
    Achievement(
      'pack_${pack.id}',
      'theater_comedy',
      _packSize(c, pack.id),
      (p, c, _) => _packDone(p, c, pack.id),
    ),
  Achievement('no_hints', 'psychology', 1, (p, _, _) => p.noHintFinishes),
  Achievement('expert', 'military_tech', 1, (p, _, _) => p.expertFinishes),
  Achievement('speedy', 'bolt', 1, (p, _, _) => p.fastFinishes),
  Achievement('daily_1', 'today', 1, (p, _, _) => p.dailyDone.length),
  Achievement(
    'streak_3',
    'local_fire_department',
    3,
    (p, _, _) => p.bestDailyStreak(),
  ),
  Achievement('streak_7', 'whatshot', 7, (p, _, _) => p.bestDailyStreak()),
  Achievement('stories_5', 'menu_book', 5, (p, _, _) => p.storiesRead.length),
  Achievement(
    'dress_up',
    'face_retouching_natural',
    1,
    (p, _, _) => p.looksSaved,
  ),
  Achievement(
    'event_badge',
    'celebration',
    1,
    (p, _, _) => p.eventBadges.length,
  ),
];

/// Unlocks newly earned achievements in [p]; returns their ids.
List<String> unlockNew(Progress p, Content c, DateTime today) {
  final fresh = <String>[];
  for (final a in achievementsFor(c)) {
    if (!p.achievements.containsKey(a.id) && a.unlocked(p, c, today)) {
      p.achievements[a.id] = dayKey(today);
      fresh.add(a.id);
    }
  }
  return fresh;
}

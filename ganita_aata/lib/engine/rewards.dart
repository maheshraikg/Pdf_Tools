/// Stars, coins and badge rules.
class Rewards {
  Rewards._();

  /// Bonus coins for a 3-star round.
  static const threeStarBonus = 10;

  /// Coins inside each Treasure Hunt chest.
  static const chestCoins = 5;

  /// Bonus coins for winning a car race.
  static const raceWinBonus = 5;

  /// Speed Challenge score needed for the Speed Star badge.
  static const speedStarScore = 20;

  /// Sums in one day for the "100 sums in a day" badge.
  static const sumsInADay = 100;

  /// 1 star = 50%+, 2 stars = 75%+, 3 stars = 90%+ correct.
  static int stars(int correct, int total) {
    if (total <= 0) return 0;
    final pct = correct * 100 / total;
    if (pct >= 90) return 3;
    if (pct >= 75) return 2;
    if (pct >= 50) return 1;
    return 0;
  }

  /// 1 coin per correct answer, plus a bonus for 3 stars.
  static int coins(int correct, int stars) => correct + (stars == 3 ? threeStarBonus : 0);
}

/// Badge ids.
class Badges {
  Badges._();

  static const streak7 = 'streak_7';
  static const streak30 = 'streak_30';
  static const day100 = 'day_100';
  static const speedStar = 'speed_star';

  static String table(int n) => 'table_$n';

  static int? tableOf(String id) => id.startsWith('table_') ? int.tryParse(id.substring(6)) : null;

  /// Every badge, in display order.
  static List<String> get all => [speedStar, day100, streak7, streak30, for (var n = 2; n <= 20; n++) table(n)];
}

/// Daily Challenge streak rules.
class Streak {
  Streak._();

  /// The new streak after completing the challenge on [today], given the last
  /// completed day. Returns null if today's challenge was already counted.
  static int? afterCompletion({required int streak, required DateTime? lastDay, required DateTime today}) {
    if (lastDay == null) return 1;
    // Whole calendar days between the two dates.
    final days = _dayNumber(today) - _dayNumber(lastDay);
    if (days <= 0) return null;
    if (days == 1) return streak + 1;
    return 1;
  }

  /// The streak to show: it drops to 0 once a whole day has been missed.
  static int current({required int streak, required DateTime? lastDay, required DateTime today}) {
    if (lastDay == null) return 0;
    final days = _dayNumber(today) - _dayNumber(lastDay);
    return days <= 1 ? streak : 0;
  }

  static int _dayNumber(DateTime d) => DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;
}

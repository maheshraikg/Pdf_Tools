/// Dhikr for the Tasbih counter.
library;

class Dhikr {
  const Dhikr({
    required this.id,
    required this.arabic,
    required this.latin,
    required this.target,
  });

  final String id;
  final String arabic;

  /// Transliteration.
  final String latin;

  /// Count of one round; 0 = no target.
  final int target;
}

/// After each prayer: 33 × SubhanAllah, 33 × Alhamdulillah, 34 × Allahu
/// Akbar, one after the other.
const List<Dhikr> afterPrayerSet = [
  Dhikr(
    id: 'subhanallah',
    arabic: 'سُبْحَانَ ٱللَّٰهِ',
    latin: 'SubhanAllah',
    target: 33,
  ),
  Dhikr(
    id: 'alhamdulillah',
    arabic: 'ٱلْحَمْدُ لِلَّٰهِ',
    latin: 'Alhamdulillah',
    target: 33,
  ),
  Dhikr(
    id: 'allahuakbar',
    arabic: 'ٱللَّٰهُ أَكْبَرُ',
    latin: 'Allahu Akbar',
    target: 34,
  ),
];

const List<Dhikr> dhikrList = [
  ...afterPrayerSet,
  Dhikr(
    id: 'tahlil',
    arabic: 'لَا إِلَٰهَ إِلَّا ٱللَّٰهُ',
    latin: 'La ilaha illallah',
    target: 100,
  ),
  Dhikr(
    id: 'istighfar',
    arabic: 'أَسْتَغْفِرُ ٱللَّٰهَ',
    latin: 'Astaghfirullah',
    target: 100,
  ),
  Dhikr(
    id: 'salawat',
    arabic: 'ٱللَّٰهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
    latin: 'Allahumma salli ala Muhammad',
    target: 100,
  ),
  Dhikr(
    id: 'subhanallahi_wabihamdihi',
    arabic: 'سُبْحَانَ ٱللَّٰهِ وَبِحَمْدِهِ',
    latin: 'SubhanAllahi wa bihamdihi',
    target: 100,
  ),
  Dhikr(id: 'free', arabic: '', latin: '', target: 0),
];

/// Counter state: the chosen mode (-1 = after-prayer set, else an index in
/// [dhikrList]), the step within the set, the count and completed rounds.
class TasbihState {
  TasbihState({
    this.mode = -1,
    this.step = 0,
    this.count = 0,
    this.rounds = 0,
    this.totalDate = '',
    this.total = 0,
  });

  int mode, step, count, rounds;

  /// Taps today (for [totalDate]).
  String totalDate;
  int total;

  Dhikr get current => mode < 0 ? afterPrayerSet[step] : dhikrList[mode];

  /// Counts one; returns true when a round (or the whole set) is complete.
  bool tap(String today) {
    if (totalDate != today) {
      totalDate = today;
      total = 0;
    }
    total++;
    count++;
    final target = current.target;
    if (target == 0 || count < target) return false;
    if (mode < 0) {
      if (step < afterPrayerSet.length - 1) {
        step++;
        count = 0;
        return true;
      }
      step = 0;
    }
    count = 0;
    rounds++;
    return true;
  }

  void reset() {
    step = 0;
    count = 0;
    rounds = 0;
  }

  void choose(int m) {
    mode = m;
    reset();
  }

  Map<String, dynamic> toJson() => {
    'mode': mode,
    'step': step,
    'count': count,
    'rounds': rounds,
    'totalDate': totalDate,
    'total': total,
  };

  factory TasbihState.fromJson(Map<String, dynamic> j) {
    final mode = j['mode'] as int? ?? -1;
    final valid = mode >= -1 && mode < dhikrList.length;
    final step = j['step'] as int? ?? 0;
    return TasbihState(
      mode: valid ? mode : -1,
      step: step >= 0 && step < afterPrayerSet.length ? step : 0,
      count: valid ? j['count'] as int? ?? 0 : 0,
      rounds: j['rounds'] as int? ?? 0,
      totalDate: j['totalDate'] as String? ?? '',
      total: j['total'] as int? ?? 0,
    );
  }
}

/// Tabular (arithmetical) Islamic calendar with a user day adjustment.
///
/// Kerala follows local moon sighting, so the date can differ by a day from
/// any calculation; the user corrects it with [HijriDate.fromGregorian]'s
/// `adjustDays`.
library;

class HijriDate {
  const HijriDate(this.year, this.month, this.day);
  final int year, month, day;

  static const monthsEn = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Akhir',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qa'dah",
    'Dhu al-Hijjah',
  ];

  static const monthsMl = [
    'മുഹർറം',
    'സഫർ',
    'റബീഉൽ അവ്വൽ',
    'റബീഉൽ ആഖിർ',
    'ജമാദുൽ ഊല',
    'ജമാദുൽ ആഖിർ',
    'റജബ്',
    'ശഅ്ബാൻ',
    'റമളാൻ',
    'ശവ്വാൽ',
    'ദുൽ ഖഅ്ദ',
    'ദുൽ ഹിജ്ജ',
  ];

  String monthName(bool malayalam) =>
      (malayalam ? monthsMl : monthsEn)[month - 1];

  bool get isRamadan => month == 9;

  /// Hijri date of a Gregorian civil date, shifted by [adjustDays].
  static HijriDate fromGregorian(
    int year,
    int month,
    int day, {
    int adjustDays = 0,
  }) {
    final jdn = gregorianToJdn(year, month, day) + adjustDays;
    var l = jdn - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j =
        ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l =
        l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final m = (24 * l) ~/ 709;
    final d = l - (709 * m) ~/ 24;
    final y = 30 * n + j - 30;
    return HijriDate(y, m, d);
  }

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$day ${monthsEn[month - 1]} $year AH';
}

/// Julian Day Number (integer, noon-based) of a Gregorian date.
int gregorianToJdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d +
      (153 * mm + 2) ~/ 5 +
      365 * yy +
      yy ~/ 4 -
      yy ~/ 100 +
      yy ~/ 400 -
      32045;
}

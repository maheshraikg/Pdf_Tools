/// Calendar helpers. All dates are local calendar days (time of day ignored).
library;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// [d] plus [months] calendar months, clamping the day to the month's end
/// (31 Jan + 1 month = 28/29 Feb).
DateTime addMonths(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12, m = total % 12 + 1;
  final last = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > last ? last : d.day);
}

DateTime addYears(DateTime d, int years) => addMonths(d, years * 12);

/// Whole calendar months completed from [from] to [to] (0 if [to] < [from]).
int monthsBetween(DateTime from, DateTime to) {
  if (!to.isAfter(from)) return 0;
  var m = (to.year - from.year) * 12 + (to.month - from.month);
  if (addMonths(from, m).isAfter(to)) m--;
  return m < 0 ? 0 : m;
}

/// First year of the Indian financial year (April–March) containing [d].
int fyStartYear(DateTime d) => d.month >= 4 ? d.year : d.year - 1;

/// "2026-27" for the financial year starting in April [startYear].
String fyLabel(int startYear) =>
    '$startYear-${((startYear + 1) % 100).toString().padLeft(2, '0')}';

/// Age in completed years on [on].
int ageOn(DateTime birth, DateTime on) {
  var a = on.year - birth.year;
  if (on.month < birth.month ||
      (on.month == birth.month && on.day < birth.day)) {
    a--;
  }
  return a;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/prayer_calc.dart';

/// Rows of the original app's world tables (local clock, fixed offset):
/// Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha in minutes; -1 = not
/// calculable there.
const _rows = [
  (
    'Mumbai',
    19.07599,
    72.87765,
    330,
    CalcMethod.karachi,
    [
      (2026, 1, 1, [354, 432, 762, 950, 1092, 1170]),
      (2026, 6, 21, [279, 362, 760, 963, 1159, 1242]),
      (2027, 10, 19, [320, 394, 744, 944, 1093, 1166]),
    ],
  ),
  (
    'Cairo',
    30.04442,
    31.23571,
    120,
    CalcMethod.egypt,
    [
      (2026, 1, 1, [319, 411, 719, 888, 1026, 1109]),
      (2026, 6, 21, [188, 294, 717, 932, 1139, 1233]),
      (2027, 10, 19, [272, 359, 700, 894, 1040, 1118]),
    ],
  ),
  (
    'New York',
    40.71277,
    -74.00597,
    -300,
    CalcMethod.isna,
    [
      (2026, 1, 1, [358, 440, 720, 861, 999, 1081]),
      (2026, 6, 21, [165, 265, 718, 958, 1171, 1271]),
      (2027, 10, 19, [296, 371, 701, 883, 1030, 1105]),
    ],
  ),
  (
    'Makkah',
    21.42251,
    39.82617,
    180,
    CalcMethod.ummAlQura,
    [
      (2026, 1, 1, [337, 419, 744, 929, 1070, 1160]),
      (2026, 6, 21, [251, 339, 742, 942, 1146, 1236]),
      (2027, 10, 19, [301, 378, 726, 925, 1073, 1163]),
    ],
  ),
  (
    'Tehran',
    35.72186,
    51.33469,
    210,
    CalcMethod.tehran,
    [
      (2026, 1, 1, [345, 434, 728, 884, 1042, 1093]),
      (2026, 6, 21, [182, 289, 726, 956, 1185, 1245]),
      (2027, 10, 19, [291, 374, 710, 898, 1063, 1110]),
    ],
  ),
  (
    'Berlin',
    52.52,
    13.40495,
    60,
    CalcMethod.mwl,
    [
      (2026, 1, 1, [370, 497, 730, 827, 963, 1083]),
      (2026, 6, 21, [-1, 223, 728, 993, 1233, -1]),
      (2027, 10, 19, [284, 398, 711, 870, 1023, 1131]),
    ],
  ),
];

void main() {
  test('same times as the original app\'s world tables', () {
    for (final (name, lat, lng, offset, method, days) in _rows) {
      for (final (y, m, d, want) in days) {
        final b = computeBasicTimes(
          year: y,
          month: m,
          day: d,
          latitude: lat,
          longitude: lng,
          params: CalcParams(method: method),
          utcOffsetMinutes: offset,
        );
        final got = [b.fajr, b.sunrise, b.dhuhr, b.asr, b.maghrib, b.isha].map((
          t,
        ) {
          final l = t.add(Duration(minutes: offset));
          final r = l.add(Duration(seconds: l.second >= 30 ? 60 : 0));
          return r.hour * 60 + r.minute;
        }).toList();
        for (var i = 0; i < 6; i++) {
          if (want[i] < 0) continue;
          expect(got[i], want[i], reason: '$name $y-$m-$d #$i');
        }
        // Where the table has no Fajr/Isha (Berlin midsummer), the app
        // still gives one: a part of the short night.
        expect(got[0] < got[1] && got[4] < got[5] + 1440, isTrue);
      }
    }
  });
}

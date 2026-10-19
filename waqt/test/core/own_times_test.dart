import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/prayer_calc.dart';

void main() {
  String clock(AppSettings s, Prayer p) {
    final d = s.calculator.day(2026, 10, 19);
    return s.wall(d[p]).toString().substring(11, 16);
  }

  test('own Azan time replaces the calculated one', () async {
    final s = AppSettings.memory();
    final asr = clock(s, Prayer.asr);
    await s.update((x) => x.fixedTimes = {Prayer.dhuhr: 13 * 60 + 15});
    expect(clock(s, Prayer.dhuhr), '13:15');
    expect(clock(s, Prayer.asr), asr);
    await s.update((x) => x.fixedTimes = {});
    expect(clock(s, Prayer.dhuhr), isNot('13:15'));
  });

  test('Custom Method uses the angles set', () async {
    final s = AppSettings.memory();
    await s.update((x) {
      x.method = CalcMethod.custom;
      x.customFajr = 18;
      x.customIsha = 18;
    });
    final karachi = AppSettings.memory();
    await karachi.update((x) => x.method = CalcMethod.karachi);
    expect(clock(s, Prayer.fajr), clock(karachi, Prayer.fajr));
    expect(clock(s, Prayer.isha), clock(karachi, Prayer.isha));
    await s.update((x) => x.customFajr = 15);
    expect(clock(s, Prayer.fajr), isNot(clock(karachi, Prayer.fajr)));
  });
}

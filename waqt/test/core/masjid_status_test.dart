import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/background.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/cities.dart';
import 'package:waqt/core/masjid.dart';
import 'package:waqt/core/prayer_calc.dart';

void main() {
  AppSettings withIqama(AppSettings s, int dhuhr) => s
    ..alerts = s.alerts.withPrayer(
      Prayer.dhuhr,
      s.alerts.of(Prayer.dhuhr).copyWith(iqamaDelay: dhuhr),
    );

  group('Mosque profiles', () {
    test('json round trip', () {
      final s = withIqama(AppSettings.memory(), 22);
      final m = Masjid.fromAlerts('Town', 'Market road', s.alerts, {
        Prayer.asr: 2,
      });
      final back = Masjid.fromJson(m.toJson());
      expect(back.name, 'Town');
      expect(back.description, 'Market road');
      expect(back.iqama[Prayer.dhuhr]!.delay, 22);
      expect(back.adjustments, {Prayer.asr: 2});
    });

    test('switching keeps each mosque\'s Iqama times', () async {
      final s = withIqama(AppSettings.memory(), 10);
      s.masjids = [
        Masjid.fromAlerts('A', '', s.alerts),
        Masjid.fromAlerts('B', '', withIqama(AppSettings.memory(), 25).alerts),
      ];
      s.activeMasjid = 0;
      // Edits go to the active mosque.
      await s.update((x) => withIqama(x, 12));
      await s.selectMasjid(1);
      expect(s.alerts.of(Prayer.dhuhr).iqamaDelay, 25);
      await s.selectMasjid(0);
      expect(s.alerts.of(Prayer.dhuhr).iqamaDelay, 12);
    });

    test('deleting the active mosque hands over to the next', () async {
      final s = withIqama(AppSettings.memory(), 10);
      s.masjids = [
        Masjid.fromAlerts('A', '', s.alerts),
        Masjid.fromAlerts('B', '', withIqama(AppSettings.memory(), 25).alerts),
      ];
      await s.removeMasjid(0);
      expect(s.masjids.single.name, 'B');
      expect(s.activeMasjid, 0);
      expect(s.alerts.of(Prayer.dhuhr).iqamaDelay, 25);
      expect(s.masjids.single.iqama[Prayer.dhuhr]!.delay, 25);
    });
  });

  test('suggested method follows the Indian state', () {
    expect(suggestedMethod('IN', 'Kerala').$1, 'kerala');
    // Mangaluru (coast) follows Kerala; Bengaluru does not.
    expect(suggestedMethod('IN', 'Karnataka', 74.86).$1, 'kerala');
    expect(suggestedMethod('IN', 'Karnataka', 77.59), (
      'karachi',
      AsrMethod.hanafi,
    ));
  });

  test('status notification states', () {
    final s = AppSettings.memory();
    final days = s.calculator.days(DateTime.utc(2026, 10, 15), 3);
    final now = days[1][Prayer.fajr].add(const Duration(hours: 1));
    final states = statusStates(s, days, now);
    expect(states, isNotEmpty);
    expect(states.first['from'], now.millisecondsSinceEpoch);
    // Next Azan after Fajr is Dhuhr.
    expect(
      states.first['countdown'],
      days[1][Prayer.dhuhr].millisecondsSinceEpoch,
    );
    // 16 Oct 2026 is a Friday.
    expect(states.first['title'] as String, contains("Jumu'ah Azan"));
    expect(states.first['iqama'] as String, endsWith('⌛'));
    expect(states.first['where'], s.place.label(false));
    for (var i = 1; i < states.length; i++) {
      expect(
        (states[i]['from'] as int) > (states[i - 1]['from'] as int),
        isTrue,
      );
      expect(
        (states[i]['countdown'] as int) > (states[i]['from'] as int),
        isTrue,
      );
    }
  });
}

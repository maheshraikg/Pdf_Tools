import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/alerts.dart';
import 'package:waqt/core/day.dart';
import 'package:waqt/core/place.dart';
import 'package:waqt/core/prayer_calc.dart';

final _koz = presetPlaces.firstWhere((p) => p.id == 'kozhikode');

void main() {
  final calc = DayCalculator(place: _koz, params: const CalcParams());

  test('Taraweeh on every night before a Ramadan fast, after Isha Iqama', () {
    final days = calc.days(DateTime.utc(2027, 1, 30), 50);
    const config = AlertConfig(
      taraweehAlert: true,
      taraweehMinutesAfterIsha: 10,
    );
    final plan = planAlerts(days, config, DateTime.utc(2027, 1, 1));
    final t = plan.where((a) => a.special == SpecialEvent.taraweeh).toList();
    final fasts = days.where((d) => d.hijri.isRamadan).length;
    expect(t.length, fasts);
    for (final a in t) {
      final d = days.firstWhere(
        (d) =>
            iqamaTime(
              d,
              Prayer.isha,
              config,
            ).add(const Duration(minutes: 10)) ==
            a.at,
      );
      final i = days.indexOf(d);
      expect(days[i + 1].hijri.isRamadan, isTrue);
    }
    // Ids do not clash with the daily alerts.
    final all = planAlerts(
      days,
      const AlertConfig(
        taraweehAlert: true,
        eidAlert: true,
        imsakAlert: true,
        tahajjudAlert: true,
      ),
      DateTime.utc(2027, 1, 1),
    );
    expect(all.map((a) => a.id).toSet().length, all.length);
  });

  test('Eid alerts 30 minutes before the set prayer time', () {
    final days = calc.days(DateTime.utc(2027, 2, 20), 120);
    const config = AlertConfig(
      eidAlert: true,
      eidFitrTime: 8 * 60,
      eidAdhaTime: 7 * 60 + 15,
    );
    final plan = planAlerts(days, config, DateTime.utc(2027, 1, 1));
    final fitr = plan.singleWhere((a) => a.special == SpecialEvent.eidAlFitr);
    final adha = plan.singleWhere((a) => a.special == SpecialEvent.eidAlAdha);
    DateTime local(DateTime u) => u.add(const Duration(minutes: 330));
    expect(local(fitr.at).hour * 60 + local(fitr.at).minute, 8 * 60 - 30);
    expect(local(adha.at).hour * 60 + local(adha.at).minute, 6 * 60 + 45);
    final fd = days.firstWhere((d) => d.hijri.month == 10 && d.hijri.day == 1);
    expect(
      DateTime.utc(
        local(fitr.at).year,
        local(fitr.at).month,
        local(fitr.at).day,
      ),
      fd.date,
    );
    expect(
      planAlerts(
        days,
        const AlertConfig(),
        DateTime.utc(2027),
      ).where((a) => a.special != null),
      isEmpty,
    );
  });

  test('sound settings: Fajr override and JSON round trip', () {
    const c = AlertConfig(
      azanSound: SoundChoice(
        AzanSound.custom,
        path: 'file:/x/azan.mp3',
        fileName: 'azan.mp3',
      ),
      fajrSound: SoundChoice(AzanSound.bell),
      vibrate: false,
      playWhenSilent: true,
    );
    expect(c.soundFor(Prayer.dhuhr).playerSound, 'file:/x/azan.mp3');
    expect(c.soundFor(Prayer.fajr).playerSound, 'bell');
    expect(const AlertConfig().soundFor(Prayer.fajr).playerSound, isNull);
    final back = AlertConfig.fromJson(
      (jsonDecode(jsonEncode(c.toJson())) as Map).cast<String, dynamic>(),
    );
    expect(back.soundFor(Prayer.isha).fileName, 'azan.mp3');
    expect(back.fajrSound?.sound, AzanSound.bell);
    expect(back.vibrate, isFalse);
    expect(back.playWhenSilent, isTrue);
    expect(back.copyWith(fajrSound: null).fajrSound, isNull);
    // Old settings without the new keys keep the notification sound.
    expect(AlertConfig.fromJson({}).azanSound.sound, AzanSound.system);
  });
}

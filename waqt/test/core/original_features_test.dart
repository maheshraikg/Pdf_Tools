import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/app/settings.dart';
import 'package:waqt/core/alerts.dart';
import 'package:waqt/core/prayer_calc.dart';

void main() {
  final s = AppSettings.memory();
  // 1 Feb 2027 + 20 days: the start of Ramadan 1448 is inside.
  final days = s.calculator.days(DateTime.utc(2027, 2, 1), 20);
  final before = DateTime.utc(2027, 1, 1);

  test('Niyyah reminders on Ramadan nights, before Fajr', () {
    final n = planNotices(
      days,
      const AlertConfig(fridayReminder: false),
      before,
    );
    expect(n, isNotEmpty);
    for (final x in n) {
      expect(x.kind, NoticeKind.niyyah);
      final next = days.firstWhere((d) => d[Prayer.fajr].isAfter(x.at));
      expect(next.hijri.isRamadan, isTrue);
      expect(x.latest.isBefore(next[Prayer.fajr]), isTrue);
    }
    // Off: none.
    expect(
      planNotices(
        days,
        const AlertConfig(niyyahReminder: false, fridayReminder: false),
        before,
      ),
      isEmpty,
    );
  });

  test('Friday-night reminder on Thursday after Maghrib', () {
    final n = planNotices(
      days,
      const AlertConfig(niyyahReminder: false),
      before,
    );
    expect(n, isNotEmpty);
    for (final x in n) {
      final d = days.lastWhere((d) => !d[Prayer.maghrib].isAfter(x.at));
      expect(d.date.weekday, DateTime.thursday);
      expect(x.at.difference(d[Prayer.maghrib]).inMinutes, 30);
    }
  });

  test('Sunrise and Ishraq alerts', () {
    final plan = planAlerts(
      days.take(1).toList(),
      const AlertConfig(
        sunriseAlert: true,
        sunriseMinutesBefore: 20,
        ishraqAlert: true,
      ),
      before,
    );
    final sunrise = plan.firstWhere((a) => a.prayer == Prayer.sunrise);
    expect(sunrise.minutesBefore, 20);
    expect(
      sunrise.at,
      days.first[Prayer.sunrise].subtract(const Duration(minutes: 20)),
    );
    expect(plan.where((a) => a.prayer == Prayer.ishraq), hasLength(1));
    // Ids stay unique.
    final all = planAlerts(
      days,
      const AlertConfig(
        sunriseAlert: true,
        ishraqAlert: true,
        tahajjudAlert: true,
        imsakAlert: true,
        taraweehAlert: true,
        eidAlert: true,
      ),
      before,
    );
    expect(all.map((a) => a.id).toSet(), hasLength(all.length));
  });

  test('auto silent only for the chosen prayers', () {
    final w = planSilent(
      days.take(7).toList(),
      const AlertConfig(
        silentEnabled: true,
        silentPrayers: {Prayer.isha},
        silentJumuah: true,
      ),
      before,
    );
    // Isha every day plus Jumu'ah once.
    expect(w, hasLength(8));
    final none = planSilent(
      days.take(7).toList(),
      const AlertConfig(
        silentEnabled: true,
        silentPrayers: {},
        silentJumuah: false,
      ),
      before,
    );
    expect(none, isEmpty);
  });

  test('new settings survive JSON', () {
    const c = AlertConfig(
      sunriseAlert: true,
      sunriseMinutesBefore: 25,
      ishraqAlert: true,
      iqamaSound: SoundChoice(AzanSound.bell),
      iqamaFullScreen: true,
      azanVolume: 70,
      iqamaVolume: 40,
      silentPrayers: {Prayer.fajr, Prayer.isha},
      silentJumuah: false,
      niyyahReminder: false,
      fridayReminder: false,
    );
    final b = AlertConfig.fromJson(c.toJson());
    expect(b.sunriseAlert, isTrue);
    expect(b.sunriseMinutesBefore, 25);
    expect(b.ishraqAlert, isTrue);
    expect(b.iqamaSound?.sound, AzanSound.bell);
    expect(b.iqamaFullScreen, isTrue);
    expect(b.azanVolume, 70);
    expect(b.iqamaVolume, 40);
    expect(b.silentPrayers, {Prayer.fajr, Prayer.isha});
    expect(b.silentJumuah, isFalse);
    expect(b.niyyahReminder, isFalse);
    expect(b.fridayReminder, isFalse);
    // Older saved settings keep the defaults.
    final old = AlertConfig.fromJson({});
    expect(old.silentPrayers, Prayer.fard.toSet());
    expect(old.niyyahReminder, isTrue);
    expect(old.iqamaSound, isNull);
  });
}

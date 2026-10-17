import 'package:flutter_test/flutter_test.dart';
import 'package:waqt/core/events.dart';
import 'package:waqt/core/prayer_calc.dart';
import 'package:waqt/core/tasbih.dart';
import 'package:waqt/core/tracker.dart';

DateTime _d(int y, int m, int d) => DateTime.utc(y, m, d);

void main() {
  test('tracker: toggle, streak with excused days, totals, JSON', () {
    final log = PrayerLog();
    void all(DateTime d) {
      for (final p in Prayer.fard) {
        log.toggle(d, p);
      }
    }

    all(_d(2026, 10, 12));
    log.setExcused(_d(2026, 10, 13), true);
    all(_d(2026, 10, 14));
    all(_d(2026, 10, 15));
    log.toggle(_d(2026, 10, 16), Prayer.fajr);
    expect(log.count(_d(2026, 10, 16)), 1);
    // Unfinished today does not break it; the excused day is skipped.
    expect(log.streak(_d(2026, 10, 16)), 3);
    expect(log.streak(_d(2026, 10, 17)), 0);
    log.toggle(_d(2026, 10, 16), Prayer.fajr);
    expect(log.prayed(_d(2026, 10, 16), Prayer.fajr), isFalse);
    final (done, max) = log.total(_d(2026, 10, 16), 7);
    expect(done, 15);
    expect(max, 30); // 6 non-excused days
    final back = PrayerLog.fromJson(log.toJson(_d(2026, 10, 16)));
    expect(back.streak(_d(2026, 10, 15)), 3);
    expect(back.excused(_d(2026, 10, 13)), isTrue);
    // Old entries are dropped.
    log.toggle(_d(2020, 1, 1), Prayer.isha);
    expect(
      PrayerLog.fromJson(log.toJson(_d(2026, 10, 16))).count(_d(2020, 1, 1)),
      0,
    );
  });

  test('tasbih: after-prayer set advances 33 · 33 · 34', () {
    final t = TasbihState();
    for (var i = 0; i < 32; i++) {
      expect(t.tap('d'), isFalse);
    }
    expect(t.tap('d'), isTrue);
    expect(t.current.latin, 'Alhamdulillah');
    for (var i = 0; i < 33; i++) {
      t.tap('d');
    }
    expect(t.current.latin, 'Allahu Akbar');
    for (var i = 0; i < 34; i++) {
      t.tap('d');
    }
    expect(t.rounds, 1);
    expect(t.current.latin, 'SubhanAllah');
    expect(t.total, 100);
    t.tap('next day');
    expect(t.total, 1);
    t.choose(dhikrList.length - 1); // free count never completes
    for (var i = 0; i < 500; i++) {
      expect(t.tap('x'), isFalse);
    }
  });

  test('upcoming Islamic occasions', () {
    final ev = upcomingEvents(_d(2026, 10, 16), count: 10);
    expect(ev.length, 10);
    expect(ev.map((e) => e.event).toSet().length, 10);
    for (final e in ev) {
      expect(e.hijri.month, e.event.month);
      expect(e.hijri.day, e.event.day);
    }
    expect(ev.first.daysLeft, greaterThanOrEqualTo(0));
    final eid = ev.firstWhere((e) => e.event == IslamicEvent.eidAlFitr);
    final shifted = upcomingEvents(
      _d(2026, 10, 16),
      adjustDays: 1,
      count: 10,
    ).firstWhere((e) => e.event == IslamicEvent.eidAlFitr);
    expect(shifted.daysLeft, eid.daysLeft - 1);
  });
}

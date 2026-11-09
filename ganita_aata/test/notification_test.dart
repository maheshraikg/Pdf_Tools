import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/services/notification_service.dart';

void main() {
  setUpAll(NotificationService.initTimeZones);

  test('reminder later today is scheduled today in IST', () {
    // 09:00 IST = 03:30 UTC.
    final t = NotificationService.nextInstance(17, 0, now: DateTime.utc(2026, 11, 9, 3, 30));
    expect(t.location.name, 'Asia/Kolkata');
    expect([t.year, t.month, t.day, t.hour, t.minute], [2026, 11, 9, 17, 0]);
    expect(t.toUtc(), DateTime.utc(2026, 11, 9, 11, 30));
  });

  test('a time already passed moves to tomorrow', () {
    // 18:00 IST.
    final t = NotificationService.nextInstance(17, 0, now: DateTime.utc(2026, 11, 9, 12, 30));
    expect([t.year, t.month, t.day, t.hour], [2026, 11, 10, 17]);
  });

  test('uses the IST calendar date even when UTC is still yesterday', () {
    // 01:00 IST on 1 Jan 2027 is 19:30 UTC on 31 Dec 2026.
    final t = NotificationService.nextInstance(7, 30, now: DateTime.utc(2026, 12, 31, 19, 30));
    expect([t.year, t.month, t.day, t.hour, t.minute], [2027, 1, 1, 7, 30]);
  });

  test('exactly now goes to the next day; month end rolls over', () {
    final t = NotificationService.nextInstance(17, 0, now: DateTime.utc(2026, 11, 30, 11, 30));
    expect([t.month, t.day], [12, 1]);
  });
}

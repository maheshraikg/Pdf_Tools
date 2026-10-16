/// Islamic occasions by Hijri date.
library;

import 'hijri.dart';

enum IslamicEvent {
  newYear(1, 1),
  ashura(1, 10),
  mawlid(3, 12),
  israMiraj(7, 27),
  midShaban(8, 15),
  ramadanStart(9, 1),
  laylatAlQadr(9, 27),
  eidAlFitr(10, 1),
  arafah(12, 9),
  eidAlAdha(12, 10);

  const IslamicEvent(this.month, this.day);
  final int month, day;
}

class UpcomingEvent {
  const UpcomingEvent(this.event, this.date, this.daysLeft, this.hijri);
  final IslamicEvent event;

  /// Civil date (UTC midnight) and days from today (0 = today).
  final DateTime date;
  final int daysLeft;
  final HijriDate hijri;
}

/// The next [count] occasions from [today] (within about a year), with the
/// user's Hijri day correction.
List<UpcomingEvent> upcomingEvents(
  DateTime today, {
  int adjustDays = 0,
  int count = 10,
}) {
  final out = <UpcomingEvent>[];
  for (var i = 0; i < 400 && out.length < count; i++) {
    final d = DateTime.utc(today.year, today.month, today.day + i);
    final h = HijriDate.fromGregorian(
      d.year,
      d.month,
      d.day,
      adjustDays: adjustDays,
    );
    for (final e in IslamicEvent.values) {
      if (e.month == h.month && e.day == h.day) {
        out.add(UpcomingEvent(e, d, i, h));
      }
    }
  }
  return out;
}

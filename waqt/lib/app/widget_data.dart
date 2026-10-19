/// Data for the home-screen widget (WaqtWidgetProvider.kt): preformatted
/// times for the coming days, so the widget can find the next prayer and
/// count down to it without running Dart.
library;

import 'dart:convert';

import '../core/day.dart';
import '../core/prayer_calc.dart';
import 'scope.dart';
import 'settings.dart';
import 'strings.dart';

String widgetJson(AppSettings settings, List<PrayerDay> days) {
  final s = S(settings.lang);
  return jsonEncode({
    'place': settings.place.label(s.ml),
    'format': s.widgetCountdown,
    'stale': s.widgetStale,
    'days': [
      for (final d in days)
        {
          'title':
              '${weekdayName(settings.lang, d.date.weekday)} ${d.day} ${monthName(settings.lang, d.month)} · '
              '${d.hijri.day} ${hijriMonthName(settings.lang, d.hijri.month)}',
          'p': [
            for (final p in Prayer.fard)
              {
                'n': s.prayer(p, friday: d.isFriday),
                's': hm(
                  settings,
                  d[p],
                ).replaceAll(' AM', 'a').replaceAll(' PM', 'p'),
                't': d[p].millisecondsSinceEpoch,
              },
          ],
        },
    ],
  });
}

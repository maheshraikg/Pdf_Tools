/// Notifications and the home-screen widget. Both are fed with precomputed
/// text for the coming days and refreshed whenever the app is opened or the
/// settings change.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:home_widget/home_widget.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../panchanga/engine.dart';
import '../panchanga/festivals.dart';
import '../panchanga/names.dart';
import 'repo.dart';
import 'scope.dart';
import 'settings.dart';
import 'strings.dart';
import 'summary.dart';

/// Days of notifications scheduled ahead (refreshed on every app start).
const int kNotifyDays = 14;

/// Days of widget data stored ahead.
const int kWidgetDays = 31;

const String kWidgetProvider =
    'com.kspstadk.tulu_panchanga.TodayWidgetProvider';

class Background {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!_supported || _ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Asks for the Android 13+ notification permission.
  static Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Re-schedules notifications and refreshes the widget for [settings].
  static Future<void> refresh(AppSettings settings, PanchangaRepo repo) async {
    if (!_supported) return;
    try {
      await init();
      final today = todayAt(repo.engine);
      final days = await repo.days(today, kWidgetDays);
      final fest = <FestivalOccurrence>[
        ...await repo.festivals(today.year),
        if (PanchangaEngine.addDays(today, kWidgetDays).year != today.year)
          ...await repo.festivals(today.year + 1),
      ];
      await _updateWidget(settings, repo.engine, days, fest);
      await _schedule(
        settings,
        repo.engine,
        days.take(kNotifyDays + 1).toList(),
        fest,
      );
    } catch (e, st) {
      debugPrint('Background refresh failed: $e\n$st');
    }
  }

  static List<FestivalOccurrence> _notable(
    List<FestivalOccurrence> all,
    DateTime date,
  ) => all
      .where(
        (o) =>
            o.date == date &&
            (o.festival.category != FestivalCategory.vrata ||
                o.festival.id == 'ekadashi'),
      )
      .toList();

  static Future<void> _updateWidget(
    AppSettings settings,
    PanchangaEngine e,
    List<DayPanchanga> days,
    List<FestivalOccurrence> fest,
  ) async {
    // The widget cannot use the Tulu-lipi font, so Tulu shows in Kannada
    // script there.
    final lang = settings.lang;
    final s = S(lang);
    final data = <String, Map<String, String>>{};
    for (final d in days) {
      final f = _notable(fest, d.date);
      data[d.date.toIso8601String().substring(0, 10)] = {
        'title': '${varaNames[d.weekday].of(lang)}, ${longDate(lang, d.date)}',
        'line1': dayHeadline(lang, d),
        'line2':
            '${nakshatraNames[d.nakshatra].of(lang)} · ${s.sunrise} ${hm(e, d.sunrise)}',
        'line3': f.isNotEmpty
            ? f.map((o) => o.festival.name.of(lang)).join(', ')
            : '${s.rahu} ${hm(e, d.kaalas.rahu.start)}–${hm(e, d.kaalas.rahu.end)}',
      };
    }
    await HomeWidget.saveWidgetData<String>('days', jsonEncode(data));
    await HomeWidget.saveWidgetData<String>(
      'place',
      settings.place.name.of(lang),
    );
    await HomeWidget.saveWidgetData<String>('stale', s.appTitle);
    await HomeWidget.updateWidget(qualifiedAndroidName: kWidgetProvider);
  }

  static tz.TZDateTime _at(double jd) =>
      tz.TZDateTime.from(dateTimeFromJdUtc(jd), tz.UTC);

  static Future<void> _schedule(
    AppSettings settings,
    PanchangaEngine e,
    List<DayPanchanga> days,
    List<FestivalOccurrence> fest,
  ) async {
    await _plugin.cancelAll();
    if (!settings.dailyNotification &&
        !settings.festivalReminder &&
        !settings.rahuReminder) {
      return;
    }
    final lang = settings.lang, s = S(lang);
    final now = DateTime.now().toUtc();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'panchanga',
        'Panchanga',
        channelDescription: 'Daily panchanga, festivals and Rahu kaala',
        importance: Importance.defaultImportance,
        styleInformation: BigTextStyleInformation(''),
      ),
    );
    var id = 1;
    Future<void> add(double jd, String title, String body) async {
      final when = _at(jd);
      if (when.isBefore(now)) return;
      await _plugin.zonedSchedule(
        id: id++,
        scheduledDate: when,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    }

    for (final d in days) {
      if (settings.dailyNotification) {
        final at = e.jdFromWall(
          DateTime.utc(
            d.date.year,
            d.date.month,
            d.date.day,
            settings.notifyHour,
            settings.notifyMinute,
          ),
        );
        final f = _notable(fest, d.date);
        await add(
          at,
          '${varaNames[d.weekday].of(lang)} · ${dayHeadline(lang, d)}',
          [
            if (f.isNotEmpty) f.map((o) => o.festival.name.of(lang)).join(', '),
            daySummary(s, lang, e, d, withHeader: false),
          ].join('\n'),
        );
      }
      if (settings.festivalReminder) {
        final tomorrow = PanchangaEngine.addDays(d.date, 1);
        final f = _notable(fest, tomorrow);
        if (f.isNotEmpty) {
          await add(
            e.jdFromWall(
              DateTime.utc(d.date.year, d.date.month, d.date.day, 19, 0),
            ),
            '${s.nextDay}: ${f.map((o) => o.festival.name.of(lang)).join(', ')}',
            longDate(lang, tomorrow),
          );
        }
      }
      if (settings.rahuReminder) {
        final r = d.kaalas.rahu;
        await add(r.start, s.rahu, '${hm(e, r.start)} – ${hm(e, r.end)}');
      }
    }
  }
}

/// UTC [DateTime] for a Julian Day.
DateTime dateTimeFromJdUtc(double jd) => DateTime.fromMillisecondsSinceEpoch(
  ((jd - 2440587.5) * 86400000.0).round(),
  isUtc: true,
);

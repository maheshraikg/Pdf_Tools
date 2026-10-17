/// Schedules Azan / Iqama notifications and the auto-silent windows for the
/// coming days. Refreshed whenever the app is opened or settings change.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/alerts.dart';
import '../core/day.dart';
import '../core/prayer_calc.dart';
import 'native.dart';
import 'scope.dart';
import 'settings.dart';
import 'strings.dart';
import 'widget_data.dart';

/// Days scheduled ahead (Android allows ~500 alarms per app; 20 days of
/// reminders + Azan + Iqama for five prayers stays well below that).
const int kScheduleDays = 20;

/// The usual Arabic Niyyah of the Ramadan fast (shown with its meaning).
const String kNiyyahArabic =
    'نَوَيْتُ صَوْمَ غَدٍ عَنْ أَدَاءِ فَرْضِ شَهْرِ رَمَضَانَ هَذِهِ السَّنَةِ لِلّٰهِ تَعَالَى';

/// Notification id of the "open the app" reminder.
const int kKeepAlertsId = 1;
const int kTestId = 2;

/// Android "insistent" flag: the Azan sound repeats until dismissed.
const int _flagInsistent = 4;

class AlertsHealth {
  const AlertsHealth({
    required this.notifications,
    required this.exactAlarms,
    required this.battery,
  });
  final bool notifications, exactAlarms, battery;
  bool get ok => notifications && exactAlarms && battery;
}

class Background {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static Future<void> init() async {
    if (!_supported || _ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_waqt'),
      ),
    );
    _ready = true;
  }

  static Future<AlertsHealth> health() async {
    if (!_supported) {
      return const AlertsHealth(
        notifications: true,
        exactAlarms: true,
        battery: true,
      );
    }
    try {
      await init();
      final a = _android;
      return AlertsHealth(
        notifications: await a?.areNotificationsEnabled() ?? true,
        exactAlarms: await a?.canScheduleExactNotifications() ?? true,
        battery: await Native.isIgnoringBatteryOptimizations(),
      );
    } catch (e) {
      // No platform plugin (tests) or a plugin failure: don't nag.
      debugPrint('Alerts health check failed: $e');
      return const AlertsHealth(
        notifications: true,
        exactAlarms: true,
        battery: true,
      );
    }
  }

  static Future<void> requestNotifications() async {
    if (!_supported) return;
    await init();
    await _android?.requestNotificationsPermission();
  }

  static Future<void> requestExactAlarms() async {
    if (!_supported) return;
    await init();
    await _android?.requestExactAlarmsPermission();
  }

  static NotificationDetails _details(S s, AlertKind kind) =>
      NotificationDetails(
        android: switch (kind) {
          AlertKind.azan => AndroidNotificationDetails(
            'azan',
            s.channelAzan,
            channelDescription: s.channelAzan,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
            timeoutAfter: 3 * 60 * 1000,
            additionalFlags: Int32List.fromList([_flagInsistent]),
          ),
          AlertKind.iqama => AndroidNotificationDetails(
            'iqama',
            s.channelIqama,
            channelDescription: s.channelIqama,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
            timeoutAfter: 30 * 60 * 1000,
          ),
          AlertKind.reminder => AndroidNotificationDetails(
            'reminder',
            s.channelReminder,
            channelDescription: s.channelReminder,
            importance: Importance.defaultImportance,
            category: AndroidNotificationCategory.reminder,
          ),
        },
      );

  /// Re-schedules everything for [settings].
  static Future<void> refresh(AppSettings settings) async {
    if (!_supported) return;
    try {
      await init();
      final s = S(settings.lang);
      final now = DateTime.now().toUtc();
      final days = settings.calculator.days(settings.today, kScheduleDays);
      final config = settings.alerts;
      final plan = planAlerts(days, config, now);
      final exact = await _android?.canScheduleExactNotifications() ?? false;

      await _plugin.cancelAll();
      final playerEvents = <Map<String, Object>>[];
      for (final a in plan) {
        final title = switch (a.kind) {
          _ when a.special != null => s.specialTitle(a.special!),
          _ when a.prayer == Prayer.sunrise => s.sunriseSoon(a.minutesBefore),
          _ when !a.prayer.isFard => s.extraTitle(a.prayer),
          AlertKind.azan => s.azanTitle(a.prayer, a.friday),
          AlertKind.iqama => s.iqamaTitle(a.prayer, a.friday),
          AlertKind.reminder => s.reminderTitle(
            a.prayer,
            a.friday,
            a.minutesBefore,
          ),
        };
        final body = switch (a.kind) {
          _ when a.special == SpecialEvent.taraweeh =>
            '${hm(settings, a.at)} · ${settings.place.label(s.ml)}',
          _ when a.special != null => s.eidPrayerAt(
            hm(settings, a.at.add(Duration(minutes: a.minutesBefore))),
          ),
          _ when a.prayer == Prayer.sunrise =>
            '${s.prayer(Prayer.sunrise)} ${hm(settings, a.at.add(Duration(minutes: a.minutesBefore)))}',
          AlertKind.reminder when a.prayer.isFard =>
            '${s.azan} ${hm(settings, a.at.add(Duration(minutes: a.minutesBefore)))}',
          _ => '${hm(settings, a.at)} · ${settings.place.label(s.ml)}',
        };
        final iqama = a.kind == AlertKind.iqama && a.special == null;
        final sound = switch (a.kind) {
          AlertKind.azan => config.soundFor(a.prayer).playerSound,
          AlertKind.iqama when iqama => config.iqamaSound?.playerSound,
          _ => null,
        };
        if (sound != null) {
          // The native player shows its own notification with Stop.
          playerEvents.add({
            'at': a.at.millisecondsSinceEpoch,
            'title': title,
            'body': body,
            'sound': sound,
            'volume': iqama ? config.iqamaVolume : config.azanVolume,
            'full': iqama ? config.iqamaFullScreen : config.fullScreen,
          });
          continue;
        }
        await _plugin.zonedSchedule(
          id: a.id,
          scheduledDate: tz.TZDateTime.from(a.at, tz.UTC),
          notificationDetails: _details(s, a.kind),
          // alarmClock is exact even in Doze; without the exact-alarm
          // permission fall back to inexact so nothing throws.
          androidScheduleMode: exact
              ? (a.kind == AlertKind.reminder
                    ? AndroidScheduleMode.exactAllowWhileIdle
                    : AndroidScheduleMode.alarmClock)
              : AndroidScheduleMode.inexactAllowWhileIdle,
          title: title,
          body: body,
        );
      }
      // Ask the user to open the app before the schedule runs out.
      final last = days.last[Prayer.dhuhr].subtract(const Duration(days: 1));
      if (last.isAfter(now)) {
        await _plugin.zonedSchedule(
          id: kKeepAlertsId,
          scheduledDate: tz.TZDateTime.from(last, tz.UTC),
          notificationDetails: _details(s, AlertKind.reminder),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: s.keepAlertsTitle,
          body: s.keepAlertsBody,
        );
      }

      await Native.setAzanAlarms(
        playerEvents,
        vibrate: config.vibrate,
        playWhenSilent: config.playWhenSilent,
        stopLabel: s.stop,
        channelName: s.channelAzan,
        fullScreen: config.fullScreen,
      );
      await Native.setNotices(
        [
          for (final n in planNotices(days, config, now))
            {
              'id': n.kind.index * 100 + n.at.day,
              'at': n.at.millisecondsSinceEpoch,
              'latest': n.latest.millisecondsSinceEpoch,
              ...switch (n.kind) {
                NoticeKind.niyyah => {
                  'title': s.niyyahTitle,
                  'text': '${s.niyyahText}\n$kNiyyahArabic',
                  'done': s.iDidNiyyah,
                },
                NoticeKind.friday => {
                  'title': s.fridayTitle,
                  'text': s.fridayText,
                  'done': s.ok,
                },
              },
            },
        ],
        laterLabel: s.remindLater,
        channelName: s.channelReminder,
      );
      await Native.updateWidget(widgetJson(settings, days));
      await Native.setStatusStates(
        settings.statusNotification ? statusStates(settings, days, now) : [],
        s.channelNextPrayer,
      );

      final silent = planSilent(days, config, now);
      var mode = config.silentMode;
      if (mode == SilentMode.silent && !await Native.hasDndAccess()) {
        mode = SilentMode.vibrate;
      }
      await Native.setSilentWindows(silent, mode);
    } catch (e, st) {
      debugPrint('Background refresh failed: $e\n$st');
    }
  }

  static Future<void> testAlert(AppSettings settings) async {
    if (!_supported) return;
    await init();
    final s = S(settings.lang);
    final sound = settings.alerts.soundFor(Prayer.fajr).playerSound;
    if (sound != null) {
      await Native.playSound(
        sound,
        s.azanTitle(Prayer.fajr, false),
        '${hm(settings, DateTime.now())} · ${settings.place.label(s.ml)}',
      );
      return;
    }
    await _plugin.show(
      id: kTestId,
      title: s.azanTitle(Prayer.fajr, false),
      body: '${hm(settings, DateTime.now())} · ${settings.place.label(s.ml)}',
      notificationDetails: _details(s, AlertKind.azan),
    );
  }
}

/// States of the permanent notification: from each Azan or Iqama (and from
/// now) until the next one, the next Azan (with a countdown to it) and the
/// next Iqama.
List<Map<String, Object>> statusStates(
  AppSettings settings,
  List<PrayerDay> days,
  DateTime now,
) {
  final s = S(settings.lang);
  final azans = <(DateTime, Prayer, bool)>[];
  final iqamas = <(DateTime, Prayer, bool)>[];
  for (final d in days) {
    for (final p in Prayer.fard) {
      azans.add((d[p], p, d.isFriday));
      iqamas.add((iqamaTime(d, p, settings.alerts), p, d.isFriday));
    }
  }
  azans.sort((a, b) => a.$1.compareTo(b.$1));
  iqamas.sort((a, b) => a.$1.compareTo(b.$1));
  final where = [
    if (settings.masjid != null) settings.masjid!.name,
    settings.place.label(s.ml),
  ].join(' · ');
  final starts = <DateTime>{
    now,
    for (final a in azans) a.$1,
    for (final i in iqamas) i.$1,
  }.where((t) => !t.isBefore(now)).toList()..sort();
  final out = <Map<String, Object>>[];
  for (final t in starts) {
    final a = azans.where((x) => x.$1.isAfter(t)).firstOrNull;
    final i = iqamas.where((x) => x.$1.isAfter(t)).firstOrNull;
    if (a == null) break;
    out.add({
      'from': t.millisecondsSinceEpoch,
      'countdown': a.$1.millisecondsSinceEpoch,
      'title': s.statusNextAzan(
        s.prayer(a.$2, friday: a.$3),
        hm(settings, a.$1),
      ),
      'text': [
        if (i != null)
          s.statusNextIqama(s.prayer(i.$2, friday: i.$3), hm(settings, i.$1)),
        where,
      ].join('\n'),
    });
  }
  return out;
}

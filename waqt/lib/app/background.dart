/// Schedules Azan / Iqama notifications and the auto-silent windows for the
/// coming days. Refreshed whenever the app is opened or settings change.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/alerts.dart';
import '../core/prayer_calc.dart';
import 'native.dart';
import 'scope.dart';
import 'settings.dart';
import 'strings.dart';
import 'widget_data.dart';

/// Days scheduled ahead (Android allows ~500 alarms per app; 20 days of
/// reminders + Azan + Iqama for five prayers stays well below that).
const int kScheduleDays = 20;

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
      for (final a in plan) {
        final title = switch (a.kind) {
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
          AlertKind.reminder when a.prayer.isFard =>
            '${s.azan} ${hm(settings, a.at.add(Duration(minutes: a.minutesBefore)))}',
          _ => '${hm(settings, a.at)} · ${settings.place.label(s.ml)}',
        };
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

      await Native.updateWidget(widgetJson(settings, days));

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
    await _plugin.show(
      id: kTestId,
      title: s.azanTitle(Prayer.fajr, false),
      body: '${hm(settings, DateTime.now())} · ${settings.place.label(s.ml)}',
      notificationDetails: _details(s, AlertKind.azan),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';

/// The daily reminder, always scheduled in India Standard Time.
///
/// The reminder repeats every day at the same wall-clock time
/// (`matchDateTimeComponents: time`) and is restored after a phone restart
/// by the plugin's boot receiver (see AndroidManifest.xml). The app also
/// re-schedules it on every launch.
class NotificationService {
  static const zoneName = 'Asia/Kolkata';
  static const _reminderId = 1;
  static const _channelId = 'daily_reminder';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static void initTimeZones() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(zoneName));
  }

  static tz.Location get zone => tz.getLocation(zoneName);

  /// The next time [hour]:[minute] happens in Asia/Kolkata after [now].
  static tz.TZDateTime nextInstance(int hour, int minute, {DateTime? now}) {
    final n = tz.TZDateTime.from(now ?? DateTime.now(), zone);
    var t = tz.TZDateTime(zone, n.year, n.month, n.day, hour, minute);
    if (!t.isAfter(n)) t = tz.TZDateTime(zone, n.year, n.month, n.day + 1, hour, minute);
    return t;
  }

  Future<void> init() async {
    if (_ready) return;
    try {
      initTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('ic_notification')),
      );
      _ready = true;
    } catch (e) {
      debugPrint('notifications unavailable: $e');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  /// Asks for permission (Android 13+). Returns false if the parent refused.
  Future<bool> requestPermission() async {
    await init();
    try {
      return await _android?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Schedules (or replaces) the daily reminder in the app language.
  Future<void> scheduleDaily({required int hour, required int minute, required Locale locale}) async {
    await init();
    if (!_ready) return;
    final l = lookupAppLocalizations(locale);
    try {
      await _plugin.cancel(id: _reminderId);
      // Exact alarms are used where the phone allows them without a special
      // permission (Android 11 and older); otherwise an inexact alarm, which
      // Android may delay by a few minutes to save battery.
      final exact = await _android?.canScheduleExactNotifications() ?? false;
      await _plugin.zonedSchedule(
        id: _reminderId,
        title: l.appTitle,
        body: l.reminderBody,
        scheduledDate: nextInstance(hour, minute),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            l.reminderChannel,
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFFFF7A00),
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('schedule failed: $e');
    }
  }

  Future<void> cancelDaily() async {
    await init();
    try {
      await _plugin.cancel(id: _reminderId);
    } catch (_) {}
  }
}

/// Does nothing (widget tests).
class NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> scheduleDaily({required int hour, required int minute, required Locale locale}) async {}
  @override
  Future<void> cancelDaily() async {}
}

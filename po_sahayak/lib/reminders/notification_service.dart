/// Maturity reminders: a notification 7 days and 1 day before maturity, at
/// 9 am. Inexact alarms only (no exact-alarm permission, which Play
/// restricts); the plugin's boot receiver restores them after a restart, and
/// they are rescheduled every time the app starts.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../app/format.dart';
import '../app/strings.dart';
import '../data/saved_account_repository.dart';

class NotificationService {
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

  /// Asks for the Android 13+ notification permission (only when the user
  /// turns a reminder on).
  static Future<bool> requestPermission() async {
    if (!_supported) return true;
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  /// Replaces all scheduled reminders with those for [accounts].
  static Future<void> reschedule(List<SavedAccount> accounts, S s) async {
    if (!_supported) return;
    try {
      await init();
      await _plugin.cancelAll();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'maturity',
          s.reminderChannel,
          importance: Importance.defaultImportance,
        ),
      );
      final now = DateTime.now();
      var id = 1;
      for (final a in accounts.where((a) => a.remind)) {
        final m = a.result.maturityDate;
        for (final daysBefore in const [7, 1]) {
          final at = DateTime(m.year, m.month, m.day - daysBefore, 9);
          if (at.isBefore(now)) continue;
          await _plugin.zonedSchedule(
            id: id++,
            scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: s.reminderTitle(a.name),
            body: s.reminderBody(dmy(m), rupee(a.result.maturityValue)),
          );
        }
      }
    } catch (e, st) {
      debugPrint('Reminder scheduling failed: $e\n$st');
    }
  }
}

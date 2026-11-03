/// Local reminders for credit card due dates and upcoming recurring entries.
/// They are recalculated from the ledger whenever the app opens or the data
/// changes, so they always match what the app shows.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../ledger/ledger.dart';
import '../models/models.dart';
import '../models/money.dart';
import 'store.dart';
import '../l10n/strings.dart';

/// Hour of day (local time) at which reminders are shown.
const int kReminderHour = 9;

/// Days before a card's due date to remind (0 = on the due date).
const List<int> kCardReminderDays = [7, 3, 0];

/// A reminder to schedule; kept separate from the plugin so it can be tested.
class PlannedReminder {
  const PlannedReminder(this.when, this.title, this.body);
  final DateTime when;
  final String title;
  final String body;
}

/// Reminders for the coming [horizonDays] after [now] (local time).
List<PlannedReminder> planReminders(
  Ledger l,
  DateTime now, {
  int horizonDays = 45,
}) {
  final today = dateOnly(now);
  final end = today.add(Duration(days: horizonDays));
  final result = <PlannedReminder>[];
  DateTime at(DateTime day) =>
      DateTime(day.year, day.month, day.day, kReminderHour);

  for (final c in l.cards) {
    final s = l.cardStatus(c, today);
    if (s.amountDue <= 0 || s.overdue) continue;
    for (final before in kCardReminderDays) {
      final day = s.dueDate.subtract(Duration(days: before));
      final when = at(day);
      if (!when.isAfter(now) || day.isAfter(end)) continue;
      result.add(
        PlannedReminder(
          when,
          before == 0
              ? tr('{0} bill due today', [c.displayName])
              : tr('{0} bill due in {1} days', [c.displayName, before]),
          tr('{0} to pay by {1}. Tap to record the payment.', [
            formatRupees(s.amountDue),
            _short(s.dueDate),
          ]),
        ),
      );
    }
  }

  for (final r in l.recurring) {
    if (!r.active) continue;
    var d = r.nextDate;
    while (!d.isAfter(end)) {
      final when = at(d);
      if (when.isAfter(now)) {
        final t = r.template;
        final name =
            t.note ?? (t.category != null ? tr(t.category!) : t.type.label);
        result.add(
          PlannedReminder(
            when,
            '$name · ${formatRupees(t.amount)}',
            tr('This {0} is recorded automatically today.', [
              t.type.label.toLowerCase(),
            ]),
          ),
        );
      }
      d = r.after(d);
    }
  }
  result.sort((a, b) => a.when.compareTo(b.when));
  return result;
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
String _short(DateTime d) => '${d.day} ${tr(_months[d.month - 1])}';

class Reminders {
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

  /// Replaces all scheduled reminders with the current plan.
  static Future<void> refresh(FinanceStore store) async {
    if (!_supported) return;
    try {
      await init();
      await _plugin.cancelAll();
      if (!store.notifications) return;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders',
          tr('Bill and payment reminders'),
          channelDescription: tr(
            'Credit card due dates and recurring payments',
          ),
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      var id = 1;
      // Android caps pending alarms per app; the nearest ones matter most.
      for (final r in planReminders(store.ledger, DateTime.now()).take(60)) {
        await _plugin.zonedSchedule(
          id: id++,
          scheduledDate: tz.TZDateTime.from(r.when.toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: r.title,
          body: r.body,
        );
      }
    } catch (e, st) {
      debugPrint('Reminder refresh failed: $e\n$st');
    }
  }
}

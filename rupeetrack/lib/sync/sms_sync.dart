import 'package:permission_handler/permission_handler.dart';

import '../app/native.dart';
import '../app/store.dart';
import 'bank_messages.dart';
import 'sync.dart';

/// Reads bank SMS from the inbox and applies them to the store. Messages are
/// parsed on the phone; nothing is uploaded.
class SmsSync {
  /// How far back a scan looks.
  static const historyDays = 180;

  static Future<bool> hasPermission() async {
    if (!Native.supported) return false;
    try {
      return await Permission.sms.isGranted;
    } on Exception {
      return false;
    }
  }

  /// Asks for SMS access. Returns false if refused; when refused for good
  /// the user has to allow it in system settings ([openSettings]).
  static Future<bool> requestPermission() async {
    if (!Native.supported) return false;
    return (await Permission.sms.request()).isGranted;
  }

  static Future<bool> isPermanentlyDenied() async =>
      Native.supported && await Permission.sms.isPermanentlyDenied;

  static Future<void> openSettings() => openAppSettings();

  /// Bank alerts come from alphanumeric sender ids ("AD-HDFCBK"), never from
  /// personal numbers; ignoring the latter also avoids forwarded or fake
  /// messages.
  static bool _fromBankSender(String sender) =>
      RegExp('[A-Za-z]').hasMatch(sender);

  /// Parses [messages] into events (pure; used by [run] and tests).
  static List<SourcedEvent> eventsFrom(List<SmsMessage> messages) => [
    for (final m in messages)
      if (_fromBankSender(m.sender))
        if (parseBankMessage(m.body, received: m.received, sender: m.sender)
            case final e?)
          SourcedEvent(
            'sms:${stableHash('${m.sender}|${m.received.millisecondsSinceEpoch}|${m.body}')}',
            e,
          ),
  ];

  /// Scans the last [historyDays] of SMS and saves what is new.
  static Future<SyncResult> run(FinanceStore store) async {
    final messages = await Native.readSms(
      since: DateTime.now().subtract(const Duration(days: historyDays)),
    );
    final result = store.planEvents(eventsFrom(messages), source: 'SMS');
    await store.applySync(result);
    return result;
  }
}

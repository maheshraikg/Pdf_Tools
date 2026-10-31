import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to MainActivity.kt.
class Native {
  static const _channel = MethodChannel('rupeetrack/native');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Opens the app; returns false (after opening its Play Store page) when
  /// it is not installed.
  static Future<bool> openApp(String package) async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('openApp', {'package': package}) ??
        false;
  }

  static Future<bool> isInstalled(String package) async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('isInstalled', {
            'package': package,
          }) ??
          false;
    } on Exception {
      // No native side (tests, other platforms).
      return false;
    }
  }

  /// Inbox SMS newer than [since], newest first. Throws [PlatformException]
  /// with code "permission" when SMS access has not been granted.
  static Future<List<SmsMessage>> readSms({
    DateTime? since,
    int limit = 5000,
  }) async {
    if (!supported) return const [];
    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'readSms',
      {'since': since?.millisecondsSinceEpoch ?? 0, 'limit': limit},
    );
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        SmsMessage(
          sender: (m['address'] as String?) ?? '',
          body: (m['body'] as String?) ?? '',
          received: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        ),
    ];
  }
}

class SmsMessage {
  const SmsMessage({
    required this.sender,
    required this.body,
    required this.received,
  });
  final String sender;
  final String body;
  final DateTime received;
}

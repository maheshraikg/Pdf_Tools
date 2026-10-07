import 'package:flutter/services.dart';

/// Whether the Tulu system keyboard is turned on / chosen on this phone.
class KeyboardStatus {
  const KeyboardStatus({this.enabled = false, this.selected = false});

  final bool enabled;
  final bool selected;
}

/// Talks to the Android side (MainActivity) about the system keyboard
/// (android/.../keyboard/TuluKeyboardService.kt).
class SystemKeyboard {
  static const _channel = MethodChannel('tulu_nighantu/keyboard');

  static Future<KeyboardStatus> status() async {
    try {
      final m = await _channel.invokeMapMethod<String, bool>('status');
      return KeyboardStatus(
        enabled: m?['enabled'] ?? false,
        selected: m?['selected'] ?? false,
      );
    } on Exception {
      return const KeyboardStatus();
    }
  }

  /// Opens Settings › On-screen keyboards, where the keyboard is turned on.
  static Future<void> openSettings() => _call('openSettings');

  /// Shows the system "choose keyboard" picker.
  static Future<void> showPicker() => _call('showPicker');

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on Exception {
      // Not available (tests, other platforms).
    }
  }
}

import 'package:flutter/services.dart';

/// Whether the Tulu system keyboard is turned on / chosen on this phone.
class KeyboardStatus {
  const KeyboardStatus({this.enabled = false, this.selected = false});

  final bool enabled;
  final bool selected;
}

/// Keyboard settings (stored on the Android side, KeyboardPrefs.kt).
class KeyboardSettings {
  const KeyboardSettings({
    this.vibrate = true,
    this.sound = false,
    this.stickerLabel = true,
  });

  factory KeyboardSettings.fromMap(Map<String, bool>? m) => KeyboardSettings(
    vibrate: m?['vibrate'] ?? true,
    sound: m?['sound'] ?? false,
    stickerLabel: m?['stickerLabel'] ?? true,
  );

  final bool vibrate;
  final bool sound;

  /// Adds a small "Tulu Nighantu" line under sticker text.
  final bool stickerLabel;

  KeyboardSettings copyWith({bool? vibrate, bool? sound, bool? stickerLabel}) =>
      KeyboardSettings(
        vibrate: vibrate ?? this.vibrate,
        sound: sound ?? this.sound,
        stickerLabel: stickerLabel ?? this.stickerLabel,
      );

  Map<String, bool> toMap() => {
    'vibrate': vibrate,
    'sound': sound,
    'stickerLabel': stickerLabel,
  };
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

  static Future<KeyboardSettings> settings() async {
    try {
      return KeyboardSettings.fromMap(
        await _channel.invokeMapMethod<String, bool>('getPrefs'),
      );
    } on Exception {
      return const KeyboardSettings();
    }
  }

  static Future<void> saveSettings(KeyboardSettings s) async {
    try {
      await _channel.invokeMethod<void>('setPrefs', s.toMap());
    } on Exception {
      // Not available (tests, other platforms).
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

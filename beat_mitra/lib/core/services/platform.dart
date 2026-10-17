import 'package:flutter/services.dart';

/// Small native bridge (see MainActivity.kt): FLAG_SECURE to block
/// screenshots / screen recording when the user asks for it.
class PlatformBridge {
  static const _ch = MethodChannel('beat_mitra/window');

  static Future<void> setSecure(bool secure) async {
    try {
      await _ch.invokeMethod('setSecure', secure);
    } on MissingPluginException {
      // Tests / unsupported platform.
    } on PlatformException {
      // ignore
    }
  }
}

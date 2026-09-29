/// Haptics and optional text-to-speech read-out (device TTS engine, offline).
library;

import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'settings.dart';

class AppFeedback {
  AppFeedback._();

  static FlutterTts? _tts;

  static Future<void> tap(Settings s) async {
    if (s.hapticsEnabled) await HapticFeedback.selectionClick();
  }

  static Future<void> success(Settings s) async {
    if (s.hapticsEnabled) await HapticFeedback.mediumImpact();
  }

  static Future<void> warning(Settings s) async {
    if (s.hapticsEnabled) await HapticFeedback.heavyImpact();
  }

  /// Speaks [text] when TTS is on (or [force]). Language follows the app
  /// language; falls back silently if the engine lacks it.
  static Future<void> speak(Settings s, String text, {String lang = 'en', bool force = false}) async {
    if (!s.ttsEnabled && !force) return;
    try {
      final tts = _tts ??= FlutterTts();
      final code = switch (lang) { 'kn' => 'kn-IN', 'hi' => 'hi-IN', _ => 'en-IN' };
      if (await tts.isLanguageAvailable(code) == true) {
        await tts.setLanguage(code);
      } else {
        await tts.setLanguage('en-IN');
      }
      await tts.setSpeechRate(0.45);
      await tts.stop();
      await tts.speak(text);
    } on Object {
      // TTS is optional; ignore engines that are missing or fail.
    }
  }

  /// "BLR" → "B L R" so TTS spells codes letter by letter.
  static String spell(String code) => code.split('').join(' ');

  /// "Bag 12" → "Bag twelve" is left to the TTS engine; digits groups are
  /// spaced so PINs are read digit by digit ("5 7 4 2 0 1").
  static String spellDigits(String s) => s.replaceAllMapped(RegExp(r'\d{4,}'), (m) => m[0]!.split('').join(' '));
}

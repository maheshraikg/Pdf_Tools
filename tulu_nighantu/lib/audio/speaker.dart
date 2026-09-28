import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Pronunciation through the phone's own text-to-speech engine.
///
/// Tulu is written here in Kannada script, so a Kannada (kn-IN) voice gives
/// a close, approximate pronunciation. Nothing is sent over the network by
/// the app; the Android TTS engine speaks on the device.
///
/// When native-speaker recordings are added (see README), play those first
/// and fall back to this.
class Speaker {
  Speaker._();

  /// The singleton instance.
  static final Speaker instance = Speaker._();

  /// BCP-47 language of the voice used for Tulu/Kannada text.
  static const String language = 'kn-IN';

  FlutterTts? _tts;
  bool? _available;

  /// Speaks [text]. Returns false when no Kannada voice is installed or TTS
  /// is unavailable, so the caller can show a hint.
  Future<bool> speak(String text) async {
    final t = text.replaceAll('...', '').trim();
    if (t.isEmpty) return true;
    try {
      final tts = _tts ??= FlutterTts();
      if (_available == null) {
        final ok = await tts.isLanguageAvailable(language);
        _available = ok == true || ok == 1;
        await tts.setLanguage(language);
        await tts.setSpeechRate(0.4);
        await tts.setPitch(1.0);
      }
      await tts.stop();
      await tts.speak(t);
      return _available!;
    } catch (e) {
      debugPrint('TTS unavailable: $e');
      return false;
    }
  }

  /// Stops any speech in progress.
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

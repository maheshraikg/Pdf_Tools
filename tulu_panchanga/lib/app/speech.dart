import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../panchanga/names.dart';

/// Reads text aloud with the phone's own text-to-speech engine (offline).
///
/// Kannada and Tulu (written in Kannada script) use a Kannada (kn-IN) voice;
/// no TTS engine has a Tulu voice, so Tulu is read with Kannada sounds.
class Speech {
  Speech._();
  static final Speech instance = Speech._();

  /// True while speaking (drives the play/stop button).
  final ValueNotifier<bool> speaking = ValueNotifier(false);

  FlutterTts? _tts;
  String? _lang;

  static String voiceFor(Lang lang) => lang == Lang.en ? 'en-IN' : 'kn-IN';

  /// Speaks [text]; returns false if no voice for [lang] is installed.
  Future<bool> speak(String text, Lang lang) async {
    final t = text
        .replaceAll('→', ',')
        .replaceAll('·', ',')
        .replaceAll('–', ' - ')
        .replaceAll('\n', '. ')
        .trim();
    if (t.isEmpty) return true;
    try {
      final tts = _tts ??= _create();
      final voice = voiceFor(lang);
      var ok = true;
      if (_lang != voice) {
        final available = await tts.isLanguageAvailable(voice);
        ok = available == true || available == 1;
        await tts.setLanguage(ok ? voice : 'en-IN');
        await tts.setSpeechRate(0.45);
        await tts.setPitch(1.0);
        _lang = voice;
      }
      await tts.stop();
      speaking.value = true;
      await tts.speak(t);
      return ok;
    } catch (e) {
      debugPrint('TTS unavailable: $e');
      speaking.value = false;
      return false;
    }
  }

  FlutterTts _create() {
    final tts = FlutterTts();
    void done() => speaking.value = false;
    tts.setCompletionHandler(done);
    tts.setCancelHandler(done);
    tts.setErrorHandler((_) => done());
    return tts;
  }

  Future<void> stop() async {
    speaking.value = false;
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

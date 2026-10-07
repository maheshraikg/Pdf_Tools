import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Pronunciation through the phone's own text-to-speech engine.
///
/// Tulu is written here in Kannada script, so a Kannada (kn-IN) voice gives
/// a close, approximate pronunciation. Nothing is sent over the network by
/// the app; the Android TTS engine speaks on the device.
///
/// Native-speaker recordings listed in `assets/audio/index.json` are played
/// first when they exist (see README); everything else uses TTS.
class Speaker {
  Speaker._();

  /// The singleton instance.
  static final Speaker instance = Speaker._();

  /// BCP-47 language of the voice used for Tulu/Kannada text.
  static const String language = 'kn-IN';

  FlutterTts? _tts;
  bool? _available;
  AudioPlayer? _player;

  /// Kannada-script text -> file name in assets/audio/.
  Map<String, String>? _recordings;

  /// Sets the recordings index (tests).
  @visibleForTesting
  void debugSetRecordings(Map<String, String> files) => _recordings = files;

  /// The recording for [text], if one was added.
  String? recordingFor(String text) =>
      _recordings?[text.replaceAll('...', '').trim()];

  Future<void> _loadRecordings() async {
    if (_recordings != null) return;
    try {
      final j = jsonDecode(
        await rootBundle.loadString('assets/audio/index.json'),
      ) as Map<String, dynamic>;
      _recordings = (j['files'] as Map<String, dynamic>? ?? const {}).map(
        (k, v) => MapEntry(k.trim(), v as String),
      );
    } catch (e) {
      _recordings = const {};
    }
  }

  /// Speaks [text]: a native-speaker recording when there is one, otherwise
  /// TTS. Returns false when no Kannada voice is installed or TTS is
  /// unavailable, so the caller can show a hint.
  Future<bool> speak(String text) async {
    final t = text.replaceAll('...', '').trim();
    if (t.isEmpty) return true;
    await _loadRecordings();
    final file = recordingFor(t);
    if (file != null) {
      try {
        await _tts?.stop();
        final p = _player ??= AudioPlayer();
        await p.stop();
        await p.play(AssetSource('audio/$file'));
        return true;
      } catch (e) {
        debugPrint('Recording failed, using TTS: $e');
      }
    }
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
      await _player?.stop();
    } catch (_) {}
  }
}

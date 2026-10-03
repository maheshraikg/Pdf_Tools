import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech input and read-aloud. Both use the phone's own engines; on-device
/// recognition is preferred, but some phones need their offline language
/// pack installed (see README).
abstract class VoiceService {
  Future<bool> get speechAvailable;

  /// Listens once and returns the recognised text (null if cancelled).
  Future<String?> listenOnce(String languageCode, {void Function(String partial)? onPartial});
  Future<void> stopListening();
  Future<void> speak(String text, String languageCode);
}

String _speechLocale(String lang) => switch (lang) {
  'kn' => 'kn_IN',
  'hi' => 'hi_IN',
  _ => 'en_IN',
};

class DeviceVoiceService implements VoiceService {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool? _ready;

  Future<bool> _init() async {
    _ready ??= await _stt.initialize(onError: (_) {}, onStatus: (_) {});
    return _ready!;
  }

  @override
  Future<bool> get speechAvailable => _init();

  @override
  Future<String?> listenOnce(String languageCode, {void Function(String partial)? onPartial}) async {
    if (!await _init()) return null;
    final done = Completer<String?>();
    var last = '';
    await _stt.listen(
      onResult: (r) {
        last = r.recognizedWords;
        onPartial?.call(last);
        if (r.finalResult && !done.isCompleted) done.complete(last);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.search,
        localeId: _speechLocale(languageCode),
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
    );
    // Safety timeout.
    return done.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () async {
        await _stt.stop();
        return last.isEmpty ? null : last;
      },
    );
  }

  @override
  Future<void> stopListening() => _stt.stop();

  @override
  Future<void> speak(String text, String languageCode) async {
    await _tts.setLanguage(switch (languageCode) {
      'kn' => 'kn-IN',
      'hi' => 'hi-IN',
      _ => 'en-IN',
    });
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }
}

class SilentVoiceService implements VoiceService {
  final List<String> spoken = [];
  String? nextHeard;
  @override
  Future<bool> get speechAvailable async => nextHeard != null;
  @override
  Future<String?> listenOnce(String languageCode, {void Function(String partial)? onPartial}) async => nextHeard;
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> speak(String text, String languageCode) async => spoken.add(text);
}

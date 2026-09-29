/// Voice input for PINs (speech_to_text uses the phone's speech service; it
/// works offline when the language pack is downloaded on the device).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'l10n/app_localizations.dart';
import 'voice.dart';

final SpeechToText _speech = SpeechToText();
bool _ready = false;

/// Listens once and returns the recognised digits (may be empty), or null
/// when speech recognition is unavailable / cancelled.
Future<String?> listenForDigits(BuildContext context, {required String languageCode}) async {
  final l = AppLocalizations.of(context);
  try {
    _ready = _ready || await _speech.initialize();
  } on Object {
    _ready = false;
  }
  if (!context.mounted) return null;
  if (!_ready) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.voiceUnavailable)));
    return null;
  }
  final locale = switch (languageCode) { 'kn' => 'kn_IN', 'hi' => 'hi_IN', _ => 'en_IN' };
  final heard = ValueNotifier<String>('');
  final done = Completer<String?>();
  await _speech.listen(
    listenOptions: SpeechListenOptions(
      localeId: locale,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
    ),
    onResult: (r) {
      heard.value = r.recognizedWords;
      if (r.finalResult && !done.isCompleted) done.complete(spokenToDigits(r.recognizedWords));
    },
  );
  if (!context.mounted) return null;
  final dialog = showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Row(children: [const Icon(Icons.mic, size: 32), const SizedBox(width: 8), Text(l.listening)]),
      content: ValueListenableBuilder<String>(
        valueListenable: heard,
        builder: (_, v, _) => Text(v.isEmpty ? l.sayPin : '$v\n→ ${spokenToDigits(v)}', style: const TextStyle(fontSize: 22)),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _speech.stop();
            if (!done.isCompleted) done.complete(spokenToDigits(heard.value));
          },
          child: Text(l.done),
        ),
      ],
    ),
  );
  unawaited(dialog.then((_) {
    if (!done.isCompleted) {
      _speech.cancel();
      done.complete(null);
    }
  }));
  final result = await done.future.timeout(const Duration(seconds: 12), onTimeout: () => spokenToDigits(heard.value));
  if (context.mounted) Navigator.of(context, rootNavigator: true).popUntil((r) => r is! DialogRoute);
  return result;
}

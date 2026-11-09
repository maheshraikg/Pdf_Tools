import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../models/question.dart';

enum Sfx { correct, wrong, pop, coin, badge, chest, tap, win }

/// Background music loops (`assets/audio/music/<name>.ogg`).
enum MusicTrack { menu, game }

/// Plays sound effects and spoken numbers/table lines from assets/audio/.
///
/// File layout (see README "Replacing audio files"):
/// * `assets/audio/sfx/<name>.ogg`
/// * `assets/audio/<lang>/n_<0-100>.ogg` – spoken numbers
/// * `assets/audio/<lang>/tables/t<a>_<b>.ogg` – "a times b is a×b"
class AudioService {
  AudioService({this.enabled = true});

  /// Sound effects and voice on/off (Settings).
  bool enabled;

  /// Background music on/off (Settings).
  bool musicEnabled = true;

  AudioPlayer? _music;
  MusicTrack? _track;
  bool _musicPaused = false;

  /// Starts (or switches to) a looping background track.
  Future<void> playMusic(MusicTrack track) async {
    _track = track;
    if (!musicEnabled || _musicPaused) return;
    try {
      final p = _music ??= AudioPlayer();
      await p.setLoopMode(LoopMode.one);
      await p.setVolume(0.35);
      await p.setAsset('assets/audio/music/${track.name}.ogg');
      if (_track == track) unawaited(p.play());
    } catch (e) {
      debugPrint('music failed: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  /// App went to the background.
  Future<void> pauseMusic() async {
    _musicPaused = true;
    try {
      await _music?.pause();
    } catch (_) {}
  }

  /// App came back.
  Future<void> resumeMusic() async {
    _musicPaused = false;
    if (!musicEnabled || _track == null) return;
    try {
      if (_music?.audioSource == null) {
        await playMusic(_track!);
      } else {
        unawaited(_music!.play());
      }
    } catch (_) {}
  }

  MusicTrack? get currentTrack => _track;

  AudioPlayer? _sfx;
  AudioPlayer? _voice;
  int _voiceToken = 0;

  Future<void> sfx(Sfx s) async {
    if (!enabled) return;
    try {
      final p = _sfx ??= AudioPlayer();
      await p.setAsset('assets/audio/sfx/${s.name}.ogg');
      unawaited(p.play());
    } catch (e) {
      debugPrint('sfx failed: $e');
    }
  }

  /// Speaks [n] (0–100) in [lang] ('kn' or 'en').
  Future<void> number(int n, String lang) async {
    if (n < 0 || n > 100) return;
    await _speak('assets/audio/$lang/n_$n.ogg');
  }

  /// After a wrong answer: a soft sound, then the right answer spoken
  /// (answers 0–100 that have a number clip).
  Future<void> wrongThenAnswer(Answer answer, String lang) async {
    await sfx(Sfx.wrong);
    if (answer.remainder != null || answer.value > 100) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await number(answer.value, lang);
  }

  /// Speaks one line of a table, e.g. "7 times 8 is 56". Completes when the
  /// clip has finished (or was stopped).
  Future<void> tableLine(int a, int b, String lang) => _speak('assets/audio/$lang/tables/t${a}_$b.ogg');

  Future<void> _speak(String asset) async {
    if (!enabled) return;
    final token = ++_voiceToken;
    try {
      final p = _voice ??= AudioPlayer();
      await p.stop();
      await p.setAsset(asset);
      if (token != _voiceToken) return;
      unawaited(p.play());
      await p.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed || token != _voiceToken)
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('voice failed: $e');
    }
  }

  Future<void> stopVoice() async {
    _voiceToken++;
    try {
      await _voice?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _sfx?.dispose();
    await _music?.dispose();
    await _voice?.dispose();
  }
}

/// No sound at all (widget tests).
class SilentAudioService extends AudioService {
  SilentAudioService() : super(enabled: false);

  @override
  Future<void> sfx(Sfx s) async {}

  @override
  Future<void> playMusic(MusicTrack track) async {}

  @override
  Future<void> pauseMusic() async {}

  @override
  Future<void> resumeMusic() async {}

  @override
  Future<void> stopMusic() async {}

  @override
  Future<void> tableLine(int a, int b, String lang) => Future.delayed(const Duration(milliseconds: 10));

  @override
  Future<void> number(int n, String lang) async {}

  @override
  Future<void> wrongThenAnswer(Answer answer, String lang) async {}
}

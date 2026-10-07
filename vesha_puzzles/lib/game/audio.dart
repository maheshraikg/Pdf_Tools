/// Sound effects and optional background music. Failures (missing files,
/// no audio device in tests) are swallowed: audio is never essential.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Sfx { pick, snap, place, complete, tap, unlock }

class AudioService {
  AudioService({this.enabled = true});

  /// False in widget tests (no platform channels).
  final bool enabled;
  bool sfxOn = true;
  bool musicOn = false;
  double volume = 0.8;
  bool hapticsOn = true;

  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _music;

  static String _file(Sfx s) => 'audio/${s.name}.wav';

  void configure({
    required bool sfx,
    required bool music,
    required double volume,
    required bool haptics,
  }) {
    sfxOn = sfx;
    this.volume = volume;
    hapticsOn = haptics;
    if (music != musicOn) {
      musicOn = music;
      music ? _startMusic() : _stopMusic();
    } else {
      _music?.setVolume(volume * 0.4);
    }
  }

  Future<void> play(Sfx s) async {
    if (hapticsOn && enabled) {
      switch (s) {
        case Sfx.snap || Sfx.place:
          HapticFeedback.lightImpact();
        case Sfx.complete || Sfx.unlock:
          HapticFeedback.mediumImpact();
        default:
      }
    }
    if (!sfxOn || !enabled) return;
    try {
      if (_pool.length < 4) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        _pool.add(p);
      }
      final p = _pool[_next++ % _pool.length];
      await p.stop();
      await p.play(AssetSource(_file(s)), volume: volume);
    } catch (e) {
      debugPrint('sfx failed: $e');
    }
  }

  Future<void> _startMusic() async {
    if (!enabled) return;
    try {
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.play(
        AssetSource('audio/music_loop.wav'),
        volume: volume * 0.4,
      );
    } catch (e) {
      debugPrint('music failed: $e');
    }
  }

  Future<void> _stopMusic() async {
    try {
      await _music?.stop();
    } catch (_) {}
  }

  /// Pause music while the app is in the background.
  void onBackground(bool background) {
    if (!musicOn || !enabled) return;
    background ? _music?.pause() : _music?.resume();
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _music?.dispose();
  }
}

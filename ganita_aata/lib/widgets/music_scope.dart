import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/audio_service.dart';

/// Plays [track] while this widget is on screen, and goes back to the menu
/// music when it leaves (wraps game screens).
class MusicScope extends StatefulWidget {
  const MusicScope({super.key, required this.track, required this.child});

  final MusicTrack track;
  final Widget child;

  @override
  State<MusicScope> createState() => _MusicScopeState();
}

class _MusicScopeState extends State<MusicScope> {
  late final AudioService _audio;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AppState>().audio;
    _audio.playMusic(widget.track);
  }

  @override
  void dispose() {
    _audio.playMusic(MusicTrack.menu);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

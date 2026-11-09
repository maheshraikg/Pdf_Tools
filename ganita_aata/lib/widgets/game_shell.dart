import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'common.dart';
import 'l10n_ext.dart';

/// Common frame for game screens: close button (asks before leaving),
/// title, timer and score.
class GameShell extends StatelessWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.child,
    this.secondsLeft,
    this.score,
    this.background,
    this.confirmExit = true,
  });

  final String title;
  final Widget child;
  final int? secondsLeft;
  final int? score;
  final List<Color>? background;
  final bool confirmExit;

  static Future<bool> askToQuit(BuildContext context) async {
    final l = context.l10n;
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.quitGameTitle),
        content: Text(l.quitGameBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, true), child: Text(l.stop)),
          FilledButton(onPressed: () => Navigator.pop(c, false), child: Text(l.keepPlaying)),
        ],
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PopScope(
      canPop: !confirmExit,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await askToQuit(context)) nav.pop();
      },
      child: Scaffold(
        body: GameBackground(
          colors: background,
          clouds: background == null,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 50,
                        child: ChunkyButton(
                          key: const ValueKey('close_game'),
                          color: Colors.white,
                          edgeColor: const Color(0xFFD5CFEA),
                          radius: 16,
                          depth: 4,
                          padding: EdgeInsets.zero,
                          onTap: () => Navigator.maybePop(context),
                          child: Icon(Icons.close_rounded, size: 28, color: AppColors.inkSoft, semanticLabel: l.stop),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: display(21)),
                      ),
                      if (secondsLeft != null) ...[
                        StatChip(
                          icon: Icon(
                            Icons.timer_rounded,
                            color: secondsLeft! <= 10 ? AppColors.primary : AppColors.ink,
                          ),
                          label: l.secondsShort(secondsLeft!),
                          color: secondsLeft! <= 10 ? AppColors.primary : AppColors.secondary,
                          compact: true,
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (score != null)
                        StatChip(
                          icon: const AppImage('star', size: 22),
                          label: '$score',
                          semantics: l.score,
                          compact: true,
                        ),
                    ],
                  ),
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A one-second countdown for timed rounds.
mixin Countdown<T extends StatefulWidget> on State<T> {
  Timer? _timer;
  int secondsLeft = 0;

  void startCountdown(int seconds, {required VoidCallback onDone}) {
    secondsLeft = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => secondsLeft--);
      if (secondsLeft <= 0) {
        t.cancel();
        onDone();
      }
    });
  }

  void stopCountdown() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

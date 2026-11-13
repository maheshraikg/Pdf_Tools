import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/rewards.dart';
import '../models/game_result.dart';
import '../models/question.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/mcq_panel.dart';
import 'game_launcher.dart';

/// Treasure Hunt: 5 right answers in a row open a chest full of coins.
class TreasureHuntGame extends StatefulWidget {
  const TreasureHuntGame({super.key, required this.topicId});

  static const roundSeconds = 150;
  static const keysPerChest = 5;

  final String topicId;

  @override
  State<TreasureHuntGame> createState() => _TreasureHuntGameState();
}

class _TreasureHuntGameState extends State<TreasureHuntGame> with Countdown {
  final _results = <QuestionResult>[];
  late Question _q;
  int _qIndex = 0;
  int _keys = 0;
  int _chests = 0;
  bool _opening = false;
  bool _finished = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _q = context.read<AppState>().nextQuestion(widget.topicId);
    startCountdown(TreasureHuntGame.roundSeconds, onDone: _finish);
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _answered(QuestionResult r) {
    _results.add(r);
    setState(() {
      if (!r.correct) {
        _keys = 0;
        return;
      }
      _keys++;
      if (_keys >= TreasureHuntGame.keysPerChest) {
        _chests++;
        _opening = true;
        final audio = context.read<AppState>().audio;
        audio.sfx(Sfx.chest);
        Future.delayed(const Duration(milliseconds: 500), () => audio.sfx(Sfx.coin));
      }
    });
  }

  void _next(QuestionResult r) {
    if (_finished) return;
    if (_opening) {
      // Let the open chest shine for a moment, then a new chest.
      _closeTimer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() {
          _opening = false;
          _keys = 0;
          _newQuestion();
        });
      });
      return;
    }
    setState(_newQuestion);
  }

  void _newQuestion() {
    _q = context.read<AppState>().nextQuestion(widget.topicId);
    _qIndex++;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    finishGame(
      context,
      GameResult(mode: GameMode.treasure, topicId: widget.topicId, items: _results, chests: _chests),
      onReplay: replayOf(GameMode.treasure, widget.topicId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GameShell(
      combo: GameResult.comboOf(_results),
      title: l.gameTreasure,
      secondsLeft: secondsLeft,
      totalSeconds: TreasureHuntGame.roundSeconds,
      score: _results.where((r) => r.correct).length,
      scene: Scene.desert,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chest(open: _opening, size: 96),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < TreasureHuntGame.keysPerChest; i++)
                            AnimatedScale(
                              scale: i < _keys ? 1.15 : 0.9,
                              duration: const Duration(milliseconds: 250),
                              child: Opacity(opacity: i < _keys ? 1 : 0.25, child: const AppImage('key', size: 30)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _opening ? l.chestOpened(Rewards.chestCoins) : l.chestsOpened(_chests),
                        style: display(20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            McqPanel(key: ValueKey('treasure_$_qIndex'), question: _q, onAnswer: _answered, onDone: _next),
          ],
        ),
      ),
    );
  }
}

/// A treasure chest whose lid swings open.
class Chest extends StatelessWidget {
  const Chest({super.key, required this.open, this.size = 90});

  final bool open;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: open ? 1 : 0),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, t, _) => CustomPaint(painter: _ChestPainter(t)),
      ),
    );
  }
}

class _ChestPainter extends CustomPainter {
  _ChestPainter(this.open);

  final double open;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final wood = Paint()..color = const Color(0xFF9C5B2E);
    final dark = Paint()..color = const Color(0xFF6D3B17);
    final gold = Paint()..color = const Color(0xFFFFC107);
    final box = Rect.fromLTWH(w * 0.08, h * 0.45, w * 0.84, h * 0.5);
    if (open > 0.05) {
      // Coins glowing inside.
      canvas.drawOval(Rect.fromLTWH(w * 0.12, h * 0.36, w * 0.76, h * 0.22), Paint()..color = const Color(0xFFFFE082));
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(
          Offset(w * (0.28 + i * 0.15), h * (0.44 - open * 0.12 * (i.isEven ? 1 : 0.5))),
          w * 0.06,
          gold,
        );
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), wood);
    canvas.drawRect(Rect.fromLTWH(box.left, box.top + box.height * 0.35, box.width, box.height * 0.12), dark);
    canvas.drawRect(Rect.fromLTWH(w * 0.44, box.top + box.height * 0.2, w * 0.12, box.height * 0.3), gold);
    // Lid, hinged at the back edge.
    canvas.save();
    canvas.translate(w * 0.08, h * 0.45);
    canvas.rotate(-open * 0.9);
    final lid = RRect.fromLTRBAndCorners(
      0,
      -h * 0.22,
      w * 0.84,
      0,
      topLeft: Radius.circular(w * 0.2),
      topRight: Radius.circular(w * 0.2),
    );
    canvas.drawRRect(lid, wood);
    canvas.drawRect(Rect.fromLTWH(0, -h * 0.06, w * 0.84, h * 0.05), dark);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChestPainter old) => old.open != open;
}

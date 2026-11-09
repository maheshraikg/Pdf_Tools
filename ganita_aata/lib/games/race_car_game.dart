import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../models/game_result.dart';
import '../models/question.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/mcq_panel.dart';
import 'game_launcher.dart';

/// Race Car: each correct answer moves the child's car forward; the
/// computer's car moves at a steady speed set by the level.
class RaceCarGame extends StatefulWidget {
  const RaceCarGame({super.key, required this.topicId});

  /// Correct answers needed to reach the finish line.
  static const steps = 20;

  /// Seconds the computer car needs to finish, by level (1–5).
  static int computerSeconds(int level) => 180 - level * 10;

  final String topicId;

  @override
  State<RaceCarGame> createState() => _RaceCarGameState();
}

class _RaceCarGameState extends State<RaceCarGame> {
  final _results = <QuestionResult>[];
  final _clock = Stopwatch();
  late final int _computerMs;
  Timer? _ticker;
  late Question _q;
  int _qIndex = 0;
  int _ready = 3;
  bool _finished = false;

  int get _steps => _results.where((r) => r.correct).length;
  double get _player => (_steps / RaceCarGame.steps).clamp(0.0, 1.0);
  double get _computer => _ready > 0 ? 0 : (_clock.elapsedMilliseconds / _computerMs).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _computerMs = RaceCarGame.computerSeconds(Curriculum.topic(widget.topicId).level) * 1000;
    _q = context.read<AppState>().nextQuestion(widget.topicId);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _readyTicks = 0;

  void _tick(Timer t) {
    if (!mounted) return;
    if (_ready > 0) {
      if (++_readyTicks % 4 == 0) {
        setState(() => _ready--);
        if (_ready == 0) _clock.start();
      }
      return;
    }
    setState(() {});
    if (_computer >= 1) _finish(false);
  }

  void _answered(QuestionResult r) {
    _results.add(r);
    if (_player >= 1) {
      setState(() {});
      Future.delayed(const Duration(milliseconds: 600), () => _finish(true));
    }
  }

  void _next(QuestionResult r) {
    if (_finished) return;
    setState(() {
      _q = context.read<AppState>().nextQuestion(widget.topicId);
      _qIndex++;
    });
  }

  void _finish(bool won) {
    if (_finished || !mounted) return;
    _finished = true;
    _ticker?.cancel();
    finishGame(
      context,
      GameResult(mode: GameMode.race, topicId: widget.topicId, items: _results, raceWon: won),
      onReplay: replayOf(GameMode.race, widget.topicId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final car = context.watch<AppState>().active!.carColor;
    final rival = car == 'car_black' ? 'car_blue' : 'car_black';
    return GameShell(
      combo: GameResult.comboOf(_results),
      title: l.gameRace,
      score: _steps,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _Track(
              player: _player,
              computer: _computer,
              playerCar: car,
              computerCar: rival,
              playerLabel: l.you,
              computerLabel: l.computer,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ready > 0
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppImage('flag', size: 80),
                          Text(l.getReady, style: display(34)),
                          Text('$_ready', style: display(120, color: AppColors.primary, height: 1)),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: McqPanel(key: ValueKey('race_$_qIndex'), question: _q, onAnswer: _answered, onDone: _next),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.player,
    required this.computer,
    required this.playerCar,
    required this.computerCar,
    required this.playerLabel,
    required this.computerLabel,
  });

  final double player;
  final double computer;
  final String playerCar;
  final String computerCar;
  final String playerLabel;
  final String computerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF5DBB63),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          const carLen = 62.0, laneH = 62.0, top = 50.0;
          final run = box.maxWidth - carLen - 40;
          Widget car(double p, String img, String label, double y, Duration d) => AnimatedPositioned(
            duration: d,
            curve: Curves.easeOut,
            left: 14 + p * run,
            top: y,
            height: laneH,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotatedBox(
                  quarterTurns: 1,
                  child: GameImage(img, height: carLen, width: carLen * 0.54),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8)),
                  child: Text(label, style: display(13, color: Colors.white)),
                ),
              ],
            ),
          );
          return Stack(
            children: [
              // Grandstand along the top.
              Positioned(
                left: 0,
                right: 0,
                top: 4,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    GameImage('race_tribune_full', height: 38),
                    GameImage('race_tent_red', height: 34),
                    GameImage('race_tribune_full', height: 38),
                    GameImage('race_tree_small', height: 34),
                  ],
                ),
              ),
              // Road.
              Positioned(
                left: 0,
                right: 0,
                top: top,
                height: laneH * 2 + 8,
                child: CustomPaint(painter: _RoadPainter()),
              ),
              // Finish line.
              Positioned(
                right: 18,
                top: top,
                height: laneH * 2 + 8,
                width: 14,
                child: CustomPaint(painter: _FinishPainter()),
              ),
              const Positioned(right: 2, bottom: 2, child: GameImage('race_tires_red', height: 22)),
              const Positioned(left: 4, bottom: 2, child: GameImage('race_cone_straight', height: 18)),
              car(player, playerCar, playerLabel, top + 2, const Duration(milliseconds: 500)),
              car(computer, computerCar, computerLabel, top + laneH + 6, const Duration(milliseconds: 250)),
            ],
          );
        },
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF5E636E));
    final edge = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 4), edge);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 4, size.width, 4), edge);
    final dash = Paint()..color = const Color(0xFFFFD54F);
    for (var x = 8.0; x < size.width; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, size.height / 2 - 2, 16, 4), dash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FinishPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 6.0;
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = 0.0; x < size.width; x += s) {
        final black = ((x / s).floor() + (y / s).floor()).isEven;
        canvas.drawRect(Rect.fromLTWH(x, y, s, s), Paint()..color = black ? Colors.black : Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A simple side-view car facing right.
class CarPainter extends CustomPainter {
  CarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = color;
    canvas.drawRRect(RRect.fromLTRBR(0, h * 0.4, w, h * 0.8, const Radius.circular(8)), body);
    final roof = Path()
      ..moveTo(w * 0.2, h * 0.42)
      ..lineTo(w * 0.32, h * 0.08)
      ..lineTo(w * 0.66, h * 0.08)
      ..lineTo(w * 0.82, h * 0.42)
      ..close();
    canvas.drawPath(roof, body);
    final glass = Paint()..color = const Color(0xFFBBE4FF);
    canvas.drawRect(Rect.fromLTRB(w * 0.34, h * 0.16, w * 0.48, h * 0.4), glass);
    canvas.drawRect(Rect.fromLTRB(w * 0.52, h * 0.16, w * 0.68, h * 0.4), glass);
    final tyre = Paint()..color = const Color(0xFF222222);
    final hub = Paint()..color = const Color(0xFFDDDDDD);
    for (final cx in [w * 0.24, w * 0.76]) {
      canvas.drawCircle(Offset(cx, h * 0.8), h * 0.2, tyre);
      canvas.drawCircle(Offset(cx, h * 0.8), h * 0.08, hub);
    }
    canvas.drawCircle(Offset(w * 0.97, h * 0.52), h * 0.06, Paint()..color = Colors.yellowAccent);
  }

  @override
  bool shouldRepaint(CarPainter old) => old.color != color;
}

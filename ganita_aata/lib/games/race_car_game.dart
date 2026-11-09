import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../data/shop_catalog.dart';
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
    final car = ShopCatalog.carColor(context.watch<AppState>().active!.carColor);
    return GameShell(
      title: l.gameRace,
      score: _steps,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _Track(
              player: _player,
              computer: _computer,
              playerColor: car,
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
    required this.playerColor,
    required this.playerLabel,
    required this.computerLabel,
  });

  final double player;
  final double computer;
  final Color playerColor;
  final String playerLabel;
  final String computerLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(color: const Color(0xFF7CC576), borderRadius: BorderRadius.circular(24)),
      padding: const EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, box) {
          const carW = 64.0, laneH = 70.0;
          final run = box.maxWidth - carW - 16;
          Widget lane(double p, Color c, String label, double top, Duration d) => AnimatedPositioned(
            duration: d,
            curve: Curves.easeOut,
            left: p * run,
            top: top + 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(size: const Size(carW, 34), painter: CarPainter(c)),
                Text(label, style: display(14, color: Colors.white)),
              ],
            ),
          );
          return Stack(
            children: [
              for (final top in [0.0, laneH + 6])
                Positioned(
                  left: 0,
                  right: 0,
                  top: top,
                  height: laneH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: const Color(0xFF555B66), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              // Finish line.
              Positioned(right: 4, top: 0, bottom: 0, width: 12, child: CustomPaint(painter: _FinishPainter())),
              lane(player, playerColor, playerLabel, 0, const Duration(milliseconds: 500)),
              lane(computer, const Color(0xFF9E9E9E), computerLabel, laneH + 6, const Duration(milliseconds: 250)),
            ],
          );
        },
      ),
    );
  }
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

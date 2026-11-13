import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../data/shop_catalog.dart';
import '../models/game_result.dart';
import '../models/question.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/game_shell.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/motion.dart';
import '../widgets/question_card.dart';
import '../widgets/shake.dart';
import 'game_launcher.dart';

/// Balloon Pop: 4 balloons carrying answers float upward; tap the right one.
class BalloonPopGame extends StatefulWidget {
  const BalloonPopGame({super.key, required this.topicId});

  static const roundSeconds = 120;

  final String topicId;

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame> with SingleTickerProviderStateMixin, Countdown {
  final _rng = Random();
  final _results = <QuestionResult>[];
  late final AnimationController _float;
  late Question _q;
  late List<Answer> _options;
  late List<double> _delays;
  late List<double> _phases;
  late List<Color> _colors;
  int? _popped;
  int? _wrong;
  bool _reveal = false;
  String? _feedback;
  bool _feedbackGood = true;
  bool _finished = false;
  Timer? _next;
  final _watch = Stopwatch();

  @override
  void initState() {
    super.initState();
    final level = Curriculum.topic(widget.topicId).level;
    _float =
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: 10000 - level * 500),
        )..addStatusListener((s) {
          if (s == AnimationStatus.completed) _missed();
        });
    _newQuestion();
    startCountdown(BalloonPopGame.roundSeconds, onDone: _finish);
  }

  @override
  void dispose() {
    _next?.cancel();
    _float.dispose();
    super.dispose();
  }

  void _newQuestion() {
    final app = context.read<AppState>();
    final colors = ShopCatalog.balloonColors(app.active!.balloonTheme).toList()..shuffle(_rng);
    _q = app.nextQuestion(widget.topicId);
    _options = app.optionsFor(_q);
    _delays = List.generate(4, (_) => _rng.nextDouble() * 0.12);
    _phases = List.generate(4, (_) => _rng.nextDouble() * pi * 2);
    _colors = List.generate(4, (i) => colors[i % colors.length]);
    _popped = null;
    _wrong = null;
    _reveal = false;
    _feedback = null;
    _watch
      ..reset()
      ..start();
    _float.forward(from: 0);
  }

  void _record(Answer? given, bool ok) {
    final ms = _watch.elapsedMilliseconds;
    context.read<AppState>().recordAnswer(_q, ok, ms);
    _results.add(QuestionResult(question: _q, given: given, correct: ok, timeMs: ms));
  }

  void _tap(int i) {
    if (_popped != null || _wrong != null || _reveal || _finished) return;
    _float.stop();
    final app = context.read<AppState>();
    final l = context.l10n;
    final ok = _options[i] == _q.answer;
    _record(_options[i], ok);
    if (ok) {
      app.audio.sfx(Sfx.pop);
      setState(() {
        _popped = i;
        _feedback = l.praiseMessage();
        _feedbackGood = true;
      });
      _next = Timer(const Duration(milliseconds: 800), _advance);
    } else {
      app.audio.wrongThenAnswer(_q.answer, app.lang);
      setState(() {
        _wrong = i;
        _reveal = true;
        _feedback = l.encourageMessage();
        _feedbackGood = false;
      });
      _next = Timer(const Duration(milliseconds: 2000), _advance);
    }
  }

  void _missed() {
    if (_popped != null || _wrong != null || _finished) return;
    _record(null, false);
    final app = context.read<AppState>();
    app.audio.wrongThenAnswer(_q.answer, app.lang);
    setState(() {
      _reveal = true;
      _feedback = context.l10n.answerIs(context.l10n.answerText(_q.answer));
      _feedbackGood = false;
    });
    _next = Timer(const Duration(milliseconds: 1800), _advance);
  }

  void _advance() {
    if (!mounted || _finished) return;
    setState(_newQuestion);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _next?.cancel();
    _float.stop();
    finishGame(
      context,
      GameResult(mode: GameMode.balloon, topicId: widget.topicId, items: _results),
      onReplay: replayOf(GameMode.balloon, widget.topicId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GameShell(
      combo: GameResult.comboOf(_results),
      title: l.gameBalloon,
      secondsLeft: secondsLeft,
      totalSeconds: BalloonPopGame.roundSeconds,
      score: _results.where((r) => r.correct).length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Entrance(
              key: ValueKey('q_${_results.length}'),
              child: QuestionCard(question: _q, fontSize: 42),
            ),
          ),
          const SizedBox(height: 4),
          FeedbackLine(text: _feedback, good: _feedbackGood),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth, h = box.maxHeight;
                final bw = min(w / 4 - 10, 104.0);
                final bh = bw * 1.3 + 30;
                return AnimatedBuilder(
                  animation: _float,
                  builder: (context, _) {
                    final t = _float.value;
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (var i = 0; i < 4; i++) _balloon(i, t, w, h, bw, bh),
                        if (_popped != null)
                          Positioned(
                            key: ValueKey('reward_${_results.length}'),
                            top: 8,
                            left: 0,
                            right: 0,
                            child: const Center(child: FloatingReward()),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _balloon(int i, double t, double w, double h, double bw, double bh) {
    final p = ((t - _delays[i]) / (1 - _delays[i])).clamp(0.0, 1.0);
    final y = h - p * (h + bh);
    final x = w * (i + 0.5) / 4 - bw / 2 + sin(t * pi * 6 + _phases[i]) * 6;
    final isCorrect = _options[i] == _q.answer;
    final highlight = _reveal && isCorrect;
    Widget b = _Balloon(
      label: context.l10n.answerText(_options[i]),
      color: _colors[i],
      width: bw,
      highlight: highlight,
      dim: _reveal && !isCorrect && i != _wrong,
    );
    if (_popped == i) {
      b = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 350),
        builder: (context, v, child) => Opacity(
          opacity: 1 - v,
          child: Transform.scale(scale: 1 + v * 0.8, child: child),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            b,
            StarBurst(size: bw * 1.5),
          ],
        ),
      );
    }
    return Positioned(
      left: x,
      top: y,
      width: bw,
      height: bh,
      child: Shake(
        active: _wrong == i,
        child: GestureDetector(
          key: ValueKey('balloon_$i'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _tap(i),
          child: b,
        ),
      ),
    );
  }
}

class _Balloon extends StatelessWidget {
  const _Balloon({
    required this.label,
    required this.color,
    required this.width,
    this.highlight = false,
    this.dim = false,
  });

  final String label;
  final Color color;
  final double width;
  final bool highlight;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: CustomPaint(
        painter: BalloonPainter(color, highlight),
        child: Align(
          alignment: const Alignment(0, -0.42),
          child: SizedBox(
            width: width * 0.8,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                textDirection: TextDirection.ltr,
                label,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 3, color: Colors.black38)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BalloonPainter extends CustomPainter {
  BalloonPainter(this.color, this.highlight);

  final Color color;
  final bool highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyH = size.width * 1.3;
    final body = Rect.fromLTWH(0, 0, size.width, bodyH);
    if (highlight) {
      canvas.drawOval(body.inflate(6), Paint()..color = const Color(0xFF2EAD5B));
    }
    canvas.drawOval(body, Paint()..color = color);
    // Shine.
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.18, bodyH * 0.12, size.width * 0.22, bodyH * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.45),
    );
    // Knot.
    final knot = Path()
      ..moveTo(size.width / 2 - 7, bodyH + 6)
      ..lineTo(size.width / 2 + 7, bodyH + 6)
      ..lineTo(size.width / 2, bodyH - 3)
      ..close();
    canvas.drawPath(knot, Paint()..color = color);
    // String.
    final string = Path()
      ..moveTo(size.width / 2, bodyH + 6)
      ..quadraticBezierTo(size.width / 2 - 8, bodyH + 16, size.width / 2, size.height);
    canvas.drawPath(
      string,
      Paint()
        ..color = Colors.black45
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(BalloonPainter old) => old.color != color || old.highlight != highlight;
}

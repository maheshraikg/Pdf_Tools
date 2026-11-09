import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../models/question.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/game_shell.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/number_pad.dart';
import '../widgets/question_card.dart';
import 'game_launcher.dart';

/// Speed Challenge: 60 seconds, type answers on a big number pad.
class SpeedChallengeGame extends StatefulWidget {
  const SpeedChallengeGame({super.key, required this.topicId});

  static const roundSeconds = 60;

  final String topicId;

  @override
  State<SpeedChallengeGame> createState() => _SpeedChallengeGameState();
}

class _SpeedChallengeGameState extends State<SpeedChallengeGame> with Countdown {
  final _results = <QuestionResult>[];
  final _watch = Stopwatch();
  late Question _q;
  String _input = '';
  bool? _flashGood;
  String? _feedback;
  bool _finished = false;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _next();
    startCountdown(SpeedChallengeGame.roundSeconds, onDone: _finish);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  void _next() {
    _q = context.read<AppState>().nextQuestion(widget.topicId);
    _input = '';
    _watch
      ..reset()
      ..start();
  }

  void _key(String k) {
    if (_finished) return;
    setState(() {
      if (k == 'R') {
        if (_input.isNotEmpty && !_input.contains('R')) _input += 'R';
      } else if (_input.replaceAll('R', '').length < 6) {
        _input += k;
      }
    });
  }

  void _back() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Answer? _parse() {
    if (_input.isEmpty) return null;
    if (_q.needsRemainder) {
      final parts = _input.split('R');
      final v = int.tryParse(parts[0]);
      final r = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return v == null ? null : Answer(v, r);
    }
    final v = int.tryParse(_input.replaceAll('R', ''));
    return v == null ? null : Answer(v);
  }

  void _submit() {
    if (_finished) return;
    final given = _parse();
    if (given == null) return;
    final app = context.read<AppState>();
    final l = context.l10n;
    final ms = _watch.elapsedMilliseconds;
    final ok = given == _q.answer;
    app.recordAnswer(_q, ok, ms);
    if (ok) {
      app.audio.sfx(Sfx.correct);
    } else {
      app.audio.wrongThenAnswer(_q.answer, app.lang);
    }
    _results.add(QuestionResult(question: _q, given: given, correct: ok, timeMs: ms));
    _flashTimer?.cancel();
    setState(() {
      _flashGood = ok;
      _feedback = ok ? l.praiseMessage() : l.solvedText(_q);
      _next();
    });
    _flashTimer = Timer(Duration(milliseconds: ok ? 500 : 1400), () {
      if (mounted) setState(() => _flashGood = null);
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    finishGame(
      context,
      GameResult(mode: GameMode.speed, topicId: widget.topicId, items: _results),
      onReplay: replayOf(GameMode.speed, widget.topicId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    final best = app.active?.speedBest[widget.topicId] ?? 0;
    final score = _results.where((r) => r.correct).length;
    final shown = _input.replaceAll('R', ' ${l.remainderShort} ');
    final small = MediaQuery.sizeOf(context).height < 700;
    return GameShell(
      title: l.gameSpeed,
      secondsLeft: secondsLeft,
      score: score,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text(l.personalBest(best), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            QuestionCard(question: _q, fontSize: small ? 36 : 44),
            FeedbackLine(text: _flashGood == null ? null : _feedback, good: _flashGood ?? true),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: small ? 60 : 76,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _flashGood == null
                    ? Colors.white
                    : _flashGood!
                    ? AppColors.good.withValues(alpha: 0.25)
                    : AppColors.gentle.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.secondary, width: 3),
              ),
              child: Text(
                shown.isEmpty ? '?' : shown,
                key: const ValueKey('speed_input'),
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: shown.isEmpty ? Colors.black26 : AppColors.ink,
                ),
              ),
            ),
            const Spacer(),
            NumberPad(
              onKey: _key,
              onBackspace: _back,
              onSubmit: _submit,
              showRemainderKey: _q.needsRemainder,
              keyHeight: small ? 46 : 64,
            ),
            SizedBox(height: small ? 4 : 12),
          ],
        ),
      ),
    );
  }
}

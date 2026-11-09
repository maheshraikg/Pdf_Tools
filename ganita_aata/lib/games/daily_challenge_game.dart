import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../models/question.dart';
import '../services/app_state.dart';
import '../widgets/common.dart';
import '../widgets/game_shell.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/mcq_panel.dart';
import 'game_launcher.dart';

/// Daily Challenge: the same 10 sums for the whole day (seeded by date and
/// level). Finishing it counts towards the streak.
class DailyChallengeGame extends StatefulWidget {
  const DailyChallengeGame({super.key});

  @override
  State<DailyChallengeGame> createState() => _DailyChallengeGameState();
}

class _DailyChallengeGameState extends State<DailyChallengeGame> {
  late final List<Question> _questions;
  late final String _topicId;
  final _results = <QuestionResult>[];
  int _i = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _questions = context.read<AppState>().dailyQuestions;
    _topicId = _questions.first.topicId;
  }

  void _next(QuestionResult r) {
    _results.add(r);
    if (_i + 1 >= _questions.length) {
      if (_finished) return;
      _finished = true;
      finishGame(
        context,
        GameResult(mode: GameMode.daily, topicId: _topicId, items: _results),
        onReplay: (c) => startGame(c, GameMode.daily, replace: true),
      );
      return;
    }
    setState(() => _i++);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GameShell(
      combo: GameResult.comboOf(_results),
      title: l.dailyChallenge,
      score: _results.where((r) => r.correct).length,
      scene: Scene.fall,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  Text(l.questionOf(_i + 1, _questions.length), style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: _i / _questions.length, minHeight: 14),
                  ),
                ],
              ),
            ),
            McqPanel(key: ValueKey('daily_$_i'), question: _questions[_i], onDone: _next),
          ],
        ),
      ),
    );
  }
}

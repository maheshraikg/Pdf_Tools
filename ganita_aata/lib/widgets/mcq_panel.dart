import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../models/question.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import 'answer_grid.dart';
import 'l10n_ext.dart';
import 'motion.dart';
import 'question_card.dart';

/// One multiple-choice question: shows the sum and 4 answers, gives
/// feedback (sound, colour, encouraging words), records the answer in the
/// adaptive engine and then calls [onDone].
///
/// Give each question its own [Key] so the panel resets.
class McqPanel extends StatefulWidget {
  const McqPanel({super.key, required this.question, required this.onDone, this.onAnswer, this.speakAnswer = true});

  /// Speak the right answer after a wrong one.
  final bool speakAnswer;

  final Question question;

  /// Called right after the tap (before the feedback pause).
  final ValueChanged<QuestionResult>? onAnswer;

  /// Called when feedback has been shown.
  final ValueChanged<QuestionResult> onDone;

  @override
  State<McqPanel> createState() => _McqPanelState();
}

class _McqPanelState extends State<McqPanel> {
  late final List<Answer> _options;
  final _watch = Stopwatch()..start();
  Answer? _chosen;
  String? _feedback;
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _options = context.read<AppState>().optionsFor(widget.question);
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  void _tap(Answer a) {
    if (_chosen != null) return;
    final ms = _watch.elapsedMilliseconds;
    final app = context.read<AppState>();
    final l = context.l10n;
    final ok = a == widget.question.answer;
    app.recordAnswer(widget.question, ok, ms);
    if (ok) {
      HapticFeedback.lightImpact();
      app.audio.sfx(Sfx.correct);
    } else if (widget.speakAnswer) {
      app.audio.wrongThenAnswer(widget.question.answer, app.lang);
    } else {
      app.audio.sfx(Sfx.wrong);
    }
    final r = QuestionResult(question: widget.question, given: a, correct: ok, timeMs: ms);
    widget.onAnswer?.call(r);
    setState(() {
      _chosen = a;
      _feedback = ok
          ? l.praiseMessage()
          : '${l.encourageMessage()}  ${l.answerIs(l.answerText(widget.question.answer))}';
    });
    _next = Timer(Duration(milliseconds: ok ? 700 : 1900), () {
      if (mounted) widget.onDone(r);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Entrance(child: QuestionCard(question: widget.question)),
            if (_chosen != null && _chosen == widget.question.answer) ...[
              const StarBurst(),
              const Positioned(right: 8, top: -6, child: FloatingReward()),
            ],
          ],
        ),
        const SizedBox(height: 8),
        FeedbackLine(text: _feedback, good: _chosen == widget.question.answer),
        const SizedBox(height: 8),
        AnswerGrid(options: _options, onTap: _tap, chosen: _chosen, correct: widget.question.answer),
      ],
    );
  }
}

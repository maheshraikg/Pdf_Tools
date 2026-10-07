import 'dart:math';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../learn/quiz.dart';
import '../widgets/common.dart';

/// Ten mixed questions: word meanings, Tulu words and Tulu lipi letters.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.random});

  /// For tests: a seeded random source.
  final Random? random;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  int _index = 0;
  int _score = 0;
  int? _picked;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _questions = buildQuiz(AppState.instance.words, random: widget.random);
    _index = 0;
    _score = 0;
    _picked = null;
  }

  bool get _done => _index >= _questions.length;

  void _pick(int i) {
    if (_picked != null) return;
    setState(() {
      _picked = i;
      if (i == _questions[_index].answer) _score++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      _picked = null;
      if (_done) AppState.instance.recordQuiz(_score);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ರಸಪ್ರಶ್ನೆ · Quiz'),
        actions: [
          ListenableBuilder(
            listenable: AppState.instance,
            builder: (_, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '🔥 ${AppState.instance.currentStreak}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _questions.isEmpty
          ? const EmptyState(
              icon: Icons.quiz_outlined,
              title: 'Not enough words for a quiz',
              subtitle: '',
            )
          : _done
          ? _result(context)
          : _question(context, cs),
    );
  }

  Widget _question(BuildContext context, ColorScheme cs) {
    final q = _questions[_index];
    final tt = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LinearProgressIndicator(
          value: _index / _questions.length,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 6),
        Text(
          '${_index + 1} / ${_questions.length}  ·  ✅ $_score',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Card(
          color: cs.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (q.promptLipi.isNotEmpty)
                  FittedBox(
                    child: TuluText(
                      q.promptLipi,
                      size: q.kind == QuizKind.letter ? 84 : 52,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                if (q.kind != QuizKind.letter || q.promptLipi.isEmpty)
                  Text(
                    q.prompt,
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    q.prompt,
                    textAlign: TextAlign.center,
                    style: tt.titleMedium?.copyWith(
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                if (q.speech != null && _picked != null)
                  SpeakButton(q.speech!, color: cs.onPrimaryContainer),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              key: ValueKey('quiz-option-$i'),
              text: q.options[i],
              state: _picked == null
                  ? _OptionState.idle
                  : i == q.answer
                  ? _OptionState.correct
                  : i == _picked
                  ? _OptionState.wrong
                  : _OptionState.dimmed,
              onTap: () => _pick(i),
            ),
          ),
        if (_picked != null)
          FilledButton.icon(
            key: const ValueKey('quiz-next'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              _index + 1 == _questions.length
                  ? 'ಫಲಿತಾಂಶ · See result'
                  : 'ಮುಂದೆ · Next',
            ),
          ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final state = AppState.instance;
    final total = _questions.length;
    final stars = _score >= total ? 3 : (_score >= total * 0.7 ? 2 : 1);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        Center(child: StarRow(stars, size: 44)),
        const SizedBox(height: 16),
        Text(
          '$_score / $total',
          textAlign: TextAlign.center,
          style: tt.displayMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          _score == total
              ? 'ಭಾರೀ ಎಡ್ಡೆ! · Perfect!'
              : 'ಎಡ್ಡೆ ಆಂಡ್! · Well done – keep practising',
          textAlign: TextAlign.center,
          style: tt.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(
          '🔥 ${state.currentStreak} day streak  ·  best ${state.streak.best}\n'
          '🏆 Best quiz: ${state.quizBest} / $total',
          textAlign: TextAlign.center,
          style: tt.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: () => setState(_start),
          icon: const Icon(Icons.replay),
          label: const Text('ಮತ್ತೆ ಆಡಿ · Play again'),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    super.key,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (state) {
      _OptionState.correct => (
        const Color(0xFF2E7D32),
        Colors.white,
        Icons.check_circle,
      ),
      _OptionState.wrong => (cs.error, cs.onError, Icons.cancel),
      _OptionState.dimmed => (
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
        null,
      ),
      _OptionState.idle => (cs.surfaceContainerHigh, cs.onSurface, null),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: state == _OptionState.idle ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (icon != null) Icon(icon, color: fg),
            ],
          ),
        ),
      ),
    );
  }
}

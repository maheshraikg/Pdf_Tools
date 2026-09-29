/// Timed sorting quiz: 20 PINs/offices, 4 options each, score and
/// articles per minute, with a local history chart.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/user_repo.dart';
import 'learn_engine.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.mode});

  final FlashMode mode;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<QuizQuestion>? _qs;
  int _i = 0;
  int _score = 0;
  String? _chosen;
  final _sw = Stopwatch();
  Timer? _tick;
  List<QuizRecord> _history = [];
  bool _done = false;

  String get _kind => 'quiz-${widget.mode.name}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_qs == null) _start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final s = context.services;
    final scheme = s.active;
    if (scheme == null) {
      setState(() => _qs = []);
      return;
    }
    final regions = await s.pinRegions();
    final qs = LearnEngine(scheme, directoryPins: regions.keys, regions: regions).quiz(widget.mode);
    if (!mounted) return;
    setState(() {
      _qs = qs;
      _i = 0;
      _score = 0;
      _chosen = null;
      _done = false;
    });
    _sw
      ..reset()
      ..start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _choose(String o) async {
    if (_chosen != null) return;
    final s = context.services;
    final q = _qs![_i];
    final right = o == q.card.answer;
    setState(() {
      _chosen = o;
      if (right) _score++;
    });
    if (right) {
      AppFeedback.success(context.settings);
    } else {
      AppFeedback.warning(context.settings);
      await s.user.addMistake(s.active?.scheme.id, _kind, q.card.prompt, q.card.isPin ? q.card.prefix : null, q.card.answer, o);
    }
    await Future<void>.delayed(Duration(milliseconds: right ? 350 : 1100));
    if (!mounted) return;
    if (_i + 1 >= _qs!.length) {
      _sw.stop();
      _tick?.cancel();
      await s.user.addQuiz(s.active?.scheme.id, _kind, _score, _qs!.length, _sw.elapsedMilliseconds);
      final h = await s.user.quizHistory(schemeId: s.active?.scheme.id);
      if (!mounted) return;
      setState(() {
        _history = h.where((r) => r.kind == _kind).toList();
        _done = true;
      });
    } else {
      setState(() {
        _i++;
        _chosen = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final qs = _qs;
    final title = widget.mode == FlashMode.air ? l.airQuiz : l.timedQuiz;
    if (qs == null) return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    if (qs.isEmpty) return Scaffold(appBar: AppBar(title: Text(title)), body: EmptyState(icon: Icons.quiz_outlined, text: l.noCards));
    final t = Theme.of(context).textTheme;
    if (_done) {
      final secs = _sw.elapsedMilliseconds / 1000;
      final apm = secs == 0 ? 0 : qs.length / (secs / 60);
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.quizScore(_score, qs.length), style: t.displaySmall?.copyWith(fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            Text(l.quizStats(secs.round(), apm.toStringAsFixed(1)), style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Text(l.history, style: t.titleMedium),
            SizedBox(height: 180, child: _HistoryChart(records: _history)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _start, icon: const Icon(Icons.replay), label: Text(l.again)),
          ],
        ),
      );
    }
    final q = qs[_i];
    final question = switch (widget.mode) {
      FlashMode.bag => q.card.isPin ? l.qWhichBagPin : l.qWhichBagPlace,
      FlashMode.air => l.qWhichAirCode,
      FlashMode.hub => l.qWhichHub,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        Center(child: Padding(padding: const EdgeInsets.only(right: 16), child: Text('⏱ ${_sw.elapsed.inSeconds}s', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _i / qs.length),
            const SizedBox(height: 8),
            Text('${_i + 1} / ${qs.length} · ${l.scoreN(_score)}', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(q.card.category == null ? question : '$question · ${categoryLabel(l, q.card.category!)}', style: t.titleMedium, textAlign: TextAlign.center),
            FittedBox(child: Text(q.card.prompt, style: t.displayMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: q.card.isPin ? 4 : 0))),
            const SizedBox(height: 16),
            for (final o in q.options)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                    backgroundColor: _chosen == null
                        ? null
                        : o == q.card.answer
                        ? okColor(context).withValues(alpha: 0.35)
                        : o == _chosen
                        ? Theme.of(context).colorScheme.errorContainer
                        : null,
                  ),
                  onPressed: () => _choose(o),
                  child: Text(o, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Minimal line chart of score % over past quizzes.
class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.records});

  final List<QuizRecord> records;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (records.length < 2) return Center(child: Text(l.historyNeedsMore));
    final c = Theme.of(context).colorScheme;
    return Semantics(
      label: records.map((r) => '${r.percent.round()}%').join(', '),
      child: CustomPaint(painter: _ChartPainter(records.map((r) => r.percent).toList(), c.primary, c.outlineVariant, c.onSurface)),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.values, this.line, this.grid, this.text);

  final List<double> values;
  final Color line, grid, text;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0, bottom = 8.0;
    final w = size.width - left, h = size.height - bottom;
    final gp = Paint()..color = grid..strokeWidth = 1;
    for (final p in [0, 50, 100]) {
      final y = h - h * p / 100;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gp);
      final tp = TextPainter(text: TextSpan(text: '$p%', style: TextStyle(color: text, fontSize: 11)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    final path = Path();
    final lp = Paint()..color = line..strokeWidth = 3..style = PaintingStyle.stroke;
    final dp = Paint()..color = line;
    for (var i = 0; i < values.length; i++) {
      final x = left + w * i / (values.length - 1);
      final y = h - h * values[i] / 100;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 4, dp);
    }
    canvas.drawPath(path, lp);
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.values != values;
}

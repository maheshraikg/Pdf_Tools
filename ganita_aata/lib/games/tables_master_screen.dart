import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
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

/// Tables Master: pick a table (2–20), then Learn (each line with audio) or
/// Quiz (the table in random order).
class TablesMasterScreen extends StatelessWidget {
  const TablesMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(l.gameTables)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(l.pickTable, style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: 19,
                itemBuilder: (context, i) {
                  final n = i + 2;
                  final mastered = app.engine.isTableMastered(n);
                  return BigCard(
                    key: ValueKey('table_$n'),
                    color: AppColors.cardColors[i % AppColors.cardColors.length],
                    padding: const EdgeInsets.all(4),
                    onTap: () => _choose(context, n),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$n',
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        if (mastered)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: Icon(Icons.star_rounded, color: Colors.yellowAccent, size: 26),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _choose(BuildContext context, int n) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.tableOf(n), style: Theme.of(c).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('learn_btn'),
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => TableLearnScreen(table: n)));
                      },
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(l.learn),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('quiz_btn'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                      onPressed: () {
                        Navigator.pop(c);
                        startTableQuiz(context, n);
                      },
                      icon: const Icon(Icons.quiz_rounded),
                      label: Text(l.quiz),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void startTableQuiz(BuildContext context, int n, {bool replace = false}) {
  context.read<AppState>().beginRound();
  final route = MaterialPageRoute<void>(builder: (_) => TableQuizGame(table: n));
  replace ? Navigator.pushReplacement(context, route) : Navigator.push(context, route);
}

/// Learn mode: each line of the table, read aloud in the app language.
class TableLearnScreen extends StatefulWidget {
  const TableLearnScreen({super.key, required this.table});

  final int table;

  @override
  State<TableLearnScreen> createState() => _TableLearnScreenState();
}

class _TableLearnScreenState extends State<TableLearnScreen> {
  int? _current;
  bool _playing = false;
  int _run = 0;

  @override
  void dispose() {
    _run++;
    _audio.stopVoice();
    super.dispose();
  }

  late final AudioService _audio;

  @override
  void initState() {
    super.initState();
    _audio = context.read<AppState>().audio;
  }

  Future<void> _say(int b) async {
    final app = context.read<AppState>();
    setState(() => _current = b);
    if (app.soundOn) {
      await app.audio.tableLine(widget.table, b, app.lang);
      await Future<void>.delayed(const Duration(milliseconds: 250));
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
    }
  }

  Future<void> _playAll() async {
    if (_playing) {
      _run++;
      _audio.stopVoice();
      setState(() => _playing = false);
      return;
    }
    final run = ++_run;
    setState(() => _playing = true);
    for (var b = (_current == null || _current == 10) ? 1 : _current!; b <= 10; b++) {
      if (!mounted || run != _run) return;
      await _say(b);
    }
    if (mounted && run == _run) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final n = widget.table;
    final engine = context.watch<AppState>().engine;
    return Scaffold(
      appBar: AppBar(title: Text(l.tableOf(n))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: 10,
                itemBuilder: (context, i) {
                  final b = i + 1;
                  final on = _current == b;
                  final mastered = engine.isMastered('mul:$n:$b:0');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      key: ValueKey('line_$b'),
                      minTileHeight: 60,
                      tileColor: on ? AppColors.primary : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onTap: () {
                        _run++;
                        setState(() => _playing = false);
                        _say(b);
                      },
                      title: Text(
                        '$n × $b = ${n * b}',
                        style: TextStyle(
                          fontSize: on ? 34 : 28,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : AppColors.ink,
                        ),
                      ),
                      trailing: mastered
                          ? Icon(
                              Icons.star_rounded,
                              color: on ? Colors.white : AppColors.coin,
                              semanticLabel: l.mastered,
                            )
                          : Icon(Icons.volume_up_rounded, color: on ? Colors.white : Colors.black38),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('listen_btn'),
                      onPressed: _playAll,
                      icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      label: Text(_playing ? l.pause : l.listen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        _run++;
                        _audio.stopVoice();
                        startTableQuiz(context, n, replace: true);
                      },
                      child: Text(l.startQuiz),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quiz mode: the 10 lines of one table in random order.
class TableQuizGame extends StatefulWidget {
  const TableQuizGame({super.key, required this.table});

  final int table;

  @override
  State<TableQuizGame> createState() => _TableQuizGameState();
}

class _TableQuizGameState extends State<TableQuizGame> {
  late final String _topicId = Curriculum.topicForTable(widget.table).id;
  late final List<Question> _questions = [
    for (var b = 1; b <= 10; b++) Question.fromParts(_topicId, Op.mul, widget.table, b),
  ]..shuffle();
  final _results = <QuestionResult>[];
  int _i = 0;
  bool _finished = false;

  void _answered(QuestionResult r) {
    if (!r.correct) {
      // Hear the right line once more.
      final app = context.read<AppState>();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) app.audio.tableLine(r.question.a, r.question.b, app.lang);
      });
    }
  }

  void _next(QuestionResult r) {
    _results.add(r);
    if (_i + 1 >= _questions.length) {
      if (_finished) return;
      _finished = true;
      final n = widget.table;
      finishGame(
        context,
        GameResult(mode: GameMode.tables, topicId: _topicId, items: _results, table: n),
        onReplay: (c) => startTableQuiz(c, n, replace: true),
      );
      return;
    }
    setState(() => _i++);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GameShell(
      title: '${l.gameTables} · ${l.tableOf(widget.table)}',
      score: _results.where((r) => r.correct).length,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.questionOf(_i + 1, _questions.length), style: Theme.of(context).textTheme.titleLarge),
            ),
            McqPanel(
              key: ValueKey('tq_$_i'),
              question: _questions[_i],
              onAnswer: _answered,
              onDone: _next,
              speakAnswer: false, // the whole table line is read instead
            ),
          ],
        ),
      ),
    );
  }
}

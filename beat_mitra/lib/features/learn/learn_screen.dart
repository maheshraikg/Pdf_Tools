import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/geo.dart';
import '../../core/services/location_service.dart';
import '../../data/models.dart';
import '../../data/repos/learn_repo.dart';
import '../common/live_location.dart';
import '../common/widgets.dart';
import 'quiz.dart';

/// Learn the beat: flashcards, walk mode and progress.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  LearnProgress? _progress;
  int _version = -1;

  Future<void> _load() async {
    final beat = context.app.activeBeat;
    if (beat == null) return;
    final p = await context.services.learn.progress(beat.id!);
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final v = context.watch<AppState>().version;
    if (v != _version) {
      _version = v;
      _load();
    }
    final p = _progress;
    final t = Theme.of(context).textTheme;
    void open(QuizMode m) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => m == QuizMode.walk ? const WalkModeScreen() : FlashcardScreen(mode: m)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.learnBeat)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (p != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.learnedPercent(p.percent.round()), style: t.headlineSmall),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: p.percent / 100,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text(l.learnedOf(p.learned, p.total), style: t.bodyLarge),
                    if (p.weakStreets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(l.weakStreets, style: t.titleMedium),
                      for (final s in p.weakStreets.take(5))
                        Text(
                          '• ${s.streetName.isEmpty ? l.noStreet : s.streetName}  ${s.learned}/${s.total}',
                          style: t.bodyLarge,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          for (final (mode, icon, title, sub) in [
            (QuizMode.photoToPlace, Icons.photo, l.quizPhoto, l.quizPhotoSub),
            (QuizMode.nameToDoor, Icons.person_search, l.quizName, l.quizNameSub),
            (QuizMode.doorToLandmark, Icons.flag, l.quizDoor, l.quizDoorSub),
            (QuizMode.walk, Icons.directions_walk, l.walkMode, l.walkModeSub),
          ])
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
                title: Text(title, style: t.titleLarge),
                subtitle: Text(sub, style: t.bodyMedium),
                onTap: () => open(mode),
              ),
            ),
          if (p != null && p.total > 0)
            TextButton(
              onPressed: () async {
                if (!await confirm(context, l.resetProgress, l.resetProgressConfirm)) return;
                if (!context.mounted) return;
                await context.services.learn.reset(context.app.activeBeat!.id!);
                _load();
              },
              child: Text(l.resetProgress),
            ),
        ],
      ),
    );
  }
}

/// Multiple-choice question card used by flashcards and walk mode.
class QuizCard extends StatefulWidget {
  const QuizCard({super.key, required this.q, required this.mode, required this.onAnswered});
  final QuizQuestion q;
  final QuizMode mode;
  final void Function(bool correct) onAnswered;

  @override
  State<QuizCard> createState() => _QuizCardState();
}

class _QuizCardState extends State<QuizCard> {
  int? _chosen;

  @override
  void didUpdateWidget(QuizCard old) {
    super.didUpdateWidget(old);
    if (old.q != widget.q) _chosen = null;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final q = widget.q;
    final question = switch (widget.mode) {
      QuizMode.photoToPlace => l.qWhichPlace,
      QuizMode.nameToDoor => l.qWhereLives(q.prompt),
      QuizMode.doorToLandmark => l.qLandmarkOf(q.prompt),
      QuizMode.walk => q.target.addressees.isNotEmpty ? l.qWhoLivesHere : l.qWhichPlace,
    };
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (q.photo != null && (widget.mode == QuizMode.photoToPlace || widget.mode == QuizMode.walk))
          Center(child: PhotoThumb(q.photo, size: 260)),
        const SizedBox(height: 12),
        Text(question, style: t.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        for (var i = 0; i < q.options.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: _chosen == null
                    ? null
                    : i == q.correct
                    ? Colors.green.shade300
                    : i == _chosen
                    ? Colors.red.shade300
                    : null,
                foregroundColor: _chosen != null && (i == q.correct || i == _chosen) ? Colors.black : null,
              ),
              onPressed: _chosen != null
                  ? null
                  : () {
                      final ok = i == q.correct;
                      ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
                      setState(() => _chosen = i);
                      widget.onAnswered(ok);
                    },
              child: Text(q.options[i], textAlign: TextAlign.center, style: const TextStyle(fontSize: 19)),
            ),
          ),
        if (_chosen != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _chosen == q.correct ? l.correct : l.wrongAnswer(q.options[q.correct]),
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(color: _chosen == q.correct ? Colors.green.shade700 : Colors.red.shade700),
            ),
          ),
      ],
    );
  }
}

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, required this.mode});
  final QuizMode mode;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final _rnd = Random();
  List<PlaceDetails> _pool = [];
  Map<int, int> _weights = {};
  QuizQuestion? _q;
  bool _answered = false;
  bool _loading = true;
  int _right = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final beat = context.app.activeBeat;
    if (beat == null) return;
    final s = context.services;
    _pool = await s.places.allDetails(beatId: beat.id);
    _weights = await s.learn.weights(beat.id!);
    _next();
    if (mounted) setState(() => _loading = false);
  }

  void _next() {
    setState(() {
      _q = buildQuestion(widget.mode, _pool, _weights, _rnd);
      _answered = false;
    });
  }

  Future<void> _answer(bool ok) async {
    final q = _q!;
    setState(() {
      _answered = true;
      _total++;
      if (ok) _right++;
    });
    await context.services.learn.record(q.target.place.id!, ok);
    _weights[q.target.place.id!] = ok ? 1 : 5;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.scoreLine(_right, _total))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _q == null
          ? EmptyState(icon: Icons.info_outline, text: l.notEnoughForQuiz)
          : QuizCard(q: _q!, mode: widget.mode, onAnswered: _answer),
      bottomNavigationBar: _answered
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward), label: Text(l.next)),
              ),
            )
          : null,
    );
  }
}

/// Walk mode: shows the nearest saved place and quizzes you about it.
class WalkModeScreen extends StatefulWidget {
  const WalkModeScreen({super.key});

  @override
  State<WalkModeScreen> createState() => _WalkModeScreenState();
}

class _WalkModeScreenState extends State<WalkModeScreen> with LiveLocation {
  final _rnd = Random();
  List<PlaceDetails> _pool = [];
  PlaceDetails? _nearest;
  double? _dist;
  QuizQuestion? _q;
  final Set<int> _asked = {};

  @override
  void initState() {
    super.initState();
    final beat = context.app.activeBeat;
    if (beat != null) {
      context.services.places.allDetails(beatId: beat.id).then((p) {
        if (mounted) setState(() => _pool = p);
      });
    }
    startLocation();
  }

  @override
  void onFix(GpsFix f) {
    PlaceDetails? best;
    var bestD = double.infinity;
    for (final d in _pool) {
      final p = d.place.point;
      if (p == null) continue;
      final dist = haversineMeters(f.point, p);
      if (dist < bestD) {
        bestD = dist;
        best = d;
      }
    }
    setState(() {
      _dist = best == null ? null : bestD;
      if (best?.place.id != _nearest?.place.id) {
        _nearest = best;
        _q = null;
        if (best != null && bestD <= 40 && !_asked.contains(best.place.id)) {
          _q = buildQuestion(QuizMode.walk, _pool, const {}, _rnd, fixedTarget: best);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final n = _nearest;
    return Scaffold(
      appBar: AppBar(title: Text(l.walkMode)),
      body: fix == null
          ? EmptyState(icon: Icons.gps_not_fixed, text: l.gpsWaiting)
          : n == null
          ? EmptyState(icon: Icons.location_searching, text: l.noNearby)
          : _q != null
          ? QuizCard(
              q: _q!,
              mode: QuizMode.walk,
              onAnswered: (ok) {
                _asked.add(n.place.id!);
                context.services.learn.record(n.place.id!, ok);
              },
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.nearestPlace(formatDistance(_dist ?? 0)), style: t.titleLarge),
                const SizedBox(height: 12),
                Center(child: PhotoThumb(n.photos.firstOrNull?.filePath, size: 240)),
                const SizedBox(height: 12),
                Text(n.title, style: t.headlineMedium, textAlign: TextAlign.center),
                if (n.place.landmark.isNotEmpty)
                  Text('⚑ ${n.place.landmark}', style: t.titleLarge, textAlign: TextAlign.center),
                Text(n.addressees.map((a) => a.name).join(', '), style: t.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(l.walkHint, textAlign: TextAlign.center, style: t.bodyLarge),
              ],
            ),
    );
  }
}

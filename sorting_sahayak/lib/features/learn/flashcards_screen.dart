/// Flip-card practice with Leitner spaced repetition (stored locally).
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/feedback.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets.dart';
import 'learn_engine.dart';

export 'learn_engine.dart' show FlashMode;

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.mode, this.onlyPins});

  final FlashMode mode;

  /// Practise only these PINs (e.g. PINs whose hub changed in a new DMSL).
  final Set<int>? onlyPins;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<LearnCard>? _deck;
  Map<String, ({int box, int due})> _boxes = {};
  int _i = 0;
  bool _flipped = false;
  int _known = 0, _unknown = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_deck == null) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final s = context.services;
    final scheme = s.active;
    if (scheme == null) {
      setState(() => _deck = []);
      return;
    }
    final regions = await s.pinRegions();
    final engine = LearnEngine(scheme, directoryPins: regions.keys, regions: regions);
    final cards = engine.cards(widget.mode, onlyPins: widget.onlyPins);
    final boxes = await s.user.leitner(scheme.scheme.id!);
    final now = DateTime.now().millisecondsSinceEpoch;
    // Due cards first (lowest box first), then the rest; new cards count as box 1.
    cards.shuffle(Random());
    cards.sort((a, b) {
      final ba = boxes[a.key], bb = boxes[b.key];
      final da = (ba?.due ?? 0) <= now, db = (bb?.due ?? 0) <= now;
      if (da != db) return da ? -1 : 1;
      return (ba?.box ?? 1).compareTo(bb?.box ?? 1);
    });
    if (mounted) {
      setState(() {
        _deck = cards;
        _boxes = boxes;
      });
    }
  }

  Future<void> _answer(bool knew) async {
    final s = context.services;
    final card = _deck![_i];
    final box = nextBox(_boxes[card.key]?.box ?? 1, knew);
    final due = dueAfter(box, DateTime.now());
    _boxes[card.key] = (box: box, due: due);
    await s.user.setLeitner(s.active!.scheme.id!, card.key, box, due);
    if (!knew) {
      await s.user.addMistake(s.active!.scheme.id, 'flash-${widget.mode.name}', card.prompt, card.isPin ? card.prefix : null, card.answer, null);
    }
    if (!mounted) return;
    AppFeedback.tap(context.settings);
    setState(() {
      if (knew) {
        _known++;
      } else {
        _unknown++;
      }
      _flipped = false;
      _i++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final deck = _deck;
    final title = switch (widget.mode) {
      FlashMode.bag => l.flashcards,
      FlashMode.air => l.airFlashcards,
      FlashMode.hub => l.hubFlashcards,
    };
    if (deck == null) return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    if (deck.isEmpty) return Scaffold(appBar: AppBar(title: Text(title)), body: EmptyState(icon: Icons.style_outlined, text: l.noCards));
    if (_i >= deck.length) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: EmptyState(
          icon: Icons.emoji_events_outlined,
          text: l.flashDone(_known, _unknown),
          action: FilledButton(onPressed: () => setState(() {
            _i = 0;
            _known = _unknown = 0;
            _deck = null;
            _load();
          }), child: Text(l.again)),
        ),
      );
    }
    final c = deck[_i];
    final box = _boxes[c.key]?.box ?? 1;
    final t = Theme.of(context).textTheme;
    final question = switch (widget.mode) {
      FlashMode.bag => c.isPin ? l.qWhichBagPin : l.qWhichBagPlace,
      FlashMode.air => l.qWhichAirCode,
      FlashMode.hub => l.qWhichHub,
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: _i / deck.length),
            const SizedBox(height: 8),
            Text('${_i + 1} / ${deck.length} · ${l.leitnerBox(box)}', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                  child: Card(
                    key: ValueKey('${c.key}$_flipped'),
                    color: _flipped ? Theme.of(context).colorScheme.primaryContainer : null,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_flipped ? l.answer : question, style: t.titleMedium),
                            const SizedBox(height: 12),
                            FittedBox(
                              child: Text(_flipped ? c.answer : c.prompt,
                                  style: t.displayMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: c.isPin && !_flipped ? 4 : 0)),
                            ),
                            if (_flipped && c.answerDetail.isNotEmpty) Text(c.answerDetail, style: t.titleLarge, textAlign: TextAlign.center),
                            if (!_flipped) ...[const SizedBox(height: 16), Text(l.tapToFlip, style: t.bodySmall)],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_flipped)
              Row(
                children: [
                  Expanded(child: FilledButton.tonalIcon(onPressed: () => _answer(false), icon: const Icon(Icons.close), label: Text(l.didntKnow))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton.icon(onPressed: () => _answer(true), icon: const Icon(Icons.check), label: Text(l.knewIt))),
                ],
              )
            else
              FilledButton(onPressed: () => setState(() => _flipped = true), child: Text(l.showAnswer)),
          ],
        ),
      ),
    );
  }
}

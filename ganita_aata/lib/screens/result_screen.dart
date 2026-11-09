import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/badge_popup.dart';
import '../widgets/l10n_ext.dart';

/// Score, stars, coins, mistakes with correct answers, and what to do next.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result, required this.summary, required this.onReplay});

  final GameResult result;
  final RoundSummary summary;
  final void Function(BuildContext context) onReplay;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  Future<void> _celebrate() async {
    final audio = context.read<AppState>().audio;
    if (widget.summary.coins > 0) await audio.sfx(Sfx.coin);
    for (final b in widget.summary.newBadges) {
      if (!mounted) return;
      await audio.sfx(Sfx.badge);
      if (!mounted) return;
      await showBadgePopup(context, b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = widget.result, s = widget.summary;
    final msg = switch (s.stars) {
      3 => l.resultMsg3,
      2 => l.resultMsg2,
      1 => l.resultMsg1,
      _ => l.resultMsg0,
    };
    final extras = <String>[
      if (r.raceWon == true) l.raceWon,
      if (r.raceWon == false) l.raceLost,
      if (r.mode == GameMode.treasure) l.chestsOpened(r.chests),
      if (s.newBest) l.newBest,
      if (s.best != null && !s.newBest) l.personalBest(s.best!),
      if (s.streak != null) l.streakNow(l.streakDays(s.streak!)),
      for (final t in s.unlockedTopics) l.newTopicUnlocked(l.topicName(t)),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l.resultTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            _Stars(stars: s.stars),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Tile(label: l.score, value: '${r.correct}/${r.total}', color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(label: l.correctLabel, value: '${r.correct}', color: AppColors.good),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(label: l.practiseLabel, value: '${r.total - r.correct}', color: AppColors.gentle),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.coin.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('🪙 ${l.coinsEarned(s.coins)}', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            for (final e in extras)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(e, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
              ),
            const SizedBox(height: 16),
            if (r.mistakes.isEmpty && r.total > 0)
              Text('🎉 ${l.allCorrect}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)
            else if (r.mistakes.isNotEmpty) ...[
              Text(l.practiseThese, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final m in r.mistakes)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_rounded, color: AppColors.gentle, size: 32),
                    title: Text(
                      l.solvedText(m.question),
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('home_btn'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home_rounded),
                    label: Text(l.home),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('again_btn'),
                    onPressed: () => widget.onReplay(context),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(l.playAgain),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + i * 250),
            curve: Curves.elasticOut,
            builder: (c, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(Icons.star_rounded, size: i == 1 ? 96 : 76, color: i < stars ? AppColors.coin : Colors.black12),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          FittedBox(
            child: Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          ),
          FittedBox(child: Text(label, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}

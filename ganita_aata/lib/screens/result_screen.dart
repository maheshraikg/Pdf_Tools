import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_result.dart';
import '../services/app_state.dart';
import '../services/audio_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/badge_popup.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/motion.dart';
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
    await audio.sfx(widget.summary.stars > 0 ? Sfx.win : Sfx.coin);
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
      body: GameBackground(
        scene: Scene.castles,
        clouds: true,
        child: Stack(
          children: [
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(child: AppImage(s.stars >= 2 ? 'trophy' : (s.stars == 1 ? 'party' : 'muscle'), size: 96)),
                  const SizedBox(height: 6),
                  Text(
                    l.resultTitle,
                    textAlign: TextAlign.center,
                    style: display(32, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  _Stars(stars: s.stars),
                  const SizedBox(height: 8),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: display(23, color: AppColors.secondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Entrance(
                          delay: 300,
                          child: CountUp(
                            value: r.correct,
                            builder: (c, v) =>
                                _Tile(label: l.score, value: '$v/${r.total}', color: AppColors.secondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Entrance(
                          delay: 420,
                          child: CountUp(
                            value: r.correct,
                            builder: (c, v) => _Tile(label: l.correctLabel, value: '$v', color: AppColors.good),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Entrance(
                          delay: 540,
                          child: _Tile(
                            label: l.practiseLabel,
                            value: '${r.total - r.correct}',
                            color: AppColors.gentle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (c, v, child) => Transform.scale(scale: v, child: child),
                      child: CountUp(
                        value: s.coins,
                        ms: 1200,
                        builder: (c, v) => StatChip(icon: const AppImage('coin', size: 32), label: l.coinsEarned(v)),
                      ),
                    ),
                  ),
                  for (final e in extras)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Panel(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const AppImage('sparkles', size: 30),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(e, style: display(18, weight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (r.mistakes.isEmpty && r.total > 0)
                    Panel(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppImage('party', size: 40),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(l.allCorrect, style: display(24, color: AppColors.goodDark)),
                          ),
                        ],
                      ),
                    )
                  else if (r.mistakes.isNotEmpty) ...[
                    Text(l.practiseThese, style: display(21, color: Colors.white)),
                    const SizedBox(height: 8),
                    for (final m in r.mistakes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Panel(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              const AppImage('bulb', size: 34),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l.solvedText(m.question),
                                    textDirection: mathDirection(m.question),
                                    style: display(28),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ChunkyButton(
                          key: const ValueKey('home_btn'),
                          color: Colors.white,
                          edgeColor: const Color(0xFFD5CFEA),
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.home_rounded, color: AppColors.secondary, size: 28),
                              const SizedBox(width: 6),
                              Flexible(
                                child: FittedBox(
                                  child: Text(l.home, style: display(21, color: AppColors.secondary)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Shimmer(
                          radius: 22,
                          child: ChunkyButton(
                            key: const ValueKey('again_btn'),
                            color: AppColors.primary,
                            onTap: () => widget.onReplay(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.replay_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: FittedBox(
                                    child: Text(l.playAgain, style: display(21, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (s.stars > 0) const Positioned.fill(child: Confetti()),
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
            child: Padding(
              padding: EdgeInsets.only(top: i == 1 ? 0 : 18),
              child: Opacity(
                opacity: i < stars ? 1 : 0.18,
                child: AppImage('star', size: i == 1 ? 88 : 66),
              ),
            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(value, style: display(32, color: darken(color, 0.12))),
          ),
          FittedBox(
            child: Text(
              label,
              style: display(16, weight: FontWeight.w500, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

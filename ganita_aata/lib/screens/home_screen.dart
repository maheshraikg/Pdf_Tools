import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_launcher.dart';
import '../models/game_result.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';
import 'badges_screen.dart';
import 'level_map_screen.dart';
import 'pin_screen.dart';
import 'profile_setup_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const modes = [GameMode.balloon, GameMode.race, GameMode.treasure, GameMode.tables, GameMode.speed];

  static String modeEmoji(GameMode m) => switch (m) {
    GameMode.balloon => '🎈',
    GameMode.race => '🏎️',
    GameMode.treasure => '💰',
    GameMode.tables => '📖',
    GameMode.speed => '⚡',
    GameMode.daily => '📅',
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.active;
    final l = context.l10n;
    if (p == null) return const ProfileSetupScreen(firstRun: true);
    final streak = app.currentStreak;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              children: [
                GestureDetector(
                  key: const ValueKey('avatar_button'),
                  onTap: () => showProfileSwitcher(context),
                  child: AvatarCircle(avatarId: p.avatar, size: 64),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.helloName(p.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(l.greetingSub, maxLines: 2, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  key: const ValueKey('parents_button'),
                  tooltip: l.forParents,
                  iconSize: 30,
                  onPressed: () => _parents(context),
                  icon: const Icon(Icons.lock_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                CoinChip(coins: p.coins, semantics: l.coins),
                StatChip(
                  icon: const Text('🔥', style: TextStyle(fontSize: 20)),
                  label: l.streakDays(streak),
                  color: AppColors.primary,
                  semantics: l.streak,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DailyCard(done: app.dailyDoneToday),
            const SizedBox(height: 16),
            SizedBox(
              height: 84,
              child: FilledButton.icon(
                key: const ValueKey('play_button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.good,
                  textStyle: const TextStyle(fontFamily: 'NotoSansKannada', fontSize: 34, fontWeight: FontWeight.w700),
                ),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LevelMapScreen())),
                icon: const Icon(Icons.play_arrow_rounded, size: 48),
                label: Text(l.play),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.currentTopic(l.topicName(p.currentTopic)),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LevelMapScreen())),
                  child: Text(l.change),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(l.games, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.95,
              children: [
                for (var i = 0; i < modes.length; i++)
                  BigCard(
                    key: ValueKey('mode_${modes[i].name}'),
                    color: AppColors.cardColors[i],
                    onTap: () => startGame(context, modes[i]),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(modeEmoji(modes[i]), style: const TextStyle(fontSize: 42, height: 1.2)),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            l.gameName(modes[i]),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l.gameDesc(modes[i]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, height: 1.25, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('shop_button'),
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ShopScreen())),
                    icon: const Text('🛍️', style: TextStyle(fontSize: 24)),
                    label: Text(l.shop),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('badges_button'),
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const BadgesScreen())),
                    icon: const Text('🏅', style: TextStyle(fontSize: 24)),
                    label: Text(l.badges),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _parents(BuildContext context) {
    final l = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.forParents, style: Theme.of(c).textTheme.titleLarge),
            ListTile(
              key: const ValueKey('open_progress'),
              leading: const Icon(Icons.insights_rounded, size: 32),
              title: Text(l.progress, style: const TextStyle(fontSize: 22)),
              onTap: () async {
                Navigator.pop(c);
                if (await requireParentPin(context) && context.mounted) {
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));
                }
              },
            ),
            ListTile(
              key: const ValueKey('open_settings'),
              leading: const Icon(Icons.settings_rounded, size: 32),
              title: Text(l.settings, style: const TextStyle(fontSize: 22)),
              onTap: () async {
                Navigator.pop(c);
                if (await requireParentPin(context) && context.mounted) {
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BigCard(
      key: const ValueKey('daily_card'),
      color: AppColors.secondary,
      onTap: () => startGame(context, GameMode.daily),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(done ? '✅' : '📅', style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.dailyChallenge,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                Text(
                  done ? l.dailyDone : l.dailyChallengeDesc,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Text(
              done ? l.playAgainToday : l.start,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to switch between children or add one.
void showProfileSwitcher(BuildContext context) {
  final l = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) {
      final app = c.watch<AppState>();
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.switchChild, style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final p in app.profiles)
              ListTile(
                key: ValueKey('profile_${p.name}'),
                minTileHeight: 72,
                leading: AvatarCircle(avatarId: p.avatar, size: 52, selected: p.id == app.active?.id),
                title: Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                subtitle: Text(l.classN(p.schoolClass)),
                trailing: p.id == app.active?.id
                    ? IconButton(
                        tooltip: l.editProfile,
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () {
                          Navigator.pop(c);
                          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ProfileSetupScreen(edit: p)));
                        },
                      )
                    : null,
                onTap: () {
                  app.switchProfile(p);
                  Navigator.pop(c);
                },
              ),
            ListTile(
              key: const ValueKey('add_child'),
              minTileHeight: 72,
              leading: const CircleAvatar(radius: 26, child: Icon(Icons.add_rounded, size: 30)),
              title: Text(l.addChild, style: const TextStyle(fontSize: 22)),
              onTap: () {
                Navigator.pop(c);
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProfileSetupScreen()));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

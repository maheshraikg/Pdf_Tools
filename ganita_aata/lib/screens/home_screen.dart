import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../games/game_launcher.dart';
import '../models/game_result.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/motion.dart';
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

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final p = app.active;
    final l = context.l10n;
    if (p == null) return const ProfileSetupScreen(firstRun: true);
    final streak = app.currentStreak;
    void openMap() => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const LevelMapScreen()));
    return Scaffold(
      body: GameBackground(
        scene: Scene.grass,
        clouds: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              Row(
                children: [
                  GestureDetector(
                    key: const ValueKey('avatar_button'),
                    onTap: () => showProfileSwitcher(context),
                    child: Bob(height: 3, child: AvatarCircle(avatarId: p.avatar, size: 66)),
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
                          style: display(26, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            CoinChip(coins: p.coins, semantics: l.coins, compact: true),
                            StatChip(
                              icon: const AppImage('fire', size: 22),
                              label: l.streakDays(streak),
                              color: AppColors.primary,
                              semantics: l.streak,
                              compact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      key: const ValueKey('parents_button'),
                      tooltip: l.forParents,
                      iconSize: 26,
                      onPressed: () => _parents(context),
                      icon: const Icon(Icons.lock_rounded, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              MascotBubble(text: l.greetingSub, size: 64),
              const SizedBox(height: 14),
              _DailyCard(done: app.dailyDoneToday),
              const SizedBox(height: 16),
              Pulse(
                child: Shimmer(
                  radius: 28,
                  child: ChunkyButton(
                    key: const ValueKey('play_button'),
                    color: AppColors.good,
                    depth: 8,
                    radius: 28,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    onTap: openMap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 48, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(l.play, style: display(38, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                child: Row(
                  children: [
                    const AppImage('abacus', size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.currentTopic(l.topicName(p.currentTopic)),
                        style: display(17, weight: FontWeight.w700, color: AppColors.inkSoft),
                      ),
                    ),
                    TextButton(onPressed: openMap, child: Text(l.change)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(l.games, style: display(26, color: Colors.white)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.92,
                children: [
                  for (var i = 0; i < modes.length; i++)
                    Entrance(
                      delay: 120 * i,
                      child: BigCard(
                        key: ValueKey('mode_${modes[i].name}'),
                        color: AppColors.card(i).$1,
                        onTap: () => startGame(context, modes[i]),
                        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 78,
                              height: 78,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Wiggle(phase: i * 0.2, child: AppImage(modeImage(modes[i]), size: 60)),
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              child: Text(l.gameName(modes[i]), style: display(21, color: Colors.white)),
                            ),
                            Flexible(
                              child: Text(
                                l.gameDesc(modes[i]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, height: 1.25, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Entrance(delay: 120 * modes.length, child: _ShopBadgesTile()),
                ],
              ),
            ],
          ),
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
            Text(l.forParents, style: display(24)),
            ListTile(
              key: const ValueKey('open_progress'),
              leading: const AppImage('chart', size: 40),
              title: Text(l.progress, style: display(21, weight: FontWeight.w700)),
              onTap: () async {
                Navigator.pop(c);
                if (await requireParentPin(context) && context.mounted) {
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));
                }
              },
            ),
            ListTile(
              key: const ValueKey('open_settings'),
              leading: const AppImage('gear', size: 40),
              title: Text(l.settings, style: display(21, weight: FontWeight.w700)),
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

/// The sixth tile of the games grid: Shop and Badges.
class _ShopBadgesTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget half(String key, String img, String label, Widget page) => Expanded(
      child: ChunkyButton(
        key: ValueKey(key),
        color: Colors.white,
        edgeColor: const Color(0xFFD9D2F5),
        radius: 22,
        depth: 5,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page)),
        child: Row(
          children: [
            AppImage(img, size: 40),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: display(20, color: AppColors.secondary)),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      children: [
        half('shop_button', 'shop', l.shop, const ShopScreen()),
        const SizedBox(height: 12),
        half('badges_button', 'medal', l.badges, const BadgesScreen()),
      ],
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          Bob(height: 4, child: AppImage(done ? 'check' : 'calendar', size: 62)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.dailyChallenge, style: display(23, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  done ? l.dailyDone : l.dailyChallengeDesc,
                  style: const TextStyle(fontSize: 14, height: 1.3, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 104),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3))],
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(done ? l.playAgainToday : l.start, style: display(17, color: AppColors.secondary)),
              ),
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
            Text(l.switchChild, style: display(24)),
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

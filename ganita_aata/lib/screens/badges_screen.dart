import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/rewards.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/badge_icon.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.watch<AppState>().active!;
    final all = Badges.all;
    final earned = all.where(p.badges.contains).length;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(l.badges)),
      body: GameBackground(
        scene: Scene.castles,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Panel(
                    child: Row(
                      children: [
                        const AppImage('trophy', size: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('$earned / ${all.length}', style: display(34, color: AppColors.primaryDark)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: all.length,
                  itemBuilder: (context, i) {
                    final id = all[i];
                    final has = p.badges.contains(id);
                    return Panel(
                      padding: const EdgeInsets.all(10),
                      color: has ? const Color(0xFFFFF8DA) : Colors.white,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BadgeIcon(id: id, size: 76, earned: has),
                          const SizedBox(height: 8),
                          Text(
                            l.badgeName(id),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: display(18, color: has ? AppColors.ink : AppColors.inkSoft),
                          ),
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              l.badgeDesc(id),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.fade,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                            ),
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
      ),
    );
  }
}

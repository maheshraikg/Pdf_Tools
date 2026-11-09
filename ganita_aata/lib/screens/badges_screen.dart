import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../engine/rewards.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/l10n_ext.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.watch<AppState>().active!;
    final all = Badges.all;
    return Scaffold(
      appBar: AppBar(title: Text(l.badges)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemCount: all.length,
        itemBuilder: (context, i) {
          final id = all[i];
          final has = p.badges.contains(id);
          return Card(
            color: has ? const Color(0xFFFFF3C4) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: has ? 1 : 0.25,
                    child: Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: has ? AppColors.coin : Colors.grey.shade300,
                      ),
                      child: Text(badgeEmoji(id), style: const TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.badgeName(id),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: Text(
                      l.badgeDesc(id),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.fade,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../game/achievements.dart';

const Map<String, IconData> _icons = {
  'extension': Icons.extension,
  'collections': Icons.collections,
  'workspace_premium': Icons.workspace_premium,
  'theater_comedy': Icons.theater_comedy,
  'psychology': Icons.psychology,
  'military_tech': Icons.military_tech,
  'bolt': Icons.bolt,
  'today': Icons.today,
  'local_fire_department': Icons.local_fire_department,
  'whatshot': Icons.whatshot,
  'menu_book': Icons.menu_book,
  'face_retouching_natural': Icons.face_retouching_natural,
  'celebration': Icons.celebration,
};

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final p = app.progress;
    final today = app.today;
    final scheme = Theme.of(context).colorScheme;
    final total = app.content.allPuzzles.length;

    Widget stat(String label, String value, IconData icon) => Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.progress)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.05,
            children: [
              stat(
                s.completedPuzzles,
                '${p.distinctCompleted}/$total',
                Icons.extension,
              ),
              stat(
                s.currentStreak,
                '${p.dailyStreak(today)}',
                Icons.local_fire_department,
              ),
              stat(s.bestStreak, '${p.bestDailyStreak()}', Icons.whatshot),
              stat(s.storiesRead, '${p.storiesRead.length}', Icons.menu_book),
              stat(s.totalHints, '${p.hintsUsed}', Icons.lightbulb_outline),
              stat(s.badges, '${p.eventBadges.length}', Icons.celebration),
            ],
          ),
          const SizedBox(height: 16),
          Text(s.achievements, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final a in achievementsFor(app.content))
            Builder(
              builder: (context) {
                final got = p.achievements.containsKey(a.id);
                final v = a.value(p, app.content, today).clamp(0, a.goal);
                final packName = a.id.startsWith('pack_')
                    ? app.content.pack(a.id.substring(5))?.title.of(lang)
                    : null;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: got
                          ? scheme.secondary
                          : scheme.surfaceContainerHighest,
                      child: Icon(
                        _icons[a.icon] ?? Icons.emoji_events,
                        color: got ? Colors.black : scheme.outline,
                      ),
                    ),
                    title: Text(s.achievementTitle(a.id, packName: packName)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.achievementDesc(a.id, a.goal)),
                        if (!got && a.goal > 1) ...[
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: v / a.goal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ],
                    ),
                    trailing: got
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Text('$v/${a.goal}'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

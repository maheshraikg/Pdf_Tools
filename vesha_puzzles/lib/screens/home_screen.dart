import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../game/daily.dart';
import '../game/saves.dart';
import '../packs/content.dart';
import '../widgets/vesha_guide.dart';
import 'difficulty_sheet.dart';
import 'dress_up_screen.dart';
import 'library_screen.dart';
import 'progress_screen.dart';
import 'puzzle_screen.dart';
import 'settings_screen.dart';
import 'stories_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final today = app.today;
    final daily = app.dailyPick;
    final events = app.activeEvents;
    final recent = _latestSave(app);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.appTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: s.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _push(context, const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (app.settings.guideTips)
            VeshaGuide(
              line: VeshaGuide.pick(
                app.content,
                'home.',
                salt: today.day + today.month,
              ),
            ),
          const SizedBox(height: 12),
          for (final e in events) _EventBanner(event: e, lang: lang),
          if (daily != null) _DailyCard(pick: daily),
          if (recent != null) _ContinueCard(save: recent.$1, puzzle: recent.$2),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _Tile(
                Icons.extension,
                s.puzzles,
                () => _push(context, const LibraryScreen()),
              ),
              _Tile(
                Icons.menu_book,
                s.stories,
                () => _push(context, const StoriesScreen()),
              ),
              if (app.content.dressUp != null)
                _Tile(
                  Icons.face_retouching_natural,
                  s.dressUp,
                  () => _push(context, const DressUpScreen()),
                ),
              _Tile(
                Icons.emoji_events,
                s.achievements,
                () => _push(context, const ProgressScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static (SavedGame, PuzzleDef)? _latestSave(AppState app) {
    (SavedGame, PuzzleDef)? best;
    for (final p in app.content.allPuzzles) {
      final g = app.saves.load(p.id);
      if (g == null) continue;
      if (best == null || g.savedAt.isAfter(best.$1.savedAt)) best = (g, p);
    }
    return best;
  }
}

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: scheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventBanner extends StatelessWidget {
  const _EventBanner({required this.event, required this.lang});
  final EventDef event;
  final Lang lang;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = Theme.of(context).colorScheme;
    final app = AppScope.of(context);
    final featured = [for (final id in event.featured) ?app.content.puzzle(id)];
    return Card(
      color: scheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.celebration, color: scheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text(
                  s.eventNow,
                  style: TextStyle(
                    color: scheme.onTertiaryContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              event.title.of(lang),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: scheme.onTertiaryContainer),
            ),
            const SizedBox(height: 4),
            Text(
              event.blurb.of(lang),
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
            if (featured.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final p in featured)
                    ActionChip(
                      avatar: const Icon(Icons.extension, size: 18),
                      label: Text(p.title.of(lang)),
                      onPressed: app.isUnlocked(p)
                          ? () => showDifficultySheet(context, p)
                          : null,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.pick});
  final DailyPick pick;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final done = app.progress.dailyDone.contains(pick.saveKey.substring(6));
    final saved = app.saves.load(pick.saveKey);
    final streak = app.progress.dailyStreak(app.today);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: done ? null : () => openDaily(context, pick),
        child: Row(
          children: [
            SizedBox(
              width: 120,
              height: 100,
              child: Image.asset(
                pick.puzzle.image,
                fit: BoxFit.cover,
                cacheWidth: 360,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.daily,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      pick.puzzle.title.of(lang),
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${s.difficulty(pick.difficulty)}${streak > 0 ? ' · ${s.streakDays(streak)}' : ''}',
                    ),
                    const SizedBox(height: 4),
                    if (done)
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(s.dailyDone),
                        ],
                      )
                    else
                      Text(
                        saved != null ? s.continueGame : s.play,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.save, required this.puzzle});
  final SavedGame save;
  final PuzzleDef puzzle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final pct = (save.fraction * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            puzzle.image,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            cacheWidth: 168,
          ),
        ),
        title: Text(puzzle.title.of(app.settings.lang)),
        subtitle: Text(
          '${s.difficulty(save.difficulty)} · ${s.percentDone(pct)}',
        ),
        trailing: FilledButton(
          onPressed: () => openPuzzle(context, puzzle: puzzle, resume: save),
          child: Text(s.continueGame),
        ),
      ),
    );
  }
}

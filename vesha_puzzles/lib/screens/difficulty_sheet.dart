import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../jigsaw/cut.dart';
import '../packs/content.dart';
import 'puzzle_screen.dart';
import 'story_screen.dart';

Future<void> showDifficultySheet(BuildContext context, PuzzleDef puzzle) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DifficultySheet(puzzle: puzzle),
    );

class _DifficultySheet extends StatelessWidget {
  const _DifficultySheet({required this.puzzle});
  final PuzzleDef puzzle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final save = app.saves.load(puzzle.id);
    final rec = app.progress.records[puzzle.id];
    final story = puzzle.storyId == null
        ? null
        : app.content.stories[puzzle.storyId];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<double>(
          future: imageAspect(puzzle.image),
          builder: (context, snap) {
            final aspect = snap.data ?? 4 / 3;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  puzzle.title.of(lang),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: Image.asset(
                      puzzle.image,
                      fit: BoxFit.cover,
                      cacheWidth: 900,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (save != null) ...[
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      '${s.resume} · ${s.difficulty(save.difficulty)} · ${s.percentDone((save.fraction * 100).round())}',
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      openPuzzle(context, puzzle: puzzle, resume: save);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.startOver,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                ] else
                  Text(
                    s.chooseDifficulty,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                const SizedBox(height: 4),
                for (final d in Difficulty.values)
                  Card(
                    child: ListTile(
                      leading: Icon(_icon(d)),
                      title: Text(s.difficulty(d)),
                      subtitle: Text(
                        [
                          s.pieces(gridFor(d.targetPieces, aspect).count),
                          if (rec?.bestMs[d.name] != null)
                            s.best(formatDuration(rec!.bestMs[d.name]!)),
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < (rec?.stars[d.name] ?? 0); i++)
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () async {
                        if (save != null) await app.saves.delete(puzzle.id);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        openPuzzle(context, puzzle: puzzle, difficulty: d);
                      },
                    ),
                  ),
                if (story != null && app.progress.completed(puzzle.id)) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: Text(s.readStory),
                    onPressed: () {
                      Navigator.pop(context);
                      openStory(context, story, puzzle: puzzle);
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  static IconData _icon(Difficulty d) => switch (d) {
    Difficulty.easy => Icons.child_care,
    Difficulty.medium => Icons.extension,
    Difficulty.hard => Icons.local_fire_department,
    Difficulty.expert => Icons.military_tech,
  };
}

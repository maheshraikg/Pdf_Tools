import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../packs/content.dart';
import 'difficulty_sheet.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cols = width > 900 ? 5 : (width > 600 ? 4 : 2);
    return Scaffold(
      appBar: AppBar(title: Text(s.puzzles)),
      body: CustomScrollView(
        slivers: [
          for (final pack in app.content.packs) ...[
            SliverToBoxAdapter(child: _PackHeader(pack: pack)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverGrid.count(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [for (final p in pack.puzzles) PuzzleTile(puzzle: p)],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackHeader extends StatelessWidget {
  const _PackHeader({required this.pack});
  final ArtPack pack;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final done = pack.puzzles.where((p) => app.progress.completed(p.id)).length;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(pack.title.of(lang), style: t.titleLarge)),
              if (pack.placeholder)
                Chip(
                  label: Text(s.placeholderArt, style: t.labelSmall),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(pack.description.of(lang), style: t.bodyMedium),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: pack.puzzles.isEmpty ? 0 : done / pack.puzzles.length,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 4),
          Text(s.puzzleCount(done, pack.puzzles.length), style: t.labelMedium),
        ],
      ),
    );
  }
}

class PuzzleTile extends StatelessWidget {
  const PuzzleTile({super.key, required this.puzzle});
  final PuzzleDef puzzle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final unlocked = app.isUnlocked(puzzle);
    final rec = app.progress.records[puzzle.id];
    final save = app.saves.load(puzzle.id);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${puzzle.title.of(lang)}${unlocked ? '' : ', ${s.locked}'}',
      child: Card(
        child: InkWell(
          onTap: () {
            if (unlocked) {
              showDifficultySheet(context, puzzle);
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(s.unlockHint)));
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: unlocked
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            )
                          : const ColorFilter.matrix(_greyscale),
                      child: Image.asset(
                        puzzle.image,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                      ),
                    ),
                    if (!unlocked)
                      Container(
                        color: Colors.black38,
                        child: const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    if (save != null && unlocked)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: _Badge(
                          s.percentDone((save.fraction * 100).round()),
                          scheme.secondary,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      puzzle.title.of(lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            i < (rec?.bestStars ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: scheme.secondary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _greyscale = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

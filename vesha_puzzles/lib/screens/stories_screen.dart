import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import 'story_screen.dart';

/// All stories, grouped by pack; a story unlocks with its puzzle.
class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    return Scaffold(
      appBar: AppBar(title: Text(s.stories)),
      body: ListView(
        children: [
          for (final pack in app.content.packs) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(pack.title.of(lang), style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final p in pack.puzzles)
              if (p.storyId != null && app.content.stories[p.storyId] != null)
                Builder(
                  builder: (context) {
                    final story = app.content.stories[p.storyId]!;
                    final open = app.progress.completed(p.id);
                    final read = app.progress.storiesRead.contains(story.id);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Opacity(
                          opacity: open ? 1 : 0.35,
                          child: Image.asset(p.image, width: 56, height: 56, fit: BoxFit.cover, cacheWidth: 168),
                        ),
                      ),
                      title: Text(story.title.of(lang)),
                      subtitle: Text(open ? p.title.of(lang) : s.storyLocked),
                      trailing: Icon(open ? (read ? Icons.check_circle : Icons.menu_book) : Icons.lock_outline),
                      onTap: open
                          ? () => openStory(context, story, puzzle: p)
                          : () => ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(s.storyLocked))),
                    );
                  },
                ),
          ],
        ],
      ),
    );
  }
}

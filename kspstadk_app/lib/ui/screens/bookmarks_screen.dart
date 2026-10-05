import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';

/// Saved posts (full content cached, readable offline).
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bookmarks = context.app.bookmarks;
    return Scaffold(
      appBar: AppBar(title: Text(l.bookmarks)),
      body: ListenableBuilder(
        listenable: bookmarks,
        builder: (context, _) {
          final posts = bookmarks.all;
          if (posts.isEmpty) {
            return EmptyState(icon: Icons.bookmark_border_rounded, title: l.noBookmarks, subtitle: l.noBookmarksHint);
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: posts.length,
            itemBuilder: (context, i) => Dismissible(
              key: ValueKey(posts[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 28),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Icon(Icons.bookmark_remove_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
              ),
              onDismissed: (_) => bookmarks.toggle(posts[i]),
              child: PostCard(post: posts[i], heroPrefix: 'bm'),
            ),
          );
        },
      ),
    );
  }
}

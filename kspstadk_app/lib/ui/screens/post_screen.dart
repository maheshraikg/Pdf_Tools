import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../content/post_content.dart';
import '../../core/text_utils.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../data/wp_api.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../post/blocks.dart';
import '../routes.dart';
import '../widgets/common.dart';

/// Parses post HTML off the UI thread. Tests swap in a synchronous parser.
Future<PostContent> Function(String html) postParser = (html) => compute(parsePostContent, html);

/// Native post reader.
class PostScreen extends StatefulWidget {
  const PostScreen({super.key, required this.postId, this.preview, this.heroTag});

  final int postId;
  final Post? preview;
  final String? heroTag;

  @override
  State<PostScreen> createState() => _PostScreenState();
}

/// Parsed bodies by `id:modified`, so going back and forth is instant.
final _parsedCache = <String, PostContent>{};

class _PostScreenState extends State<PostScreen> {
  StreamSubscription<Swr<Post>>? _sub;
  Swr<Post> _state = const Swr(loading: true);
  PostContent? _content;
  String? _contentKey;

  @override
  void initState() {
    super.initState();
    _state = Swr(data: widget.preview, loading: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({bool force = false}) {
    _sub?.cancel();
    final app = context.app;
    _sub = app.repo.post(widget.postId, force: force, preview: widget.preview).listen((s) {
      if (!mounted) return;
      setState(() => _state = s);
      final p = s.data;
      if (p != null && p.hasContent) {
        _parse(p);
        app.history.add(p);
        app.bookmarks.refresh(p);
      }
    });
  }

  Future<void> _parse(Post p) async {
    final key = '${p.id}:${p.modified.millisecondsSinceEpoch}:${p.content.length}';
    if (key == _contentKey) return;
    _contentKey = key;
    final cached = _parsedCache[key];
    final PostContent parsed = cached ?? await postParser(p.content);
    if (cached == null) {
      if (_parsedCache.length > 20) _parsedCache.remove(_parsedCache.keys.first);
      _parsedCache[key] = parsed;
    }
    if (mounted && key == _contentKey) setState(() => _content = parsed);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _share(Post p) {
    final l = AppLocalizations.of(context);
    SharePlus.instance.share(ShareParams(text: l.sharePostText(p.title, p.link), subject: p.title));
  }

  Future<void> _toggleBookmark(Post p) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final added = await context.app.bookmarks.toggle(p);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(added ? l.bookmarkAdded : l.bookmarkRemoved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final p = _state.data;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _state.error != null
            ? ErrorState(error: _state.error, onRetry: () => _load(force: true))
            : const PostListSkeleton(count: 4),
      );
    }
    final bookmarks = context.app.bookmarks;
    final blocks = _content?.blocks;
    final hasRelated = _content?.related != null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _load(force: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              stretch: true,
              expandedHeight: p.imageUrl != null ? 230 : 0,
              backgroundColor: t.colorScheme.surface,
              actions: [
                IconButton(tooltip: l.share, icon: const Icon(Icons.share_rounded), onPressed: () => _share(p)),
                ListenableBuilder(
                  listenable: bookmarks,
                  builder: (context, _) {
                    final on = bookmarks.contains(p.id);
                    return IconButton(
                      tooltip: on ? l.bookmarked : l.bookmark,
                      icon: Icon(on ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: on ? Brand.green : null),
                      onPressed: p.hasContent ? () => _toggleBookmark(p) : null,
                    );
                  },
                ),
              ],
              flexibleSpace: p.imageUrl == null
                  ? null
                  : FlexibleSpaceBar(
                      background: Hero(
                        tag: widget.heroTag ?? 'post-${p.id}',
                        child: NetImage(p.imageUrl, memWidth: 1000),
                      ),
                    ),
            ),
            const SliverToBoxAdapter(child: OfflineBanner()),
            SliverToBoxAdapter(child: _Header(post: p)),
            if (_state.error != null && !p.hasContent)
              SliverToBoxAdapter(
                child: SizedBox(height: 360, child: ErrorState(error: _state.error, onRetry: () => _load(force: true))),
              )
            else if (blocks == null)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(children: [
                    ShimmerBox(height: 16),
                    SizedBox(height: 10),
                    ShimmerBox(height: 16),
                    SizedBox(height: 10),
                    ShimmerBox(height: 16, width: 220),
                    SizedBox(height: 24),
                    ShimmerBox(height: 160),
                  ]),
                ),
              )
            else
              SliverList.builder(
                itemCount: blocks.length,
                itemBuilder: (context, i) => BlockView(block: blocks[i], post: p),
              ),
            if (blocks != null && !hasRelated) SliverToBoxAdapter(child: _RelatedByCategory(post: p)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openInApp(p.link),
                      icon: const Icon(Icons.public_rounded),
                      label: Text(l.viewOnSite),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: GradientPill(label: l.share, icon: Icons.share_rounded, onTap: () => _share(p))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final cfg = context.app.config;
    final locale = Localizations.localeOf(context);
    // One chip per configured concept (twins merged), then leftovers.
    final chips = <(String, List<int>, Color?)>[];
    final seen = <int>{};
    for (final c in [...cfg.classes, ...cfg.subjects, ...cfg.mediums, ...cfg.tiles]) {
      if (c.ids.any(post.categoryIds.contains)) {
        chips.add((c.label(locale), c.ids, c.color));
        seen.addAll(c.ids);
      }
    }
    for (final term in post.categories) {
      if (!seen.contains(term.id)) chips.add((term.name, [term.id], null));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final (label, ids, color) in chips.take(5))
                TagChip(label: label, color: color, onTap: () => openCategory(context, title: label, ids: ids, color: color)),
            ]),
          const SizedBox(height: 10),
          Semantics(header: true, child: Text(post.title, style: t.textTheme.headlineSmall?.copyWith(fontSize: 22))),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: t.textTheme.labelMedium!.copyWith(color: t.colorScheme.onSurfaceVariant),
            child: Wrap(spacing: 14, runSpacing: 4, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_rounded, size: 14),
                const SizedBox(width: 4),
                Text(friendlyDate(context, post.date)),
              ]),
              if (post.hasContent)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.schedule_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(l.readingTime(readingMinutes(post.content))),
                ]),
            ]),
          ),
          const SizedBox(height: 8),
          const Divider(),
        ],
      ),
    );
  }
}

/// Fallback related list from the post's first category.
class _RelatedByCategory extends StatefulWidget {
  const _RelatedByCategory({required this.post});

  final Post post;

  @override
  State<_RelatedByCategory> createState() => _RelatedByCategoryState();
}

class _RelatedByCategoryState extends State<_RelatedByCategory> {
  Future<PostPage>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_future == null && widget.post.categoryIds.isNotEmpty) {
      // Prefer the most specific category (fewest posts is unknown here, so
      // skip the huge news buckets when there's another one).
      final ids = widget.post.categoryIds.where((c) => !const {1, 8, 10}.contains(c)).toList();
      final cat = ids.isNotEmpty ? ids.first : widget.post.categoryIds.first;
      _future = context.app.repo.loadPage(
        WpApi.postsQuery(categories: [cat], exclude: [widget.post.id], perPage: 6),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<PostPage>(
      future: _future,
      builder: (context, snap) {
        final posts = snap.data?.posts ?? const <Post>[];
        if (posts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RelatedViewFromPosts(title: l.relatedPosts, posts: posts),
            ],
          ),
        );
      },
    );
  }
}

class RelatedViewFromPosts extends StatelessWidget {
  const RelatedViewFromPosts({super.key, required this.title, required this.posts});

  final String title;
  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return RelatedView(
      title: title,
      items: [
        for (final p in posts) RelatedItem(title: p.title, url: p.link),
      ],
    );
  }
}

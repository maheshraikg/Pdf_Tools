import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../data/wp_api.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/post_card.dart';

/// Infinite, cached list of posts for a set of categories (or all posts).
class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key, required this.title, this.categoryIds = const [], this.color});

  final String title;
  final List<int> categoryIds;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            foregroundColor: Colors.white,
            backgroundColor: color ?? Brand.blue,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14, end: 16),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 18)),
              background: DecoratedBox(
                decoration: BoxDecoration(gradient: color != null ? Brand.tint(color!) : Brand.headerGradient),
              ),
            ),
          ),
        ],
        body: PagedPostList(query: WpApi.postsQuery(categories: categoryIds), heroPrefix: 'cat-${categoryIds.join('_')}'),
      ),
    );
  }
}

/// Paginated post list (page 1 stale-while-revalidate, then infinite scroll).
class PagedPostList extends StatefulWidget {
  const PagedPostList({super.key, required this.query, this.heroPrefix = 'list', this.header, this.emptyBuilder});

  final Map<String, dynamic> query;
  final String heroPrefix;
  final Widget? header;
  final WidgetBuilder? emptyBuilder;

  @override
  State<PagedPostList> createState() => _PagedPostListState();
}

class _PagedPostListState extends State<PagedPostList> {
  final _posts = <Post>[];
  StreamSubscription<Swr<PostPage>>? _sub;
  Object? _error;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
  }

  @override
  void didUpdateWidget(PagedPostList old) {
    super.didUpdateWidget(old);
    if (old.query.toString() != widget.query.toString()) _loadFirst();
  }

  Future<void> _loadFirst({bool force = false}) {
    final done = Completer<void>();
    _sub?.cancel();
    setState(() {
      _error = null;
      _loadingFirst = _posts.isEmpty;
    });
    _sub = context.app.repo.postPage({...widget.query, 'page': 1}, force: force).listen((s) {
      if (!mounted) return;
      setState(() {
        if (s.data != null) {
          _posts
            ..clear()
            ..addAll(s.data!.posts);
          _page = 1;
          _hasMore = s.data!.hasMore;
        }
        _error = s.error;
        _loadingFirst = s.data == null && s.loading;
      });
      if (!s.loading && !done.isCompleted) done.complete();
    }, onDone: () {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await context.app.repo.loadPage({...widget.query, 'page': _page + 1});
      if (!mounted) return;
      setState(() {
        final ids = _posts.map((p) => p.id).toSet();
        _posts.addAll(next.posts.where((p) => !ids.contains(p.id)));
        _page = next.page;
        _hasMore = next.hasMore && next.posts.isNotEmpty;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    Widget body;
    if (_loadingFirst) {
      body = ListView(children: [if (widget.header != null) widget.header!, const PostListSkeleton()]);
    } else if (_posts.isEmpty && _error != null) {
      body = ListView(children: [
        if (widget.header != null) widget.header!,
        SizedBox(height: 420, child: ErrorState(error: _error, onRetry: () => _loadFirst(force: true))),
      ]);
    } else if (_posts.isEmpty) {
      body = ListView(children: [
        if (widget.header != null) widget.header!,
        SizedBox(
          height: 420,
          child: widget.emptyBuilder?.call(context) ?? EmptyState(icon: Icons.inbox_rounded, title: l.emptyPosts),
        ),
      ]);
    } else {
      final headerCount = widget.header != null ? 1 : 0;
      body = NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 600) _loadMore();
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 6, bottom: 24),
          itemCount: headerCount + _posts.length + 1,
          itemBuilder: (context, i) {
            if (i < headerCount) return widget.header!;
            final idx = i - headerCount;
            if (idx == _posts.length) {
              if (_loadingMore) return const PostListSkeleton(count: 2);
              if (_hasMore && _error != null) {
                return Center(child: TextButton.icon(onPressed: _loadMore, icon: const Icon(Icons.refresh), label: Text(l.retry)));
              }
              return const SizedBox(height: 24);
            }
            return PostCard(post: _posts[idx], heroPrefix: widget.heroPrefix);
          },
        ),
      );
    }
    return RefreshIndicator(onRefresh: () => _loadFirst(force: true), child: body);
  }
}

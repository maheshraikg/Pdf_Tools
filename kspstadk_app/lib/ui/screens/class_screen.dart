import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../data/site_config.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/post_card.dart';

/// Class → Subject → Medium drill-down. The site's categories are flat, so a
/// class's posts are fetched once (≤ ~100) and grouped on the device.
class ClassScreen extends StatefulWidget {
  const ClassScreen({super.key, required this.concept});

  final Concept concept;

  @override
  State<ClassScreen> createState() => _ClassScreenState();
}

class _ClassScreenState extends State<ClassScreen> {
  StreamSubscription<Swr<List<Post>>>? _sub;
  Swr<List<Post>> _s = const Swr(loading: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({bool force = false}) {
    _sub?.cancel();
    _sub = context.app.repo.allPostsLite(widget.concept.ids, force: force).listen((s) {
      if (mounted) setState(() => _s = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cfg = context.app.config;
    final locale = Localizations.localeOf(context);
    final posts = _s.data ?? const <Post>[];
    final bySubject = <Concept, List<Post>>{};
    for (final p in posts) {
      final s = cfg.subjectOf(p);
      if (s != null) bySubject.putIfAbsent(s, () => []).add(p);
    }
    final subjects = cfg.subjects.where(bySubject.containsKey).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _load(force: true),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              foregroundColor: Colors.white,
              backgroundColor: Brand.blue,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 14),
                title: Text(widget.concept.label(locale), style: const TextStyle(color: Colors.white, fontSize: 19)),
                background: Stack(fit: StackFit.expand, children: [
                  const DecoratedBox(decoration: BoxDecoration(gradient: Brand.headerGradient)),
                  Positioned(
                    right: -10,
                    bottom: -30,
                    child: Text(widget.concept.key,
                        style: TextStyle(fontSize: 150, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: .12))),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: OfflineBanner()),
            if (posts.isEmpty && _s.error != null)
              SliverFillRemaining(child: ErrorState(error: _s.error, onRetry: () => _load(force: true)))
            else if (posts.isEmpty && _s.loading)
              const PostListSkeleton(sliver: true)
            else if (posts.isEmpty)
              SliverFillRemaining(child: EmptyState(icon: Icons.inbox_rounded, title: l.emptyPosts))
            else ...[
              if (subjects.isNotEmpty) ...[
                SliverToBoxAdapter(child: SectionHeader(title: l.subjects)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 92,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (context, i) {
                      final s = subjects[i];
                      return SubjectTile(
                        subject: s,
                        count: bySubject[s]!.length,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => SubjectPostsScreen(classConcept: widget.concept, subject: s, posts: bySubject[s]!),
                        )),
                      );
                    },
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SectionHeader(title: '${l.allPosts} · ${l.postsCount(posts.length)}', icon: Icons.list_alt_rounded),
              ),
              SliverList.builder(
                itemCount: posts.length,
                itemBuilder: (context, i) => PostCard(post: posts[i], heroPrefix: 'class-${widget.concept.key}'),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ],
        ),
      ),
    );
  }
}

class SubjectTile extends StatelessWidget {
  const SubjectTile({super.key, required this.subject, required this.count, required this.onTap});

  final Concept subject;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final color = subject.color ?? Brand.green;
    final locale = Localizations.localeOf(context);
    return AppCard(
      semanticLabel: '${subject.label(locale)}, ${l.postsCount(count)}',
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(gradient: Brand.tint(color), borderRadius: BorderRadius.circular(14)),
          child: Icon(subjectIcons[subject.key] ?? Icons.book_rounded, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(subject.label(locale), maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall),
            Text(l.postsCount(count), style: t.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

/// Subject posts within a class, with a medium filter.
class SubjectPostsScreen extends StatefulWidget {
  const SubjectPostsScreen({super.key, required this.classConcept, required this.subject, required this.posts});

  final Concept classConcept;
  final Concept subject;
  final List<Post> posts;

  @override
  State<SubjectPostsScreen> createState() => _SubjectPostsScreenState();
}

class _SubjectPostsScreenState extends State<SubjectPostsScreen> {
  Concept? _medium;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cfg = context.app.config;
    final locale = Localizations.localeOf(context);
    final color = widget.subject.color ?? Brand.green;
    final mediums = cfg.mediums.where((m) => widget.posts.any((p) => m.ids.any(p.categoryIds.contains))).toList();
    final posts = _medium == null ? widget.posts : widget.posts.where((p) => _medium!.ids.any(p.categoryIds.contains)).toList();
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        flexibleSpace: DecoratedBox(decoration: BoxDecoration(gradient: Brand.tint(color))),
        title: Text('${widget.classConcept.label(locale)} · ${widget.subject.label(locale)}',
            style: const TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (mediums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Wrap(spacing: 8, children: [
                ChoiceChip(label: Text(l.filterAll), selected: _medium == null, onSelected: (_) => setState(() => _medium = null)),
                for (final m in mediums)
                  ChoiceChip(
                    label: Text(m.label(locale)),
                    selected: _medium == m,
                    selectedColor: color.withValues(alpha: .18),
                    onSelected: (_) => setState(() => _medium = m),
                  ),
              ]),
            ),
          for (final p in posts) PostCard(post: p, heroPrefix: 'subj-${widget.subject.key}'),
        ],
      ),
    );
  }
}

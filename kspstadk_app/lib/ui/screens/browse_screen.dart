import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../data/site_config.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import 'class_screen.dart';
import 'home_screen.dart' show ClassBubble;

/// Browse: sections, classes, subjects and every other site category with
/// post counts. New categories on the site appear under "More categories".
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  StreamSubscription<Swr<List<Category>>>? _sub;
  Swr<List<Category>> _s = const Swr(loading: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({bool force = false}) {
    _sub?.cancel();
    _sub = context.app.repo.categories(force: force).listen((s) {
      if (mounted) setState(() => _s = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Twins hold the same posts, so a concept's count is its largest member.
  int _count(List<int> ids, Map<int, Category> byId) =>
      ids.map((i) => byId[i]?.count ?? 0).fold(0, (a, b) => a > b ? a : b);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cfg = context.app.config;
    final locale = Localizations.localeOf(context);
    final cats = _s.data ?? const <Category>[];
    final byId = {for (final c in cats) c.id: c};
    final others = otherCategories(cats, cfg);

    return Scaffold(
      appBar: AppBar(title: Text(l.navBrowse)),
      body: RefreshIndicator(
        onRefresh: () async => _load(force: true),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: OfflineBanner()),
            SliverToBoxAdapter(child: SectionHeader(title: l.classes, icon: Icons.school_rounded, padding: const EdgeInsets.fromLTRB(16, 8, 8, 12))),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 76, mainAxisExtent: 96, crossAxisSpacing: 4),
                itemCount: cfg.classes.length,
                itemBuilder: (context, i) => ClassBubble(concept: cfg.classes[i], index: i, size: 56),
              ),
            ),
            SliverToBoxAdapter(child: SectionHeader(title: l.sections)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, mainAxisExtent: 84, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: cfg.tiles.length,
                itemBuilder: (context, i) {
                  final tile = cfg.tiles[i];
                  final n = _count(tile.ids, byId);
                  return _SectionCard(
                    title: tile.label(locale),
                    subtitle: cats.isEmpty ? null : l.postsCount(n),
                    icon: configIcon(tile.icon),
                    color: tile.color ?? Brand.green,
                    onTap: () => openCategory(context, title: tile.label(locale), ids: tile.ids, color: tile.color),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: SectionHeader(title: l.subjects)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, mainAxisExtent: 84, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: cfg.subjects.length,
                itemBuilder: (context, i) {
                  final s = cfg.subjects[i];
                  return SubjectTile(
                    subject: s,
                    count: _count(s.ids, byId),
                    onTap: () => openCategory(context, title: s.label(locale), ids: s.ids, color: s.color),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(child: SectionHeader(title: l.moreCategories)),
            if (cats.isEmpty && _s.error != null)
              SliverToBoxAdapter(child: SizedBox(height: 320, child: ErrorState(error: _s.error, onRetry: () => _load(force: true))))
            else if (cats.isEmpty)
              const PostListSkeleton(sliver: true, count: 4)
            else
              SliverList.builder(
                itemCount: others.length,
                itemBuilder: (context, i) {
                  final g = others[i];
                  final c = Brand.rainbow[i % Brand.rainbow.length][0];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: AppCard(
                      onTap: () => openCategory(context, title: g.label(locale), ids: g.ids, color: c),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(g.label(locale), style: Theme.of(context).textTheme.titleSmall)),
                        TagChip(label: '${g.count}', color: c),
                        const Icon(Icons.chevron_right_rounded),
                      ]),
                    ),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.color, required this.onTap, this.subtitle});

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return AppCard(
      semanticLabel: '$title ${subtitle ?? ''}',
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(gradient: Brand.tint(color), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall?.copyWith(height: 1.3)),
            if (subtitle != null) Text(subtitle!, style: t.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repository.dart';
import '../../data/site_config.dart';
import '../../data/wp_api.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import '../shell.dart';
import '../widgets/common.dart';
import '../widgets/icons.dart';
import '../widgets/post_card.dart';
import 'class_screen.dart';
import 'notifications_screen.dart';

/// Home: gradient header + configurable sections (assets/config/home_sections.json).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Bumped on pull-to-refresh; every section re-subscribes with force.
  final _refresh = ValueNotifier<int>(0);

  @override
  void dispose() {
    _refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = context.app.config;
    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: 120,
        onRefresh: () async {
          _refresh.value++;
          await Future<void>.delayed(const Duration(milliseconds: 800));
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            const SliverToBoxAdapter(child: OfflineBanner()),
            for (final s in cfg.sections) SliverToBoxAdapter(child: _section(s)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Widget _section(HomeSection s) => switch (s.type) {
        'latest' => _LatestCarousel(count: s.count, refresh: _refresh),
        'tiles' => const _QuickTiles(),
        'classes' => const _ClassStrip(),
        'continue' => const _ContinueReading(),
        'popular' => _Popular(refresh: _refresh),
        'category' => _CategorySection(section: s, refresh: _refresh),
        'join' => const JoinCard(),
        _ => const SizedBox.shrink(),
      };
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final l = AppLocalizations.of(context);
    final dark = t.brightness == Brightness.dark;
    final inbox = context.app.inbox;
    return Container(
      decoration: BoxDecoration(
        gradient: dark ? Brand.darkHeaderGradient : Brand.headerGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
                    alignment: Alignment.center,
                    child: ShaderMask(
                      shaderCallback: (r) => Brand.primaryGradient.createShader(r),
                      child: const Text('K', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.appTitle, style: t.textTheme.titleLarge?.copyWith(color: Colors.white, letterSpacing: .5, height: 1.2)),
                        Text(l.appSubtitle, style: t.textTheme.labelSmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                  ListenableBuilder(
                    listenable: inbox,
                    builder: (context, _) => IconButton(
                      tooltip: l.notifications,
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                      icon: Badge(
                        isLabelVisible: inbox.unread > 0,
                        label: Text('${inbox.unread}'),
                        child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(l.greeting, style: t.textTheme.titleMedium?.copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text(l.homeTagline, style: t.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: .85))),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  button: true,
                  label: l.searchHint,
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => AppShell.of(context)?.selectTab(3),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(children: [
                          const Icon(Icons.search_rounded, color: Brand.muted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(l.searchHint, style: t.textTheme.bodyMedium?.copyWith(color: Brand.muted))),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subscribes to a post page and re-subscribes (forced) on refresh.
class _PageLoader extends StatefulWidget {
  const _PageLoader({required this.query, required this.refresh, required this.builder});

  final Map<String, dynamic> query;
  final ValueNotifier<int>? refresh;
  final Widget Function(BuildContext, Swr<PostPage>) builder;

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader> {
  StreamSubscription<Swr<PostPage>>? _sub;
  Swr<PostPage> _s = const Swr(loading: true);

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_forceLoad);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _forceLoad() => _load(force: true);

  void _load({bool force = false}) {
    _sub?.cancel();
    _sub = context.app.repo.postPage(widget.query, force: force).listen((s) {
      if (mounted) setState(() => _s = s.data == null && _s.data != null ? Swr(data: _s.data, error: s.error, loading: s.loading) : s);
    });
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_forceLoad);
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _s);
}

class _LatestCarousel extends StatefulWidget {
  const _LatestCarousel({required this.count, required this.refresh});

  final int count;
  final ValueNotifier<int> refresh;

  @override
  State<_LatestCarousel> createState() => _LatestCarouselState();
}

class _LatestCarouselState extends State<_LatestCarousel> {
  final _controller = PageController(viewportFraction: .86);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l.latest,
          onSeeAll: () => openCategory(context, title: l.latest, ids: const []),
        ),
        _PageLoader(
          query: WpApi.postsQuery(perPage: widget.count),
          refresh: widget.refresh,
          builder: (context, s) {
            final posts = s.data?.posts ?? const <Post>[];
            if (posts.isEmpty) {
              if (s.error != null) {
                return SizedBox(height: 300, child: ErrorState(error: s.error, onRetry: () => widget.refresh.value++));
              }
              return const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ShimmerBox(height: 200, radius: Brand.radius));
            }
            return Column(children: [
              SizedBox(
                height: 205,
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  itemCount: posts.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 16 : 6, right: 6, bottom: 6),
                    child: PostHeroCard(post: posts[i], heroPrefix: 'latest'),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < posts.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: i == _index ? Brand.primaryGradient : null,
                        color: i == _index ? null : Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              ),
            ]);
          },
        ),
      ],
    );
  }
}

class _QuickTiles extends StatelessWidget {
  const _QuickTiles();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final cfg = context.app.config;
    final locale = Localizations.localeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.quickAccess),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 600 ? 6 : 4;
            final w = c.maxWidth / cols;
            return Wrap(
              children: [
                for (final tile in cfg.tiles)
                  SizedBox(
                    width: w,
                    child: Semantics(
                      button: true,
                      label: tile.label(locale),
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => openCategory(context, title: tile.label(locale), ids: tile.ids, color: tile.color),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Column(children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: Brand.tint(tile.color ?? Brand.green),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(color: (tile.color ?? Brand.green).withValues(alpha: .3), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Icon(configIcon(tile.icon), color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tile.label(locale),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: t.textTheme.labelSmall?.copyWith(height: 1.3, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _ClassStrip extends StatelessWidget {
  const _ClassStrip();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final classes = context.app.config.classes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.classes, icon: Icons.school_rounded),
        SizedBox(
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: classes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => ClassBubble(concept: classes[i], index: i),
          ),
        ),
      ],
    );
  }
}

class ClassBubble extends StatelessWidget {
  const ClassBubble({super.key, required this.concept, required this.index, this.size = 60});

  final Concept concept;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final locale = Localizations.localeOf(context);
    return Semantics(
      button: true,
      label: concept.label(locale),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClassScreen(concept: concept))),
        child: Column(children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(gradient: Brand.rainbowAt(index), shape: BoxShape.circle),
            child: Text(concept.key, style: t.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          Text(locale.languageCode == 'en' ? 'Class' : 'ತರಗತಿ', style: t.textTheme.labelSmall),
        ]),
      ),
    );
  }
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final history = context.app.history;
    return ListenableBuilder(
      listenable: history,
      builder: (context, _) {
        final posts = history.recent(6);
        if (posts.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: l.continueReading, icon: Icons.history_rounded),
            SizedBox(
              height: 176,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => PostMiniCard(post: posts[i], heroPrefix: 'continue', width: 200),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Popular extends StatelessWidget {
  const _Popular({required this.refresh});

  final ValueNotifier<int> refresh;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ids = context.app.config.popularPostIds;
    if (ids.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l.popularDownloads, icon: Icons.local_fire_department_rounded),
        _PageLoader(
          query: WpApi.postsQuery(include: ids, perPage: ids.length),
          refresh: refresh,
          builder: (context, s) {
            final posts = s.data?.posts ?? const <Post>[];
            return SizedBox(
              height: 176,
              child: posts.isEmpty
                  ? ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: const [ShimmerBox(width: 200, height: 160), SizedBox(width: 12), ShimmerBox(width: 200, height: 160)],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: posts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) =>
                          PostMiniCard(post: posts[i], heroPrefix: 'popular', width: 200, icon: Icons.download_for_offline_rounded),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.section, required this.refresh});

  final HomeSection section;
  final ValueNotifier<int> refresh;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final title = (locale.languageCode == 'en' ? section.en : section.kn) ?? section.kn ?? section.en ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, onSeeAll: () => openCategory(context, title: title, ids: section.ids)),
        _PageLoader(
          query: WpApi.postsQuery(categories: section.ids, perPage: section.count),
          refresh: refresh,
          builder: (context, s) {
            final posts = s.data?.posts ?? const <Post>[];
            if (posts.isEmpty) return s.error != null ? const SizedBox.shrink() : PostListSkeleton(count: section.count.clamp(1, 3));
            return Column(children: [
              for (final p in posts) PostCard(post: p, heroPrefix: 'sec-${section.ids.join()}'),
            ]);
          },
        ),
      ],
    );
  }
}

/// WhatsApp / Telegram join card (links from the config file).
class JoinCard extends StatelessWidget {
  const JoinCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final cfg = context.app.config;
    if (cfg.whatsappUrl == null && cfg.telegramUrl == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF075E54), Color(0xFF128C7E), Color(0xFF229ED9)]),
          borderRadius: BorderRadius.circular(Brand.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.joinTitle, style: t.textTheme.titleMedium?.copyWith(color: Colors.white)),
                  Text(l.joinSubtitle, style: t.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              if (cfg.whatsappUrl != null)
                Expanded(
                  child: _JoinPill(
                    label: l.joinWhatsapp,
                    icon: Icons.forum_rounded,
                    color: const Color(0xFF25D366),
                    onTap: () => openLink(context, cfg.whatsappUrl!),
                  ),
                ),
              if (cfg.whatsappUrl != null && cfg.telegramUrl != null) const SizedBox(width: 10),
              if (cfg.telegramUrl != null)
                Expanded(
                  child: _JoinPill(
                    label: l.joinTelegram,
                    icon: Icons.send_rounded,
                    color: const Color(0xFF2AABEE),
                    onTap: () => openExternal(cfg.telegramUrl!),
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _JoinPill extends StatelessWidget {
  const _JoinPill({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF0F1324))),
              ),
            ]),
          ),
        ),
      );
}

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/site_config.dart';
import '../../state/app_state.dart';
import '../routes.dart';
import 'common.dart';

/// Best short label for a post: its configured section/class/subject in the
/// current language, else its first category name.
String postLabel(BuildContext context, Post p) {
  final cfg = context.app.config;
  final locale = Localizations.localeOf(context);
  for (final list in [cfg.tiles, cfg.classes, cfg.subjects]) {
    for (final c in list) {
      if (c.ids.any(p.categoryIds.contains)) return c.label(locale);
    }
  }
  final cats = p.categories;
  if (cats.isEmpty) return '';
  final pick = locale.languageCode == 'en'
      ? cats.firstWhere((c) => !RegExp(r'[ಀ-೿]').hasMatch(c.name), orElse: () => cats.first)
      : cats.firstWhere((c) => RegExp(r'[ಀ-೿]').hasMatch(c.name), orElse: () => cats.first);
  return CategoryGroup([Category(id: pick.id, name: pick.name, slug: pick.slug, parent: 0, count: 0)]).label(locale);
}

Color postColor(BuildContext context, Post p) {
  final cfg = context.app.config;
  for (final c in [...cfg.subjects, ...cfg.tiles]) {
    if (c.color != null && c.ids.any(p.categoryIds.contains)) return c.color!;
  }
  return Theme.of(context).colorScheme.primary;
}

/// List row: thumbnail, title, label chip and date.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.heroPrefix = 'list'});

  final Post post;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final label = postLabel(context, post);
    final tag = '$heroPrefix-${post.id}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: AppCard(
        semanticLabel: post.title,
        onTap: () => openPost(context, post.id, preview: post, heroTag: tag),
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Brand.radiusSmall),
                child: NetImage(post.thumbUrl, width: 96, height: 76, memWidth: 300),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: t.textTheme.titleSmall?.copyWith(height: 1.4)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (label.isNotEmpty) Flexible(child: TagChip(label: label, color: postColor(context, post))),
                      const SizedBox(width: 8),
                      Text(friendlyDate(context, post.date),
                          style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large image card for the "Latest" carousel.
class PostHeroCard extends StatelessWidget {
  const PostHeroCard({super.key, required this.post, this.heroPrefix = 'latest'});

  final Post post;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tag = '$heroPrefix-${post.id}';
    return Semantics(
      button: true,
      label: post.title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => openPost(context, post.id, preview: post, heroTag: tag),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(Brand.radius), boxShadow: Brand.softShadow(context)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Brand.radius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(tag: tag, child: NetImage(post.imageUrl, memWidth: 800)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC0F1324)],
                      stops: [.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TagChip(label: postLabel(context, post), color: Colors.white),
                      const SizedBox(height: 6),
                      Text(post.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleSmall?.copyWith(color: Colors.white, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal card (continue reading, popular).
class PostMiniCard extends StatelessWidget {
  const PostMiniCard({super.key, required this.post, this.heroPrefix = 'mini', this.width = 220, this.icon});

  final Post post;
  final String heroPrefix;
  final double width;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final tag = '$heroPrefix-${post.id}';
    return SizedBox(
      width: width,
      child: AppCard(
        semanticLabel: post.title,
        onTap: () => openPost(context, post.id, preview: post, heroTag: tag),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Brand.radius)),
              child: Hero(tag: tag, child: NetImage(post.thumbUrl, height: 100, width: width, memWidth: 400)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: t.colorScheme.primary), const SizedBox(width: 6)],
                  Expanded(
                    child: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.labelLarge?.copyWith(height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

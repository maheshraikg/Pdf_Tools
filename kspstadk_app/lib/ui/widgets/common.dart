import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme.dart';
import '../../data/repository.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

/// White rounded card with a soft shadow (dark: outlined surface).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding, this.radius = Brand.radius, this.color, this.semanticLabel});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? scheme.surfaceContainerLowest,
          borderRadius: shape,
          boxShadow: Brand.softShadow(context),
          border: dark ? Border.all(color: scheme.outlineVariant) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ),
      ),
    );
  }
}

/// Green → blue gradient pill button.
class GradientPill extends StatelessWidget {
  const GradientPill({super.key, required this.label, this.icon, this.onTap, this.gradient = Brand.primaryGradient, this.dense = false});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Gradient gradient;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onTap == null ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey]) : gradient,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [BoxShadow(color: Brand.blue.withValues(alpha: .22), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: dense ? 36 : 46),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 20, vertical: dense ? 6 : 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, color: Colors.white, size: dense ? 18 : 20), const SizedBox(width: 8)],
                    Flexible(child: Text(label, style: style, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll, this.icon, this.padding});

  final String title;
  final VoidCallback? onSeeAll;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 22, 8, 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(gradient: Brand.primaryGradient, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[Icon(icon, size: 20, color: t.colorScheme.primary), const SizedBox(width: 6)],
          Expanded(child: Semantics(header: true, child: Text(title, style: t.textTheme.titleMedium))),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: Text(AppLocalizations.of(context).seeAll)),
        ],
      ),
    );
  }
}

/// Cached network image with a shimmer placeholder and a calm fallback.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height, this.memWidth = 600});

  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// Decode width (keeps memory and jank low in lists).
  final int memWidth;

  /// Tests turn network images off (no platform cache plugins there).
  static bool enabled = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary.withValues(alpha: .15), scheme.secondary.withValues(alpha: .15)]),
      ),
      child: Icon(Icons.menu_book_rounded, color: scheme.primary.withValues(alpha: .55), size: 32),
    );
    if (url == null || url!.isEmpty || !enabled) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memWidth,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => ShimmerBox(width: width, height: height, radius: 0),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height, this.radius = 12});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF1C2438) : const Color(0xFFE8ECF4),
      highlightColor: dark ? const Color(0xFF2A3350) : const Color(0xFFF7F9FC),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      ),
    );
  }
}

/// Skeleton for a list of [PostCard]s.
class PostListSkeleton extends StatelessWidget {
  const PostListSkeleton({super.key, this.count = 6, this.sliver = false});

  final int count;
  final bool sliver;

  Widget _item(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
        child: Row(
          children: [
            ShimmerBox(width: 96, height: 76, radius: 14),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(height: 14, width: 180),
                  SizedBox(height: 10),
                  ShimmerBox(height: 10, width: 90),
                ],
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (sliver) {
      return SliverList.builder(itemCount: count, itemBuilder: (c, _) => _item(c));
    }
    return Semantics(
      label: AppLocalizations.of(context).downloading,
      child: Column(children: List.generate(count, (_) => _item(context))),
    );
  }
}

/// Friendly empty state with an illustration drawn in code (no image assets).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 130,
              child: CustomPaint(
                painter: _BlobPainter(t.colorScheme.primary, t.colorScheme.secondary),
                child: Center(child: Icon(icon, size: 56, color: t.colorScheme.primary)),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: t.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.a, this.b);

  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final path = Path();
    const n = 9;
    for (var i = 0; i <= n; i++) {
      final ang = i / n * 2 * math.pi;
      final r = size.shortestSide * (.42 + .06 * math.sin(i * 2.3));
      final p = c + Offset(math.cos(ang) * r * 1.12, math.sin(ang) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: [a.withValues(alpha: .16), b.withValues(alpha: .16)]).createShader(Offset.zero & size)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    final dot = Paint()..color = b.withValues(alpha: .35);
    canvas.drawCircle(c + Offset(size.width * .38, -size.height * .32), 6, dot);
    canvas.drawCircle(c + Offset(-size.width * .40, size.height * .30), 4, dot..color = a.withValues(alpha: .35));
    canvas.drawCircle(c + Offset(size.width * .30, size.height * .36), 3, dot);
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.a != a || old.b != b;
}

/// Error view with retry; recognises "offline".
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final offline = isOfflineError(error);
    return EmptyState(
      icon: offline ? Icons.wifi_off_rounded : Icons.cloud_off_rounded,
      title: offline ? l.errorOffline : l.errorGeneric,
      subtitle: offline ? l.errorOfflineHint : null,
      action: GradientPill(label: l.retry, icon: Icons.refresh_rounded, onTap: onRetry),
    );
  }
}

/// Thin banner shown while the device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final net = context.app.network;
    return ListenableBuilder(
      listenable: net,
      builder: (context, _) => AnimatedSize(
        duration: const Duration(milliseconds: 250),
        child: net.online
            ? const SizedBox(width: double.infinity)
            : Container(
                width: double.infinity,
                color: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(AppLocalizations.of(context).offlineBanner,
                            style: const TextStyle(color: Colors.white, fontSize: 12.5)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Small rounded label chip.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.color, this.onTap});

  final String label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Material(
      color: c.withValues(alpha: .12),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

/// "Today", "Yesterday" or a localised date.
String friendlyDate(BuildContext context, DateTime d) {
  final l = AppLocalizations.of(context);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return l.today;
  if (diff == 1) return l.yesterday;
  final locale = Localizations.localeOf(context).languageCode;
  try {
    return DateFormat.yMMMd(locale).format(d);
  } catch (_) {
    return DateFormat.yMMMd('en').format(d);
  }
}

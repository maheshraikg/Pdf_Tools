import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

/// Inline post image: cached, rounded; tap opens a pinch-zoom viewer.
class ZoomableNetImage extends StatelessWidget {
  const ZoomableNetImage({super.key, required this.url, this.aspectRatio, this.alt});

  final String url;
  final double? aspectRatio;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final tag = 'img-${identityHashCode(this)}';
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(Brand.radiusSmall),
      child: aspectRatio != null || !NetImage.enabled
          ? AspectRatio(aspectRatio: aspectRatio ?? 16 / 9, child: NetImage(url, memWidth: 1000))
          : CachedNetworkImage(
              imageUrl: url,
              memCacheWidth: 1000,
              placeholder: (_, _) => const ShimmerBox(height: 200, radius: 0),
              errorWidget: (_, _, _) => const SizedBox.shrink(),
            ),
    );
    return Semantics(
      image: true,
      label: alt,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (_, _, _) => _FullImage(url: url, tag: tag),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        )),
        child: Hero(tag: tag, child: img),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  const _FullImage({required this.url, required this.tag});

  final String url;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, foregroundColor: Colors.white),
      extendBodyBehindAppBar: true,
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 6,
        child: Center(child: Hero(tag: tag, child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain))),
      ),
    );
  }
}

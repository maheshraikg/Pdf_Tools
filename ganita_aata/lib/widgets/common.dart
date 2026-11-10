import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_theme.dart';
import 'motion.dart';

/// A flat 2D vector illustration from assets/images (Fluent Emoji "Flat"
/// style, MIT licence). Vectors stay sharp at any size.
class AppImage extends StatelessWidget {
  const AppImage(this.name, {super.key, this.size = 48, this.semanticLabel});

  final String name;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/$name.svg',
      width: size,
      height: size,
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (c, e, s) => SizedBox(width: size, height: size),
    );
  }
}

/// Flat 2D game art from assets/game (Kenney, CC0): animal avatars,
/// scenes, scenery, medals and cars.
class GameImage extends StatelessWidget {
  const GameImage(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.semanticLabel,
  });

  final Alignment alignment;

  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/game/$name.png',
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (c, e, s) => SizedBox(width: width, height: height),
    );
  }
}

/// Sky colour shared by all scene backgrounds.
const skyColor = Color(0xFFCEEEFB);

/// Scene backgrounds (`assets/game/bg_<name>.png`).
enum Scene { grass, forest, fall, castles, desert }

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.avatarId, this.size = 56, this.selected = false});

  final String avatarId;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected ? const [Color(0xFFFFE7B8), Color(0xFFFFC46B)] : const [Colors.white, Color(0xFFF1ECFF)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppColors.primary : Colors.white, width: selected ? 4 : 3),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: GameImage(avatarId, width: size * 0.86, height: size * 0.86),
    );
  }
}

/// A rounded pill with an icon and a value (coins, streak, timer…).
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.coin,
    this.semantics,
    this.compact = false,
  });

  final Widget icon;
  final String label;
  final Color color;
  final String? semantics;

  /// Smaller text and padding (game top bar).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: Container(
        padding: EdgeInsets.fromLTRB(compact ? 6 : 8, compact ? 3 : 4, compact ? 10 : 14, compact ? 3 : 4),
        decoration: BoxDecoration(
          color: AppColors.night0.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: display(compact ? 18 : 21, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.semantics, this.compact = false});

  final int coins;
  final String? semantics;
  final bool compact;

  @override
  Widget build(BuildContext context) => StatChip(
    icon: AppImage('coin', size: compact ? 22 : 28),
    label: '$coins',
    semantics: semantics,
    compact: compact,
  );
}

Color darken(Color c, [double amount = 0.18]) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// A chunky, game-style 3D button: a coloured face on a darker base that
/// sinks when pressed.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = AppColors.primary,
    this.edgeColor,
    this.depth = 6,
    this.radius = 22,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.gradient = true,
    this.colors,
  });

  /// Two-tone (top, bottom) face; overrides [color].

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? edgeColor;
  final double depth;
  final double radius;
  final EdgeInsets padding;
  final bool gradient;
  final List<Color>? colors;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = widget.colors?.last ?? widget.color;
    final edge = widget.edgeColor ?? darken(face, 0.14);
    final sink = _down ? widget.depth - 1.5 : 0.0;
    final r = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.only(top: sink),
          child: Container(
            decoration: BoxDecoration(
              color: edge,
              borderRadius: r,
              boxShadow: _down
                  ? null
                  : [BoxShadow(color: edge.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 6))],
            ),
            padding: EdgeInsets.only(bottom: widget.depth - sink),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: widget.gradient
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.colors ?? [Color.lerp(face, Colors.white, 0.18)!, face],
                      )
                    : null,
                color: widget.gradient ? null : face,
              ),
              child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

/// A big, colourful tappable card with a 3D edge.
class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    // Card colours get their matching two-tone gradient.
    final pair = AppColors.cards.where((c) => c.$1 == color).firstOrNull;
    return ChunkyButton(
      onTap: onTap ?? () {},
      color: color,
      colors: pair == null ? null : [pair.$1, pair.$2],
      radius: 26,
      depth: 6,
      padding: padding,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// The night sky behind kids' screens: indigo-to-violet gradient, stars,
/// soft glowing planets and, optionally, a landscape silhouette.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child, this.colors, this.clouds = false, this.scene});

  final Widget child;

  /// Custom gradient (top → bottom); defaults to the night sky.
  final List<Color>? colors;
  final bool clouds;

  /// A landscape drawn along the bottom as a night silhouette.
  final Scene? scene;

  static const sky = [AppColors.night0, AppColors.night1, AppColors.night2];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors ?? sky),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _SkyPainter())),
          ),
          if (scene != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 150,
              child: ShaderMask(
                // Fade the top so the band melts into the sky.
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xFF000000)],
                  stops: [0, 0.45],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: ColorFiltered(
                  // Day landscape → a violet night tree-line along the bottom.
                  colorFilter: const ColorFilter.mode(Color(0xFF4A35B0), BlendMode.modulate),
                  child: GameImage('bg_${scene!.name}', fit: BoxFit.cover, alignment: const Alignment(0, 0.05)),
                ),
              ),
            ),
          if (clouds) const Positioned.fill(child: Opacity(opacity: 0.18, child: DriftingClouds())),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(11);
    // Soft glowing planets.
    for (final (x, y, r, c) in const [
      (0.88, 0.10, 70.0, Color(0x33FF7AD9)),
      (0.05, 0.42, 90.0, Color(0x2A3FD5FF)),
      (0.75, 0.68, 60.0, Color(0x26FFC23D)),
    ]) {
      canvas.drawCircle(
        Offset(size.width * x, size.height * y),
        r,
        Paint()
          ..shader = RadialGradient(colors: [c, c.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: Offset(size.width * x, size.height * y), radius: r)),
      );
    }
    // Stars.
    final p = Paint();
    for (var i = 0; i < 70; i++) {
      final big = rng.nextDouble() < 0.12;
      p.color = Colors.white.withValues(alpha: 0.25 + rng.nextDouble() * 0.6);
      final o = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height * 0.85);
      if (big) {
        // Four-point sparkle.
        final r = 3.0 + rng.nextDouble() * 2;
        final path = Path()
          ..moveTo(o.dx, o.dy - r * 2)
          ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 2, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r * 2)
          ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 2, o.dy)
          ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r * 2);
        canvas.drawPath(path, p);
      } else {
        canvas.drawCircle(o, 0.8 + rng.nextDouble() * 1.4, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The owl mascot with a speech bubble.
class MascotBubble extends StatelessWidget {
  const MascotBubble({super.key, required this.text, this.size = 72});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Bob(
          child: GameImage('av_owl', width: size, height: size),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: AppColors.ink.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(text, style: display(18, weight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

/// White rounded panel with a soft shadow.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Colors.white});

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.ink.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

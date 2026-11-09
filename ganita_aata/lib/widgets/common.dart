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
  const GameImage(this.name, {super.key, this.width, this.height, this.fit = BoxFit.contain, this.semanticLabel});

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
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color, width: 2.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 4),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: display(compact ? 18 : 21)),
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
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final Color? edgeColor;
  final double depth;
  final double radius;
  final EdgeInsets padding;
  final bool gradient;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final face = widget.color;
    final edge = widget.edgeColor ?? darken(face);
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
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.lerp(face, Colors.white, 0.18)!, face],
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
    return ChunkyButton(
      onTap: onTap ?? () {},
      color: color,
      radius: 26,
      depth: 6,
      padding: padding,
      child: SizedBox(width: double.infinity, child: child),
    );
  }
}

/// Soft gradient with a few floating bubbles, used behind screens.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child, this.colors, this.clouds = false, this.scene});

  final Widget child;
  final List<Color>? colors;
  final bool clouds;

  /// A landscape drawn along the bottom, under the sky.
  final Scene? scene;

  @override
  Widget build(BuildContext context) {
    if (scene != null) {
      return ColoredBox(
        color: skyColor,
        child: Stack(
          children: [
            Positioned(left: 0, right: 0, bottom: 0, child: GameImage('bg_${scene!.name}', fit: BoxFit.fitWidth)),
            if (clouds) const Positioned.fill(child: DriftingClouds()),
            Positioned.fill(child: child),
          ],
        ),
      );
    }
    final c = colors ?? const [Color(0xFFBFE6FF), Color(0xFFFFF4E0)];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _BubblesPainter())),
          ),
          if (clouds) const Positioned.fill(child: DriftingClouds()),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _BubblesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(7);
    final p = Paint();
    for (var i = 0; i < 10; i++) {
      p.color = Colors.white.withValues(alpha: 0.18 + rng.nextDouble() * 0.15);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        18 + rng.nextDouble() * 50,
        p,
      );
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

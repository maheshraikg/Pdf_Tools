import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'common.dart';

/// Turns all looping decoration animations on or off. Tests switch it off
/// (looping animations never "settle"); the app also stops them when the
/// phone's "remove animations" accessibility setting is on.
bool motionEnabled = true;

bool _motionOn(BuildContext context) => motionEnabled && !MediaQuery.disableAnimationsOf(context);

/// A looping 0→1 driver for idle decoration animations.
abstract class _LoopState<T extends StatefulWidget> extends State<T> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  Duration get period;

  Animation<double> get loop => _c ?? const AlwaysStoppedAnimation(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final on = _motionOn(context);
    if (on && _c == null) {
      _c = AnimationController(vsync: this, duration: period)..repeat();
    } else if (!on && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }
}

/// Gently floats its child up and down with a little sway (mascot, icons).
class Bob extends StatefulWidget {
  const Bob({super.key, required this.child, this.height = 6, this.tilt = 0.04, this.period = 2400, this.phase = 0});

  final Widget child;
  final double height;
  final double tilt;
  final int period;
  final double phase;

  @override
  State<Bob> createState() => _BobState();
}

class _BobState extends _LoopState<Bob> {
  @override
  Duration get period => Duration(milliseconds: widget.period);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, child) {
      final t = (loop.value + widget.phase) * 2 * pi;
      return Transform.translate(
        offset: Offset(0, sin(t) * widget.height),
        child: Transform.rotate(angle: sin(t + 1) * widget.tilt, child: child),
      );
    },
    child: widget.child,
  );
}

/// Breathes (scales) its child softly — for the main call to action.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child, this.amount = 0.04, this.period = 1600});

  final Widget child;
  final double amount;
  final int period;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends _LoopState<Pulse> {
  @override
  Duration get period => Duration(milliseconds: widget.period);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, child) =>
        Transform.scale(scale: 1 + (sin(loop.value * 2 * pi) + 1) / 2 * widget.amount, child: child),
    child: widget.child,
  );
}

/// Every few seconds gives its child a short playful wiggle.
class Wiggle extends StatefulWidget {
  const Wiggle({super.key, required this.child, this.period = 3200, this.phase = 0});

  final Widget child;
  final int period;
  final double phase;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends _LoopState<Wiggle> {
  @override
  Duration get period => Duration(milliseconds: widget.period);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, child) {
      final v = (loop.value + widget.phase) % 1;
      // Wiggle during the first 15% of each cycle, rest otherwise.
      final w = v < 0.15 ? sin(v / 0.15 * pi * 4) * (1 - v / 0.15) : 0.0;
      return Transform.rotate(
        angle: w * 0.18,
        child: Transform.scale(scale: 1 + w.abs() * 0.08, child: child),
      );
    },
    child: widget.child,
  );
}

/// Clouds drifting slowly across the sky.
class DriftingClouds extends StatefulWidget {
  const DriftingClouds({super.key});

  @override
  State<DriftingClouds> createState() => _DriftingCloudsState();
}

class _DriftingCloudsState extends _LoopState<DriftingClouds> {
  @override
  Duration get period => const Duration(seconds: 60);

  static const _clouds = [
    ('sc_cloud1', 120.0, 70.0, 0.0),
    ('sc_cloud3', 100.0, 170.0, 0.45),
    ('sc_cloud2', 90.0, 270.0, 0.75),
  ];

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: loop,
        builder: (context, _) => Stack(
          children: [
            for (final (img, w, top, phase) in _clouds)
              Positioned(
                top: top,
                left: ((loop.value + phase) % 1) * (box.maxWidth + w) - w,
                child: GameImage(img, width: w),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Bounces its child in (fade + rise + scale) after [delay].
class Entrance extends StatefulWidget {
  const Entrance({super.key, required this.child, this.delay = 0});

  final Widget child;

  /// Milliseconds before the child appears (for staggered lists).
  final int delay;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    if (!motionEnabled) {
      _c.value = 1;
    } else {
      _t = Timer(Duration(milliseconds: widget.delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Opacity(
        opacity: _c.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - curve.value) * 30),
          child: Transform.scale(scale: 0.8 + 0.2 * curve.value, child: child),
        ),
      ),
      child: widget.child,
    );
  }
}

/// "+1" with a coin that floats up and fades — shown on a right answer.
class FloatingReward extends StatelessWidget {
  const FloatingReward({super.key, this.text = '+1'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (context, t, child) => Opacity(
          opacity: (1 - t).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, -70 * t),
            child: Transform.scale(scale: 0.7 + 0.6 * Curves.elasticOut.transform(t.clamp(0.0, 1.0)), child: child),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppImage('coin', size: 34),
            const SizedBox(width: 4),
            Text(
              text,
              style: display(
                30,
                color: AppColors.primaryDark,
              ).copyWith(shadows: const [Shadow(color: Colors.white, blurRadius: 6)]),
            ),
          ],
        ),
      ),
    );
  }
}

/// A star burst around a tapped spot (correct answers).
class StarBurst extends StatelessWidget {
  const StarBurst({super.key, this.size = 160});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              for (var i = 0; i < 8; i++)
                Positioned(
                  left: size / 2 - 12 + cos(i * pi / 4) * size * 0.42 * t,
                  top: size / 2 - 12 + sin(i * pi / 4) * size * 0.42 * t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Transform.rotate(angle: t * 3, child: const AppImage('star', size: 24)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the current run of right answers ("3 in a row") with a flame.
class ComboBadge extends StatelessWidget {
  const ComboBadge({super.key, required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (c, a) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
        child: c,
      ),
      child: combo < 2
          ? const SizedBox(key: ValueKey(0), height: 36)
          : Container(
              key: ValueKey(combo),
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF9F1C), Color(0xFFFF5E5E)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x55FF5E5E), blurRadius: 8, offset: Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppImage('fire', size: 24),
                  const SizedBox(width: 4),
                  Text('×$combo', style: display(22, color: Colors.white, height: 1)),
                ],
              ),
            ),
    );
  }
}

/// A soft light sweep across its child every few seconds (gold buttons).
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child, this.period = 3200, this.radius = 24});

  final Widget child;
  final int period;
  final double radius;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends _LoopState<Shimmer> {
  @override
  Duration get period => Duration(milliseconds: widget.period);

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      Positioned.fill(
        child: IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: AnimatedBuilder(
              animation: loop,
              builder: (context, _) {
                // Sweep during the first 35% of each cycle.
                final v = (loop.value / 0.35).clamp(0.0, 1.0);
                if (v <= 0 || v >= 1) return const SizedBox.shrink();
                return FractionallySizedBox(
                  widthFactor: 0.35,
                  alignment: Alignment(-1.6 + 3.2 * v, 0),
                  child: Transform(
                    transform: Matrix4.skewX(-0.35),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.45),
                            Colors.white.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
}

/// Counts a number up from 0 when it first appears (scores, coins).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.builder, this.ms = 900});

  final int value;
  final Widget Function(BuildContext context, int shown) builder;
  final int ms;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: Duration(milliseconds: motionEnabled ? ms : 1),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => builder(context, v.round()),
    );
  }
}

/// The owl mascot reacting to an answer: a happy hop or a gentle "hmm" tilt.
class OwlReaction extends StatelessWidget {
  const OwlReaction({super.key, required this.happy, this.size = 44});

  final bool happy;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      builder: (context, t, child) {
        if (happy) {
          final hop = sin(t * pi * 2) * (1 - t);
          return Transform.translate(
            offset: Offset(0, -18 * hop.abs()),
            child: Transform.scale(scale: 1 + 0.15 * hop.abs(), child: child),
          );
        }
        return Transform.rotate(angle: sin(t * pi * 3) * 0.2 * (1 - t), child: child);
      },
      child: GameImage('av_owl', width: size, height: size),
    );
  }
}

/// Screen-to-screen transition: the new page zooms in softly with a fade.
class PlayfulPageTransitionsBuilder extends PageTransitionsBuilder {
  const PlayfulPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final a = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    final out = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(a),
        child: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.6).animate(out),
          child: ScaleTransition(scale: Tween(begin: 1.0, end: 0.96).animate(out), child: child),
        ),
      ),
    );
  }
}

/// A thin bar showing the time left in a round; turns orange near the end.
class TimeBar extends StatelessWidget {
  const TimeBar({super.key, required this.secondsLeft, required this.total});

  final int secondsLeft;
  final int total;

  @override
  Widget build(BuildContext context) {
    final f = total <= 0 ? 0.0 : (secondsLeft / total).clamp(0.0, 1.0);
    final low = secondsLeft <= 10;
    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: f),
        duration: const Duration(milliseconds: 950),
        builder: (context, v, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: v,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                colors: low ? const [Color(0xFFFFB86B), Color(0xFFFF6B6B)] : AppColors.goldGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: (low ? const Color(0xFFFF8A5B) : AppColors.primary).withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The night sky's stars, softly twinkling, and glowing planets.
class TwinklingSky extends StatefulWidget {
  const TwinklingSky({super.key});

  @override
  State<TwinklingSky> createState() => _TwinklingSkyState();
}

class _TwinklingSkyState extends _LoopState<TwinklingSky> {
  @override
  Duration get period => const Duration(seconds: 5);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, _) => CustomPaint(painter: _SkyPainter(loop.value)),
  );
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t);

  /// 0–1 twinkle phase.
  final double t;

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
      final base = 0.25 + rng.nextDouble() * 0.6;
      final phase = rng.nextDouble() * 2 * pi;
      p.color = Colors.white.withValues(alpha: (base * (0.55 + 0.45 * sin(t * 2 * pi + phase))).clamp(0.0, 1.0));
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
  bool shouldRepaint(_SkyPainter old) => old.t != t;
}

/// The living sky behind the Today header: it follows the prayer times
/// (night, dawn, day, afternoon, dusk) with twinkling stars, a glowing moon
/// or sun, drifting clouds and a mosque on the horizon.
library;

import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

enum SkyPhase { night, dawn, day, afternoon, dusk }

class SkyScene extends StatefulWidget {
  const SkyScene({super.key, required this.phase, required this.child});

  final SkyPhase phase;
  final Widget child;

  @override
  State<SkyScene> createState() => _SkySceneState();
}

class _SkySceneState extends State<SkyScene>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );

  // Still in widget tests (an endless animation never settles there).
  static final _test = Platform.environment.containsKey('FLUTTER_TEST');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still =
        _test || (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (still) {
      _c.stop();
      _c.value = 0.3;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SkyPainter(widget.phase, _c), child: widget.child);
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.phase, this.t) : super(repaint: t);

  final SkyPhase phase;
  final Animation<double> t;

  static final _stars = () {
    final r = math.Random(7);
    return [
      for (var i = 0; i < 70; i++)
        (r.nextDouble(), r.nextDouble() * 0.75, r.nextDouble(), r.nextDouble()),
    ];
  }();

  List<Color> get _sky => switch (phase) {
    SkyPhase.night => const [
      Color(0xFF070F2B),
      Color(0xFF122556),
      Color(0xFF0B4440),
    ],
    SkyPhase.dawn => const [
      Color(0xFF1B2552),
      Color(0xFF5E3F7E),
      Color(0xFFC9755C),
    ],
    SkyPhase.day => const [kEmeraldDeep, kEmerald, kTeal],
    SkyPhase.afternoon => const [
      Color(0xFF0B4D41),
      Color(0xFF26704F),
      Color(0xFF9C7A2C),
    ],
    SkyPhase.dusk => const [
      Color(0xFF221844),
      Color(0xFF6A3456),
      Color(0xFFC8643A),
    ],
  };

  double get _starAlpha => switch (phase) {
    SkyPhase.night => 1,
    SkyPhase.dawn => 0.35,
    SkyPhase.dusk => 0.55,
    _ => 0,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final v = t.value;
    final wave = math.sin(2 * math.pi * v);

    // Sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _sky,
        ).createShader(Offset.zero & size),
    );

    // Stars, each twinkling at its own pace.
    final sa = _starAlpha;
    if (sa > 0) {
      final p = Paint();
      for (final (x, y, speed, phase0) in _stars) {
        final tw =
            0.35 +
            0.65 *
                (0.5 +
                    0.5 *
                        math.sin(2 * math.pi * (v * (2 + speed * 4) + phase0)));
        p.color = Colors.white.withValues(alpha: sa * tw * 0.9);
        canvas.drawCircle(Offset(x * w, y * h), 0.6 + speed * 1.1, p);
      }
      // Now and then a shooting star.
      if (phase == SkyPhase.night && v > 0.55 && v < 0.6) {
        final k = (v - 0.55) / 0.05;
        final start = Offset(w * (0.15 + 0.45 * k), h * (0.08 + 0.18 * k));
        final tail = start - Offset(w * 0.12, h * 0.05);
        canvas.drawLine(
          tail,
          start,
          Paint()
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.9 * (1 - k)),
              ],
            ).createShader(Rect.fromPoints(tail, start)),
        );
      }
    }

    // Moon or sun, softly floating.
    final night = phase == SkyPhase.night;
    final low = phase == SkyPhase.dawn || phase == SkyPhase.dusk;
    final c = Offset(
      w * (low ? 0.8 : 0.84),
      h *
              (low
                  ? 0.62
                  : phase == SkyPhase.afternoon
                  ? 0.36
                  : 0.2) +
          wave * 3,
    );
    final r = math.min(w, h) * (night ? 0.075 : 0.085);
    final glow = night
        ? const Color(0xFFFFF4D6)
        : (low ? const Color(0xFFFFB36B) : kGoldSoft);
    canvas.drawCircle(
      c,
      r * 3.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            glow.withValues(alpha: 0.35 + 0.08 * wave),
            glow.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * 3.2)),
    );
    if (night) {
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(Rect.fromCircle(center: c, radius: r)),
        Path()..addOval(
          Rect.fromCircle(
            center: c + Offset(r * 0.45, -r * 0.2),
            radius: r * 0.9,
          ),
        ),
      );
      canvas.drawPath(moon, Paint()..color = const Color(0xFFFFF6DC));
    } else {
      // Sun with slowly turning rays.
      final rays = Paint()
        ..color = glow.withValues(alpha: 0.5)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 12; i++) {
        final a = 2 * math.pi * (i / 12 + v / 3);
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(
          c + d * r * 1.35,
          c + d * r * (1.75 + 0.15 * math.sin(2 * math.pi * v * 2 + i)),
          rays,
        );
      }
      canvas.drawCircle(
        c,
        r,
        Paint()..color = low ? const Color(0xFFFFC27A) : kGold,
      );
    }

    // Drifting clouds.
    final cloud = Paint()
      ..color = Colors.white.withValues(alpha: night ? 0.05 : 0.1);
    for (final (y, s, sp, off) in const [
      (0.16, 1.0, 1.0, 0.0),
      (0.34, 0.7, 2.0, 0.45),
      (0.52, 0.85, 1.0, 0.8),
    ]) {
      final x = (((v * sp + off) % 1) * 1.5 - 0.25) * w;
      final cy = y * h, u = w * 0.07 * s;
      // One shape, so the puffs do not show where they overlap.
      canvas.drawPath(
        Path()
          ..addOval(
            Rect.fromCenter(
              center: Offset(x, cy),
              width: u * 3.2,
              height: u * 1.1,
            ),
          )
          ..addOval(
            Rect.fromCircle(
              center: Offset(x - u * 0.5, cy - u * 0.35),
              radius: u * 0.6,
            ),
          )
          ..addOval(
            Rect.fromCircle(
              center: Offset(x + u * 0.35, cy - u * 0.45),
              radius: u * 0.75,
            ),
          ),
        cloud,
      );
    }

    // Mosque on the horizon.
    final ground = h * 0.97;
    final sil = Paint()
      ..color = Colors.black.withValues(alpha: night ? 0.32 : 0.2);
    final hill = Path()
      ..moveTo(0, h)
      ..lineTo(0, ground - h * 0.03)
      ..quadraticBezierTo(
        w * 0.3,
        ground - h * 0.08,
        w * 0.6,
        ground - h * 0.03,
      )
      ..quadraticBezierTo(w * 0.85, ground, w, ground - h * 0.05)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(hill, sil);
    final mx = w * 0.72, unit = math.min(w, h) * 0.05;
    final base = ground - h * 0.03;
    final m = Path()
      // Hall.
      ..addRect(
        Rect.fromLTRB(
          mx - unit * 2.4,
          base - unit * 1.6,
          mx + unit * 2.4,
          base + 4,
        ),
      )
      // Dome.
      ..addOval(
        Rect.fromCenter(
          center: Offset(mx, base - unit * 1.9),
          width: unit * 2.6,
          height: unit * 2.4,
        ),
      )
      // Minarets.
      ..addRect(
        Rect.fromLTRB(
          mx - unit * 3.2,
          base - unit * 4.2,
          mx - unit * 2.75,
          base + 4,
        ),
      )
      ..addRect(
        Rect.fromLTRB(
          mx + unit * 2.75,
          base - unit * 4.2,
          mx + unit * 3.2,
          base + 4,
        ),
      );
    for (final x in [mx - unit * 2.975, mx + unit * 2.975]) {
      m.addPath(
        Path()
          ..moveTo(x - unit * 0.32, base - unit * 4.2)
          ..lineTo(x, base - unit * 4.9)
          ..lineTo(x + unit * 0.32, base - unit * 4.2)
          ..close(),
        Offset.zero,
      );
    }
    m.addRect(Rect.fromLTWH(mx - 1, base - unit * 3.6, 2, unit * 0.6));
    canvas.drawPath(m, sil);
    // Lit windows at night.
    if (night || phase == SkyPhase.dusk) {
      final lamp = Paint()..color = kGold.withValues(alpha: 0.45 + 0.15 * wave);
      for (var i = -1; i <= 1; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(mx + i * unit * 1.2, base - unit * 0.75),
              width: unit * 0.45,
              height: unit * 0.8,
            ),
            Radius.circular(unit * 0.22),
          ),
          lamp,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.phase != phase;
}

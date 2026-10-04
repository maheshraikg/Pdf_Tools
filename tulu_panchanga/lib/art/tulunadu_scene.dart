/// Animated Tulunadu landscape for the Today header: sky that follows the
/// real time of day, the Sun or the Moon (in its actual phase) on its arc,
/// the Western Ghats, coconut palms, a Mangalore-tile house and paddy fields,
/// with Tulu-flag bunting on festival days.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'kambala.dart';

class TulunaduScene extends StatefulWidget {
  const TulunaduScene({
    super.key,
    required this.dayFraction,
    required this.isNight,
    required this.moonElongation,
    this.festive = false,
    this.height = 210,
    this.child,
  });

  /// Position of the Sun (day) or Moon (night) along its arc, 0..1.
  final double dayFraction;
  final bool isNight;

  /// Moon − Sun elongation in degrees (0 new, 180 full).
  final double moonElongation;
  final bool festive;
  final double height;
  final Widget? child;

  @override
  State<TulunaduScene> createState() => _TulunaduSceneState();
}

class _TulunaduSceneState extends State<TulunaduScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(
                  painter: _ScenePainter(
                    t: _c.value,
                    f: widget.dayFraction,
                    night: widget.isNight,
                    elong: widget.moonElongation,
                    festive: widget.festive,
                  ),
                ),
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.t,
    required this.f,
    required this.night,
    required this.elong,
    required this.festive,
  });

  final double t;
  final double f;
  final bool night;
  final double elong;
  final bool festive;

  static double _w(double t, [double ph = 0]) =>
      math.sin((t + ph) * 2 * math.pi);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // --- Sky ---------------------------------------------------------------
    final List<Color> sky;
    if (night) {
      sky = const [Color(0xFF0E1033), Color(0xFF2B2152), Color(0xFF4A2F5E)];
    } else {
      // 0 at sunrise/sunset, 1 at noon.
      final k = math.sin(math.pi * f.clamp(0.0, 1.0));
      final d = (k * 2.2).clamp(0.0, 1.0);
      sky = [
        Color.lerp(const Color(0xFFFF7E5F), const Color(0xFF4FB3F0), d)!,
        Color.lerp(const Color(0xFFFFA36C), const Color(0xFF9ED8FF), d)!,
        Color.lerp(const Color(0xFFFFD39A), const Color(0xFFFFF1D6), d)!,
      ];
    }
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(rect),
    );

    // --- Stars / clouds ----------------------------------------------------
    if (night) {
      final rnd = math.Random(7);
      for (var i = 0; i < 40; i++) {
        final x = rnd.nextDouble() * w, y = rnd.nextDouble() * h * 0.55;
        final tw = 0.5 + 0.5 * _w(t * 3, rnd.nextDouble());
        canvas.drawCircle(
          Offset(x, y),
          0.6 + rnd.nextDouble() * 1.2,
          Paint()..color = Colors.white.withValues(alpha: 0.3 + 0.7 * tw),
        );
      }
    } else {
      final cloud = Paint()..color = Colors.white.withValues(alpha: 0.85);
      for (final (y, s, sp) in const [(0.18, 1.0, 0.0), (0.30, 0.7, 0.45)]) {
        final x = ((t + sp) % 1) * (w + 160) - 80;
        for (final (dx, dy, r) in const [
          (0.0, 0.0, 16.0),
          (18.0, -6.0, 20.0),
          (38.0, 0.0, 15.0),
        ]) {
          canvas.drawCircle(Offset(x + dx * s, h * y + dy * s), r * s, cloud);
        }
      }
    }

    // --- Sun or Moon on its arc -------------------------------------------
    final arcX = w * (0.08 + 0.84 * f.clamp(0.0, 1.0));
    final arcY = h * 0.62 - math.sin(math.pi * f.clamp(0.0, 1.0)) * h * 0.46;
    final body = Offset(arcX, arcY);
    if (night) {
      _moon(canvas, body, 15, elong);
    } else {
      final pulse = 1 + 0.06 * _w(t * 4);
      canvas.drawCircle(
        body,
        38 * pulse,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0x88FFE082), const Color(0x00FFE082)],
          ).createShader(Rect.fromCircle(center: body, radius: 38)),
      );
      canvas.drawCircle(body, 17, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(body, 13, Paint()..color = const Color(0xFFFFF176));
    }

    // --- Western Ghats -----------------------------------------------------
    final far = Path()..moveTo(0, h * 0.62);
    for (var i = 0; i <= 8; i++) {
      final x = w * i / 8;
      far.lineTo(x, h * (0.50 + 0.08 * math.sin(i * 1.7)));
    }
    far
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      far,
      Paint()
        ..color = night ? const Color(0xFF2D2A4A) : const Color(0xFF6C9A8B),
    );
    final near = Path()..moveTo(0, h * 0.70);
    for (var i = 0; i <= 6; i++) {
      final x = w * i / 6;
      near.lineTo(x, h * (0.62 + 0.06 * math.cos(i * 2.1)));
    }
    near
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      near,
      Paint()
        ..color = night ? const Color(0xFF233A33) : const Color(0xFF3F7D4E),
    );

    // --- Paddy fields with a moving ripple ---------------------------------
    final fieldTop = h * 0.76;
    canvas.drawRect(
      Rect.fromLTRB(0, fieldTop, w, h),
      Paint()
        ..color = night ? const Color(0xFF2E4A1F) : const Color(0xFF8BC34A),
    );
    final ripple = Paint()
      ..color = (night ? Colors.black : Colors.white).withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < 4; row++) {
      final y = fieldTop + 8 + row * 9.0;
      final p = Path()..moveTo(0, y);
      for (var x = 0.0; x <= w; x += 12) {
        p.lineTo(x, y + 2.5 * math.sin(x / 22 + t * 2 * math.pi * 2 + row));
      }
      canvas.drawPath(p, ripple);
    }

    // --- Mangalore-tile house ------------------------------------------------
    final hx = w - 70, hy = fieldTop + 6;
    canvas.drawRect(
      Rect.fromLTWH(hx, hy - 22, 46, 22),
      Paint()
        ..color = night ? const Color(0xFFBFA98A) : const Color(0xFFFFF3DC),
    );
    final roof = Path()
      ..moveTo(hx - 8, hy - 20)
      ..lineTo(hx + 10, hy - 38)
      ..lineTo(hx + 36, hy - 38)
      ..lineTo(hx + 54, hy - 20)
      ..close();
    canvas.drawPath(roof, Paint()..color = TuluColors.terracotta);
    for (var i = 0; i < 4; i++) {
      final y = hy - 34 + i * 4.0;
      canvas.drawLine(
        Offset(hx - 4 + i * 3, y),
        Offset(hx + 50 - i * 3, y),
        Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(hx + 19, hy - 14, 8, 14),
      Paint()..color = const Color(0xFF6D4C41),
    );
    final win = Paint()
      ..color = night ? const Color(0xFFFFD54F) : const Color(0xFF8D6E63);
    canvas.drawRect(Rect.fromLTWH(hx + 6, hy - 15, 7, 6), win);
    canvas.drawRect(Rect.fromLTWH(hx + 33, hy - 15, 7, 6), win);

    // --- Kambala race through the paddy (daytime) --------------------------
    {
      final p = ((t * 2) % 1) / 0.72;
      if (p <= 1) {
        final x = -70 + (w + 140) * p;
        paintKambala(
          canvas,
          Offset(x, h * 0.95),
          h / 210,
          (t * 30) % 1,
          night: night,
        );
      }
    }

    // --- Coconut palms --------------------------------------------------------
    _palm(canvas, Offset(w * 0.12, h * 1.0), h * 0.62, _w(t * 2) * 0.05, night);
    _palm(
      canvas,
      Offset(w * 0.26, h * 1.02),
      h * 0.48,
      _w(t * 2, 0.3) * 0.06,
      night,
    );
    _palm(
      canvas,
      Offset(w * 0.92, h * 1.02),
      h * 0.52,
      _w(t * 2, 0.6) * 0.05,
      night,
    );

    // --- Festive Tulu-flag bunting ------------------------------------------
    if (festive) {
      final n = (w / 22).floor();
      final sag = 10.0;
      for (var i = 0; i < n; i++) {
        final x0 = w * i / n, x1 = w * (i + 1) / n;
        double y(double x) => 6 + sag * math.sin(math.pi * x / w);
        final swing = 2 * _w(t * 3, i / n);
        final tri = Path()
          ..moveTo(x0 + 2, y(x0))
          ..lineTo(x1 - 2, y(x1))
          ..lineTo((x0 + x1) / 2 + swing, y((x0 + x1) / 2) + 16)
          ..close();
        canvas.drawPath(
          tri,
          Paint()..color = i.isEven ? TuluColors.red : TuluColors.turmeric,
        );
      }
      final string = Path()..moveTo(0, 6);
      for (var x = 0.0; x <= w; x += 8) {
        string.lineTo(x, 6 + sag * math.sin(math.pi * x / w));
      }
      canvas.drawPath(
        string,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 1,
      );
    }

    // --- Flower petals falling on festival days (marigold and jasmine) ---
    if (festive) {
      final rnd = math.Random(3);
      for (var i = 0; i < 22; i++) {
        final x0 = rnd.nextDouble() * w;
        final speed = 0.6 + rnd.nextDouble() * 0.8;
        final p = (t * speed * 3 + rnd.nextDouble()) % 1;
        final x = x0 + 18 * math.sin((p * 4 + i) * math.pi);
        final y = -10 + p * (h + 20);
        final color = i % 3 == 0
            ? Colors.white
            : (i.isEven ? const Color(0xFFFF9800) : TuluColors.turmeric);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p * 6 + i);
        canvas.drawOval(
          const Rect.fromLTRB(-3.5, -2, 3.5, 2),
          Paint()..color = color.withValues(alpha: 0.95),
        );
        canvas.restore();
      }
    }

    // Soft scrim at the bottom so overlaid text stays readable.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: night ? 0.35 : 0.22),
          ],
          stops: const [0.45, 1],
        ).createShader(rect),
    );
  }

  void _palm(Canvas c, Offset base, double height, double sway, bool night) {
    final trunkColor = night
        ? const Color(0xFF3E2C20)
        : const Color(0xFF8D6E4C);
    final leafColor = night ? const Color(0xFF1F3B22) : const Color(0xFF2E7D32);
    final top = base + Offset(height * 0.18 + height * sway, -height);
    final trunk = Path()
      ..moveTo(base.dx - 4, base.dy)
      ..quadraticBezierTo(
        base.dx + height * 0.02,
        base.dy - height * 0.5,
        top.dx - 2,
        top.dy,
      )
      ..lineTo(top.dx + 2, top.dy)
      ..quadraticBezierTo(
        base.dx + height * 0.06,
        base.dy - height * 0.5,
        base.dx + 4,
        base.dy,
      )
      ..close();
    c.drawPath(trunk, Paint()..color = trunkColor);
    final leaf = Paint()
      ..color = leafColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      final a = -math.pi + i * math.pi / 6 + sway * 2;
      final len = height * (0.32 + (i == 3 ? 0.04 : 0));
      final end =
          top +
          Offset(math.cos(a) * len, math.sin(a) * len * 0.55 + len * 0.35);
      final ctrl = top + Offset(math.cos(a) * len * 0.5, -len * 0.18);
      final p = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      c.drawPath(p, leaf);
    }
    // Coconuts.
    final nut = Paint()
      ..color = night ? const Color(0xFF4E3B1F) : const Color(0xFF8D6E2B);
    c.drawCircle(top + const Offset(-3, 4), 3, nut);
    c.drawCircle(top + const Offset(3, 5), 3, nut);
  }

  /// The Moon in its true phase: elongation 0 = new, 180 = full; waxing is
  /// lit on the right (as seen from India in the evening sky).
  void _moon(Canvas c, Offset o, double r, double elong) {
    c.drawCircle(
      o,
      r * 2.4,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x55FFF9C4), const Color(0x00FFF9C4)],
        ).createShader(Rect.fromCircle(center: o, radius: r * 2.4)),
    );
    c.drawCircle(o, r, Paint()..color = const Color(0xFF3B3A5C));
    final e = (elong % 360) * math.pi / 180;
    final waxing = elong % 360 < 180;
    final k = math.cos(e).abs();
    final half = Path()
      ..addArc(
        Rect.fromCircle(center: o, radius: r),
        waxing ? -math.pi / 2 : math.pi / 2,
        math.pi,
      );
    final ell = Path()
      ..addOval(Rect.fromCenter(center: o, width: 2 * r * k, height: 2 * r));
    final crescent = math.cos(e) > 0; // less than half lit
    final lit = Path.combine(
      crescent ? PathOperation.difference : PathOperation.union,
      half,
      ell,
    );
    c.drawPath(lit, Paint()..color = const Color(0xFFFFF3B0));
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.t != t ||
      old.f != f ||
      old.night != night ||
      old.elong != elong ||
      old.festive != festive;
}

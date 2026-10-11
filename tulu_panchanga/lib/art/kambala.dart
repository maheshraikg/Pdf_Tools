/// Kambala: a pair of decorated buffaloes and their runner racing through a
/// slushy paddy field, splashing water: Tulunadu's own winter sport.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Paints a Kambala pair whose front hooves touch [ground] (centre of the
/// pair), facing right. [s] is the scale (1 ≈ 60 px long), [phase] runs
/// 0..1 per stride and drives legs, bobbing and splashes.
void paintKambala(
  Canvas c,
  Offset ground,
  double s,
  double phase, {
  bool night = false,
}) {
  final stride = phase * 2 * math.pi;
  final bob = math.sin(stride * 2) * 1.6 * s;
  c.save();
  c.translate(ground.dx, ground.dy + bob);
  c.scale(s);

  // Water splashes behind and under the hooves.
  final splash = Paint()..color = const Color(0xCCBFE6FF);
  for (var i = 0; i < 9; i++) {
    final p = (phase * 2 + i / 9) % 1;
    final x = -34 - p * 34 + (i % 3) * 6;
    final y = -4 - math.sin(p * math.pi) * (10 + (i % 4) * 4);
    c.drawCircle(Offset(x, y), 2.2 * (1 - p) + 0.6, splash);
  }
  c.drawOval(
    const Rect.fromLTRB(-30, -2, 30, 3),
    Paint()..color = const Color(0x553E7DA6),
  );

  // Two buffaloes, the far one slightly behind and darker.
  for (final far in [true, false]) {
    c.save();
    if (far) c.translate(-7, -5);
    _buffalo(c, stride + (far ? 0.6 : 0), far, night);
    c.restore();
  }

  // Yoke across the necks.
  c.drawLine(
    const Offset(10, -24),
    const Offset(4, -28),
    Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round,
  );

  // Runner (holding the ropes, red headband).
  final run = stride * 1.0;
  final skin = night ? const Color(0xFF8D5B3E) : const Color(0xFFB9784E);
  final body = Paint()
    ..color = skin
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  const hip = Offset(-36, -12);
  const shoulder = Offset(-31, -26);
  c.drawLine(hip, shoulder, body..strokeWidth = 4);
  body.strokeWidth = 2.6;
  for (final sgn in [1.0, -1.0]) {
    final a = math.sin(run + (sgn > 0 ? 0 : math.pi)) * 0.7;
    final knee = hip + Offset(math.sin(a) * 7, 7);
    final foot = knee + Offset(math.sin(a - 0.4) * 7, 6);
    c.drawLine(hip, knee, body);
    c.drawLine(knee, foot, body);
  }
  // Arms forward to the ropes.
  c.drawLine(shoulder, const Offset(-22, -22), body);
  c.drawLine(
    const Offset(-22, -22),
    const Offset(-4, -22),
    Paint()
      ..color = const Color(0xFFFFF3C4)
      ..strokeWidth = 1,
  );
  // Shorts.
  c.drawRect(
    Rect.fromCenter(center: hip + const Offset(0, -1), width: 7, height: 5),
    Paint()..color = TuluColors.red,
  );
  // Head and headband.
  c.drawCircle(shoulder + const Offset(2, -6), 4.2, Paint()..color = skin);
  c.drawLine(
    shoulder + const Offset(-2, -8),
    shoulder + const Offset(6, -8),
    Paint()
      ..color = TuluColors.turmeric
      ..strokeWidth = 2,
  );
  c.restore();
}

void _buffalo(Canvas c, double stride, bool far, bool night) {
  final hide = far
      ? (night ? const Color(0xFF1C1C1C) : const Color(0xFF2F2F33))
      : (night ? const Color(0xFF262626) : const Color(0xFF3D3D43));
  final p = Paint()..color = hide;
  // Legs (galloping).
  final leg = Paint()
    ..color = hide
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round;
  const hips = [
    Offset(-16, -10),
    Offset(-10, -10),
    Offset(10, -10),
    Offset(16, -10),
  ];
  for (var i = 0; i < 4; i++) {
    final a =
        math.sin(stride + (i.isEven ? 0 : math.pi) + (i < 2 ? 0.8 : 0)) * 0.6;
    final knee = hips[i] + Offset(math.sin(a) * 5, 5);
    final hoof = knee + Offset(math.sin(a * 1.3) * 4, 5);
    c.drawLine(hips[i], knee, leg);
    c.drawLine(knee, hoof, leg);
  }
  // Body.
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(-22, -26, 20, -8),
      const Radius.circular(9),
    ),
    p,
  );
  // Decorative cloth (red and yellow, like the Tulu flag).
  if (!far) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(-10, -26, 6, -16),
        const Radius.circular(3),
      ),
      Paint()..color = TuluColors.red,
    );
    c.drawRect(
      const Rect.fromLTRB(-10, -19, 6, -16),
      Paint()..color = TuluColors.turmeric,
    );
  }
  // Head bobbing.
  final nod = math.sin(stride * 2) * 1.5;
  c.save();
  c.translate(22, -22 + nod);
  c.drawOval(const Rect.fromLTRB(-6, -6, 9, 6), p);
  // Horns curving back.
  final horn = Paint()
    ..color = const Color(0xFFE8DCC8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  final h = Path()
    ..moveTo(-1, -5)
    ..quadraticBezierTo(-10, -14, -14, -6);
  c.drawPath(h, horn);
  // Eye and a little brass forehead ornament.
  c.drawCircle(const Offset(3, -2), 1.1, Paint()..color = Colors.white);
  c.drawCircle(const Offset(0, -6), 1.6, Paint()..color = TuluColors.gold);
  c.restore();
  // Tail flicking.
  final tail = Path()
    ..moveTo(-22, -22)
    ..quadraticBezierTo(-30, -18 + math.sin(stride) * 3, -28, -10);
  c.drawPath(
    tail,
    Paint()
      ..color = hide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6,
  );
}

/// Lightweight celebration: coloured paper and marigold petals.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class Confetti extends StatefulWidget {
  const Confetti({
    super.key,
    this.count = 90,
    this.duration = const Duration(milliseconds: 2600),
  });
  final int count;
  final Duration duration;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Bit {
  _Bit(math.Random r)
    : x = r.nextDouble(),
      delay = r.nextDouble() * 0.35,
      speed = 0.6 + r.nextDouble() * 0.6,
      drift = (r.nextDouble() - 0.5) * 0.3,
      spin = (r.nextDouble() - 0.5) * 12,
      size = 5 + r.nextDouble() * 7,
      petal = r.nextDouble() < 0.4,
      color = _colors[r.nextInt(_colors.length)];
  final double x, delay, speed, drift, spin, size;
  final bool petal;
  final Color color;

  static const _colors = [
    Color(0xFFB3261E),
    Color(0xFFE0A100),
    Color(0xFF2E7D32),
    Color(0xFFF57C00),
    Color(0xFFFFD54F),
  ];
}

class _ConfettiState extends State<Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _bits = List.generate(widget.count, (_) => _Bit(r));
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_c, _bits),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.bits) : super(repaint: t);
  final Animation<double> t;
  final List<_Bit> bits;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final b in bits) {
      final k = ((t.value - b.delay) / (1 - b.delay)).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final y = -20 + k * b.speed * (size.height + 40) * 1.2;
      final x =
          (b.x + b.drift * k + 0.02 * math.sin(k * 12 + b.x * 9)) * size.width;
      p.color = b.color.withValues(alpha: k > 0.8 ? (1 - k) * 5 : 1);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * k);
      if (b.petal) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset.zero,
            width: b.size,
            height: b.size * 1.6,
          ),
          p,
        );
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: b.size,
            height: b.size * 0.5,
          ),
          p,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

import 'dart:math';

import 'package:flutter/material.dart';

/// A short, light confetti burst (one controller, ~60 pieces).
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 60});

  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();
  late final List<_Piece> _p;

  @override
  void initState() {
    super.initState();
    final r = Random();
    const colors = [Color(0xFFFF7A8A), Color(0xFF4FA3FF), Color(0xFF3DDC84), Color(0xFFFFB627), Color(0xFFA77BFF)];
    _p = List.generate(
      widget.pieces,
      (_) => _Piece(
        x: r.nextDouble(),
        vx: (r.nextDouble() - 0.5) * 0.5,
        vy: 0.5 + r.nextDouble() * 0.7,
        spin: (r.nextDouble() - 0.5) * 12,
        color: colors[r.nextInt(colors.length)],
        size: 6 + r.nextDouble() * 6,
        delay: r.nextDouble() * 0.25,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => _c.isCompleted
            ? const SizedBox.expand()
            : CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_p, _c.value)),
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.color,
    required this.size,
    required this.delay,
  });

  final double x, vx, vy, spin, size, delay;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      final lt = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (lt <= 0) continue;
      final x = (p.x + p.vx * lt) * size.width;
      final y = -20 + (p.vy * lt + 0.6 * lt * lt) * size.height;
      paint.color = p.color.withValues(alpha: 1 - lt * 0.6);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * lt);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

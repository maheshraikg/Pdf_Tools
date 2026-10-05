/// Animated charts drawn with CustomPaint. Doubles are used only for
/// drawing; every amount shown as text comes from Decimal.
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../domain/models/result.dart';

/// Ring split into deposit (scheme colour) and interest (postal yellow),
/// with [center] in the middle.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.deposit,
    required this.interest,
    required this.color,
    required this.center,
    this.size = 150,
  });

  final Decimal deposit;
  final Decimal interest;
  final Color color;
  final Widget center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = (deposit + interest).toDouble();
    final share = total <= 0 ? 0.0 : interest.toDouble() / total;
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => CustomPaint(
        size: Size.square(size),
        painter: _DonutPainter(share, t, color, track),
        child: SizedBox.square(dimension: size, child: child),
      ),
      child: Center(child: center),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.share, this.t, this.color, this.track);
  final double share;
  final double t;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Offset.zero & size;
    final arc = rect.deflate(stroke / 2);
    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(arc, 0, math.pi * 2, false, p(track));
    const start = -math.pi / 2;
    final sweep = math.pi * 2 * t;
    final depositSweep = sweep * (1 - share);
    canvas.drawArc(arc, start, depositSweep, false, p(color));
    canvas.drawArc(
      arc,
      start + depositSweep,
      sweep * share,
      false,
      p(Brand.yellow),
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.t != t || old.share != share || old.color != color;
}

/// Year-by-year bars: money put in (scheme colour) and interest earned so
/// far (yellow), growing in with a stagger.
class GrowthBars extends StatelessWidget {
  const GrowthBars({
    super.key,
    required this.rows,
    required this.color,
    this.height = 170,
  });

  final List<ScheduleRow> rows;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    var dep = 0.0, intr = 0.0;
    final bars = <(double, double)>[];
    for (final r in rows) {
      dep += r.deposit.toDouble();
      intr += r.interest.toDouble();
      bars.add((dep, intr));
    }
    final cs = Theme.of(context).colorScheme;
    final label = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: cs.onSurfaceVariant);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size(double.infinity, height),
        painter: _BarsPainter(
          bars,
          t,
          color,
          cs.outlineVariant.withValues(alpha: 0.5),
          label ?? const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.bars, this.t, this.color, this.grid, this.label);
  final List<(double, double)> bars;
  final double t;
  final Color color;
  final Color grid;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const bottom = 18.0;
    final h = size.height - bottom;
    final maxV = bars.map((b) => b.$1 + b.$2).reduce(math.max);
    if (maxV <= 0) return;
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = h * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    final n = bars.length;
    final slot = size.width / n;
    final w = math.min(slot * 0.62, 34.0);
    final labelEvery = n > 12 ? 3 : (n > 7 ? 2 : 1);
    for (var i = 0; i < n; i++) {
      // Each bar starts a little after the previous one.
      final local = ((t * (1 + n * 0.08)) - i * 0.08).clamp(0.0, 1.0);
      final (d, it) = bars[i];
      final x = slot * i + (slot - w) / 2;
      final dh = h * d / maxV * local, ih = h * it / maxV * local;
      final r = Radius.circular(math.min(6, w / 3));
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, h - dh, w, dh),
          bottomLeft: r,
          bottomRight: r,
          topLeft: ih < 1 ? r : Radius.zero,
          topRight: ih < 1 ? r : Radius.zero,
        ),
        Paint()..color = color,
      );
      if (ih >= 1) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, h - dh - ih, w, ih),
            topLeft: r,
            topRight: r,
          ),
          Paint()..color = Brand.yellow,
        );
      }
      if ((i + 1) % labelEvery == 0 || i == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${i + 1}', style: label),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + w / 2 - tp.width / 2, h + 3));
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t || old.bars != bars;
}

/// Legend dot + label.
class LegendDot extends StatelessWidget {
  const LegendDot(this.color, this.label, {super.key});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );
}

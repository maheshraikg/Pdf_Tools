/// Small animation helpers: staggered entrance and counting amounts.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../app/format.dart';

/// Fades and slides its child up once, after [delay]. Uses one controller
/// with an [Interval] (no timers), so tests settle normally.
class Appear extends StatefulWidget {
  const Appear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 24,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  /// Delay for the [index]-th item of a staggered list.
  static Duration step(int index, {int ms = 45}) =>
      Duration(milliseconds: (index * ms).clamp(0, 600));

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  static const _run = Duration(milliseconds: 420);
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final total = widget.delay + _run;
    _c = AnimationController(vsync: this, duration: total)..forward();
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(
        widget.delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(
        offset: Offset(0, widget.offset * (1 - _t.value)),
        child: child,
      ),
    ),
  );
}

/// A rupee amount that counts up from zero. The final frame shows the exact
/// Decimal value.
class AnimatedRupee extends StatelessWidget {
  const AnimatedRupee(
    this.value, {
    super.key,
    this.style,
    this.duration = const Duration(milliseconds: 1100),
  });

  final Decimal value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(value),
    tween: Tween(begin: 0, end: 1),
    duration: duration,
    curve: Curves.easeOutCubic,
    builder: (context, t, _) => Text(
      t >= 1
          ? rupee(value)
          : rupee(value * Decimal.parse(t.toStringAsFixed(4))),
      style: style,
      maxLines: 1,
    ),
  );
}

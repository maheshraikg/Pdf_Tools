/// Shared building blocks of the redesigned UI.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/prayer_calc.dart';

/// Icon for a time of the day.
IconData prayerIcon(Prayer p) => switch (p) {
  Prayer.imsak => Icons.restaurant_outlined,
  Prayer.fajr => Icons.wb_twilight,
  Prayer.sunrise => Icons.wb_sunny_outlined,
  Prayer.ishraq => Icons.flare,
  Prayer.dhuhr => Icons.light_mode,
  Prayer.asr => Icons.wb_sunny,
  Prayer.maghrib => Icons.wb_twilight_outlined,
  Prayer.isha => Icons.bedtime,
  Prayer.tahajjud => Icons.nights_stay,
};

/// Repeating eight-pointed-star (khatam) lattice, drawn faintly over the
/// hero gradient and the mosque display.
class IslamicPatternPainter extends CustomPainter {
  IslamicPatternPainter({required this.color, this.cell = 56});
  final Color color;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final r = cell * 0.34;
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        // Two overlapping squares make the star.
        for (final a in [0.0, math.pi / 4]) {
          final path = Path();
          for (var i = 0; i < 4; i++) {
            final t = a + i * math.pi / 2;
            final p = c + Offset(math.cos(t), math.sin(t)) * r;
            i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
          }
          path.close();
          canvas.drawPath(path, paint);
        }
        canvas.drawCircle(c, r * 0.42, paint);
      }
    }
  }

  @override
  bool shouldRepaint(IslamicPatternPainter old) =>
      old.color != color || old.cell != cell;
}

/// A rounded group of rows with an optional heading, like modern settings
/// screens.
class Section extends StatelessWidget {
  const Section({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 4, 8),
              child: Text(
                title!.toUpperCase(),
                style: t.textTheme.labelMedium?.copyWith(
                  color: t.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 64),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Leading icon in a soft tinted square.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color});
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: c),
    );
  }
}

/// Fades and slides [child] in when it first appears, [index] steps after
/// the first (a staggered list). Plays once; off when the phone asks for
/// no animations.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + 70 * index),
      curve: Interval(
        (70 * index) / (320 + 70 * index),
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Text whose characters roll up when they change (a flip-clock countdown).
class RollingText extends StatelessWidget {
  const RollingText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return Text(text, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < text.length; i++)
          ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, a) {
                final incoming = child.key == ValueKey('$i${text[i]}');
                return SlideTransition(
                  position: Tween(
                    begin: Offset(0, incoming ? 0.9 : -0.9),
                    end: Offset.zero,
                  ).animate(a),
                  child: FadeTransition(opacity: a, child: child),
                );
              },
              child: Text(text[i], key: ValueKey('$i${text[i]}'), style: style),
            ),
          ),
      ],
    );
  }
}

/// A small dot that pulses a few times (marks the live next prayer).
class LivePulse extends StatefulWidget {
  const LivePulse({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!(MediaQuery.maybeDisableAnimationsOf(context) ?? false) &&
        !_c.isAnimating) {
      // A few beats, then it rests (no endless animation draining power).
      _c.repeat(reverse: true, count: 8);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s * (1 + 1.4 * _c.value),
              height: s * (1 + 1.4 * _c.value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 * (1 - _c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shrinks [child] a little while it is pressed.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

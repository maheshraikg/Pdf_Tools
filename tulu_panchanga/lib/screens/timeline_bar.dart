import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/engine.dart';
import '../panchanga/names.dart';
import 'day_widgets.dart';

/// A horizontal bar for the Hindu day (sunrise → next sunrise) showing
/// daytime/night, Rahu/Yama/Gulika, Abhijit, tithi and nakshatra changes and
/// the current time.
class TimelineBar extends StatelessWidget {
  const TimelineBar({super.key, required this.day});
  final DayPanchanga day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final e = context.repo.engine, s = context.s, lang = context.lang;
    final d = day;
    final now = jdNow();
    final marks = <_Mark>[
      for (final x in d.tithis.where((x) => x.end < d.nextSunrise))
        _Mark(
          x.end,
          '${s.tithi}: ${tithiLabel(lang, (x.index + 1) % 30)}',
          hm(e, x.end),
          true,
        ),
      for (final x in d.nakshatras.where((x) => x.end < d.nextSunrise))
        _Mark(
          x.end,
          '${s.nakshatra}: ${nakshatraNames[(x.index + 1) % 27].of(lang)}',
          hm(e, x.end),
          false,
        ),
    ]..sort((a, b) => a.at.compareTo(b.at));

    return Section(
      title: s.timeline,
      children: [
        SizedBox(
          height: 54,
          child: CustomPaint(
            size: Size.infinite,
            painter: _TimelinePainter(
              day: d,
              now: now,
              dayColor: t.colorScheme.primaryContainer,
              nightColor: t.colorScheme.surfaceContainerHighest,
              tickColor: t.colorScheme.onSurface,
              nowColor: t.colorScheme.tertiary,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('☀ ${hm(e, d.sunrise)}', style: t.textTheme.bodySmall),
            Text('☾ ${hm(e, d.sunset)}', style: t.textTheme.bodySmall),
            Text('☀ ${hm(e, d.nextSunrise)}', style: t.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 2,
          children: [
            _legend(context, KaalaColors.rahu, s.rahu),
            _legend(context, KaalaColors.yama, s.yamaganda),
            _legend(context, KaalaColors.gulika, s.gulika),
            if (d.weekday != 3)
              _legend(context, KaalaColors.abhijit, s.abhijit),
          ],
        ),
        for (final m in marks)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Icon(
                  m.tithi ? Icons.change_history : Icons.star_border,
                  size: 14,
                  color: t.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(m.time, style: t.textTheme.bodySmall),
                const SizedBox(width: 6),
                Expanded(
                  child: LipiText(
                    m.label,
                    style: t.textTheme.bodySmall,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 10, height: 10, color: c),
      const SizedBox(width: 4),
      LipiText(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _Mark {
  _Mark(this.at, this.label, this.time, this.tithi);
  final double at;
  final String label;
  final String time;
  final bool tithi;
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.day,
    required this.now,
    required this.dayColor,
    required this.nightColor,
    required this.tickColor,
    required this.nowColor,
  });

  final DayPanchanga day;
  final double now;
  final Color dayColor, nightColor, tickColor, nowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final a = day.sunrise, b = day.nextSunrise;
    double x(double jd) => ((jd - a) / (b - a)).clamp(0.0, 1.0) * size.width;
    const top = 14.0, h = 22.0;
    final r = RRect.fromLTRBR(
      0,
      top,
      size.width,
      top + h,
      const Radius.circular(6),
    );
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(
      Rect.fromLTRB(0, top, x(day.sunset), top + h),
      Paint()..color = dayColor,
    );
    canvas.drawRect(
      Rect.fromLTRB(x(day.sunset), top, size.width, top + h),
      Paint()..color = nightColor,
    );
    final k = day.kaalas;
    void band(Window w, Color c) => canvas.drawRect(
      Rect.fromLTRB(x(w.start), top + 3, x(w.end), top + h - 3),
      Paint()..color = c.withValues(alpha: 0.85),
    );
    band(k.rahu, KaalaColors.rahu);
    band(k.yamaganda, KaalaColors.yama);
    band(k.gulika, KaalaColors.gulika);
    if (day.weekday != 3) band(k.abhijit, KaalaColors.abhijit);
    canvas.restore();

    // Tithi changes (triangles above), nakshatra changes (dots below).
    final tick = Paint()..color = tickColor;
    for (final s in day.tithis.where((s) => s.end < b)) {
      final px = x(s.end);
      final path = Path()
        ..moveTo(px - 5, top - 9)
        ..lineTo(px + 5, top - 9)
        ..lineTo(px, top - 1)
        ..close();
      canvas.drawPath(path, tick);
    }
    for (final s in day.nakshatras.where((s) => s.end < b)) {
      canvas.drawCircle(Offset(x(s.end), top + h + 6), 3.5, tick);
    }

    if (now >= a && now < b) {
      final px = x(now);
      canvas.drawLine(
        Offset(px, top - 4),
        Offset(px, top + h + 4),
        Paint()
          ..color = nowColor
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.day != day || (old.now - now).abs() > 1 / 1440;
}

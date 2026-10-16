import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/scope.dart';
import '../core/prayer_calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Prayer tracker: streak, totals and a week of prayers to tick off.
class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  /// 0 = the week ending today, 1 = the week before…
  int _weeksBack = 0;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final log = settings.log;
    final today = settings.today;
    final streak = log.streak(today);
    final (week, weekMax) = log.total(today, 7);
    final (month, monthMax) = log.total(today, 30);
    final end = today.subtract(Duration(days: 7 * _weeksBack));
    final days = [for (var i = 6; i >= 0; i--) end.subtract(Duration(days: i))];

    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: t.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );

    String pct(int a, int b) => b == 0 ? '–' : '${(100 * a / b).round()}%';

    return Scaffold(
      appBar: AppBar(title: Text(s.tracker)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 18),
              decoration: BoxDecoration(
                gradient: heroGradient(Theme.of(context).brightness),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: kGold,
                          size: 30,
                        ),
                        Text(
                          '$streak',
                          style: t.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          s.streak,
                          style: t.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  stat('$week/$weekMax', s.last7Days),
                  stat(pct(month, monthMax), s.last30Days),
                ],
              ),
            ),
          ),
          Section(
            title: s.week,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: s.previousWeek,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _weeksBack++),
                    ),
                    Expanded(
                      child: Text(
                        '${days.first.day} ${monthName(settings.lang, days.first.month)} – '
                        '${days.last.day} ${monthName(settings.lang, days.last.month)}',
                        textAlign: TextAlign.center,
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.nextWeek,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _weeksBack == 0
                          ? null
                          : () => setState(() => _weeksBack--),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Row(
                  children: [
                    const SizedBox(width: 64),
                    for (final p in Prayer.fard)
                      Expanded(
                        child: Tooltip(
                          message: s.prayer(p),
                          child: Icon(
                            prayerIcon(p),
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (final d in days)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shortWeekdayName(settings.lang, d.weekday),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.labelMedium?.copyWith(
                                fontWeight: d == today
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: d == today ? scheme.primary : null,
                              ),
                            ),
                            Text(
                              '${d.day}',
                              style: t.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final p in Prayer.fard)
                        Expanded(
                          child: Center(
                            child: _Dot(
                              on: log.prayed(d, p),
                              excused: log.excused(d),
                              label: '${s.prayer(p)} ${d.day}',
                              onTap: d.isAfter(today)
                                  ? null
                                  : () => settings.updateQuietly(
                                      (x) => x.log.toggle(d, p),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
          Section(
            children: [
              SwitchListTile(
                secondary: const IconBadge(Icons.pause_circle_outline),
                title: Text(s.excusedToday),
                subtitle: Text(s.excusedHelp),
                value: log.excused(today),
                onChanged: (v) =>
                    settings.updateQuietly((x) => x.log.setExcused(today, v)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
            child: Text(
              s.trackerPrivacy,
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.on,
    required this.excused,
    required this.label,
    required this.onTap,
  });

  final bool on, excused;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      checked: on,
      child: InkResponse(
        radius: 22,
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on
                ? scheme.primary
                : excused
                ? scheme.tertiary.withValues(alpha: 0.15)
                : scheme.primary.withValues(alpha: 0.08),
            border: Border.all(
              color: on
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
          child: on
              ? Icon(Icons.check_rounded, size: 18, color: scheme.onPrimary)
              : excused
              ? Icon(Icons.pause, size: 14, color: scheme.tertiary)
              : null,
        ),
      ),
    );
  }
}

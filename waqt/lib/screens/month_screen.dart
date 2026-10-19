import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../core/day.dart';
import '../core/events.dart';
import '../core/prayer_calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

const _cols = [
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

class MonthScreen extends StatefulWidget {
  const MonthScreen({super.key});

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  int _offset = 0;

  /// Calendar grid instead of the times table.
  bool _grid = false;
  final _scroll = ScrollController();

  /// Fixed row height, so "today" can be scrolled to without measuring.
  static const double _rowHeight = 56;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Shows today (with two days above it) in the current month.
  void _scrollToToday() {
    if (!mounted || !_scroll.hasClients) return;
    final target = _offset == 0
        ? (context.settings.today.day - 3) * _rowHeight
        : 0.0;
    _scroll.jumpTo(
      target.clamp(0.0, _scroll.position.maxScrollExtent).toDouble(),
    );
  }

  void _changeMonth(int delta) {
    setState(() => _offset += delta);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final today = settings.today;
    final first = DateTime.utc(today.year, today.month + _offset);
    final count = DateTime.utc(first.year, first.month + 1, 0).day;
    final days = settings.calculator.days(first, count);
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.bodySmall!;
    final h1 = days.first.hijri, h2 = days.last.hijri;
    final hijriRange = h1.month == h2.month
        ? '${hijriMonthName(settings.lang, h1.month)} ${h1.year}'
        : '${hijriMonthName(settings.lang, h1.month)} – ${hijriMonthName(settings.lang, h2.month)} ${h2.year}';

    String clock(DateTime utc) {
      // Compact: no AM/PM in the table.
      final w = settings.wall(utc);
      final h = settings.use24h
          ? w.hour
          : (w.hour % 12 == 0 ? 12 : w.hour % 12);
      return '$h:${w.minute.toString().padLeft(2, '0')}';
    }

    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Month header: title, Hijri range and month arrows.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${monthName(settings.lang, first.month)} ${first.year}',
                          style: t.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          hijriRange,
                          style: t.bodyMedium?.copyWith(
                            color: scheme.tertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _grid ? s.timesTable : s.calendarView,
                    onPressed: () => setState(() => _grid = !_grid),
                    icon: Icon(
                      _grid
                          ? Icons.table_rows_outlined
                          : Icons.calendar_view_month,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            _EventStrip(
              events: upcomingEvents(
                today,
                adjustDays: settings.hijriAdjust,
                count: 6,
              ),
            ),
            if (_grid)
              Expanded(
                child: _CalendarGrid(days: days, today: today),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          color: scheme.primary.withValues(alpha: 0.08),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                child: Text(
                                  s.date,
                                  style: small.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              for (final p in _cols)
                                Expanded(
                                  child: Column(
                                    children: [
                                      Icon(
                                        prayerIcon(p),
                                        size: 16,
                                        color: scheme.primary,
                                      ),
                                      const SizedBox(height: 2),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          s.prayer(p),
                                          style: small.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: _scroll,
                            itemExtent: _rowHeight,
                            itemCount: days.length,
                            itemBuilder: (context, i) {
                              final d = days[i];
                              final isToday =
                                  d.year == today.year &&
                                  d.month == today.month &&
                                  d.day == today.day;
                              final timeStyle = t.bodyMedium?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday ? Colors.white : null,
                              );
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isToday
                                      ? heroGradient(
                                          Theme.of(context).brightness,
                                        )
                                      : null,
                                  color: !isToday && d.isFriday
                                      ? scheme.tertiary.withValues(alpha: 0.08)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 46,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${d.day}',
                                            style: t.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: isToday
                                                  ? Colors.white
                                                  : d.isFriday
                                                  ? scheme.tertiary
                                                  : null,
                                            ),
                                          ),
                                          Text(
                                            '${d.hijri.day}'
                                            '${IslamicEvent.values.any((e) => e.month == d.hijri.month && e.day == d.hijri.day) ? ' ★' : ''}',
                                            style: small.copyWith(
                                              color: isToday
                                                  ? kGold
                                                  : scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    for (final p in _cols)
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            clock(d[p]),
                                            style:
                                                p == Prayer.sunrise && !isToday
                                                ? timeStyle?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  )
                                                : timeStyle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Upcoming Islamic occasions as a row of cards.
class _EventStrip extends StatelessWidget {
  const _EventStrip({required this.events});
  final List<UpcomingEvent> events;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    if (events.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = events[i];
          final soon = e.daysLeft <= 7;
          return Tooltip(
            message: s.hijriEstimateNote,
            child: Container(
              width: 170,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                gradient: soon
                    ? heroGradient(Theme.of(context).brightness)
                    : null,
                color: soon ? null : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: soon
                    ? null
                    : Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.eventName(e.event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: soon ? Colors.white : null,
                    ),
                  ),
                  Text(
                    '${e.date.day} ${monthName(settings.lang, e.date.month)}',
                    maxLines: 1,
                    style: t.bodySmall?.copyWith(
                      color: soon
                          ? Colors.white.withValues(alpha: 0.8)
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    s.daysLeft(e.daysLeft),
                    maxLines: 1,
                    style: t.labelMedium?.copyWith(
                      color: soon ? kGold : scheme.tertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The month as a calendar: each day with its Hijri date and a star on
/// Islamic occasions; tap a day for its times.
class _CalendarGrid extends StatefulWidget {
  const _CalendarGrid({required this.days, required this.today});

  final List<PrayerDay> days;
  final DateTime today;

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  DateTime? _picked;

  @override
  void didUpdateWidget(_CalendarGrid old) {
    super.didUpdateWidget(old);
    if (old.days.first.date != widget.days.first.date) _picked = null;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final days = widget.days;
    final inMonth = days.any((d) => d.date == widget.today);
    final picked = days.firstWhere(
      (d) => d.date == (_picked ?? (inMonth ? widget.today : days.first.date)),
      orElse: () => days.first,
    );
    // Weeks start on Sunday.
    final lead = days.first.date.weekday % 7;
    final cells = [for (var i = 0; i < lead; i++) null, ...days];
    bool event(PrayerDay d) => IslamicEvent.values.any(
      (e) => e.month == d.hijri.month && e.day == d.hijri.day,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        Row(
          children: [
            for (var w = 0; w < 7; w++)
              Expanded(
                child: Center(
                  child: Text(
                    shortWeekdayName(settings.lang, w == 0 ? 7 : w),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: t.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: w == 5 ? scheme.tertiary : scheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.82,
          children: [
            for (final d in cells)
              if (d == null)
                const SizedBox.shrink()
              else
                () {
                  final isToday = d.date == widget.today;
                  final isPicked = d.date == picked.date;
                  return PressScale(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _picked = d.date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: isToday
                              ? heroGradient(Theme.of(context).brightness)
                              : null,
                          color: isToday
                              ? null
                              : isPicked
                              ? scheme.primary.withValues(alpha: 0.14)
                              : scheme.surfaceContainerHighest.withValues(
                                  alpha: 0.5,
                                ),
                          border: isPicked && !isToday
                              ? Border.all(color: scheme.primary, width: 1.5)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${d.day}',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isToday ? Colors.white : null,
                              ),
                            ),
                            Text(
                              '${d.hijri.day}${event(d) ? ' ★' : ''}',
                              style: t.labelSmall?.copyWith(
                                color: isToday ? kGold : scheme.tertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }(),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Card(
            key: ValueKey(picked.date),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    longDate(settings.lang, picked.date),
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    hijriLabel(settings.lang, picked.hijri),
                    style: t.bodySmall?.copyWith(color: scheme.tertiary),
                  ),
                  for (final e in IslamicEvent.values)
                    if (e.month == picked.hijri.month &&
                        e.day == picked.hijri.day)
                      Text(
                        '★ ${s.eventName(e)}',
                        style: t.bodyMedium?.copyWith(
                          color: scheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  const SizedBox(height: 8),
                  for (final p in [
                    Prayer.fajr,
                    Prayer.sunrise,
                    Prayer.dhuhr,
                    Prayer.asr,
                    Prayer.maghrib,
                    Prayer.isha,
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.prayer(p, friday: picked.isFriday),
                              style: t.bodyMedium,
                            ),
                          ),
                          Text(
                            hm(settings, picked[p]),
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

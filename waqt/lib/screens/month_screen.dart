import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../core/prayer_calc.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${monthName(settings.lang, first.month)} ${first.year}'),
            Text(hijriRange, style: small),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: scheme.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              children: [
                SizedBox(width: 44, child: Text(s.date, style: small)),
                for (final p in _cols)
                  Expanded(
                    child: Text(
                      s.prayer(p),
                      style: small.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
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
                return Container(
                  color: isToday
                      ? scheme.secondaryContainer
                      : d.isFriday
                      ? scheme.surfaceContainerLow
                      : null,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${d.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: d.isFriday ? scheme.primary : null,
                              ),
                            ),
                            Text('${d.hijri.day}', style: small),
                          ],
                        ),
                      ),
                      for (final p in _cols)
                        Expanded(
                          child: Text(
                            clock(d[p]),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: p == Prayer.sunrise
                                  ? scheme.onSurfaceVariant
                                  : null,
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
    );
  }
}

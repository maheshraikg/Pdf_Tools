import 'dart:async';

import 'package:flutter/material.dart';

import '../app/background.dart' show kNiyyahArabic;
import '../app/scope.dart';
import '../app/settings.dart';
import '../core/day.dart';
import '../core/duas.dart';
import '../core/prayer_calc.dart';
import '../ui/sky_scene.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'duas_screen.dart';

/// The days of this Ramadan, or of the next one (by the Hijri calendar with
/// the user's correction).
List<PrayerDay> ramadanDays(AppSettings settings) {
  final today = settings.today;
  final calc = settings.calculator;
  // Asked every second by the Today screen: kept until the day or the
  // settings change.
  final key = (identityHashCode(calc), today);
  if (_cache?.$1 == key) return _cache!.$2;
  final days = _ramadanDays(calc, today);
  _cache = (key, days);
  return days;
}

((int, DateTime), List<PrayerDay>)? _cache;

List<PrayerDay> _ramadanDays(DayCalculator calc, DateTime today) {
  // A day of Ramadan from today on (or today itself).
  DateTime? any;
  for (var i = 0; i < 400; i++) {
    final d = DateTime.utc(today.year, today.month, today.day + i);
    if (calc.day(d.year, d.month, d.day).hijri.isRamadan) {
      any = d;
      break;
    }
  }
  if (any == null) return const [];
  var first = any;
  while (true) {
    final prev = first.subtract(const Duration(days: 1));
    if (!calc.day(prev.year, prev.month, prev.day).hijri.isRamadan) break;
    first = prev;
  }
  final days = <PrayerDay>[];
  for (var d = first; ; d = d.add(const Duration(days: 1))) {
    final day = calc.day(d.year, d.month, d.day);
    if (!day.hijri.isRamadan) break;
    days.add(day);
  }
  return days;
}

/// Suhoor and Iftar countdown, the month's timetable and the Ramadan duas.
class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

class _RamadanScreenState extends State<RamadanScreen> {
  late final Timer _tick;
  DateTime _now = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _now = DateTime.now().toUtc()),
    );
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final days = ramadanDays(settings);
    final today = settings.today;
    final index = days.indexWhere((d) => d.date == today);
    final inRamadan = index >= 0;

    // What to count down to: Iftar today, else the end of the next Suhoor.
    String? label;
    DateTime? target;
    if (inRamadan) {
      final d = days[index];
      if (_now.isBefore(d[Prayer.fajr])) {
        label = s.suhoorEndsIn;
        target = d[Prayer.fajr];
      } else if (_now.isBefore(d[Prayer.maghrib])) {
        label = s.iftarIn;
        target = d[Prayer.maghrib];
      } else if (index + 1 < days.length) {
        label = s.suhoorEndsIn;
        target = days[index + 1][Prayer.fajr];
      }
    }
    final daysToGo = days.isEmpty || inRamadan
        ? null
        : days.first.date.difference(today).inDays;

    String hm2(DateTime utc) {
      final w = settings.wall(utc);
      final h = settings.use24h
          ? w.hour
          : (w.hour % 12 == 0 ? 12 : w.hour % 12);
      return '$h:${w.minute.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.ramadanTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: SkyScene(
              phase: SkyPhase.night,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
                child: Column(
                  children: [
                    Text(
                      inRamadan
                          ? s.ramadanDay(index + 1)
                          : daysToGo != null
                          ? s.ramadanIn(daysToGo)
                          : s.ramadanTitle,
                      textAlign: TextAlign.center,
                      style: t.titleLarge?.copyWith(
                        color: kGold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (!inRamadan && days.isNotEmpty)
                      Text(
                        longDate(settings.lang, days.first.date),
                        style: t.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    if (label != null && target != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        label,
                        style: t.titleMedium?.copyWith(color: Colors.white),
                      ),
                      FittedBox(
                        child: RollingText(
                          clockCountdown(
                            target.difference(_now),
                            withHours: true,
                          ),
                          style: t.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                    if (inRamadan) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final (name, time) in [
                            (s.suhoorEnds, days[index][Prayer.fajr]),
                            (s.iftar, days[index][Prayer.maghrib]),
                          ])
                            Column(
                              children: [
                                Text(
                                  name,
                                  style: t.labelLarge?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  hm(settings, time),
                                  style: t.titleLarge?.copyWith(
                                    color: kGold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (days.isNotEmpty)
            Section(
              title: s.ramadanTimetable,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      const Spacer(),
                      for (final (label, color) in [
                        (s.suhoorEnds, scheme.onSurface),
                        (s.iftar, scheme.primary),
                      ])
                        SizedBox(
                          width: 64,
                          child: Text(
                            label,
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            style: t.labelSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final (i, d) in days.indexed)
                  Container(
                    color: i == index
                        ? scheme.primary.withValues(alpha: 0.12)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${i + 1}',
                            style: t.titleSmall?.copyWith(
                              color: scheme.tertiary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${shortWeekdayName(settings.lang, d.date.weekday)} '
                            '${d.day} ${monthName(settings.lang, d.month)}',
                            style: t.bodyMedium,
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            hm2(d[Prayer.fajr]),
                            textAlign: TextAlign.end,
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            hm2(d[Prayer.maghrib]),
                            textAlign: TextAlign.end,
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    '${s.suhoorEnds}: ${s.prayer(Prayer.fajr)} · '
                    '${s.iftar}: ${s.prayer(Prayer.maghrib)}',
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          DuaCard(
            dua: Dua(
              DuaGroup.ramadan,
              s.niyyahLabel,
              kNiyyahArabic,
              '',
              s.niyyahText,
            ),
          ),
          const SizedBox(height: 12),
          for (final d in duas.where((d) => d.group == DuaGroup.ramadan)) ...[
            DuaCard(dua: d),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

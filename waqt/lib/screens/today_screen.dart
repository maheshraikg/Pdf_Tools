import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/background.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/day.dart';
import '../core/events.dart';
import '../core/prayer_calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'alerts_screen.dart';
import 'display_screen.dart';
import 'place_screen.dart';
import 'prayer_sheet.dart';
import 'prayer_table.dart';
import 'tracker_screen.dart';

/// Prayers shown as cards, in order (the other times are listed below).
const _cardPrayers = [
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  Timer? _tick;
  int _offsetDays = 0;
  AlertsHealth? _health;
  ClockStatus? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _checkHealth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkHealth();
  }

  Future<void> _checkHealth() async {
    final h = await Background.health();
    final c = await Native.clockStatus();
    if (mounted) {
      setState(() {
        _health = h;
        _clock = c;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final calc = settings.calculator;
    final now = DateTime.now().toUtc();
    final today = settings.today;
    final shown = DateTime.utc(
      today.year,
      today.month,
      today.day + _offsetDays,
    );
    final day = calc.day(shown.year, shown.month, shown.day);
    // Yesterday, today, tomorrow: enough for "previous" and "next" prayer.
    final around = calc.days(today.subtract(const Duration(days: 1)), 3);
    final next = nextPrayer(around.sublist(1), now);
    DateTime? previous;
    for (final d in around) {
      for (final p in Prayer.fard) {
        if (!d[p].isAfter(now)) previous = d[p];
      }
    }
    final scheme = Theme.of(context).colorScheme;
    bool isNext(Prayer p) =>
        next != null && next.prayer == p && _sameDay(next.day, day);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(
              day: day,
              today: around[1],
              next: _offsetDays == 0 ? next : null,
              previous: previous,
              now: now,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList.list(
              children: [
                if (!settings.placeChosen) ...[
                  _choosePlaceCard(context),
                  const SizedBox(height: 12),
                ],
                if (_clock != null && !_clock!.ok) ...[
                  _clockCard(context, _clock!),
                  const SizedBox(height: 12),
                ],
                if (_health != null && !_health!.ok) ...[
                  _healthCard(context, _health!),
                  const SizedBox(height: 12),
                ],
                if (settings.masjids.length > 1) ...[
                  _masjidTabs(context),
                  const SizedBox(height: 10),
                ],
                _daySwitcher(context, day),
                const SizedBox(height: 8),
                if (!settings.todayTable)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      icon: const Icon(Icons.table_rows_outlined, size: 18),
                      label: Text(s.viewChart),
                      onPressed: () =>
                          settings.updateQuietly((x) => x.todayTable = true),
                    ),
                  ),
                if (settings.todayTable) ...[
                  PrayerTable(day: day, now: now, isNext: isNext),
                  const SizedBox(height: 10),
                ],
                for (final p
                    in settings.todayTable
                        ? const <Prayer>[]
                        : _cardPrayers) ...[
                  _PrayerCard(
                    day: day,
                    prayer: p,
                    isNext: isNext(p),
                    isPast: day[p].isBefore(now) && !isNext(p),
                    started: !day[p].isAfter(now),
                  ),
                  const SizedBox(height: 10),
                ],
                if (!day.date.isAfter(today)) ...[
                  _trackerCard(context, day),
                  const SizedBox(height: 10),
                ],
                if (!settings.todayTable) _MoreTimes(day: day),
                const SizedBox(height: 18),
                Text(
                  '${day.source == TimeSource.timetable ? s.fromTimetable : '${s.calculated} · ${settings.method.name}'}'
                  '${day.source == TimeSource.calculation ? ' · ${s.asrName(settings.asr)}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mosque profiles as tabs: tap to switch Iqama times.
  Widget _masjidTabs(BuildContext context) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: settings.masjids.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final m = settings.masjids[i];
          final on = i == settings.activeMasjid;
          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => settings.selectMasjid(i),
            child: Container(
              constraints: const BoxConstraints(minWidth: 110, maxWidth: 190),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: on
                    ? heroGradient(Theme.of(context).brightness)
                    : null,
                color: on ? null : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: on
                    ? null
                    : Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.6),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    m.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : null,
                    ),
                  ),
                  Text(
                    m.description.isEmpty ? s.noDescription : m.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(
                      color: on ? kGold : scheme.onSurfaceVariant,
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

  static bool _sameDay(PrayerDay a, PrayerDay b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _daySwitcher(BuildContext context, PrayerDay day) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final label = _offsetDays == 0
        ? s.today
        : '${weekdayName(settings.lang, day.date.weekday)}, '
              '${day.day} ${monthName(settings.lang, day.month)}';
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: s.previousDay,
          onPressed: () => setState(() => _offsetDays--),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_offsetDays != 0)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => setState(() => _offsetDays = 0),
                  child: Text(s.backToToday),
                ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: s.nextDay,
          onPressed: () => setState(() => _offsetDays++),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  /// "3 of 5 prayed · 4-day streak", opening the tracker.
  Widget _trackerCard(BuildContext context, PrayerDay day) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final n = settings.log.count(day.date);
    final streak = settings.log.streak(settings.today);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const TrackerScreen())),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: n / Prayer.fard.length,
                      strokeWidth: 4,
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    ),
                    Text(
                      '$n',
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.prayedOf(n, Prayer.fard.length),
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      streak > 0 ? s.streakDays(streak) : s.tapToMarkPrayed,
                      style: t.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Icon(
                    Icons.local_fire_department,
                    color: scheme.tertiary,
                  ),
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choosePlaceCard(BuildContext context) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    // Text above the button: long (Malayalam) text must not be squeezed
    // beside it on narrow phones.
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const IconBadge(Icons.place),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.chooseYourPlace,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const PlaceScreen()),
                ),
                child: Text(s.choose),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The phone's clock decides when every alert fires.
  Widget _clockCard(BuildContext context, ClockStatus c) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final off = c.offset;
    return Card(
      color: scheme.errorContainer,
      child: ListTile(
        leading: Icon(Icons.schedule, color: scheme.error),
        title: Text(
          c.clockWrong
              ? s.clockOff(off!.inMinutes.abs().clamp(1, 9999))
              : s.clockNotAuto,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(s.clockHelp),
        trailing: FilledButton.tonal(
          onPressed: () async {
            await Native.openDateSettings();
            await Future<void>.delayed(const Duration(seconds: 1));
            await _checkHealth();
          },
          child: Text(s.fix),
        ),
      ),
    );
  }

  Widget _healthCard(BuildContext context, AlertsHealth h) {
    final s = context.s;
    final scheme = Theme.of(context).colorScheme;
    Widget item(String label, VoidCallback onFix) => ListTile(
      dense: true,
      leading: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(label),
      trailing: FilledButton.tonal(
        onPressed: () async {
          onFix();
          await Future<void>.delayed(const Duration(seconds: 1));
          await _checkHealth();
        },
        child: Text(s.fix),
      ),
    );
    return Card(
      color: scheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              s.alertsNeedAttention,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (!h.notifications)
            item(s.allowNotifications, Background.requestNotifications),
          if (!h.exactAlarms)
            item(s.allowExactAlarms, Background.requestExactAlarms),
          if (!h.battery)
            item(s.disableBatteryOptimisation, Native.openBatterySettings),
          if (!h.battery)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                s.batteryHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

/// Gradient header: place, dates, next prayer with a live countdown and the
/// progress from the previous prayer to the next.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.day,
    required this.today,
    required this.next,
    required this.previous,
    required this.now,
  });

  final PrayerDay day;
  final PrayerDay today;
  final ({Prayer prayer, DateTime at, PrayerDay day})? next;
  final DateTime? previous;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s, lang = settings.lang;
    final t = Theme.of(context).textTheme;
    final b = Theme.of(context).brightness;
    const white = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.75);

    // Between Azan and Iqama of a prayer today: Iqama countdown chip.
    String? iqamaLine;
    for (final fp in Prayer.fard) {
      final iq = iqamaTime(today, fp, settings.alerts);
      if (now.isAfter(today[fp]) && now.isBefore(iq)) {
        iqamaLine =
            '${s.prayer(fp, friday: today.isFriday)} · '
            '${s.iqamaIn(clockCountdown(iq.difference(now)))}';
      }
    }

    final n = next;
    double? progress;
    final prev = previous;
    if (n != null && prev != null) {
      final total = n.at.difference(prev).inSeconds;
      if (total > 0) {
        progress = (now.difference(prev).inSeconds / total).clamp(0.0, 1.0);
      }
    }
    const radius = BorderRadius.vertical(bottom: Radius.circular(32));

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: heroGradient(b)),
        child: CustomPaint(
          painter: IslamicPatternPainter(
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 12, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: _placeChip(context)),
                      const Spacer(),
                      IconButton(
                        tooltip: s.displayMode,
                        color: white,
                        icon: const Icon(Icons.tv_rounded),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DisplayScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    longDate(lang, day.date),
                    style: t.titleMedium?.copyWith(color: dim),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hijriLabel(lang, day.hijri),
                    style: t.titleSmall?.copyWith(
                      color: kGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  ..._occasionChips(context, dim),
                  if (n != null) ...[
                    const SizedBox(height: 22),
                    Text(
                      s.next.toUpperCase(),
                      style: t.labelMedium?.copyWith(
                        color: dim,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                s.prayer(n.prayer, friday: n.day.isFriday),
                                style: t.headlineMedium?.copyWith(
                                  color: white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            hm(settings, n.at),
                            style: t.titleLarge?.copyWith(
                              color: white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Digits always left-to-right, also in Arabic/Urdu.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        clockCountdown(n.at.difference(now), withHours: true),
                        style: t.displayMedium?.copyWith(
                          color: white,
                          fontWeight: FontWeight.w300,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (progress != null) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            color: kGold,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (iqamaLine != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: kGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          iqamaLine,
                          style: t.labelLarge?.copyWith(
                            color: kEmeraldDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ramadan Suhoor/Iftar times and an occasion within 3 days.
  List<Widget> _occasionChips(BuildContext context, Color dim) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final ev = upcomingEvents(
      settings.today,
      adjustDays: settings.hijriAdjust,
      count: 1,
    );
    final event = ev.isNotEmpty && ev.first.daysLeft <= 3 ? ev.first : null;
    final ramadan = today.hijri.isRamadan;
    if (event == null && !ramadan) return const [];
    Widget pill(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kGold),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: t.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    return [
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (ramadan) ...[
            pill(
              Icons.restaurant_outlined,
              '${s.suhoorEnds} ${hm(settings, today[Prayer.imsak])}',
            ),
            pill(
              Icons.wb_twilight_outlined,
              '${s.iftar} ${hm(settings, today[Prayer.maghrib])}',
            ),
          ],
          if (event != null)
            pill(
              Icons.star_rounded,
              '${s.eventName(event.event)} · ${s.daysLeft(event.daysLeft)}',
            ),
        ],
      ),
    ];
  }

  Widget _placeChip(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const PlaceScreen())),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place, size: 18, color: kGold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  settings.place.label(s.ml),
                  style: t.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.expand_more, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// One prayer: icon, name, Iqama, Azan time and a bell to switch its alert.
class _PrayerCard extends StatelessWidget {
  const _PrayerCard({
    required this.day,
    required this.prayer,
    required this.isNext,
    required this.isPast,
    required this.started,
  });

  final PrayerDay day;
  final Prayer prayer;
  final bool isNext;
  final bool isPast;

  /// Its time has come: it can be marked as prayed.
  final bool started;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;
    final p = prayer;
    final alert = p.isFard ? settings.alerts.of(p) : null;
    final fg = isNext ? Colors.white : scheme.onSurface;
    final sub = isNext
        ? Colors.white.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant;

    final card = Container(
      decoration: BoxDecoration(
        gradient: isNext ? heroGradient(theme.brightness) : null,
        color: isNext ? null : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: isNext
            ? null
            : Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: kEmerald.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 4, 12),
      child: Row(
        children: [
          if (p.isFard && started)
            _PrayedToggle(
              prayed: settings.log.prayed(day.date, p),
              icon: prayerIcon(p),
              onDark: isNext,
              tooltip: s.markPrayed,
              onTap: () =>
                  settings.updateQuietly((x) => x.log.toggle(day.date, p)),
            )
          else
            IconBadge(
              prayerIcon(p),
              color: isNext
                  ? kGold
                  : (p.isFard ? scheme.primary : scheme.tertiary),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    s.prayer(p, friday: day.isFriday),
                    style: t.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (alert != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${s.iqama} ${hm(settings, iqamaTime(day, p, settings.alerts))}',
                      style: t.bodySmall?.copyWith(color: sub),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                hm(settings, day[p]),
                style: t.titleLarge?.copyWith(
                  color: fg,
                  fontWeight: isNext ? FontWeight.w800 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: p == Prayer.sunrise
                ? IconButton(
                    tooltip: s.sunriseAlert,
                    icon: Icon(
                      settings.alerts.sunriseAlert
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: settings.alerts.sunriseAlert
                          ? scheme.tertiary
                          : sub,
                    ),
                    onPressed: () => settings.update(
                      (x) => x.alerts = x.alerts.copyWith(
                        sunriseAlert: !x.alerts.sunriseAlert,
                      ),
                    ),
                  )
                : alert == null
                ? null
                : IconButton(
                    tooltip: s.azanAlert,
                    color: isNext ? kGold : scheme.primary,
                    icon: Icon(
                      alert.azan
                          ? Icons.notifications_active
                          : Icons.notifications_off_outlined,
                      color: alert.azan ? null : sub,
                    ),
                    onPressed: () => settings.update(
                      (x) => x.alerts = x.alerts.withPrayer(
                        p,
                        alert.copyWith(azan: !alert.azan),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
    final prayed = p.isFard && settings.log.prayed(day.date, p);
    return Opacity(
      opacity: isPast && !prayed ? 0.6 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showPrayerSheet(context, day, p),
          child: card,
        ),
      ),
    );
  }
}

/// Prayer icon that turns into a tick once marked as prayed.
class _PrayedToggle extends StatelessWidget {
  const _PrayedToggle({
    required this.prayed,
    required this.icon,
    required this.onDark,
    required this.tooltip,
    required this.onTap,
  });

  final bool prayed, onDark;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = onDark ? kGold : scheme.primary;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: prayed ? c : c.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: c.withValues(alpha: prayed ? 1 : 0.6)),
          ),
          child: Icon(
            prayed ? Icons.check_rounded : icon,
            size: 20,
            color: prayed ? (onDark ? kEmeraldDeep : scheme.onPrimary) : c,
          ),
        ),
      ),
    );
  }
}

/// The other times of the original chart: Imsak, Ishraq, Jumu'ah,
/// Taraweeh, Tahajjud and Eid, each with its alert bell.
class _MoreTimes extends StatelessWidget {
  const _MoreTimes({required this.day});
  final PrayerDay day;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final c = settings.alerts;
    void set(AlertConfig n) => settings.update((x) => x.alerts = n);
    void openAlerts() => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AlertsScreen()));

    // Jumu'ah of this week (today when it is Friday).
    final ahead = (DateTime.friday - day.date.weekday) % 7;
    final f = day.date.add(Duration(days: ahead));
    final friday = settings.calculator.day(f.year, f.month, f.day);
    // The coming Eid by the Hijri date.
    final h = day.hijri;
    final fitr = h.month < 10 || (h.month == 10 && h.day <= 1);
    final eidMinutes = fitr ? c.eidFitrTime : c.eidAdhaTime;

    final rows = <Widget>[
      if (settings.showExtras)
        _MoreRow(
          icon: prayerIcon(Prayer.imsak),
          label: s.prayer(Prayer.imsak),
          time: hm(settings, day[Prayer.imsak]),
          alert: c.imsakAlert,
          onAlert: () => set(c.copyWith(imsakAlert: !c.imsakAlert)),
          onTap: () => showPrayerSheet(context, day, Prayer.imsak),
        ),
      if (settings.showExtras)
        _MoreRow(
          icon: prayerIcon(Prayer.ishraq),
          label: s.prayer(Prayer.ishraq),
          time: hm(settings, day[Prayer.ishraq]),
          alert: c.ishraqAlert,
          onAlert: () => set(c.copyWith(ishraqAlert: !c.ishraqAlert)),
          onTap: () => showPrayerSheet(context, day, Prayer.ishraq),
        ),
      _MoreRow(
        icon: Icons.groups_outlined,
        label: s.prayer(Prayer.dhuhr, friday: true),
        sub: ahead == 0
            ? null
            : '${weekdayName(settings.lang, DateTime.friday)} ${f.day}',
        time: hm(settings, iqamaTime(friday, Prayer.dhuhr, c)),
        alert: c.of(Prayer.dhuhr).iqama,
        onAlert: () => set(
          c.withPrayer(
            Prayer.dhuhr,
            c.of(Prayer.dhuhr).copyWith(iqama: !c.of(Prayer.dhuhr).iqama),
          ),
        ),
        onTap: () => showPrayerSheet(context, friday, Prayer.dhuhr),
      ),
      _MoreRow(
        icon: Icons.nights_stay_outlined,
        label: s.specialTitle(SpecialEvent.taraweeh),
        time: hm(
          settings,
          iqamaTime(
            day,
            Prayer.isha,
            c,
          ).add(Duration(minutes: c.taraweehMinutesAfterIsha)),
        ),
        alert: c.taraweehAlert,
        onAlert: () => set(c.copyWith(taraweehAlert: !c.taraweehAlert)),
        onTap: openAlerts,
      ),
      if (settings.showExtras)
        _MoreRow(
          icon: prayerIcon(Prayer.tahajjud),
          label: s.prayer(Prayer.tahajjud),
          time: hm(settings, day[Prayer.tahajjud]),
          alert: c.tahajjudAlert,
          onAlert: () => set(c.copyWith(tahajjudAlert: !c.tahajjudAlert)),
          onTap: () => showPrayerSheet(context, day, Prayer.tahajjud),
        ),
      _MoreRow(
        icon: Icons.celebration_outlined,
        label: s.specialTitle(
          fitr ? SpecialEvent.eidAlFitr : SpecialEvent.eidAlAdha,
        ),
        time: hm(settings, day.atLocal(eidMinutes)),
        alert: c.eidAlert,
        onAlert: () => set(c.copyWith(eidAlert: !c.eidAlert)),
        onTap: openAlerts,
      ),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 60),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.alert,
    required this.onAlert,
    required this.onTap,
    this.sub,
  });

  final IconData icon;
  final String label, time;
  final String? sub;
  final bool alert;
  final VoidCallback onAlert, onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: scheme.tertiary),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: t.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              time,
              style: t.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            IconButton(
              tooltip: s.alerts,
              icon: Icon(
                alert
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                color: alert ? scheme.primary : scheme.outline,
              ),
              onPressed: onAlert,
            ),
          ],
        ),
      ),
    );
  }
}

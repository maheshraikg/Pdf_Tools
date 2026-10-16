import 'dart:async';

import 'package:flutter/material.dart';

import '../app/background.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/day.dart';
import '../core/prayer_calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'display_screen.dart';
import 'place_screen.dart';

/// Prayers shown as cards, in order (extras go in the small row below).
const _cardPrayers = [
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];
const _extraPrayers = [Prayer.imsak, Prayer.ishraq, Prayer.tahajjud];

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> with WidgetsBindingObserver {
  Timer? _tick;
  int _offsetDays = 0;
  AlertsHealth? _health;

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
    if (mounted) setState(() => _health = h);
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
                if (_health != null && !_health!.ok) ...[
                  _healthCard(context, _health!),
                  const SizedBox(height: 12),
                ],
                _daySwitcher(context, day),
                const SizedBox(height: 8),
                for (final p in _cardPrayers) ...[
                  _PrayerCard(
                    day: day,
                    prayer: p,
                    isNext: isNext(p),
                    isPast: day[p].isBefore(now) && !isNext(p),
                  ),
                  const SizedBox(height: 10),
                ],
                if (settings.showExtras) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      for (final p in _extraPrayers) ...[
                        if (p != _extraPrayers.first) const SizedBox(width: 10),
                        Expanded(
                          child: _ExtraTile(day: day, prayer: p),
                        ),
                      ],
                    ],
                  ),
                ],
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
  });

  final PrayerDay day;
  final Prayer prayer;
  final bool isNext;
  final bool isPast;

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
            child: alert == null
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
    return Opacity(opacity: isPast ? 0.55 : 1, child: card);
  }
}

/// Small tile for Imsak / Ishraq / Tahajjud.
class _ExtraTile extends StatelessWidget {
  const _ExtraTile({required this.day, required this.prayer});
  final PrayerDay day;
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(prayerIcon(prayer), size: 20, color: scheme.tertiary),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                s.prayer(prayer),
                style: t.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hm(settings, day[prayer]),
                style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

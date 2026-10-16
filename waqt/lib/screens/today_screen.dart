import 'dart:async';

import 'package:flutter/material.dart';

import '../app/background.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/day.dart';
import '../core/prayer_calc.dart';
import 'display_screen.dart';
import 'place_screen.dart';

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
    final upcoming = calc.days(today, 2);
    final next = nextPrayer(upcoming, now);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        actions: [
          IconButton(
            tooltip: s.displayMode,
            icon: const Icon(Icons.tv),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const DisplayScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (!settings.placeChosen) _choosePlaceCard(context),
          if (_health != null && !_health!.ok) _healthCard(context, _health!),
          _header(context, day),
          if (_offsetDays == 0 && next != null)
            _nextCard(context, next.prayer, next.at, next.day, now),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _tableHeader(context),
                for (final p in Prayer.values)
                  if (p.isFard || p == Prayer.sunrise || settings.showExtras)
                    _row(context, day, p, next, now),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: s.previousDay,
                onPressed: () => setState(() => _offsetDays--),
                icon: const Icon(Icons.chevron_left),
              ),
              TextButton(
                onPressed: _offsetDays == 0
                    ? null
                    : () => setState(() => _offsetDays = 0),
                child: Text(s.backToToday),
              ),
              IconButton(
                tooltip: s.nextDay,
                onPressed: () => setState(() => _offsetDays++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Center(
            child: Text(
              '${day.source == TimeSource.timetable ? s.fromTimetable : '${s.calculated} · ${settings.method.name}'}'
              '${day.source == TimeSource.calculation ? ' · ${s.asrName(settings.asr)}' : ''}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choosePlaceCard(BuildContext context) {
    final s = context.s;
    // Text above the button: long (Malayalam) text must not be squeezed
    // beside it on narrow phones.
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place),
                const SizedBox(width: 12),
                Expanded(child: Text(s.chooseYourPlace)),
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
      leading: Icon(Icons.warning_amber, color: scheme.error),
      title: Text(label),
      trailing: TextButton(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              s.alertsNeedAttention,
              style: Theme.of(context).textTheme.titleSmall,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                s.batteryHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, PrayerDay day) {
    final settings = context.settings, s = context.s, lang = settings.lang;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const PlaceScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.place, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      settings.place.label(s.ml),
                      style: t.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          Text(longDate(lang, day.date), style: t.bodyLarge),
          Text(
            hijriLabel(settings.lang, day.hijri),
            style: t.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nextCard(
    BuildContext context,
    Prayer p,
    DateTime at,
    PrayerDay day,
    DateTime now,
  ) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    // Between Azan and Iqama of the current prayer, count down to Iqama.
    String? iqamaLine;
    final today = settings.calculator.day(
      settings.today.year,
      settings.today.month,
      settings.today.day,
    );
    for (final fp in Prayer.fard) {
      final iq = iqamaTime(today, fp, settings.alerts);
      if (now.isAfter(today[fp]) && now.isBefore(iq)) {
        iqamaLine =
            '${s.prayer(fp, friday: today.isFriday)}: ${s.iqamaIn(countdown(s, iq.difference(now)))}';
      }
    }
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(s.next, style: t.labelLarge),
            Text(
              s.prayer(p, friday: day.isFriday),
              style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${hm(settings, at)} · ${s.inTime(countdown(s, at.difference(now)))}',
              style: t.titleMedium,
            ),
            if (iqamaLine != null) ...[
              const SizedBox(height: 6),
              Text(iqamaLine, style: t.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    PrayerDay day,
    Prayer p,
    ({Prayer prayer, DateTime at, PrayerDay day})? next,
    DateTime now,
  ) {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final isNext =
        next != null &&
        next.prayer == p &&
        next.day.year == day.year &&
        next.day.month == day.month &&
        next.day.day == day.day;
    final style = TextStyle(
      fontSize: p.isFard ? 17 : 14,
      fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
      color: p.isFard ? null : scheme.onSurfaceVariant,
    );
    final alert = p.isFard ? settings.alerts.of(p) : null;
    // Fixed column widths with scale-down text: long names (Malayalam) and
    // 12-hour times never wrap or collide on narrow phones.
    return Container(
      color: isNext ? scheme.secondaryContainer : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _Fit(
              Text(s.prayer(p, friday: day.isFriday), style: style),
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          SizedBox(
            width: 24,
            child: alert == null
                ? null
                : Icon(
                    alert.azan
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
          SizedBox(
            width: _azanWidth,
            child: _Fit(Text(hm(settings, day[p]), style: style)),
          ),
          SizedBox(
            width: _iqamaWidth,
            child: alert == null
                ? null
                : _Fit(
                    Text(
                      hm(settings, iqamaTime(day, p, settings.alerts)),
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                        fontWeight: isNext ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Column titles above the times.
  Widget _tableHeader(BuildContext context) {
    final s = context.s;
    final st = Theme.of(context).textTheme.labelSmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: _azanWidth,
            child: Text(s.azan, style: st, textAlign: TextAlign.end),
          ),
          SizedBox(
            width: _iqamaWidth,
            child: Text(s.iqama, style: st, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

const double _azanWidth = 92;
const double _iqamaWidth = 84;

/// Right-aligned (by default) text that shrinks instead of wrapping.
class _Fit extends StatelessWidget {
  const _Fit(this.child, {this.alignment = AlignmentDirectional.centerEnd});
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

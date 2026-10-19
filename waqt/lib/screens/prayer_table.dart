import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../core/alerts.dart';
import '../core/day.dart';
import '../core/prayer_calc.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'alerts_screen.dart';
import 'prayer_sheet.dart';

/// The day as one chart, like the original app's: each row has the Azan
/// time and its bell, the minutes box, the Iqama (or resulting) time and
/// its bell. Below the five prayers: Sunrise → Ishraq, Jumu'ah, Taraweeh,
/// Tahajjud, Imsak and Eid.
class PrayerTable extends StatelessWidget {
  const PrayerTable({
    super.key,
    required this.day,
    required this.now,
    required this.isNext,
  });

  final PrayerDay day;
  final DateTime now;
  final bool Function(Prayer) isNext;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final c = settings.alerts;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void set(AlertConfig n) => settings.update((x) => x.alerts = n);
    void sheet(PrayerDay d, Prayer p) => showPrayerSheet(context, d, p);
    void openAlerts() => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AlertsScreen()));
    String t(DateTime x) => _short(settings, x);
    String signed(int m) => m > 0 ? '+$m' : '$m';

    // Jumu'ah of this week (today when it is Friday).
    final ahead = (DateTime.friday - day.date.weekday) % 7;
    final f = day.date.add(Duration(days: ahead));
    final friday = settings.calculator.day(f.year, f.month, f.day);
    final h = day.hijri;
    final fitr = h.month < 10 || (h.month == 10 && h.day <= 1);
    final eidMinutes = fitr ? c.eidFitrTime : c.eidAdhaTime;
    final eidAt = day.atLocal(eidMinutes);
    final taraweeh = iqamaTime(
      day,
      Prayer.isha,
      c,
    ).add(Duration(minutes: c.taraweehMinutesAfterIsha));

    String clock(int minutes) =>
        t(day.atLocal(minutes)); // a fixed local time, e.g. 1:00

    final rows = <_Row>[
      for (final p in Prayer.fard) ...[
        () {
          final fri = p == Prayer.dhuhr && day.isFriday;
          final fixed = c.fixedIqama(p, day.isFriday);
          final a = c.of(p);
          return _Row(
            icon: prayerIcon(p),
            name: s.prayer(p, friday: day.isFriday),
            first: t(day[p]),
            firstBell: a.azan,
            onFirstBell: () => set(c.withPrayer(p, a.copyWith(azan: !a.azan))),
            box: fixed != null ? clock(fixed) : '${c.iqamaDelay(p, fri)}',
            second: t(iqamaTime(day, p, c)),
            secondBell: a.iqama,
            onSecondBell: () =>
                set(c.withPrayer(p, a.copyWith(iqama: !a.iqama))),
            next: isNext(p),
            past: !day[p].isAfter(now) && !isNext(p),
            // Started: the icon ticks it as prayed (tracker).
            prayed: day[p].isAfter(now)
                ? null
                : settings.log.prayed(day.date, p),
            onPrayed: () =>
                settings.updateQuietly((x) => x.log.toggle(day.date, p)),
            prayedTooltip: s.markPrayed,
            onTap: () => sheet(day, p),
          );
        }(),
        // Sunrise right after Subh, as on the printed calendars.
        if (p == Prayer.fajr)
          _Row(
            icon: prayerIcon(Prayer.sunrise),
            name: s.prayer(Prayer.sunrise),
            first: t(day[Prayer.sunrise]),
            firstBell: c.sunriseAlert,
            onFirstBell: () => set(c.copyWith(sunriseAlert: !c.sunriseAlert)),
            box: '',
            second: '',
            secondBell: null,
            onSecondBell: null,
            past: !day[Prayer.sunrise].isAfter(now),
            onTap: () => sheet(day, Prayer.sunrise),
          ),
      ],
      if (settings.showExtras) ...[
        _Row(
          icon: prayerIcon(Prayer.ishraq),
          name: s.prayer(Prayer.ishraq),
          first: t(day[Prayer.sunrise]),
          box: '+${settings.ishraqMinutes}',
          second: t(day[Prayer.ishraq]),
          secondBell: c.ishraqAlert,
          onSecondBell: () => set(c.copyWith(ishraqAlert: !c.ishraqAlert)),
          extra: true,
          onTap: () => sheet(day, Prayer.ishraq),
        ),
        if (!day.isFriday)
          _Row(
            icon: Icons.groups_outlined,
            name: s.prayer(Prayer.dhuhr, friday: true),
            first: t(friday[Prayer.dhuhr]),
            box: c.jumuahFixedIqama != null
                ? clock(c.jumuahFixedIqama!)
                : '${c.jumuahIqamaDelay}',
            second: t(iqamaTime(friday, Prayer.dhuhr, c)),
            secondBell: c.of(Prayer.dhuhr).iqama,
            onSecondBell: () => set(
              c.withPrayer(
                Prayer.dhuhr,
                c.of(Prayer.dhuhr).copyWith(iqama: !c.of(Prayer.dhuhr).iqama),
              ),
            ),
            extra: true,
            onTap: () => sheet(friday, Prayer.dhuhr),
          ),
        _Row(
          icon: Icons.nights_stay_outlined,
          name: s.specialTitle(SpecialEvent.taraweeh),
          first: t(day[Prayer.isha]),
          box: '+${c.taraweehMinutesAfterIsha}',
          second: t(taraweeh),
          secondBell: c.taraweehAlert,
          onSecondBell: () => set(c.copyWith(taraweehAlert: !c.taraweehAlert)),
          extra: true,
          onTap: openAlerts,
        ),
        _Row(
          icon: prayerIcon(Prayer.tahajjud),
          name: s.prayer(Prayer.tahajjud),
          first: t(day[Prayer.fajr]),
          // Minutes before Fajr, whichever night the time falls in.
          box: signed(
            -((day[Prayer.fajr].difference(day[Prayer.tahajjud]).inMinutes) %
                (24 * 60)),
          ),
          second: t(day[Prayer.tahajjud]),
          secondBell: c.tahajjudAlert,
          onSecondBell: () => set(c.copyWith(tahajjudAlert: !c.tahajjudAlert)),
          extra: true,
          onTap: () => sheet(day, Prayer.tahajjud),
        ),
        _Row(
          icon: prayerIcon(Prayer.imsak),
          name: s.prayer(Prayer.imsak),
          first: t(day[Prayer.fajr]),
          box: '-${settings.imsakMinutes}',
          second: t(day[Prayer.imsak]),
          secondBell: c.imsakAlert,
          onSecondBell: () => set(c.copyWith(imsakAlert: !c.imsakAlert)),
          extra: true,
          onTap: () => sheet(day, Prayer.imsak),
        ),
        _Row(
          icon: Icons.celebration_outlined,
          name: s.eidShort,
          first: t(day[Prayer.sunrise]),
          box: clock(eidMinutes),
          second: t(eidAt),
          secondBell: c.eidAlert,
          onSecondBell: () => set(c.copyWith(eidAlert: !c.eidAlert)),
          extra: true,
          onTap: openAlerts,
        ),
      ],
    ];

    final head = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(2, 0, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        tooltip: s.viewCards,
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.view_agenda_outlined,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                        onPressed: () =>
                            settings.updateQuietly((x) => x.todayTable = false),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: _timeW + _bellW,
                    child: Text(
                      s.azan.toUpperCase(),
                      style: head,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: _boxW),
                  SizedBox(
                    width: _timeW + _bellW,
                    child: Text(
                      s.iqama.toUpperCase(),
                      style: head,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < rows.length; i++) ...[
              if (i == Prayer.fard.length + 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Divider(
                    height: 1,
                    color: scheme.outlineVariant,
                    indent: 14,
                    endIndent: 14,
                  ),
                ),
              Appear(key: ValueKey('${day.date}-$i'), index: i, child: rows[i]),
            ],
          ],
        ),
      ),
    );
  }
}

const double _timeW = 60, _bellW = 30, _boxW = 52;

/// "5:03" / "17:03": the chart has no room for AM/PM.
String _short(AppSettings settings, DateTime utc) {
  final w = settings.wall(utc);
  final m = w.minute.toString().padLeft(2, '0');
  if (settings.use24h) return '${w.hour.toString().padLeft(2, '0')}:$m';
  final h = w.hour % 12 == 0 ? 12 : w.hour % 12;
  return '$h:$m';
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.name,
    required this.first,
    required this.box,
    required this.second,
    required this.secondBell,
    required this.onSecondBell,
    required this.onTap,
    this.firstBell,
    this.onFirstBell,
    this.next = false,
    this.past = false,
    this.extra = false,
    this.prayed,
    this.onPrayed,
    this.prayedTooltip,
  });

  /// Marked as prayed (null: cannot be marked yet / not a prayer).
  final bool? prayed;
  final VoidCallback? onPrayed;
  final String? prayedTooltip;

  final IconData icon;
  final String name, first, box, second;
  final bool? firstBell;
  final bool? secondBell;
  final VoidCallback? onFirstBell;
  final VoidCallback? onSecondBell;
  final VoidCallback onTap;

  /// The next prayer (highlighted), a passed one (dimmed), or one of the
  /// rows below the five prayers (base time greyed, like the original).
  final bool next, past, extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tt = theme.textTheme;
    final fg = next ? Colors.white : scheme.onSurface;
    final faint = next
        ? Colors.white.withValues(alpha: 0.75)
        : scheme.onSurfaceVariant.withValues(alpha: 0.7);
    final timeStyle = tt.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: fg,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget bell(bool? on, VoidCallback? onTap) => SizedBox(
      width: _bellW,
      child: on == null
          ? null
          : InkResponse(
              onTap: onTap,
              radius: 18,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                  child: child,
                ),
                child: Icon(
                  on
                      ? Icons.notifications_active
                      : Icons.notifications_off_outlined,
                  key: ValueKey(on),
                  size: 20,
                  color: on
                      ? (next ? kGold : scheme.primary)
                      : (next ? Colors.white54 : scheme.outline),
                ),
              ),
            ),
    );

    Widget time(String v, {bool grey = false}) => SizedBox(
      width: _timeW,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          v,
          style: grey
              ? timeStyle?.copyWith(fontWeight: FontWeight.w500, color: faint)
              : timeStyle,
        ),
      ),
    );

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(horizontal: next ? 4 : 6, vertical: 1),
      padding: EdgeInsetsDirectional.fromSTEB(
        8,
        next ? 12 : 9,
        0,
        next ? 12 : 9,
      ),
      decoration: BoxDecoration(
        gradient: next ? heroGradient(theme.brightness) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: next
            ? [
                BoxShadow(
                  color: kEmerald.withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : const [],
      ),
      child: Row(
        children: [
          if (prayed != null)
            Tooltip(
              message: prayedTooltip ?? '',
              child: InkResponse(
                onTap: onPrayed,
                radius: 18,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: prayed!
                        ? (next ? kGold : scheme.primary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: next ? kGold : scheme.primary,
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    prayed! ? Icons.check_rounded : icon,
                    size: 16,
                    color: prayed!
                        ? (next ? kEmeraldDeep : scheme.onPrimary)
                        : (next ? kGold : scheme.primary),
                  ),
                ),
              ),
            )
          else
            Icon(
              icon,
              size: 20,
              color: next ? kGold : (extra ? scheme.tertiary : scheme.primary),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                name,
                style: tt.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          time(first, grey: extra),
          bell(firstBell, onFirstBell),
          SizedBox(
            width: _boxW,
            child: box.isEmpty
                ? null
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: next
                            ? Colors.white.withValues(alpha: 0.16)
                            : scheme.secondaryContainer.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          box,
                          style: tt.labelMedium?.copyWith(
                            color: next
                                ? Colors.white
                                : scheme.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          time(second),
          bell(secondBell, onSecondBell),
        ],
      ),
    );
    return Opacity(
      opacity: past && prayed != true ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: row,
      ),
    );
  }
}

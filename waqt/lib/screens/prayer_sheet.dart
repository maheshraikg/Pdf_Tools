import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/day.dart';
import '../core/prayer_calc.dart';
import '../ui/widgets.dart';
import 'alerts_screen.dart';
import 'settings_screen.dart';

/// Everything about one time, editable from the Today screen: alerts,
/// Iqama minutes or a fixed Iqama, a reminder and a ± minutes adjustment.
Future<void> showPrayerSheet(BuildContext context, PrayerDay day, Prayer p) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _PrayerSheet(day: day, prayer: p),
    );

class _PrayerSheet extends StatelessWidget {
  const _PrayerSheet({required this.day, required this.prayer});
  final PrayerDay day;
  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final p = prayer;
    final c = settings.alerts;
    final friday = p == Prayer.dhuhr && day.isFriday;
    void set(AlertConfig n) => settings.update((x) => x.alerts = n);
    final a = c.of(p);
    // The day's times are recomputed after a change.
    final d = settings.calculator.day(day.year, day.month, day.day);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ListTile(
              leading: IconBadge(prayerIcon(p)),
              title: Text(
                s.prayer(p, friday: day.isFriday),
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                [
                  '${s.azan} ${hm(settings, d[p])}',
                  if (p.isFard)
                    '${s.iqama} ${hm(settings, iqamaTime(d, p, c))}',
                ].join(' · '),
              ),
            ),
            const Divider(),
            if (p.isFard) ...[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(s.azanAlert),
                value: a.azan,
                onChanged: (v) => set(c.withPrayer(p, a.copyWith(azan: v))),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.campaign_outlined),
                title: Text(s.iqamaAlert),
                value: a.iqama,
                onChanged: (v) => set(c.withPrayer(p, a.copyWith(iqama: v))),
              ),
              MinutesStepper(
                label: friday ? s.jumuahIqama : s.iqamaAfterAzan,
                value: friday ? c.jumuahIqamaDelay : a.iqamaDelay,
                min: 0,
                max: friday ? 90 : 60,
                onChanged: (v) => set(
                  friday
                      ? c.copyWith(jumuahIqamaDelay: v)
                      : c.withPrayer(p, a.copyWith(iqamaDelay: v)),
                ),
              ),
              FixedIqamaTile(
                label: friday ? s.jumuahFixedIqama : null,
                value: friday ? c.jumuahFixedIqama : a.fixedIqama,
                onChanged: (v) => set(
                  friday
                      ? c.copyWith(jumuahFixedIqama: v)
                      : c.withPrayer(p, a.copyWith(fixedIqama: v)),
                ),
              ),
              MinutesStepper(
                label: s.reminderBefore,
                value: a.reminderMinutes,
                min: 0,
                max: 60,
                zeroLabel: s.off,
                onChanged: (v) =>
                    set(c.withPrayer(p, a.copyWith(reminderMinutes: v))),
              ),
            ],
            if (p == Prayer.imsak) ...[
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(s.imsakAlert),
                value: c.imsakAlert,
                onChanged: (v) => set(c.copyWith(imsakAlert: v)),
              ),
              MinutesStepper(
                label: s.imsakBeforeFajr,
                value: settings.imsakMinutes,
                min: 0,
                max: 60,
                onChanged: (v) => settings.update((x) => x.imsakMinutes = v),
              ),
            ],
            if (p == Prayer.ishraq)
              MinutesStepper(
                label: s.ishraqAfterSunrise,
                value: settings.ishraqMinutes,
                min: 0,
                max: 60,
                onChanged: (v) => settings.update((x) => x.ishraqMinutes = v),
              ),
            if (p == Prayer.tahajjud)
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: Text(s.tahajjudAlert),
                value: c.tahajjudAlert,
                onChanged: (v) => set(c.copyWith(tahajjudAlert: v)),
              ),
            if (p != Prayer.imsak && p != Prayer.ishraq)
              MinutesStepper(
                label: s.adjustThisTime,
                value: settings.adjustments[p] ?? 0,
                min: -30,
                max: 30,
                onChanged: (v) => settings.update(
                  (x) =>
                      x.adjustments = {...x.adjustments, p: v}
                        ..removeWhere((_, m) => m == 0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

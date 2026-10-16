import 'package:flutter/material.dart';

import '../app/background.dart';
import '../app/native.dart';
import '../app/scope.dart';
import '../core/alerts.dart';
import '../core/prayer_calc.dart';
import '../ui/widgets.dart';
import 'settings_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with WidgetsBindingObserver {
  bool _dnd = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDnd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkDnd();
  }

  Future<void> _checkDnd() async {
    final v = await Native.hasDndAccess();
    if (mounted) setState(() => _dnd = v || !Native.supported);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final c = settings.alerts;
    void set(AlertConfig n) => settings.update((x) => x.alerts = n);

    return Scaffold(
      appBar: AppBar(title: Text(s.alerts)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Section(
            children: [
              for (final p in Prayer.fard)
                ExpansionTile(
                  leading: IconBadge(
                    prayerIcon(p),
                    color: c.of(p).azan
                        ? null
                        : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text(s.prayer(p)),
                  subtitle: Text(
                    [
                      if (c.of(p).azan) s.azan,
                      if (c.of(p).iqama) '${s.iqama} +${c.of(p).iqamaDelay}',
                    ].join(' · '),
                  ),
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: Text(s.azanAlert),
                      value: c.of(p).azan,
                      onChanged: (v) =>
                          set(c.withPrayer(p, c.of(p).copyWith(azan: v))),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: Text(s.iqamaAlert),
                      value: c.of(p).iqama,
                      onChanged: (v) =>
                          set(c.withPrayer(p, c.of(p).copyWith(iqama: v))),
                    ),
                    MinutesStepper(
                      label: s.iqamaAfterAzan,
                      value: c.of(p).iqamaDelay,
                      min: 0,
                      max: 60,
                      onChanged: (v) =>
                          set(c.withPrayer(p, c.of(p).copyWith(iqamaDelay: v))),
                    ),
                    _FixedIqamaTile(
                      value: c.of(p).fixedIqama,
                      onChanged: (v) =>
                          set(c.withPrayer(p, c.of(p).copyWith(fixedIqama: v))),
                    ),
                    MinutesStepper(
                      label: s.reminderBefore,
                      value: c.of(p).reminderMinutes,
                      min: 0,
                      max: 60,
                      zeroLabel: s.off,
                      onChanged: (v) => set(
                        c.withPrayer(p, c.of(p).copyWith(reminderMinutes: v)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Section(
            title: s.prayer(Prayer.dhuhr, friday: true),
            children: [
              MinutesStepper(
                label: s.jumuahIqama,
                value: c.jumuahIqamaDelay,
                min: 0,
                max: 90,
                onChanged: (v) => set(c.copyWith(jumuahIqamaDelay: v)),
              ),
              _FixedIqamaTile(
                label: s.jumuahFixedIqama,
                value: c.jumuahFixedIqama,
                onChanged: (v) => set(c.copyWith(jumuahFixedIqama: v)),
              ),
            ],
          ),
          Section(
            children: [
              SwitchListTile(
                secondary: IconBadge(prayerIcon(Prayer.imsak)),
                title: Text(s.imsakAlert),
                value: c.imsakAlert,
                onChanged: (v) => set(c.copyWith(imsakAlert: v)),
              ),
              SwitchListTile(
                secondary: IconBadge(prayerIcon(Prayer.tahajjud)),
                title: Text(s.tahajjudAlert),
                value: c.tahajjudAlert,
                onChanged: (v) => set(c.copyWith(tahajjudAlert: v)),
              ),
            ],
          ),
          Section(
            children: [
              SwitchListTile(
                secondary: const IconBadge(Icons.volume_off),
                title: Text(s.autoSilent),
                subtitle: Text(s.autoSilentHelp),
                value: c.silentEnabled,
                onChanged: (v) => set(c.copyWith(silentEnabled: v)),
              ),
              if (c.silentEnabled) ...[
                ListTile(
                  title: Text(s.silentMode),
                  trailing: SegmentedButton<SilentMode>(
                    segments: [
                      for (final m in SilentMode.values)
                        ButtonSegment(
                          value: m,
                          label: Text(s.silentModeName(m).split(' ').first),
                        ),
                    ],
                    selected: {c.silentMode},
                    onSelectionChanged: (v) =>
                        set(c.copyWith(silentMode: v.first)),
                  ),
                ),
                if (c.silentMode == SilentMode.silent && !_dnd)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(s.dndAccessNeeded),
                    trailing: TextButton(
                      onPressed: Native.openDndSettings,
                      child: Text(s.grant),
                    ),
                  ),
                MinutesStepper(
                  label: s.silentAfterIqama,
                  value: c.silentMinutesAfterIqama,
                  min: 5,
                  max: 60,
                  onChanged: (v) => set(c.copyWith(silentMinutesAfterIqama: v)),
                ),
                MinutesStepper(
                  label: s.jumuahSilent,
                  value: c.jumuahSilentMinutes,
                  min: 10,
                  max: 90,
                  onChanged: (v) => set(c.copyWith(jumuahSilentMinutes: v)),
                ),
              ],
            ],
          ),
          Section(
            children: [
              ListTile(
                leading: const IconBadge(Icons.play_arrow_rounded),
                title: Text(s.testAlert),
                onTap: () async {
                  await Background.requestNotifications();
                  await Background.testAlert(settings);
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
            child: Text(
              s.alertsScheduledNote,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Fixed Iqama time": tap to pick a clock time, ✕ to go back to the delay.
class _FixedIqamaTile extends StatelessWidget {
  const _FixedIqamaTile({
    required this.value,
    required this.onChanged,
    this.label,
  });

  final int? value;
  final String? label;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s, settings = context.settings;
    final v = value;
    String clock(int m) {
      final h = m ~/ 60, min = (m % 60).toString().padLeft(2, '0');
      if (settings.use24h) return '${h.toString().padLeft(2, '0')}:$min';
      return '${h % 12 == 0 ? 12 : h % 12}:$min ${amPm(settings.lang, h)}';
    }

    return ListTile(
      dense: true,
      title: Text(label ?? s.fixedIqama),
      subtitle: Text(v == null ? s.fixedIqamaOff : s.fixedIqamaHelp),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            v == null ? s.off : clock(v),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (v != null)
            IconButton(
              tooltip: s.clear,
              icon: const Icon(Icons.close),
              onPressed: () => onChanged(null),
            ),
        ],
      ),
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: v == null
              ? const TimeOfDay(hour: 13, minute: 0)
              : TimeOfDay(hour: v ~/ 60, minute: v % 60),
        );
        if (t != null) onChanged(t.hour * 60 + t.minute);
      },
    );
  }
}

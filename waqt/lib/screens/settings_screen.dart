import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../core/prayer_calc.dart';
import 'alerts_screen.dart';
import 'place_screen.dart';
import 'timetable_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(s.location),
            subtitle: Text(
              '${settings.place.label(s.ml)} · '
              '${settings.place.latitude.toStringAsFixed(4)}, '
              '${settings.place.longitude.toStringAsFixed(4)}',
            ),
            onTap: () => push(const PlaceScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(s.alerts),
            onTap: () => push(const AlertsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(s.timetable),
            subtitle: Text(
              settings.timetable != null
                  ? settings.timetable!.name
                  : s.noTimetable,
            ),
            onTap: () => push(const TimetableScreen()),
          ),
          const Divider(),
          _Header(s.calculation),
          ListTile(
            title: Text(s.method),
            subtitle: Text(settings.method.name),
            onTap: () => _pick<CalcMethod>(
              context,
              s.method,
              CalcMethod.all,
              settings.method,
              (m) => m.name,
              (m) => settings.update((x) => x.method = m),
            ),
          ),
          ListTile(
            title: Text(s.asrMethod),
            subtitle: Text(s.asrName(settings.asr)),
            onTap: () => _pick<AsrMethod>(
              context,
              s.asrMethod,
              AsrMethod.values,
              settings.asr,
              s.asrName,
              (a) => settings.update((x) => x.asr = a),
            ),
          ),
          ListTile(
            title: Text(s.highLatitude),
            subtitle: Text(s.highLatName(settings.highLatitude)),
            onTap: () => _pick<HighLatitudeRule>(
              context,
              s.highLatitude,
              HighLatitudeRule.values,
              settings.highLatitude,
              s.highLatName,
              (r) => settings.update((x) => x.highLatitude = r),
            ),
          ),
          ExpansionTile(
            title: Text(s.adjustments),
            subtitle: Text(s.adjustmentsHelp),
            children: [
              for (final p in Prayer.values)
                _Stepper(
                  label: s.prayer(p),
                  value: settings.adjustments[p] ?? 0,
                  min: -30,
                  max: 30,
                  signed: true,
                  onChanged: (v) => settings.update(
                    (x) =>
                        x.adjustments = {...x.adjustments, p: v}
                          ..removeWhere((_, v) => v == 0),
                  ),
                ),
              _Stepper(
                label: s.imsakBeforeFajr,
                value: settings.imsakMinutes,
                min: 0,
                max: 30,
                onChanged: (v) => settings.update((x) => x.imsakMinutes = v),
              ),
              _Stepper(
                label: s.ishraqAfterSunrise,
                value: settings.ishraqMinutes,
                min: 5,
                max: 40,
                onChanged: (v) => settings.update((x) => x.ishraqMinutes = v),
              ),
              TextButton(
                onPressed: () => settings.update((x) {
                  x.adjustments = {};
                  x.imsakMinutes = 10;
                  x.ishraqMinutes = 15;
                }),
                child: Text(s.reset),
              ),
            ],
          ),
          _Stepper(
            label: s.hijriAdjust,
            help: s.hijriAdjustHelp,
            value: settings.hijriAdjust,
            min: -2,
            max: 2,
            signed: true,
            unit:
                '${settings.hijriAdjust > 0
                    ? '+'
                    : settings.hijriAdjust < 0
                    ? '−'
                    : ''}'
                '${s.days(settings.hijriAdjust.abs())}',
            onChanged: (v) => settings.update((x) => x.hijriAdjust = v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(s.language),
            subtitle: Text(settings.lang.nativeName),
            onTap: () => _pick<Lang>(
              context,
              s.language,
              Lang.values,
              settings.lang,
              (l) => l.nativeName,
              (l) => settings.update((x) => x.lang = l),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(s.theme),
            onTap: () => _pick<ThemeMode>(
              context,
              s.theme,
              ThemeMode.values,
              settings.themeMode,
              (m) => switch (m) {
                ThemeMode.system => s.themeSystem,
                ThemeMode.light => s.themeLight,
                ThemeMode.dark => s.themeDark,
              },
              (m) => settings.update((x) => x.themeMode = m),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.schedule),
            title: Text(s.use24h),
            value: settings.use24h,
            onChanged: (v) => settings.update((x) => x.use24h = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.nights_stay_outlined),
            title: Text(s.showExtras),
            value: settings.showExtras,
            onChanged: (v) => settings.update((x) => x.showExtras = v),
          ),
          const Divider(),
          AboutListTile(
            icon: const Icon(Icons.info_outline),
            applicationName: s.appTitle,
            applicationVersion: '1.0.0',
            aboutBoxChildren: [Text(s.privacyNote)],
            child: Text(s.about),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Future<void> _pick<T>(
    BuildContext context,
    String title,
    List<T> values,
    T current,
    String Function(T) label,
    void Function(T) onPick,
  ) async {
    final v = await showDialog<T>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(title),
        children: [
          RadioGroup<T>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(context, v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final x in values)
                  RadioListTile<T>(value: x, title: Text(label(x))),
              ],
            ),
          ),
        ],
      ),
    );
    if (v != null) onPick(v);
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

/// A label with − value + buttons.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.signed = false,
    this.help,
    this.unit,
  });

  final String label;
  final String? help;

  /// Replaces the plain number as the shown value (e.g. "+1 day").
  final String? unit;
  final int value, min, max;
  final bool signed;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = unit ?? (signed && value > 0 ? '+$value' : '$value');
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 36),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
    // With help text, the controls go on their own line so the text keeps
    // the full width (long Malayalam explanations).
    if (help == null) {
      return ListTile(title: Text(label), trailing: controls);
    }
    return ListTile(
      title: Text(label),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(help!),
          Align(alignment: AlignmentDirectional.centerEnd, child: controls),
        ],
      ),
    );
  }
}

/// Shared with the alerts screen.
class MinutesStepper extends StatelessWidget {
  const MinutesStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.zeroLabel,
  });

  final String label;
  final int value, min, max;
  final String? zeroLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              value == 0 && zeroLabel != null
                  ? zeroLabel!
                  : '$value ${s.minutesShort}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

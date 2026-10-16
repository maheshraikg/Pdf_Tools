import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../core/prayer_calc.dart';
import '../ui/widgets.dart';
import 'alerts_screen.dart';
import 'display_settings_screen.dart';
import 'place_screen.dart';
import 'timetable_screen.dart';
import 'tracker_screen.dart';

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
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Section(
            children: [
              ListTile(
                leading: const IconBadge(Icons.place),
                title: Text(s.location),
                subtitle: Text(
                  '${settings.place.label(s.ml)} · '
                  '${settings.place.latitude.toStringAsFixed(4)}, '
                  '${settings.place.longitude.toStringAsFixed(4)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const PlaceScreen()),
              ),
              ListTile(
                leading: const IconBadge(Icons.notifications_active),
                title: Text(s.alerts),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const AlertsScreen()),
              ),
              ListTile(
                leading: const IconBadge(Icons.table_chart),
                title: Text(s.timetable),
                subtitle: Text(
                  settings.timetable != null
                      ? settings.timetable!.name
                      : s.noTimetable,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const TimetableScreen()),
              ),
              ListTile(
                leading: const IconBadge(Icons.task_alt),
                title: Text(s.tracker),
                subtitle: Text(
                  s.prayedOf(
                    settings.log.count(settings.today),
                    Prayer.fard.length,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const TrackerScreen()),
              ),
              ListTile(
                leading: const IconBadge(Icons.tv),
                title: Text(s.displayMode),
                subtitle: Text(
                  s.displayPagesSummary(settings.displayPageCount),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => push(const DisplaySettingsScreen()),
              ),
            ],
          ),
          Section(
            title: s.calculation,
            children: [
              ListTile(
                leading: const IconBadge(Icons.calculate_outlined),
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
                leading: const IconBadge(Icons.wb_sunny_outlined),
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
                leading: const IconBadge(Icons.public),
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
                leading: const IconBadge(Icons.tune),
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
                    onChanged: (v) =>
                        settings.update((x) => x.imsakMinutes = v),
                  ),
                  _Stepper(
                    label: s.ishraqAfterSunrise,
                    value: settings.ishraqMinutes,
                    min: 5,
                    max: 40,
                    onChanged: (v) =>
                        settings.update((x) => x.ishraqMinutes = v),
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
                icon: Icons.event_outlined,
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
            ],
          ),
          Section(
            title: s.theme,
            children: [
              ListTile(
                leading: const IconBadge(Icons.translate),
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
                leading: const IconBadge(Icons.dark_mode_outlined),
                title: Text(s.theme),
                subtitle: Text(switch (settings.themeMode) {
                  ThemeMode.system => s.themeSystem,
                  ThemeMode.light => s.themeLight,
                  ThemeMode.dark => s.themeDark,
                }),
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
                secondary: const IconBadge(Icons.schedule),
                title: Text(s.use24h),
                value: settings.use24h,
                onChanged: (v) => settings.update((x) => x.use24h = v),
              ),
              SwitchListTile(
                secondary: const IconBadge(Icons.nights_stay_outlined),
                title: Text(s.showExtras),
                value: settings.showExtras,
                onChanged: (v) => settings.update((x) => x.showExtras = v),
              ),
            ],
          ),
          Section(
            children: [
              AboutListTile(
                icon: const IconBadge(Icons.info_outline),
                applicationName: s.appTitle,
                applicationVersion: '1.0.0',
                aboutBoxChildren: [Text(s.privacyNote)],
                child: Text(s.about),
              ),
            ],
          ),
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
    this.icon,
  });

  final IconData? icon;
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
    final leading = icon == null ? null : IconBadge(icon!);
    if (help == null) {
      return ListTile(leading: leading, title: Text(label), trailing: controls);
    }
    return ListTile(
      leading: leading,
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
    this.unit,
    this.step = 1,
  });

  final String label;
  final int value, min, max, step;
  final String? zeroLabel;

  /// Unit after the number (default: minutes).
  final String? unit;
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
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
          ),
          SizedBox(
            width: 64,
            child: Text(
              value == 0 && zeroLabel != null
                  ? zeroLabel!
                  : '$value ${unit ?? s.minutesShort}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
          ),
        ],
      ),
    );
  }
}

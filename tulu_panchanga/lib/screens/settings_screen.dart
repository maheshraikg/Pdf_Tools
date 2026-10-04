import 'package:flutter/material.dart';

import '../app/background.dart';
import '../app/scope.dart';
import '../panchanga/names.dart';
import '../panchanga/place.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s, settings = context.settings, lang = context.lang;
    final t = Theme.of(context);
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: LipiText(
        text,
        style: t.textTheme.titleSmall?.copyWith(color: t.colorScheme.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: LipiText(s.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          header(s.language),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<Lang>(
              segments: [
                for (final l in Lang.values)
                  ButtonSegment(value: l, label: Text(l.label)),
              ],
              selected: {settings.lang},
              onSelectionChanged: (v) =>
                  settings.update((x) => x.lang = v.first),
            ),
          ),
          SwitchListTile(
            title: LipiText(s.tuluLipi),
            subtitle: Text(s.tuluLipiHint),
            value: settings.tuluLipi,
            onChanged: (v) => settings.update((x) => x.tuluLipi = v),
          ),
          header(s.location),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: LipiText(settings.place.name.of(lang)),
            subtitle: Text(
              '${settings.place.lat.toStringAsFixed(4)}°, '
              '${settings.place.lon.toStringAsFixed(4)}° · '
              'UTC${_offset(settings.place.fixedOffsetMinutes)}',
            ),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => _pickPlace(context),
          ),
          header(s.conventions),
          _radio<SunriseConvention>(
            context,
            s.sunriseRule,
            settings.config.sunrise,
            {
              SunriseConvention.upperLimb: s.upperLimb,
              SunriseConvention.discCentre: s.discCentre,
            },
            (v) => settings.update(
              (x) => x.config = x.config.copyWith(sunrise: v),
            ),
          ),
          _radio<SolarMonthRule>(
            context,
            s.monthRule,
            settings.config.solarMonthRule,
            {
              SolarMonthRule.sunset: s.ruleSunset,
              SolarMonthRule.aparahna: s.ruleAparahna,
              SolarMonthRule.nextDay: s.ruleNextDay,
            },
            (v) => settings.update(
              (x) => x.config = x.config.copyWith(solarMonthRule: v),
            ),
          ),
          _radio<TiePreference>(
            context,
            s.tieRule,
            settings.config.tiePreference,
            {
              TiePreference.first: s.tieFirst,
              TiePreference.second: s.tieSecond,
            },
            (v) => settings.update(
              (x) => x.config = x.config.copyWith(tiePreference: v),
            ),
          ),
          header(s.notifications),
          SwitchListTile(
            title: LipiText(s.dailyNotification),
            value: settings.dailyNotification,
            onChanged: (v) async {
              if (v) await Background.requestPermission();
              await settings.update((x) => x.dailyNotification = v);
            },
          ),
          ListTile(
            enabled: settings.dailyNotification,
            leading: const Icon(Icons.schedule),
            title: LipiText(s.notifyAt),
            trailing: Text(
              '${settings.notifyHour.toString().padLeft(2, '0')}:'
              '${settings.notifyMinute.toString().padLeft(2, '0')}',
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.notifyHour,
                  minute: settings.notifyMinute,
                ),
              );
              if (picked != null) {
                await settings.update((x) {
                  x.notifyHour = picked.hour;
                  x.notifyMinute = picked.minute;
                });
              }
            },
          ),
          SwitchListTile(
            title: LipiText(s.festivalReminder),
            value: settings.festivalReminder,
            onChanged: (v) async {
              if (v) await Background.requestPermission();
              await settings.update((x) => x.festivalReminder = v);
            },
          ),
          SwitchListTile(
            title: LipiText(s.rahuReminder),
            value: settings.rahuReminder,
            onChanged: (v) async {
              if (v) await Background.requestPermission();
              await settings.update((x) => x.rahuReminder = v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.widgets_outlined),
            title: LipiText(s.widgetHint),
          ),
          header(s.theme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(s.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(s.themeLight),
                ),
                ButtonSegment(value: ThemeMode.dark, label: Text(s.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) =>
                  settings.update((x) => x.themeMode = v.first),
            ),
          ),
          header(s.about),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LipiText(s.aboutText),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Fonts: Baloo Tamma 2 and Mallige (Tulu-Tigalari), SIL OFL 1.1.',
              style: t.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static String _offset(int minutes) {
    final sign = minutes < 0 ? '−' : '+';
    final m = minutes.abs();
    return '$sign${m ~/ 60}:${(m % 60).toString().padLeft(2, '0')}';
  }

  Widget _radio<T>(
    BuildContext context,
    String title,
    T value,
    Map<T, String> options,
    ValueChanged<T> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: LipiText(
              title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          RadioGroup<T>(
            groupValue: value,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: Column(
              children: [
                for (final e in options.entries)
                  RadioListTile<T>(
                    dense: true,
                    value: e.key,
                    title: LipiText(e.value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPlace(BuildContext context) async {
    final settings = context.settings, lang = context.lang, s = context.s;
    final picked = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (ctx, controller) => ListView(
          controller: controller,
          children: [
            for (final p in presetPlaces)
              ListTile(
                leading: Icon(
                  p == settings.place
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: LipiText(p.name.of(lang)),
                subtitle: Text(p.name.en),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: LipiText(s.customLocation),
              onTap: () => Navigator.pop(ctx, 'custom'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || picked == null) return;
    if (picked is Place) {
      await settings.update((x) => x.place = picked);
    } else {
      final custom = await showDialog<Place>(
        context: context,
        builder: (_) => const _CustomPlaceDialog(),
      );
      if (custom != null) await settings.update((x) => x.place = custom);
    }
  }
}

class _CustomPlaceDialog extends StatefulWidget {
  const _CustomPlaceDialog();

  @override
  State<_CustomPlaceDialog> createState() => _CustomPlaceDialogState();
}

class _CustomPlaceDialogState extends State<_CustomPlaceDialog> {
  final _name = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _off = TextEditingController(text: '5.5');
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _lat, _lon, _off]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    InputDecoration dec(String l) =>
        InputDecoration(labelText: l, errorText: null);
    return AlertDialog(
      title: LipiText(s.customLocation),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: dec(s.placeName)),
            TextField(
              controller: _lat,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: dec('${s.latitude} (12.91)'),
            ),
            TextField(
              controller: _lon,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: dec('${s.longitude} (74.86)'),
            ),
            TextField(
              controller: _off,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: dec('${s.timeZone}: UTC + hours (5.5)'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final lat = double.tryParse(_lat.text.trim());
            final lon = double.tryParse(_lon.text.trim());
            final off = double.tryParse(_off.text.trim());
            if (lat == null ||
                lon == null ||
                off == null ||
                lat.abs() > 60 ||
                lon.abs() > 180 ||
                off.abs() > 14) {
              setState(
                () => _error = '|lat| ≤ 60, |lon| ≤ 180, |UTC offset| ≤ 14',
              );
              return;
            }
            final name = _name.text.trim().isEmpty
                ? 'Custom'
                : _name.text.trim();
            Navigator.pop(
              context,
              Place(
                id: 'custom',
                name: Name(name, name),
                lat: lat,
                lon: lon,
                tz: 'custom',
                fixedOffsetMinutes: (off * 60).round(),
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

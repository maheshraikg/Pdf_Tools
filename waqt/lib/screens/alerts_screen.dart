import 'package:file_picker/file_picker.dart';
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
  bool _fullScreenOk = true;

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
    final fs = await Native.canFullScreen();
    if (mounted) {
      setState(() {
        _dnd = v || !Native.supported;
        _fullScreenOk = fs;
      });
    }
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
          _soundSection(context, c, set),
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
            title: s.specialOccasions,
            children: [
              SwitchListTile(
                secondary: const IconBadge(Icons.nights_stay_outlined),
                title: Text(s.specialTitle(SpecialEvent.taraweeh)),
                subtitle: Text(s.taraweehHelp),
                value: c.taraweehAlert,
                onChanged: (v) => set(c.copyWith(taraweehAlert: v)),
              ),
              if (c.taraweehAlert)
                MinutesStepper(
                  label: s.taraweehAfterIsha,
                  value: c.taraweehMinutesAfterIsha,
                  min: 0,
                  max: 60,
                  onChanged: (v) =>
                      set(c.copyWith(taraweehMinutesAfterIsha: v)),
                ),
              SwitchListTile(
                secondary: const IconBadge(Icons.celebration_outlined),
                title: Text(s.eidAlert),
                subtitle: Text(s.eidHelp),
                value: c.eidAlert,
                onChanged: (v) => set(c.copyWith(eidAlert: v)),
              ),
              if (c.eidAlert) ...[
                _TimeTile(
                  label: s.specialTitle(SpecialEvent.eidAlFitr),
                  value: c.eidFitrTime,
                  onChanged: (v) => set(c.copyWith(eidFitrTime: v)),
                ),
                _TimeTile(
                  label: s.specialTitle(SpecialEvent.eidAlAdha),
                  value: c.eidAdhaTime,
                  onChanged: (v) => set(c.copyWith(eidAdhaTime: v)),
                ),
              ],
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

extension on _AlertsScreenState {
  Widget _soundSection(
    BuildContext context,
    AlertConfig c,
    void Function(AlertConfig) set,
  ) {
    final s = context.s, settings = context.settings;

    Widget preview(SoundChoice choice, Prayer p) {
      final sound = choice.playerSound;
      if (sound == null || !Native.supported) return const SizedBox.shrink();
      return IconButton(
        tooltip: s.playSound,
        icon: const Icon(Icons.play_circle_outline),
        onPressed: () => Native.playSound(
          sound,
          s.azanTitle(p, false),
          settings.place.label(s.ml),
        ),
      );
    }

    return Section(
      title: s.azanSoundTitle,
      children: [
        ListTile(
          leading: const IconBadge(Icons.music_note_outlined),
          title: Text(s.azanSoundTitle),
          subtitle: Text(s.soundName(c.azanSound)),
          trailing: preview(c.azanSound, Prayer.dhuhr),
          onTap: () async {
            final v = await _pickSound(context, 'azan', c.azanSound, false);
            if (v != null) set(c.copyWith(azanSound: v.$1));
          },
        ),
        ListTile(
          leading: IconBadge(prayerIcon(Prayer.fajr)),
          title: Text(s.fajrSoundTitle),
          subtitle: Text(
            c.fajrSound == null ? s.sameAsOthers : s.soundName(c.fajrSound!),
          ),
          trailing: preview(c.soundFor(Prayer.fajr), Prayer.fajr),
          onTap: () async {
            final v = await _pickSound(
              context,
              'fajr',
              c.fajrSound ?? c.azanSound,
              true,
              same: c.fajrSound == null,
            );
            if (v != null) set(c.copyWith(fajrSound: v.$1));
          },
        ),
        ...[
          SwitchListTile(
            secondary: const IconBadge(Icons.fullscreen),
            title: Text(s.fullScreenAzan),
            subtitle: Text(s.fullScreenAzanHelp),
            value: c.fullScreen,
            onChanged: (v) => set(c.copyWith(fullScreen: v)),
          ),
          if (c.fullScreen && !_fullScreenOk)
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(s.fullScreenPermission),
              trailing: TextButton(
                onPressed: Native.openFullScreenSettings,
                child: Text(s.grant),
              ),
            ),
          SwitchListTile(
            secondary: const IconBadge(Icons.vibration),
            title: Text(s.vibrate),
            value: c.vibrate,
            onChanged: (v) => set(c.copyWith(vibrate: v)),
          ),
          SwitchListTile(
            secondary: const IconBadge(Icons.notifications_paused_outlined),
            title: Text(s.playWhenSilent),
            subtitle: Text(s.playWhenSilentHelp),
            value: c.playWhenSilent,
            onChanged: (v) => set(c.copyWith(playWhenSilent: v)),
          ),
        ],
      ],
    );
  }

  /// Sound picker; returns (choice, null = "same as other prayers").
  Future<(SoundChoice?,)?> _pickSound(
    BuildContext context,
    String slot,
    SoundChoice current,
    bool allowSame, {
    bool same = false,
  }) async {
    final s = context.s;
    final messenger = ScaffoldMessenger.of(context);
    final scheme = Theme.of(context).colorScheme;
    Widget tick(bool on) => on
        ? Icon(Icons.check_circle, color: scheme.primary)
        : const SizedBox(width: 24);
    final picked = await showDialog<Object>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(allowSame ? s.fajrSoundTitle : s.azanSoundTitle),
        children: [
          if (allowSame)
            ListTile(
              title: Text(s.sameAsOthers),
              trailing: tick(same),
              onTap: () => Navigator.pop(context, 'same'),
            ),
          for (final o in AzanSound.values)
            ListTile(
              title: Text(s.soundKindName(o)),
              subtitle: o == AzanSound.custom
                  ? Text(
                      current.sound == AzanSound.custom &&
                              current.fileName != null
                          ? current.fileName!
                          : s.customSoundHelp,
                    )
                  : o == AzanSound.system
                  ? Text(s.systemSoundHelp)
                  : null,
              trailing: tick(!same && current.sound == o),
              onTap: () => Navigator.pop(context, o),
            ),
        ],
      ),
    );
    if (picked == null) return null;
    if (picked == 'same') return (null,);
    final kind = picked as AzanSound;
    if (kind != AzanSound.custom) return (SoundChoice(kind),);

    final f = await FilePicker.pickFile(type: FileType.audio);
    if (f == null) return null;
    try {
      final bytes = await f.readAsBytes();
      final dot = f.name.lastIndexOf('.');
      final ext = dot < 0 ? 'mp3' : f.name.substring(dot + 1);
      final path = await Native.saveSound(slot, ext, bytes);
      if (path == null) throw StateError('not saved');
      return (SoundChoice(AzanSound.custom, path: path, fileName: f.name),);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.soundError)));
      return null;
    }
  }
}

/// A clock time setting (tap to change).
class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final h = value ~/ 60, m = (value % 60).toString().padLeft(2, '0');
    final text = settings.use24h
        ? '${h.toString().padLeft(2, '0')}:$m'
        : '${h % 12 == 0 ? 12 : h % 12}:$m ${amPm(settings.lang, h)}';
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: h, minute: value % 60),
        );
        if (t != null) onChanged(t.hour * 60 + t.minute);
      },
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

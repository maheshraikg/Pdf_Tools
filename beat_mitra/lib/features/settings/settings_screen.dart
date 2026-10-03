import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/app_lock.dart';
import '../../core/settings.dart';
import '../beat/beats_screen.dart';
import '../common/widgets.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'map_screen.dart';
import 'pin_pad.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final s = context.watch<AppSettings>();
    final t = Theme.of(context).textTheme;

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(text, style: t.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );

    Future<void> choose<T>(String title, T current, List<(T, String)> options, ValueChanged<T> onPick) async {
      final r = await showDialog<T>(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(title),
          children: [
            RadioGroup<T>(
              groupValue: current,
              onChanged: (x) => Navigator.pop(c, x),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (v, label) in options)
                    RadioListTile<T>(
                      value: v,
                      title: Text(label, style: const TextStyle(fontSize: 18)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
      if (r != null) onPick(r);
    }

    final langName = switch (s.localeCode) {
      'kn' => 'ಕನ್ನಡ',
      'en' => 'English',
      'hi' => 'हिन्दी',
      _ => l.deviceLanguage,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l.beats),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BeatsScreen())),
          ),
          header(l.display),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.language),
            subtitle: Text(langName),
            onTap: () => choose<String?>(l.language, s.localeCode, [
              (null, l.deviceLanguage),
              ('kn', 'ಕನ್ನಡ'),
              ('en', 'English'),
              ('hi', 'हिन्दी'),
            ], (v) => s.localeCode = v),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: Text(l.theme),
            subtitle: Text(switch (s.themeMode) {
              ThemeMode.light => l.themeLight,
              ThemeMode.dark => l.themeDark,
              _ => l.themeSystem,
            }),
            onTap: () => choose<ThemeMode>(l.theme, s.themeMode, [
              (ThemeMode.system, l.themeSystem),
              (ThemeMode.light, l.themeLight),
              (ThemeMode.dark, l.themeDark),
            ], (v) => s.themeMode = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny),
            title: Text(l.sunlightMode),
            subtitle: Text(l.sunlightModeSub),
            value: s.sunlight,
            onChanged: (v) => s.sunlight = v,
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(l.textSize),
            subtitle: Text(
              s.textScale >= 1.3
                  ? l.textXL
                  : s.textScale >= 1.15
                  ? l.textLarge
                  : l.textNormal,
            ),
            onTap: () => choose<double>(l.textSize, s.textScale, [
              (1.0, l.textNormal),
              (1.15, l.textLarge),
              (1.3, l.textXL),
            ], (v) => s.textScale = v),
          ),
          header(l.security),
          ListTile(leading: const Icon(Icons.pin), title: Text(l.changePin), onTap: () => _changePin(context)),
          FutureBuilder<bool>(
            future: context.read<AppLock>().canUseBiometric(),
            builder: (c, snap) => SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l.useFingerprint),
              subtitle: snap.data == false ? Text(l.biometricUnavailable) : null,
              value: s.biometric && snap.data == true,
              onChanged: snap.data == true ? (v) => s.biometric = v : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(l.autoLock),
            subtitle: Text(s.lockTimeoutMin == 0 ? l.lockImmediately : l.lockAfterMin(s.lockTimeoutMin)),
            onTap: () => choose<int>(l.autoLock, s.lockTimeoutMin, [
              (0, l.lockImmediately),
              for (final m in [1, 2, 5, 15]) (m, l.lockAfterMin(m)),
            ], (v) => s.lockTimeoutMin = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.screenshot_monitor),
            title: Text(l.blockScreenshots),
            subtitle: Text(l.blockScreenshotsSub),
            value: s.blockScreenshots,
            onChanged: (v) => s.blockScreenshots = v,
          ),
          header(l.gpsAndRoute),
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: Text(l.gpsThreshold),
            subtitle: Text('${s.gpsThresholdM} m'),
            onTap: () => choose<int>(l.gpsThreshold, s.gpsThresholdM, [
              for (final m in [10, 20, 30, 50]) (m, '$m m'),
            ], (v) => s.gpsThresholdM = v),
          ),
          ListTile(
            leading: const Icon(Icons.flag_circle_outlined),
            title: Text(l.startPoint),
            subtitle: Text(s.startMode == 'office' && s.officeLat != null ? l.startOffice : l.startCurrent),
            onTap: () => _startPoint(context, s),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(l.vibrateNear),
            value: s.vibrateNear,
            onChanged: (v) => s.vibrateNear = v,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.record_voice_over),
            title: Text(l.ttsSetting),
            subtitle: Text(l.ttsSettingSub),
            value: s.tts,
            onChanged: (v) => s.tts = v,
          ),
          header(l.dataSection),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(l.historyRetention),
            subtitle: Text(l.daysCount(s.historyDays)),
            onTap: () => choose<int>(
              l.historyRetention,
              s.historyDays,
              [
                for (final d in [30, 60, 90, 180, 365]) (d, l.daysCount(d)),
              ],
              (v) async {
                s.historyDays = v;
                final n = await context.services.articles.deleteOlderThan(v);
                if (context.mounted) {
                  context.toast(l.oldDeleted(n));
                  context.app.touch();
                }
              },
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.public),
            title: Text(l.onlineMap),
            subtitle: Text(mapAvailableInBuild ? l.onlineMapSub : l.mapNotInBuild),
            value: s.onlineMap && mapAvailableInBuild,
            onChanged: !mapAvailableInBuild
                ? null
                : (v) async {
                    if (v && !await confirm(context, l.onlineMap, l.onlineMapConfirm)) return;
                    s.onlineMap = v;
                  },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            title: Text(l.deleteAll, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _deleteAll(context),
          ),
          header(l.helpAndAbout),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l.help),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.about),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
        ],
      ),
    );
  }

  Future<void> _startPoint(BuildContext context, AppSettings s) async {
    final l = context.l;
    final r = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(l.startPoint),
        children: [
          SimpleDialogOption(
            padding: const EdgeInsets.all(16),
            onPressed: () => Navigator.pop(c, 'current'),
            child: Text(l.startCurrent, style: const TextStyle(fontSize: 18)),
          ),
          SimpleDialogOption(
            padding: const EdgeInsets.all(16),
            onPressed: () => Navigator.pop(c, 'office'),
            child: Text(l.setOfficeHere, style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
    if (r == 'current') {
      s.startMode = 'current';
    } else if (r == 'office' && context.mounted) {
      final fix = await context.services.location.current();
      if (fix == null) {
        if (context.mounted) context.toast(l.gpsWaiting);
        return;
      }
      await s.setOffice(fix.point.lat, fix.point.lng);
      s.startMode = 'office';
      if (context.mounted) context.toast(l.saved);
    }
  }

  Future<void> _changePin(BuildContext context) async {
    final l = context.l;
    final lock = context.read<AppLock>();
    String? first;
    String? error;
    var stage = 0; // 0 = old, 1 = new, 2 = confirm
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => AlertDialog(
          title: Text(switch (stage) {
            0 => l.enterOldPin,
            1 => l.createPin,
            _ => l.confirmPin,
          }),
          content: SingleChildScrollView(
            child: PinPad(
              key: ValueKey(stage),
              error: error,
              onDone: (pin) async {
                if (stage == 0) {
                  if (!await lock.checkPin(pin)) {
                    setD(() => error = l.wrongPin);
                    return false;
                  }
                  setD(() {
                    stage = 1;
                    error = null;
                  });
                } else if (stage == 1) {
                  first = pin;
                  setD(() => stage = 2);
                } else if (pin != first) {
                  setD(() {
                    stage = 1;
                    error = l.pinMismatch;
                  });
                  return false;
                } else {
                  await lock.setPin(pin);
                  if (c.mounted) Navigator.pop(c);
                  if (context.mounted) context.toast(l.pinChanged);
                }
                return true;
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAll(BuildContext context) async {
    final l = context.l;
    if (!await confirm(context, l.deleteAll, l.deleteAllConfirm1, danger: true, ok: l.next)) return;
    if (!context.mounted) return;
    final typed = await askText(context, l.deleteAll, label: l.deleteAllConfirm2);
    if (typed?.trim().toUpperCase() != 'DELETE' || !context.mounted) {
      if (context.mounted && typed != null) context.toast(l.notDeleted);
      return;
    }
    final services = context.read<AppServices>();
    final app = context.read<AppState>();
    final lock = context.read<AppLock>();
    final settings = context.read<AppSettings>();
    for (final f in await services.places.allPhotoFiles()) {
      await services.photos.delete(f);
    }
    await services.photos.deleteAll();
    await services.database.wipe();
    await settings.clearAll();
    await lock.removePin();
    await app.reloadBeats();
    await app.rebuildIndex();
    if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }
}

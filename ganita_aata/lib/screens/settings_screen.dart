import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../data/languages.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/l10n_ext.dart';
import '../widgets/language_grid.dart';
import 'pin_screen.dart';
import 'splash_screen.dart';

/// Parent settings (behind the PIN).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    final p = app.active;
    TextStyle big = const TextStyle(fontSize: 20, fontWeight: FontWeight.w700);
    return Theme(
      data: buildParentTheme(),
      child: Scaffold(
        appBar: AppBar(title: Text(l.settings)),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            ListTile(
              key: const ValueKey('lang_toggle'),
              leading: const Icon(Icons.translate_rounded, size: 30),
              title: Text(l.language, style: big),
              subtitle: Text(Languages.byCode(app.lang).nativeName, style: big.copyWith(color: AppColors.secondary)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 30),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (c) => SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.language, style: display(24)),
                        const SizedBox(height: 12),
                        LanguageGrid(onPicked: () => Navigator.pop(c)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SwitchListTile(
              key: const ValueKey('sound_switch'),
              secondary: const Icon(Icons.volume_up_rounded, size: 30),
              title: Text(l.sound, style: big),
              value: app.soundOn,
              onChanged: app.setSound,
            ),
            SwitchListTile(
              key: const ValueKey('music_switch'),
              secondary: const Icon(Icons.music_note_rounded, size: 30),
              title: Text(l.music, style: big),
              value: app.musicOn,
              onChanged: app.setMusic,
            ),
            SwitchListTile(
              key: const ValueKey('reminder_switch'),
              secondary: const Icon(Icons.notifications_active_rounded, size: 30),
              title: Text(l.dailyReminder, style: big),
              subtitle: Text(l.reminderBody),
              value: app.reminderOn,
              onChanged: (on) async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await app.setReminder(on);
                if (!ok) messenger.showSnackBar(SnackBar(content: Text(l.notificationsBlocked)));
              },
            ),
            ListTile(
              key: const ValueKey('reminder_time'),
              enabled: app.reminderOn,
              leading: const Icon(Icons.schedule_rounded, size: 30),
              title: Text(l.reminderTime, style: big),
              trailing: Text(app.reminderTime.format(context), style: big.copyWith(color: AppColors.secondary)),
              onTap: () async {
                final t = await showTimePicker(context: context, initialTime: app.reminderTime);
                if (t != null) await app.setReminder(true, t);
              },
            ),
            const Divider(),
            ListTile(
              key: const ValueKey('change_pin'),
              leading: const Icon(Icons.password_rounded, size: 30),
              title: Text(l.changePin, style: big),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (await changeParentPin(context)) messenger.showSnackBar(SnackBar(content: Text(l.pinChanged)));
              },
            ),
            if (p != null) ...[
              ListTile(
                key: const ValueKey('reset_progress'),
                leading: const Icon(Icons.restart_alt_rounded, size: 30),
                title: Text(l.resetProgress, style: big),
                subtitle: Text('${l.child}: ${p.name}'),
                onTap: () => _confirm(
                  context,
                  title: l.resetProgress,
                  body: l.resetProgressBody(p.name),
                  action: l.reset,
                  onYes: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await app.resetProgress();
                    messenger.showSnackBar(SnackBar(content: Text(l.progressReset)));
                  },
                ),
              ),
              ListTile(
                key: const ValueKey('remove_child'),
                leading: const Icon(Icons.person_remove_rounded, size: 30),
                title: Text(l.removeChild, style: big),
                subtitle: Text('${l.child}: ${p.name}'),
                onTap: () => _confirm(
                  context,
                  title: l.removeChild,
                  body: l.removeChildBody(p.name),
                  action: l.remove,
                  onYes: () async {
                    final nav = Navigator.of(context);
                    await app.deleteProfile(p);
                    // Back to the start: Home, or profile setup if no child is left.
                    nav.pushAndRemoveUntil(
                      MaterialPageRoute<void>(builder: (_) => const SplashScreen(delay: Duration.zero)),
                      (_) => false,
                    );
                  },
                ),
              ),
            ],
            const Divider(),
            ListTile(
              key: const ValueKey('about'),
              leading: const Icon(Icons.info_rounded, size: 30),
              title: Text(l.about, style: big),
              onTap: () => _about(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
    required Future<void> Function() onYes,
  }) async {
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(
            key: const ValueKey('confirm_yes'),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB35C00)),
            onPressed: () => Navigator.pop(c, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (yes == true) await onYes();
  }

  void _about(BuildContext context) {
    final l = context.l10n;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.appTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.version(appVersion), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(l.aboutBody),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => showLicensePage(context: c, applicationName: l.appTitle, applicationVersion: appVersion),
            child: Text(l.licenses),
          ),
          FilledButton(onPressed: () => Navigator.pop(c), child: Text(l.close)),
        ],
      ),
    );
  }
}

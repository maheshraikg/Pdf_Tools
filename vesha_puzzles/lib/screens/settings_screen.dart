import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../monetization/flags.dart';
import '../packs/content.dart';
import 'credits_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final st = app.settings;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(s.language),
            leading: const Icon(Icons.translate),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<Lang>(
              segments: [
                for (final l in Lang.values)
                  ButtonSegment(value: l, label: Text(l.nativeName)),
              ],
              selected: {st.lang},
              onSelectionChanged: (v) =>
                  app.updateSettings((x) => x.lang = v.first),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(s.soundEffects),
            value: st.sfx,
            onChanged: (v) => app.updateSettings((x) => x.sfx = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.music_note_outlined),
            title: Text(s.music),
            value: st.music,
            onChanged: (v) => app.updateSettings((x) => x.music = v),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(s.volume),
            subtitle: Slider(
              value: st.volume,
              onChanged: (v) => app.updateSettings((x) => x.volume = v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.vibration),
            title: Text(s.haptics),
            value: st.haptics,
            onChanged: (v) => app.updateSettings((x) => x.haptics = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: Text(s.ghostDefault),
            value: st.ghostByDefault,
            onChanged: (v) => app.updateSettings((x) => x.ghostByDefault = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.motion_photos_off_outlined),
            title: Text(s.reduceMotion),
            value: st.reduceMotion,
            onChanged: (v) => app.updateSettings((x) => x.reduceMotion = v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.chat_bubble_outline),
            title: Text(s.guideTips),
            value: st.guideTips,
            onChanged: (v) => app.updateSettings((x) => x.guideTips = v),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(s.theme),
          ),
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
              selected: {st.themeMode},
              onSelectionChanged: (v) =>
                  app.updateSettings((x) => x.themeMode = v.first),
            ),
          ),
          const Divider(height: 32),
          if (kEnableIap)
            ListTile(
              leading: const Icon(Icons.volunteer_activism_outlined),
              title: Text(s.supportArtists),
              subtitle: app.iap.available ? null : Text(s.supportUnavailable),
              onTap: app.iap.available ? () => app.iap.buySupporter() : null,
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(s.credits),
            subtitle: Text(s.privacy),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(s.resetProgress),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  content: Text(s.resetConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(s.delete),
                    ),
                  ],
                ),
              );
              if (ok == true) await app.resetProgress();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

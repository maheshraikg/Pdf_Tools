import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/strings.dart';
import '../../widgets/common.dart';

const String kAppVersion = '1.0.0';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s, settings = context.settings, rates = context.rates;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(title: Text(s.language)),
          RadioGroup<Lang>(
            groupValue: settings.lang,
            onChanged: (v) {
              if (v != null) settings.lang = v;
            },
            child: const Column(
              children: [
                RadioListTile(value: Lang.kn, title: Text('ಕನ್ನಡ')),
                RadioListTile(value: Lang.en, title: Text('English')),
              ],
            ),
          ),
          const Divider(),
          ListTile(title: Text(s.theme)),
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
              onSelectionChanged: (v) => settings.themeMode = v.first,
            ),
          ),
          const Divider(height: 32),
          ListTile(title: Text(s.about)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.appTitle} – ${s.tagline}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Note(s.notAffiliated, icon: Icons.gpp_maybe_outlined),
                Note(
                  '${s.rateVersion}: ${rates.version} · '
                  '${s.validFrom(dmy(rates.validFrom))}',
                  icon: Icons.percent,
                ),
                Note('${s.version} $kAppVersion', icon: Icons.tag),
                Note(s.estimateOnly),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(s.privacy),
            onTap: () => showDialog<void>(
              context: context,
              builder: (c) => AlertDialog(
                title: Text(s.privacy),
                content: Text(s.privacyText),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(c),
                    child: Text(s.ok),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

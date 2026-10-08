import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/constants.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = context.settings;
    final services = context.services;
    return ListenableBuilder(
      listenable: Listenable.merge([s, services]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(l.settings)),
        body: ListView(
          children: [
            ListTile(
              title: Text(l.language, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            RadioGroup<String>(
              groupValue: s.locale?.languageCode ?? '',
              onChanged: (v) => s.locale = v == null || v.isEmpty ? null : Locale(v),
              child: Column(
                children: [
                  RadioListTile<String>(value: '', title: Text(l.languageDevice)),
                  const RadioListTile<String>(value: 'kn', title: Text('ಕನ್ನಡ (Kannada)')),
                  const RadioListTile<String>(value: 'en', title: Text('English')),
                  const RadioListTile<String>(value: 'hi', title: Text('हिन्दी (Hindi)')),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(l.theme, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(value: ThemeMode.system, label: Text(l.themeSystem)),
                  ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
                  ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) => s.themeMode = v.first,
              ),
            ),
            const Divider(),
            SwitchListTile(
              value: s.ttsEnabled,
              onChanged: (v) => s.ttsEnabled = v,
              title: Text(l.ttsSetting),
              subtitle: Text(l.ttsSettingSub),
            ),
            SwitchListTile(value: s.hapticsEnabled, onChanged: (v) => s.hapticsEnabled = v, title: Text(l.hapticsSetting)),
            const Divider(),
            ListTile(
              title: Text(l.categories, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(l.categoriesSub),
              trailing: IconButton(
                tooltip: l.add,
                icon: const Icon(Icons.add),
                onPressed: () async {
                  final c = TextEditingController();
                  final name = await showDialog<String>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: Text(l.addCategory),
                      content: TextField(
                        controller: c,
                        autofocus: true,
                        decoration: InputDecoration(labelText: l.fCategory),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d), child: Text(l.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: Text(l.add)),
                      ],
                    ),
                  );
                  if (name != null && name.trim().isNotEmpty) {
                    await services.schemes.addCategory(name);
                    await services.reloadActive();
                  }
                },
              ),
            ),
            for (final c in services.categories)
              ListTile(
                dense: true,
                title: Text(categoryLabel(l, c)),
                trailing: kBuiltInCategories.contains(c)
                    ? null
                    : IconButton(
                        tooltip: l.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          await services.schemes.deleteCategory(c);
                          await services.reloadActive();
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

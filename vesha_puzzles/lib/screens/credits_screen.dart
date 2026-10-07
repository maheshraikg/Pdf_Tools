import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final t = Theme.of(context).textTheme;
    final d = app.content.dressUp;
    return Scaffold(
      appBar: AppBar(title: Text(s.credits)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.appTitle, style: t.headlineSmall),
          Text('${s.tagline} · v$version'),
          const SizedBox(height: 8),
          Text(s.privacy),
          const Divider(height: 32),
          Text(s.artCredits, style: t.titleMedium),
          for (final p in app.content.packs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.title.of(lang)),
              subtitle: Text(
                [
                  p.credits.artist,
                  p.credits.licence,
                  if (p.credits.year.isNotEmpty) p.credits.year,
                  if (p.credits.url.isNotEmpty) p.credits.url,
                ].join(' · '),
              ),
            ),
          for (final p in app.content.allPuzzles)
            if (p.credit case final c?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(p.title.of(lang)),
                subtitle: Text(
                  [
                    c.author,
                    c.licence,
                    if (c.changes.isNotEmpty) c.changes,
                    c.source,
                  ].join(' · '),
                ),
              ),
          if (d != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.dressUp),
              subtitle: Text('${d.credits.artist} · ${d.credits.licence}'),
            ),
          const Divider(height: 32),
          Text(s.contentCredits, style: t.titleMedium),
          const SizedBox(height: 4),
          Text(s.contentNote),
          const Divider(height: 32),
          Text(s.soundCredits, style: t.titleMedium),
          const SizedBox(height: 4),
          Text(s.soundNote),
          const Divider(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.gavel_outlined),
            label: Text(s.licences),
            onPressed: () => showLicensePage(
              context: context,
              applicationName: s.appTitle,
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}

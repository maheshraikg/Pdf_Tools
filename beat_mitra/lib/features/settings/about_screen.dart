import 'package:flutter/material.dart';

import '../common/widgets.dart';

const String appVersion = '1.0.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.markunread_mailbox, size: 72, color: Theme.of(context).colorScheme.primary),
          Text('${l.appName} $appVersion', textAlign: TextAlign.center, style: t.headlineSmall),
          Text(l.appTagline, textAlign: TextAlign.center, style: t.titleMedium),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l.disclaimer, style: t.titleMedium),
            ),
          ),
          const SizedBox(height: 8),
          Text(l.privacyTitle, style: t.titleLarge),
          for (final s in [l.privacyOnDevice, l.privacyEncrypted, l.privacyNoCloud, l.privacyNoAnalytics, l.privacyMap])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('• $s', style: t.bodyLarge),
            ),
          const SizedBox(height: 12),
          Text(l.freeTools, style: t.bodyMedium),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.description_outlined),
            label: Text(l.licences),
            onPressed: () => showLicensePage(
              context: context,
              applicationName: l.appName,
              applicationVersion: appVersion,
              applicationLegalese:
                  '${l.disclaimer}\n\nMap data © OpenStreetMap contributors (ODbL), only when the optional map is used.',
            ),
          ),
        ],
      ),
    );
  }
}

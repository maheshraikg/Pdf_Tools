import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/l10n/app_localizations.dart';
import 'legal_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.local_post_office_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
          Text('$kAppNameEn · $kAppNameKn', style: t.headlineSmall, textAlign: TextAlign.center),
          Text(l.versionN(kAppVersion), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(kDisclaimerEn, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                if (l.localeName != 'en') ...[const SizedBox(height: 8), Text(l.disclaimer, style: t.titleMedium, textAlign: TextAlign.center)],
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.privacyTitle, style: t.titleMedium),
          Text(l.privacyText),
          const SizedBox(height: 16),
          Text(l.dataTitle, style: t.titleMedium),
          Text(l.dataCredit),
          const SizedBox(height: 4),
          Text(l.schemeDataNote),
          const SizedBox(height: 16),
          Text(l.licenceTitle, style: t.titleMedium),
          Text(l.licenceText),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.verified_user_outlined),
            label: Text(l.legalTitle),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => showLicensePage(context: context, applicationName: kAppNameEn, applicationVersion: kAppVersion), child: Text(l.openSourceLicences)),
        ],
      ),
    );
  }
}

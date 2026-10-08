/// Disclaimer & privacy policy: independent tool, not an official
/// Department of Posts app, no warranty, fully offline.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/constants.dart';
import '../../core/l10n/app_localizations.dart';

List<(IconData, String, String)> legalSections(AppLocalizations l) => [
  (Icons.verified_user_outlined, l.legalH1, l.legal1),
  (Icons.do_not_disturb_alt_outlined, l.legalH2, l.legal2),
  (Icons.report_gmailerrorred_outlined, l.legalH3, l.legal3),
  (Icons.person_outline, l.legalH4, l.legal4),
  (Icons.lock_outline, l.legalH5, l.legal5),
  (Icons.public, l.legalH6, l.legal6),
  (Icons.update, l.legalH7, l.legal7),
];

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.legalTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.tertiaryContainer, borderRadius: BorderRadius.circular(18)),
            child: Text(
              l.localeName == 'en' ? kDisclaimerEn : '$kDisclaimerEn\n\n${l.disclaimer}',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: c.onTertiaryContainer),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          for (final (icon, h, body) in legalSections(l))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: c.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(body, style: t.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(l.versionN(kAppVersion), textAlign: TextAlign.center, style: t.bodySmall),
        ],
      ),
    );
  }
}

/// Shown once on first launch; the app can be used after "I understand".
Future<void> showFirstRunDisclaimer(BuildContext context) async {
  final settings = context.settings;
  if (settings.disclaimerAccepted) return;
  final l = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (d) => PopScope(
      canPop: false,
      child: AlertDialog(
        icon: const Icon(Icons.verified_user_outlined, size: 40),
        title: Text(l.legalTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kDisclaimerEn, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (l.localeName != 'en') ...[
                const SizedBox(height: 6),
                Text(l.disclaimer, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 10),
              Text(l.legal3),
              const SizedBox(height: 8),
              Text(l.legal5),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(d, MaterialPageRoute(builder: (_) => const LegalScreen())),
            child: Text(l.readFullPolicy),
          ),
          FilledButton(
            key: const ValueKey('accept_legal'),
            onPressed: () {
              settings.disclaimerAccepted = true;
              Navigator.pop(d);
            },
            child: Text(l.acceptLegal),
          ),
        ],
      ),
    ),
  );
}

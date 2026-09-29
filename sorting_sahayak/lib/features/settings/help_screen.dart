import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme.dart';

/// Short illustrated guide (icons + text), in the app language.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final steps = <(IconData, Color, String, String)>[
      (Icons.rule_folder_outlined, kSeedRed, l.help1Title, l.help1),
      (Icons.dialpad, kSeedRed, l.help2Title, l.help2),
      (Icons.flight, kAirYellow, l.help3Title, l.help3),
      (Icons.travel_explore, kSurfaceBlue, l.help4Title, l.help4),
      (Icons.fact_check_outlined, Colors.green, l.help5Title, l.help5),
      (Icons.document_scanner_outlined, Colors.teal, l.help6Title, l.help6),
      (Icons.inventory_2_outlined, Colors.brown, l.help7Title, l.help7),
      (Icons.school_outlined, Colors.purple, l.help8Title, l.help8),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.help)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final (i, s) in steps.indexed)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 28, backgroundColor: s.$2, child: Icon(s.$1, color: onColour(s.$2), size: 30)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ${s.$3}', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(s.$4),
                        ],
                      ),
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

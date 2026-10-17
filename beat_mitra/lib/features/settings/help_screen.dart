import 'package:flutter/material.dart';

import '../common/widgets.dart';

/// Picture guide (big icons) in the current language.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final t = Theme.of(context).textTheme;
    final steps = <(IconData, IconData?, String, String)>[
      (Icons.map_outlined, Icons.signpost_outlined, l.help1Title, l.help1Body),
      (Icons.add_location_alt, Icons.photo_camera, l.help2Title, l.help2Body),
      (Icons.search, Icons.mic, l.help3Title, l.help3Body),
      (Icons.explore, Icons.vibration, l.help4Title, l.help4Body),
      (Icons.qr_code_scanner, Icons.document_scanner, l.help5Title, l.help5Body),
      (Icons.alt_route, Icons.check_circle, l.help6Title, l.help6Body),
      (Icons.summarize_outlined, Icons.share, l.help7Title, l.help7Body),
      (Icons.school_outlined, Icons.directions_walk, l.help8Title, l.help8Body),
      (Icons.ios_share, Icons.lock, l.help9Title, l.help9Body),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.help)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var i = 0; i < steps.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Picture": a large icon pair in a coloured box.
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(steps[i].$1, size: 52, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          if (steps[i].$2 != null)
                            Positioned(
                              right: 6,
                              bottom: 6,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Theme.of(context).colorScheme.secondary,
                                child: Icon(steps[i].$2, size: 20, color: Theme.of(context).colorScheme.onSecondary),
                              ),
                            ),
                          Positioned(
                            left: 6,
                            top: 4,
                            child: Text('${i + 1}', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$3, style: t.titleLarge),
                          const SizedBox(height: 4),
                          Text(steps[i].$4, style: t.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(l.helpKannadaOcr, style: t.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}

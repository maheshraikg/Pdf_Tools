import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/pin_utils.dart';
import '../../core/widgets.dart';

/// PIN structure lesson with examples and the circle code table.
class PinBasicsScreen extends StatelessWidget {
  const PinBasicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    // Group consecutive 2-digit codes that share a circle name.
    final groups = <(String, String)>[];
    final codes = kPinCircles.keys.toList()..sort();
    var start = codes.first, prev = codes.first;
    for (final c in [...codes.skip(1), -1]) {
      if (c != -1 && c == prev + 1 && kPinCircles[c] == kPinCircles[start]) {
        prev = c;
        continue;
      }
      groups.add((start == prev ? '$start' : '$start–$prev', kPinCircles[start]!));
      if (c != -1) start = prev = c;
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.pinBasics)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.pinBasicsIntro, style: t.bodyLarge),
          const SizedBox(height: 12),
          PinBreakdownView(breakdown: PinUtils.breakdown('574201')!),
          const SizedBox(height: 12),
          Text(l.pinBasicsDigits, style: t.bodyLarge),
          const SizedBox(height: 12),
          Text(l.pinZones, style: t.titleMedium),
          for (final e in kPinZones.entries) ListTile(dense: true, leading: Text('${e.key}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), title: Text(e.value)),
          const SizedBox(height: 12),
          Text(l.circleTable, style: t.titleMedium),
          Table(
            columnWidths: const {0: FixedColumnWidth(84)},
            border: TableBorder.symmetric(inside: BorderSide(color: Theme.of(context).dividerColor)),
            children: [
              for (final g in groups)
                TableRow(children: [
                  Padding(padding: const EdgeInsets.all(6), child: Text(g.$1, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                  Padding(padding: const EdgeInsets.all(6), child: Text(g.$2, style: const TextStyle(fontSize: 16))),
                ]),
            ],
          ),
          const SizedBox(height: 8),
          for (final e in kPinCircleOverrides.entries) Text('${e.key}: ${e.value}'),
          const SizedBox(height: 12),
          Text(l.pinBasicsNote, style: t.bodySmall),
        ],
      ),
    );
  }
}

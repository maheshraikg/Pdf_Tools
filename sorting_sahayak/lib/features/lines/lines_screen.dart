/// All lines / bags of the active scheme. Pick one to see the whole line:
/// every office in position order with its PIN.
library;

import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/labels.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/live_search.dart';
import '../../data/models/scheme.dart';
import '../home_shell.dart';
import '../lookup/line_table.dart';
import '../lookup/sort_result_view.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final services = context.services;
    final settings = context.settings;
    final scheme = services.active;
    final modes = services.categories;
    final mode = modes.contains(settings.category) ? settings.category : modes.first;

    final lines = <String, List<BagRule>>{};
    for (final r in scheme?.rules ?? const <BagRule>[]) {
      if (r.category != null && r.category != mode) continue;
      (lines[r.bagCode] ??= []).add(r);
    }
    final order = scheme?.bagOrder ?? const <String>[];
    final codes = lines.keys.where((k) => _filter.isEmpty || k.toLowerCase().contains(_filter.toLowerCase())).toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 1 << 20 : ia).compareTo(ib < 0 ? 1 << 20 : ib);
      });

    return Scaffold(
      appBar: AppBar(title: Text(l.allLines), scrolledUnderElevation: 0),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            decoration: BoxDecoration(
              gradient: headerGradient(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                      selectedBackgroundColor: Colors.white,
                      selectedForegroundColor: kNavy,
                      textStyle: t.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w900),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    showSelectedIcon: false,
                    segments: [for (final m in modes) ButtonSegment(value: m, label: Text(categoryLabel(l, m)))],
                    selected: {mode},
                    onSelectionChanged: (v) => setState(() => settings.category = v.first),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('lines_filter'),
                  onChanged: (v) => setState(() => _filter = v.trim()),
                  decoration: InputDecoration(
                    hintText: l.filterLines,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: c.surfaceContainerLowest,
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: scheme == null
                ? const Padding(padding: EdgeInsets.all(12), child: NoSchemeBar())
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: codes.length,
                    itemBuilder: (_, i) {
                      final code = codes[i];
                      final bag = scheme.bags[code] ?? Bag(code: code);
                      final stops = lineRoster(scheme.rules, code, category: mode);
                      final colour = bagColour(context, bag);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LineDetailScreen(code: code, category: mode),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 8, color: colour),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(code, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                                        Text(
                                          [if (bag.name.isNotEmpty && bag.name != code) bag.name, l.stopsN(stops.length)].join(' · '),
                                          style: t.titleSmall?.copyWith(color: c.onSurfaceVariant, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.chevron_right)),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One line: every office in position order with its PIN.
class LineDetailScreen extends StatelessWidget {
  const LineDetailScreen({super.key, required this.code, required this.category});

  final String code;
  final String category;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final scheme = context.services.active;
    final bag = scheme?.bags[code] ?? Bag(code: code);
    final stops = scheme == null ? const <LineStop>[] : lineRoster(scheme.rules, code, category: category);
    final colour = bagColour(context, bag);
    return Scaffold(
      appBar: AppBar(title: Text(code)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colour, Color.lerp(colour, Colors.black, 0.28)!]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: t.headlineMedium?.copyWith(color: onColour(colour), fontWeight: FontWeight.w900),
                ),
                Text(
                  [if (bag.name.isNotEmpty && bag.name != code) bag.name, categoryLabel(l, category), l.stopsN(stops.length)].join(' · '),
                  style: t.titleMedium?.copyWith(color: onColour(colour), fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LineTable(
            stops: stops,
            colour: colour,
            onDark: false,
            matched: const {},
            onPin: (pin) {
              final shell = HomeShell.of(context);
              Navigator.popUntil(context, (r) => r.isFirst);
              shell?.openSort(pin);
            },
          ),
        ],
      ),
    );
  }
}

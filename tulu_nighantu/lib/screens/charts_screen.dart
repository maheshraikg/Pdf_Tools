import 'package:flutter/material.dart';

import '../app_state.dart';
import '../learn/charts.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'trace_screen.dart';

const Map<String, IconData> _chartIcons = {
  'numbers': Icons.onetwothree,
  'days': Icons.calendar_view_week,
  'months': Icons.calendar_month,
  'dirs': Icons.explore_outlined,
  'colours': Icons.palette_outlined,
};

/// List of learning charts (numbers, days, months, directions, colours).
class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final charts = buildCharts(AppState.instance.words);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ಚಾರ್ಟ್‌ಗಳು · Charts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final c in charts)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  child: Icon(_chartIcons[c.icon]),
                ),
                title: Text(
                  '${c.kn} · ${c.en}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  c.items.take(3).map((w) => w.tulu).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text('${c.items.length}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ChartDetailScreen(chart: c),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Tap a card to hear it; ✏️ to practise writing it. '
            'Sample data – verify with native speakers.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// One chart as a grid of cards: Tulu lipi, Kannada script, roman, meaning.
class ChartDetailScreen extends StatelessWidget {
  const ChartDetailScreen({super.key, required this.chart});

  final LearnChart chart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${chart.kn} · ${chart.en}')),
      body: LayoutBuilder(
        builder: (context, box) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: box.maxWidth > 600 ? 3 : 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: chart.items.length,
          itemBuilder: (_, i) => ChartCard(word: chart.items[i]),
        ),
      ),
    );
  }
}

/// A single chart entry; tap to listen.
class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => speakText(context, word.tulu),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: TuluText(word.lipi, size: 40, color: cs.primary),
                  ),
                ),
              ),
              Text(
                word.tulu,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                word.roman,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      word.en,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ಬರೆಯಿರಿ · Write',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TraceScreen.word(word: word),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../learn/culture.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'add_word_screen.dart';

/// Festivals and traditions of Tulunadu, and Tulu proverbs.
class CultureScreen extends StatefulWidget {
  const CultureScreen({super.key, this.data});

  /// For tests: data to show instead of loading the asset.
  final CultureData? data;

  @override
  State<CultureScreen> createState() => _CultureScreenState();
}

class _CultureScreenState extends State<CultureScreen> {
  late final Future<CultureData> _data = widget.data != null
      ? Future.value(widget.data)
      : CultureData.load();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ತುಳುನಾಡ್ · Culture'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ಆಚರಣೆ · Festivals'),
              Tab(text: 'ಗಾದೆ · Proverbs'),
            ],
          ),
        ),
        body: FutureBuilder<CultureData>(
          future: _data,
          builder: (context, snap) {
            final d = snap.data;
            if (d == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final f in d.festivals) _FestivalCard(item: f),
                    const DataNote(),
                  ],
                ),
                _ProverbsView(proverbs: d.proverbs),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FestivalCard extends StatefulWidget {
  const _FestivalCard({required this.item});

  final CultureItem item;

  @override
  State<_FestivalCard> createState() => _FestivalCardState();
}

class _FestivalCardState extends State<_FestivalCard> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final f = widget.item;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RepaintBoundary(
        key: _key,
        child: Material(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: TuluText(
                              f.lipi,
                              size: 30,
                              color: cs.primary,
                            ),
                          ),
                          Text(
                            '${f.tulu} · ${f.roman}',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SpeakButton(f.tulu),
                    IconButton(
                      tooltip: 'ಹಂಚಿ · Share',
                      icon: const Icon(Icons.share_rounded),
                      onPressed: () =>
                          shareBoundaryAsImage(context, _key, 'tulu_${f.id}'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(f.en, style: tt.titleSmall),
                Text(
                  '🗓 ${f.when}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(f.about, style: tt.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProverbsView extends StatelessWidget {
  const _ProverbsView({required this.proverbs});

  final List<Proverb> proverbs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (proverbs.isEmpty)
          const EmptyState(
            icon: Icons.format_quote_rounded,
            title: 'ಗಾದೆಗಳು ಬರಲಿವೆ · Proverbs coming soon',
            subtitle:
                'Know a Tulu proverb (ಗಾದೆ)? Send it below – checked proverbs '
                'are added to the app for everyone.',
          ),
        for (final p in proverbs)
          Card(
            child: ListTile(
              title: TuluText(p.lipi, size: 22, color: cs.primary),
              subtitle: Text(
                '${p.tulu}\n${p.en}${p.kn.isEmpty ? '' : '\n${p.kn}'}',
              ),
              isThreeLine: true,
              trailing: SpeakButton(p.tulu),
            ),
          ),
        const SizedBox(height: 12),
        if (AppState.canSuggest)
          FilledButton.tonalIcon(
            onPressed: () => _sendProverb(context),
            icon: const Icon(Icons.send_rounded),
            label: const Text('ಗಾದೆ ಕಳುಹಿಸಿ · Send a proverb'),
          ),
      ],
    );
  }

  Future<void> _sendProverb(BuildContext context) async {
    final tulu = TextEditingController();
    final meaning = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ಗಾದೆ · Proverb'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tulu,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Proverb in Tulu (Kannada script)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meaning,
                maxLines: 3,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Meaning (English or Kannada)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ಬೇಡ · Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ಕಳುಹಿಸಿ · Send'),
          ),
        ],
      ),
    );
    final t = tulu.text.trim();
    final m = meaning.text.trim();
    tulu.dispose();
    meaning.dispose();
    if (ok != true || t.isEmpty || m.isEmpty) return;
    await sendSuggestions(messenger, [
      Word(
        id: AppState.newCustomId(),
        tulu: t,
        roman: '',
        kn: '',
        en: m,
        cat: 'proverb',
      ),
    ]);
  }
}

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/word.dart';
import '../widgets/common.dart';
import 'trace_screen.dart';

/// Full entry for one word with share / copy / practise actions.
class WordDetailScreen extends StatefulWidget {
  const WordDetailScreen({super.key, required this.word});

  final Word word;

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    final state = AppState.instance;
    final cat = state.categoryById(w.cat);

    return Scaffold(
      appBar: AppBar(title: Text(w.tulu), actions: [FavouriteButton(w.id)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: ShareCard(tulu: w.lipi, kannada: w.tulu, roman: w.roman),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _row('ಕನ್ನಡ', w.kn),
                const Divider(height: 1),
                _row('English', w.en),
                const Divider(height: 1),
                _row(
                  'ವರ್ಗ · Category',
                  cat == null ? w.cat : '${cat.kn} · ${cat.en}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ListenableBuilder(
                listenable: state,
                builder: (context, _) {
                  final fav = state.isFavourite(w.id);
                  return FilledButton.tonalIcon(
                    onPressed: () => state.toggleFavourite(w.id),
                    icon: Icon(fav ? Icons.bookmark : Icons.bookmark_border),
                    label: Text(fav ? 'ಉಳಿಸಲಾಗಿದೆ · Saved' : 'ಉಳಿಸಿ · Save'),
                  );
                },
              ),
              OutlinedButton.icon(
                onPressed: () => copyText(context, w.lipi, 'ತುಳು ಲಿಪಿ'),
                icon: const Icon(Icons.copy),
                label: const Text('ತುಳು ಲಿಪಿ ನಕಲಿಸಿ · Copy Tulu lipi'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    shareBoundaryAsImage(context, _cardKey, 'tulu_${w.id}'),
                icon: const Icon(Icons.share),
                label: const Text('ಚಿತ್ರವಾಗಿ ಹಂಚಿ · Share as image'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TraceScreen.word(word: w),
                  ),
                ),
                icon: const Icon(Icons.gesture),
                label: const Text('ಬರೆದು ಅಭ್ಯಾಸ · Practise writing'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );
}

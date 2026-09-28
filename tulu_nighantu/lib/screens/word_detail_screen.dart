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
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _row(Icons.translate, 'ಕನ್ನಡ', w.kn),
                const Divider(height: 1, indent: 56),
                _row(Icons.language, 'English', w.en),
                const Divider(height: 1, indent: 56),
                _row(
                  Icons.category_outlined,
                  'ವರ್ಗ · Category',
                  cat == null ? w.cat : '${cat.kn} · ${cat.en}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TraceScreen.word(word: w),
              ),
            ),
            icon: const Icon(Icons.gesture),
            label: const Text('ಬರೆದು ಅಭ್ಯಾಸ · Practise writing'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallAction(
                  icon: Icons.volume_up_rounded,
                  label: 'ಕೇಳಿ\nListen',
                  onPressed: () => speakText(context, w.tulu),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ListenableBuilder(
                  listenable: state,
                  builder: (context, _) {
                    final fav = state.isFavourite(w.id);
                    return _SmallAction(
                      icon: fav ? Icons.bookmark : Icons.bookmark_border,
                      label: fav ? 'ಉಳಿಸಲಾಗಿದೆ\nSaved' : 'ಉಳಿಸಿ\nSave',
                      onPressed: () => state.toggleFavourite(w.id),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAction(
                  icon: Icons.copy_rounded,
                  label: 'ನಕಲಿಸಿ\nCopy lipi',
                  onPressed: () => copyText(context, w.lipi, 'ತುಳು ಲಿಪಿ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAction(
                  icon: Icons.share_rounded,
                  label: 'ಹಂಚಿ\nShare',
                  onPressed: () =>
                      shareBoundaryAsImage(context, _cardKey, 'tulu_${w.id}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );
}

/// Tonal button with an icon above a two-line label.
class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: onPressed,
    child: Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, height: 1.25),
        ),
      ],
    ),
  );
}

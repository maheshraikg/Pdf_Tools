import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/word.dart';
import '../widgets/common.dart';

/// Dictionary tab: search, category chips, word of the day and results.
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _controller = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final query = _controller.text;
    final results = state.search(query, category: _category);
    final showWotd = query.trim().isEmpty && _category == null;
    final wotd = state.wordOfTheDay;

    return Scaffold(
      appBar: AppBar(title: const Text('ತುಳು ನಿಘಂಟು')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _searchField()),
          SliverToBoxAdapter(child: _categoryChips(state)),
          if (showWotd && wotd != null)
            SliverToBoxAdapter(child: _WordOfTheDayCard(word: wotd)),
          if (results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No match – try another spelling')),
            )
          else
            SliverList.builder(
              itemCount: results.length,
              itemBuilder: (_, i) => WordTile(results[i]),
            ),
          const SliverToBoxAdapter(child: DataNote()),
        ],
      ),
    );
  }

  Widget _searchField() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: TextField(
      controller: _controller,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search Tulu, ಕನ್ನಡ or English',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'ಅಳಿಸಿ · Clear',
                icon: const Icon(Icons.close),
                onPressed: () => setState(_controller.clear),
              ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
        filled: true,
      ),
    ),
  );

  Widget _categoryChips(AppState state) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _chip(null, 'ಎಲ್ಲಾ · All'),
        for (final c in state.categories) _chip(c.id, '${c.kn} · ${c.en}'),
      ],
    ),
  );

  Widget _chip(String? id, String label) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: ChoiceChip(
      label: Text(label),
      selected: _category == id,
      onSelected: (_) => setState(() => _category = id),
    ),
  );
}

/// Highlighted card for the word of the day.
class _WordOfTheDayCard extends StatelessWidget {
  const _WordOfTheDayCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: cs.primaryContainer,
      child: InkWell(
        onTap: () => openWord(context, word),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ಇಂದಿನ ಪದ · Word of the Day',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: cs.onPrimaryContainer),
              ),
              const SizedBox(height: 8),
              Center(
                child: TuluText(
                  word.lipi,
                  size: 48,
                  color: cs.onPrimaryContainer,
                ),
              ),
              Center(
                child: Text(
                  word.tulu,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (word.roman.isNotEmpty)
                Center(
                  child: Text(
                    word.roman,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'ಕನ್ನಡ: ${word.kn}',
                style: TextStyle(color: cs.onPrimaryContainer),
              ),
              Text(
                'English: ${word.en}',
                style: TextStyle(color: cs.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

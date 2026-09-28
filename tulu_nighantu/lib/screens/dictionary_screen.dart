import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../lipi/tulu_lipi.dart';
import '../models/word.dart';
import '../widgets/common.dart';

/// Icon for each category id.
const Map<String, IconData> kCategoryIcons = {
  'family': Icons.family_restroom,
  'body': Icons.accessibility_new,
  'food': Icons.restaurant,
  'nature': Icons.park_outlined,
  'animals': Icons.pets,
  'numbers': Icons.onetwothree,
  'time': Icons.schedule,
  'words': Icons.chat_bubble_outline,
  'verbs': Icons.directions_run,
  'culture': Icons.home_outlined,
  'phrases': Icons.forum_outlined,
};

/// Dictionary tab: hero search header, category chips, word of the day and
/// results.
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
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              controller: _controller,
              // A text search always covers every category.
              onChanged: () => setState(() {
                if (_controller.text.trim().isNotEmpty) _category = null;
              }),
            ),
          ),
          SliverToBoxAdapter(child: _categoryChips(state)),
          if (showWotd && wotd != null)
            SliverToBoxAdapter(child: _WordOfTheDayCard(word: wotd)),
          SliverToBoxAdapter(
            child: SectionHeader(
              showWotd ? 'ಎಲ್ಲಾ ಪದಗಳು' : 'ಫಲಿತಾಂಶ',
              '${results.length} ${showWotd ? 'words' : 'results'}',
            ),
          ),
          if (results.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No match – try another spelling',
                subtitle: 'ಬೇರೆ ಕಾಗುಣಿತದಲ್ಲಿ ಹುಡುಕಿ',
              ),
            )
          else
            SliverList.builder(
              itemCount: results.length,
              itemBuilder: (_, i) => WordTile(results[i]),
            ),
          const SliverToBoxAdapter(child: DataNote()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _categoryChips(AppState state) => SizedBox(
    height: 56,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      children: [
        _chip(null, 'ಎಲ್ಲಾ · All', Icons.apps),
        for (final c in state.categories)
          _chip(c.id, '${c.kn} · ${c.en}', kCategoryIcons[c.id]),
      ],
    ),
  );

  Widget _chip(String? id, String label, IconData? icon) {
    final selected = _category == id;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: icon == null
            ? null
            : Icon(icon, size: 18, color: selected ? cs.onPrimary : cs.primary),
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _category = id),
      ),
    );
  }
}

/// Gradient header with the app title and the search field.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB3261E), Color(0xFF7A1410)],
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ತುಳು ನಿಘಂಟು',
                            style: tt.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Tulu ⇄ ಕನ್ನಡ ⇄ English',
                            style: tt.bodyMedium?.copyWith(
                              color: const Color(0xFFFFD54F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TuluText(
                      TuluLipi.fromKannada('ತುಳು'),
                      size: 34,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Material(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(16),
                  color: cs.surface,
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search Tulu, ಕನ್ನಡ or English',
                      fillColor: cs.surface,
                      prefixIcon: Icon(Icons.search, color: cs.primary),
                      suffixIcon: controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'ಅಳಿಸಿ · Clear',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                controller.clear();
                                onChanged();
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Highlighted card for the word of the day.
class _WordOfTheDayCard extends StatelessWidget {
  const _WordOfTheDayCard({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final fg = light ? const Color(0xFF3D2E00) : const Color(0xFFFFE08A);
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: light
                  ? const [Color(0xFFFFF3C4), Color(0xFFFFD54F)]
                  : const [Color(0xFF3D2E00), Color(0xFF5C4400)],
            ),
          ),
          child: InkWell(
            onTap: () => openWord(context, word),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 16, color: fg),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'ಇಂದಿನ ಪದ · Word of the Day',
                          style: tt.labelLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.tulu,
                              style: tt.headlineMedium?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (word.roman.isNotEmpty)
                              Text(
                                word.roman,
                                style: tt.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: fg.withValues(alpha: 0.8),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              '${word.en} · ${word.kn}',
                              style: tt.bodyLarge?.copyWith(color: fg),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 88,
                          maxWidth: 130,
                          minHeight: 88,
                        ),
                        padding: const EdgeInsets.all(10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: light ? 0.6 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: FittedBox(
                          child: TuluText(
                            word.lipi,
                            size: 44,
                            color: light
                                ? const Color(0xFFB3261E)
                                : const Color(0xFFFFD54F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

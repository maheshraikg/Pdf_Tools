import 'package:flutter/material.dart';

import '../app_state.dart';
import '../lipi/tulu_lipi.dart';

import 'package:share_plus/share_plus.dart';

import '../widgets/common.dart';
import 'add_word_screen.dart';
import 'settings_screen.dart';

/// App version shown in the About card (keep in sync with pubspec.yaml).
const String kAppVersion = '1.1.0';

/// Saved tab: favourites, progress and about.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('ಉಳಿಸಿದವು · Saved'),
        actions: [
          IconButton(
            tooltip: 'ಸೆಟ್ಟಿಂಗ್ಸ್ · Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final favs = state.favouriteWords;
          return ListView(
            children: [
              const SectionHeader('ಮೆಚ್ಚಿನ ಪದಗಳು', 'Favourites'),
              if (favs.isEmpty)
                const _EmptyFavourites()
              else
                for (final w in favs) WordTile(w),
              const SectionHeader('ನನ್ನ ಪದಗಳು', 'My words'),
              _MyWords(state: state),
              const SectionHeader('ಪ್ರಗತಿ', 'Progress'),
              _ProgressCard(state: state),
              const SectionHeader('ಬಗ್ಗೆ', 'About'),
              const _AboutCard(),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

/// Words the user added, with add and export/share buttons.
class _MyWords extends StatelessWidget {
  const _MyWords({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final mine = state.customWords;
    final unsent = [
      for (final w in mine)
        if (!state.sentSuggestions.contains(w.id)) w,
    ];
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (mine.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'ಸಿಗದ ಪದಗಳನ್ನು ನೀವೇ ಸೇರಿಸಿ · Add words the dictionary is '
              'missing – they become searchable and translatable at once.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          )
        else
          for (final w in mine) WordTile(w),
        if (AppState.canSuggest && unsent.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () =>
                  sendSuggestions(ScaffoldMessenger.of(context), unsent),
              icon: const Icon(Icons.send_rounded),
              label: Text(
                'ನಿಘಂಟಿಗೆ ಕಳುಹಿಸಿ · Send ${unsent.length} to dictionary',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => openAddWord(context),
                  icon: const Icon(Icons.add),
                  label: const Text('ಸೇರಿಸಿ · Add'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: mine.isEmpty
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(
                            subject: 'Tulu Nighantu – new words',
                            text: state.exportCustomWords(),
                          ),
                        ),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyFavourites extends StatelessWidget {
  const _EmptyFavourites();

  @override
  Widget build(BuildContext context) => const EmptyState(
    icon: Icons.bookmark_border,
    title: 'ಇನ್ನೂ ಏನೂ ಉಳಿಸಿಲ್ಲ · Nothing saved yet',
    subtitle:
        'ಪದದ ಪಕ್ಕದ 🔖 ಒತ್ತಿ ಉಳಿಸಿ\nTap the bookmark next to a word to save it',
  );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final n = kLipiLetters.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.draw_rounded,
              value: '${state.lettersPractised}/$n',
              label: 'ಅಕ್ಷರಗಳು\nLetters practised',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              icon: Icons.star_rounded,
              value: '${state.letterStars}/${n * 3}',
              label: 'ನಕ್ಷತ್ರಗಳು\nStars',
              accent: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single statistic in a tinted tile.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final bg = accent
        ? (light ? const Color(0xFFFFF3C4) : const Color(0xFF3D2E00))
        : cs.primaryContainer;
    final fg = accent
        ? (light ? const Color(0xFF3D2E00) : const Color(0xFFFFE08A))
        : cs.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w800),
          ),
          Text(label, style: TextStyle(color: fg, height: 1.25)),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: GlyphBadge(TuluLipi.fromKannada('ತ'), size: 44),
            title: const Text(
              'ತುಳು ನಿಘಂಟು · Tulu Nighantu',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Version $kAppVersion · ಆಫ್‌ಲೈನ್ · Works offline (AI optional)',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.font_download_outlined),
            title: Text('Font: Mallige (SIL OFL 1.1)'),
            subtitle: Text('Tulu-Tigalari, Unicode 16.0'),
          ),
          ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: const Text('ಪದಪಟ್ಟಿ · Word list'),
            subtitle: Text(
              AppState.instance.dataNote.isEmpty
                  ? 'Sample list – verified by native speakers before publishing'
                  : AppState.instance.dataNote,
            ),
          ),
        ],
      ),
    );
  }
}

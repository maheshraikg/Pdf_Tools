import 'package:flutter/material.dart';

import '../app_state.dart';
import '../lipi/tulu_lipi.dart';
import '../widgets/common.dart';

/// App version shown in the About card (keep in sync with pubspec.yaml).
const String kAppVersion = '1.0.0';

/// Saved tab: favourites, progress and about.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('ಉಳಿಸಿದವು · Saved')),
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
              'Version $kAppVersion · ಆಫ್‌ಲೈನ್ · Works offline',
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

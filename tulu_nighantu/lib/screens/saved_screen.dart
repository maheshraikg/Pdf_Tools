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
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.bookmark_border, size: 48, color: outline),
          const SizedBox(height: 8),
          const Text(
            'ಇನ್ನೂ ಏನೂ ಉಳಿಸಿಲ್ಲ · Nothing saved yet',
            textAlign: TextAlign.center,
          ),
          Text(
            'ಪದದ ಪಕ್ಕದ 🔖 ಒತ್ತಿ ಉಳಿಸಿ · Tap the bookmark next to a word to save it',
            textAlign: TextAlign.center,
            style: TextStyle(color: outline),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final n = kLipiLetters.length;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.draw),
            title: const Text('ಅಭ್ಯಾಸ ಮಾಡಿದ ಅಕ್ಷರಗಳು · Letters practised'),
            trailing: Text('${state.lettersPractised} / $n'),
          ),
          ListTile(
            leading: Icon(
              Icons.star_rounded,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            title: const Text('ನಕ್ಷತ್ರಗಳು · Stars'),
            trailing: Text('${state.letterStars} / ${n * 3}'),
          ),
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
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('ತುಳು ನಿಘಂಟು · Tulu Nighantu'),
            subtitle: Text('Version $kAppVersion · ಆಫ್‌ಲೈನ್ · Works offline'),
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

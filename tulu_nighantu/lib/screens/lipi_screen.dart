import 'package:flutter/material.dart';

import '../app_state.dart';
import '../lipi/tulu_lipi.dart';
import '../widgets/common.dart';
import 'trace_screen.dart';

/// Lipi tab: alphabet grid grouped by [LetterGroup] with progress.
class LipiScreen extends StatelessWidget {
  const LipiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('ತುಳು ಲಿಪಿ · Tulu Lipi')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTrace(context, 0),
        icon: const Icon(Icons.play_arrow),
        label: const Text('ಎಲ್ಲಾ ಅಭ್ಯಾಸ · Practise all'),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ProgressHeader(state: state)),
            for (final g in LetterGroup.values) ..._group(context, g, state),
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(BuildContext context, LetterGroup g, AppState state) {
    final letters = kLipiLetters.where((l) => l.group == g).toList();
    return [
      SliverToBoxAdapter(child: SectionHeader(g.kannada, g.english)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.8,
          children: [
            for (final l in letters)
              _LetterCell(letter: l, stars: state.starsFor(l.starKey)),
          ],
        ),
      ),
    ];
  }
}

void _openTrace(BuildContext context, int index) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TraceScreen.letters(startIndex: index),
    ),
  );
}

/// "x / N letters practised" with a progress bar and total stars.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final n = kLipiLetters.length;
    final done = state.lettersPractised;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$done / $n ಅಕ್ಷರ ಅಭ್ಯಾಸ · letters practised',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Icon(
                  Icons.star_rounded,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                Text(' ${state.letterStars} / ${n * 3}'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: n == 0 ? 0 : done / n),
          ],
        ),
      ),
    );
  }
}

/// One alphabet cell: big Tulu glyph, Kannada label, stars.
class _LetterCell extends StatelessWidget {
  const _LetterCell({required this.letter, required this.stars});

  final LipiLetter letter;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showLetterSheet(context, letter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              child: TuluText(letter.tulu, size: 34, color: cs.primary),
            ),
            Text(letter.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            StarRow(stars, size: 12),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet with the huge glyph, barakhadi row and a trace button.
void _showLetterSheet(BuildContext context, LipiLetter letter) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TuluText(letter.tulu, size: 110, color: cs.primary),
              Text(
                '${letter.label} · ${letter.roman}',
                style: Theme.of(ctx).textTheme.headlineSmall,
              ),
              if (letter.isConsonant) ...[
                SectionHeader('ಕಾಗುಣಿತ', 'Barakhadi'),
                _Barakhadi(letter: letter),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openTrace(context, kLipiLetters.indexOf(letter));
                },
                icon: const Icon(Icons.gesture),
                label: const Text('ಈ ಅಕ್ಷರ ಬರೆಯಿರಿ · Trace this letter'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Consonant + each vowel sign, Tulu above Kannada.
class _Barakhadi extends StatelessWidget {
  const _Barakhadi({required this.letter});

  final LipiLetter letter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kBarakhadiSigns.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final kn = letter.kannada + kBarakhadiSigns[i];
          return Container(
            width: 64,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TuluText(TuluLipi.fromKannada(kn), size: 28, color: cs.primary),
                Text(kn),
              ],
            ),
          );
        },
      ),
    );
  }
}

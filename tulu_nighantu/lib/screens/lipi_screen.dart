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
        backgroundColor: const Color(0xFFFFD54F),
        foregroundColor: const Color(0xFF3D2E00),
        onPressed: () => _openTrace(context, 0),
        icon: const Icon(Icons.play_arrow_rounded),
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
      SliverToBoxAdapter(
        child: SectionHeader(
          g.kannada,
          '${g.english} · '
          '${letters.where((l) => state.starsFor(l.starKey) > 0).length}'
          '/${letters.length}',
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid.count(
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.82,
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

/// Progress ring with "x / N letters practised" and total stars.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final n = kLipiLetters.length;
    final done = state.lettersPractised;
    final value = n == 0 ? 0.0 : done / n;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB3261E), Color(0xFF7A1410)],
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  color: const Color(0xFFFFD54F),
                  backgroundColor: Colors.white24,
                ),
                Center(
                  child: Text(
                    '${(value * 100).round()}%',
                    style: tt.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done / $n ಅಕ್ಷರ ಅಭ್ಯಾಸ',
                  style: tt.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'letters practised',
                  style: tt.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFFD54F),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.letterStars} / ${n * 3}',
                      style: tt.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One alphabet cell: big Tulu glyph, Kannada label, stars. Practised
/// letters are tinted; fully mastered ones get a gold outline.
class _LetterCell extends StatelessWidget {
  const _LetterCell({required this.letter, required this.stars});

  final LipiLetter letter;
  final int stars;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final practised = stars > 0;
    return Material(
      color: practised ? cs.primaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: stars == 3
            ? BorderSide(color: cs.tertiary, width: 2)
            : BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showLetterSheet(context, letter),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  child: TuluText(
                    letter.tulu,
                    size: 34,
                    color: practised ? cs.onPrimaryContainer : cs.primary,
                  ),
                ),
              ),
              Text(
                letter.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              StarRow(stars, size: 12),
            ],
          ),
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
              Container(
                width: 180,
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TuluText(
                      letter.tulu,
                      size: 110,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                letter.label,
                style: Theme.of(ctx).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${letter.roman} · ${letter.group.english}',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              ListenableBuilder(
                listenable: AppState.instance,
                builder: (_, _) => StarRow(
                  AppState.instance.starsFor(letter.starKey),
                  size: 22,
                ),
              ),
              if (letter.isConsonant) ...[
                const SectionHeader('ಕಾಗುಣಿತ', 'Barakhadi'),
                _Barakhadi(letter: letter),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
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
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kBarakhadiSigns.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final kn = letter.kannada + kBarakhadiSigns[i];
          return Container(
            width: 66,
            decoration: BoxDecoration(
              color: i == 0 ? cs.primaryContainer : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TuluText(TuluLipi.fromKannada(kn), size: 28, color: cs.primary),
                Text(
                  kn,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

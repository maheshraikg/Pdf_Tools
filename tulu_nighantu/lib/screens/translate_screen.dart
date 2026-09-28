import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/word.dart';
import '../translate/translator.dart';
import '../widgets/ai_answer_sheet.dart';
import '../widgets/common.dart';
import 'add_word_screen.dart';

/// Translate view: type Kannada or English, get Tulu (dictionary-based).
class TranslateView extends StatefulWidget {
  const TranslateView({super.key});

  @override
  State<TranslateView> createState() => _TranslateViewState();
}

class _TranslateViewState extends State<TranslateView> {
  final _controller = TextEditingController();
  final _cardKey = GlobalKey();

  static const _samples = [
    'How are you?',
    'mother and father',
    'ನೀರು ಕುಡಿ',
    'What is your name?',
    'big tree',
    'ನನಗೆ ಗೊತ್ತಿಲ್ಲ',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = _controller.text;
    final result = AppState.instance.translator.translate(input);
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        TextField(
          controller: _controller,
          minLines: 2,
          maxLines: 5,
          style: const TextStyle(fontSize: 18),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'ಕನ್ನಡ ಅಥವಾ English ಬರೆಯಿರಿ · Type Kannada or English',
            prefixIcon: const Icon(Icons.translate),
            suffixIcon: input.isEmpty
                ? null
                : IconButton(
                    tooltip: 'ಅಳಿಸಿ · Clear',
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_controller.clear),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final s in _samples)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(Icons.bolt, size: 16, color: cs.primary),
                    label: Text(s),
                    onPressed: () => setState(() => _controller.text = s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (result.isEmpty)
          const EmptyState(
            icon: Icons.translate,
            title: 'ತುಳುವಿಗೆ ಅನುವಾದಿಸಿ · Translate to Tulu',
            subtitle:
                'ಕನ್ನಡ ಅಥವಾ ಇಂಗ್ಲಿಷ್ ಪದ/ವಾಕ್ಯ ಬರೆಯಿರಿ\n'
                'Type a Kannada or English word or sentence',
          )
        else ...[
          _StatusBanner(result: result),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _cardKey,
            child: ShareCard(
              tulu: result.lipi,
              kannada: result.tulu,
              roman: result.roman,
              tuluSize: 38,
            ),
          ),
          const SizedBox(height: 12),
          _actions(result),
          const SizedBox(height: 8),
          AskAiButton(input),
          const SectionHeader('ಪದ-ಪದವಾಗಿ', 'Word by word'),
          ..._breakdown(result),
        ],
        const SizedBox(height: 16),
        _note(cs),
      ],
    );
  }

  Widget _actions(Translation r) => Row(
    children: [
      Expanded(
        child: FilledButton.tonalIcon(
          onPressed: () => speakText(context, r.tulu),
          icon: const Icon(Icons.volume_up_rounded),
          label: const Text('ಕೇಳಿ'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton.tonalIcon(
          onPressed: () => copyText(context, '${r.tulu}\n${r.lipi}', 'ತುಳು'),
          icon: const Icon(Icons.copy_rounded),
          label: const Text('ನಕಲಿಸಿ'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton.tonalIcon(
          onPressed: () =>
              shareBoundaryAsImage(context, _cardKey, 'tulu_translation'),
          icon: const Icon(Icons.share_rounded),
          label: const Text('ಹಂಚಿ'),
        ),
      ),
    ],
  );

  List<Widget> _breakdown(Translation r) {
    if (r.phrase != null) {
      return [_PieceTile(source: _controller.text.trim(), word: r.phrase)];
    }
    return [
      for (final p in r.pieces)
        _PieceTile(
          source: p.source,
          word: p.word,
          approximate: p.approximate,
          onAdd: () async {
            final saved = await openAddWord(context, prefill: p.source);
            if (saved != null && mounted) setState(() {});
          },
        ),
    ];
  }

  Widget _note(ColorScheme cs) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'ನಿಘಂಟಿನ ಪದಗಳಿಂದ ಪದ-ಪದ ಅನುವಾದ; ತುಳು ವ್ಯಾಕರಣ ಅನ್ವಯಿಸಿಲ್ಲ.\n'
            'Word-by-word from the dictionary: whole phrases are matched '
            'first, but Tulu grammar and word order are not applied. Words '
            'not in the dictionary are left as typed.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      ],
    ),
  );
}

/// "Phrase found" / "x of y words found" banner.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.result});

  final Translation result;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = result.phrase != null ? 1 : result.pieces.length;
    final (icon, text, bg, fg) = result.phrase != null
        ? (
            Icons.check_circle,
            'ವಾಕ್ಯ ಸಿಕ್ಕಿತು · Phrase found',
            cs.primaryContainer,
            cs.onPrimaryContainer,
          )
        : result.complete
        ? (
            Icons.check_circle_outline,
            'ಎಲ್ಲಾ ಪದಗಳು ಸಿಕ್ಕಿವೆ · All $total words found',
            cs.primaryContainer,
            cs.onPrimaryContainer,
          )
        : (
            Icons.help_outline,
            '${result.foundCount}/$total ಪದಗಳು ಸಿಕ್ಕಿವೆ · words found',
            cs.errorContainer,
            cs.onErrorContainer,
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// One source chunk → Tulu word row; tap opens the dictionary entry.
class _PieceTile extends StatelessWidget {
  const _PieceTile({
    required this.source,
    required this.word,
    this.approximate = false,
    this.onAdd,
  });

  /// Called when an unknown word is tapped (to add it).
  final VoidCallback? onAdd;

  final String source;
  final Word? word;
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final w = word;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: w == null ? cs.errorContainer.withValues(alpha: 0.5) : null,
      child: ListTile(
        onTap: w == null ? onAdd : () => openWord(context, w),
        title: Row(
          children: [
            Flexible(
              child: Text(
                source,
                style: TextStyle(color: cs.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 16, color: cs.outline),
            ),
            Flexible(
              child: Text(
                w == null ? 'ಸೇರಿಸಿ · tap to add' : w.tulu,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: w == null ? cs.error : cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: w == null
            ? null
            : Text(
                '${w.roman} · ${w.en}'
                '${approximate ? ' · ≈ ಅಂದಾಜು match' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: w == null
            ? null
            : TuluText(firstSyllable(w.lipi), size: 22, color: cs.primary),
      ),
    );
  }
}

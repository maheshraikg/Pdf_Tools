import 'package:flutter/material.dart';

import '../lipi/composer.dart';
import '../lipi/tulu_lipi.dart';
import '../widgets/common.dart';

/// Card styles for the shared picture.
enum _CardStyle {
  red('ಕೆಂಪು · Red', Color(0xFFB3261E), Color(0xFFFFD54F)),
  yellow('ಹಳದಿ · Yellow', Color(0xFFFFD54F), Color(0xFF7A1410)),
  white('ಬೊಳ್ದು · White', Colors.white, Color(0xFFB3261E)),
  sticker('Sticker', Colors.transparent, Color(0xFFB3261E));

  const _CardStyle(this.label, this.background, this.ink);

  final String label;
  final Color background;
  final Color ink;
}

/// Type in Tulu lipi with an on-screen keyboard (or the phone's Kannada
/// keyboard) and share the result as a picture or sticker. Pictures work in
/// every app, even where the Tulu-Tigalari font is not installed.
class TuluKeyboardScreen extends StatefulWidget {
  const TuluKeyboardScreen({super.key});

  @override
  State<TuluKeyboardScreen> createState() => _TuluKeyboardScreenState();
}

class _TuluKeyboardScreenState extends State<TuluKeyboardScreen> {
  final _text = TextEditingController();
  final _cardKey = GlobalKey();
  _CardStyle _style = _CardStyle.red;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(String t) => _text.value = TextEditingValue(
    text: t,
    selection: TextSelection.collapsed(offset: t.length),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kn = _text.text;
    final lipi = TuluLipi.fromKannada(kn);
    final consonant = lastConsonant(kn);
    return Scaffold(
      appBar: AppBar(title: const Text('ತುಳು ಕೀಬೋರ್ಡ್ · Tulu keyboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _style.background,
                borderRadius: BorderRadius.circular(24),
                border: _style == _CardStyle.white
                    ? Border.all(color: cs.outlineVariant)
                    : null,
              ),
              child: lipi.isEmpty
                  ? Text(
                      'ಕೆಳಗೆ ಬರೆಯಿರಿ · Type below',
                      style: TextStyle(color: cs.outline, fontSize: 18),
                    )
                  : TuluText(lipi, size: 44, color: _style.ink),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in _CardStyle.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _style == s,
                  onSelected: (_) => setState(() => _style = s),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: lipi.isEmpty
                      ? null
                      : () => shareBoundaryAsImage(
                          context,
                          _cardKey,
                          'tulu_lipi',
                        ),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('ಹಂಚಿ · Share'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: lipi.isEmpty
                      ? null
                      : () => copyText(context, lipi, 'ತುಳು ಲಿಪಿ'),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            decoration: InputDecoration(
              labelText: 'ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ · In Kannada script',
              hintText: 'Use the keys below or your phone keyboard',
              suffixIcon: IconButton(
                tooltip: 'ಅಳಿಸಿ · Clear',
                icon: const Icon(Icons.clear),
                onPressed: () => _set(''),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _keys(context, [
            for (final s in kVowelSigns)
              _Key(
                kannada: '${consonant ?? '◌'}$s',
                onTap: consonant == null && s != 'ಂ' && s != 'ಃ'
                    ? null
                    : () => _set(applySign(kn, s)),
                highlight: true,
              ),
          ]),
          const SizedBox(height: 8),
          for (final g in LetterGroup.values)
            if (g != LetterGroup.yogavaha)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _keys(context, [
                  for (final l in kLipiLetters.where((l) => l.group == g))
                    _Key(kannada: l.kannada, onTap: () => _set(kn + l.kannada)),
                ]),
              ),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _set('$kn '),
                  icon: const Icon(Icons.space_bar),
                  label: const Text('Space'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: kn.isEmpty ? null : () => _set(backspace(kn)),
                icon: const Icon(Icons.backspace_outlined),
                label: const Text('⌫'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: most phones do not have a Tulu lipi font yet, so share as a '
            'picture – everyone can see it. "Copy" gives Unicode text for '
            'apps and phones that support Tulu-Tigalari.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _keys(BuildContext context, List<_Key> keys) =>
      Wrap(spacing: 6, runSpacing: 6, children: keys);
}

/// One key: the Tulu glyph with its Kannada letter underneath.
class _Key extends StatelessWidget {
  const _Key({required this.kannada, this.onTap, this.highlight = false});

  final String kannada;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    return Material(
      color: highlight ? cs.secondaryContainer : cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 58,
          child: Opacity(
            opacity: enabled ? 1 : 0.35,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: FittedBox(
                      child: TuluText(
                        TuluLipi.fromKannada(kannada.replaceAll('◌', '')),
                        size: 24,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                Text(
                  kannada,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../lipi/tulu_lipi.dart';
import '../widgets/common.dart';

/// Converter tab: live Kannada → Tulu lipi with copy and share.
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _controller = TextEditingController(text: 'ಜೈ ತುಳುನಾಡ್');
  final _cardKey = GlobalKey();

  static const _samples = ['ತುಳು', 'ಜೈ ತುಳುನಾಡ್', 'ಸೊಲ್ಮೆಲು', 'ಎಡ್ಡೆ ಆವಡ್'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final input = _controller.text;
    final output = TuluLipi.fromKannada(input);
    final hasKannada = TuluLipi.hasKannada(input);

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ಲಿಪಿ ಬದಲಿಸಿ · Converter')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _StepLabel(
            icon: Icons.keyboard_outlined,
            text: 'ಕನ್ನಡ · Kannada',
          ),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 6,
            style: const TextStyle(fontSize: 18),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ ಬರೆಯಿರಿ · Type in Kannada script',
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
          if (input.trim().isNotEmpty && !hasKannada)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ಕನ್ನಡ ಅಕ್ಷರಗಳು ಕಾಣುತ್ತಿಲ್ಲ · No Kannada letters found – '
                      'type using a Kannada keyboard',
                      style: TextStyle(color: cs.error),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: cs.tertiary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: cs.onTertiary,
                  size: 20,
                ),
              ),
            ),
          ),
          const _StepLabel(
            icon: Icons.auto_awesome,
            text: 'ತುಳು ಲಿಪಿ · Tulu lipi',
          ),
          RepaintBoundary(
            key: _cardKey,
            child: ShareCard(tulu: output, kannada: input, tuluSize: 40),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.copy_rounded,
                  label: 'ತುಳು ನಕಲಿಸಿ\nCopy Tulu',
                  primary: true,
                  onPressed: output.isEmpty
                      ? null
                      : () => copyText(context, output, 'ತುಳು ಲಿಪಿ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.volume_up_rounded,
                  label: 'ಕೇಳಿ\nListen',
                  onPressed: hasKannada
                      ? () => speakText(context, input)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.copy_all_rounded,
                  label: 'ಕನ್ನಡ\nCopy Kannada',
                  onPressed: input.isEmpty
                      ? null
                      : () => copyText(context, input, 'ಕನ್ನಡ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'ಹಂಚಿ\nShare image',
                  onPressed: output.isEmpty
                      ? null
                      : () => shareBoundaryAsImage(
                          context,
                          _cardKey,
                          'tulu_lipi',
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                    'ಸೂಚನೆ: ಯೂನಿಕೋಡ್ ತುಳು ಲಿಪಿಯಲ್ಲಿ ಹ್ರಸ್ವ ಎ/ಒ ಇಲ್ಲ, ಆದ್ದರಿಂದ ಅವನ್ನು '
                    'ಏ/ಓ ಆಗಿ ಬರೆಯಲಾಗುತ್ತದೆ. ಒತ್ತಕ್ಷರಗಳು ವಿರಾಮದೊಂದಿಗೆ ಕಾಣುತ್ತವೆ.\n'
                    'Note: short ಎ/ಒ are written as ಏ/ಓ in Unicode Tulu lipi. '
                    'Conjuncts are shown with a visible virama.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small icon + label above a converter section.
class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Square-ish action button with an icon above a two-line label.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return primary
        ? FilledButton(
            style: FilledButton.styleFrom(
              shape: shape,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: onPressed,
            child: child,
          )
        : FilledButton.tonal(
            style: FilledButton.styleFrom(
              shape: shape,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            onPressed: onPressed,
            child: child,
          );
  }
}

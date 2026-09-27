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
    final outline = Theme.of(context).colorScheme.outline;

    return Scaffold(
      appBar: AppBar(title: const Text('ಲಿಪಿ ಬದಲಿಸಿ · Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ ಬರೆಯಿರಿ · Type in Kannada script',
              border: const OutlineInputBorder(),
              suffixIcon: input.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ಅಳಿಸಿ · Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_controller.clear),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in _samples)
                ActionChip(
                  label: Text(s),
                  onPressed: () => setState(() => _controller.text = s),
                ),
            ],
          ),
          if (input.trim().isNotEmpty && !hasKannada)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'ಕನ್ನಡ ಅಕ್ಷರಗಳು ಕಾಣುತ್ತಿಲ್ಲ · No Kannada letters found – '
                'type using a Kannada keyboard',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          RepaintBoundary(
            key: _cardKey,
            child: ShareCard(tulu: output, kannada: input, tuluSize: 40),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: output.isEmpty
                    ? null
                    : () => copyText(context, output, 'ತುಳು ಲಿಪಿ'),
                icon: const Icon(Icons.copy),
                label: const Text('ತುಳು ನಕಲಿಸಿ · Copy Tulu text'),
              ),
              OutlinedButton.icon(
                onPressed: input.isEmpty
                    ? null
                    : () => copyText(context, input, 'ಕನ್ನಡ'),
                icon: const Icon(Icons.copy_all),
                label: const Text('ಕನ್ನಡ ನಕಲಿಸಿ · Copy Kannada'),
              ),
              OutlinedButton.icon(
                onPressed: output.isEmpty
                    ? null
                    : () =>
                          shareBoundaryAsImage(context, _cardKey, 'tulu_lipi'),
                icon: const Icon(Icons.share),
                label: const Text('ಚಿತ್ರವಾಗಿ ಹಂಚಿ · Share as image'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ಸೂಚನೆ: ಯೂನಿಕೋಡ್ ತುಳು ಲಿಪಿಯಲ್ಲಿ ಹ್ರಸ್ವ ಎ/ಒ ಇಲ್ಲ, ಆದ್ದರಿಂದ ಅವನ್ನು '
            'ಏ/ಓ ಆಗಿ ಬರೆಯಲಾಗುತ್ತದೆ. ಒತ್ತಕ್ಷರಗಳು ವಿರಾಮದೊಂದಿಗೆ ಕಾಣುತ್ತವೆ.\n'
            'Note: short ಎ/ಒ are written as ಏ/ಓ in Unicode Tulu lipi. '
            'Conjuncts are shown with a visible virama.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: outline),
          ),
        ],
      ),
    );
  }
}

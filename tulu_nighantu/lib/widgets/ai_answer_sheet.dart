import 'package:flutter/material.dart';

import '../ai/gemini_client.dart';
import '../app_state.dart';
import '../lipi/tulu_lipi.dart';
import '../models/word.dart';
import '../screens/add_word_screen.dart';
import '../screens/settings_screen.dart';
import 'common.dart';

/// "Ask AI" button used next to translations and empty search results.
class AskAiButton extends StatelessWidget {
  const AskAiButton(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: text.trim().isEmpty ? null : () => showAiAnswer(context, text),
    icon: const Icon(Icons.auto_awesome),
    label: const Text('AI ಸಹಾಯ · Ask AI'),
  );
}

/// Shows a bottom sheet with Gemini's (unverified) Tulu for [text].
Future<void> showAiAnswer(BuildContext context, String text) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AiSheet(text: text.trim()),
    );

class _AiSheet extends StatefulWidget {
  const _AiSheet({required this.text});

  final String text;

  @override
  State<_AiSheet> createState() => _AiSheetState();
}

class _AiSheetState extends State<_AiSheet> {
  Future<AiAnswer>? _future;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    final client = AppState.instance.aiClient();
    if (client == null) return;
    // Ground the AI with verified dictionary words related to the text.
    final state = AppState.instance;
    final glossary = <Word>{
      for (final p in state.translator.translate(widget.text).pieces) ?p.word,
      ...state.search(widget.text).take(5),
    }.toList();
    setState(() {
      _future = client.translate(widget.text, glossary: glossary);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI ಸಹಾಯ · Ask AI',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '“${widget.text}”',
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            if (_future == null) _noKey(context) else _answer(context),
          ],
        ),
      ),
    );
  }

  Widget _noKey(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Add your Gemini API key in Settings to use AI. It is stored only '
        'on this phone.',
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          );
          if (mounted) _start();
        },
        icon: const Icon(Icons.key),
        label: const Text('Open Settings'),
      ),
    ],
  );

  Widget _answer(BuildContext context) => FutureBuilder<AiAnswer>(
    future: _future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snap.hasError) {
        final msg = snap.error is AiException
            ? (snap.error! as AiException).message
            : 'Something went wrong. Please try again.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              msg,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        );
      }
      return _AnswerCard(answer: snap.data!, source: widget.text);
    },
  );
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.source});

  final AiAnswer answer;
  final String source;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final a = answer;
    final (confColor, confText) = switch (a.confidence) {
      'high' => (cs.primary, 'ಹೆಚ್ಚು ವಿಶ್ವಾಸ · high confidence'),
      'medium' => (cs.tertiary, 'ಮಧ್ಯಮ · medium confidence'),
      _ => (cs.error, 'ಕಡಿಮೆ ವಿಶ್ವಾಸ · low confidence'),
    };
    final isKannadaSource = TuluLipi.hasKannada(source);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShareCard(tulu: a.lipi, kannada: a.tulu, roman: a.roman, tuluSize: 38),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Chip(
              avatar: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: cs.error,
              ),
              label: const Text('AI – ಪರಿಶೀಲಿಸಿಲ್ಲ · not verified'),
            ),
            Chip(
              avatar: Icon(Icons.speed, size: 18, color: confColor),
              label: Text(confText),
            ),
          ],
        ),
        if (a.en.isNotEmpty || a.kn.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            [if (a.en.isNotEmpty) a.en, if (a.kn.isNotEmpty) a.kn].join(' · '),
            style: tt.bodyLarge,
          ),
        ],
        if (a.notes.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            a.notes,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => speakText(context, a.tulu),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('ಕೇಳಿ'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () =>
                    copyText(context, '${a.tulu}\n${a.lipi}', 'ತುಳು'),
                icon: const Icon(Icons.copy_rounded),
                label: const Text('ನಕಲಿಸಿ'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            openAddWord(
              context,
              draft: Word(
                id: AppState.newCustomId(),
                tulu: a.tulu,
                roman: a.roman,
                kn: isKannadaSource ? source : a.kn,
                en: isKannadaSource ? a.en : source,
                cat: a.tulu.contains(' ') ? 'phrases' : 'words',
                custom: true,
              ),
            );
          },
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('ನನ್ನ ಪದಗಳಿಗೆ ಸೇರಿಸಿ · Add to my words'),
        ),
      ],
    );
  }
}

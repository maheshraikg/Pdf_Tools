import 'package:flutter/material.dart';

import '../app_state.dart';
import '../lipi/tulu_lipi.dart';
import '../models/word.dart';
import '../widgets/common.dart';

/// Add (or edit) a word of the user's own; saved on the phone and
/// searchable/translatable immediately.
class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key, this.initial, this.prefill, this.draft});

  /// Existing user word to edit.
  final Word? initial;

  /// Text the user searched for: English fills the English meaning,
  /// Kannada fills the Kannada meaning.
  final String? prefill;

  /// Pre-filled new word (e.g. an AI suggestion) saved as a new entry.
  final Word? draft;

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _tulu, _roman, _kn, _en;
  late String _cat;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final w = widget.initial ?? widget.draft;
    final p = widget.prefill?.trim() ?? '';
    final pKannada = p.isNotEmpty && TuluLipi.hasKannada(p);
    _tulu = TextEditingController(text: w?.tulu ?? '');
    _roman = TextEditingController(text: w?.roman ?? '');
    _kn = TextEditingController(text: w?.kn ?? (pKannada ? p : ''));
    _en = TextEditingController(
      text: w?.en ?? (p.isNotEmpty && !pKannada ? p : ''),
    );
    _cat = w?.cat ?? 'words';
  }

  @override
  void dispose() {
    for (final c in [_tulu, _roman, _kn, _en]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final state = AppState.instance;
    final w = Word(
      id: widget.initial?.id ?? AppState.newCustomId(),
      tulu: _tulu.text.trim(),
      roman: _roman.text.trim(),
      kn: _kn.text.trim(),
      en: _en.text.trim(),
      cat: _cat,
      custom: true,
    );
    _editing ? state.updateCustomWord(w) : state.addCustomWord(w);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${w.tulu} ಉಳಿಸಲಾಗಿದೆ · saved')));
    Navigator.of(context).pop(w);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ಅಳಿಸುವುದೇ? · Delete this word?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ಬೇಡ · Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ಅಳಿಸಿ · Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    AppState.instance.deleteCustomWord(widget.initial!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = AppState.instance.categories;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'ಪದ ತಿದ್ದಿ · Edit word' : 'ಪದ ಸೇರಿಸಿ · Add word',
        ),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'ಅಳಿಸಿ · Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ShareCard(
              tulu: TuluLipi.fromKannada(_tulu.text),
              kannada: _tulu.text,
              roman: _roman.text,
              tuluSize: 40,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tulu,
              style: const TextStyle(fontSize: 18),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'ತುಳು ಪದ (ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ) · Tulu word *',
                hintText: 'e.g. ನೀರ್',
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'ತುಳು ಪದ ಬೇಕು · Tulu word is required';
                if (!TuluLipi.hasKannada(t)) {
                  return 'ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ ಬರೆಯಿರಿ · Type it in Kannada script';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roman,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'ರೋಮನ್ · Romanised (optional)',
                hintText: 'e.g. neer',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _kn,
              decoration: const InputDecoration(
                labelText: 'ಕನ್ನಡ ಅರ್ಥ · Kannada meaning',
                hintText: 'e.g. ನೀರು',
              ),
              validator: _needOneMeaning,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _en,
              decoration: const InputDecoration(
                labelText: 'English meaning',
                hintText: 'e.g. water',
              ),
              validator: _needOneMeaning,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: cats.any((c) => c.id == _cat) ? _cat : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ವರ್ಗ · Category'),
              items: [
                for (final c in cats)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      '${c.kn} · ${c.en}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _cat = v ?? 'words'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_editing ? 'ಉಳಿಸಿ · Update' : 'ಸೇರಿಸಿ · Save word'),
            ),
            const SizedBox(height: 12),
            Text(
              'ಈ ಪದ ನಿಮ್ಮ ಫೋನ್‌ನಲ್ಲಿ ಮಾತ್ರ ಉಳಿಯುತ್ತದೆ. ಎಲ್ಲರಿಗೂ ಸೇರಿಸಲು '
              '"ಉಳಿಸಿದವು › ನನ್ನ ಪದಗಳು › Export" ಬಳಸಿ.\n'
              'Saved on this phone only. To add it for everyone, use '
              'Saved › My words › Export and send it in.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String? _needOneMeaning(String? _) =>
      _kn.text.trim().isEmpty && _en.text.trim().isEmpty
      ? 'ಕನ್ನಡ ಅಥವಾ English ಅರ್ಥ ಬೇಕು · Add a Kannada or English meaning'
      : null;
}

/// Opens [AddWordScreen]; returns the saved word, if any.
Future<Word?> openAddWord(
  BuildContext context, {
  Word? initial,
  String? prefill,
  Word? draft,
}) => Navigator.of(context).push<Word>(
  MaterialPageRoute(
    builder: (_) =>
        AddWordScreen(initial: initial, prefill: prefill, draft: draft),
  ),
);

import 'package:flutter/material.dart';

import '../ai/gemini_client.dart';
import '../app_state.dart';

/// Settings: the optional Gemini key for "Ask AI".
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _key = TextEditingController(text: AppState.instance.aiKey);
  final _model = TextEditingController(text: AppState.instance.aiModel);
  bool _show = false;
  bool _testing = false;
  String? _status;

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  void _save() {
    AppState.instance.setAiSettings(key: _key.text, model: _model.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('ಉಳಿಸಲಾಗಿದೆ · Saved')));
  }

  Future<void> _test() async {
    _save();
    final client = AppState.instance.aiClient();
    if (client == null) {
      setState(() => _status = 'Enter a key first.');
      return;
    }
    setState(() {
      _testing = true;
      _status = null;
    });
    try {
      final a = await client.translate('water');
      _status = '✓ Works – "water" → ${a.tulu}';
    } on AiException catch (e) {
      _status = '✗ ${e.message}';
    }
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('ಸೆಟ್ಟಿಂಗ್ಸ್ · Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI ಸಹಾಯ · Ask AI (Gemini)',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (AppState.hasBuiltInAi)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: cs.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI is built in – no key needed. ಕೀ ಬೇಕಾಗಿಲ್ಲ.',
                      style: TextStyle(color: cs.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ),
          Text(
            AppState.hasBuiltInAi
                ? 'Optional: use your own Gemini API key instead of the '
                      'built-in AI (e.g. if the daily limit is reached). The key '
                      'is stored only on this phone.'
                : 'Optional. Paste your own Gemini API key to get AI Tulu '
                      'translations when the dictionary has no answer. The key '
                      'is stored only on this phone and sent only to Google\'s '
                      'Gemini API when you tap "Ask AI". Get a key at '
                      'aistudio.google.com › API keys.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _key,
            obscureText: !_show,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Gemini API key',
              suffixIcon: IconButton(
                tooltip: _show ? 'Hide' : 'Show',
                icon: Icon(_show ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _show = !_show),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Model',
              helperText: 'Default: $kDefaultGeminiModel',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('ಉಳಿಸಿ · Save'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: _testing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bolt),
                  label: const Text('Test'),
                ),
              ),
            ],
          ),
          if (_status != null) ...[const SizedBox(height: 12), Text(_status!)],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              _key.clear();
              _save();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove key'),
          ),
          const SizedBox(height: 8),
          Text(
            'AI answers are not verified and can be wrong – Tulu is a '
            'low-resource language for AI models. The offline dictionary '
            'stays the trusted source.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

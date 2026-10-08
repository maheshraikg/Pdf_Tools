import 'package:flutter/material.dart';

import 'system_keyboard.dart';

/// Guides the user through turning on the Tulu system keyboard so it can be
/// used in WhatsApp and every other app.
class KeyboardSetupCard extends StatefulWidget {
  const KeyboardSetupCard({super.key});

  @override
  State<KeyboardSetupCard> createState() => _KeyboardSetupCardState();
}

class _KeyboardSetupCardState extends State<KeyboardSetupCard>
    with WidgetsBindingObserver {
  KeyboardStatus _status = const KeyboardStatus();
  KeyboardSettings _settings = const KeyboardSettings();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Settings: show the new status.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await SystemKeyboard.status();
    final settings = await SystemKeyboard.settings();
    if (mounted) {
      setState(() {
        _status = s;
        _settings = settings;
      });
    }
  }

  void _update(KeyboardSettings s) {
    setState(() => _settings = s);
    SystemKeyboard.saveSettings(s);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ready = _status.enabled && _status.selected;
    return Card(
      color: ready ? cs.primaryContainer : cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.keyboard_alt_outlined, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WhatsApp ಮತ್ತು ಎಲ್ಲಾ ಆ್ಯಪ್‌ಗಳಲ್ಲಿ · Use in WhatsApp & every app',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Step(
              n: 1,
              done: _status.enabled,
              text: 'Turn on “Tulu Nighantu keyboard” in Settings',
              action: 'ಆನ್ ಮಾಡಿ · Turn on',
              onTap: SystemKeyboard.openSettings,
            ),
            _Step(
              n: 2,
              done: _status.selected,
              text: 'Choose it as your keyboard (or tap 🌐 while typing)',
              action: 'ಆರಿಸಿ · Choose',
              onTap: _status.enabled ? SystemKeyboard.showPicker : null,
            ),
            if (_status.enabled) ...[
              const Divider(height: 20),
              _Toggle(
                title: 'ಕಂಪನ · Vibrate on key press',
                value: _settings.vibrate,
                onChanged: (v) => _update(_settings.copyWith(vibrate: v)),
              ),
              _Toggle(
                title: 'ಶಬ್ದ · Key sound',
                value: _settings.sound,
                onChanged: (v) => _update(_settings.copyWith(sound: v)),
              ),
              _Toggle(
                title: 'Add “ತುಳು ನಿಘಂಟು” under stickers',
                value: _settings.stickerLabel,
                onChanged: (v) => _update(_settings.copyWith(stickerLabel: v)),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Then in any chat: type with the Tulu keys and tap “Sticker” '
              '(everyone can see it) or “Text” (needs a Tulu font). Pages: '
              'ಅ vowels · ಕ ಟ ಪ consonants · ್ಕ ್ಪ joined letters (ಕ್ತ, ತ್ರ) · '
              '೧ ಕ್ಷ ಶ್ರೀ and numbers. '
              'The keyboard does not save or send what you type anywhere else.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    value: value,
    onChanged: onChanged,
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.done,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final int n;
  final bool done;
  final String text;
  final String action;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: done ? const Color(0xFF2E7D32) : cs.primary,
            foregroundColor: Colors.white,
            child: done
                ? const Icon(Icons.check, size: 16)
                : Text('$n', style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          const SizedBox(width: 6),
          if (!done)
            FilledButton(
              onPressed: onTap == null ? null : () => onTap!(),
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

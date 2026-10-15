import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../keyboard/keyboard_setup_card.dart';

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
  const TuluKeyboardScreen({super.key, bool? showSystemKeyboardSetup})
    : _setup = showSystemKeyboardSetup;

  final bool? _setup;

  /// Whether to show the "use in every app" card (Android only).
  bool get showSystemKeyboardSetup => _setup ?? Platform.isAndroid;

  @override
  State<TuluKeyboardScreen> createState() => _TuluKeyboardScreenState();
}

class _TuluKeyboardScreenState extends State<TuluKeyboardScreen> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _cardKey = GlobalKey();
  _CardStyle _style = _CardStyle.red;
  _Page _page = _Page.letters1;

  /// Typing with the phone's own keyboard instead of the keys below.
  bool _phoneKeyboard = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Rewrites the text before the cursor; a selection is replaced.
  void _edit(String Function(String before) change) {
    final v = _text.value;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    final before = v.text.substring(0, sel.start);
    final after = v.text.substring(sel.end);
    final next = change(before);
    _text.value = TextEditingValue(
      text: next + after,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  void _backspace() {
    final sel = _text.selection;
    if (sel.isValid && !sel.isCollapsed) {
      _edit((b) => b);
    } else {
      _edit(backspace);
    }
  }

  String get _beforeCursor {
    final v = _text.value;
    final at = v.selection.isValid ? v.selection.start : v.text.length;
    return v.text.substring(0, at);
  }

  void _togglePhoneKeyboard() {
    setState(() => _phoneKeyboard = !_phoneKeyboard);
    if (_phoneKeyboard) {
      _focus.requestFocus();
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kn = _text.text;
    final lipi = TuluLipi.fromKannada(kn);
    return Scaffold(
      appBar: AppBar(title: const Text('ತುಳು ಕೀಬೋರ್ಡ್ · Tulu keyboard')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              children: [
                if (widget.showSystemKeyboardSetup) ...[
                  const KeyboardSetupCard(),
                  const SizedBox(height: 8),
                ],
                RepaintBoundary(
                  key: _cardKey,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 96),
                    padding: const EdgeInsets.all(16),
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
                        : TuluText(lipi, size: 40, color: _style.ink),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('keyboard-text'),
                  controller: _text,
                  focusNode: _focus,
                  // The keys below type here; the phone keyboard only when
                  // chosen, so it never covers them.
                  readOnly: !_phoneKeyboard,
                  showCursor: true,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'ಕನ್ನಡ ಲಿಪಿಯಲ್ಲಿ · In Kannada script',
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _phoneKeyboard
                              ? 'Tulu keys · ತುಳು ಕೀಲಿಗಳು'
                              : 'Phone keyboard · ಫೋನ್ ಕೀಬೋರ್ಡ್',
                          icon: Icon(
                            _phoneKeyboard
                                ? Icons.grid_view_rounded
                                : Icons.keyboard_alt_outlined,
                          ),
                          onPressed: _togglePhoneKeyboard,
                        ),
                        IconButton(
                          tooltip: 'ಅಳಿಸಿ · Clear',
                          icon: const Icon(Icons.clear),
                          onPressed: () => _text.clear(),
                        ),
                      ],
                    ),
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
                const SizedBox(height: 8),
                Text(
                  'Tip: share as a picture – everyone can see it, even where '
                  'the Tulu-Tigalari font is not installed. "Copy" gives '
                  'Unicode text for phones that have the font.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!_phoneKeyboard) _keyboard(context),
        ],
      ),
    );
  }

  /// The docked keyboard: vowel signs, page tabs, keys and the bottom row.
  Widget _keyboard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final before = _beforeCursor;
    final consonant = lastConsonant(before);
    final canJoin = addOttu(before, 'ಕ') != before;
    final (letters, columns) = switch (_page) {
      _Page.letters1 => (kKeyboardPage1, 7),
      _Page.letters2 => (kKeyboardPage2, 7),
      _Page.ottu => (kKeyboardConsonants, 9),
      _Page.digits => ('೧ ೨ ೩ ೪ ೫ ೬ ೭ ೮ ೯ ೦'.split(' '), 10),
    };
    final rows = [
      for (var i = 0; i < letters.length; i += columns)
        letters.sublist(i, (i + columns).clamp(0, letters.length)),
    ];
    return Material(
      color: cs.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in kVowelSigns)
                      SizedBox(
                        width: 46,
                        child: _Key(
                          kannada: '${consonant ?? '◌'}$s',
                          onTap:
                              consonant == null &&
                                  applySign(before, s) == before
                              ? null
                              : () => _edit((b) => applySign(b, s)),
                          highlight: true,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  for (final p in _Page.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Material(
                          color: p == _page
                              ? cs.primary
                              : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(10),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() => _page = p),
                            child: SizedBox(
                              height: 34,
                              child: Center(
                                child: Text(
                                  p.label,
                                  textScaler: TextScaler.noScaling,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: p == _page
                                        ? cs.onPrimary
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(
                height: 4 * 48,
                child: Column(
                  children: [
                    for (final row in rows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final k in row)
                              Expanded(
                                child: _page == _Page.ottu
                                    ? _Key(
                                        kannada: '್$k',
                                        onTap: canJoin
                                            ? () => _edit((b) => addOttu(b, k))
                                            : null,
                                      )
                                    : _Key(
                                        kannada: k,
                                        onTap: () => _edit((b) => b + k),
                                      ),
                              ),
                            for (var i = row.length; i < columns; i++)
                              const Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                    for (var i = rows.length; i < 4; i++)
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
              SizedBox(
                height: 46,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: FilledButton.tonal(
                          onPressed: () => _edit((b) => '$b '),
                          child: const Text('␣ Space'),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: FilledButton.tonal(
                          key: const ValueKey('keyboard-backspace'),
                          onPressed: _text.text.isEmpty ? null : _backspace,
                          child: const Icon(Icons.backspace_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pages of the in-app keyboard.
enum _Page {
  letters1('ಅ ಕ'),
  letters2('ತ ಯ'),
  ottu('್ಕ'),
  digits('೧೨೩');

  const _Page(this.label);

  final String label;
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
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: highlight ? cs.secondaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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

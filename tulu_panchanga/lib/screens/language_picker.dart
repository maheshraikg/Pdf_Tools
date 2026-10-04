import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/settings.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../panchanga/names.dart';

/// Grid of language tiles, each in its own script.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({
    super.key,
    required this.selected,
    required this.onPick,
  });
  final Lang selected;
  final ValueChanged<Lang> onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final l in Lang.values)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 104,
            decoration: BoxDecoration(
              gradient: l == selected ? TuluColors.flagGradient : null,
              color: l == selected ? null : t.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: l == selected
                    ? Colors.transparent
                    : t.colorScheme.outlineVariant,
              ),
              boxShadow: l == selected
                  ? [
                      BoxShadow(
                        color: TuluColors.red.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onPick(l),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  child: Column(
                    children: [
                      Text(
                        l.label,
                        style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: l == selected ? Colors.white : null,
                        ),
                      ),
                      Text(
                        l.english,
                        style: t.textTheme.labelSmall?.copyWith(
                          color: l == selected
                              ? Colors.white70
                              : t.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One-time sheet after the opening screen: the app starts in Kannada and
/// offers the other languages.
Future<void> showFirstRunLanguageSheet(BuildContext context) async {
  final settings = context.settings;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) {
        final s = S(settings.lang);
        final t = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.translate_rounded,
                  size: 40,
                  color: TuluColors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  s.chooseLanguage,
                  textAlign: TextAlign.center,
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.languageLater,
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                LanguagePicker(
                  selected: settings.lang,
                  onPick: (l) => settings.update((x) => x.lang = l),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('✓  ${settings.lang.label}'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  await settings.update((x) => x.languageChosen = true);
}

/// Shows the first-run sheet once.
void maybeAskLanguage(BuildContext context, AppSettings settings) {
  if (settings.languageChosen) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) showFirstRunLanguageSheet(context);
  });
}

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/strings.dart';

/// App-bar button that switches between Kannada and English.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.settings;
    final toKn = settings.lang == Lang.en;
    return TextButton(
      onPressed: () => settings.lang = toKn ? Lang.kn : Lang.en,
      child: Text(toKn ? 'ಕನ್ನಡ' : 'English'),
    );
  }
}

/// A label + big value line.
class ValueTile extends StatelessWidget {
  const ValueTile(this.label, this.value, {super.key, this.emphasis = false});
  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: t.bodyLarge)),
          const SizedBox(width: 12),
          // Large amounts shrink rather than overflow on small phones.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: (emphasis ? t.titleLarge : t.titleMedium)?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small grey note with an icon.
class Note extends StatelessWidget {
  const Note(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

/// Shows a date picker in the app's locale; [initial] is clamped into
/// [first]..[last].
Future<DateTime?> pickDate(
  BuildContext context,
  DateTime initial, {
  DateTime? first,
  DateTime? last,
}) {
  final f = first ?? DateTime(2000), l = last ?? DateTime(2075);
  final i = initial.isBefore(f) ? f : (initial.isAfter(l) ? l : initial);
  return showDatePicker(
    context: context,
    initialDate: i,
    firstDate: f,
    lastDate: l,
  );
}

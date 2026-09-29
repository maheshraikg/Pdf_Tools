import 'package:flutter/material.dart';

const Color kSeedRed = Color(0xFFC62828);
const Color kAccentAmber = Color(0xFFFFC107);

/// Label badge colours for the parcel bag pattern.
const Color kAirYellow = Color(0xFFFFD600);
const Color kSurfaceBlue = Color(0xFF1565C0);

/// Warning / success colours with good contrast in both themes.
Color warningColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFFB74D) : const Color(0xFFB45309);
Color okColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFF1B5E20);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedRed,
    brightness: brightness,
  ).copyWith(
    secondary: brightness == Brightness.light ? const Color(0xFF7A5900) : kAccentAmber,
    secondaryContainer: brightness == Brightness.light ? const Color(0xFFFFE08A) : const Color(0xFF5C4300),
    tertiary: kAccentAmber,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
  // Slightly larger, heavier text than the M3 defaults: sorting happens fast
  // and often in poor light.
  final t = base.textTheme;
  final text = t.copyWith(
    bodyLarge: t.bodyLarge?.copyWith(fontSize: 18),
    bodyMedium: t.bodyMedium?.copyWith(fontSize: 16),
    bodySmall: t.bodySmall?.copyWith(fontSize: 14),
    labelLarge: t.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleMedium: t.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
    titleLarge: t.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
  );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onPrimary, fontSize: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52), textStyle: text.labelLarge),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52), textStyle: text.labelLarge),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 10),
  );
}

/// Parses "#RRGGBB" / "RRGGBB" / colour names used in scheme files.
Color? parseColour(String? input) {
  if (input == null) return null;
  final s = input.trim().toLowerCase();
  if (s.isEmpty) return null;
  const named = {
    'red': Color(0xFFD32F2F),
    'green': Color(0xFF2E7D32),
    'blue': Color(0xFF1565C0),
    'yellow': Color(0xFFFBC02D),
    'orange': Color(0xFFEF6C00),
    'purple': Color(0xFF6A1B9A),
    'pink': Color(0xFFD81B60),
    'brown': Color(0xFF6D4C41),
    'grey': Color(0xFF616161),
    'gray': Color(0xFF616161),
    'black': Color(0xFF212121),
    'white': Color(0xFFFAFAFA),
    'teal': Color(0xFF00796B),
    'cyan': Color(0xFF0097A7),
    'maroon': Color(0xFF880E4F),
  };
  if (named.containsKey(s)) return named[s];
  final hex = s.replaceFirst('#', '');
  if (RegExp(r'^[0-9a-f]{6}$').hasMatch(hex)) return Color(int.parse('ff$hex', radix: 16));
  return null;
}

String colourToHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Palette offered in the bag editor and used for auto-assigned bag colours.
const List<Color> kBagPalette = [
  Color(0xFFD32F2F), Color(0xFF1565C0), Color(0xFF2E7D32), Color(0xFFEF6C00), //
  Color(0xFF6A1B9A), Color(0xFF00796B), Color(0xFFD81B60), Color(0xFF6D4C41), //
  Color(0xFF455A64), Color(0xFFF9A825), Color(0xFF0097A7), Color(0xFF880E4F),
];

/// Text colour with enough contrast on [bg].
Color onColour(Color bg) => bg.computeLuminance() > 0.45 ? Colors.black : Colors.white;

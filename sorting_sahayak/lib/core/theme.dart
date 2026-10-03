import 'package:flutter/material.dart';

/// Brand palette: deep indigo with saffron highlights, teal for actions and
/// sky blue for air. High contrast in poor light and clear of any
/// organisation's branding.
const Color kNavy = Color(0xFF3730A3); // primary indigo
const Color kIndigoDeep = Color(0xFF1E1B4B);
const Color kIndigoTop = Color(0xFF2E2A85);
const Color kIndigoBottom = Color(0xFF4338CA);
const Color kTeal = Color(0xFF0D9488);
const Color kAmber = Color(0xFFF59E0B);
const Color kSky = Color(0xFF0EA5E9);
const Color kSkyDeep = Color(0xFF0369A1);

/// Vertical gradient under the app bar (seamless with its colour).
LinearGradient headerGradient(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: dark ? const [kIndigoDeep, Color(0xFF2A2670)] : const [kIndigoTop, kIndigoBottom],
  );
}

// Kept for older call sites.
const Color kSeedRed = kNavy;
const Color kAccentAmber = kAmber;

/// Label badge colours for the parcel bag pattern.
const Color kAirYellow = Color(0xFFFFD600);
const Color kSurfaceBlue = Color(0xFF1565C0);

/// Warning / success colours with good contrast in both themes.
Color warningColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
Color okColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: kNavy, brightness: brightness).copyWith(
    primary: dark ? const Color(0xFFA5B4FC) : kNavy,
    onPrimary: dark ? kIndigoDeep : Colors.white,
    primaryContainer: dark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
    onPrimaryContainer: dark ? const Color(0xFFE0E7FF) : kIndigoDeep,
    secondary: dark ? const Color(0xFF5EEAD4) : kTeal,
    onSecondary: dark ? const Color(0xFF042F2E) : Colors.white,
    secondaryContainer: dark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
    onSecondaryContainer: dark ? const Color(0xFFCCFBF1) : const Color(0xFF042F2E),
    tertiary: kAmber,
    surface: dark ? const Color(0xFF0B1020) : const Color(0xFFF4F5FB),
    onSurface: dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A),
    onSurfaceVariant: dark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
    surfaceContainerLowest: dark ? const Color(0xFF0B1220) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF131C31) : Colors.white,
    surfaceContainer: dark ? const Color(0xFF172036) : Colors.white,
    surfaceContainerHigh: dark ? const Color(0xFF1E293B) : const Color(0xFFE9EEF7),
    surfaceContainerHighest: dark ? const Color(0xFF273449) : const Color(0xFFDFE6F2),
    outline: dark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
    outlineVariant: dark ? const Color(0xFF334155) : const Color(0xFFD5DCE8),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
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
  final radius = BorderRadius.circular(16);
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
      backgroundColor: dark ? kIndigoDeep : kIndigoTop,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.titleLarge?.copyWith(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: scheme.outlineVariant)),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      elevation: 3,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant, size: 26),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.secondary,
      foregroundColor: scheme.onSecondary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: scheme.primary, width: 2)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: scheme.outlineVariant),
    ),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 10),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
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

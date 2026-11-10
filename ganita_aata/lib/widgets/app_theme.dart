import 'package:flutter/material.dart';

/// "Night-sky adventure" palette: a deep indigo sky, white text on it, gold
/// for the main action and one two-tone gradient per game. Keep to these.
class AppColors {
  AppColors._();

  // Sky (backgrounds).
  static const night0 = Color(0xFF120B33);
  static const night1 = Color(0xFF241460);
  static const night2 = Color(0xFF3F2185);
  static const onDark = Colors.white;
  static const onDarkSoft = Color(0xFFCBC3FF);
  static const glass = Color(0x1FFFFFFF);
  static const glassBorder = Color(0x40FFFFFF);

  // Accents.
  static const primary = Color(0xFFFFC23D); // gold – main action
  static const primaryDark = Color(0xFFF29A0C);
  static const secondary = Color(0xFF8B6CFF); // violet
  static const secondaryDark = Color(0xFF5F43D6);
  static const good = Color(0xFF34D399); // mint – right answers
  static const goodDark = Color(0xFF0E9F6E);
  static const gentle = Color(0xFFFFB86B); // soft orange instead of "red"
  static const coin = Color(0xFFFFC23D);

  // Text on white surfaces.
  static const ink = Color(0xFF1E1546);
  static const inkSoft = Color(0xFF6E66A3);

  // Light surfaces (parent screens).
  static const sky = Color(0xFFEEEAFF);
  static const cream = Color(0xFFF6F3FF);

  /// One (top, bottom) gradient per game / answer button.
  static const cards = <(Color, Color)>[
    (Color(0xFFFF9A5A), Color(0xFFFF4F8B)), // sunset
    (Color(0xFF3FD5FF), Color(0xFF3E7BFF)), // ocean
    (Color(0xFF5BE7A9), Color(0xFF12B886)), // mint
    (Color(0xFFFFD45C), Color(0xFFFF9F1C)), // mango
    (Color(0xFFB88CFF), Color(0xFF7B4DFF)), // grape
    (Color(0xFFFF7AD9), Color(0xFFB84DFF)), // berry
  ];

  static List<Color> get cardColors => [for (final c in cards) c.$1];

  static (Color, Color) card(int i) => cards[i % cards.length];

  static List<Color> cardGradient(int i) => [card(i).$1, card(i).$2];

  static const goldGradient = [Color(0xFFFFE07A), Color(0xFFFFB21E)];
  static const mintGradient = [Color(0xFF6EF2B8), Color(0xFF14B985)];
}

/// Rounded, playful display font (Kannada + Latin).
const displayFont = 'Baloo';

/// Body text font.
const bodyFont = 'NotoSansKannada';

/// Rounded display fonts for the other Indian scripts (and Urdu), used when a
/// character is not in Baloo Tamma 2.
const scriptFallback = [
  'BalooDeva',
  'BalooTamil',
  'BalooTelugu',
  'BalooMalayalam',
  'BalooBengali',
  'BalooGujarati',
  'BalooGurmukhi',
  'BalooOdia',
  'BalooArabic',
];

/// Extra fallback fonts for screenshot tests (null in the app, where the
/// phone's own fonts are the fallback).
List<String>? debugFontFallback;

List<String> get _displayFallback => [...scriptFallback, ...?debugFontFallback];

TextStyle display(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w800, double? height}) =>
    TextStyle(
      fontFamily: displayFont,
      fontFamilyFallback: _displayFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.15,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.secondary,
    primary: AppColors.secondary,
    onPrimary: Colors.white,
    secondary: AppColors.primary,
    onSecondary: AppColors.ink,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: bodyFont,
    fontFamilyFallback: debugFontFallback,
  );
  final t = base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  TextStyle? d(TextStyle? s, double size, [FontWeight w = FontWeight.w800]) => s?.copyWith(
    fontFamily: displayFont,
    fontFamilyFallback: _displayFallback,
    fontSize: size,
    fontWeight: w,
    height: 1.15,
  );
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.night1,
    textTheme: t.copyWith(
      displaySmall: d(t.displaySmall, 38),
      headlineMedium: d(t.headlineMedium, 30),
      headlineSmall: d(t.headlineSmall, 26),
      titleLarge: d(t.titleLarge, 24, FontWeight.w700),
      titleMedium: d(t.titleMedium, 20, FontWeight.w700),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 18),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 16),
      labelLarge: d(t.labelLarge, 20, FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.onDark,
      centerTitle: true,
      titleTextStyle: display(26, color: AppColors.onDark),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: display(20, weight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        side: const BorderSide(color: AppColors.secondary, width: 2),
        textStyle: display(20, weight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(textStyle: display(18, weight: FontWeight.w700)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentTextStyle: display(18, color: Colors.white, weight: FontWeight.w500),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: display(24),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
    ),
  );
}

/// Calm light theme for the parent screens (Progress, Settings, PIN).
ThemeData buildParentTheme() {
  final t = buildTheme();
  return t.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    appBarTheme: t.appBarTheme.copyWith(
      foregroundColor: AppColors.ink,
      titleTextStyle: display(26),
      backgroundColor: AppColors.cream,
    ),
  );
}

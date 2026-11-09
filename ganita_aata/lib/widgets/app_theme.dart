import 'package:flutter/material.dart';

/// Bright, child-friendly colours.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFFF8A00); // mango orange
  static const primaryDark = Color(0xFFE06A00);
  static const secondary = Color(0xFF7B5CFF); // grape purple
  static const secondaryDark = Color(0xFF5B3FD9);
  static const sky = Color(0xFFE6F4FF);
  static const cream = Color(0xFFFFF7EA);
  static const good = Color(0xFF22C55E);
  static const goodDark = Color(0xFF16A34A);
  static const gentle = Color(0xFFFFB547); // used instead of "red" for mistakes
  static const coin = Color(0xFFFFC21A);
  static const ink = Color(0xFF2B2550);
  static const inkSoft = Color(0xFF6B6690);

  /// Card colours: (light, dark) pairs for gradients and 3D edges.
  static const cards = <(Color, Color)>[
    (Color(0xFFFF7A8A), Color(0xFFE5485F)), // strawberry
    (Color(0xFF4FA3FF), Color(0xFF2B7BE0)), // sky blue
    (Color(0xFF3DDC84), Color(0xFF1FAF62)), // leaf green
    (Color(0xFFFFB627), Color(0xFFE8920B)), // sunflower
    (Color(0xFFA77BFF), Color(0xFF7D4FE6)), // grape
    (Color(0xFF22D3EE), Color(0xFF0BA5C2)), // aqua
  ];

  static List<Color> get cardColors => [for (final c in cards) c.$1];

  static (Color, Color) card(int i) => cards[i % cards.length];
}

/// Rounded, playful display font (Kannada + Latin).
const displayFont = 'Baloo';

/// Body text font.
const bodyFont = 'NotoSansKannada';

/// Extra fallback fonts for screenshot tests (null in the app, where the
/// phone's own fonts are the fallback).
List<String>? debugFontFallback;

TextStyle display(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w800, double? height}) =>
    TextStyle(
      fontFamily: displayFont,
      fontFamilyFallback: debugFontFallback,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height ?? 1.15,
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: Colors.white,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: bodyFont,
    fontFamilyFallback: debugFontFallback,
  );
  final t = base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  TextStyle? d(TextStyle? s, double size, [FontWeight w = FontWeight.w800]) =>
      s?.copyWith(fontFamily: displayFont, fontSize: size, fontWeight: w, height: 1.15);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
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
      foregroundColor: AppColors.ink,
      centerTitle: true,
      titleTextStyle: display(26),
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
        side: const BorderSide(color: AppColors.primary, width: 2),
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

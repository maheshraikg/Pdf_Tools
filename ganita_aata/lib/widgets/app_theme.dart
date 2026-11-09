import 'package:flutter/material.dart';

/// Bright, child-friendly colours and very large text.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFFF7A00); // mango orange
  static const secondary = Color(0xFF6C4CF1); // purple
  static const sky = Color(0xFFE8F4FF);
  static const cream = Color(0xFFFFF8EC);
  static const good = Color(0xFF2EAD5B);
  static const gentle = Color(0xFFFFB74D); // used instead of "red" for mistakes
  static const coin = Color(0xFFFFC107);
  static const ink = Color(0xFF2D2A4A);

  static const cardColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4D96FF),
    Color(0xFF6BCB77),
    Color(0xFFFFB830),
    Color(0xFF9B5DE5),
    Color(0xFF00BBF9),
  ];
}

/// Extra fallback fonts for screenshot tests (null in the app, where the
/// phone's own fonts are the fallback).
List<String>? debugFontFallback;

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
    fontFamily: 'NotoSansKannada',
    fontFamilyFallback: debugFontFallback,
  );
  final t = base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: t.copyWith(
      displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700, fontSize: 24),
      titleMedium: t.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      bodyLarge: t.bodyLarge?.copyWith(fontSize: 19),
      bodyMedium: t.bodyMedium?.copyWith(fontSize: 17),
      labelLarge: t.labelLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'NotoSansKannada',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontFamily: 'NotoSansKannada', fontSize: 22, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: AppColors.primary, width: 2),
        textStyle: const TextStyle(fontFamily: 'NotoSansKannada', fontSize: 20, fontWeight: FontWeight.w700),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : null),
    ),
  );
}

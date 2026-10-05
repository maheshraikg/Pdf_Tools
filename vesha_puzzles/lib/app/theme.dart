/// Colours drawn from Yakshagana costume: kumkum red, turmeric gold,
/// leaf green, lamp-black and areca-sheath cream.
library;

import 'package:flutter/material.dart';

class VeshaColors {
  static const red = Color(0xFFB3261E);
  static const gold = Color(0xFFE0A100);
  static const green = Color(0xFF2E7D32);
  static const black = Color(0xFF1B1411);
  static const cream = Color(0xFFFFF4DE);
  static const saffron = Color(0xFFF57C00);
}

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(
    seedColor: VeshaColors.red,
    brightness: b,
    secondary: VeshaColors.gold,
    tertiary: VeshaColors.green,
    surface: b == Brightness.light
        ? VeshaColors.cream
        : const Color(0xFF1E1714),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

/// Board background and frame colours.
({Color background, Color frame}) boardColors(Brightness b) =>
    b == Brightness.light
    ? (background: const Color(0xFFEFE3CC), frame: const Color(0xFFE2D2B4))
    : (background: const Color(0xFF15100E), frame: const Color(0xFF241C18));

String formatDuration(int ms) {
  final s = ms ~/ 1000;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}

/// Waqt's look: deep emerald with a gold accent, rounded surfaces.
library;

import 'package:flutter/material.dart';

const Color kEmerald = Color(0xFF0B5D46);
const Color kEmeraldDeep = Color(0xFF053B2D);
const Color kTeal = Color(0xFF13806A);
const Color kGold = Color(0xFFE2B84B);
const Color kGoldSoft = Color(0xFFF3DFA2);

/// Extra fallback font families (used by the screenshot tool, where no
/// system fonts for Indian and Arabic scripts exist).
List<String>? debugFontFallback;

/// Gradient of the hero header and the "next prayer" tile.
LinearGradient heroGradient(Brightness b) => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: b == Brightness.light
      ? const [kEmeraldDeep, kEmerald, kTeal]
      : const [Color(0xFF02231B), Color(0xFF07402F), Color(0xFF0B5A48)],
);

ThemeData buildTheme(Brightness b) {
  final light = b == Brightness.light;
  final scheme = ColorScheme.fromSeed(
    seedColor: kEmerald,
    brightness: b,
    primary: light ? kEmerald : const Color(0xFF6FD3B1),
    tertiary: light ? const Color(0xFF8A6A12) : kGold,
    surface: light ? const Color(0xFFF6F8F6) : const Color(0xFF0C1412),
  );
  final radius = BorderRadius.circular(20);
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamilyFallback: debugFontFallback,
  );
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      // Explicit size: base.textTheme has no sizes until Theme.of
      // localises it.
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
        fontFamilyFallback: debugFontFallback,
      ),
      toolbarHeight: 64,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: light ? Colors.white : const Color(0xFF15201D),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: light ? 0.5 : 0.3),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: light ? Colors.white : const Color(0xFF101A17),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 70,
      indicatorColor: scheme.primary.withValues(alpha: 0.14),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12.5,
          fontFamilyFallback: debugFontFallback,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.4),
      space: 1,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Icon(Icons.check, size: 14)
            : null,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light ? Colors.white : const Color(0xFF15201D),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      shape: Border(),
      collapsedShape: Border(),
    ),
  );
}

/// Post-office colours (red and yellow, no logo or emblem), per-scheme
/// accents and the app theme.
library;

import 'package:flutter/material.dart';

import '../domain/models/scheme.dart';

abstract final class Brand {
  /// Postal red.
  static const red = Color(0xFFC8102E);
  static const redDark = Color(0xFF8E0B1F);
  static const redDeep = Color(0xFF5E0614);

  /// Postal yellow.
  static const yellow = Color(0xFFFDB913);
  static const yellowSoft = Color(0xFFFFE7A3);

  static const cream = Color(0xFFFFF8F1);
  static const ink = Color(0xFF2B1B17);

  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [red, redDark, redDeep],
    stops: [0, 0.6, 1],
  );
}

/// Accent colour and icon for each scheme.
extension SchemeStyle on Scheme {
  Color get color => switch (this) {
    Scheme.sb => const Color(0xFF00838F),
    Scheme.rd => const Color(0xFF6A3FA0),
    Scheme.td1 => const Color(0xFFD84315),
    Scheme.td2 => const Color(0xFFC62828),
    Scheme.td3 => const Color(0xFFAD1457),
    Scheme.td5 => Brand.red,
    Scheme.mis => const Color(0xFFEF6C00),
    Scheme.scss => const Color(0xFF2E7D32),
    Scheme.nsc => const Color(0xFF1565C0),
    Scheme.kvp => const Color(0xFF558B2F),
    Scheme.ppf => const Color(0xFF283593),
    Scheme.ssy => const Color(0xFFC2185B),
    Scheme.mssc => const Color(0xFF8E24AA),
  };

  IconData get icon => switch (this) {
    Scheme.sb => Icons.account_balance_wallet_rounded,
    Scheme.rd => Icons.event_repeat_rounded,
    Scheme.td1 ||
    Scheme.td2 ||
    Scheme.td3 ||
    Scheme.td5 => Icons.lock_clock_rounded,
    Scheme.mis => Icons.calendar_month_rounded,
    Scheme.scss => Icons.elderly_rounded,
    Scheme.nsc => Icons.workspace_premium_rounded,
    Scheme.kvp => Icons.agriculture_rounded,
    Scheme.ppf => Icons.shield_rounded,
    Scheme.ssy => Icons.child_care_rounded,
    Scheme.mssc => Icons.woman_rounded,
  };

  /// The colour for text and numbers: lightened on dark backgrounds.
  Color textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? Color.lerp(color, Colors.white, 0.45)!
      : color;

  /// Gradient for headers in this scheme's colour.
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [color, Color.lerp(color, Colors.black, 0.35)!],
  );
}

/// Extra fallback fonts (only set by the screenshot tool, where the test
/// environment has no system Kannada font).
List<String>? debugFontFallback;

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: Brand.red,
        brightness: b,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: dark ? const Color(0xFFFF8A8A) : Brand.red,
        onPrimary: dark ? const Color(0xFF4A0010) : Colors.white,
        secondary: Brand.yellow,
        onSecondary: Brand.ink,
        secondaryContainer: dark ? const Color(0xFF5A4300) : Brand.yellowSoft,
        onSecondaryContainer: dark ? Brand.yellowSoft : Brand.ink,
        surface: dark ? const Color(0xFF1C1314) : Brand.cream,
        surfaceContainerLowest: dark ? const Color(0xFF160E0F) : Colors.white,
        surfaceContainerLow: dark ? const Color(0xFF241A1B) : Colors.white,
      );
  // Larger text and touch targets for senior citizens. Sizes live in the
  // script geometries (Kannada uses "tall"), so scale all three.
  TextTheme big(TextTheme t) => t.apply(fontSizeFactor: 1.1);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamilyFallback: debugFontFallback,
    typography: Typography.material2021(
      platform: TargetPlatform.android,
      colorScheme: scheme,
      englishLike: big(Typography.englishLike2021),
      dense: big(Typography.dense2021),
      tall: big(Typography.tall2021),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontFamilyFallback: debugFontFallback,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: shape.copyWith(
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        shape: shape,
        textStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamilyFallback: debugFontFallback,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: shape,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: dark ? const Color(0xFF5A4300) : Brand.yellowSoft,
      elevation: 3,
      shadowColor: Colors.black26,
      surfaceTintColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          overflow: TextOverflow.ellipsis,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontFamilyFallback: debugFontFallback,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.6),
    ),
  );
}

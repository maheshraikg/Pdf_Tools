/// Tulunadu colours and the app theme.
library;

import 'package:flutter/material.dart';

/// Colours of Tulunadu: the red and yellow of the Tulu flag, Mangalore-tile
/// terracotta, paddy and areca greens, the Arabian sea and temple-lamp gold.
class TuluColors {
  TuluColors._();

  static const red = Color(0xFFB3261E); // Tulu flag red
  static const deepRed = Color(0xFF7A1C17);
  static const turmeric = Color(0xFFF2C94C); // Tulu flag yellow
  static const gold = Color(0xFFE0A100);
  static const terracotta = Color(0xFFC0583A); // Mangalore tiles
  static const paddy = Color(0xFF7CB342);
  static const areca = Color(0xFF2E7D32);
  static const sea = Color(0xFF1E6F9F);
  static const cream = Color(0xFFFFF8EC);
  static const sand = Color(0xFFF6E7CC);
  static const night = Color(0xFF1B1530);
  static const darkSurface = Color(0xFF1E1412);

  /// Warm gradient used for headers and buttons.
  static const flagGradient = LinearGradient(
    colors: [red, Color(0xFFD9481F), gold],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Rounded Kannada/Latin UI font (Baloo Tamma 2).
const String kUiFont = 'Baloo';

/// Text is drawn this much larger than Material defaults (on top of the
/// phone's own font-size setting), for easy reading of Kannada script.
const double kTextScale = 1.15;

/// Wraps the app so all text is [kTextScale] times larger.
Widget scaleText(BuildContext context, Widget? child) {
  final mq = MediaQuery.of(context);
  final user = mq.textScaler.scale(100) / 100;
  return MediaQuery(
    data: mq.copyWith(textScaler: TextScaler.linear(user * kTextScale)),
    child: child ?? const SizedBox.shrink(),
  );
}

/// Extra fallback font families (used by the screenshot tool, where no
/// system Kannada font exists).
List<String>? debugFontFallback;

ThemeData buildTheme(Brightness b) {
  final light = b == Brightness.light;
  final seeded = ColorScheme.fromSeed(seedColor: TuluColors.red, brightness: b);
  final scheme = seeded.copyWith(
    primary: light ? TuluColors.red : const Color(0xFFFFB4A8),
    onPrimary: light ? Colors.white : TuluColors.deepRed,
    primaryContainer: light ? const Color(0xFFFFDAD3) : TuluColors.deepRed,
    secondary: light ? TuluColors.gold : TuluColors.turmeric,
    onSecondary: light ? Colors.white : const Color(0xFF3B2A00),
    secondaryContainer: light
        ? const Color(0xFFFFEDB8)
        : const Color(0xFF4A3800),
    onSecondaryContainer: light
        ? const Color(0xFF3B2A00)
        : const Color(0xFFFFEDB8),
    tertiary: light ? TuluColors.areca : const Color(0xFF9CD67D),
    tertiaryContainer: light
        ? const Color(0xFFDDF3C8)
        : const Color(0xFF1F4A12),
    onTertiaryContainer: light
        ? const Color(0xFF0E2A05)
        : const Color(0xFFDDF3C8),
    surface: light ? TuluColors.cream : TuluColors.darkSurface,
    surfaceContainerLowest: light ? Colors.white : const Color(0xFF170F0D),
    surfaceContainerLow: light
        ? const Color(0xFFFFF3E2)
        : const Color(0xFF26191A),
    surfaceContainer: light ? const Color(0xFFFCEBD6) : const Color(0xFF2D1F1C),
    surfaceContainerHighest: light
        ? const Color(0xFFF1DCC0)
        : const Color(0xFF3B2A26),
  );
  final plain = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: kUiFont,
    fontFamilyFallback: debugFontFallback,
  );
  final base = plain;
  final tt = Typography.material2021(platform: TargetPlatform.android)
      .englishLike
      .merge(plain.textTheme);
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: tt.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.primary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: light ? Colors.white : const Color(0xFF2A1C19),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: light ? const Color(0xFFF1DCC0) : const Color(0xFF4A3530),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: light ? Colors.white : const Color(0xFF231714),
      indicatorColor: light ? const Color(0xFFFFE08A) : TuluColors.deepRed,
      elevation: 3,
      labelTextStyle: WidgetStatePropertyAll(
        tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
  );
}

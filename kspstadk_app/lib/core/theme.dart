import 'package:flutter/material.dart';

/// KSPSTADK design tokens: white rounded cards with soft shadows, green → blue
/// gradient pills, rainbow accents (as on the site's "ಇವುಗಳನ್ನೂ ಓದಿ" block).
class Brand {
  Brand._();

  static const green = Color(0xFF16A34A);
  static const teal = Color(0xFF0EA5A4);
  static const blue = Color(0xFF2563EB);
  static const indigo = Color(0xFF4F46E5);
  static const ink = Color(0xFF0F1324);
  static const muted = Color(0xFF5B6478);

  static const primaryGradient = LinearGradient(
    colors: [green, teal, blue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const headerGradient = LinearGradient(
    colors: [Color(0xFF0F9D58), Color(0xFF0EA5A4), Color(0xFF2563EB), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0, .35, .75, 1],
  );

  static const darkHeaderGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF0F3D63), Color(0xFF1E1B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Pairs used for the rainbow related-post chips and card accents, in the
  /// same order the site uses (red→orange, green→cyan, blue→purple, …).
  static const rainbow = <List<Color>>[
    [Color(0xFFE53935), Color(0xFFFB8C00)],
    [Color(0xFF43A047), Color(0xFF00ACC1)],
    [Color(0xFF1E88E5), Color(0xFF8E24AA)],
    [Color(0xFFD81B60), Color(0xFF8E24AA)],
    [Color(0xFFF4511E), Color(0xFFFFB300)],
    [Color(0xFF00897B), Color(0xFF7CB342)],
    [Color(0xFF3949AB), Color(0xFF00ACC1)],
  ];

  static LinearGradient rainbowAt(int i) =>
      LinearGradient(colors: rainbow[i % rainbow.length], begin: Alignment.centerLeft, end: Alignment.centerRight);

  /// A gradient derived from a single accent colour (subject tiles etc.).
  static LinearGradient tint(Color c) => LinearGradient(
        colors: [Color.lerp(c, Colors.white, .18)!, c],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static const radius = 18.0;
  static const radiusSmall = 12.0;

  static List<BoxShadow> softShadow(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark
        ? const []
        : [
            BoxShadow(color: const Color(0xFF0F1324).withValues(alpha: .06), blurRadius: 18, offset: const Offset(0, 6)),
            BoxShadow(color: const Color(0xFF0F1324).withValues(alpha: .03), blurRadius: 3, offset: const Offset(0, 1)),
          ];
  }
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Poppins';

  /// Poppins has no Kannada glyphs; Noto Sans Kannada (bundled) shapes them.
  static const fallback = ['NotoSansKannada'];

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: Brand.green,
      brightness: b,
      primary: dark ? const Color(0xFF4ADE80) : Brand.green,
      secondary: dark ? const Color(0xFF60A5FA) : Brand.blue,
      tertiary: dark ? const Color(0xFFC4B5FD) : Brand.indigo,
      surface: dark ? const Color(0xFF0E1320) : const Color(0xFFF5F7FB),
    ).copyWith(
      surfaceContainerLowest: dark ? const Color(0xFF151B2B) : Colors.white,
      surfaceContainerLow: dark ? const Color(0xFF182033) : Colors.white,
      surfaceContainer: dark ? const Color(0xFF1C2438) : const Color(0xFFF0F3F9),
      surfaceContainerHigh: dark ? const Color(0xFF232C43) : const Color(0xFFE9EDF5),
      onSurfaceVariant: dark ? const Color(0xFFA9B2C7) : Brand.muted,
      outlineVariant: dark ? const Color(0xFF2A3350) : const Color(0xFFE3E8F1),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: b,
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
    );
    // Kannada needs a taller line box than Latin text.
    final text = base.textTheme.apply(
      fontFamily: fontFamily,
      fontFamilyFallback: fallback,
      bodyColor: dark ? const Color(0xFFE8ECF5) : Brand.ink,
      displayColor: dark ? Colors.white : Brand.ink,
    );
    final tt = text.copyWith(
      headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.35),
      titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.4),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.45),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.45),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.7, fontSize: 16.5),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.6),
      bodySmall: text.bodySmall?.copyWith(height: 1.5),
      labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: tt,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: tt.titleLarge?.copyWith(fontSize: 20),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Brand.radius),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: dark ? 1 : .6)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: tt.labelMedium,
        backgroundColor: scheme.surfaceContainerLowest,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primary.withValues(alpha: .14),
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(tt.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: const StadiumBorder(), textStyle: tt.labelLarge),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: const StadiumBorder(), textStyle: tt.labelLarge),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}

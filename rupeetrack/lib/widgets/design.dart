import 'dart:math' as math;

import 'package:flutter/material.dart';

/// RupeeTrack's design system: a calm neutral base, one confident indigo
/// brand colour, green only for money coming in, amber only for warnings,
/// rounded vector icons and generous spacing.

// ---- Tokens ------------------------------------------------------------------

/// Brand indigo.
const kViolet = Color(0xFF4F46E5);

/// Lighter brand tone (gradient partner, highlights).
const kPink = Color(0xFF6366F1);

/// Positive / money in.
const kLime = Color(0xFF10B981);

/// Informational accent.
const kCyan = Color(0xFF0EA5E9);

/// Warning.
const kOrange = Color(0xFFF59E0B);

const kInk = Color(0xFF0B0D12);

/// Deep indigo of the hero card.
const kAurora = [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF3730A3)];

const double kRadius = 20;
const EdgeInsets kPagePadding = EdgeInsets.symmetric(horizontal: 16);

/// Calm, distinguishable palette for categories and charts.
const List<Color> kChartColors = [
  Color(0xFF6366F1), // indigo
  Color(0xFF14B8A6), // teal
  Color(0xFFF59E0B), // amber
  Color(0xFFF43F5E), // rose
  Color(0xFF0EA5E9), // sky
  Color(0xFF8B5CF6), // violet
  Color(0xFF10B981), // emerald
  Color(0xFF64748B), // slate
];

Color chartColor(int i) => kChartColors[i % kChartColors.length];

/// Extra fallback fonts (screenshot tests only).
List<String>? debugFontFallback;

bool isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

// ---- Surfaces ----------------------------------------------------------------

/// Rounded "glass" panel for every grouped block of content: a soft surface
/// with a hairline border in dark mode and a gentle shadow in light mode.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = isDark(context);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: dark ? const Color(0xFF222632) : const Color(0xFFE6E8EE),
          ),
          boxShadow: dark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: color ?? scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(kRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// The glowing gradient card at the top of a screen, for its headline
/// number. Soft light blobs give it depth.
class HeroPanel extends StatelessWidget {
  const HeroPanel({
    super.key,
    required this.child,
    this.colors,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  final Widget child;
  final List<Color>? colors;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final c = colors ?? kAurora;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kRadius + 6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c,
        ),
        boxShadow: [
          BoxShadow(
            color: c.first.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadius + 6),
        child: Stack(
          children: [
            // A single faint ring for depth, like a premium card.
            Positioned(
              right: -60,
              top: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                    width: 28,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: Colors.white),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label + value for use on a [HeroPanel] (white text).
class HeroFigure extends StatelessWidget {
  const HeroFigure(this.label, this.value, {super.key, this.big = false});

  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: t.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: (big ? t.displaySmall : t.titleMedium)?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: big ? -1 : -0.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small rounded label, e.g. "+12.4%" or "Due in 3 days".
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark(context) ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded progress bar; the fill is a gradient unless [color] is given.
class Meter extends StatelessWidget {
  const Meter({super.key, required this.value, this.color, this.height = 10});

  /// 0..1 (values above 1 show a full bar).
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: scheme.surfaceContainerHighest),
            ),
            FractionallySizedBox(
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(height),
                  color: color ?? scheme.primary,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon in a softly tinted rounded square.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 42});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: isDark(context) ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: c, size: size * 0.5),
    );
  }
}

/// Pill-shaped button filled with the aurora gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: kViolet.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Charts ------------------------------------------------------------------

class DonutSlice {
  const DonutSlice(this.value, this.color);
  final double value;
  final Color color;
}

/// Ring chart with rounded segment ends and an optional centre label.
class Donut extends StatelessWidget {
  const Donut({
    super.key,
    required this.slices,
    this.size = 136,
    this.thickness = 18,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final double thickness;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices,
          thickness,
          Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.thickness, this.track);

  final List<DonutSlice> slices;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arc = rect.deflate(thickness / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      arc,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = track,
    );
    final total = slices.fold<double>(0, (s, x) => s + math.max(0, x.value));
    if (total <= 0) return;
    // Room for the rounded caps between segments.
    final gap = slices.length > 1 ? thickness / (size.width / 2) : 0.0;
    var start = -math.pi / 2;
    for (final s in slices) {
      if (s.value <= 0) continue;
      final sweep = s.value / total * math.pi * 2;
      final visible = math.max(0.001, sweep - gap);
      canvas.drawArc(
        arc,
        start + gap / 2,
        visible,
        false,
        paint..color = s.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.track != track;
}

/// Column bars for a short series (e.g. last six months of spending); the
/// latest bar glows with the gradient.
class MiniBars extends StatelessWidget {
  const MiniBars({
    super.key,
    required this.values,
    required this.labels,
    this.height = 96,
    this.highlightLast = true,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final bool highlightLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final max = values.fold<double>(0, math.max);
    return SizedBox(
      height: height + 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: max <= 0
                        ? 6
                        : math.max(6, values[i] / max * height),
                    margin: const EdgeInsets.symmetric(horizontal: 7),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: highlightLast && i == values.length - 1
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---- Theme -------------------------------------------------------------------

/// App-wide Material 3 theme in the RupeeTrack style.
ThemeData buildAppTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final base = ColorScheme.fromSeed(seedColor: kViolet, brightness: b);
  final scheme = base.copyWith(
    primary: dark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
    onPrimaryContainer: dark
        ? const Color(0xFFE0E7FF)
        : const Color(0xFF312E81),
    secondary: dark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
    tertiary: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
    tertiaryContainer: dark ? const Color(0xFF052E25) : const Color(0xFFECFDF5),
    onTertiaryContainer: dark
        ? const Color(0xFFA7F3D0)
        : const Color(0xFF065F46),
    error: dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
    errorContainer: dark ? const Color(0xFF3B1212) : const Color(0xFFFEF2F2),
    onSurface: dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
    onSurfaceVariant: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
    surface: dark ? kInk : const Color(0xFFF6F7F9),
    surfaceContainerLowest: dark ? const Color(0xFF0E1016) : Colors.white,
    surfaceContainerLow: dark ? const Color(0xFF141720) : Colors.white,
    surfaceContainer: dark ? const Color(0xFF181B25) : const Color(0xFFF1F3F7),
    surfaceContainerHigh: dark
        ? const Color(0xFF1D212C)
        : const Color(0xFFEDEFF4),
    surfaceContainerHighest: dark
        ? const Color(0xFF262B38)
        : const Color(0xFFE4E7EE),
    outline: dark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
    outlineVariant: dark ? const Color(0xFF262B38) : const Color(0xFFE2E5EC),
  );
  final typography = Typography.material2021(
    platform: TargetPlatform.android,
    colorScheme: scheme,
  );
  final text = (dark ? typography.white : typography.black).apply(
    fontFamily: 'Inter',
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    fontFamilyFallback: debugFontFallback,
    // Inter reads best with tight tracking; Material's default letter
    // spacing (up to 0.5) makes it look loose and unpolished.
    textTheme: _tight(text).copyWith(
      titleLarge: _tight(text).titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: _tight(text).titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: _tight(text).titleSmall
          ?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: _tight(text).labelLarge
          ?.copyWith(fontWeight: FontWeight.w600),
    ),
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: text.headlineSmall?.copyWith(
        fontFamily: 'Inter',
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: dark ? const Color(0xFF0F1117) : Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
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
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primaryContainer,
      labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        textStyle: text.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(rounded),
        textStyle: WidgetStatePropertyAll(
          text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

TextTheme _tight(TextTheme t) {
  TextStyle? f(TextStyle? s, double spacing) =>
      s?.copyWith(letterSpacing: spacing);
  return t.copyWith(
    displayLarge: f(t.displayLarge, -1.2),
    displayMedium: f(t.displayMedium, -1),
    displaySmall: f(t.displaySmall, -0.8),
    headlineLarge: f(t.headlineLarge, -0.6),
    headlineMedium: f(t.headlineMedium, -0.5),
    headlineSmall: f(t.headlineSmall, -0.4),
    titleLarge: f(t.titleLarge, -0.3),
    titleMedium: f(t.titleMedium, -0.1),
    titleSmall: f(t.titleSmall, 0),
    bodyLarge: f(t.bodyLarge, 0),
    bodyMedium: f(t.bodyMedium, 0),
    bodySmall: f(t.bodySmall, 0),
    labelLarge: f(t.labelLarge, 0),
    labelMedium: f(t.labelMedium, 0),
    labelSmall: f(t.labelSmall, 0.1),
  );
}

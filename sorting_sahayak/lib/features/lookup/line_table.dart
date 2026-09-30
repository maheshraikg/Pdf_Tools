import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/live_search.dart';

/// The whole line in position order: "5  Naravi  574109".
class LineTable extends StatelessWidget {
  const LineTable({super.key, required this.stops, required this.colour, required this.onDark, required this.matched, required this.onPin});

  final List<LineStop> stops;
  final Color colour;
  final bool onDark;
  final Set<String> matched;
  final ValueChanged<String> onPin;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final fg = onDark ? onColour(colour) : c.onSurface;
    return Column(
      key: const ValueKey('line_table'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in stops)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: s.pins.any(matched.contains)
                  ? (onDark
                        ? Colors.white.withValues(alpha: 0.28)
                        : Color.alphaBlend(colour.withValues(alpha: 0.22), c.surfaceContainerLowest))
                  : (onDark ? Colors.white.withValues(alpha: 0.10) : c.surfaceContainerHigh.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: s.position.isEmpty ? Colors.transparent : colour, shape: BoxShape.circle),
                  child: Text(
                    s.position.isEmpty ? '–' : s.position,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: s.position.isEmpty ? fg : onColour(colour)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.name,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: fg),
                  ),
                ),
                for (final p in s.pins.take(3))
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: RegExp(r'^\d{6}$').hasMatch(p) ? () => onPin(p) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: fg,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

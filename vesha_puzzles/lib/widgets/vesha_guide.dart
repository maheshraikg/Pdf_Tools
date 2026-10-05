/// Vesha, the guide: a young Yakshagana performer who greets the player,
/// gives tips and introduces stories.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../packs/content.dart';

class VeshaGuide extends StatelessWidget {
  const VeshaGuide({
    super.key,
    required this.line,
    this.size = 88,
    this.onTap,
    this.compact = false,
  });

  final GuideLine? line;
  final double size;
  final VoidCallback? onTap;
  final bool compact;

  /// Picks a line whose id starts with [prefix]; stable for a given [salt].
  static GuideLine? pick(Content c, String prefix, {int salt = 0}) {
    final l = c.linesWithPrefix(prefix).toList();
    if (l.isEmpty) return null;
    return l[salt.abs() % l.length];
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = line;
    if (l == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final img = app.content.guide.imageFor(l.mood);
    final avatar = SizedBox.square(
      dimension: size,
      child: img != null
          ? Image.asset(img, fit: BoxFit.contain, excludeFromSemantics: true)
          : CustomPaint(painter: _FallbackVesha(scheme.primary)),
    );
    return Semantics(
      label: 'Vesha',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            avatar,
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                margin: EdgeInsets.only(bottom: size * 0.25),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: Text(
                  l.text.of(app.settings.lang),
                  maxLines: compact ? 3 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                  style: TextStyle(
                    color: scheme.onSecondaryContainer,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple drawn stand-in if the guide images are missing.
class _FallbackVesha extends CustomPainter {
  _FallbackVesha(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height * 0.6);
    final r = s.width * 0.28;
    // Crown fan.
    final crown = Paint()..color = const Color(0xFFE0A100);
    for (var i = 0; i < 9; i++) {
      final a = math.pi + i * math.pi / 8;
      canvas.drawCircle(
        c + Offset(math.cos(a), math.sin(a)) * r * 1.35,
        r * 0.28,
        crown,
      );
    }
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF2B98A));
    canvas.drawCircle(
      c + Offset(-r * 0.35, -r * 0.1),
      r * 0.1,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      c + Offset(r * 0.35, -r * 0.1),
      r * 0.1,
      Paint()..color = Colors.black,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, r * 0.2), radius: r * 0.4),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.1,
    );
  }

  @override
  bool shouldRepaint(_FallbackVesha old) => old.color != color;
}

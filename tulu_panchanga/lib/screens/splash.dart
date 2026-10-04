import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../art/festival_art.dart';
import '../art/kambala.dart';
import '../lipi/tulu_lipi.dart';

/// Animated opening screen (always in Kannada): Tulu-flag colours, a
/// Yakshagana crown, the title, a Tulu-lipi watermark and a Kambala race.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _intro.forward().whenComplete(_finish);
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  Animation<double> _seg(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(a, b, curve: c),
      );

  @override
  Widget build(BuildContext context) {
    final art = _seg(0.0, 0.45, Curves.elasticOut);
    final title = _seg(0.25, 0.55);
    final sub = _seg(0.4, 0.7);
    final t = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: _finish,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([_intro, _loop]),
          builder: (context, _) => CustomPaint(
            painter: _SplashBackground(_loop.value, _intro.value),
            child: SafeArea(
              child: Stack(
                children: [
                  // Tulu-lipi "ತುಳು" watermark.
                  Align(
                    alignment: const Alignment(0, -0.05),
                    child: Opacity(
                      opacity: 0.12 * title.value,
                      child: Text(
                        TuluLipi.fromKannada('ತುಳು'),
                        style: const TextStyle(
                          fontFamily: kTuluFontFamily,
                          fontSize: 190,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: art.value.clamp(0.0, 1.2),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(48),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x66000000),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const FestivalArt(
                              kind: ArtKind.yakshagana,
                              size: 170,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Opacity(
                          opacity: title.value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - title.value)),
                            child: Text(
                              'ತುಳು ಪಂಚಾಂಗ',
                              style: t.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                shadows: const [
                                  Shadow(blurRadius: 12, color: Colors.black38),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: sub.value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - sub.value)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                'ತುಳುನಾಡಿನ ದಿನ · ಹಬ್ಬ · ಮುಹೂರ್ತ',
                                style: t.titleMedium?.copyWith(
                                  color: TuluColors.turmeric,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.97),
                    child: Opacity(
                      opacity: sub.value,
                      child: Text(
                        'ಜೈ ತುಳುನಾಡ್',
                        style: t.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
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

class _SplashBackground extends CustomPainter {
  _SplashBackground(this.t, this.intro);
  final double t;
  final double intro;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7A1C17), TuluColors.red, Color(0xFFE0641F)],
        ).createShader(rect),
    );

    // Slowly turning sun rays behind the crown.
    final center = Offset(w / 2, h * 0.40);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(t * math.pi / 6);
    final ray = Paint()..color = TuluColors.turmeric.withValues(alpha: 0.10);
    for (var i = 0; i < 16; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 8);
      final p = Path()
        ..moveTo(-24, 0)
        ..lineTo(0, -h)
        ..lineTo(24, 0)
        ..close();
      canvas.drawPath(p, ray);
      canvas.restore();
    }
    canvas.restore();
    canvas.drawCircle(
      center,
      150,
      Paint()
        ..shader = RadialGradient(
          colors: [
            TuluColors.turmeric.withValues(alpha: 0.35),
            TuluColors.turmeric.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 150)),
    );

    // Bunting dropping in from the top.
    final drop = Curves.easeOutBack.transform(intro.clamp(0.0, 0.35) / 0.35);
    final n = (w / 26).floor();
    for (var i = 0; i < n; i++) {
      final x0 = w * i / n, x1 = w * (i + 1) / n;
      double y(double x) => (-30 + 50 * drop) + 14 * math.sin(math.pi * x / w);
      final swing = 3 * math.sin((t * 4 + i / n) * 2 * math.pi);
      final tri = Path()
        ..moveTo(x0 + 2, y(x0))
        ..lineTo(x1 - 2, y(x1))
        ..lineTo((x0 + x1) / 2 + swing, y((x0 + x1) / 2) + 20)
        ..close();
      canvas.drawPath(
        tri,
        Paint()..color = i.isEven ? TuluColors.turmeric : Colors.white,
      );
    }

    // Paddy strip and Kambala race at the bottom.
    final ground = h * 0.86;
    canvas.drawRect(
      Rect.fromLTRB(0, ground, w, h),
      Paint()..color = const Color(0xFF6E9E3A),
    );
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var row = 0; row < 3; row++) {
      final yy = ground + 10 + row * 12.0;
      final p = Path()..moveTo(0, yy);
      for (var x = 0.0; x <= w; x += 12) {
        p.lineTo(x, yy + 3 * math.sin(x / 20 + t * 2 * math.pi * 3 + row));
      }
      canvas.drawPath(p, ripple);
    }
    final x = -80 + (w + 160) * ((t * 1.25) % 1);
    paintKambala(canvas, Offset(x, ground + 16), 1.25, (t * 12) % 1);
  }

  @override
  bool shouldRepaint(_SplashBackground old) => old.t != t || old.intro != intro;
}

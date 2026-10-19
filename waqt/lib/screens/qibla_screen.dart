import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app/scope.dart';
import '../core/qibla.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, required this.active});

  /// Whether the tab is visible (sensors are only read then).
  final bool active;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<AccelerometerEvent>? _acc;
  StreamSubscription<MagnetometerEvent>? _mag;
  ({double x, double y, double z})? _a, _m;
  final _smoother = AngleSmoother();
  double? _heading;
  bool _noSensor = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _listen();
  }

  @override
  void didUpdateWidget(QiblaScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _listen();
    if (!widget.active && old.active) _stop();
  }

  void _stop() {
    _acc?.cancel();
    _mag?.cancel();
    _acc = null;
    _mag = null;
  }

  void _listen() {
    _stop();
    const period = Duration(milliseconds: 60);
    _acc = accelerometerEventStream(samplingPeriod: period).listen(
      (e) => _a = (x: e.x, y: e.y, z: e.z),
      onError: (_) => setState(() => _noSensor = true),
      cancelOnError: true,
    );
    _mag = magnetometerEventStream(samplingPeriod: period).listen(
      (e) {
        _m = (x: e.x, y: e.y, z: e.z);
        final a = _a;
        if (a == null) return;
        final h = compassHeading(a, _m!);
        if (h != null && mounted) setState(() => _heading = _smoother.add(h));
      },
      onError: (_) => setState(() => _noSensor = true),
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  bool _wasAligned = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final place = settings.place;
    final bearing = qiblaBearing(place.latitude, place.longitude);
    final km = kaabaDistanceKm(place.latitude, place.longitude);
    final t = Theme.of(context).textTheme;
    final heading = _heading;
    final rel = heading == null ? null : (bearing - heading + 360) % 360;
    final aligned = rel != null && (rel < 3 || rel > 357);
    if (aligned && !_wasAligned) HapticFeedback.heavyImpact();
    _wasAligned = aligned;

    // How far to turn, and which way (rel < 180: the Qibla is to the right).
    Widget? guidance;
    if (rel != null && !aligned) {
      final right = rel < 180;
      final deg = right ? rel : 360 - rel;
      guidance = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            right ? Icons.rotate_right : Icons.rotate_left,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            '${deg.round()}°',
            style: t.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.qibla)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: heroGradient(Theme.of(context).brightness),
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
                  child: Column(
                    children: [
                      Text(
                        '${bearing.toStringAsFixed(0)}°',
                        style: t.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        s.qiblaBearing(bearing.toStringAsFixed(1)),
                        style: t.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      if (_noSensor)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            s.noCompass,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        )
                      else
                        // Facing the Qibla: the dial glows gold and grows.
                        AnimatedScale(
                          scale: aligned ? 1.04 : 1,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutBack,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kGold.withValues(
                                    alpha: aligned ? 0.55 : 0,
                                  ),
                                  blurRadius: aligned ? 36 : 0,
                                  spreadRadius: aligned ? 4 : 0,
                                ),
                              ],
                            ),
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                child: CustomPaint(
                                  painter: _CompassPainter(
                                    heading: heading,
                                    bearing: bearing,
                                    aligned: aligned,
                                    labelStyle:
                                        t.titleMedium ?? const TextStyle(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 36,
                        child: Center(
                          child: aligned
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kGold,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    s.facingQibla,
                                    style: t.labelLarge?.copyWith(
                                      color: kEmeraldDeep,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : guidance,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const IconBadge(Icons.place),
                  title: Text(place.label(s.ml)),
                  subtitle: Text(s.distanceToKaaba(km.round().toString())),
                ),
                const Divider(indent: 64),
                ListTile(
                  leading: const IconBadge(Icons.info_outline),
                  subtitle: Text(s.qiblaHelp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dial that turns with the phone: ticks, N/E/S/W, and a gold Kaaba marker
/// at the Qibla bearing; the top marker is the phone's heading.
class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.heading,
    required this.bearing,
    required this.aligned,
    required this.labelStyle,
  });
  final double? heading;
  final double bearing;
  final bool aligned;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;

    // Glow when facing the Qibla.
    if (aligned) {
      canvas.drawCircle(
        c,
        r + 4,
        Paint()
          ..color = kGold.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.04),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = aligned ? kGold : Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 3 : 1.5,
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-(heading ?? 0) * math.pi / 180);
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final major = i % 18 == 0;
      final len = major ? 14.0 : (i % 2 == 0 ? 8.0 : 4.0);
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        dir * (r - len - 4),
        dir * (r - 4),
        Paint()
          ..color = Colors.white.withValues(alpha: major ? 0.9 : 0.45)
          ..strokeWidth = major ? 2 : 1,
      );
    }
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: labelStyle.copyWith(
            color: i == 0 ? kGold : Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = Offset(math.sin(a), -math.cos(a)) * (r - 34);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // Needle to the Kaaba.
    final qa = bearing * math.pi / 180;
    final qd = Offset(math.sin(qa), -math.cos(qa));
    canvas.drawLine(
      Offset.zero,
      qd * (r - 52),
      Paint()
        ..color = kGold
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final kaaba = Rect.fromCenter(center: qd * (r - 52), width: 22, height: 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(kaaba, const Radius.circular(3)),
      Paint()..color = const Color(0xFF111111),
    );
    canvas.drawRect(
      Rect.fromLTWH(kaaba.left, kaaba.top + 5, kaaba.width, 3.5),
      Paint()..color = kGold,
    );
    canvas.restore();

    // Phone's heading marker and hub.
    final top = Path()
      ..moveTo(c.dx, c.dy - r - 4)
      ..lineTo(c.dx - 9, c.dy - r + 12)
      ..lineTo(c.dx + 9, c.dy - r + 12)
      ..close();
    canvas.drawPath(top, Paint()..color = aligned ? kGold : Colors.white);
    canvas.drawCircle(c, 7, Paint()..color = kGold);
    canvas.drawCircle(c, 3, Paint()..color = kEmeraldDeep);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading ||
      old.bearing != bearing ||
      old.aligned != aligned ||
      old.labelStyle != labelStyle;
}

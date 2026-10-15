import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app/scope.dart';
import '../core/qibla.dart';

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

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final place = settings.place;
    final bearing = qiblaBearing(place.latitude, place.longitude);
    final km = kaabaDistanceKm(place.latitude, place.longitude);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final heading = _heading;
    final rel = heading == null ? null : (bearing - heading + 360) % 360;
    final aligned = rel != null && (rel < 3 || rel > 357);

    return Scaffold(
      appBar: AppBar(title: Text(s.qibla)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            s.qiblaBearing(bearing.toStringAsFixed(1)),
            style: t.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            '${place.label(s.ml)} · ${s.distanceToKaaba(km.round().toString())}',
            style: t.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_noSensor)
            Text(s.noCompass, textAlign: TextAlign.center)
          else
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _CompassPainter(
                    heading: heading,
                    bearing: bearing,
                    scheme: scheme,
                    aligned: aligned,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (aligned)
            Text(
              s.facingQibla,
              style: t.titleMedium?.copyWith(color: scheme.primary),
              textAlign: TextAlign.center,
            ),
          if (heading != null)
            Text(
              '${heading.round()}°',
              style: t.bodyLarge,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          Text(s.qiblaHelp, style: t.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.heading,
    required this.bearing,
    required this.scheme,
    required this.aligned,
  });
  final double? heading;
  final double bearing;
  final ColorScheme scheme;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    final dial = Paint()
      ..color = scheme.surfaceContainerHighest
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, r, dial);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = aligned ? scheme.primary : scheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 4 : 1.5,
    );

    // Dial rotates so north points to magnetic north (top = phone top).
    final rot = -(heading ?? 0) * math.pi / 180;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final tick = Paint()
      ..color = scheme.onSurfaceVariant
      ..strokeWidth = 1;
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final len = i % 18 == 0 ? 14.0 : (i % 2 == 0 ? 8.0 : 4.0);
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(dir * (r - len), dir * (r - 2), tick);
    }
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: i == 0 ? scheme.error : scheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final p = Offset(math.sin(a), -math.cos(a)) * (r - 30);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }

    // Qibla needle with a Kaaba marker.
    final qa = bearing * math.pi / 180;
    final qd = Offset(math.sin(qa), -math.cos(qa));
    final needle = Paint()
      ..color = scheme.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, qd * (r - 44), needle);
    final kaaba = Rect.fromCenter(center: qd * (r - 44), width: 18, height: 18);
    canvas.drawRect(kaaba, Paint()..color = const Color(0xFF222222));
    canvas.drawRect(
      Rect.fromLTWH(kaaba.left, kaaba.top + 4, kaaba.width, 3),
      Paint()..color = const Color(0xFFD4AF37),
    );
    canvas.restore();

    // Fixed marker for the phone's top edge.
    final top = Paint()..color = scheme.onSurface;
    final path = Path()
      ..moveTo(c.dx, c.dy - r - 2)
      ..lineTo(c.dx - 8, c.dy - r + 12)
      ..lineTo(c.dx + 8, c.dy - r + 12)
      ..close();
    canvas.drawPath(path, top);
    canvas.drawCircle(c, 5, Paint()..color = scheme.onSurface);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.heading != heading ||
      old.bearing != bearing ||
      old.aligned != aligned ||
      old.scheme != scheme;
}

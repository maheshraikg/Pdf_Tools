/// Cute animated festival illustrations, drawn in code (no image assets).
///
/// Each drawing works in a 100×100 box and takes an animation phase t in
/// [0, 1) for gentle looping motion (flame flicker, swaying, twinkling).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../panchanga/festivals.dart';

enum ArtKind {
  diya,
  ganesha,
  naga,
  kalasha,
  flute,
  yakshagana,
  paddy,
  rain,
  tulasi,
  sun,
  linga,
  holi,
  moon,
  newMoon,
  bow,
}

/// Picks the illustration for a festival.
ArtKind artFor(Festival f) {
  switch (f.id) {
    case 'deepavali_amavasya':
    case 'naraka_chaturdashi':
    case 'bali_padyami':
    case 'mahalaya_amavasya':
      return ArtKind.diya;
    case 'ganesh_chaturthi':
    case 'sankashti':
      return ArtKind.ganesha;
    case 'nagara_panchami':
    case 'subrahmanya_shashti':
      return ArtKind.naga;
    case 'ugadi':
    case 'akshaya_tritiya':
    case 'swarna_gowri':
    case 'varamahalakshmi':
    case 'nooli_hunnime':
    case 'guru_purnima':
      return ArtKind.kalasha;
    case 'janmashtami':
    case 'krishna_jayanti_udupi':
    case 'vaikuntha_ekadashi':
      return ArtKind.flute;
    case 'navaratri':
    case 'sharada_puja':
    case 'durgashtami':
    case 'mahanavami':
    case 'vijayadashami':
      return ArtKind.yakshagana;
    case 'bisu':
    case 'keddasa':
    case 'pattanaje':
      return ArtKind.paddy;
    case 'aati_amavasye':
      return ArtKind.rain;
    case 'tulasi_puja':
      return ArtKind.tulasi;
    case 'makara_sankranti':
    case 'tula_sankramana':
    case 'ratha_saptami':
      return ArtKind.sun;
    case 'shivaratri':
    case 'pradosha':
      return ArtKind.linga;
    case 'holi':
      return ArtKind.holi;
    case 'ramanavami':
    case 'hanumad_vrata':
      return ArtKind.bow;
    case 'purnima':
    case 'ekadashi':
      return ArtKind.moon;
    case 'amavasya':
      return ArtKind.newMoon;
  }
  return switch (f.category) {
    FestivalCategory.sankramana => ArtKind.sun,
    FestivalCategory.vrata => ArtKind.moon,
    FestivalCategory.tulu => ArtKind.paddy,
    FestivalCategory.major => ArtKind.diya,
  };
}

/// Soft background colour behind each illustration.
Color artBackground(ArtKind k) => switch (k) {
  ArtKind.diya => const Color(0xFF3A1D3F),
  ArtKind.ganesha => const Color(0xFFFFE6B3),
  ArtKind.naga => const Color(0xFFD9F0C8),
  ArtKind.kalasha => const Color(0xFFFFE0D6),
  ArtKind.flute => const Color(0xFFD5E8FF),
  ArtKind.yakshagana => const Color(0xFF5B1A1A),
  ArtKind.paddy => const Color(0xFFE6F4C7),
  ArtKind.rain => const Color(0xFF9FB8CC),
  ArtKind.tulasi => const Color(0xFFE3F2D5),
  ArtKind.sun => const Color(0xFFFFE9A8),
  ArtKind.linga => const Color(0xFF243B5E),
  ArtKind.holi => const Color(0xFFFFF1F6),
  ArtKind.moon => const Color(0xFF1F2A4D),
  ArtKind.newMoon => const Color(0xFF141833),
  ArtKind.bow => const Color(0xFFFFE3C2),
};

/// An illustration in a rounded tile; animated unless [animate] is false or
/// the system asks for reduced motion.
class FestivalArt extends StatefulWidget {
  const FestivalArt({
    super.key,
    required this.kind,
    this.size = 56,
    this.animate = true,
    this.circle = false,
  });

  FestivalArt.of(
    Festival f, {
    Key? key,
    double size = 56,
    bool animate = true,
    bool circle = false,
  }) : this(
         key: key,
         kind: artFor(f),
         size: size,
         animate: animate,
         circle: circle,
       );

  final ArtKind kind;
  final double size;
  final bool animate;
  final bool circle;

  @override
  State<FestivalArt> createState() => _FestivalArtState();
}

class _FestivalArtState extends State<FestivalArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduce) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
      _c.value = 0.3;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.circle ? widget.size / 2 : widget.size * 0.26;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) =>
                CustomPaint(painter: _ArtPainter(widget.kind, _c.value)),
          ),
        ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.kind, this.t);
  final ArtKind kind;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = artBackground(kind));
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    // Whole-figure bounce and breathing, like a looping sticker GIF.
    final bounce = math.sin(t * 4 * math.pi);
    canvas.translate(50, 54);
    canvas.scale(1 + 0.035 * bounce, 1 - 0.025 * bounce);
    canvas.translate(-50, -54 - 3.5 * bounce.abs());
    final draw = switch (kind) {
      ArtKind.diya => _diya,
      ArtKind.ganesha => _ganesha,
      ArtKind.naga => _naga,
      ArtKind.kalasha => _kalasha,
      ArtKind.flute => _flute,
      ArtKind.yakshagana => _yakshagana,
      ArtKind.paddy => _paddy,
      ArtKind.rain => _rain,
      ArtKind.tulasi => _tulasi,
      ArtKind.sun => _sun,
      ArtKind.linga => _linga,
      ArtKind.holi => _holi,
      ArtKind.moon => _moon,
      ArtKind.newMoon => _newMoon,
      ArtKind.bow => _bow,
    };
    draw(canvas, t);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ArtPainter old) => old.t != t || old.kind != kind;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Paint _p(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..isAntiAlias = true;

double _wave(double t, [double phase = 0]) =>
    math.sin((t + phase) * 2 * math.pi);

/// Two dot eyes and a smile: everything is cuter with a face.
void _face(
  Canvas c,
  Offset center,
  double scale, {
  Color ink = const Color(0xFF3B2314),
}) {
  final eye = _p(ink);
  c.drawCircle(center + Offset(-5 * scale, -1 * scale), 1.6 * scale, eye);
  c.drawCircle(center + Offset(5 * scale, -1 * scale), 1.6 * scale, eye);
  c.drawArc(
    Rect.fromCenter(
      center: center + Offset(0, 2 * scale),
      width: 7 * scale,
      height: 5 * scale,
    ),
    0.2,
    math.pi - 0.4,
    false,
    _stroke(ink, 1.2 * scale),
  );
  final blush = _p(const Color(0x66FF6F7D));
  c.drawCircle(center + Offset(-8 * scale, 3 * scale), 2.2 * scale, blush);
  c.drawCircle(center + Offset(8 * scale, 3 * scale), 2.2 * scale, blush);
}

void _sparkle(Canvas c, Offset o, double r, Color color) {
  final path = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
    ..close();
  c.drawPath(path, _p(color));
}

void _sparkles(Canvas c, double t, List<Offset> at, Color color) {
  for (var i = 0; i < at.length; i++) {
    final s = (0.5 + 0.5 * _wave(t, i / at.length)).clamp(0.0, 1.0);
    _sparkle(c, at[i], 1.5 + 2.5 * s, color.withValues(alpha: 0.4 + 0.6 * s));
  }
}

// ---------------------------------------------------------------------------
// Drawings
// ---------------------------------------------------------------------------

void _diya(Canvas c, double t) {
  // Glow.
  final flick = _wave(t * 3) * 0.5 + _wave(t * 5, 0.3) * 0.5;
  c.drawCircle(
    const Offset(50, 42),
    30 + 3 * flick,
    Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xAAFFC94D), const Color(0x00FFC94D)],
      ).createShader(Rect.fromCircle(center: const Offset(50, 42), radius: 34)),
  );
  _sparkles(c, t, const [
    Offset(18, 20),
    Offset(82, 26),
    Offset(76, 72),
    Offset(22, 66),
  ], TuluColors.turmeric);
  // Flame.
  final sway = 2.5 * _wave(t * 2);
  final h = 22 + 3 * flick;
  final flame = Path()
    ..moveTo(50, 58)
    ..quadraticBezierTo(36, 50, 50 + sway, 58 - h)
    ..quadraticBezierTo(64, 50, 50, 58)
    ..close();
  c.drawPath(flame, _p(const Color(0xFFFF8A1F)));
  final inner = Path()
    ..moveTo(50, 58)
    ..quadraticBezierTo(43, 52, 50 + sway * 0.7, 58 - h * 0.6)
    ..quadraticBezierTo(57, 52, 50, 58)
    ..close();
  c.drawPath(inner, _p(const Color(0xFFFFE27A)));
  // Clay lamp.
  final lamp = Path()
    ..moveTo(20, 60)
    ..quadraticBezierTo(50, 92, 80, 60)
    ..quadraticBezierTo(86, 58, 88, 54)
    ..lineTo(70, 60)
    ..close();
  c.drawPath(lamp, _p(TuluColors.terracotta));
  c.drawOval(Rect.fromLTRB(20, 55, 80, 65), _p(const Color(0xFFE07A50)));
  c.drawOval(Rect.fromLTRB(26, 57, 74, 63), _p(const Color(0xFF8E3B22)));
  _face(c, const Offset(50, 69), 0.8, ink: const Color(0xFFFFE0C2));
}

void _ganesha(Canvas c, double t) {
  final flap = 3 * _wave(t * 2);
  const skin = Color(0xFFF6A8B8);
  const skinDark = Color(0xFFE47F96);
  // Ears.
  c.drawOval(
    Rect.fromCenter(center: Offset(22 - flap, 50), width: 30, height: 38),
    _p(skinDark),
  );
  c.drawOval(
    Rect.fromCenter(center: Offset(78 + flap, 50), width: 30, height: 38),
    _p(skinDark),
  );
  c.drawOval(
    Rect.fromCenter(center: Offset(23 - flap, 50), width: 20, height: 28),
    _p(skin),
  );
  c.drawOval(
    Rect.fromCenter(center: Offset(77 + flap, 50), width: 20, height: 28),
    _p(skin),
  );
  // Head.
  c.drawCircle(const Offset(50, 50), 24, _p(skin));
  // Crown.
  final crown = Path()
    ..moveTo(32, 32)
    ..lineTo(38, 14)
    ..lineTo(44, 24)
    ..lineTo(50, 8)
    ..lineTo(56, 24)
    ..lineTo(62, 14)
    ..lineTo(68, 32)
    ..close();
  c.drawPath(crown, _p(TuluColors.gold));
  c.drawCircle(const Offset(50, 22), 3, _p(TuluColors.red));
  // Tilaka.
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 38), width: 3, height: 7),
    _p(TuluColors.red),
  );
  // Eyes.
  final eye = _p(const Color(0xFF3B2314));
  c.drawCircle(const Offset(42, 46), 2.4, eye);
  c.drawCircle(const Offset(58, 46), 2.4, eye);
  c.drawCircle(const Offset(42.8, 45.2), 0.8, _p(Colors.white));
  c.drawCircle(const Offset(58.8, 45.2), 0.8, _p(Colors.white));
  // Trunk curling.
  final curl = 4 * _wave(t * 2, 0.25);
  final trunk = Path()
    ..moveTo(46, 54)
    ..cubicTo(44, 70, 52, 80, 60 + curl, 76)
    ..cubicTo(66 + curl, 72, 62 + curl, 66, 58, 70)
    ..cubicTo(56, 72, 54, 66, 54, 54)
    ..close();
  c.drawPath(trunk, _p(skin));
  c.drawPath(trunk, _stroke(skinDark, 1));
  // Tusk and cheeks.
  c.drawLine(
    const Offset(42, 58),
    const Offset(38, 64),
    _stroke(Colors.white, 3),
  );
  final blush = _p(const Color(0x66FF6F7D));
  c.drawCircle(const Offset(35, 55), 3.5, blush);
  c.drawCircle(const Offset(65, 55), 3.5, blush);
  // Modak.
  final m = Path()
    ..moveTo(74, 92)
    ..quadraticBezierTo(70, 82, 80, 76)
    ..quadraticBezierTo(90, 82, 86, 92)
    ..close();
  c.drawPath(m, _p(const Color(0xFFFFF3D6)));
  c.drawPath(m, _stroke(const Color(0xFFE0B870), 1));
}

void _naga(Canvas c, double t) {
  final sway = 4 * _wave(t);
  const green = Color(0xFF3E8E41);
  const light = Color(0xFFB5E3A0);
  // Coiled body.
  c.drawOval(Rect.fromLTRB(18, 74, 82, 94), _p(const Color(0xFF2F6E32)));
  c.drawOval(Rect.fromLTRB(24, 70, 76, 86), _p(green));
  // Neck.
  final neck = Path()
    ..moveTo(42, 78)
    ..quadraticBezierTo(40 + sway, 56, 50 + sway, 44)
    ..lineTo(58 + sway, 46)
    ..quadraticBezierTo(50 + sway, 60, 58, 78)
    ..close();
  c.drawPath(neck, _p(green));
  // Hood.
  final hx = 52 + sway;
  final hood = Path()
    ..moveTo(hx, 14)
    ..cubicTo(hx + 26, 18, hx + 22, 46, hx + 4, 52)
    ..lineTo(hx - 4, 52)
    ..cubicTo(hx - 22, 46, hx - 26, 18, hx, 14)
    ..close();
  c.drawPath(hood, _p(green));
  final belly = Path()
    ..moveTo(hx, 22)
    ..cubicTo(hx + 14, 26, hx + 12, 44, hx + 2, 48)
    ..lineTo(hx - 2, 48)
    ..cubicTo(hx - 12, 44, hx - 14, 26, hx, 22)
    ..close();
  c.drawPath(belly, _p(light));
  // Spectacle mark and face.
  c.drawCircle(Offset(hx - 5, 30), 2.5, _p(const Color(0xFF2F6E32)));
  c.drawCircle(Offset(hx + 5, 30), 2.5, _p(const Color(0xFF2F6E32)));
  _face(c, Offset(hx, 38), 0.7);
  // Tongue flick.
  if ((t * 4) % 1 < 0.3) {
    c.drawLine(Offset(hx, 43), Offset(hx, 48), _stroke(TuluColors.red, 1.2));
  }
  // Flowers offered.
  for (final o in const [Offset(16, 86), Offset(86, 84)]) {
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      c.drawCircle(
        o + Offset(math.cos(a) * 3, math.sin(a) * 3),
        2.4,
        _p(const Color(0xFFFFA726)),
      );
    }
    c.drawCircle(o, 1.8, _p(TuluColors.red));
  }
}

void _kalasha(Canvas c, double t) {
  _sparkles(c, t, const [
    Offset(16, 22),
    Offset(84, 18),
    Offset(86, 60),
    Offset(14, 64),
  ], TuluColors.gold);
  // Mango leaves.
  final sway = 2 * _wave(t);
  for (var i = -2; i <= 2; i++) {
    c.save();
    c.translate(50, 40);
    c.rotate(i * 0.38 + sway * 0.02);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-6, -14, 0, -26)
      ..quadraticBezierTo(6, -14, 0, 0)
      ..close();
    c.drawPath(leaf, _p(i.isEven ? TuluColors.areca : TuluColors.paddy));
    c.restore();
  }
  // Coconut.
  c.drawOval(
    Rect.fromCenter(center: const Offset(50, 30), width: 22, height: 26),
    _p(const Color(0xFF8D5A2B)),
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(47, 26), width: 6, height: 8),
    _p(const Color(0xFFB07A44)),
  );
  // Pot.
  c.drawOval(
    Rect.fromLTRB(22, 42, 78, 92),
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xFFFFE08A), Color(0xFFE0A100), Color(0xFFB07800)],
      ).createShader(Rect.fromLTRB(22, 42, 78, 92)),
  );
  c.drawRect(Rect.fromLTRB(36, 40, 64, 46), _p(TuluColors.gold));
  // Swastika-free decorative band.
  c.drawLine(
    const Offset(26, 70),
    const Offset(74, 70),
    _stroke(TuluColors.red, 3),
  );
  for (var i = 0; i < 5; i++) {
    c.drawCircle(Offset(30 + i * 10.0, 70), 2, _p(Colors.white));
  }
  _face(c, const Offset(50, 60), 0.8, ink: const Color(0xFF5A3A00));
}

void _flute(Canvas c, double t) {
  // Notes floating up.
  for (var i = 0; i < 3; i++) {
    final p = (t + i / 3) % 1;
    final x = 64 + i * 8 + 4 * _wave(p);
    final y = 52 - p * 40;
    final a = (1 - p);
    final paint = _p(const Color(0xFF3949AB).withValues(alpha: a));
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 6, height: 4.5),
      paint,
    );
    c.drawLine(
      Offset(x + 2.6, y),
      Offset(x + 2.6, y - 10),
      _stroke(const Color(0xFF3949AB).withValues(alpha: a), 1.2),
    );
  }
  // Peacock feather.
  c.save();
  c.translate(32, 36);
  c.rotate(-0.5 + 0.06 * _wave(t));
  c.drawLine(
    Offset.zero,
    const Offset(0, 40),
    _stroke(const Color(0xFF6D4C41), 1.5),
  );
  for (var i = 0; i < 10; i++) {
    final y = i * 3.0;
    c.drawLine(
      Offset(0, y),
      Offset(-10, y - 6),
      _stroke(const Color(0xFF66BB6A), 1),
    );
    c.drawLine(
      Offset(0, y),
      Offset(10, y - 6),
      _stroke(const Color(0xFF66BB6A), 1),
    );
  }
  c.drawOval(
    Rect.fromCenter(center: const Offset(0, -6), width: 22, height: 28),
    _p(const Color(0xFF26A69A)),
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(0, -5), width: 14, height: 18),
    _p(const Color(0xFF1E88E5)),
  );
  c.drawOval(
    Rect.fromCenter(center: const Offset(0, -4), width: 7, height: 9),
    _p(const Color(0xFF1A237E)),
  );
  c.drawCircle(const Offset(0, -6), 2, _p(TuluColors.turmeric));
  c.restore();
  // Flute.
  c.save();
  c.translate(50, 66);
  c.rotate(-0.25);
  final r = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: 76, height: 9),
    const Radius.circular(4.5),
  );
  c.drawRRect(r, _p(const Color(0xFFD7A15A)));
  c.drawRRect(r, _stroke(const Color(0xFF8D5A2B), 1));
  for (var i = 0; i < 6; i++) {
    c.drawCircle(Offset(-20 + i * 8.0, 0), 1.6, _p(const Color(0xFF5D3A1A)));
  }
  c.drawRect(const Rect.fromLTRB(-34, -4.5, -28, 4.5), _p(TuluColors.red));
  c.drawRect(const Rect.fromLTRB(28, -4.5, 34, 4.5), _p(TuluColors.red));
  c.restore();
}

void _yakshagana(Canvas c, double t) {
  // Glint sweeping across the kireeta (Yakshagana crown).
  final cx = 50.0;
  // Fan-shaped back crown.
  const rays = 13;
  for (var i = 0; i < rays; i++) {
    final a = math.pi + (i + 0.5) * math.pi / rays;
    final p1 = Offset(cx + math.cos(a) * 16, 60 + math.sin(a) * 16);
    final p2 = Offset(cx + math.cos(a) * 44, 60 + math.sin(a) * 44);
    c.drawLine(
      p1,
      p2,
      _stroke(i.isEven ? TuluColors.gold : TuluColors.turmeric, 6),
    );
    c.drawCircle(
      p2,
      3.2,
      _p(i.isEven ? TuluColors.red : const Color(0xFF2E7D32)),
    );
  }
  c.drawArc(
    Rect.fromCircle(center: Offset(cx, 60), radius: 44),
    math.pi,
    math.pi,
    false,
    _stroke(TuluColors.gold, 2),
  );
  // Face.
  c.drawCircle(Offset(cx, 66), 16, _p(const Color(0xFFFFC27A)));
  // Red-white Yakshagana make-up: eye lines and namam.
  c.drawLine(
    Offset(cx - 11, 63),
    Offset(cx - 3, 64),
    _stroke(Colors.black, 2.2),
  );
  c.drawLine(
    Offset(cx + 3, 64),
    Offset(cx + 11, 63),
    _stroke(Colors.black, 2.2),
  );
  c.drawCircle(Offset(cx - 7, 64), 1.6, _p(Colors.white));
  c.drawCircle(Offset(cx + 7, 64), 1.6, _p(Colors.white));
  c.drawLine(Offset(cx, 52), Offset(cx, 59), _stroke(TuluColors.red, 2.5));
  c.drawArc(
    Rect.fromCenter(center: Offset(cx, 71), width: 10, height: 6),
    0.1,
    math.pi - 0.2,
    false,
    _stroke(TuluColors.red, 2),
  );
  // Moustache curls.
  c.drawArc(
    Rect.fromCenter(center: Offset(cx - 6, 69), width: 10, height: 6),
    math.pi * 0.1,
    math.pi * 0.9,
    false,
    _stroke(Colors.black, 1.6),
  );
  c.drawArc(
    Rect.fromCenter(center: Offset(cx + 6, 69), width: 10, height: 6),
    0,
    math.pi * 0.9,
    false,
    _stroke(Colors.black, 1.6),
  );
  // Front crown band.
  c.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - 18, 46, cx + 18, 54),
      const Radius.circular(3),
    ),
    _p(TuluColors.gold),
  );
  for (var i = 0; i < 5; i++) {
    c.drawCircle(
      Offset(cx - 12 + i * 6.0, 50),
      1.8,
      _p(i.isEven ? TuluColors.red : const Color(0xFF2E7D32)),
    );
  }
  // Earrings.
  c.drawCircle(Offset(cx - 17, 72), 3, _p(TuluColors.turmeric));
  c.drawCircle(Offset(cx + 17, 72), 3, _p(TuluColors.turmeric));
  // Glint.
  final gx = -10 + 120 * t;
  c.drawLine(
    Offset(gx, 10),
    Offset(gx - 14, 60),
    _stroke(Colors.white.withValues(alpha: 0.25), 6),
  );
  _sparkles(c, t, const [Offset(14, 86), Offset(86, 88)], TuluColors.turmeric);
}

void _paddy(Canvas c, double t) {
  // Sun behind.
  c.drawCircle(const Offset(72, 26), 14, _p(const Color(0xFFFFC94D)));
  // Ground.
  c.drawRect(const Rect.fromLTRB(0, 80, 100, 100), _p(const Color(0xFF8BC34A)));
  // Sheaf of paddy, stalks swaying.
  for (var i = 0; i < 9; i++) {
    final x0 = 34 + i * 4.0;
    final sway = 5 * _wave(t, i * 0.07);
    final top = Offset(x0 - 16 + i * 4.0 + sway, 26 + (i % 3) * 4.0);
    final path = Path()
      ..moveTo(x0, 84)
      ..quadraticBezierTo(x0, 50, top.dx, top.dy);
    c.drawPath(path, _stroke(const Color(0xFF7CB342), 2));
    // Grains.
    for (var g = 0; g < 5; g++) {
      final p = Offset.lerp(top, Offset(x0, 60), g / 7)!;
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(3, 0), width: 4, height: 2.6),
        _p(const Color(0xFFE6B422)),
      );
    }
  }
  // Tie.
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(40, 68, 62, 74),
      const Radius.circular(2),
    ),
    _p(TuluColors.red),
  );
  _sparkles(c, t, const [Offset(16, 24), Offset(20, 56)], Colors.white);
}

void _rain(Canvas c, double t) {
  // Cloud.
  final cloud = _p(const Color(0xFFEFF4F8));
  for (final (x, y, r) in const [
    (30.0, 26.0, 12.0),
    (46.0, 20.0, 15.0),
    (62.0, 26.0, 12.0),
    (46.0, 30.0, 14.0),
  ]) {
    c.drawCircle(Offset(x + 2 * _wave(t), y), r, cloud);
  }
  _face(c, Offset(46 + 2 * _wave(t), 26), 0.7, ink: const Color(0xFF455A64));
  // Rain drops.
  final drop = _p(const Color(0xFF1E6F9F));
  for (var i = 0; i < 9; i++) {
    final x = 14.0 + i * 9;
    final y = 40 + ((t + i * 0.37) % 1) * 56;
    c.drawOval(
      Rect.fromCenter(center: Offset(x, y), width: 2.6, height: 6),
      drop,
    );
  }
  // Areca-leaf umbrella (Tulunadu "kombu-koDe" style).
  final u = Path()
    ..moveTo(52, 62)
    ..quadraticBezierTo(76, 54, 96, 66)
    ..lineTo(52, 66)
    ..close();
  c.drawPath(u, _p(const Color(0xFFC49A5A)));
  c.drawLine(
    const Offset(72, 62),
    const Offset(72, 92),
    _stroke(const Color(0xFF6D4C41), 1.6),
  );
  // Pale (Alstonia) bark kashaya cup.
  c.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTRB(16, 78, 34, 94),
      const Radius.circular(4),
    ),
    _p(Colors.white),
  );
  c.drawRect(const Rect.fromLTRB(18, 80, 32, 84), _p(const Color(0xFF8D6E63)));
  for (var i = 0; i < 2; i++) {
    final p = (t + i * 0.5) % 1;
    c.drawCircle(
      Offset(25 + 2 * _wave(p), 74 - p * 10),
      1.5,
      _p(Colors.white.withValues(alpha: 1 - p)),
    );
  }
}

void _tulasi(Canvas c, double t) {
  // Tulasi katte (pedestal).
  c.drawRect(const Rect.fromLTRB(28, 56, 72, 92), _p(const Color(0xFFF5E1C0)));
  c.drawRect(const Rect.fromLTRB(24, 52, 76, 58), _p(TuluColors.terracotta));
  c.drawRect(const Rect.fromLTRB(24, 90, 76, 94), _p(TuluColors.terracotta));
  // Kolam dots.
  for (var i = 0; i < 4; i++) {
    c.drawCircle(Offset(36 + i * 9.0, 74), 2, _p(TuluColors.red));
  }
  _face(c, const Offset(50, 66), 0.6, ink: const Color(0xFF6D4C41));
  // Plant.
  final sway = 2 * _wave(t);
  for (var i = 0; i < 7; i++) {
    final a = -math.pi / 2 + (i - 3) * 0.32;
    final len = 22 + (3 - (i - 3).abs()) * 4.0;
    final tip = Offset(50 + math.cos(a) * len + sway, 52 + math.sin(a) * len);
    c.drawLine(
      const Offset(50, 52),
      tip,
      _stroke(const Color(0xFF558B2F), 1.4),
    );
    for (var k = 1; k <= 3; k++) {
      final p = Offset.lerp(const Offset(50, 52), tip, k / 3.2)!;
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(-3, 0), width: 6, height: 3.5),
        _p(const Color(0xFF7CB342)),
      );
      c.drawOval(
        Rect.fromCenter(center: p + const Offset(3, 0), width: 6, height: 3.5),
        _p(const Color(0xFF689F38)),
      );
    }
    c.drawCircle(tip, 1.6, _p(const Color(0xFF8E24AA)));
  }
  // Little lamp.
  final f = _wave(t * 3);
  c.drawOval(const Rect.fromLTRB(76, 86, 94, 92), _p(TuluColors.terracotta));
  final flame = Path()
    ..moveTo(85, 87)
    ..quadraticBezierTo(80, 82, 85 + f, 76)
    ..quadraticBezierTo(90, 82, 85, 87)
    ..close();
  c.drawPath(flame, _p(const Color(0xFFFF9800)));
}

void _sun(Canvas c, double t) {
  c.save();
  c.translate(50, 50);
  c.rotate(t * math.pi / 6);
  for (var i = 0; i < 12; i++) {
    c.save();
    c.rotate(i * math.pi / 6);
    final ray = Path()
      ..moveTo(-5, -26)
      ..lineTo(0, -44)
      ..lineTo(5, -26)
      ..close();
    c.drawPath(ray, _p(i.isEven ? const Color(0xFFFF9800) : TuluColors.gold));
    c.restore();
  }
  c.restore();
  c.drawCircle(
    const Offset(50, 50),
    26,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFF176), Color(0xFFFFC107)],
      ).createShader(Rect.fromCircle(center: const Offset(50, 50), radius: 26)),
  );
  _face(c, const Offset(50, 52), 1.3, ink: const Color(0xFF8D4A00));
}

void _linga(Canvas c, double t) {
  // Crescent moon.
  c.drawCircle(const Offset(74, 22), 10, _p(const Color(0xFFFFF59D)));
  c.drawCircle(const Offset(78, 19), 9, _p(const Color(0xFF243B5E)));
  _sparkles(c, t, const [
    Offset(18, 18),
    Offset(30, 34),
    Offset(88, 48),
  ], Colors.white);
  // Base (peetha).
  final base = Path()
    ..moveTo(14, 78)
    ..lineTo(76, 78)
    ..quadraticBezierTo(90, 78, 92, 72)
    ..lineTo(80, 70)
    ..lineTo(20, 70)
    ..close();
  c.drawPath(base, _p(const Color(0xFF546E7A)));
  c.drawRect(const Rect.fromLTRB(22, 78, 70, 92), _p(const Color(0xFF455A64)));
  // Linga.
  c.drawRRect(
    RRect.fromRectAndCorners(
      const Rect.fromLTRB(32, 34, 58, 72),
      topLeft: const Radius.circular(13),
      topRight: const Radius.circular(13),
    ),
    _p(const Color(0xFF37474F)),
  );
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      Offset(36, 46 + i * 4.0),
      Offset(54, 46 + i * 4.0),
      _stroke(Colors.white, 1.6),
    );
  }
  c.drawCircle(const Offset(45, 56), 2.2, _p(TuluColors.red));
  // Bilva leaves.
  for (final a in const [-0.5, 0.0, 0.5]) {
    c.save();
    c.translate(45, 34);
    c.rotate(a);
    c.drawOval(const Rect.fromLTRB(-3, -12, 3, 0), _p(const Color(0xFF66BB6A)));
    c.restore();
  }
  // Water drops from above.
  final p = t % 1;
  c.drawOval(
    Rect.fromCenter(center: Offset(45, 6 + p * 26), width: 2.6, height: 5),
    _p(const Color(0xFF90CAF9).withValues(alpha: 1 - p * 0.6)),
  );
}

void _holi(Canvas c, double t) {
  const colors = [
    Color(0xFFE91E63), Color(0xFFFFC107), Color(0xFF4CAF50), //
    Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFFFF5722),
  ];
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3 + t * 0.6;
    final r = 20 + 8 * _wave(t, i / 6);
    final o = Offset(50 + math.cos(a) * r, 50 + math.sin(a) * r);
    c.drawCircle(
      o,
      12 + 2 * _wave(t, i / 4),
      _p(colors[i].withValues(alpha: 0.75)),
    );
  }
  for (var i = 0; i < 14; i++) {
    final a = i * 2 * math.pi / 14;
    final p = (t + i / 14) % 1;
    final o = Offset(
      50 + math.cos(a) * (20 + p * 30),
      50 + math.sin(a) * (20 + p * 30),
    );
    c.drawCircle(o, 2.2 * (1 - p), _p(colors[i % 6]));
  }
  c.drawCircle(const Offset(50, 50), 13, _p(Colors.white));
  _face(c, const Offset(50, 51), 0.9);
}

void _moon(Canvas c, double t) {
  _sparkles(c, t, const [
    Offset(18, 20),
    Offset(80, 16),
    Offset(86, 70),
    Offset(20, 76),
    Offset(64, 86),
  ], const Color(0xFFFFF9C4));
  c.drawCircle(
    const Offset(50, 50),
    34,
    Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x55FFF9C4), Color(0x00FFF9C4)],
      ).createShader(Rect.fromCircle(center: const Offset(50, 50), radius: 34)),
  );
  c.drawCircle(const Offset(50, 50), 24, _p(const Color(0xFFFFF3B0)));
  c.drawCircle(const Offset(40, 42), 4, _p(const Color(0xFFF0DD8A)));
  c.drawCircle(const Offset(60, 60), 3, _p(const Color(0xFFF0DD8A)));
  _face(c, const Offset(50, 52), 1.0, ink: const Color(0xFF6D5D1A));
}

void _newMoon(Canvas c, double t) {
  _sparkles(c, t, const [
    Offset(14, 18),
    Offset(84, 14),
    Offset(88, 66),
    Offset(16, 78),
    Offset(60, 90),
    Offset(36, 10),
  ], const Color(0xFFFFF9C4));
  // Earthshine rim around a dark disc.
  final glow = 0.5 + 0.5 * _wave(t);
  c.drawCircle(
    const Offset(50, 50),
    27,
    _stroke(
      Color.lerp(const Color(0x667986CB), const Color(0xAAB3C1FF), glow)!,
      3,
    ),
  );
  c.drawCircle(const Offset(50, 50), 25, _p(const Color(0xFF2B2F55)));
  c.drawCircle(const Offset(41, 43), 4, _p(const Color(0xFF353A66)));
  c.drawCircle(const Offset(60, 60), 3, _p(const Color(0xFF353A66)));
  _face(c, const Offset(50, 52), 1.0, ink: const Color(0xFFB3C1FF));
}

void _bow(Canvas c, double t) {
  c.drawCircle(const Offset(50, 50), 32, _p(const Color(0xFFFFD08A)));
  c.save();
  c.translate(50, 50);
  c.rotate(-0.6);
  final bend = 2 * _wave(t);
  c.drawArc(
    Rect.fromCenter(center: const Offset(-8, 0), width: 40 + bend, height: 70),
    -math.pi / 2,
    math.pi,
    false,
    _stroke(const Color(0xFF6D4C41), 4),
  );
  c.drawLine(
    const Offset(-8, -35),
    Offset(-8 - bend, 35),
    _stroke(const Color(0xFFEEE0C0), 1.2),
  );
  final shift = 4 * _wave(t);
  c.drawLine(
    Offset(-30 + shift, 0),
    Offset(26 + shift, 0),
    _stroke(const Color(0xFF8D6E63), 2),
  );
  final head = Path()
    ..moveTo(32 + shift, 0)
    ..lineTo(24 + shift, -5)
    ..lineTo(24 + shift, 5)
    ..close();
  c.drawPath(head, _p(TuluColors.gold));
  c.drawLine(
    Offset(-30 + shift, 0),
    Offset(-34 + shift, -5),
    _stroke(TuluColors.red, 2),
  );
  c.drawLine(
    Offset(-30 + shift, 0),
    Offset(-34 + shift, 5),
    _stroke(TuluColors.red, 2),
  );
  c.restore();
  _sparkles(c, t, const [Offset(16, 16), Offset(84, 84)], Colors.white);
}

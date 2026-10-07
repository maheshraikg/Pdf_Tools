// Draws the dress-up layers and the Vesha guide portraits as vector
// illustrations with Flutter's canvas (anti-aliased paths, gradients).
// They replace the blocky placeholders until commissioned art arrives.
//
//   flutter test tool/art/draw_art_test.dart
//
// Every dress-up layer shares one 1024×1536 canvas (face centre 512,500)
// so layers stack without offsets, as docs/ART_GUIDE.md specifies.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const W = 1024.0, H = 1536.0;
const fc = Offset(512, 500); // face centre
const frx = 118.0, fry = 138.0; // face radii

const skin = Color(0xFFE6A57A), skinDark = Color(0xFFC9845A);
const gold = Color(0xFFE2A818),
    goldDark = Color(0xFFA8740A),
    goldLight = Color(0xFFFFE08A);
const red = Color(0xFFC62828), redDark = Color(0xFF7F1414);
const green = Color(0xFF2E7D32), greenDark = Color(0xFF1B4D1F);
const black = Color(0xFF1B1411),
    white = Color(0xFFFFFDF6),
    mirror = Color(0xFFE8F4FF);

Paint fill(Color c) => Paint()
  ..color = c
  ..isAntiAlias = true;
Paint stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
List<double> _stops(int n) => [for (var i = 0; i < n; i++) i / (n - 1)];
Paint grad(Rect r, List<Color> cs, {bool vertical = true}) =>
    Paint()
      ..shader = ui.Gradient.linear(
        vertical ? r.topCenter : r.centerLeft,
        vertical ? r.bottomCenter : r.centerRight,
        cs,
        _stops(cs.length),
      );
Paint radial(Offset c, double r, List<Color> cs) =>
    Paint()..shader = ui.Gradient.radial(c, r, cs, _stops(cs.length));

Rect faceRect() => Rect.fromCenter(center: fc, width: frx * 2, height: fry * 2);

/// A small round mirror/glass stone with highlight.
void gem(Canvas c, Offset p, double r, Color col) {
  c.drawCircle(p, r * 1.25, fill(goldDark));
  c.drawCircle(
    p,
    r,
    radial(p - Offset(r * .3, r * .3), r * 1.2, [
      Color.lerp(col, Colors.white, .55)!,
      col,
    ]),
  );
  c.drawCircle(
    p - Offset(r * .35, r * .35),
    r * .28,
    fill(Colors.white.withValues(alpha: .85)),
  );
}

// ---------------------------------------------------------------------------
// Base figure.

void drawLegs(Canvas c) {
  for (final x in [440.0, 584.0]) {
    final leg = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, 1300), width: 82, height: 400),
      const Radius.circular(40),
    );
    c.drawRRect(leg, grad(leg.outerRect, [skin, skinDark], vertical: false));
    // Feet.
    c.drawOval(
      Rect.fromCenter(
        center: Offset(x + (x < 512 ? -14 : 14), 1500),
        width: 118,
        height: 52,
      ),
      fill(skinDark),
    );
    // Ankle bells (gejje).
    for (var i = 0; i < 7; i++) {
      final a = math.pi * i / 6;
      gem(
        c,
        Offset(x - 44 * math.cos(a), 1462 + 6 * math.sin(a)),
        7,
        goldLight,
      );
    }
  }
}

void drawArms(Canvas c) {
  for (final s in [-1.0, 1.0]) {
    final p = Path()
      ..moveTo(512 + s * 168, 730)
      ..quadraticBezierTo(512 + s * 245, 860, 512 + s * 262, 1060)
      ..lineTo(512 + s * 205, 1068)
      ..quadraticBezierTo(512 + s * 192, 880, 512 + s * 130, 780)
      ..close();
    c.drawPath(p, grad(p.getBounds(), [skin, skinDark], vertical: false));
    // Hand.
    c.drawCircle(Offset(512 + s * 236, 1085), 40, fill(skin));
    c.drawCircle(Offset(512 + s * 236, 1085), 40, stroke(skinDark, 3));
  }
}

void drawTorso(Canvas c) {
  // Neck.
  final neck = Rect.fromLTRB(462, 600, 562, 720);
  c.drawRect(neck, grad(neck, [skinDark, skin]));
  // Simple white undershirt and dhoti.
  final shirt = Path()
    ..moveTo(340, 740)
    ..quadraticBezierTo(512, 690, 684, 740)
    ..lineTo(660, 1130)
    ..lineTo(364, 1130)
    ..close();
  c.drawPath(shirt, grad(shirt.getBounds(), [white, const Color(0xFFE9E2D0)]));
  final dhoti = Path()
    ..moveTo(364, 1120)
    ..lineTo(660, 1120)
    ..lineTo(690, 1330)
    ..quadraticBezierTo(512, 1350, 334, 1330)
    ..close();
  c.drawPath(dhoti, grad(dhoti.getBounds(), [white, const Color(0xFFE0D8C4)]));
  c.drawPath(dhoti, stroke(const Color(0xFFCFC5AE), 3));
}

void drawEars(Canvas c) {
  for (final s in [-1.0, 1.0]) {
    c.drawOval(
      Rect.fromCenter(
        center: fc + Offset(s * (frx + 6), 20),
        width: 42,
        height: 70,
      ),
      fill(skinDark),
    );
  }
}

/// Plain face shape with neutral features (used by the base and the guide).
void drawFaceShape(Canvas c, Color base, Color shade) {
  c.drawOval(
    faceRect(),
    radial(fc - const Offset(30, 40), fry * 1.3, [
      Color.lerp(base, Colors.white, .15)!,
      base,
      shade,
    ]),
  );
}

void drawEyes(
  Canvas c, {
  double lift = 0,
  bool wings = false,
  Color liner = black,
  double lidWidth = 4,
}) {
  for (final s in [-1.0, 1.0]) {
    final e = fc + Offset(s * 46, -8 - lift);
    final eye = Path()
      ..moveTo(e.dx - 30, e.dy)
      ..quadraticBezierTo(e.dx, e.dy - 24, e.dx + 30, e.dy)
      ..quadraticBezierTo(e.dx, e.dy + 18, e.dx - 30, e.dy)
      ..close();
    c.drawPath(eye, fill(white));
    c.drawCircle(e + const Offset(0, -2), 12, fill(const Color(0xFF3B2416)));
    c.drawCircle(e + const Offset(0, -2), 6, fill(black));
    c.drawCircle(e + const Offset(-4, -6), 3.5, fill(Colors.white));
    c.drawPath(eye, stroke(liner, lidWidth));
    if (wings) {
      final outer = e + Offset(s * 30, 0);
      c.drawPath(
        Path()
          ..moveTo(outer.dx, outer.dy)
          ..quadraticBezierTo(
            outer.dx + s * 22,
            outer.dy - 6,
            outer.dx + s * 38,
            outer.dy - 22,
          ),
        stroke(liner, lidWidth + 2),
      );
    }
  }
}

void drawBrows(
  Canvas c, {
  double thick = 7,
  double arch = 14,
  double flare = 0,
  Color col = black,
}) {
  for (final s in [-1.0, 1.0]) {
    final p = Path()
      ..moveTo(fc.dx + s * 16, fc.dy - 48)
      ..quadraticBezierTo(
        fc.dx + s * 50,
        fc.dy - 48 - arch,
        fc.dx + s * 86,
        fc.dy - 42 - flare,
      );
    c.drawPath(p, stroke(col, thick));
  }
}

void drawNose(Canvas c) {
  c.drawPath(
    Path()
      ..moveTo(fc.dx - 4, fc.dy + 8)
      ..quadraticBezierTo(fc.dx - 14, fc.dy + 44, fc.dx, fc.dy + 50)
      ..quadraticBezierTo(fc.dx + 10, fc.dy + 50, fc.dx + 14, fc.dy + 44),
    stroke(skinDark, 4),
  );
}

void drawMouth(
  Canvas c, {
  Color col = const Color(0xFFB0413E),
  double smile = 12,
  double width = 34,
}) {
  final m = fc + const Offset(0, 80);
  c.drawPath(
    Path()
      ..moveTo(m.dx - width, m.dy)
      ..quadraticBezierTo(m.dx, m.dy + smile * 1.6, m.dx + width, m.dy)
      ..quadraticBezierTo(m.dx, m.dy + smile * .5, m.dx - width, m.dy),
    fill(col),
  );
}

void drawHair(Canvas c) {
  final p = Path()
    ..moveTo(fc.dx - frx - 4, fc.dy - 10)
    ..quadraticBezierTo(fc.dx - frx, fc.dy - fry - 20, fc.dx, fc.dy - fry - 22)
    ..quadraticBezierTo(
      fc.dx + frx,
      fc.dy - fry - 20,
      fc.dx + frx + 4,
      fc.dy - 10,
    )
    ..quadraticBezierTo(
      fc.dx + frx - 10,
      fc.dy - fry + 30,
      fc.dx,
      fc.dy - fry + 22,
    )
    ..quadraticBezierTo(
      fc.dx - frx + 10,
      fc.dy - fry + 30,
      fc.dx - frx - 4,
      fc.dy - 10,
    )
    ..close();
  c.drawPath(p, fill(const Color(0xFF241812)));
}

void base(Canvas c) {
  drawLegs(c);
  drawArms(c);
  drawTorso(c);
  drawEars(c);
  drawFaceShape(c, skin, skinDark);
  drawHair(c);
  drawBrows(c, thick: 6, arch: 10);
  drawEyes(c, lidWidth: 3);
  drawNose(c);
  drawMouth(c, smile: 10);
}

// ---------------------------------------------------------------------------
// Face paints (each repaints the whole face area).

void faceRaja(Canvas c) {
  drawFaceShape(c, const Color(0xFFF4B48A), const Color(0xFFD98C62));
  // Red namam on the forehead.
  c.drawPath(
    Path()
      ..moveTo(fc.dx - 9, fc.dy - 120)
      ..lineTo(fc.dx + 9, fc.dy - 120)
      ..lineTo(fc.dx + 4, fc.dy - 52)
      ..lineTo(fc.dx - 4, fc.dy - 52)
      ..close(),
    fill(red),
  );
  drawBrows(c, thick: 11, arch: 22, flare: 16);
  drawEyes(c, wings: true, lidWidth: 6);
  drawNose(c);
  // Moustache curling up.
  for (final s in [-1.0, 1.0]) {
    c.drawPath(
      Path()
        ..moveTo(fc.dx, fc.dy + 62)
        ..quadraticBezierTo(
          fc.dx + s * 48,
          fc.dy + 70,
          fc.dx + s * 72,
          fc.dy + 46,
        ),
      stroke(black, 9),
    );
  }
  drawMouth(c, col: red, smile: 8, width: 26);
  // White dotted cheek line (chutti-like border).
  for (var i = 0; i <= 10; i++) {
    final a = math.pi * (0.15 + 0.7 * i / 10);
    c.drawCircle(
      fc + Offset(math.cos(a) * (frx - 10), math.sin(a) * (fry - 8)),
      5,
      fill(white),
    );
  }
}

void faceBannada(Canvas c) {
  drawFaceShape(c, const Color(0xFFD93A2B), const Color(0xFF8F1A12));
  // White swirling cheek patterns.
  for (final s in [-1.0, 1.0]) {
    c.drawPath(
      Path()
        ..moveTo(fc.dx + s * 20, fc.dy + 30)
        ..cubicTo(
          fc.dx + s * 70,
          fc.dy + 10,
          fc.dx + s * 110,
          fc.dy + 60,
          fc.dx + s * 80,
          fc.dy + 110,
        ),
      stroke(white, 12),
    );
    c.drawPath(
      Path()
        ..moveTo(fc.dx + s * 30, fc.dy - 70)
        ..quadraticBezierTo(
          fc.dx + s * 90,
          fc.dy - 110,
          fc.dx + s * 108,
          fc.dy - 40,
        ),
      stroke(white, 9),
    );
  }
  // Black around the eyes.
  for (final s in [-1.0, 1.0]) {
    c.drawOval(
      Rect.fromCenter(center: fc + Offset(s * 46, -10), width: 96, height: 62),
      fill(black),
    );
  }
  drawEyes(c, lift: 2, liner: black, lidWidth: 4);
  drawBrows(c, thick: 14, arch: 30, flare: 30, col: white);
  // Fangs and a wide mouth.
  final m = fc + const Offset(0, 84);
  c.drawPath(
    Path()
      ..moveTo(m.dx - 48, m.dy - 6)
      ..quadraticBezierTo(m.dx, m.dy + 40, m.dx + 48, m.dy - 6)
      ..close(),
    fill(black),
  );
  for (final s in [-1.0, 1.0]) {
    c.drawPath(
      Path()
        ..moveTo(m.dx + s * 30, m.dy)
        ..lineTo(m.dx + s * 22, m.dy + 26)
        ..lineTo(m.dx + s * 16, m.dy + 2)
        ..close(),
      fill(white),
    );
  }
  // White dots along the jaw.
  for (var i = 0; i <= 12; i++) {
    final a = math.pi * (0.1 + 0.8 * i / 12);
    c.drawCircle(
      fc + Offset(math.cos(a) * (frx - 4), math.sin(a) * (fry - 2)),
      7,
      fill(white),
    );
  }
}

void faceStri(Canvas c) {
  drawFaceShape(c, const Color(0xFFF7C9A0), const Color(0xFFE0A47A));
  c.drawCircle(fc + const Offset(0, -64), 9, fill(red));
  c.drawCircle(fc + const Offset(0, -64), 4, fill(goldLight));
  drawBrows(c, thick: 5, arch: 16);
  drawEyes(c, wings: true, lidWidth: 4);
  drawNose(c);
  // Nose ring.
  c.drawCircle(fc + const Offset(18, 50), 9, stroke(gold, 3));
  for (final s in [-1.0, 1.0]) {
    c.drawCircle(fc + Offset(s * 70, 48), 18, fill(const Color(0x55FF7F8F)));
  }
  drawMouth(c, col: const Color(0xFFC2185B), smile: 12, width: 26);
}

void faceHasya(Canvas c) {
  drawFaceShape(c, skin, skinDark);
  drawBrows(c, thick: 8, arch: 26);
  drawEyes(c, lidWidth: 4);
  // White spots on cheeks and a red nose tip.
  for (final s in [-1.0, 1.0]) {
    for (final o in [
      const Offset(70, 30),
      const Offset(84, 60),
      const Offset(60, 62),
    ]) {
      c.drawCircle(fc + Offset(s * o.dx, o.dy), 8, fill(white));
    }
  }
  c.drawCircle(fc + const Offset(0, 44), 16, fill(red));
  // Thin twirled moustache and a big grin.
  for (final s in [-1.0, 1.0]) {
    c.drawPath(
      Path()
        ..moveTo(fc.dx, fc.dy + 64)
        ..cubicTo(
          fc.dx + s * 40,
          fc.dy + 60,
          fc.dx + s * 70,
          fc.dy + 80,
          fc.dx + s * 64,
          fc.dy + 56,
        ),
      stroke(black, 5),
    );
  }
  drawMouth(c, col: const Color(0xFF8E2A22), smile: 26, width: 46);
}

// ---------------------------------------------------------------------------
// Costumes: jacket (angi) + flared skirt (kase) with trim bands.

void costume(
  Canvas c,
  Color main,
  Color dark,
  Color trim, {
  bool checks = false,
}) {
  final jacket = Path()
    ..moveTo(334, 744)
    ..quadraticBezierTo(512, 694, 690, 744)
    ..lineTo(712, 900) // sleeves
    ..lineTo(664, 920)
    ..lineTo(652, 1132)
    ..lineTo(372, 1132)
    ..lineTo(360, 920)
    ..lineTo(312, 900)
    ..close();
  c.drawPath(jacket, grad(jacket.getBounds(), [main, dark], vertical: false));
  c.drawPath(jacket, stroke(trim, 6));
  // Front opening trim.
  c.drawLine(const Offset(512, 720), const Offset(512, 1130), stroke(trim, 10));
  // Waist sash.
  final sash = RRect.fromRectAndRadius(
    const Rect.fromLTRB(352, 1104, 672, 1160),
    const Radius.circular(18),
  );
  c.drawRRect(sash, grad(sash.outerRect, [goldLight, gold, goldDark]));
  // Flared skirt.
  final skirt = Path()
    ..moveTo(360, 1150)
    ..lineTo(664, 1150)
    ..quadraticBezierTo(760, 1290, 790, 1400)
    ..quadraticBezierTo(512, 1440, 234, 1400)
    ..quadraticBezierTo(264, 1290, 360, 1150)
    ..close();
  c.drawPath(skirt, grad(skirt.getBounds(), [main, dark]));
  c.save();
  c.clipPath(skirt);
  if (checks) {
    for (var x = 200.0; x < 820; x += 44) {
      c.drawLine(
        Offset(x, 1140),
        Offset(x + 40, 1440),
        stroke(dark.withValues(alpha: .55), 10),
      );
    }
  }
  for (var y = 1210.0; y < 1420; y += 52) {
    c.drawRect(Rect.fromLTRB(200, y, 820, y + 14), fill(trim));
    for (var x = 230.0; x < 800; x += 46) {
      c.drawCircle(Offset(x, y + 7), 4, fill(white));
    }
  }
  c.restore();
  c.drawPath(skirt, stroke(trim, 5));
}

// ---------------------------------------------------------------------------
// Ornaments.

void chestPlate(Canvas c) {
  final p = Path()
    ..moveTo(392, 742)
    ..quadraticBezierTo(512, 712, 632, 742)
    ..lineTo(604, 940)
    ..quadraticBezierTo(512, 990, 420, 940)
    ..close();
  c.drawPath(p, grad(p.getBounds(), [goldLight, gold, goldDark]));
  c.drawPath(p, stroke(goldDark, 5));
  // Rows of stones.
  for (var r = 0; r < 4; r++) {
    final y = 780.0 + r * 42;
    final n = 6 - (r ~/ 2);
    for (var i = 0; i < n; i++) {
      final x = 512 + (i - (n - 1) / 2) * (190 / n);
      gem(c, Offset(x, y), 11, [red, green, mirror, red][(i + r) % 4]);
    }
  }
  gem(c, const Offset(512, 952), 18, red);
}

void beads(Canvas c) {
  for (var k = 0; k < 4; k++) {
    final rx = 120.0 + k * 22, ry = 70.0 + k * 34;
    for (var i = 0; i <= 26; i++) {
      final a = math.pi * i / 26;
      final p = Offset(512 - rx * math.cos(a), 735 + ry * math.sin(a));
      c.drawCircle(
        p,
        9,
        radial(p - const Offset(3, 3), 11, [
          Colors.white,
          [white, red, goldLight, green][k],
        ]),
      );
    }
  }
  gem(c, Offset(512, 735 + 70.0 + 3 * 34 + 14), 16, red);
}

void shoulders(Canvas c, Color metal, Color metalDark) {
  for (final s in [-1.0, 1.0]) {
    final o = Offset(512 + s * 190, 760);
    // Flared wing of rays.
    for (var i = 0; i < 7; i++) {
      final a = -math.pi / 2 + s * (0.15 + i * 0.22);
      final tip = o + Offset(math.cos(a), math.sin(a)) * 150;
      c.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(tip.dx - 12, tip.dy)
          ..lineTo(tip.dx + 12, tip.dy)
          ..close(),
        fill(i.isEven ? metal : metalDark),
      );
      gem(c, tip, 9, i.isEven ? red : mirror);
    }
    c.drawCircle(
      o,
      46,
      grad(Rect.fromCircle(center: o, radius: 46), [
        Color.lerp(metal, Colors.white, .4)!,
        metalDark,
      ]),
    );
    gem(c, o, 20, green);
  }
}

void earDiscs(Canvas c) {
  for (final s in [-1.0, 1.0]) {
    final o = fc + Offset(s * (frx + 30), 40);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * 34, 12, fill(gold));
    }
    c.drawCircle(
      o,
      34,
      grad(Rect.fromCircle(center: o, radius: 34), [goldLight, goldDark]),
    );
    gem(c, o, 15, red);
  }
}

void fanCrown(
  Canvas c, {
  required double r,
  required List<Color> bands,
  Color? rays,
  bool bannadaStyle = false,
}) {
  final o = fc + Offset(0, -fry + 30);
  // Concentric half discs.
  for (var i = 0; i < bands.length; i++) {
    final rr = r * (1 - i * 0.16);
    c.drawArc(
      Rect.fromCircle(center: o, radius: rr),
      math.pi,
      math.pi,
      true,
      fill(bands[i]),
    );
  }
  // Rays / mirror dots on the outer rim.
  final n = bannadaStyle ? 26 : 19;
  for (var i = 0; i <= n; i++) {
    final a = math.pi + i * math.pi / n;
    final p = o + Offset(math.cos(a), math.sin(a)) * (r * 0.93);
    if (rays != null) {
      c.drawLine(
        o + Offset(math.cos(a), math.sin(a)) * (r * 0.55),
        p,
        stroke(rays, bannadaStyle ? 10 : 5),
      );
    }
    gem(c, p, bannadaStyle ? 12 : 10, i.isEven ? mirror : red);
  }
  // Headband over the forehead.
  final band = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: o + const Offset(0, 6),
      width: frx * 2 + 30,
      height: 46,
    ),
    const Radius.circular(20),
  );
  c.drawRRect(band, grad(band.outerRect, [goldLight, gold, goldDark]));
  for (var i = -4; i <= 4; i++) {
    gem(c, o + Offset(i * 26.0, 6), 8, i.isEven ? red : green);
  }
}

void kireeta(Canvas c) {
  fanCrown(
    c,
    r: 300,
    bands: [gold, red, gold, green, goldLight],
    rays: goldDark,
  );
  // Central peak.
  final o = fc + Offset(0, -fry + 30);
  final peak = Path()
    ..moveTo(o.dx - 60, o.dy - 10)
    ..lineTo(o.dx, o.dy - 300)
    ..lineTo(o.dx + 60, o.dy - 10)
    ..close();
  c.drawPath(
    peak,
    grad(peak.getBounds(), [goldLight, goldDark], vertical: false),
  );
  for (var i = 0; i < 5; i++) {
    gem(c, o + Offset(0, -50.0 - i * 48), 11, i.isEven ? red : mirror);
  }
}

void pagade(Canvas c) {
  final o = fc + Offset(0, -fry + 20);
  final turban = Path()
    ..moveTo(o.dx - frx - 30, o.dy + 20)
    ..quadraticBezierTo(o.dx - frx - 50, o.dy - 150, o.dx, o.dy - 170)
    ..quadraticBezierTo(o.dx + frx + 50, o.dy - 150, o.dx + frx + 30, o.dy + 20)
    ..close();
  c.drawPath(turban, grad(turban.getBounds(), [red, redDark], vertical: false));
  for (var i = 0; i < 6; i++) {
    c.drawArc(
      Rect.fromCenter(
        center: o + const Offset(0, 10),
        width: (frx + 30) * 2 - i * 20,
        height: 300 - i * 34,
      ),
      math.pi * 1.05,
      math.pi * .9,
      false,
      stroke(gold, 6),
    );
  }
  final band = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: o + const Offset(0, 4),
      width: frx * 2 + 70,
      height: 54,
    ),
    const Radius.circular(22),
  );
  c.drawRRect(band, grad(band.outerRect, [goldLight, gold, goldDark]));
  for (var i = -5; i <= 5; i++) {
    gem(c, o + Offset(i * 24.0, 4), 8, i.isEven ? white : red);
  }
  // Plume.
  gem(c, o + const Offset(0, -150), 18, red);
}

void kedage(Canvas c) {
  final o = fc + Offset(0, -fry + 30);
  for (var i = 0; i < 3; i++) {
    final w = 150.0 - i * 40, top = o.dy - 120 - i * 110;
    final tier = Path()
      ..moveTo(o.dx - w, top + 120)
      ..lineTo(o.dx - w * .7, top)
      ..lineTo(o.dx + w * .7, top)
      ..lineTo(o.dx + w, top + 120)
      ..close();
    c.drawPath(
      tier,
      grad(tier.getBounds(), [
        i.isEven ? gold : red,
        i.isEven ? goldDark : redDark,
      ], vertical: false),
    );
    for (var k = -2; k <= 2; k++) {
      gem(c, Offset(o.dx + k * w * .3, top + 60), 9, k.isEven ? mirror : green);
    }
  }
  gem(c, Offset(o.dx, o.dy - 470), 22, red);
  final band = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: o + const Offset(0, 6),
      width: frx * 2 + 30,
      height: 46,
    ),
    const Radius.circular(20),
  );
  c.drawRRect(band, grad(band.outerRect, [goldLight, gold, goldDark]));
}

void bannadaCrown(Canvas c) {
  fanCrown(
    c,
    r: 330,
    bands: [black, red, white, red, gold],
    rays: black,
    bannadaStyle: true,
  );
}

// ---------------------------------------------------------------------------
// Props, held in the hands at (276,1085) and (748,1085).

void sword(Canvas c) {
  const h = Offset(748, 1085);
  final blade = Path()
    ..moveTo(h.dx - 10, h.dy - 30)
    ..lineTo(h.dx + 70, h.dy - 420)
    ..lineTo(h.dx + 92, h.dy - 400)
    ..lineTo(h.dx + 12, h.dy - 24)
    ..close();
  c.drawPath(
    blade,
    grad(blade.getBounds(), [
      const Color(0xFFF5F7FA),
      const Color(0xFF9AA5B1),
    ], vertical: false),
  );
  c.drawLine(
    h + const Offset(-40, -8),
    h + const Offset(40, -40),
    stroke(gold, 16),
  );
  c.drawLine(
    h + const Offset(0, 10),
    h + const Offset(-8, 60),
    stroke(goldDark, 18),
  );
  c.drawCircle(h, 40, fill(skin));
}

void bow(Canvas c) {
  const h = Offset(276, 1085);
  final arc = Path()
    ..moveTo(h.dx + 20, h.dy - 330)
    ..quadraticBezierTo(h.dx - 150, h.dy, h.dx + 20, h.dy + 300);
  c.drawPath(arc, stroke(const Color(0xFF6D3F1E), 18));
  c.drawPath(arc, stroke(gold, 4));
  c.drawLine(
    h + const Offset(20, -330),
    h + const Offset(20, 300),
    stroke(white, 3),
  );
  c.drawCircle(h, 40, fill(skin));
}

void mace(Canvas c) {
  const h = Offset(748, 1085);
  c.drawLine(
    h + const Offset(0, 40),
    h + const Offset(40, -330),
    stroke(const Color(0xFF6D3F1E), 20),
  );
  final head = h + const Offset(48, -390);
  c.drawOval(
    Rect.fromCenter(center: head, width: 120, height: 150),
    radial(head - const Offset(20, 25), 90, [goldLight, gold, goldDark]),
  );
  for (var i = 0; i < 3; i++) {
    c.drawLine(
      head + Offset(-60, -40.0 + i * 40),
      head + Offset(60, -40.0 + i * 40),
      stroke(goldDark, 5),
    );
  }
  gem(c, head + const Offset(0, -86), 12, red);
  c.drawCircle(h, 40, fill(skin));
}

// ---------------------------------------------------------------------------
// Vesha, the guide (768×768, scaled from the figure's head area).

void guide(Canvas c, String mood) {
  c.save();
  c.translate(384, 430);
  c.scale(1.25);
  c.translate(-fc.dx, -fc.dy);
  // Shoulders + small costume.
  final body = Path()
    ..moveTo(300, 760)
    ..quadraticBezierTo(512, 660, 724, 760)
    ..lineTo(760, 900)
    ..lineTo(264, 900)
    ..close();
  c.drawPath(body, grad(body.getBounds(), [red, redDark], vertical: false));
  c.drawRect(const Rect.fromLTRB(462, 600, 562, 700), fill(skinDark));
  chestPlate(c);
  drawEars(c);
  drawFaceShape(c, const Color(0xFFF2B48A), const Color(0xFFD98C62));
  c.drawCircle(fc + const Offset(0, -70), 8, fill(red));
  if (mood == 'think') {
    drawBrows(c, thick: 7, arch: 22, flare: -6);
    for (final s in [-1.0, 1.0]) {
      final e = fc + Offset(s * 46, -14);
      c.drawCircle(e, 16, fill(white));
      c.drawCircle(e + const Offset(8, -6), 8, fill(black));
    }
    drawMouth(c, smile: 2, width: 18);
    // Finger on chin.
    c.drawCircle(fc + const Offset(60, 130), 30, fill(skin));
    c.drawCircle(fc + const Offset(60, 130), 30, stroke(skinDark, 3));
  } else {
    drawBrows(c, thick: 7, arch: mood == 'happy' ? 24 : 16);
    if (mood == 'happy') {
      for (final s in [-1.0, 1.0]) {
        c.drawArc(
          Rect.fromCenter(
            center: fc + Offset(s * 46, -6),
            width: 54,
            height: 40,
          ),
          math.pi * 1.1,
          math.pi * .8,
          false,
          stroke(black, 7),
        );
      }
      final m = fc + const Offset(0, 74);
      c.drawPath(
        Path()
          ..moveTo(m.dx - 44, m.dy)
          ..quadraticBezierTo(m.dx, m.dy + 70, m.dx + 44, m.dy)
          ..close(),
        fill(const Color(0xFF8E2A22)),
      );
      c.drawOval(
        Rect.fromCenter(center: m + const Offset(0, 24), width: 40, height: 20),
        fill(const Color(0xFFE57373)),
      );
    } else {
      drawEyes(c, wings: true, lidWidth: 4);
      drawMouth(c, smile: 14, width: 30);
    }
    for (final s in [-1.0, 1.0]) {
      c.drawCircle(fc + Offset(s * 74, 50), 20, fill(const Color(0x55FF6F7F)));
    }
  }
  earDiscs(c);
  fanCrown(
    c,
    r: 210,
    bands: [gold, red, gold, green, goldLight],
    rays: goldDark,
  );
  c.restore();
}

// ---------------------------------------------------------------------------

Future<void> render(String path, Size size, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final img = await rec.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  test('draw dress-up layers and guide', () async {
    const dir = 'assets/dressup/layers';
    const s = Size(W, H);
    final layers = <String, void Function(Canvas)>{
      'base.png': base,
      'face/raja.png': faceRaja,
      'face/bannada.png': faceBannada,
      'face/stri.png': faceStri,
      'face/hasya.png': faceHasya,
      'costume/red.png': (c) => costume(c, red, redDark, gold, checks: true),
      'costume/green.png': (c) => costume(c, green, greenDark, gold),
      'costume/black.png': (c) =>
          costume(c, const Color(0xFF2A2A2A), black, red),
      'chest/gold.png': chestPlate,
      'chest/beads.png': beads,
      'shoulders/gold.png': (c) => shoulders(c, gold, goldDark),
      'shoulders/silver.png': (c) =>
          shoulders(c, const Color(0xFFD7DEE4), const Color(0xFF8E9AA4)),
      'ears/discs.png': earDiscs,
      'crown/kireeta.png': kireeta,
      'crown/pagade.png': pagade,
      'crown/kedage.png': kedage,
      'crown/bannada.png': bannadaCrown,
      'prop/sword.png': sword,
      'prop/bow.png': bow,
      'prop/mace.png': mace,
    };
    for (final e in layers.entries) {
      await render('$dir/${e.key}', s, e.value);
    }
    for (final m in ['idle', 'happy', 'think']) {
      await render(
        'assets/guide/vesha_$m.png',
        const Size(768, 768),
        (c) => guide(c, m),
      );
    }
    // Composite preview for review.
    await render('build/art_preview.png', s, (c) {
      c.drawRect(Offset.zero & s, fill(const Color(0xFFFFF4DE)));
      for (final f in [
        base,
        faceRaja,
        (Canvas c) => costume(c, red, redDark, gold, checks: true),
        chestPlate,
        (Canvas c) => shoulders(c, gold, goldDark),
        earDiscs,
        kireeta,
        sword,
      ]) {
        f(c);
      }
    });
  });
}

// Generates the placeholder art pack, dress-up layers, guide images,
// launcher icons and sounds. Run from vesha_puzzles/:
//
//   dart run tool/gen_placeholders.dart
//
// Every file it writes is a stand-in with the exact name and aspect the
// real asset must have (see docs/ART_GUIDE.md). Real art simply replaces
// the files; no code changes are needed.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

// Placeholder sizes (final art sizes are in docs/ART_GUIDE.md).
const puzzleW = 1200, puzzleH = 900;
const layerW = 512, layerH = 768;
const guideSize = 384;
const ss = 2; // supersampling factor

img.Color rgb(int c, [int a = 255]) =>
    img.ColorRgba8((c >> 16) & 255, (c >> 8) & 255, c & 255, a);

const red = 0xB3261E, gold = 0xE0A100, green = 0x2E7D32, black = 0x1B1411;
const cream = 0xFFF4DE, saffron = 0xF57C00, skin = 0xE9A97A, white = 0xFFFFFF;
const pink = 0xF2A7B8, blue = 0x1E5AA8, teal = 0x0F7C80, orange = 0xF08A12;

class Canvas {
  Canvas(int w, int h, {bool transparent = false})
    : im = img.Image(width: w * ss, height: h * ss, numChannels: 4) {
    if (transparent) img.fill(im, color: rgb(0, 0));
  }
  final img.Image im;
  int get w => im.width ~/ ss;
  int get h => im.height ~/ ss;

  void gradient(int top, int bottom) {
    for (var y = 0; y < im.height; y++) {
      final t = y / im.height;
      int mix(int s) =>
          (((top >> s) & 255) * (1 - t) + ((bottom >> s) & 255) * t).round();
      final c = img.ColorRgba8(mix(16), mix(8), mix(0), 255);
      img.drawLine(im, x1: 0, y1: y, x2: im.width - 1, y2: y, color: c);
    }
  }

  void circle(num x, num y, num r, int c, [int a = 255]) => img.fillCircle(
    im,
    x: (x * ss).round(),
    y: (y * ss).round(),
    radius: (r * ss).round(),
    color: rgb(c, a),
  );

  void ring(num x, num y, num r, int c, num t) {
    for (var i = 0; i < t * ss; i++) {
      img.drawCircle(
        im,
        x: (x * ss).round(),
        y: (y * ss).round(),
        radius: (r * ss).round() - i,
        color: rgb(c),
      );
    }
  }

  void rect(
    num x1,
    num y1,
    num x2,
    num y2,
    int c, [
    int a = 255,
    num radius = 0,
  ]) => img.fillRect(
    im,
    x1: (x1 * ss).round(),
    y1: (y1 * ss).round(),
    x2: (x2 * ss).round(),
    y2: (y2 * ss).round(),
    color: rgb(c, a),
    radius: radius * ss,
  );

  void poly(List<List<num>> pts, int c, [int a = 255]) => img.fillPolygon(
    im,
    vertices: [for (final p in pts) img.Point(p[0] * ss, p[1] * ss)],
    color: rgb(c, a),
  );

  void line(num x1, num y1, num x2, num y2, int c, num t) => img.drawLine(
    im,
    x1: (x1 * ss).round(),
    y1: (y1 * ss).round(),
    x2: (x2 * ss).round(),
    y2: (y2 * ss).round(),
    color: rgb(c),
    thickness: t * ss,
    antialias: true,
  );

  /// Ellipse via polygon.
  void oval(num cx, num cy, num rx, num ry, int c, [int a = 255]) => poly(
    [
      for (var i = 0; i < 48; i++)
        [
          cx + rx * math.cos(i * math.pi / 24),
          cy + ry * math.sin(i * math.pi / 24),
        ],
    ],
    c,
    a,
  );

  img.Image done() => img.copyResize(
    im,
    width: w,
    height: h,
    interpolation: img.Interpolation.average,
  );
}

void save(String path, img.Image image, {bool jpg = false}) {
  final f = File(path)..parent.createSync(recursive: true);
  f.writeAsBytesSync(
    jpg ? img.encodeJpg(image, quality: 82) : img.encodePng(image, level: 9),
  );
  stdout.writeln('wrote $path (${f.lengthSync() ~/ 1024} KB)');
}

// ---------------------------------------------------------------------------
// Shared motifs.

/// Fan-shaped crown (kireeta) of concentric half discs with mirror dots.
void crownFan(Canvas c, num cx, num cy, num r) {
  for (final (k, col) in [
    (1.0, gold),
    (0.82, red),
    (0.66, gold),
    (0.5, green),
  ]) {
    c.poly([
      for (var i = 0; i <= 32; i++)
        [
          cx + r * k * math.cos(math.pi + i * math.pi / 32),
          cy + r * k * math.sin(math.pi + i * math.pi / 32),
        ],
    ], col);
  }
  for (var i = 0; i <= 12; i++) {
    final a = math.pi + i * math.pi / 12;
    c.circle(
      cx + r * 0.91 * math.cos(a),
      cy + r * 0.91 * math.sin(a),
      r * 0.045,
      white,
    );
  }
}

void performer(
  Canvas c,
  num cx,
  num top,
  num s, {
  int body = red,
  int face = skin,
  int skirt = gold,
}) {
  // Skirt (kase), body (jacket), arms, head.
  c.poly([
    [cx - s * 0.9, top + s * 2.6],
    [cx + s * 0.9, top + s * 2.6],
    [cx + s * 0.45, top + s * 1.7],
    [cx - s * 0.45, top + s * 1.7],
  ], skirt);
  c.rect(
    cx - s * 0.45,
    top + s * 0.95,
    cx + s * 0.45,
    top + s * 1.8,
    body,
    255,
    s * 0.12,
  );
  c.line(
    cx - s * 0.45,
    top + s * 1.1,
    cx - s * 0.95,
    top + s * 1.6,
    body,
    s * 0.18,
  );
  c.line(
    cx + s * 0.45,
    top + s * 1.1,
    cx + s * 0.95,
    top + s * 0.7,
    body,
    s * 0.18,
  );
  c.circle(cx, top + s * 0.6, s * 0.38, face);
  c.circle(cx - s * 0.13, top + s * 0.55, s * 0.05, black);
  c.circle(cx + s * 0.13, top + s * 0.55, s * 0.05, black);
  c.rect(cx - s * 0.12, top + s * 0.78, cx + s * 0.12, top + s * 0.82, red);
}

void texture(Canvas c, int seed, List<int> colours, {int n = 140}) {
  final r = math.Random(seed);
  for (var i = 0; i < n; i++) {
    c.circle(
      r.nextDouble() * c.w,
      r.nextDouble() * c.h,
      3 + r.nextDouble() * 10,
      colours[r.nextInt(colours.length)],
      90,
    );
  }
}

void border(Canvas c, int col) {
  const t = 14;
  c.rect(0, 0, c.w, t, col);
  c.rect(0, c.h - t, c.w, c.h, col);
  c.rect(0, 0, t, c.h, col);
  c.rect(c.w - t, 0, c.w, c.h, col);
  for (var x = 30; x < c.w; x += 40) {
    c.circle(x, t / 2, 4, white);
    c.circle(x, c.h - t / 2, 4, white);
  }
}

/// Caption drawn on the final (not supersampled) image so it stays crisp.
void label(img.Image im, String id, String title) {
  final h = im.height;
  img.fillRect(
    im,
    x1: 24,
    y1: h - 104,
    x2: 40 + 26 * math.max(title.length, 15),
    y2: h - 26,
    color: rgb(black, 170),
    radius: 10,
  );
  img.drawString(
    im,
    title,
    font: img.arial48,
    x: 40,
    y: h - 100,
    color: rgb(white),
  );
  img.drawString(
    im,
    'PLACEHOLDER  $id',
    font: img.arial24,
    x: 42,
    y: h - 54,
    color: rgb(gold),
  );
}

// ---------------------------------------------------------------------------
// Puzzle placeholders.

typedef Painter = void Function(Canvas c);

final Map<String, (String, Painter)> puzzles = {
  'y01_raja_vesha': (
    'Raja Vesha',
    (c) {
      c.gradient(0x5B0E0A, 0x1B1411);
      texture(c, 1, [gold, red]);
      crownFan(c, 600, 380, 300);
      performer(c, 600, 230, 230, body: red, skirt: gold);
      crownFan(c, 600, 330, 120);
    },
  ),
  'y02_bannada_vesha': (
    'Bannada Vesha',
    (c) {
      c.gradient(0x111111, 0x3A0B0B);
      texture(c, 2, [red, white, gold]);
      c.oval(600, 420, 260, 300, red);
      c.oval(600, 440, 200, 230, black);
      for (var i = 0; i < 9; i++) {
        c.circle(440 + i * 40, 640, 12, white);
      }
      c.oval(520, 380, 60, 30, white);
      c.oval(680, 380, 60, 30, white);
      c.circle(520, 380, 16, black);
      c.circle(680, 380, 16, black);
      c.poly([
        [540, 520],
        [660, 520],
        [600, 580],
      ], white);
      crownFan(c, 600, 180, 240);
    },
  ),
  'y03_stri_vesha': (
    'Stri Vesha',
    (c) {
      c.gradient(0xF8D6DE, 0x2E7D32);
      texture(c, 3, [pink, gold, green]);
      c.oval(600, 330, 230, 170, black);
      performer(c, 600, 200, 220, body: green, skirt: pink, face: 0xF3C29B);
      for (var i = 0; i < 7; i++) {
        c.circle(470 + i * 43, 300, 14, gold);
      }
    },
  ),
  'y04_hasyagara': (
    'Hasyagara',
    (c) {
      c.gradient(0xFFE082, 0xF57C00);
      for (var x = 0; x < c.w; x += 100) {
        for (var y = 0; y < c.h; y += 100) {
          if ((x + y) ~/ 100 % 2 == 0)
            c.rect(x, y, x + 100, y + 100, white, 60);
        }
      }
      performer(c, 600, 220, 230, body: blue, skirt: red);
      c.poly([
        [480, 260],
        [720, 260],
        [600, 120],
      ], red);
      c.circle(600, 118, 26, gold);
      c.oval(600, 405, 80, 26, black);
    },
  ),
  'y05_himmela': (
    'Himmela',
    (c) {
      c.gradient(0x2B1B12, 0x7A4A1C);
      texture(c, 5, [gold, saffron]);
      // chende (tall drum), maddale (barrel drum), cymbals
      c.rect(250, 300, 390, 700, red, 255, 16);
      c.rect(250, 300, 390, 330, cream);
      c.line(230, 260, 330, 330, cream, 10);
      c.oval(640, 520, 190, 120, 0x8D5524);
      c.oval(450, 520, 40, 115, cream);
      c.oval(830, 520, 40, 115, cream);
      c.circle(960, 360, 70, gold);
      c.circle(1050, 420, 70, gold);
      c.circle(960, 360, 14, black);
      c.circle(1050, 420, 14, black);
    },
  ),
  'y06_chowki': (
    'Chowki',
    (c) {
      c.gradient(0x3E2723, 0x120B08);
      texture(c, 6, [gold, saffron], n: 60);
      // lamp
      c.poly([
        [520, 700],
        [680, 700],
        [640, 620],
        [560, 620],
      ], gold);
      c.rect(588, 420, 612, 620, gold);
      c.oval(600, 420, 110, 30, gold);
      c.oval(600, 360, 26, 60, 0xFFC400);
      c.oval(600, 375, 12, 28, white);
      // mirror and paint bowls
      c.oval(300, 360, 120, 160, 0x90A4AE);
      c.ring(300, 360, 128, gold, 10);
      for (final (x, col) in [
        (820, red),
        (920, white),
        (1020, 0x1565C0),
        (870, gold),
        (970, black),
      ]) {
        c.circle(x, x % 100 == 20 ? 600 : 680, 42, col);
        c.ring(x, x % 100 == 20 ? 600 : 680, 46, 0x6D4C41, 6);
      }
    },
  ),
  'y07_abhimanyu': (
    'Abhimanyu',
    (c) {
      c.gradient(0x0D47A1, 0x1B1411);
      for (var k = 9; k > 0; k--) {
        c.ring(600, 420, k * 42.0, k.isEven ? gold : red, 14);
      }
      performer(c, 600, 250, 130, body: saffron, skirt: green);
      c.line(700, 320, 820, 210, 0xB0BEC5, 10);
    },
  ),
  'y08_tala_maddale': (
    'Tala-Maddale',
    (c) {
      c.gradient(0xFFF4DE, 0xD7B98E);
      c.rect(100, 560, 1100, 640, 0x8D6E63, 255, 20);
      for (final (x, col) in [
        (260, white),
        (480, cream),
        (720, white),
        (940, 0xFFE0B2),
      ]) {
        c.oval(x, 520, 90, 60, col);
        c.circle(x, 400, 60, skin);
        c.ring(x, 400, 60, black, 4);
      }
      c.oval(600, 590, 80, 40, 0x8D5524);
    },
  ),
  'c01_pili_vesha': (
    'Pili Vesha',
    (c) {
      c.gradient(0xF9A825, 0xE65100);
      for (var i = -6; i < 16; i++) {
        c.poly(
          [
            [i * 90, 0],
            [i * 90 + 40, 0],
            [i * 90 + 260, c.h],
            [i * 90 + 220, c.h],
          ],
          black,
          200,
        );
      }
      c.oval(600, 430, 230, 210, orange);
      c.oval(600, 500, 120, 90, white);
      c.oval(520, 380, 40, 26, white);
      c.oval(680, 380, 40, 26, white);
      c.circle(520, 380, 14, black);
      c.circle(680, 380, 14, black);
      c.poly([
        [560, 450],
        [640, 450],
        [600, 490],
      ], black);
      for (var i = 0; i < 3; i++) {
        c.line(440, 470 + i * 20, 360, 450 + i * 30, black, 5);
        c.line(760, 470 + i * 20, 840, 450 + i * 30, black, 5);
      }
    },
  ),
  'c02_rathotsava': (
    'Rathotsava',
    (c) {
      c.gradient(0x4FC3F7, 0xFFF4DE);
      texture(c, 12, [saffron, red], n: 80);
      for (var i = 0; i < 6; i++) {
        final w = 300 - i * 40.0, y = 620 - i * 80.0;
        c.poly([
          [600 - w, y],
          [600 + w, y],
          [600 + w * 0.85, y - 80],
          [600 - w * 0.85, y - 80],
        ], i.isEven ? red : gold);
      }
      c.poly([
        [560, 140],
        [640, 140],
        [600, 40],
      ], saffron);
      c.circle(420, 680, 60, 0x5D4037);
      c.circle(780, 680, 60, 0x5D4037);
      c.line(600, 700, 1150, 860, 0x8D6E63, 8);
    },
  ),
  'c03_harbour_boats': (
    'Harbour Boats',
    (c) {
      c.gradient(0x81D4FA, 0x01579B);
      for (var y = 500; y < c.h; y += 40) {
        for (var x = 0; x < c.w; x += 80) {
          c.oval(x + (y % 80), y, 40, 8, white, 90);
        }
      }
      for (final (x, y, col) in [
        (300, 520, red),
        (650, 600, teal),
        (950, 540, gold),
      ]) {
        c.poly([
          [x - 160, y],
          [x + 160, y],
          [x + 110, y + 70],
          [x - 110, y + 70],
        ], col);
        c.rect(x - 4, y - 200, x + 4, y, 0x5D4037);
        c.poly([
          [x + 6, y - 190],
          [x + 120, y - 40],
          [x + 6, y - 40],
        ], white);
      }
    },
  ),
  'c04_mallige': (
    'Mallige',
    (c) {
      c.gradient(0x1B5E20, 0x0B3D0F);
      final r = math.Random(14);
      for (var s = 0; s < 9; s++) {
        final x0 = 120.0 + s * 120;
        for (var i = 0; i < 26; i++) {
          final x = x0 + 20 * math.sin(i / 3 + s), y = 40.0 + i * 32;
          c.oval(x, y, 9 + r.nextInt(3), 15, white);
          c.circle(x, y + 13, 4, 0xA5D6A7);
        }
      }
    },
  ),
};

// ---------------------------------------------------------------------------
// Dress-up placeholders (all layers share one canvas).

const lw = layerW, lh = layerH;
const fx = lw / 2, fy = 250; // face centre

final Map<String, Painter> layers = {
  'base.png': (c) {
    // Plain figure in a light under-dress.
    c.rect(fx - 40, fy + 60, fx + 40, fy + 110, skin);
    c.rect(fx - 110, fy + 100, fx + 110, fy + 360, cream, 255, 30);
    c.line(fx - 105, fy + 130, fx - 190, fy + 330, skin, 34);
    c.line(fx + 105, fy + 130, fx + 190, fy + 330, skin, 34);
    c.rect(fx - 100, fy + 350, fx - 20, fy + 500, skin, 255, 20);
    c.rect(fx + 20, fy + 350, fx + 100, fy + 500, skin, 255, 20);
    c.oval(fx, fy, 78, 92, skin);
    c.circle(fx - 28, fy - 8, 7, black);
    c.circle(fx + 28, fy - 8, 7, black);
    c.rect(fx - 22, fy + 40, fx + 22, fy + 46, 0x8D3B2B, 255, 3);
  },
  'face/raja.png': (c) {
    c.oval(fx, fy, 78, 92, 0xF5B98C);
    c.line(fx - 50, fy - 30, fx - 10, fy - 26, black, 6);
    c.line(fx + 10, fy - 26, fx + 50, fy - 30, black, 6);
    c.oval(fx - 28, fy - 6, 16, 9, white);
    c.oval(fx + 28, fy - 6, 16, 9, white);
    c.circle(fx - 28, fy - 6, 6, black);
    c.circle(fx + 28, fy - 6, 6, black);
    c.poly([
      [fx - 6, fy - 70],
      [fx + 6, fy - 70],
      [fx + 3, fy - 30],
      [fx - 3, fy - 30],
    ], red);
    c.rect(fx - 26, fy + 40, fx + 26, fy + 48, red, 255, 4);
  },
  'face/bannada.png': (c) {
    c.oval(fx, fy, 82, 96, red);
    c.oval(fx, fy + 20, 60, 50, white);
    c.oval(fx - 30, fy - 10, 22, 13, white);
    c.oval(fx + 30, fy - 10, 22, 13, white);
    c.circle(fx - 30, fy - 10, 8, black);
    c.circle(fx + 30, fy - 10, 8, black);
    for (var i = 0; i < 7; i++) {
      c.circle(fx - 66 + i * 22, fy + 78, 7, white);
    }
    c.rect(fx - 30, fy + 34, fx + 30, fy + 44, black, 255, 4);
  },
  'face/stri.png': (c) {
    c.oval(fx, fy, 76, 90, 0xF7C9A5);
    c.oval(fx - 28, fy - 6, 16, 9, white);
    c.oval(fx + 28, fy - 6, 16, 9, white);
    c.circle(fx - 28, fy - 6, 6, black);
    c.circle(fx + 28, fy - 6, 6, black);
    c.circle(fx, fy - 40, 6, red);
    c.oval(fx, fy + 44, 18, 7, 0xC2185B);
  },
  'face/hasya.png': (c) {
    c.oval(fx, fy, 78, 92, skin);
    c.circle(fx - 28, fy - 8, 9, black);
    c.circle(fx + 28, fy - 8, 9, black);
    c.circle(fx, fy + 12, 14, red);
    c.oval(fx, fy + 48, 34, 12, black);
    c.line(fx - 60, fy - 40, fx - 10, fy - 30, white, 6);
    c.line(fx + 10, fy - 30, fx + 60, fy - 40, white, 6);
  },
  'costume/red.png': (c) => _costume(c, red, gold),
  'costume/green.png': (c) => _costume(c, green, gold),
  'costume/black.png': (c) => _costume(c, black, red),
  'chest/gold.png': (c) {
    c.poly([
      [fx - 90, fy + 110],
      [fx + 90, fy + 110],
      [fx + 60, fy + 230],
      [fx - 60, fy + 230],
    ], gold);
    for (var i = 0; i < 5; i++) {
      c.circle(fx - 60 + i * 30, fy + 160, 9, red);
      c.circle(fx - 60 + i * 30, fy + 160, 4, white);
    }
  },
  'chest/beads.png': (c) {
    for (var k = 0; k < 3; k++) {
      for (var i = 0; i <= 12; i++) {
        final a = math.pi * i / 12;
        c.circle(
          fx - (70 + k * 14) * math.cos(a),
          fy + 110 + (60 + k * 22) * math.sin(a),
          7,
          k == 1 ? red : white,
        );
      }
    }
  },
  'shoulders/gold.png': (c) => _shoulders(c, gold),
  'shoulders/silver.png': (c) => _shoulders(c, 0xCFD8DC),
  'ears/discs.png': (c) {
    for (final s in [-1, 1]) {
      c.circle(fx + s * 92, fy + 10, 30, gold);
      c.circle(fx + s * 92, fy + 10, 14, red);
      c.circle(fx + s * 92, fy + 10, 5, white);
    }
  },
  'crown/kireeta.png': (c) => crownFan(c, fx, fy - 60, 190),
  'crown/pagade.png': (c) {
    c.oval(fx, fy - 90, 120, 60, red);
    c.rect(fx - 110, fy - 100, fx + 110, fy - 60, gold, 255, 12);
    for (var i = 0; i < 6; i++) {
      c.circle(fx - 90 + i * 36, fy - 80, 8, white);
    }
  },
  'crown/kedage.png': (c) {
    c.poly([
      [fx - 90, fy - 60],
      [fx + 90, fy - 60],
      [fx + 40, fy - 230],
      [fx - 40, fy - 230],
    ], gold);
    c.poly([
      [fx - 60, fy - 80],
      [fx + 60, fy - 80],
      [fx + 25, fy - 200],
      [fx - 25, fy - 200],
    ], red);
    c.circle(fx, fy - 236, 14, white);
  },
  'crown/bannada.png': (c) {
    crownFan(c, fx, fy - 50, 230);
    for (var i = 0; i < 5; i++) {
      c.circle(fx - 120 + i * 60, fy - 60, 14, black);
    }
  },
  'prop/sword.png': (c) {
    c.line(fx + 190, fy + 330, fx + 250, fy + 60, 0xCFD8DC, 16);
    c.line(fx + 165, fy + 300, fx + 215, fy + 315, gold, 12);
  },
  'prop/bow.png': (c) {
    for (var i = 0; i <= 20; i++) {
      final a = -math.pi / 2.6 + i * (math.pi / 1.3) / 20;
      c.circle(
        fx - 190 - 50 * math.cos(a),
        fy + 230 + 170 * math.sin(a),
        7,
        0x6D4C41,
      );
    }
    c.line(fx - 190, fy + 70, fx - 190, fy + 390, white, 3);
  },
  'prop/mace.png': (c) {
    c.line(fx + 190, fy + 340, fx + 220, fy + 140, 0x6D4C41, 14);
    c.oval(fx + 224, fy + 110, 46, 56, gold);
  },
};

void _costume(Canvas c, int body, int trim) {
  c.rect(fx - 112, fy + 100, fx + 112, fy + 330, body, 255, 30);
  c.poly([
    [fx - 160, fy + 520],
    [fx + 160, fy + 520],
    [fx + 100, fy + 320],
    [fx - 100, fy + 320],
  ], body);
  for (var y = fy + 340; y < fy + 520; y += 36) {
    c.rect(fx - 150, y, fx + 150, y + 10, trim);
  }
  c.rect(fx - 112, fy + 310, fx + 112, fy + 336, trim);
}

void _shoulders(Canvas c, int col) {
  for (final s in [-1, 1]) {
    c.poly([
      [fx + s * 100, fy + 110],
      [fx + s * 175, fy + 95],
      [fx + s * 165, fy + 160],
      [fx + s * 105, fy + 150],
    ], col);
    c.circle(fx + s * 140, fy + 125, 10, red);
  }
}

// ---------------------------------------------------------------------------
// Guide (Vesha) and icons.

void guide(Canvas c, String mood) {
  const cx = guideSize / 2, cy = 228.0;
  crownFan(c, cx, cy - 40, 150);
  c.rect(cx - 70, cy + 70, cx + 70, guideSize, red, 255, 30);
  c.oval(cx, cy, 82, 90, skin);
  c.circle(cx, cy - 52, 7, red);
  if (mood == 'think') {
    c.line(cx - 42, cy - 4, cx - 14, cy - 4, black, 6);
    c.circle(cx + 28, cy - 6, 9, black);
    c.oval(cx + 10, cy + 46, 16, 8, 0x8D3B2B);
    c.circle(cx + 120, cy - 120, 16, white);
    c.circle(cx + 145, cy - 150, 24, white);
  } else {
    c.circle(cx - 28, cy - 6, 9, black);
    c.circle(cx + 28, cy - 6, 9, black);
    if (mood == 'happy') {
      c.oval(cx, cy + 40, 30, 20, 0x8D3B2B);
      c.oval(cx, cy + 32, 30, 10, skin);
      c.circle(cx - 52, cy + 22, 12, pink);
      c.circle(cx + 52, cy + 22, 12, pink);
    } else {
      c.rect(cx - 20, cy + 38, cx + 20, cy + 46, 0x8D3B2B, 255, 4);
    }
  }
}

img.Image icon(int size) {
  final c = Canvas(size, size);
  c.rect(0, 0, size, size, red, 255, size * 0.22);
  crownFan(c, size / 2, size * 0.62, size * 0.36);
  c.circle(size / 2, size * 0.7, size * 0.16, skin);
  c.rect(
    size * 0.62,
    size * 0.62,
    size * 0.86,
    size * 0.86,
    gold,
    255,
    size * 0.04,
  );
  c.circle(size * 0.74, size * 0.6, size * 0.06, gold);
  return c.done();
}

// ---------------------------------------------------------------------------
// Sounds: short synthesized WAVs (mono, 22.05 kHz, 16-bit).

const rate = 22050;

Uint8List wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(
      44 + i * 2,
      (samples[i].clamp(-1.0, 1.0) * 32000).round(),
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

List<double> tone(
  double f,
  double secs, {
  double decay = 8,
  double vol = 0.6,
  double f2 = 0,
}) {
  final n = (secs * rate).round();
  return [
    for (var i = 0; i < n; i++)
      vol *
          math.exp(-decay * i / rate) *
          (math.sin(2 * math.pi * f * i / rate) +
              (f2 > 0 ? 0.5 * math.sin(2 * math.pi * f2 * i / rate) : 0)),
  ];
}

/// Drum hit: pitch-dropping sine plus a little noise (chende-like tap).
List<double> drum(double f, double secs, {double vol = 0.8, int seed = 1}) {
  final r = math.Random(seed);
  final n = (secs * rate).round();
  var phase = 0.0;
  return [
    for (var i = 0; i < n; i++)
      () {
        final t = i / rate;
        phase += 2 * math.pi * f * (1 + 1.5 * math.exp(-t * 40)) / rate;
        return vol *
            math.exp(-t * 18) *
            (math.sin(phase) +
                0.25 * (r.nextDouble() * 2 - 1) * math.exp(-t * 60));
      }(),
  ];
}

List<double> mixAt(List<double> base, List<double> add, double at) {
  final o = (at * rate).round();
  final out = [...base];
  while (out.length < o + add.length) {
    out.add(0);
  }
  for (var i = 0; i < add.length; i++) {
    out[o + i] += add[i];
  }
  return out;
}

void sounds(String dir) {
  void w(String name, List<double> s) {
    final f = File('$dir/$name')..parent.createSync(recursive: true);
    f.writeAsBytesSync(wav(s));
    stdout.writeln('wrote ${f.path} (${f.lengthSync() ~/ 1024} KB)');
  }

  w('pick.wav', tone(660, 0.08, decay: 40, vol: 0.35));
  w('tap.wav', tone(880, 0.05, decay: 60, vol: 0.3));
  w('snap.wav', drum(220, 0.18, vol: 0.7));
  w(
    'place.wav',
    mixAt(drum(180, 0.2), tone(990, 0.25, decay: 14, vol: 0.25), 0.03),
  );
  w(
    'unlock.wav',
    mixAt(
      mixAt(
        tone(784, 0.3, decay: 8, vol: 0.3),
        tone(988, 0.3, decay: 8, vol: 0.3),
        0.1,
      ),
      tone(1175, 0.4, decay: 6, vol: 0.3),
      0.2,
    ),
  );
  // Completion: a short drum roll then a bright chord (bell-like).
  var done = <double>[];
  for (var i = 0; i < 8; i++) {
    done = mixAt(done, drum(200 + i * 10, 0.15, vol: 0.5, seed: i), i * 0.07);
  }
  for (final f in [523.25, 659.25, 783.99]) {
    done = mixAt(done, tone(f, 1.2, decay: 3, vol: 0.22, f2: f * 2), 0.6);
  }
  w('complete.wav', done);
  // Music: 8-second loop on a pentatonic scale over a drum pulse.
  var music = List<double>.filled(8 * rate, 0);
  final notes = [293.66, 329.63, 392.0, 440.0, 493.88, 587.33];
  final r = math.Random(7);
  for (var b = 0; b < 32; b++) {
    music = mixAt(
      music,
      drum(b % 4 == 0 ? 150 : 210, 0.2, vol: b % 4 == 0 ? 0.35 : 0.18, seed: b),
      b * 0.25,
    );
    if (b % 2 == 0)
      music = mixAt(
        music,
        tone(notes[r.nextInt(notes.length)], 0.45, decay: 5, vol: 0.14),
        b * 0.25,
      );
  }
  w('music_loop.wav', music.sublist(0, 8 * rate));
}

void main() {
  for (final e in puzzles.entries) {
    final c = Canvas(puzzleW, puzzleH);
    e.value.$2(c);
    border(c, gold);
    final out = c.done();
    label(out, e.key.substring(0, 3), e.value.$1);
    final pack = e.key.startsWith('y') ? 'yakshagana' : 'karavali';
    save('assets/packs/$pack/images/${e.key}.jpg', out, jpg: true);
  }
  for (final e in layers.entries) {
    final c = Canvas(layerW, layerH, transparent: true);
    e.value(c);
    save('assets/dressup/layers/${e.key}', c.done());
  }
  for (final m in ['idle', 'happy', 'think']) {
    final c = Canvas(guideSize, guideSize, transparent: true);
    guide(c, m);
    save('assets/guide/vesha_$m.png', c.done());
  }
  const mip = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };
  for (final e in mip.entries) {
    save(
      'android/app/src/main/res/mipmap-${e.key}/ic_launcher.png',
      icon(e.value),
    );
  }
  save('docs/icon_512.png', icon(512));
  sounds('assets/audio');
}

/// Pre-renders every piece (clipped picture + bevel + outline) to a GPU
/// image so the board paints a handful of `drawImageRect` calls per frame
/// instead of re-clipping the source picture.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'board.dart';

class PieceImageCache {
  PieceImageCache(this.board, this.source);

  final JigsawBoard board;
  final ui.Image source;
  final Map<int, ui.Image> _images = {};
  double _scale = 0;

  /// Pixels per world unit the cached images were rendered at.
  double get scale => _scale;
  bool get isReady => _images.length == board.cut.count;

  ui.Image? operator [](int id) => _images[id];

  /// Largest useful scale: one source pixel per output pixel.
  double get maxScale => source.width / board.width;

  /// Renders all pieces at [requested] pixels/world unit (capped to the
  /// source resolution and to a texture budget). Returns true if images
  /// were (re)built.
  bool ensureScale(double requested) {
    final budget = math.sqrt(
      24e6 / 4 / (board.cut.count * _cellPxArea(1)),
    ); // ~24 MB total
    final target = math.min(requested, math.min(maxScale, budget));
    if (_scale > 0 && target <= _scale * 1.35 && target >= _scale * 0.5) {
      return false;
    }
    _renderAll(target);
    return true;
  }

  double _cellPxArea(double s) {
    final m = board.paths.margin;
    return (board.cellW + 2 * m) * s * (board.cellH + 2 * m) * s;
  }

  void _renderAll(double s) {
    dispose();
    _scale = s;
    for (var id = 0; id < board.cut.count; id++) {
      _images[id] = _render(id, s);
    }
  }

  /// World-space rectangle a cached piece image covers, relative to the
  /// piece's position.
  Rect get localRect {
    final m = board.paths.margin;
    return Rect.fromLTWH(-m, -m, board.cellW + 2 * m, board.cellH + 2 * m);
  }

  ui.Image _render(int id, double s) {
    final r = localRect;
    final w = (r.width * s).ceil(), h = (r.height * s).ceil();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(s);
    c.translate(-r.left, -r.top);
    final path = board.paths.pathOf(id);
    final home = board.home(id);

    c.save();
    c.clipPath(path);
    // Source pixels per world unit.
    final k = source.width / board.width;
    final world = r.shift(home);
    final src = Rect.fromLTRB(
      world.left * k,
      world.top * k,
      world.right * k,
      world.bottom * k,
    );
    c.drawImageRect(
      source,
      src,
      r,
      Paint()..filterQuality = FilterQuality.medium,
    );
    // Bevel: light along the top-left, shade along the bottom-right.
    final bw = math.min(board.cellW, board.cellH) * 0.035;
    c.drawPath(
      path.shift(Offset(bw, bw)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 2
        ..color = const Color(0x55FFFFFF),
    );
    c.drawPath(
      path.shift(Offset(-bw, -bw)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = bw * 2
        ..color = const Color(0x44000000),
    );
    c.restore();
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 / s
        ..color = const Color(0x66000000),
    );
    final pic = rec.endRecording();
    final img = pic.toImageSync(w, h);
    pic.dispose();
    return img;
  }

  void dispose() {
    for (final i in _images.values) {
      i.dispose();
    }
    _images.clear();
    _scale = 0;
  }
}

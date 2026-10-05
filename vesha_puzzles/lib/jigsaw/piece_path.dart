/// Outline of a jigsaw piece as a [Path].
library;

import 'dart:math' as math;
import 'dart:ui';

import 'cut.dart';

/// Builds piece outlines for a [JigsawCut] laid out on cells of
/// [cellW] × [cellH] world units. Paths are in piece-local coordinates:
/// (0, 0) is the top-left corner of the piece's home cell.
class PiecePaths {
  PiecePaths(this.cut, this.cellW, this.cellH) : _knob = math.min(cellW, cellH);

  final JigsawCut cut;
  final double cellW;
  final double cellH;
  final double _knob;
  final Map<int, Path> _cache = {};

  /// Space around the cell that knobs may occupy.
  double get margin => EdgeShape.maxExtent * _knob;

  Path pathOf(int id) => _cache.putIfAbsent(id, () => _build(id));

  /// Edge points in world coordinates (forward direction of the edge).
  List<Offset> _hEdgePoints(int r, int c) {
    final e = cut.hEdge(r, c);
    final x0 = c * cellW, y0 = (r + 1) * cellH;
    return [
      for (final (l, w) in e.unitPoints())
        Offset(x0 + l * cellW, y0 + w * _knob),
    ];
  }

  List<Offset> _vEdgePoints(int r, int c) {
    final e = cut.vEdge(r, c);
    final x0 = (c + 1) * cellW, y0 = r * cellH;
    return [
      for (final (l, w) in e.unitPoints())
        Offset(x0 + w * _knob, y0 + l * cellH),
    ];
  }

  Path _build(int id) {
    final r = cut.rowOf(id), c = cut.colOf(id);
    final ox = c * cellW, oy = r * cellH;
    final path = Path();
    Offset local(Offset p) => Offset(p.dx - ox, p.dy - oy);

    void curve(List<Offset> pts) {
      for (var i = 1; i + 2 < pts.length; i += 3) {
        final a = local(pts[i]), b = local(pts[i + 1]), d = local(pts[i + 2]);
        path.cubicTo(a.dx, a.dy, b.dx, b.dy, d.dx, d.dy);
      }
    }

    path.moveTo(0, 0);
    // Top: left → right.
    if (r == 0) {
      path.lineTo(cellW, 0);
    } else {
      curve(_hEdgePoints(r - 1, c));
    }
    // Right: top → bottom.
    if (c == cut.cols - 1) {
      path.lineTo(cellW, cellH);
    } else {
      curve(_vEdgePoints(r, c));
    }
    // Bottom: right → left.
    if (r == cut.rows - 1) {
      path.lineTo(0, cellH);
    } else {
      curve(_hEdgePoints(r, c).reversed.toList());
    }
    // Left: bottom → top.
    if (c == 0) {
      path.lineTo(0, 0);
    } else {
      curve(_vEdgePoints(r, c - 1).reversed.toList());
    }
    path.close();
    return path;
  }
}

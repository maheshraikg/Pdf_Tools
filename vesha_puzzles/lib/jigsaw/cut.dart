/// Jigsaw cut generation: grid size for a difficulty and the tab shape of
/// every internal edge, fully determined by a seed.
library;

import 'dart:math' as math;

enum Difficulty { easy, medium, hard, expert }

extension DifficultyInfo on Difficulty {
  /// Approximate number of pieces for this difficulty.
  int get targetPieces => switch (this) {
    Difficulty.easy => 12,
    Difficulty.medium => 24,
    Difficulty.hard => 48,
    Difficulty.expert => 80,
  };

  static Difficulty parse(String? s) => Difficulty.values.firstWhere(
    (d) => d.name == s,
    orElse: () => Difficulty.medium,
  );
}

class GridSize {
  const GridSize(this.rows, this.cols);
  final int rows;
  final int cols;
  int get count => rows * cols;

  @override
  bool operator ==(Object other) =>
      other is GridSize && other.rows == rows && other.cols == cols;
  @override
  int get hashCode => Object.hash(rows, cols);
  @override
  String toString() => '${rows}x$cols';
}

/// Picks rows × cols close to [target] pieces with pieces as square as
/// possible for an image of [aspect] (width / height).
GridSize gridFor(int target, double aspect) {
  GridSize? best;
  var bestCost = double.infinity;
  for (var cols = 2; cols <= 16; cols++) {
    for (var rows = 2; rows <= 16; rows++) {
      final pieceAspect = aspect * rows / cols;
      final cost =
          (rows * cols - target).abs() / target +
          0.6 * math.log(pieceAspect).abs();
      if (cost < bestCost) {
        bestCost = cost;
        best = GridSize(rows, cols);
      }
    }
  }
  return best!;
}

/// Shape of one shared edge. [sign] +1 means the knob points in the
/// positive perpendicular direction (down for horizontal edges, right for
/// vertical ones). The jitter values make every knob slightly different.
class EdgeShape {
  const EdgeShape(this.sign, this.a, this.b, this.c, this.d, this.e);
  final int sign;
  final double a, b, c, d, e;

  static const double tab = 0.1;

  /// Ten points of the three cubic segments in the unit edge frame
  /// (x along the edge 0..1, y perpendicular, scaled by [sign]).
  /// Based on the classic "Draradech" jigsaw edge.
  List<(double, double)> unitPoints() {
    const t = tab;
    final s = sign.toDouble();
    (double, double) p(double l, double w) => (l, w * s);
    return [
      p(0.0, 0.0),
      p(0.2, a),
      p(0.5 + b + d, -t + c),
      p(0.5 - t + b, t + c),
      p(0.5 - 2.0 * t + b - d, 3.0 * t + c),
      p(0.5 + 2.0 * t + b - d, 3.0 * t + c),
      p(0.5 + t + b, t + c),
      p(0.5 + b + d, -t + c),
      p(0.8, e),
      p(1.0, 0.0),
    ];
  }

  /// Largest perpendicular extent of the knob in edge-length units.
  static const double maxExtent = 3.0 * tab + 0.05;
}

/// Edge type as seen from one piece.
enum EdgeKind { flat, knob, hole }

class JigsawCut {
  JigsawCut._(this.rows, this.cols, this.seed, this._h, this._v);

  /// [seed] fully determines the tabs.
  factory JigsawCut.generate(int rows, int cols, int seed) {
    final rnd = math.Random(seed);
    const j = 0.04;
    double u() => (rnd.nextDouble() * 2 - 1) * j;
    EdgeShape edge() => EdgeShape(rnd.nextBool() ? 1 : -1, u(), u(), u(), u(), u());
    final h = List.generate((rows - 1) * cols, (_) => edge());
    final v = List.generate(rows * (cols - 1), (_) => edge());
    return JigsawCut._(rows, cols, seed, h, v);
  }

  final int rows;
  final int cols;
  final int seed;
  final List<EdgeShape> _h; // between row r and r+1, index r*cols+c
  final List<EdgeShape> _v; // between col c and c+1, index r*(cols-1)+c

  int get count => rows * cols;
  int idOf(int row, int col) => row * cols + col;
  int rowOf(int id) => id ~/ cols;
  int colOf(int id) => id % cols;

  /// Horizontal edge below row [r] (0 <= r < rows-1) in column [c].
  EdgeShape hEdge(int r, int c) => _h[r * cols + c];

  /// Vertical edge right of column [c] (0 <= c < cols-1) in row [r].
  EdgeShape vEdge(int r, int c) => _v[r * (cols - 1) + c];

  bool isEdgePiece(int id) {
    final r = rowOf(id), c = colOf(id);
    return r == 0 || c == 0 || r == rows - 1 || c == cols - 1;
  }

  bool isCorner(int id) {
    final r = rowOf(id), c = colOf(id);
    return (r == 0 || r == rows - 1) && (c == 0 || c == cols - 1);
  }

  EdgeKind _kind(int sign, {required bool outwardPositive}) {
    final out = outwardPositive ? sign > 0 : sign < 0;
    return out ? EdgeKind.knob : EdgeKind.hole;
  }

  EdgeKind top(int id) {
    final r = rowOf(id), c = colOf(id);
    if (r == 0) return EdgeKind.flat;
    return _kind(hEdge(r - 1, c).sign, outwardPositive: false);
  }

  EdgeKind bottom(int id) {
    final r = rowOf(id), c = colOf(id);
    if (r == rows - 1) return EdgeKind.flat;
    return _kind(hEdge(r, c).sign, outwardPositive: true);
  }

  EdgeKind left(int id) {
    final r = rowOf(id), c = colOf(id);
    if (c == 0) return EdgeKind.flat;
    return _kind(vEdge(r, c - 1).sign, outwardPositive: false);
  }

  EdgeKind right(int id) {
    final r = rowOf(id), c = colOf(id);
    if (c == cols - 1) return EdgeKind.flat;
    return _kind(vEdge(r, c).sign, outwardPositive: true);
  }

  /// 4-neighbours of a piece.
  Iterable<int> neighbours(int id) sync* {
    final r = rowOf(id), c = colOf(id);
    if (r > 0) yield idOf(r - 1, c);
    if (r < rows - 1) yield idOf(r + 1, c);
    if (c > 0) yield idOf(r, c - 1);
    if (c < cols - 1) yield idOf(r, c + 1);
  }
}

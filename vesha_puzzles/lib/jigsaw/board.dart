/// Game state of one jigsaw: pieces, groups, tray, snapping, completion.
///
/// World coordinates: the finished picture occupies the rectangle
/// (0, 0, cols*cellW, rows*cellH). A piece's home is its cell's top-left
/// corner. Pieces snapped together form a group; every piece in a group is
/// displaced from home by the same [PieceGroup.offset], so a group is
/// always internally correct. A group with offset zero that is locked has
/// been placed in the frame.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'cut.dart';
import 'piece_path.dart';

class PieceGroup {
  PieceGroup(this.id, this.pieces, this.offset, {this.locked = false});
  final int id;
  final Set<int> pieces;
  Offset offset;
  bool locked;
}

enum SnapKind { none, joined, placed }

class SnapResult {
  const SnapResult(this.kind, this.groupId);
  final SnapKind kind;
  final int groupId;
}

class JigsawBoard {
  JigsawBoard({
    required this.cut,
    this.cellW = 100,
    required this.cellH,
    List<int>? trayOrder,
  }) : paths = PiecePaths(cut, cellW, cellH) {
    for (var id = 0; id < cut.count; id++) {
      _groupOf[id] = id;
      _groups[id] = PieceGroup(id, {id}, Offset.zero);
    }
    _tray.addAll(trayOrder ?? _shuffled(cut.count, cut.seed));
  }

  final JigsawCut cut;
  final double cellW;
  final double cellH;
  final PiecePaths paths;

  final Map<int, int> _groupOf = {};
  final Map<int, PieceGroup> _groups = {};
  final List<int> _tray = [];

  /// Group ids from bottom to top (only groups on the board).
  final List<int> _z = [];

  double get width => cut.cols * cellW;
  double get height => cut.rows * cellH;
  Rect get frame => Rect.fromLTWH(0, 0, width, height);

  /// Area pieces can be moved within.
  Rect get bounds {
    final pad = math.max(width, height) * 0.6;
    return frame.inflate(pad);
  }

  /// Default snapping distance in world units.
  double get defaultTolerance => math.min(cellW, cellH) * 0.22;

  List<int> get tray => List.unmodifiable(_tray);
  bool inTray(int id) => _tray.contains(id);
  PieceGroup groupOfPiece(int id) => _groups[_groupOf[id]]!;
  PieceGroup? group(int gid) => _groups[gid];
  Iterable<PieceGroup> get groupsBottomToTop => _z.map((g) => _groups[g]!);

  Offset home(int id) => Offset(cut.colOf(id) * cellW, cut.rowOf(id) * cellH);
  Offset positionOf(int id) => home(id) + groupOfPiece(id).offset;
  bool isPlaced(int id) => !inTray(id) && groupOfPiece(id).locked;
  int get placedCount =>
      List.generate(cut.count, (i) => i).where(isPlaced).length;

  bool get isComplete => placedCount == cut.count;

  static List<int> _shuffled(int n, int seed) {
    final l = List.generate(n, (i) => i);
    l.shuffle(math.Random(seed ^ 0x5eed));
    return l;
  }

  /// Puts a tray piece on the board with its cell top-left at [topLeft].
  SnapResult placeFromTray(int id, Offset topLeft, {double? tolerance}) {
    if (!_tray.remove(id)) return SnapResult(SnapKind.none, _groupOf[id]!);
    final g = groupOfPiece(id);
    g.offset = _clampOffset(g, topLeft - home(id));
    _z.add(g.id);
    return endDrag(g.id, tolerance: tolerance);
  }

  /// Returns a board piece (and its whole group if it is not placed) to
  /// the tray. Only single, unplaced pieces can be returned.
  bool returnToTray(int id) {
    final g = groupOfPiece(id);
    if (inTray(id) || g.locked || g.pieces.length != 1) return false;
    _z.remove(g.id);
    g.offset = Offset.zero;
    _tray.insert(0, id);
    return true;
  }

  /// Top-most movable-or-placed piece at [world], or null.
  int? hitTest(Offset world) {
    for (final gid in _z.reversed) {
      final g = _groups[gid]!;
      for (final id in g.pieces) {
        final local = world - positionOf(id);
        if (paths.pathOf(id).contains(local)) return id;
      }
    }
    return null;
  }

  /// Raises a group to the top of the z-order.
  void bringToFront(int gid) {
    if (_z.remove(gid)) _z.add(gid);
  }

  void moveGroup(int gid, Offset delta) {
    final g = _groups[gid]!;
    if (g.locked) return;
    g.offset = _clampOffset(g, g.offset + delta);
  }

  void setGroupOffset(int gid, Offset offset) {
    final g = _groups[gid]!;
    if (g.locked) return;
    g.offset = offset;
  }

  Offset _clampOffset(PieceGroup g, Offset offset) {
    // Keep at least each group's first piece centre inside the bounds.
    final id = g.pieces.first;
    final centre = home(id) + Offset(cellW / 2, cellH / 2) + offset;
    final b = bounds;
    final cx = centre.dx.clamp(b.left, b.right);
    final cy = centre.dy.clamp(b.top, b.bottom);
    return offset + Offset(cx - centre.dx, cy - centre.dy);
  }

  /// Snaps a dropped group to the frame and/or its neighbours.
  SnapResult endDrag(int gid, {double? tolerance}) {
    final tol = tolerance ?? defaultTolerance;
    var current = gid;
    var kind = SnapKind.none;
    var changed = true;
    while (changed) {
      changed = false;
      final g = _groups[current]!;
      if (!g.locked && g.offset.distance <= tol) {
        g.offset = Offset.zero;
        g.locked = true;
        kind = SnapKind.placed;
        changed = true;
      }
      // Merge with neighbouring groups whose offset matches.
      for (final id in g.pieces.toList()) {
        for (final n in cut.neighbours(id)) {
          if (inTray(n)) continue;
          final other = groupOfPiece(n);
          if (other.id == g.id) continue;
          if ((other.offset - g.offset).distance <= tol) {
            if (g.locked && !other.locked) {
              other.offset = Offset.zero;
            }
            current = _merge(g, other).id;
            if (kind == SnapKind.none) kind = SnapKind.joined;
            if (_groups[current]!.locked) kind = SnapKind.placed;
            changed = true;
            break;
          }
        }
        if (changed) break;
      }
    }
    // A finished picture assembled anywhere snaps into the frame.
    final g = _groups[current]!;
    if (g.pieces.length == cut.count && !g.locked) {
      g.offset = Offset.zero;
      g.locked = true;
      kind = SnapKind.placed;
    }
    return SnapResult(kind, current);
  }

  /// Merges two groups; the result keeps [into]'s offset unless [other]
  /// is locked. Returns the surviving group.
  PieceGroup _merge(PieceGroup into, PieceGroup other) {
    final keep = other.locked ? other : into;
    final drop = identical(keep, into) ? other : into;
    for (final id in drop.pieces) {
      _groupOf[id] = keep.id;
    }
    keep.pieces.addAll(drop.pieces);
    keep.locked = keep.locked || drop.locked;
    _groups.remove(drop.id);
    final zi = _z.indexOf(keep.id);
    _z.remove(drop.id);
    if (!keep.locked) {
      _z.remove(keep.id);
      _z.add(keep.id);
    } else if (zi >= 0) {
      // Locked groups sit below everything movable.
      _z.remove(keep.id);
      _z.insert(0, keep.id);
    }
    return keep;
  }

  /// Picks a piece for a hint: an unplaced piece, preferring one next to
  /// already placed pieces, then edge pieces, then tray order.
  int? pickHintPiece() {
    final candidates = [
      for (var id = 0; id < cut.count; id++)
        if (!isPlaced(id)) id,
    ];
    if (candidates.isEmpty) return null;
    int score(int id) {
      var s = 0;
      if (cut.neighbours(id).any(isPlaced)) s += 4;
      if (cut.isEdgePiece(id)) s += 2;
      if (cut.isCorner(id)) s += 1;
      return s;
    }

    candidates.sort((a, b) {
      final d = score(b) - score(a);
      return d != 0 ? d : (_tray.indexOf(a)).compareTo(_tray.indexOf(b));
    });
    return candidates.first;
  }

  /// Places piece [id] (and its group) in the frame.
  SnapResult placePiece(int id) {
    if (inTray(id)) {
      return placeFromTray(id, home(id), tolerance: 1e-6);
    }
    final g = groupOfPiece(id);
    g.offset = Offset.zero;
    return endDrag(g.id, tolerance: 1e-6);
  }

  // ---- persistence -------------------------------------------------------

  Map<String, Object?> toJson() => {
    'rows': cut.rows,
    'cols': cut.cols,
    'seed': cut.seed,
    'cellH': cellH,
    'tray': _tray,
    'z': _z,
    'groups': [
      for (final g in _groups.values)
        if (!g.pieces.every(inTray))
          {
            'id': g.id,
            'p': g.pieces.toList()..sort(),
            'x': _round(g.offset.dx),
            'y': _round(g.offset.dy),
            'l': g.locked,
          },
    ],
  };

  static double _round(double v) => (v * 100).roundToDouble() / 100;

  /// Restores a board saved with [toJson]. Throws [FormatException] when
  /// the data is inconsistent.
  factory JigsawBoard.fromJson(Map<String, Object?> json) {
    int i(String k) => (json[k] as num).toInt();
    final cut = JigsawCut.generate(i('rows'), i('cols'), i('seed'));
    final tray = (json['tray'] as List).map((e) => (e as num).toInt()).toList();
    final b = JigsawBoard(
      cut: cut,
      cellH: (json['cellH'] as num).toDouble(),
      trayOrder: tray,
    );
    final seen = <int>{...tray};
    b._groups.clear();
    b._groupOf.clear();
    for (final id in tray) {
      b._groupOf[id] = id;
      b._groups[id] = PieceGroup(id, {id}, Offset.zero);
    }
    for (final raw in (json['groups'] as List).cast<Map>()) {
      final gid = (raw['id'] as num).toInt();
      final pieces = (raw['p'] as List).map((e) => (e as num).toInt()).toSet();
      for (final id in pieces) {
        if (id < 0 || id >= cut.count || !seen.add(id)) {
          throw const FormatException('piece listed twice or out of range');
        }
        b._groupOf[id] = gid;
      }
      b._groups[gid] = PieceGroup(
        gid,
        pieces,
        Offset((raw['x'] as num).toDouble(), (raw['y'] as num).toDouble()),
        locked: raw['l'] == true,
      );
    }
    if (seen.length != cut.count) {
      throw const FormatException('missing pieces');
    }
    final z = (json['z'] as List).map((e) => (e as num).toInt()).toList();
    final onBoard = b._groups.keys.where((g) => !tray.contains(g)).toSet();
    b._z
      ..addAll(z.where(onBoard.contains))
      ..addAll(onBoard.where((g) => !z.contains(g)));
    return b;
  }
}

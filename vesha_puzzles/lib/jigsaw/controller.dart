/// Glue between a [JigsawBoard], its piece images and the on-screen view:
/// viewport (zoom/pan), dragging, tray, ghost image and hints.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'board.dart';
import 'piece_cache.dart';

class JigsawController extends ChangeNotifier {
  JigsawController({required this.board, required ui.Image image})
    : cache = PieceImageCache(board, image);

  final JigsawBoard board;
  final PieceImageCache cache;
  ui.Image get image => cache.source;

  /// Repaints the board (fires on every drag frame).
  final ValueNotifier<int> boardTick = ValueNotifier(0);

  /// Fires when the set of tray pieces (or its filter) changes.
  final ValueNotifier<int> trayTick = ValueNotifier(0);

  // ---- viewport -------------------------------------------------------
  double scale = 1;
  Offset pan = Offset.zero;
  Size viewSize = Size.zero;
  double devicePixelRatio = 1;
  static const double minZoom = 0.6, maxZoom = 5;
  double _fitScale = 1;

  Offset toWorld(Offset screen) => (screen - pan) / scale;
  Offset toScreen(Offset world) => world * scale + pan;

  /// Fits the frame (plus a margin) into [size].
  void fit(Size size) {
    viewSize = size;
    if (size.isEmpty) return;
    final f = board.frame;
    _fitScale = math.min(size.width / (f.width * 1.12), size.height / (f.height * 1.12));
    scale = _fitScale;
    pan = Offset(
      (size.width - f.width * scale) / 2,
      (size.height - f.height * scale) / 2,
    );
    _refreshCache();
    _tickBoard();
    trayTick.value++;
  }

  void resize(Size size) {
    if (viewSize.isEmpty) {
      fit(size);
      return;
    }
    if (size == viewSize) return;
    // Keep the centre of the view on the same world point.
    final centre = toWorld(viewSize.center(Offset.zero));
    viewSize = size;
    pan = size.center(Offset.zero) - centre * scale;
    _tickBoard();
  }

  void setView(double newScale, Offset newPan) {
    scale = newScale.clamp(_fitScale * minZoom, _fitScale * maxZoom);
    pan = newPan;
    _tickBoard();
  }

  void zoomBy(double factor) {
    final c = viewSize.center(Offset.zero);
    final w = toWorld(c);
    final s = (scale * factor).clamp(_fitScale * minZoom, _fitScale * maxZoom);
    setView(s, c - w * s);
    zoomEnded();
  }

  /// Called when a zoom gesture ends: sharper piece images if needed.
  void zoomEnded() {
    if (_refreshCache()) _tickBoard();
  }

  bool _refreshCache() => cache.ensureScale(scale * devicePixelRatio);

  // ---- options --------------------------------------------------------
  bool showGhost = false;
  bool edgesOnly = false;

  void toggleGhost() {
    showGhost = !showGhost;
    _tickBoard();
    notifyListeners();
  }

  void toggleEdgesOnly() {
    edgesOnly = !edgesOnly;
    trayTick.value++;
    notifyListeners();
  }

  List<int> get visibleTray => [
    for (final id in board.tray)
      if (!edgesOnly || board.cut.isEdgePiece(id)) id,
  ];

  // ---- interaction ----------------------------------------------------
  int? draggingGroup;
  int moves = 0;
  int? highlightPiece;

  void Function(SnapResult result)? onSnap;
  VoidCallback? onPick;
  VoidCallback? onChanged;
  VoidCallback? onComplete;

  /// Starts dragging the group under [screen]; returns false if nothing
  /// movable is there.
  bool beginDrag(Offset screen) {
    final id = board.hitTest(toWorld(screen));
    if (id == null) return false;
    final g = board.groupOfPiece(id);
    if (g.locked) return false;
    draggingGroup = g.id;
    board.bringToFront(g.id);
    onPick?.call();
    _tickBoard();
    return true;
  }

  void dragBy(Offset screenDelta) {
    final g = draggingGroup;
    if (g == null) return;
    board.moveGroup(g, screenDelta / scale);
    _tickBoard();
  }

  void endDrag() {
    final g = draggingGroup;
    if (g == null) return;
    draggingGroup = null;
    moves++;
    _afterSnap(board.endDrag(g, tolerance: _tolerance));
  }

  /// Snap distance: generous on small screens (at least ~14 dp).
  double get _tolerance =>
      math.max(board.defaultTolerance, 14 / scale);

  void dropFromTray(int id, Offset screen) {
    final centre = toWorld(screen);
    final topLeft = centre - Offset(board.cellW / 2, board.cellH / 2);
    moves++;
    final r = board.placeFromTray(id, topLeft, tolerance: _tolerance);
    trayTick.value++;
    _afterSnap(r);
  }

  /// Tap on a tray piece: drop it somewhere visible near the frame.
  void dropFromTrayAuto(int id) {
    final rnd = math.Random(id * 31 + moves);
    final v = Rect.fromPoints(toWorld(Offset.zero), toWorld(viewSize.bottomRight(Offset.zero)));
    final f = board.frame;
    // Prefer the strip below the frame if visible, else anywhere visible.
    final below = Rect.fromLTRB(v.left, f.bottom + board.cellH * 0.2, v.right, v.bottom);
    final area = below.height > board.cellH ? below : v.deflate(board.cellW / 2);
    final p = Offset(
      area.left + rnd.nextDouble() * math.max(1, area.width - board.cellW),
      area.top + rnd.nextDouble() * math.max(1, area.height - board.cellH),
    );
    moves++;
    final r = board.placeFromTray(id, p, tolerance: _tolerance);
    trayTick.value++;
    _afterSnap(r);
  }

  bool returnToTray(Offset screen) {
    final id = board.hitTest(toWorld(screen));
    if (id == null || !board.returnToTray(id)) return false;
    trayTick.value++;
    _tickBoard();
    onChanged?.call();
    return true;
  }

  /// Places one piece for the player. Returns false if nothing is left.
  bool useHint() {
    final id = board.pickHintPiece();
    if (id == null) return false;
    final wasTray = board.inTray(id);
    final r = board.placePiece(id);
    highlightPiece = id;
    if (wasTray) trayTick.value++;
    _afterSnap(r);
    return true;
  }

  void clearHighlight() {
    highlightPiece = null;
    _tickBoard();
  }

  void _afterSnap(SnapResult r) {
    _tickBoard();
    onSnap?.call(r);
    onChanged?.call();
    notifyListeners();
    if (board.isComplete) onComplete?.call();
  }

  void _tickBoard() => boardTick.value++;

  @override
  void dispose() {
    cache.dispose();
    boardTick.dispose();
    trayTick.dispose();
    super.dispose();
  }
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesha_puzzles/jigsaw/board.dart';
import 'package:vesha_puzzles/jigsaw/cut.dart';

void main() {
  group('grid', () {
    test('piece counts are close to the target and pieces near square', () {
      for (final d in Difficulty.values) {
        for (final aspect in [4 / 3, 1.0, 3 / 4, 16 / 9]) {
          final g = gridFor(d.targetPieces, aspect);
          expect(
            (g.count - d.targetPieces).abs() / d.targetPieces,
            lessThan(0.3),
            reason: '$d $aspect -> $g',
          );
          final pieceAspect = aspect * g.rows / g.cols;
          expect(pieceAspect, inInclusiveRange(0.7, 1.45), reason: '$d $aspect');
        }
      }
    });

    test('4:3 easy is 3x4', () {
      expect(gridFor(12, 4 / 3), const GridSize(3, 4));
    });
  });

  group('cut', () {
    test('same seed gives the same cut, different seed differs', () {
      final a = JigsawCut.generate(4, 5, 42);
      final b = JigsawCut.generate(4, 5, 42);
      final c = JigsawCut.generate(4, 5, 43);
      String sig(JigsawCut x) => [
        for (var id = 0; id < x.count; id++)
          '${x.top(id)}${x.right(id)}${x.bottom(id)}${x.left(id)}',
      ].join();
      expect(sig(a), sig(b));
      expect(sig(a), isNot(sig(c)));
    });

    test('neighbouring edges are complementary, border edges flat', () {
      final cut = JigsawCut.generate(5, 6, 7);
      for (var id = 0; id < cut.count; id++) {
        final r = cut.rowOf(id), c = cut.colOf(id);
        if (r == 0) expect(cut.top(id), EdgeKind.flat);
        if (c == 0) expect(cut.left(id), EdgeKind.flat);
        if (r == cut.rows - 1) expect(cut.bottom(id), EdgeKind.flat);
        if (c == cut.cols - 1) expect(cut.right(id), EdgeKind.flat);
        if (c < cut.cols - 1) {
          final right = cut.right(id), left = cut.left(id + 1);
          expect(right, isNot(EdgeKind.flat));
          expect(right == EdgeKind.knob, left == EdgeKind.hole);
        }
        if (r < cut.rows - 1) {
          final bottom = cut.bottom(id), top = cut.top(id + cut.cols);
          expect(bottom == EdgeKind.knob, top == EdgeKind.hole);
        }
      }
    });

    test('edge and corner pieces', () {
      final cut = JigsawCut.generate(3, 4, 1);
      expect([for (var i = 0; i < 12; i++) if (cut.isCorner(i)) i], [0, 3, 8, 11]);
      expect([for (var i = 0; i < 12; i++) if (!cut.isEdgePiece(i)) i], [5, 6]);
    });
  });

  group('paths', () {
    test('piece paths stay within cell + margin and contain the cell centre', () {
      final b = JigsawBoard(cut: JigsawCut.generate(4, 4, 3), cellH: 80);
      final m = b.paths.margin;
      for (var id = 0; id < b.cut.count; id++) {
        final p = b.paths.pathOf(id);
        final bounds = p.getBounds();
        expect(bounds.left, greaterThanOrEqualTo(-m - 0.01));
        expect(bounds.top, greaterThanOrEqualTo(-m - 0.01));
        expect(bounds.right, lessThanOrEqualTo(100 + m + 0.01));
        expect(bounds.bottom, lessThanOrEqualTo(80 + m + 0.01));
        expect(p.contains(const Offset(50, 40)), isTrue);
      }
    });

    test('a knob of one piece fills the hole of its neighbour', () {
      final b = JigsawBoard(cut: JigsawCut.generate(1, 2, 9), cellH: 100);
      final knobLeft = b.cut.right(0) == EdgeKind.knob;
      // A point just across the shared edge at the knob's middle.
      final probe = Offset(knobLeft ? 112 : 88, 50);
      final owner = knobLeft ? 0 : 1;
      final other = 1 - owner;
      Offset local(int id) => probe - b.home(id);
      expect(b.paths.pathOf(owner).contains(local(owner)), isTrue);
      expect(b.paths.pathOf(other).contains(local(other)), isFalse);
    });
  });

  group('board', () {
    JigsawBoard make() => JigsawBoard(cut: JigsawCut.generate(3, 4, 11), cellH: 90);

    test('starts with every piece in the tray', () {
      final b = make();
      expect(b.tray.toSet(), {for (var i = 0; i < 12; i++) i});
      expect(b.placedCount, 0);
      expect(b.isComplete, isFalse);
    });

    test('dropping near home places and locks', () {
      final b = make();
      final r = b.placeFromTray(5, b.home(5) + const Offset(8, -6));
      expect(r.kind, SnapKind.placed);
      expect(b.isPlaced(5), isTrue);
      expect(b.positionOf(5), b.home(5));
    });

    test('dropping far away does not snap', () {
      final b = make();
      final r = b.placeFromTray(5, b.home(5) + const Offset(300, 200));
      expect(r.kind, SnapKind.none);
      expect(b.isPlaced(5), isFalse);
      expect(b.inTray(5), isFalse);
    });

    test('neighbours join into a group off the frame and move together', () {
      final b = make();
      const away = Offset(250, 300);
      b.placeFromTray(0, b.home(0) + away);
      final r = b.placeFromTray(1, b.home(1) + away + const Offset(5, 4));
      expect(r.kind, SnapKind.joined);
      expect(b.groupOfPiece(0).id, b.groupOfPiece(1).id);
      expect(b.positionOf(1) - b.positionOf(0), b.home(1) - b.home(0));
      b.moveGroup(b.groupOfPiece(0).id, const Offset(10, 10));
      expect(b.positionOf(1) - b.positionOf(0), b.home(1) - b.home(0));
      // Dropping the pair near home places both.
      final gid = b.groupOfPiece(0).id;
      b.setGroupOffset(gid, const Offset(6, 6));
      expect(b.endDrag(gid).kind, SnapKind.placed);
      expect(b.isPlaced(0) && b.isPlaced(1), isTrue);
    });

    test('non-neighbours do not join', () {
      final b = make();
      const away = Offset(250, 300);
      b.placeFromTray(0, b.home(0) + away);
      final r = b.placeFromTray(6, b.home(6) + away);
      expect(r.kind, SnapKind.none);
      expect(b.groupOfPiece(0).id, isNot(b.groupOfPiece(6).id));
    });

    test('a piece dropped next to a placed neighbour is placed', () {
      final b = make();
      b.placePiece(0);
      final r = b.placeFromTray(1, b.home(1) + const Offset(10, 10));
      expect(r.kind, SnapKind.placed);
      expect(b.groupOfPiece(0).id, b.groupOfPiece(1).id);
    });

    test('locked groups cannot be moved', () {
      final b = make();
      b.placePiece(3);
      b.moveGroup(b.groupOfPiece(3).id, const Offset(50, 50));
      expect(b.positionOf(3), b.home(3));
    });

    test('completing via hints', () {
      final b = make();
      var n = 0;
      while (!b.isComplete) {
        final id = b.pickHintPiece()!;
        b.placePiece(id);
        n++;
      }
      expect(n, lessThanOrEqualTo(12));
      expect(b.pickHintPiece(), isNull);
      expect(b.groupsBottomToTop.length, 1);
    });

    test('hint prefers pieces next to placed ones', () {
      final b = make();
      b.placePiece(0);
      final h = b.pickHintPiece()!;
      expect(b.cut.neighbours(0), contains(h));
    });

    test('an assembled picture anywhere snaps into the frame', () {
      final b = JigsawBoard(cut: JigsawCut.generate(2, 2, 4), cellH: 100);
      const away = Offset(100, 0);
      for (var id = 0; id < 4; id++) {
        b.placeFromTray(id, b.home(id) + away);
      }
      expect(b.isComplete, isTrue);
    });

    test('hit test finds the top-most piece', () {
      final b = make();
      b.placeFromTray(2, const Offset(500, 500));
      b.placeFromTray(7, const Offset(500, 500));
      expect(b.hitTest(const Offset(550, 545)), 7);
      b.bringToFront(b.groupOfPiece(2).id);
      expect(b.hitTest(const Offset(550, 545)), 2);
      expect(b.hitTest(const Offset(-900, -900)), isNull);
    });

    test('positions are clamped to the bounds', () {
      final b = make();
      b.placeFromTray(4, const Offset(1e6, 1e6));
      final c = b.positionOf(4) + Offset(b.cellW / 2, b.cellH / 2);
      expect(b.bounds.inflate(0.01).contains(c), isTrue);
    });

    test('return to tray', () {
      final b = make();
      b.placeFromTray(4, const Offset(500, 500));
      expect(b.returnToTray(4), isTrue);
      expect(b.inTray(4), isTrue);
      expect(b.tray.first, 4);
      b.placePiece(4);
      expect(b.returnToTray(4), isFalse);
    });

    test('save and restore round-trips', () {
      final b = make();
      const away = Offset(250, 300);
      b.placeFromTray(0, b.home(0) + away);
      b.placeFromTray(1, b.home(1) + away);
      b.placePiece(11);
      b.placeFromTray(6, const Offset(-100, 20));
      final json = jsonDecode(jsonEncode(b.toJson())) as Map<String, Object?>;
      final r = JigsawBoard.fromJson(json);
      expect(r.tray, b.tray);
      for (var id = 0; id < 12; id++) {
        expect(r.inTray(id), b.inTray(id), reason: '$id');
        expect(r.isPlaced(id), b.isPlaced(id), reason: '$id');
        if (!b.inTray(id)) expect(r.positionOf(id), b.positionOf(id));
      }
      expect(r.groupOfPiece(0).id, r.groupOfPiece(1).id);
      expect(r.hitTest(const Offset(-50, 60)), 6);
    });

    test('restore rejects corrupt data', () {
      final json = make().toJson();
      json['tray'] = [0, 0, 1];
      expect(() => JigsawBoard.fromJson(json), throwsFormatException);
    });
  });
}

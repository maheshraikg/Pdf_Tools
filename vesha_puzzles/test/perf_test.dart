// Rough performance guard for the engine at the largest difficulty.
// Thresholds are generous (CI machines vary); timings are printed.
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesha_puzzles/jigsaw/board.dart';
import 'package:vesha_puzzles/jigsaw/cut.dart';
import 'package:vesha_puzzles/jigsaw/piece_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  JigsawBoard expert() {
    final g = gridFor(Difficulty.expert.targetPieces, 4 / 3);
    return JigsawBoard(cut: JigsawCut.generate(g.rows, g.cols, 5), cellH: 100);
  }

  test('expert board: hit tests, drags and snaps are fast', () {
    final b = expert();
    final sw = Stopwatch()..start();
    for (var id = 0; id < b.cut.count; id++) {
      b.paths.pathOf(id);
    }
    final pathsMs = sw.elapsedMilliseconds;
    for (final id in b.tray.toList()) {
      b.placeFromTray(id, Offset(-300.0 - id, 1200.0 + id * 3));
    }
    sw.reset();
    var hits = 0;
    for (var i = 0; i < 2000; i++) {
      if (b.hitTest(Offset(-250.0 + i % 40, 1250.0 + i % 300)) != null) hits++;
    }
    final hitUs = sw.elapsedMicroseconds / 2000;
    sw.reset();
    for (var i = 0; i < 2000; i++) {
      final gid = b.groupOfPiece(i % b.cut.count).id;
      b.moveGroup(gid, const Offset(0.5, 0.5));
      b.endDrag(gid);
    }
    final dragUs = sw.elapsedMicroseconds / 2000;
    // ignore: avoid_print
    print(
      'expert ${b.cut.rows}x${b.cut.cols}: paths ${pathsMs}ms, hitTest ${hitUs.toStringAsFixed(1)}µs, move+snap ${dragUs.toStringAsFixed(1)}µs, hits $hits',
    );
    expect(hitUs, lessThan(2000));
    expect(dragUs, lessThan(2000));
  });

  test('piece cache renders expert pieces within the memory budget', () {
    final b = expert();
    final rec = ui.PictureRecorder();
    Canvas(rec).drawRect(
      const Rect.fromLTWH(0, 0, 2048, 1536),
      Paint()..color = const Color(0xFF884422),
    );
    final src = rec.endRecording().toImageSync(2048, 1536);
    final cache = PieceImageCache(b, src);
    final sw = Stopwatch()..start();
    cache.ensureScale(3.0);
    final ms = sw.elapsedMilliseconds;
    var bytes = 0;
    for (var id = 0; id < b.cut.count; id++) {
      final i = cache[id]!;
      bytes += i.width * i.height * 4;
    }
    // ignore: avoid_print
    print(
      'cache: scale ${cache.scale.toStringAsFixed(2)}, ${(bytes / 1e6).toStringAsFixed(1)} MB, ${ms}ms',
    );
    expect(bytes, lessThan(26e6));
    expect(
      cache.ensureScale(3.1),
      isFalse,
      reason: 'small zoom changes must not re-render',
    );
    cache.dispose();
    src.dispose();
  });
}

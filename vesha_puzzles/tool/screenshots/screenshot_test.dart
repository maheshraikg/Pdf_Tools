// Renders the main screens to PNG for visual review (not part of CI).
//
//   flutter test tool/screenshots/screenshot_test.dart
//
// Needs Roboto (from the Flutter SDK cache) and Noto Sans Kannada
// (apt install fonts-noto-core). Output: docs/screenshots/*.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesha_puzzles/app/scope.dart';
import 'package:vesha_puzzles/app/storage.dart';
import 'package:vesha_puzzles/app/theme.dart';
import 'package:vesha_puzzles/game/audio.dart';
import 'package:vesha_puzzles/game/progress.dart';
import 'package:vesha_puzzles/jigsaw/cut.dart';
import 'package:vesha_puzzles/packs/content.dart';
import 'package:vesha_puzzles/packs/loader.dart';
import 'package:vesha_puzzles/screens/dress_up_screen.dart';
import 'package:vesha_puzzles/screens/home_screen.dart';
import 'package:vesha_puzzles/screens/library_screen.dart';
import 'package:vesha_puzzles/screens/progress_screen.dart';
import 'package:vesha_puzzles/screens/puzzle_screen.dart';
import 'package:vesha_puzzles/screens/story_screen.dart';

Future<void> loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(
      Future.value(ByteData.view(File(p).readAsBytesSync().buffer)),
    );
  }
  await loader.load();
}

void main() {
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final mf = '$sdk/bin/cache/artifacts/material_fonts';
  const noto = '/usr/share/fonts/truetype/noto';
  late Content content;

  setUpAll(() async {
    await loadFont('Roboto', [
      '$mf/Roboto-Regular.ttf',
      '$mf/Roboto-Medium.ttf',
      '$mf/Roboto-Bold.ttf',
    ]);
    await loadFont('MaterialIcons', ['$mf/MaterialIcons-Regular.otf']);
    await loadFont('NotoKannada', [
      '$noto/NotoSansKannada-Regular.ttf',
      '$noto/NotoSansKannada-Bold.ttf',
    ]);
    debugFontFallback = ['NotoKannada'];
    content = await ContentLoader(rootBundle).load();
    Directory('docs/screenshots').createSync(recursive: true);
  });

  AppState state(Lang lang) {
    final s = AppState(
      store: MemoryStore(),
      content: content,
      audio: AudioService(enabled: false),
      clock: () => DateTime(2026, 10, 15, 10),
    );
    s.updateSettings((x) => x.lang = lang);
    for (final id in [
      'y01_raja_vesha',
      'y02_bannada_vesha',
      'c01_pili_vesha',
    ]) {
      s.complete(
        Completion(
          puzzleId: id,
          difficulty: Difficulty.medium,
          ms: 312000,
          hints: id.length % 3,
          when: DateTime(2026, 10, 14),
          daily: id == 'y01_raja_vesha',
        ),
      );
    }
    return s;
  }

  Future<void> shot(
    WidgetTester t,
    String name,
    AppState s,
    Widget home, {
    Future<void> Function()? after,
  }) async {
    t.view.physicalSize = const Size(1080, 2280);
    t.view.devicePixelRatio = 2.75;
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: AppScope(
          state: s,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            home: home,
          ),
        ),
      ),
    );
    // Let images decode.
    for (var i = 0; i < 4; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await t.pump(const Duration(milliseconds: 100));
    }
    if (after != null) await after();
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1.25);
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('docs/screenshots/$name.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 3));
  }

  testWidgets('screenshots', (t) async {
    await shot(t, 'en_1_home', state(Lang.en), const HomeScreen());
    await shot(t, 'en_2_library', state(Lang.en), const LibraryScreen());
    final p = content.puzzle('y07_abhimanyu')!;
    await shot(
      t,
      'en_3_puzzle',
      state(Lang.en),
      PuzzleScreen(
        puzzle: p,
        difficulty: Difficulty.medium,
        saveKey: p.id,
        seed: 3,
      ),
      after: () async {
        final c =
            (t.state(find.byType(PuzzleScreen)) as dynamic).debugController;
        // Place some pieces, drop a few loose ones near the frame.
        for (var i = 0; i < 9; i++) {
          c.board.placePiece(c.board.pickHintPiece());
        }
        for (final id in (c.board.tray as List<int>).take(5).toList()) {
          c.dropFromTrayAuto(id);
        }
        await t.pump(const Duration(milliseconds: 100));
      },
    );
    await shot(
      t,
      'en_4_story',
      state(Lang.en),
      StoryScreen(
        story: content.stories['y02_bannada_vesha']!,
        puzzle: content.puzzle('y02_bannada_vesha'),
      ),
    );
    await shot(t, 'en_5_dressup', state(Lang.en), const DressUpScreen());
    await shot(t, 'en_6_achievements', state(Lang.en), const ProgressScreen());
    await shot(t, 'kn_1_home', state(Lang.kn), const HomeScreen());
    await shot(
      t,
      'tcy_4_story',
      state(Lang.tcy),
      StoryScreen(
        story: content.stories['c01_pili_vesha']!,
        puzzle: content.puzzle('c01_pili_vesha'),
      ),
    );
    final q = content.puzzle('y03_stri_vesha')!;
    await shot(
      t,
      'en_7_complete',
      state(Lang.en),
      PuzzleScreen(
        puzzle: q,
        difficulty: Difficulty.easy,
        saveKey: q.id,
        seed: 3,
      ),
      after: () async {
        final c =
            (t.state(find.byType(PuzzleScreen)) as dynamic).debugController;
        while (!(c.board.isComplete as bool)) {
          c.useHint();
        }
        await t.pump(const Duration(milliseconds: 300));
      },
    );
  });
}

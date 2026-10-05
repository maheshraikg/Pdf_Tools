import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesha_puzzles/app/scope.dart';
import 'package:vesha_puzzles/app/storage.dart';
import 'package:vesha_puzzles/game/audio.dart';
import 'package:vesha_puzzles/jigsaw/cut.dart';
import 'package:vesha_puzzles/main.dart';
import 'package:vesha_puzzles/packs/content.dart';
import 'package:vesha_puzzles/packs/loader.dart';
import 'package:vesha_puzzles/screens/dress_up_screen.dart';
import 'package:vesha_puzzles/screens/progress_screen.dart';
import 'package:vesha_puzzles/screens/puzzle_screen.dart';
import 'package:vesha_puzzles/screens/settings_screen.dart';
import 'package:vesha_puzzles/screens/story_screen.dart';

void main() {
  late Content content;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    content = await ContentLoader(rootBundle).load();
  });

  AppState newState([MemoryStore? store]) => AppState(
    store: store ?? MemoryStore(),
    content: content,
    audio: AudioService(enabled: false),
    clock: () => DateTime(2026, 10, 15, 10), // during the Navaratri event
  );

  Future<void> pumpApp(WidgetTester t, AppState s, {Widget? home}) async {
    t.view.physicalSize = const Size(1080, 2280);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    if (home == null) {
      await t.pumpWidget(VeshaApp(state: s));
    } else {
      await t.pumpWidget(
        AppScope(
          state: s,
          child: MaterialApp(home: home),
        ),
      );
    }
    await t.pump();
  }

  testWidgets('home shows guide, event, daily and menu', (t) async {
    await pumpApp(t, newState());
    expect(find.text('Vesha Puzzles'), findsOneWidget);
    expect(find.text('Daily puzzle'), findsOneWidget);
    expect(find.text('Navaratri: Pili Vesha'), findsOneWidget);
    expect(find.text('Puzzles'), findsOneWidget);
    expect(find.text('Dress-up'), findsOneWidget);
  });

  testWidgets('language switch to Kannada', (t) async {
    final s = newState();
    await pumpApp(t, s);
    s.updateSettings((x) => x.lang = Lang.kn);
    await t.pump();
    expect(find.text('ವೇಷ ಪಝಲ್'), findsOneWidget);
    expect(find.text('ಇಂದಿನ ಪಝಲ್'), findsOneWidget);
  });

  testWidgets('library shows packs and locked tiles', (t) async {
    await pumpApp(t, newState());
    await t.tap(find.text('Puzzles'));
    await t.pumpAndSettle();
    expect(find.text('Yakshagana'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsWidgets);
    await t.tap(find.text('Raja Vesha – the King'));
    await t.pumpAndSettle();
    expect(find.text('Choose difficulty'), findsOneWidget);
    expect(find.text('Expert'), findsOneWidget);
  });

  testWidgets(
    'play a puzzle to completion with hints, then save/resume is cleared',
    (t) async {
      final store = MemoryStore();
      final s = newState(store);
      final puzzle = content.puzzle('y01_raja_vesha')!;
      await pumpApp(
        t,
        s,
        home: PuzzleScreen(
          puzzle: puzzle,
          difficulty: Difficulty.easy,
          saveKey: puzzle.id,
          seed: 1,
        ),
      );
      // Image decoding happens outside the fake-async zone.
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await t.pump();
      await t.pump();
      expect(find.text('Hint'), findsOneWidget);
      final state = t.state(find.byType(PuzzleScreen)) as dynamic;
      // Place all but a few pieces through the controller, then use hints.
      final c = state.debugController;
      final n = c.board.cut.count as int;
      for (var i = 0; i < n - 2; i++) {
        c.board.placePiece(c.board.pickHintPiece());
      }
      c.onChanged?.call();
      await t.pump(const Duration(seconds: 1));
      // Autosave happened.
      expect(s.saves.has(puzzle.id), isTrue);
      await t.tap(find.text('Hint'));
      await t.pump();
      await t.tap(find.text('Hint'));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Well done!'), findsOneWidget);
      expect(find.text('Read the story'), findsOneWidget);
      expect(s.progress.completed(puzzle.id), isTrue);
      expect(s.progress.records[puzzle.id]!.stars['easy'], 2);
      expect(s.saves.has(puzzle.id), isFalse);
      await t.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('resume restores a saved board', (t) async {
    final s = newState();
    final puzzle = content.puzzle('c02_rathotsava')!;
    await pumpApp(
      t,
      s,
      home: PuzzleScreen(
        puzzle: puzzle,
        difficulty: Difficulty.medium,
        saveKey: puzzle.id,
        seed: 9,
      ),
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pump();
    await t.tap(find.text('Hint'));
    await t.pump();
    await t.tap(find.text('Hint'));
    await t.pump(const Duration(seconds: 1));
    final saved = s.saves.load(puzzle.id)!;
    expect(saved.hints, 2);
    await t.pumpWidget(const SizedBox());
    await pumpApp(
      t,
      s,
      home: PuzzleScreen(
        puzzle: puzzle,
        difficulty: saved.difficulty,
        saveKey: puzzle.id,
        resume: saved,
      ),
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pump();
    final c2 = (t.state(find.byType(PuzzleScreen)) as dynamic).debugController;
    expect(c2.board.placedCount, 2);
    expect(find.textContaining('2 / '), findsOneWidget);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('story screen marks the story read and shows review flag', (
    t,
  ) async {
    final s = newState();
    final story = content.stories['y01_raja_vesha']!;
    await pumpApp(t, s, home: StoryScreen(story: story));
    await t.pump();
    expect(find.text('The King Arrives'), findsOneWidget);
    expect(find.text('Draft – awaiting expert review'), findsOneWidget);
    expect(s.progress.storiesRead, contains(story.id));
  });

  testWidgets('dress-up: pick options, locked ones stay locked, save look', (
    t,
  ) async {
    final s = newState();
    await pumpApp(t, s, home: const DressUpScreen());
    await t.pumpAndSettle();
    expect(find.text('Face paint'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsWidgets);
    await t.dragUntilVisible(
      find.text('Headgear'),
      find.byType(ListView).first,
      const Offset(-150, 0),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Headgear'));
    await t.pump();
    await t.tap(find.text('Kireeta'));
    await t.pump();
    expect(s.store.getString('dressup.current'), contains('kireeta'));
    await t.tap(find.byTooltip('Save look'));
    await t.pump();
    expect(s.progress.looksSaved, 1);
    expect(s.progress.achievements, contains('dress_up'));
  });

  testWidgets('progress and settings screens render', (t) async {
    final s = newState();
    await pumpApp(t, s, home: const ProgressScreen());
    expect(find.text('First picture'), findsOneWidget);
    await pumpApp(t, s, home: const SettingsScreen());
    await t.tap(find.text('ತುಳು'));
    await t.pump();
    expect(s.settings.lang, Lang.tcy);
  });
}

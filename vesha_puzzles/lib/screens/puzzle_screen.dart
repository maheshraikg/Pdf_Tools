import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../app/theme.dart';
import '../game/audio.dart';
import '../game/daily.dart';
import '../game/progress.dart';
import '../game/saves.dart';
import '../jigsaw/board.dart';
import '../jigsaw/board_view.dart';
import '../jigsaw/controller.dart';
import '../jigsaw/cut.dart';
import '../packs/content.dart';
import '../widgets/confetti.dart';
import '../widgets/share_image.dart';
import '../widgets/vesha_guide.dart';
import 'story_screen.dart';

/// Decodes an asset into a GPU image, capped at [maxWidth] pixels wide.
Future<ui.Image> loadUiImage(String asset, {int maxWidth = 2048}) async {
  final data = await rootBundle.load(asset);
  final buffer = await ui.ImmutableBuffer.fromUint8List(
    data.buffer.asUint8List(),
  );
  final desc = await ui.ImageDescriptor.encoded(buffer);
  final codec = await desc.instantiateCodec(
    targetWidth: desc.width > maxWidth ? maxWidth : null,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  desc.dispose();
  buffer.dispose();
  return frame.image;
}

final Map<String, double> _aspects = {};

/// Width / height of an image asset (decoded header only, cached).
Future<double> imageAspect(String asset) async {
  final cached = _aspects[asset];
  if (cached != null) return cached;
  final data = await rootBundle.load(asset);
  final buffer = await ui.ImmutableBuffer.fromUint8List(
    data.buffer.asUint8List(),
  );
  final desc = await ui.ImageDescriptor.encoded(buffer);
  final a = desc.width / desc.height;
  desc.dispose();
  buffer.dispose();
  return _aspects[asset] = a;
}

int hintAllowance(Difficulty d) => d == Difficulty.easy ? 5 : 3;

Future<void> openPuzzle(
  BuildContext context, {
  required PuzzleDef puzzle,
  Difficulty difficulty = Difficulty.medium,
  SavedGame? resume,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => PuzzleScreen(
      puzzle: puzzle,
      difficulty: resume?.difficulty ?? difficulty,
      saveKey: puzzle.id,
      resume: resume,
    ),
  ),
);

Future<void> openDaily(BuildContext context, DailyPick pick) {
  final app = AppScope.read(context);
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PuzzleScreen(
        puzzle: pick.puzzle,
        difficulty: pick.difficulty,
        saveKey: pick.saveKey,
        seed: pick.seed,
        daily: true,
        resume: app.saves.load(pick.saveKey),
      ),
    ),
  );
}

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.puzzle,
    required this.difficulty,
    required this.saveKey,
    this.resume,
    this.seed,
    this.daily = false,
  });

  final PuzzleDef puzzle;
  final Difficulty difficulty;
  final String saveKey;
  final SavedGame? resume;
  final int? seed;
  final bool daily;

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with WidgetsBindingObserver {
  JigsawController? _c;
  ui.Image? _image;
  Object? _error;
  late final Difficulty _difficulty = widget.difficulty;
  int _baseMs = 0;
  final Stopwatch _watch = Stopwatch();
  Timer? _ticker;
  Timer? _saveDebounce;
  int _hints = 0;
  bool _finished = false;
  _Result? _result;
  bool _showTrayHelp = false;

  late final AppState app = AppScope.read(context);

  int get _elapsed => _baseMs + _watch.elapsedMilliseconds;

  @visibleForTesting
  JigsawController? get debugController => _c;
  int get _hintsLeft => hintAllowance(_difficulty) - _hints;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final img = await loadUiImage(widget.puzzle.image);
      JigsawBoard? board;
      final r = widget.resume;
      if (r != null) {
        try {
          board = JigsawBoard.fromJson(r.board);
          _baseMs = r.elapsedMs;
          _hints = r.hints;
        } catch (e) {
          debugPrint('Ignoring unreadable save: $e');
          board = null; // corrupt save: start fresh
        }
      }
      board ??= _newBoard(img);
      if (!mounted) {
        img.dispose();
        return;
      }
      final c = JigsawController(board: board, image: img)
        ..showGhost = app.settings.ghostByDefault
        ..moves = r?.moves ?? 0
        ..onPick = (() => app.audio.play(Sfx.pick))
        ..onSnap = _onSnap
        ..onChanged = _scheduleSave
        ..onComplete = _onComplete;
      setState(() {
        _image = img;
        _c = c;
        _showTrayHelp = app.progress.totalCompletions == 0 && r == null;
      });
      _watch.start();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_finished) setState(() {});
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  JigsawBoard _newBoard(ui.Image img) {
    final aspect = img.width / img.height;
    final g = gridFor(_difficulty.targetPieces, aspect);
    const cellW = 100.0;
    final cellH = cellW * (img.height / g.rows) / (img.width / g.cols);
    final seed = widget.seed ?? math.Random().nextInt(1 << 31);
    return JigsawBoard(
      cut: JigsawCut.generate(g.rows, g.cols, seed),
      cellH: cellH,
    );
  }

  void _onSnap(SnapResult r) {
    switch (r.kind) {
      case SnapKind.placed:
        app.audio.play(Sfx.place);
      case SnapKind.joined:
        app.audio.play(Sfx.snap);
      case SnapKind.none:
    }
    if (_showTrayHelp) setState(() => _showTrayHelp = false);
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 700), _save);
  }

  Future<void> _save() async {
    final c = _c;
    if (c == null || _finished) return;
    await app.saves.save(
      SavedGame(
        key: widget.saveKey,
        puzzleId: widget.puzzle.id,
        difficulty: _difficulty,
        board: c.board.toJson(),
        elapsedMs: _elapsed,
        hints: _hints,
        moves: c.moves,
        savedAt: DateTime.now(),
      ),
    );
    app.notifySaves();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_finished && _c != null) _watch.start();
    } else {
      _watch.stop();
      _save();
    }
  }

  void _onComplete() {
    if (_finished) return;
    _finished = true;
    _watch.stop();
    _saveDebounce?.cancel();
    final ms = _elapsed;
    final events = app.eventsFeaturing(widget.puzzle.id);
    final outcome = app.complete(
      Completion(
        puzzleId: widget.puzzle.id,
        difficulty: _difficulty,
        ms: ms,
        hints: _hints,
        when: app.clock(),
        daily: widget.daily,
        eventIds: events,
      ),
    );
    app.saves.delete(widget.saveKey);
    app.notifySaves();
    app.audio.play(Sfx.complete);
    if (outcome.achievements.isNotEmpty) {
      Future.delayed(
        const Duration(milliseconds: 900),
        () => app.audio.play(Sfx.unlock),
      );
    }
    setState(() {
      _result = _Result(
        ms: ms,
        hints: _hints,
        best: outcome.best,
        achievements: outcome.achievements,
      );
    });
  }

  void _hint() {
    final c = _c;
    if (c == null || _finished) return;
    if (_hintsLeft <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(S.of(context).noHints)));
      return;
    }
    if (c.useHint()) setState(() => _hints++);
  }

  Future<void> _restart() async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(s.restartConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.restart),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _image == null) return;
    await app.saves.delete(widget.saveKey);
    _resetWith(_newBoard(_image!));
  }

  void _resetWith(JigsawBoard board) {
    final old = _c!;
    final c = JigsawController(board: board, image: _image!)
      ..showGhost = old.showGhost
      ..onPick = old.onPick
      ..onSnap = old.onSnap
      ..onChanged = old.onChanged
      ..onComplete = old.onComplete;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The old controller must outlive the frame that still paints it.
      old.dispose();
    });
    setState(() {
      _c = c;
      _finished = false;
      _result = null;
      _hints = 0;
      _baseMs = 0;
      _watch
        ..reset()
        ..start();
    });
  }

  void _playAgain() {
    if (_image == null) return;
    _resetWith(_newBoard(_image!));
  }

  void _showPreview() {
    final img = widget.puzzle.image;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pop(ctx),
          child: Image.asset(img),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _saveDebounce?.cancel();
    if (!_finished && _c != null) _save();
    final c = _c, img = _image;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c?.dispose();
      img?.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final lang = app.settings.lang;
    final c = _c;
    final colors = boardColors(Theme.of(context).brightness);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.puzzle.title.of(lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (c != null)
              Text(
                '${formatDuration(_elapsed)} · ${s.placed(c.board.placedCount, c.board.cut.count)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: s.preview,
            icon: const Icon(Icons.image_outlined),
            onPressed: _showPreview,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'restart') _restart();
              if (v == 'fit') c?.fit(c.viewSize);
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'fit', child: Text(s.fit)),
              PopupMenuItem(value: 'restart', child: Text(s.restart)),
            ],
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(s.loadFailed))
          : c == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: ClipRect(
                        child: JigsawBoardView(
                          controller: c,
                          frameColor: colors.frame,
                          backgroundColor: colors.background,
                          highlightColor: VeshaColors.gold,
                        ),
                      ),
                    ),
                    _Toolbar(
                      controller: c,
                      hintsLeft: _hintsLeft,
                      onHint: _hint,
                    ),
                    if (_showTrayHelp)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: VeshaGuide(
                          compact: true,
                          size: 48,
                          line:
                              app.content.line('tip.tray') ??
                              GuideLine(
                                'tip.tray',
                                LText({'en': s.trayHelp}),
                                'idle',
                              ),
                        ),
                      ),
                    SafeArea(
                      top: false,
                      child: Material(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: JigsawTray(controller: c, height: 96),
                      ),
                    ),
                  ],
                ),
                if (_result != null) ...[
                  const Positioned.fill(child: Confetti()),
                  Positioned.fill(
                    child: _CompletionOverlay(
                      result: _result!,
                      puzzle: widget.puzzle,
                      image: _image!,
                      daily: widget.daily,
                      onPlayAgain: widget.daily ? null : _playAgain,
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.hintsLeft,
    required this.onHint,
  });
  final JigsawController controller;
  final int hintsLeft;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: s.ghost,
              isSelected: controller.showGhost,
              icon: const Icon(Icons.visibility_outlined),
              selectedIcon: const Icon(Icons.visibility),
              onPressed: controller.toggleGhost,
            ),
            IconButton.filledTonal(
              tooltip: s.edgesOnly,
              isSelected: controller.edgesOnly,
              icon: const Icon(Icons.crop_free),
              onPressed: controller.toggleEdgesOnly,
            ),
            const Spacer(),
            IconButton(
              tooltip: s.zoomOut,
              icon: const Icon(Icons.zoom_out),
              onPressed: () => controller.zoomBy(1 / 1.4),
            ),
            IconButton(
              tooltip: s.zoomIn,
              icon: const Icon(Icons.zoom_in),
              onPressed: () => controller.zoomBy(1.4),
            ),
            const SizedBox(width: 4),
            Badge(
              label: Text('$hintsLeft'),
              isLabelVisible: true,
              child: FilledButton.tonalIcon(
                onPressed: hintsLeft > 0 ? onHint : null,
                icon: const Icon(Icons.lightbulb_outline),
                label: Text(s.hint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Result {
  const _Result({
    required this.ms,
    required this.hints,
    required this.best,
    required this.achievements,
  });
  final int ms;
  final int hints;
  final bool best;
  final List<String> achievements;
  int get stars => starsFor(hints: hints);
}

class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({
    required this.result,
    required this.puzzle,
    required this.image,
    required this.daily,
    required this.onPlayAgain,
  });

  final _Result result;
  final PuzzleDef puzzle;
  final ui.Image image;
  final bool daily;
  final VoidCallback? onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = S.of(context);
    final lang = app.settings.lang;
    final scheme = Theme.of(context).colorScheme;
    final story = puzzle.storyId == null
        ? null
        : app.content.stories[puzzle.storyId];
    final pack = app.content.pack(puzzle.packId);
    final nextIdx = puzzle.index + 1;
    final next = pack != null && nextIdx < pack.puzzles.length
        ? pack.puzzles[nextIdx]
        : null;
    final title = puzzle.title.of(lang);
    final time = formatDuration(result.ms);

    return ColoredBox(
      color: Colors.black45,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VeshaGuide(
                      size: 64,
                      line: VeshaGuide.pick(
                        app.content,
                        'done.',
                        salt: result.ms,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.wellDone,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++)
                          Icon(
                            i < result.stars ? Icons.star : Icons.star_border,
                            size: 40,
                            color: scheme.secondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${s.time(time)} · ${s.hintsUsed(result.hints)}'),
                    if (result.best)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          s.newBest,
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    for (final a in result.achievements)
                      ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.emoji_events,
                          color: scheme.secondary,
                        ),
                        title: Text(s.unlockedAchievement),
                        subtitle: Text(
                          s.achievementTitle(
                            a,
                            packName: app.content
                                .pack(a.replaceFirst('pack_', ''))
                                ?.title
                                .of(lang),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (story != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.menu_book),
                        label: Text(s.readStory),
                        onPressed: () =>
                            openStory(context, story, puzzle: puzzle),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share),
                          label: Text(s.share),
                          onPressed: () async {
                            final text = s.shareText(title, time);
                            final png = await renderShareImage(
                              image,
                              title,
                              '${s.appTitle} · $time',
                            );
                            await shareImage(png, '${puzzle.id}.png', text);
                          },
                        ),
                        if (onPlayAgain != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.replay),
                            label: Text(s.playAgain),
                            onPressed: onPlayAgain,
                          ),
                        if (next != null && !daily && app.isUnlocked(next))
                          OutlinedButton.icon(
                            icon: const Icon(Icons.skip_next),
                            label: Text(s.next),
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => PuzzleScreen(
                                      puzzle: next,
                                      difficulty: _lastDifficulty(context),
                                      saveKey: next.id,
                                      resume: app.saves.load(next.id),
                                    ),
                                  ),
                                ),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.done),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Difficulty _lastDifficulty(BuildContext context) =>
      context.findAncestorStateOfType<_PuzzleScreenState>()?._difficulty ??
      Difficulty.medium;
}

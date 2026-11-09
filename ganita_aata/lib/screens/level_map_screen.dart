import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../games/game_launcher.dart';
import '../models/game_result.dart';
import '../models/topic.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';
import 'home_screen.dart';

/// A winding path of levels. Locked levels show a lock. Tap a level to pick
/// a topic, then a game.
class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  static const _rowH = 200.0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    final levels = Curriculum.levels;
    return Scaffold(
      appBar: AppBar(title: Text(l.levelMap)),
      body: GameBackground(
        colors: const [Color(0xFFD6F5D6), Color(0xFFFFF8EC)],
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              Offset center(int i) => Offset(i.isEven ? w * 0.3 : w * 0.7, 60 + i * _rowH);
              final points = [for (var i = 0; i < levels.length; i++) center(i)];
              return SizedBox(
                height: levels.length * _rowH,
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _PathPainter(points))),
                    for (final (dx, dy, e) in const [
                      (0.85, 0.3, '🌳'),
                      (0.1, 1.5, '🌴'),
                      (0.88, 2.4, '🌻'),
                      (0.08, 3.3, '🌳'),
                      (0.86, 4.2, '🏰'),
                    ])
                      Positioned(
                        left: w * dx - 20,
                        top: dy * _rowH,
                        child: Text(e, style: const TextStyle(fontSize: 40)),
                      ),
                    for (var i = 0; i < levels.length; i++)
                      Positioned(
                        left: points[i].dx - 70,
                        top: points[i].dy - 50,
                        width: 140,
                        child: _LevelNode(level: levels[i], unlocked: app.isLevelUnlocked(levels[i].number)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final midY = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE8C48A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..strokeCap = StrokeCap.round,
    );
    // Dashed centre line.
    final dash = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 28) {
        canvas.drawPath(m.extractPath(d, d + 14), dash..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points;
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.unlocked});

  final Level level;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final color = AppColors.cardColors[(level.number - 1) % AppColors.cardColors.length];
    final classes = level.fromClass == level.toClass
        ? l.classN(level.fromClass)
        : l.classRange(level.fromClass, level.toClass);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          shape: const CircleBorder(),
          color: unlocked ? color : Colors.grey.shade400,
          elevation: 4,
          child: InkWell(
            key: ValueKey('level_${level.number}'),
            customBorder: const CircleBorder(),
            onTap: () => unlocked
                ? _showTopics(context, level)
                : ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l.lockedLevelSnack, style: const TextStyle(fontSize: 18)))),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Center(
                child: unlocked
                    ? Text(
                        '${level.number}',
                        style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w700, color: Colors.white),
                      )
                    : Icon(Icons.lock_rounded, size: 46, color: Colors.white, semanticLabel: l.locked),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text(l.levelN(level.number), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              Text(classes, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

void _showTopics(BuildContext context, Level level) {
  final l = context.l10n;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) {
      final app = c.watch<AppState>();
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l.levelN(level.number)} · ${l.chooseTopic}', style: Theme.of(c).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final t in level.topics) _topicTile(context, c, app, t),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

Widget _topicTile(BuildContext context, BuildContext sheet, AppState app, Topic t) {
  final l = context.l10n;
  final open = app.isUnlocked(t.id);
  final stat = app.engine.topics[t.id];
  final current = app.active?.currentTopic == t.id;
  return ListTile(
    key: ValueKey('topic_${t.id}'),
    minTileHeight: 68,
    leading: Icon(
      open ? (current ? Icons.radio_button_checked_rounded : Icons.play_circle_fill_rounded) : Icons.lock_rounded,
      size: 36,
      color: open ? AppColors.good : Colors.grey,
    ),
    title: Text(l.topicName(t.id), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
    subtitle: open
        ? (stat == null || stat.attempts == 0
              ? null
              : LinearProgressIndicator(
                  value: stat.recentAccuracy,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ))
        : Text(l.lockedHint),
    onTap: () {
      if (!open) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.lockedHint, style: const TextStyle(fontSize: 18))));
        return;
      }
      app.setCurrentTopic(t.id);
      Navigator.pop(sheet);
      _chooseGame(context, t.id);
    },
  );
}

void _chooseGame(BuildContext context, String topicId) {
  final l = context.l10n;
  const modes = [GameMode.balloon, GameMode.race, GameMode.treasure, GameMode.speed];
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.chooseGame, style: Theme.of(c).textTheme.titleLarge),
            Text(l.topicName(topicId), style: Theme.of(c).textTheme.bodyLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                for (var i = 0; i < modes.length; i++)
                  BigCard(
                    key: ValueKey('pick_${modes[i].name}'),
                    color: AppColors.cardColors[i],
                    padding: const EdgeInsets.all(8),
                    onTap: () {
                      Navigator.pop(c);
                      startGame(context, modes[i], topicId: topicId);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(HomeScreen.modeEmoji(modes[i]), style: const TextStyle(fontSize: 34)),
                        FittedBox(
                          child: Text(
                            l.gameName(modes[i]),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

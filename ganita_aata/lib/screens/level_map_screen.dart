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
import '../widgets/motion.dart';

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
        colors: const [Color(0xFFBDF0C6), Color(0xFF8EDB9C)],
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
                    for (final (dx, dy, img, sz) in const [
                      (0.80, 0.05, 'sc_house1', 70.0),
                      (0.04, 0.55, 'sc_bush1', 60.0),
                      (0.06, 1.15, 'sc_treePalm', 70.0),
                      (0.84, 1.85, 'sc_tree', 46.0),
                      (0.74, 2.15, 'sc_bush2', 60.0),
                      (0.04, 2.75, 'sc_treePine', 44.0),
                      (0.12, 3.05, 'sc_houseSmall1', 60.0),
                      (0.84, 3.45, 'sc_treeLong', 34.0),
                      (0.70, 4.15, 'sc_castleSmall', 110.0),
                      (0.04, 4.35, 'sc_towerSmall', 40.0),
                    ])
                      Positioned(
                        left: w * dx,
                        top: dy * _rowH,
                        child: GameImage(img, width: sz),
                      ),
                    for (var i = 0; i < levels.length; i++)
                      Positioned(
                        left: points[i].dx - 70,
                        top: points[i].dy - 50,
                        width: 140,
                        child: _LevelNode(
                          level: levels[i],
                          unlocked: app.isLevelUnlocked(levels[i].number),
                          openTopics: levels[i].topics.where((t) => app.isUnlocked(t.id)).length,
                          current: levels[i].topics.any((t) => t.id == app.active?.currentTopic),
                          avatar: app.active?.avatar,
                        ),
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
  const _LevelNode({
    required this.level,
    required this.unlocked,
    required this.openTopics,
    this.current = false,
    this.avatar,
  });

  /// The child's current topic is in this level ("you are here").
  final bool current;
  final String? avatar;

  final Level level;
  final bool unlocked;

  /// How many of this level's topics are open.
  final int openTopics;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (face, edge) = AppColors.card(level.number - 1);
    final classes = level.fromClass == level.toClass
        ? l.classN(level.fromClass)
        : l.classRange(level.fromClass, level.toClass);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            current
                ? Pulse(
                    amount: 0.06,
                    child: SizedBox(
                      width: 98,
                      height: 98,
                      child: ChunkyButton(
                        key: ValueKey('level_${level.number}'),
                        color: unlocked ? face : const Color(0xFFC9C5D8),
                        edgeColor: unlocked ? edge : const Color(0xFFA19CB5),
                        radius: 49,
                        depth: 7,
                        padding: EdgeInsets.zero,
                        onTap: () => unlocked
                            ? _showTopics(context, level)
                            : ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.lockedLevelSnack))),
                        child: unlocked
                            ? Text('${level.number}', style: display(50, color: Colors.white, height: 1))
                            : AppImage('lock', size: 46, semanticLabel: l.locked),
                      ),
                    ),
                  )
                : SizedBox(
                    width: 98,
                    height: 98,
                    child: ChunkyButton(
                      key: ValueKey('level_${level.number}'),
                      color: unlocked ? face : const Color(0xFFC9C5D8),
                      edgeColor: unlocked ? edge : const Color(0xFFA19CB5),
                      radius: 49,
                      depth: 7,
                      padding: EdgeInsets.zero,
                      onTap: () => unlocked
                          ? _showTopics(context, level)
                          : ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.lockedLevelSnack))),
                      child: unlocked
                          ? Text('${level.number}', style: display(50, color: Colors.white, height: 1))
                          : AppImage('lock', size: 46, semanticLabel: l.locked),
                    ),
                  ),
            if (current && avatar != null)
              Positioned(
                top: -34,
                right: -30,
                child: Bob(height: 5, child: AvatarCircle(avatarId: avatar!, size: 50, selected: true)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < level.topics.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Opacity(opacity: i < openTopics ? 1 : 0.25, child: const AppImage('star', size: 18)),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: AppColors.ink.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Text(l.levelN(level.number), style: display(18)),
              Text(classes, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
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
    leading: open
        ? (current ? const AppImage('glow_star', size: 40) : const AppImage('star', size: 36))
        : const AppImage('lock', size: 34),
    title: Text(l.topicName(t.id), style: display(21, color: open ? AppColors.ink : AppColors.inkSoft)),
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
                        AppImage(modeImage(modes[i]), size: 50),
                        FittedBox(
                          child: Text(l.gameName(modes[i]), style: display(20, color: Colors.white)),
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

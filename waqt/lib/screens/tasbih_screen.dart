import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/scope.dart';
import '../core/tasbih.dart';
import '../core/tracker.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

/// Digital tasbih: tap the big circle to count, with a ring towards the
/// target, haptics and the after-prayer 33·33·34 set.
class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  Future<void> _choose(BuildContext context) async {
    final settings = context.settings, s = context.s;
    final scheme = Theme.of(context).colorScheme;
    final mode = settings.tasbih.mode;
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const IconBadge(Icons.repeat),
              title: Text(s.afterPrayerSet),
              subtitle: const Text('33 · 33 · 34'),
              trailing: mode == -1
                  ? Icon(Icons.check_circle, color: scheme.primary)
                  : null,
              onTap: () => Navigator.pop(context, -1),
            ),
            for (var i = 0; i < dhikrList.length; i++)
              ListTile(
                leading: IconBadge(
                  dhikrList[i].target == 0 ? Icons.all_inclusive : Icons.circle,
                ),
                title: Text(
                  dhikrList[i].target == 0 ? s.freeCount : dhikrList[i].latin,
                ),
                subtitle: dhikrList[i].target == 0
                    ? null
                    : Text(
                        '${s.dhikrMeaning(dhikrList[i].id)} · ×${dhikrList[i].target}',
                      ),
                trailing: mode == i
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () => Navigator.pop(context, i),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await settings.updateQuietly((x) => x.tasbih.choose(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.settings, s = context.s;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final st = settings.tasbih;
    final d = st.current;
    final today = dateKey(settings.today);
    final totalToday = st.totalDate == today ? st.total : 0;
    final progress = d.target == 0 ? null : st.count / d.target;

    void tap() {
      var done = false;
      settings.updateQuietly((x) => done = x.tasbih.tap(today));
      if (done) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.tasbih),
        actions: [
          IconButton(
            tooltip: s.reset,
            icon: const Icon(Icons.restart_alt),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(s.resetCounter),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(s.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(s.reset),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await settings.updateQuietly((x) => x.tasbih.reset());
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final size = math.min(box.maxWidth * 0.72, box.maxHeight * 0.42);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Center(
                child: ActionChip(
                  avatar: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(
                    st.mode == -1
                        ? s.afterPrayerSet
                        : d.target == 0
                        ? s.freeCount
                        : d.latin,
                  ),
                  onPressed: () => _choose(context),
                ),
              ),
              const SizedBox(height: 16),
              if (d.arabic.isNotEmpty) ...[
                Text(
                  d.arabic,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                    height: 1.6,
                  ),
                ),
                Text(
                  d.latin,
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  s.dhikrMeaning(d.id),
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (st.mode == -1)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < afterPrayerSet.length; i++)
                        Container(
                          width: 28,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: i <= st.step
                                ? scheme.primary
                                : scheme.primary.withValues(alpha: 0.18),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: Semantics(
                  button: true,
                  label: s.tasbihTap,
                  child: GestureDetector(
                    key: const Key('tasbih-tap'),
                    onTap: tap,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: heroGradient(
                                Theme.of(context).brightness,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: kEmerald.withValues(alpha: 0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: CustomPaint(
                                size: Size.square(size),
                                painter: IslamicPatternPainter(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  cell: 44,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: size - 18,
                            height: size - 18,
                            child: CircularProgressIndicator(
                              value: progress ?? 0,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              color: kGold,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${st.count}',
                                style: t.displayLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                  fontSize: size * 0.3,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              if (d.target > 0)
                                Text(
                                  '/ ${d.target}',
                                  style: t.titleMedium?.copyWith(color: kGold),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                s.tasbihTap,
                textAlign: TextAlign.center,
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Stat(value: '${st.rounds}', label: s.rounds),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(value: '$totalToday', label: s.todayTotal),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: t.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

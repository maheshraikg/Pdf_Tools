import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/scope.dart';
import '../app/strings.dart';
import '../core/duas.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

String duaGroupName(S s, DuaGroup g) => switch (g) {
  DuaGroup.morningEvening => s.groupMorningEvening,
  DuaGroup.afterPrayer => s.groupAfterPrayer,
  DuaGroup.daily => s.groupDaily,
  DuaGroup.ramadan => s.ramadanTitle,
};

/// Duas and adhkar by group, each with a tap counter.
class DuasScreen extends StatelessWidget {
  const DuasScreen({super.key, this.initial = DuaGroup.morningEvening});

  final DuaGroup initial;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return DefaultTabController(
      length: DuaGroup.values.length,
      initialIndex: initial.index,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.duasTitle),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final g in DuaGroup.values) Tab(text: duaGroupName(s, g)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final g in DuaGroup.values)
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  for (final (i, d) in duas.where((d) => d.group == g).indexed)
                    Appear(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DuaCard(dua: d),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DuaCard extends StatefulWidget {
  const DuaCard({super.key, required this.dua});

  final Dua dua;

  @override
  State<DuaCard> createState() => _DuaCardState();
}

class _DuaCardState extends State<DuaCard> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.s, d = widget.dua;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = _count >= d.times;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.title,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (d.source.isNotEmpty)
                        Text(
                          d.source,
                          style: t.labelSmall?.copyWith(color: scheme.tertiary),
                        ),
                    ],
                  ),
                ),
                if (d.times > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '×${d.times}',
                      style: t.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              d.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: t.titleLarge?.copyWith(height: 1.9),
            ),
            if (d.transliteration.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                d.transliteration,
                style: t.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: scheme.primary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(d.meaning, style: t.bodyMedium),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: PressScale(
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _count = done ? 0 : _count + 1);
                    if (_count == d.times) HapticFeedback.heavyImpact();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: done ? kGold : scheme.primary,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            done ? Icons.check_circle : Icons.touch_app,
                            key: ValueKey(done),
                            size: 18,
                            color: done ? kEmeraldDeep : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _count == 0 ? s.tapToCount : '$_count / ${d.times}',
                          style: t.labelLarge?.copyWith(
                            color: done ? kEmeraldDeep : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

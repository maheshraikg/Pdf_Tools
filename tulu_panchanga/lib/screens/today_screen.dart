import 'dart:async';

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/engine.dart';
import 'day_detail_screen.dart';
import 'day_widgets.dart';
import 'fancy.dart';
import 'share_card.dart';
import 'timeline_bar.dart';

/// Today (or any picked date) at a glance, under an animated Tulunadu scene.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DateTime? _date;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Refresh the sky, the "now" marker and highlights every minute.
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.repo, s = context.s;
    final today = todayAt(repo.engine);
    var currentHinduDay = today;
    // Before sunrise the Hindu day is still yesterday's.
    if (jdNow() < repo.day(today).sunrise) {
      currentHinduDay = PanchangaEngine.addDays(today, -1);
    }
    final date = _date ?? currentHinduDay;
    final day = repo.day(date);
    final isToday = date == currentHinduDay;
    void go(int n) => setState(() => _date = PanchangaEngine.addDays(date, n));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: LipiText(
          s.appTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
          ),
        ),
        actions: [
          SpeakButton(color: Colors.white, text: () => speechFor(context, day)),
          IconButton(
            tooltip: s.share,
            icon: const Icon(Icons.share_rounded),
            onPressed: () => showShareCard(context, day),
          ),
          IconButton(
            tooltip: s.pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime(date.year, date.month, date.day),
                firstDate: DateTime(1950),
                lastDate: DateTime(2099, 12, 31),
              );
              if (picked != null) {
                setState(() => _date = PanchangaEngine.dateOnly(picked));
              }
            },
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 200) return;
          go(v < 0 ? 1 : -1);
        },
        child: FutureBuilder(
          future: repo.festivalsOn(date),
          builder: (context, snap) {
            final festive = (snap.data ?? const []).any(
              (o) => FestivalBanner.notable(o),
            );
            return ListView(
              padding: EdgeInsets.zero,
              children: [
                HeroHeader(
                  day: day,
                  isToday: isToday,
                  festive: festive,
                  onPrev: () => go(-1),
                  onNext: () => go(1),
                ),
                if (!isToday)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: FilledButton.tonalIcon(
                        icon: const Icon(Icons.today_rounded),
                        label: LipiText(s.today),
                        onPressed: () => setState(() => _date = null),
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                // Re-run the entrance animation when the day changes.
                KeyedSubtree(
                  key: ValueKey(date),
                  child: Column(
                    children: [
                      Entrance(index: 0, child: FestivalBanner(date: date)),
                      Entrance(index: 1, child: TimelineBar(day: day)),
                      Entrance(index: 2, child: ElementsCard(day: day)),
                      Entrance(index: 3, child: KaalaCard(day: day)),
                      Entrance(index: 4, child: SunMoonCard(day: day)),
                    ],
                  ),
                ),
                const FlowerDivider(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: LipiText(s.fullDetails),
                    onPressed: () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (_, _, _) => DayDetailScreen(date: date),
                        transitionsBuilder: (_, a, _, c) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position:
                                Tween(
                                  begin: const Offset(0, 0.06),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: a,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                            child: c,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

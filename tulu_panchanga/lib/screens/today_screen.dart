import 'dart:async';

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/engine.dart';
import 'day_detail_screen.dart';
import 'day_widgets.dart';
import 'share_card.dart';
import 'timeline_bar.dart';

/// Today (or any picked date) at a glance.
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
    // Refresh the "now" marker and highlights every minute.
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
    var date = _date ?? today;
    // Before sunrise the Hindu day is still yesterday's.
    if (_date == null && jdNow() < repo.day(today).sunrise) {
      date = PanchangaEngine.addDays(today, -1);
    }
    final day = repo.day(date);

    return Scaffold(
      appBar: AppBar(
        title: LipiText(s.appTitle),
        actions: [
          IconButton(
            tooltip: s.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showShareCard(context, day),
          ),
          IconButton(
            tooltip: s.pickDate,
            icon: const Icon(Icons.calendar_month_outlined),
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
          setState(() => _date = PanchangaEngine.addDays(date, v < 0 ? 1 : -1));
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      setState(() => _date = PanchangaEngine.addDays(date, -1)),
                ),
                Expanded(child: DayHeader(day: day)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      setState(() => _date = PanchangaEngine.addDays(date, 1)),
                ),
              ],
            ),
            if (date != today)
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.today),
                  label: LipiText(s.today),
                  onPressed: () => setState(() => _date = null),
                ),
              ),
            Center(
              child: Text(
                context.n(context.settings.place.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TimelineBar(day: day),
            FestivalsCard(date: date),
            ElementsCard(day: day),
            KaalaCard(day: day),
            SunMoonCard(day: day),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.tonalIcon(
                icon: const Icon(Icons.article_outlined),
                label: LipiText(s.fullDetails),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DayDetailScreen(date: date),
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

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../panchanga/engine.dart';
import 'day_widgets.dart';
import 'fancy.dart';
import 'share_card.dart';
import 'timeline_bar.dart';

/// Everything computed for one day.
class DayDetailScreen extends StatefulWidget {
  const DayDetailScreen({super.key, required this.date});
  final DateTime date;

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late DateTime _date = PanchangaEngine.dateOnly(widget.date);

  @override
  Widget build(BuildContext context) {
    final day = context.repo.day(_date);
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(longDate(context.lang, _date)),
        actions: [
          IconButton(
            tooltip: s.share,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => showShareCard(context, day),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    setState(() => _date = PanchangaEngine.addDays(_date, -1)),
              ),
              Expanded(child: DayHeader(day: day)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    setState(() => _date = PanchangaEngine.addDays(_date, 1)),
              ),
            ],
          ),
          FestivalBanner(date: _date),
          ElementsCard(day: day, full: true),
          TimelineBar(day: day),
          KaalaCard(day: day, full: true),
          SunMoonCard(day: day),
          YearCard(day: day),
        ],
      ),
    );
  }
}

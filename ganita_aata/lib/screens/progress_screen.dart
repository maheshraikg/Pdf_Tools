import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/curriculum.dart';
import '../data/shop_catalog.dart';
import '../engine/adaptive_engine.dart';
import '../models/profile.dart';
import '../models/question.dart';
import '../models/stats.dart';
import '../services/app_state.dart';
import '../widgets/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/l10n_ext.dart';

/// Parent view (behind the PIN): accuracy per topic, speed over time, weak
/// facts, days practised and total sums.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Profile? _profile;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = context.read<AppState>().now;
    _month = DateTime(now.year, now.month);
  }

  AdaptiveEngine _engineFor(AppState app, Profile p) => p.id == app.active?.id
      ? app.engine
      : AdaptiveEngine(profileId: p.id, store: app.store, unlocked: {...p.unlocked});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final app = context.watch<AppState>();
    final p = _profile ?? app.active!;
    final e = _engineFor(app, p);
    final total = e.totalSums;
    final accuracy = total == 0 ? 0 : (e.totalCorrect * 100 / total).round();
    final mastered = e.facts.values.where((f) => f.mastered).length;
    final practised = e.days.values.where((d) => d.sums > 0).length;
    return Scaffold(
      appBar: AppBar(title: Text(l.progress)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (app.profiles.length > 1)
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in app.profiles)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Text(ShopCatalog.emojiFor(c.avatar)),
                        label: Text(c.name, style: const TextStyle(fontSize: 18)),
                        selected: c.id == p.id,
                        onSelected: (_) => setState(() => _profile = c),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              AvatarCircle(avatarId: p.avatar, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${p.name} · ${l.classN(p.schoolClass)}', style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _Stat(label: l.totalSums, value: '$total', color: AppColors.secondary),
              _Stat(label: l.accuracy, value: '$accuracy%', color: AppColors.good),
              _Stat(label: l.factsMastered, value: '$mastered', color: AppColors.coin),
              _Stat(label: l.daysPractised, value: '$practised', color: AppColors.primary),
            ],
          ),
          _Section(title: l.accuracyPerTopic, child: _topicAccuracy(context, e)),
          _Section(
            title: l.speedOverTime,
            child: _SpeedChart(days: e.days, now: app.now),
          ),
          _Section(title: l.weakFacts, child: _weakFacts(context, e)),
          _Section(
            title: l.daysPractised,
            child: _Calendar(month: _month, days: e.days, onMonth: (m) => setState(() => _month = m)),
          ),
        ],
      ),
    );
  }

  Widget _topicAccuracy(BuildContext context, AdaptiveEngine e) {
    final l = context.l10n;
    final rows = [
      for (final t in Curriculum.topics)
        if ((e.topics[t.id]?.attempts ?? 0) > 0) e.topics[t.id]!,
    ];
    if (rows.isEmpty) return Text(l.noDataYet);
    return Column(
      children: [
        for (final s in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.topicName(s.topicId),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${(s.accuracy * 100).round()}%',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: s.accuracy,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  color: s.accuracy >= 0.85 ? AppColors.good : (s.accuracy >= 0.6 ? AppColors.coin : AppColors.gentle),
                  backgroundColor: Colors.black12,
                ),
                Text(l.triesRight(s.attempts, (s.accuracy * 100).round()), style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _weakFacts(BuildContext context, AdaptiveEngine e) {
    final l = context.l10n;
    final weak = e.weakFacts(limit: 15);
    if (weak.isEmpty) return Text(e.totalSums == 0 ? l.noDataYet : l.noWeakFacts);
    return Column(
      children: [
        for (final f in weak)
          if (Question.fromKey(f.topicId, f.key) case final q?)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lightbulb_rounded, color: AppColors.gentle),
              title: Text(l.solvedText(q), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              subtitle: Text('${l.topicName(f.topicId)} · ${l.triesRight(f.attempts, (f.accuracy * 100).round())}'),
            ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
          ),
          FittedBox(child: Text(label, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Average seconds per sum for each practised day in the last 30 days.
class _SpeedChart extends StatelessWidget {
  const _SpeedChart({required this.days, required this.now});

  final Map<String, DayStat> days;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = DateTime(now.year, now.month, now.day);
    final spots = <FlSpot>[];
    for (var i = 29; i >= 0; i--) {
      final d = days[dayKey(today.subtract(Duration(days: i)))];
      if (d != null && d.sums > 0) {
        spots.add(FlSpot((29 - i).toDouble(), double.parse(d.avgSeconds.toStringAsFixed(1))));
      }
    }
    if (spots.isEmpty) return Text(l.noDataYet);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final fmt = DateFormat('d/M');
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 29,
          minY: 0,
          maxY: (maxY * 1.2).ceilToDouble().clamp(5, 120),
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 7,
                reservedSize: 28,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    fmt.format(today.subtract(Duration(days: 29 - v.toInt()))),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.secondary,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.secondary.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Month calendar; practised days are green with the number of sums.
class _Calendar extends StatelessWidget {
  const _Calendar({required this.month, required this.days, required this.onMonth});

  final DateTime month;
  final Map<String, DayStat> days;
  final ValueChanged<DateTime> onMonth;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final startOffset = (first.weekday % 7 - loc.firstDayOfWeekIndex) % 7;
    final weekdays = [for (var i = 0; i < 7; i++) loc.narrowWeekdays[(i + loc.firstDayOfWeekIndex) % 7]];
    final cells = startOffset + daysInMonth;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => onMonth(DateTime(month.year, month.month - 1)),
              icon: const Icon(Icons.chevron_left_rounded, size: 32),
            ),
            Expanded(
              child: Text(
                DateFormat.yMMMM(locale).format(month),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: () => onMonth(DateTime(month.year, month.month + 1)),
              icon: const Icon(Icons.chevron_right_rounded, size: 32),
            ),
          ],
        ),
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(w, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: (cells / 7).ceil() * 7,
          itemBuilder: (context, i) {
            final day = i - startOffset + 1;
            if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
            final stat = days[dayKey(DateTime(month.year, month.month, day))];
            final done = stat != null && stat.sums > 0;
            return Container(
              decoration: BoxDecoration(
                color: done ? AppColors.good : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: done ? Colors.white : AppColors.ink,
                        ),
                      ),
                      if (done) Text('${stat.sums}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

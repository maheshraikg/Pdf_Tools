/// Interactive charts (fl_chart): spending pace, income vs spending by
/// month, and spending by category. Tap or drag to read exact amounts.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../ledger/ledger.dart';
import '../models/money.dart';
import 'common.dart';
import 'design.dart';

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// A round axis maximum (₹ in rupees) a little above [max].
double _niceMax(double max) {
  if (max <= 0) return 100;
  final mag = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
  for (final f in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]) {
    if (f * mag >= max * 1.08) return f * mag;
  }
  return 10 * mag;
}

Widget _axisLabel(BuildContext context, String text) => Text(
  text,
  style: Theme.of(context).textTheme.labelSmall
      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
);

/// Two-tone legend dot.
class ChartLegend extends StatelessWidget {
  const ChartLegend(this.items, {super.key});
  final List<(String, Color, bool)> items; // label, colour, dashed

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 6,
    children: [
      for (final (label, color, dashed) in items)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: dashed ? 2 : 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
    ],
  );
}

/// This month's running spending against last month's, so the user can see
/// at a glance whether they are ahead or behind.
class SpendingPaceChart extends StatelessWidget {
  const SpendingPaceChart({
    super.key,
    required this.ledger,
    required this.today,
  });
  final Ledger ledger;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = ledger.cumulativeSpending(today, upTo: today);
    final lastMonth = DateTime.utc(today.year, today.month - 1);
    final prev = ledger.cumulativeSpending(lastMonth);
    final daysInMonth = monthEnd(today).day;
    final maxY = _niceMax([...now, ...prev].fold<int>(0, math.max) / 100);
    List<FlSpot> spots(List<int> v) => [
      for (var i = 0; i < v.length; i++) FlSpot(i + 1.0, v[i] / 100),
    ];

    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: daysInMonth.toDouble(),
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: _axisLabel(
                    context,
                    formatRupeesCompact((v * 100).round()),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  final d = v.round();
                  final show = d == 1 || d % 7 == 0 || d == daysInMonth;
                  return SideTitleWidget(
                    meta: meta,
                    child: show ? _axisLabel(context, '$d') : const SizedBox(),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              fitInsideHorizontally: true,
              getTooltipItems: (spots) => [
                for (final s in spots)
                  LineTooltipItem(
                    '${s.barIndex == 1 ? 'This month' : 'Last month'} · day '
                    '${s.x.round()}\n${formatRupees((s.y * 100).round())}',
                    TextStyle(
                      color: scheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots(prev),
              color: scheme.outline,
              barWidth: 2,
              dashArray: [5, 4],
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: spots(now),
              color: scheme.primary,
              barWidth: 3,
              isCurved: true,
              preventCurveOverShooting: true,
              isStrokeCapRound: true,
              dotData: FlDotData(
                checkToShowDot: (spot, bar) => spot.x == now.length,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 4.5,
                      color: scheme.primary,
                      strokeWidth: 2.5,
                      strokeColor: scheme.surfaceContainerLow,
                    ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primary.withValues(alpha: 0.22),
                    scheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Income and spending side by side for the last [months] months.
class IncomeSpendBars extends StatelessWidget {
  const IncomeSpendBars({
    super.key,
    required this.ledger,
    required this.today,
    this.months = 6,
  });
  final Ledger ledger;
  final DateTime today;
  final int months;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ms = [
      for (var i = months - 1; i >= 0; i--)
        DateTime.utc(today.year, today.month - i),
    ];
    final income = [
      for (final m in ms) ledger.income(monthStart(m), monthEnd(m)) / 100,
    ];
    final spent = [
      for (final m in ms) ledger.spending(monthStart(m), monthEnd(m)) / 100,
    ];
    final maxY = _niceMax([...income, ...spent].fold<double>(0, math.max));
    final inColor = scheme.moneyIn;
    final outColor = scheme.primary;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: scheme.outlineVariant, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 54,
                interval: maxY / 4,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: _axisLabel(
                    context,
                    formatRupeesCompact((v * 100).round()),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: _axisLabel(
                    context,
                    _monthsShort[ms[v.toInt()].month - 1],
                  ),
                ),
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              fitInsideHorizontally: true,
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${_monthsShort[ms[gi].month - 1]} · ${ri == 0 ? 'Income' : 'Spent'}\n'
                '${formatRupees((rod.toY * 100).round())}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < ms.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 4,
                barRods: [
                  BarChartRodData(
                    toY: income[i],
                    color: inColor,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: spent[i],
                    color: outColor,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Spending by category: a donut you can tap, with a clear legend of amounts
/// and shares.
class CategoryBreakdown extends StatefulWidget {
  const CategoryBreakdown({super.key, required this.byCategory});
  final Map<String, Paise> byCategory;

  @override
  State<CategoryBreakdown> createState() => _CategoryBreakdownState();
}

class _CategoryBreakdownState extends State<CategoryBreakdown> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final entries = widget.byCategory.entries
        .where((e) => e.value > 0)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold(0, (s, e) => s + e.value);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final selected = _touched == null ? null : entries[_touched!];

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 56,
                  startDegreeOffset: -90,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      final i = response?.touchedSection?.touchedSectionIndex;
                      if (!event.isInterestedForInteractions ||
                          i == null ||
                          i < 0) {
                        return;
                      }
                      setState(() => _touched = _touched == i ? null : i);
                    },
                  ),
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value.toDouble(),
                        color: colorForCategory(entries[i].key),
                        radius: _touched == i ? 30 : 24,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selected?.key ?? 'Total spent',
                    style: t.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    formatRupeesCompact(selected?.value ?? total),
                    style: t.titleLarge,
                  ),
                  if (selected != null)
                    Text(
                      '${(selected.value * 100 / total).round()}%',
                      style: t.labelMedium,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < entries.length && i < 6; i++)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _touched = _touched == i ? null : i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
              child: Row(
                children: [
                  IconBadge(
                    iconForCategory(entries[i].key),
                    color: colorForCategory(entries[i].key),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                entries[i].key,
                                style: t.bodyMedium?.copyWith(
                                  fontWeight: _touched == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              formatRupees(entries[i].value),
                              style: t.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Meter(
                                value: entries[i].value / total,
                                color: colorForCategory(entries[i].key),
                                height: 6,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${(entries[i].value * 100 / total).round()}%',
                                textAlign: TextAlign.right,
                                style: t.labelSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

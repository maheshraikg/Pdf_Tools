import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/ledger.dart';
import '../models/money.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'home_screen.dart';

/// Trends and habits: spending pace, income vs spending, where the money
/// went, and short insights.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final now = today();
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final from = monthStart(now), to = monthEnd(now);
    final byCategory = l.spendingByCategory(from, to);
    final streak = l.noSpendStreak(now);
    final change = l.spendingChangeVsLastMonth(now);
    final avg = l.dailyAverage(now);

    final facts = <(String, String)>[
      if (streak > 0)
        ('$streak day${streak == 1 ? '' : 's'}', 'without spending'),
      if (change != null)
        (
          '${change.abs().toStringAsFixed(0)}% ${change <= 0 ? 'less' : 'more'}',
          'than this time last month',
        ),
      if (avg > 0) (formatRupees(avg), 'average spend per day'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          if (facts.isNotEmpty)
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: [
                  for (var i = 0; i < facts.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(facts[i].$1, style: t.titleMedium),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              facts[i].$2,
                              style: t.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Spending pace', style: t.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Total spent so far in ${monthsLong[now.month - 1]}, day by day',
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                SpendingPaceChart(ledger: l, today: now),
                const SizedBox(height: 10),
                ChartLegend([
                  ('This month', scheme.onSurface, false),
                  ('Last month', scheme.outline, true),
                ]),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Income vs spending', style: t.titleMedium),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Figure(
                        'Income',
                        formatRupeesCompact(l.income(from, to)),
                        color: scheme.moneyIn,
                      ),
                    ),
                    Expanded(
                      child: Figure(
                        'Spent',
                        formatRupeesCompact(l.spending(from, to)),
                      ),
                    ),
                    Expanded(
                      child: Figure(
                        'Invested',
                        formatRupeesCompact(l.invested(from, to)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                IncomeSpendBars(ledger: l, today: now),
                const SizedBox(height: 10),
                ChartLegend([
                  ('Income', scheme.moneyIn, false),
                  ('Spent', scheme.onSurface, false),
                ]),
              ],
            ),
          ),
          if (byCategory.values.any((v) => v > 0))
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where it went', style: t.titleMedium),
                  const SizedBox(height: 8),
                  CategoryBreakdown(byCategory: byCategory),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/ledger.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'budgets_screen.dart';
import 'forms.dart';
import 'quick_add_sheet.dart';
import 'settings_screen.dart';

const _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// One-screen overview: net worth, alerts, this month, where the money went,
/// budgets and the latest activity.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Switches the bottom navigation to another tab.
  final ValueChanged<int> onOpenTab;

  String _greeting() {
    final h = clock().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final l = store.ledger;
    final now = today();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              toolbarHeight: 72,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Text('RupeeTrack'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            if (store.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: _Welcome())
            else
              SliverList.list(
                children: [
                  _NetWorthHero(worth: l.netWorth(now)),
                  _QuickActions(onOpenTab: onOpenTab),
                  for (final a in l.alerts(now))
                    _AlertBanner(alert: a, onOpenTab: onOpenTab),
                  _MonthPanel(now: now),
                  _WhereItWent(now: now),
                  _BudgetsPanel(now: now),
                  SectionHeader(
                    'Recent activity',
                    action: TextButton(
                      onPressed: () => onOpenTab(1),
                      child: const Text('See all'),
                    ),
                  ),
                  if (l.txns.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long,
                      message:
                          'No transactions yet. Tap Add to record your '
                          'first expense. It takes a few seconds.',
                    )
                  else
                    Panel(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          for (final t in l.txns.take(5))
                            TxnTile(
                              t,
                              onTap: () => showQuickAdd(context, initial: t),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 96),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget point(IconData icon, String title, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.titleSmall),
                Text(
                  text,
                  style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroPanel(
            margin: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.currency_rupee, size: 40),
                const SizedBox(height: 12),
                Text(
                  'All your money,\none simple view.',
                  style: t.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Private, offline and free. No sign-up, no bank login.',
                  style: t.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          point(
            Icons.bolt,
            'Add an expense in seconds',
            'Amount, category, account and done.',
          ),
          point(
            Icons.credit_card,
            'Never miss a card bill',
            'Limits, usage and due-date reminders for every card.',
          ),
          point(
            Icons.insights,
            'Watch your investments grow',
            'SIPs, PPF, FDs, NPS and more, with returns.',
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => showAddAccountDialog(context),
            icon: const Icon(Icons.account_balance),
            label: const Text('Add bank account or cash'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showAddCardDialog(context),
            icon: const Icon(Icons.credit_card),
            label: const Text('Add credit card'),
          ),
        ],
      ),
    );
  }
}

class _NetWorthHero extends StatelessWidget {
  const _NetWorthHero({required this.worth});
  final NetWorth worth;

  @override
  Widget build(BuildContext context) {
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroFigure('Net worth', formatRupees(worth.total), big: true),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: HeroFigure(
                  'In accounts',
                  formatRupeesCompact(worth.cash),
                ),
              ),
              Expanded(
                child: HeroFigure(
                  'Investments',
                  formatRupeesCompact(worth.investments),
                ),
              ),
              Expanded(
                child: HeroFigure(
                  'Cards owed',
                  formatRupeesCompact(worth.liabilities),
                ),
              ),
            ],
          ),
          if (worth.hasUnvaluedInvestments) ...[
            const SizedBox(height: 12),
            Text(
              'Investments without a current value are counted at cost.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget action(IconData icon, String label, Color color, VoidCallback f) =>
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: f,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  IconBadge(icon, color: color, size: 52),
                  const SizedBox(height: 6),
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          action(
            Icons.remove,
            'Expense',
            scheme.moneyOut,
            () => showQuickAdd(context),
          ),
          action(
            Icons.add,
            'Income',
            scheme.moneyIn,
            () => showQuickAdd(context, type: TxnType.income),
          ),
          action(
            Icons.credit_score,
            'Pay card',
            chartColor(1),
            () => showQuickAdd(context, type: TxnType.cardPayment),
          ),
          action(
            Icons.trending_up,
            'Invest',
            chartColor(0),
            () => showQuickAdd(context, type: TxnType.invest),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert, required this.onOpenTab});
  final FinanceAlert alert;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, color) = switch (alert.kind) {
      AlertKind.overdue => (Icons.error, scheme.error),
      AlertKind.dueSoon => (Icons.event, const Color(0xFFE08A00)),
      AlertKind.overBudget => (Icons.money_off, scheme.error),
      AlertKind.highUtilisation => (Icons.speed, const Color(0xFFE08A00)),
      AlertKind.nearBudget => (Icons.pie_chart, const Color(0xFFE08A00)),
    };
    final card = alert.card;
    final payable =
        card != null &&
        (alert.kind == AlertKind.overdue || alert.kind == AlertKind.dueSoon);
    return Panel(
      color: color.withValues(alpha: 0.10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      onTap: () => alert.category != null
          ? Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
            )
          : onOpenTab(2),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(alert.message)),
          if (payable)
            TextButton(
              onPressed: () => showQuickAdd(
                context,
                type: TxnType.cardPayment,
                toCardId: card.id,
              ),
              child: const Text('Pay'),
            ),
        ],
      ),
    );
  }
}

class _MonthPanel extends StatelessWidget {
  const _MonthPanel({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final scheme = Theme.of(context).colorScheme;
    final from = monthStart(now), to = monthEnd(now);
    final spent = l.spending(from, to);
    final income = l.income(from, to);
    final rate = l.savingsRate(from, to);
    final months = [
      for (var i = 5; i >= 0; i--) DateTime.utc(now.year, now.month - i),
    ];
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel(now),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (rate != null)
                Pill(
                  'Saved ${rate.toStringAsFixed(0)}%',
                  color: rate >= 0 ? scheme.moneyIn : scheme.moneyOut,
                  icon: Icons.savings_outlined,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Figure(
                  'Spent',
                  formatRupees(spent),
                  color: scheme.moneyOut,
                ),
              ),
              Expanded(
                child: Figure(
                  'Income',
                  formatRupees(income),
                  color: scheme.moneyIn,
                ),
              ),
              Expanded(
                child: Figure('Invested', formatRupees(l.invested(from, to))),
              ),
            ],
          ),
          const SizedBox(height: 18),
          MiniBars(
            values: [
              for (final m in months)
                l.spending(monthStart(m), monthEnd(m)).toDouble(),
            ],
            labels: [for (final m in months) _monthsShort[m.month - 1]],
          ),
        ],
      ),
    );
  }
}

class _WhereItWent extends StatelessWidget {
  const _WhereItWent({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final byCategory = l
        .spendingByCategory(monthStart(now), monthEnd(now))
        .entries
        .where((e) => e.value > 0)
        .toList();
    if (byCategory.isEmpty) return const SizedBox.shrink();
    final top = byCategory.take(5).toList();
    final rest = byCategory.skip(5).fold(0, (s, e) => s + e.value);
    final total = byCategory.fold(0, (s, e) => s + e.value);
    final rows = [
      for (var i = 0; i < top.length; i++) (top[i].key, top[i].value, i),
      if (rest > 0) ('Others', rest, top.length),
    ];
    final t = Theme.of(context).textTheme;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where it went', style: t.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Donut(
                slices: [
                  for (final r in rows)
                    DonutSlice(r.$2.toDouble(), chartColor(r.$3)),
                ],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Spent', style: t.labelSmall),
                    Text(
                      formatRupeesCompact(total),
                      style: t.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    for (final r in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: chartColor(r.$3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                r.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(r.$2 * 100 / total).round()}%',
                              style: t.labelMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetsPanel extends StatelessWidget {
  const _BudgetsPanel({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final statuses = context.ledger.budgetStatuses(now);
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    void open() => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const BudgetsScreen()),
    );
    if (statuses.isEmpty) {
      return Panel(
        onTap: open,
        child: Row(
          children: [
            const IconBadge(Icons.pie_chart_outline),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set monthly budgets', style: t.titleSmall),
                  Text(
                    'Get a warning before a category overspends.',
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      );
    }
    return Panel(
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Budgets', style: t.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in statuses.take(4))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: BudgetRow(status: s),
            ),
        ],
      ),
    );
  }
}

/// Category, spent / limit and a meter that turns amber then red.
class BudgetRow extends StatelessWidget {
  const BudgetRow({super.key, required this.status});
  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final scheme = Theme.of(context).colorScheme;
    final color = s.percent >= 100
        ? scheme.error
        : s.percent >= 80
        ? const Color(0xFFE08A00)
        : scheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(categoryIcons[s.budget.category] ?? Icons.category, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(s.budget.category)),
            Text(
              '${formatRupees(s.spent)} / ${formatRupees(s.budget.monthlyLimit)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Meter(value: s.percent / 100, color: color),
      ],
    );
  }
}

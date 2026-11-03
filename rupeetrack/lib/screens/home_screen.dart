import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/ledger.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'auto_detect_screen.dart';
import 'budgets_screen.dart';
import 'forms.dart';
import 'pay_bill_sheet.dart';
import 'quick_add_sheet.dart';
import 'settings_screen.dart';

const _monthsLong = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// The home screen: this month's spending up front, quick actions,
/// insights, alerts, trends, where the money went, budgets and the latest
/// activity.
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
              toolbarHeight: 76,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  ShaderMask(
                    shaderCallback: (r) =>
                        const LinearGradient(colors: [kViolet, kPink])
                            .createShader(r),
                    child: const Text(
                      'RupeeTrack',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Settings',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (store.isEmpty)
              const SliverFillRemaining(hasScrollBody: false, child: _Welcome())
            else
              SliverList.list(
                children: [
                  _SpendHero(now: now),
                  const _QuickActions(),
                  if (store.detected.isNotEmpty)
                    Panel(
                      color: scheme.primaryContainer,
                      padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const AutoDetectScreen(),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Found ${store.detected.values.map((h) => h.label).join(', ')} '
                              'in your bank messages',
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  for (final a in l.alerts(now))
                    _AlertBanner(alert: a, onOpenTab: onOpenTab),
                  _Insights(now: now),
                  _TrendPanel(now: now),
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
                          'Nothing here yet. Tap Add to log your first spend. '
                          'It takes a few seconds.',
                    )
                  else
                    Panel(
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                  const SizedBox(height: 110),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          IconBadge(icon, size: 46),
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HeroPanel(
            margin: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.currency_rupee_rounded, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  'Know where every\nrupee goes.',
                  style: t.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Private, offline and free. No sign-up, no bank login.',
                  style: t.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          point(
            Icons.bolt_rounded,
            'Log a spend in seconds',
            'Amount, category, account. Done.',
          ),
          point(
            Icons.credit_card_rounded,
            'Never miss a card bill',
            'Limits, dues and reminders for every card.',
          ),
          point(
            Icons.trending_up_rounded,
            'Watch your money grow',
            'SIPs, PPF, FDs, gold and more, with returns.',
          ),
          point(
            Icons.insights_rounded,
            'Insights that help you save',
            'Streaks, trends and budgets at a glance.',
          ),
          const Spacer(),
          GradientButton(
            onPressed: () => showAddAccountDialog(context),
            icon: Icons.account_balance_rounded,
            label: 'Add bank account or cash',
          ),
          const SizedBox(height: 12),
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

/// This month's spending, big, with how it compares to last month.
class _SpendHero extends StatelessWidget {
  const _SpendHero({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final from = monthStart(now), to = monthEnd(now);
    final spent = l.spending(from, to);
    final change = l.spendingChangeVsLastMonth(now);
    final worth = l.netWorth(now);
    final rate = l.savingsRate(from, to);
    final daysLeft = to.difference(now).inDays;
    return HeroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent in ${_monthsLong[now.month - 1]}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    change <= 0
                        ? '▼ ${(-change).toStringAsFixed(0)}% vs last month'
                        : '▲ ${change.toStringAsFixed(0)}% vs last month',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupees(spent),
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.5,
              ),
            ),
          ),
          Text(
            '${formatRupees(l.dailyAverage(now) ~/ 100 * 100)}/day · '
            '${daysLeft == 0
                ? 'last day of the month'
                : daysLeft == 1
                ? '1 day to go'
                : '$daysLeft days to go'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: HeroFigure(
                    'Net worth',
                    formatRupeesCompact(worth.total),
                  ),
                ),
                Expanded(
                  child: HeroFigure(
                    'In accounts',
                    formatRupeesCompact(worth.cash),
                  ),
                ),
                Expanded(
                  child: HeroFigure(
                    rate == null ? 'Cards owed' : 'Saved',
                    rate == null
                        ? formatRupeesCompact(worth.liabilities)
                        : '${rate.toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget action(IconData icon, String label, Color color, VoidCallback f) =>
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadius),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: f,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      IconBadge(icon, color: color, size: 44),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: t.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          action(
            Icons.arrow_outward_rounded,
            'Expense',
            const Color(0xFFF43F5E),
            () => showQuickAdd(context),
          ),
          action(
            Icons.south_west_rounded,
            'Income',
            kLime,
            () => showQuickAdd(context, type: TxnType.income),
          ),
          action(
            Icons.credit_score_rounded,
            'Pay card',
            kViolet,
            () => showQuickAdd(context, type: TxnType.cardPayment),
          ),
          action(
            Icons.trending_up_rounded,
            'Invest',
            kCyan,
            () => showQuickAdd(context, type: TxnType.invest),
          ),
        ],
      ),
    );
  }
}

/// Swipeable insight cards: streaks, top category, budgets, pace.
class _Insights extends StatelessWidget {
  const _Insights({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final from = monthStart(now), to = monthEnd(now);
    final byCat = l
        .spendingByCategory(from, to)
        .entries
        .where((e) => e.value > 0)
        .toList();
    final total = byCat.fold(0, (s, e) => s + e.value);
    final streak = l.noSpendStreak(now);
    final change = l.spendingChangeVsLastMonth(now);
    final budgets = l.budgetStatuses(now);
    final left = budgets.fold(0, (s, b) => s + b.remaining);
    final daysLeft = to.difference(now).inDays + 1;

    final cards = <(IconData, String, String, Color)>[
      if (streak > 0)
        (
          Icons.local_fire_department_rounded,
          '$streak-day streak',
          'No spending for $streak day${streak == 1 ? '' : 's'}. Keep it going!',
          kOrange,
        ),
      if (byCat.isNotEmpty)
        (
          iconForCategory(byCat.first.key),
          '${byCat.first.key} is ${(byCat.first.value * 100 / total).round()}%',
          'Your top spend this month: ${formatRupees(byCat.first.value)}',
          colorForCategory(byCat.first.key),
        ),
      if (change != null)
        change <= 0
            ? (
                Icons.trending_down_rounded,
                '${(-change).toStringAsFixed(0)}% less',
                'than this time last month. Nice!',
                kLime,
              )
            : (
                Icons.trending_up_rounded,
                '${change.toStringAsFixed(0)}% more',
                'than this time last month.',
                kOrange,
              ),
      if (budgets.isNotEmpty && left > 0)
        (
          Icons.track_changes_rounded,
          '${formatRupeesCompact(left ~/ daysLeft)}/day left',
          'to stay within your budgets',
          kViolet,
        ),
      if (l.dailyAverage(now) > 0)
        (
          Icons.calendar_today_rounded,
          '${formatRupeesCompact(l.dailyAverage(now))}/day',
          'average spend this month',
          kCyan,
        ),
    ];
    if (cards.isEmpty) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 132,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final (icon, title, text, color) = cards[i];
            final scheme = Theme.of(context).colorScheme;
            return Container(
              width: 172,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadius),
                color: scheme.surfaceContainerLow,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon, color: color, size: 36),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall,
                  ),
                ],
              ),
            );
          },
        ),
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
      AlertKind.dueSoon => (Icons.event, kOrange),
      AlertKind.overBudget => (Icons.money_off, scheme.error),
      AlertKind.highUtilisation => (Icons.speed, kOrange),
      AlertKind.nearBudget => (Icons.pie_chart, kOrange),
    };
    final card = alert.card;
    final payable =
        card != null &&
        (alert.kind == AlertKind.overdue || alert.kind == AlertKind.dueSoon);
    return Panel(
      color: color.withValues(alpha: isDark(context) ? 0.16 : 0.10),
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
              onPressed: () => showPayBillSheet(context, card),
              child: const Text('Pay'),
            ),
        ],
      ),
    );
  }
}

class _TrendPanel extends StatelessWidget {
  const _TrendPanel({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final from = monthStart(now), to = monthEnd(now);
    return Column(
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spending pace', style: t.titleMedium),
              const SizedBox(height: 2),
              Text(
                'Total spent so far this month, day by day',
                style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SpendingPaceChart(ledger: l, today: now),
              const SizedBox(height: 10),
              ChartLegend([
                ('This month', scheme.primary, false),
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
                ('Spent', scheme.primary, false),
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhereItWent extends StatelessWidget {
  const _WhereItWent({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final byCategory = context.ledger.spendingByCategory(
      monthStart(now),
      monthEnd(now),
    );
    if (!byCategory.values.any((v) => v > 0)) return const SizedBox.shrink();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where it went', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          CategoryBreakdown(byCategory: byCategory),
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
            const IconBadge(Icons.donut_large_rounded),
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
        ? kOrange
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              iconForCategory(s.budget.category),
              size: 18,
              color: colorForCategory(s.budget.category),
            ),
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

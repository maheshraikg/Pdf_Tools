import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/ledger.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import 'forms.dart';
import 'quick_add_sheet.dart';

/// One-screen overview: net worth, this month, card alerts, top categories
/// and the latest transactions.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Switches the bottom navigation to another tab.
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final l = store.ledger;
    final now = today();
    final from = monthStart(now);
    final to = monthEnd(now);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RupeeTrack'),
        actions: [
          PopupMenuButton<ThemeMode>(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Theme',
            initialValue: store.themeMode,
            onSelected: store.setThemeMode,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Text('System theme'),
              ),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        ],
      ),
      body: store.isEmpty
          ? _Welcome()
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _NetWorthCard(worth: l.netWorth(now)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _QuickActions(onOpenTab: onOpenTab),
                ),
                SectionHeader(monthLabel(now)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Spent',
                          value: formatRupeesCompact(l.spending(from, to)),
                          color: scheme.moneyOut,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Income',
                          value: formatRupeesCompact(l.income(from, to)),
                          color: scheme.moneyIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Invested',
                          value: formatRupeesCompact(l.invested(from, to)),
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final a in l.alerts(now))
                  _AlertTile(alert: a, onOpenTab: onOpenTab),
                _TopCategories(byCategory: l.spendingByCategory(from, to)),
                SectionHeader(
                  'Recent',
                  action: TextButton(
                    onPressed: () => onOpenTab(1),
                    child: const Text('See all'),
                  ),
                ),
                if (l.txns.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long,
                    message:
                        'No transactions yet. Tap + to add your first '
                        'expense — it takes a few seconds.',
                  ),
                for (final t in l.txns.take(5))
                  TxnTile(t, onTap: () => showQuickAdd(context, initial: t)),
              ],
            ),
    );
  }
}

class _Welcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.currency_rupee,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Welcome to RupeeTrack',
          style: t.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Track your bank balances, credit card dues and investments in one '
          'place. Start by adding where your money is.',
          style: t.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => showAddAccountDialog(context),
          icon: const Icon(Icons.account_balance),
          label: const Text('Add bank account or cash'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => showAddCardDialog(context),
          icon: const Icon(Icons.credit_card),
          label: const Text('Add credit card'),
        ),
        const SizedBox(height: 24),
        Text(
          'Everything stays on this phone. No sign-up, no bank login.',
          style: t.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.worth});
  final NetWorth worth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(16),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Figure('Net worth', formatRupees(worth.total), large: true),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Figure('In accounts', formatRupeesCompact(worth.cash)),
                ),
                Expanded(
                  child: Figure(
                    'Investments',
                    formatRupeesCompact(worth.investments),
                  ),
                ),
                Expanded(
                  child: Figure(
                    'Cards owed',
                    formatRupeesCompact(worth.liabilities),
                    color: worth.liabilities > 0 ? scheme.moneyOut : null,
                  ),
                ),
              ],
            ),
            if (worth.hasUnvaluedInvestments) ...[
              const SizedBox(height: 8),
              Text(
                'Some investments have no current value yet; the amount '
                'invested is used for them.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    Widget action(IconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        action(
          Icons.remove_circle_outline,
          'Expense',
          () => showQuickAdd(context),
        ),
        action(
          Icons.add_circle_outline,
          'Income',
          () => showQuickAdd(context, type: TxnType.income),
        ),
        action(
          Icons.credit_score,
          'Pay card',
          () => showQuickAdd(context, type: TxnType.cardPayment),
        ),
        action(
          Icons.trending_up,
          'Invest',
          () => showQuickAdd(context, type: TxnType.invest),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Figure(label, value, color: color),
    ),
  );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onOpenTab});
  final FinanceAlert alert;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final urgent = alert.kind != AlertKind.highUtilisation;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: urgent ? scheme.errorContainer : scheme.tertiaryContainer,
      child: ListTile(
        leading: Icon(
          switch (alert.kind) {
            AlertKind.overdue => Icons.error,
            AlertKind.dueSoon => Icons.event,
            AlertKind.highUtilisation => Icons.speed,
          },
          color: urgent ? scheme.onErrorContainer : scheme.onTertiaryContainer,
        ),
        title: Text(alert.message),
        trailing: urgent
            ? TextButton(
                onPressed: () => showQuickAdd(
                  context,
                  type: TxnType.cardPayment,
                  toCardId: alert.card.id,
                ),
                child: const Text('Pay'),
              )
            : null,
        onTap: () => onOpenTab(2),
      ),
    );
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.byCategory});
  final Map<String, Paise> byCategory;

  @override
  Widget build(BuildContext context) {
    final entries = byCategory.entries
        .where((e) => e.value > 0)
        .take(5)
        .toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    final max = entries.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Where it went'),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(categoryIcons[e.key] ?? Icons.category, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(e.key)),
                          Text(formatRupees(e.value)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: e.value / max,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

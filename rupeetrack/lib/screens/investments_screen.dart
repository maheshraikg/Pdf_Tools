import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/returns.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import 'forms.dart';
import 'holding_detail_screen.dart';
import 'quick_add_sheet.dart';

String _percent(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}%';

/// Portfolio kept apart from everyday spending, with returns where a current
/// value has been entered.
class InvestmentsScreen extends StatelessWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final now = today();
    final summaries = [
      for (final i in l.investments) l.investmentSummary(i, now),
    ];
    final scheme = Theme.of(context).colorScheme;

    final netInvested = summaries.fold(0, (s, x) => s + x.netInvested);
    final valued = summaries.where((s) => s.currentValue != null).toList();
    final valuedGain = valued.fold(0, (s, x) => s + x.absoluteReturn!);
    final valuedContributed = valued.fold(0, (s, x) => s + x.contributed);
    final currentTotal = summaries.fold(
      0,
      (s, x) => s + (x.currentValue ?? (x.netInvested > 0 ? x.netInvested : 0)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Add investment',
            onPressed: () => showAddInvestmentDialog(context),
          ),
        ],
      ),
      body: summaries.isEmpty
          ? EmptyState(
              icon: Icons.trending_up,
              message:
                  'Add your mutual funds, SIPs, PPF, FDs, NPS, gold and '
                  'more. Money you invest is kept out of your spending.',
              actionLabel: 'Add investment',
              onAction: () => showAddInvestmentDialog(context),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Card(
                  margin: const EdgeInsets.all(16),
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Figure(
                          'Portfolio value',
                          formatRupees(currentTotal),
                          large: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Figure(
                                'Invested',
                                formatRupeesCompact(netInvested),
                              ),
                            ),
                            Expanded(
                              child: Figure(
                                'Gain',
                                valued.isEmpty
                                    ? '–'
                                    : '${valuedGain >= 0 ? '+' : ''}'
                                          '${formatRupeesCompact(valuedGain)}',
                                color: valued.isEmpty
                                    ? null
                                    : valuedGain >= 0
                                    ? scheme.moneyIn
                                    : scheme.moneyOut,
                              ),
                            ),
                            Expanded(
                              child: Figure(
                                'Return',
                                valuedContributed <= 0
                                    ? '–'
                                    : _percent(
                                        valuedGain * 100 / valuedContributed,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (valued.length < summaries.length) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Gain and return only include holdings with a '
                            'current value.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                for (final s in summaries) _InvestmentTile(summary: s),
              ],
            ),
    );
  }
}

class _InvestmentTile extends StatelessWidget {
  const _InvestmentTile({required this.summary});
  final InvestmentSummary summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final inv = s.investment;
    final scheme = Theme.of(context).colorScheme;
    final gain = s.absoluteReturn;
    final gainColor = gain == null
        ? null
        : gain >= 0
        ? scheme.moneyIn
        : scheme.moneyOut;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => HoldingDetailScreen.investment(inv.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inv.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          inv.type.label,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (s.returnPercent != null)
                    Text(
                      _percent(s.returnPercent!),
                      style: TextStyle(
                        color: gainColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Figure('Invested', formatRupees(s.netInvested)),
                  ),
                  Expanded(
                    child: Figure(
                      'Current value',
                      s.currentValue == null
                          ? 'Not set'
                          : formatRupees(s.currentValue!),
                    ),
                  ),
                ],
              ),
              if (gain != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Figure(
                        'Gain',
                        '${gain >= 0 ? '+' : ''}${formatRupees(gain)}',
                        color: gainColor,
                      ),
                    ),
                    Expanded(
                      child: Figure(
                        'Yearly (XIRR)',
                        s.xirr == null ? '–' : _percent(s.xirr! * 100),
                      ),
                    ),
                  ],
                ),
              ],
              if (s.incomePaidOut > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Dividends / interest received: ${formatRupees(s.incomePaidOut)}',
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      inv.valueUpdatedOn == null
                          ? 'Enter today’s value to see returns'
                          : 'Value as of ${shortDate(inv.valueUpdatedOn!)} (entered by you)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => showUpdateValueDialog(context, inv),
                    child: const Text('Update value'),
                  ),
                  TextButton(
                    onPressed: () => showQuickAdd(
                      context,
                      type: TxnType.invest,
                      investmentId: inv.id,
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

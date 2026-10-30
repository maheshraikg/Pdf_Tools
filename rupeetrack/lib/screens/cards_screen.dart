import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/ledger.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import 'forms.dart';
import 'holding_detail_screen.dart';
import 'quick_add_sheet.dart';

/// Every credit card with its limit, usage, bill and due date.
class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final now = today();
    final statuses = [for (final c in l.cards) l.cardStatus(c, now)];
    final totalLimit = l.cards.fold(0, (s, c) => s + c.creditLimit);
    final totalOwed = l.totalCardOutstanding;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Add card',
            onPressed: () => showAddCardDialog(context),
          ),
        ],
      ),
      body: statuses.isEmpty
          ? EmptyState(
              icon: Icons.credit_card,
              message:
                  'Add your credit cards to track spending, limits and '
                  'payment due dates.',
              actionLabel: 'Add card',
              onAction: () => showAddCardDialog(context),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (statuses.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Figure('Total owed', formatRupees(totalOwed)),
                        ),
                        Expanded(
                          child: Figure(
                            'Total available',
                            formatRupees(
                              statuses.fold(0, (s, x) => s + x.availableCredit),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Figure(
                            'Utilisation',
                            totalLimit == 0
                                ? '–'
                                : '${(totalOwed * 100 / totalLimit).toStringAsFixed(0)}%',
                          ),
                        ),
                      ],
                    ),
                  ),
                for (final s in statuses) _CardTile(status: s),
              ],
            ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.status});
  final CardStatus status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    final scheme = Theme.of(context).colorScheme;
    final util = s.utilisationPercent;
    final utilColor = util >= 75
        ? scheme.error
        : util >= 30
        ? Colors.orange
        : scheme.moneyIn;
    final daysLeft = s.dueDate.difference(today()).inDays;
    final dueText = s.overdue
        ? 'Overdue since ${shortDate(s.dueDate)}'
        : s.amountDue > 0
        ? 'Due ${shortDate(s.dueDate)} · ${daysLeft == 0 ? 'today' : 'in $daysLeft days'}'
        : 'Next due ${shortDate(s.dueDate)}';

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => HoldingDetailScreen.card(s.card.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.card.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${util.toStringAsFixed(0)}% used',
                    style: TextStyle(
                      color: utilColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (util / 100).clamp(0, 1),
                color: utilColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Figure('Outstanding', formatRupees(s.outstanding)),
                  ),
                  Expanded(
                    child: Figure('Available', formatRupees(s.availableCredit)),
                  ),
                  Expanded(
                    child: Figure(
                      'Limit',
                      formatRupeesCompact(s.card.creditLimit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Figure('This cycle', formatRupees(s.cycleSpend)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Figure(
                      'Bill to pay',
                      formatRupees(s.amountDue),
                      color: s.overdue ? scheme.error : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    s.overdue ? Icons.error : Icons.event,
                    size: 18,
                    color: s.overdue ? scheme.error : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dueText,
                      style: TextStyle(color: s.overdue ? scheme.error : null),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => showQuickAdd(
                      context,
                      type: TxnType.cardPayment,
                      toCardId: s.card.id,
                      amount: s.amountDue > 0 ? s.amountDue : null,
                    ),
                    child: const Text('Pay bill'),
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

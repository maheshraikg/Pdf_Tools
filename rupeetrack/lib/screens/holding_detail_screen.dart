import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import 'quick_add_sheet.dart';

/// History of one account, card or investment, with a delete option for ones
/// that have no transactions.
class HoldingDetailScreen extends StatelessWidget {
  const HoldingDetailScreen.account(int id, {super.key})
    : accountId = id,
      cardId = null,
      investmentId = null;
  const HoldingDetailScreen.card(int id, {super.key})
    : cardId = id,
      accountId = null,
      investmentId = null;
  const HoldingDetailScreen.investment(int id, {super.key})
    : investmentId = id,
      accountId = null,
      cardId = null;

  final int? accountId;
  final int? cardId;
  final int? investmentId;

  @override
  Widget build(BuildContext context) {
    final store = context.store;
    final l = store.ledger;
    final account = l.account(accountId);
    final card = l.card(cardId);
    final investment = l.investment(investmentId);
    final title = account?.name ?? card?.displayName ?? investment?.name;
    if (title == null) {
      // Deleted while open.
      return Scaffold(appBar: AppBar());
    }

    final txns = accountId != null
        ? l.accountTxns(accountId!)
        : cardId != null
        ? l.cardTxns(cardId!)
        : l.investmentTxns(investmentId!);

    final String headline;
    final String headlineLabel;
    if (account != null) {
      headlineLabel = 'Balance';
      headline = formatRupees(l.accountBalance(account.id));
    } else if (card != null) {
      headlineLabel = 'Outstanding';
      headline = formatRupees(l.cardOutstanding(card.id));
    } else {
      final s = l.investmentSummary(investment!, today());
      headlineLabel = 'Invested';
      headline = formatRupees(s.netInvested);
    }

    final inUse = store.isInUse(
      accountId: accountId,
      cardId: cardId,
      investmentId: investmentId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!inUse)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Delete $title?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                final navigator = Navigator.of(context);
                await store.deleteHolding(
                  accountId: accountId,
                  cardId: cardId,
                  investmentId: investmentId,
                );
                navigator.pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Figure(headlineLabel, headline, large: true),
          ),
          if (txns.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long,
              message: 'No transactions yet.',
            ),
          for (final t in txns)
            TxnTile(t, onTap: () => showQuickAdd(context, initial: t)),
        ],
      ),
    );
  }
}

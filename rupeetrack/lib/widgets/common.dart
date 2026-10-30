import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../ledger/ledger.dart';
import '../models/models.dart';
import '../models/money.dart';

/// Colours used for money direction, tuned for both themes.
extension MoneyColors on ColorScheme {
  Color get moneyIn => brightness == Brightness.light
      ? const Color(0xFF1B7F3B)
      : const Color(0xFF7DD99A);
  Color get moneyOut => error;
}

const categoryIcons = <String, IconData>{
  'Food': Icons.restaurant,
  'Groceries': Icons.local_grocery_store,
  'Transport': Icons.directions_bus,
  'Fuel': Icons.local_gas_station,
  'Shopping': Icons.shopping_bag,
  'Bills': Icons.receipt_long,
  'Rent': Icons.home,
  'Health': Icons.medical_services,
  'Entertainment': Icons.movie,
  'Travel': Icons.flight,
  'Education': Icons.school,
  'Salary': Icons.work,
  'Interest': Icons.savings,
  'Business': Icons.storefront,
  'Gift': Icons.card_giftcard,
};

IconData iconForTxn(Txn t) => switch (t.type) {
  TxnType.transfer => Icons.swap_horiz,
  TxnType.cardPayment => Icons.credit_score,
  TxnType.invest => Icons.trending_up,
  TxnType.investWithdrawal => Icons.account_balance_wallet,
  TxnType.investIncome => Icons.payments,
  TxnType.refund => Icons.undo,
  _ => categoryIcons[t.category] ?? Icons.category,
};

IconData iconForAccount(AccountKind k) => switch (k) {
  AccountKind.savings => Icons.account_balance,
  AccountKind.cash => Icons.payments,
  AccountKind.wallet => Icons.qr_code_2,
};

/// Title shown for a transaction in lists.
String txnTitle(Txn t, Ledger l) {
  if (t.note != null && t.note!.isNotEmpty) return t.note!;
  return switch (t.type) {
    TxnType.expense || TxnType.income => t.category ?? t.type.label,
    TxnType.refund => 'Refund · ${t.category ?? 'Other'}',
    TxnType.transfer => 'Transfer',
    TxnType.cardPayment => 'Bill paid · ${l.card(t.toCardId)?.name ?? 'card'}',
    TxnType.invest => l.investment(t.investmentId)?.name ?? 'Investment',
    TxnType.investWithdrawal =>
      'Withdrawn · ${l.investment(t.investmentId)?.name ?? ''}',
    TxnType.investIncome =>
      'Income · ${l.investment(t.investmentId)?.name ?? ''}',
  };
}

/// "SBI Savings → HDFC Regalia" style description of where money moved.
String txnRoute(Txn t, Ledger l) {
  String? name({int? accountId, int? cardId}) =>
      l.account(accountId)?.name ?? l.card(cardId)?.displayName;
  final from =
      name(accountId: t.fromAccountId, cardId: t.fromCardId) ??
      (t.type == TxnType.investWithdrawal || t.type == TxnType.investIncome
          ? l.investment(t.investmentId)?.name
          : null);
  final to =
      name(accountId: t.toAccountId, cardId: t.toCardId) ??
      (t.type == TxnType.invest ? l.investment(t.investmentId)?.name : null);
  if (from != null && to != null) return '$from → $to';
  return from ?? to ?? (t.type == TxnType.investIncome ? 'Reinvested' : '');
}

/// +1 money in, -1 money out, 0 moved between the user's own holdings.
int txnDirection(Txn t) => switch (t.type) {
  TxnType.expense => -1,
  TxnType.income || TxnType.refund || TxnType.investIncome => 1,
  _ => 0,
};

class TxnTile extends StatelessWidget {
  const TxnTile(this.txn, {super.key, this.onTap, this.showDate = true});

  final Txn txn;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final scheme = Theme.of(context).colorScheme;
    final dir = txnDirection(txn);
    final color = switch (dir) {
      1 => scheme.moneyIn,
      -1 => scheme.moneyOut,
      _ => scheme.onSurfaceVariant,
    };
    final sign = switch (dir) {
      1 => '+',
      -1 => '−',
      _ => '',
    };
    final route = txnRoute(txn, l);
    final subtitle = [
      if (route.isNotEmpty) route,
      if (showDate) relativeDate(txn.date),
    ].join(' · ');
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        foregroundColor: scheme.onSecondaryContainer,
        child: Icon(iconForTxn(txn), size: 20),
      ),
      title: Text(
        txnTitle(txn, l),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '$sign${formatRupees(txn.amount)}',
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Small labelled figure used in summary rows.
class Figure extends StatelessWidget {
  const Figure(
    this.label,
    this.value, {
    super.key,
    this.color,
    this.large = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: t.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: (large ? t.headlineSmall : t.titleMedium)?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?action,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Text field for rupee amounts.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.autofocus = false,
    this.large = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool large;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final style = large
        ? Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w600)
        : null;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      style: style,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₹ ',
        prefixStyle: style,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

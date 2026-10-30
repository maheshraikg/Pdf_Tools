import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../app/store.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import 'forms.dart';

/// Opens the quick entry sheet. Pass [initial] to edit an existing
/// transaction, or [type] / [toCardId] / [investmentId] to prefill a new one.
Future<void> showQuickAdd(
  BuildContext context, {
  Txn? initial,
  TxnType? type,
  int? toCardId,
  int? investmentId,
  int? amount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => QuickAddSheet(
      initial: initial,
      type: type,
      toCardId: toCardId,
      investmentId: investmentId,
      amount: amount,
    ),
  );
}

/// Amount first, then one tap each for category and payment source, then
/// Save: a typical expense takes a few seconds.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({
    super.key,
    this.initial,
    this.type,
    this.toCardId,
    this.investmentId,
    this.amount,
  });

  final Txn? initial;
  final TxnType? type;
  final int? toCardId;
  final int? investmentId;
  final int? amount;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late TxnType _type;
  String? _category;
  Source? _from;
  Source? _to;
  int? _investmentId;
  late DateTime _date;
  List<String> _errors = const [];
  bool _initialised = false;

  bool get _editing => widget.initial != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final store = context.store;
    final t = widget.initial;
    if (t != null) {
      _type = t.type;
      _amount.text = formatRupees(t.amount).substring(1).replaceAll(',', '');
      _note.text = t.note ?? '';
      _category = t.category;
      _from = _sourceOf(t.fromAccountId, t.fromCardId);
      _to = _sourceOf(t.toAccountId, t.toCardId);
      _investmentId = t.investmentId;
      _date = t.date;
    } else {
      _type = widget.type ?? TxnType.expense;
      if (widget.amount != null) {
        _amount.text = (widget.amount! / 100).toStringAsFixed(
          widget.amount! % 100 == 0 ? 0 : 2,
        );
      }
      _category = _type == TxnType.income
          ? incomeCategories.first
          : store.lastCategory;
      _from = _validSource(store.lastSource) ?? _defaultAccount();
      _to = widget.toCardId != null ? Source.card(widget.toCardId!) : null;
      _investmentId =
          widget.investmentId ??
          (store.ledger.investments.length == 1
              ? store.ledger.investments.first.id
              : null);
      _date = today();
      _adjustForType();
    }
  }

  static Source? _sourceOf(int? accountId, int? cardId) => accountId != null
      ? Source.account(accountId)
      : cardId != null
      ? Source.card(cardId)
      : null;

  Source? _validSource(Source? s) {
    if (s == null) return null;
    final l = context.ledger;
    if (s.accountId != null && l.account(s.accountId) != null) return s;
    if (s.cardId != null && l.card(s.cardId) != null) return s;
    return null;
  }

  Source? _defaultAccount() {
    final accounts = context.ledger.accounts;
    return accounts.isEmpty ? null : Source.account(accounts.first.id);
  }

  /// Keeps the selected from/to choices valid for the current type.
  void _adjustForType() {
    final l = context.ledger;
    final fromAccountOnly = switch (_type) {
      TxnType.transfer || TxnType.cardPayment => true,
      _ => false,
    };
    if (!_usesFrom) {
      _from = null;
    } else if (_from == null || (fromAccountOnly && _from!.cardId != null)) {
      _from = _defaultAccount();
    }
    switch (_type) {
      case TxnType.income || TxnType.investWithdrawal:
        if (_to?.accountId == null) _to = _defaultAccount();
      case TxnType.transfer:
        if (_to?.accountId == null || _to == _from) {
          final other = l.accounts.where((a) => Source.account(a.id) != _from);
          _to = other.isEmpty ? null : Source.account(other.first.id);
        }
      case TxnType.cardPayment:
        if (_to?.cardId == null && l.cards.isNotEmpty) {
          _to = Source.card(l.cards.first.id);
        }
      case TxnType.refund:
        _to ??= _from ?? _defaultAccount();
      case TxnType.investIncome:
        if (_to?.cardId != null) _to = null;
      case TxnType.expense || TxnType.invest:
        _to = null;
    }
    if (_type == TxnType.income) {
      if (!incomeCategories.contains(_category)) {
        _category = incomeCategories.first;
      }
    } else if (_usesCategory &&
        incomeCategories.contains(_category) &&
        !expenseCategories.contains(_category)) {
      _category = context.store.lastCategory;
    }
  }

  bool get _usesCategory => switch (_type) {
    TxnType.expense || TxnType.income || TxnType.refund => true,
    _ => false,
  };

  bool get _usesFrom => switch (_type) {
    TxnType.expense ||
    TxnType.invest ||
    TxnType.transfer ||
    TxnType.cardPayment => true,
    _ => false,
  };

  bool get _usesInvestment => switch (_type) {
    TxnType.invest || TxnType.investWithdrawal || TxnType.investIncome => true,
    _ => false,
  };

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = parseRupees(_amount.text);
    if (amount == null) {
      setState(
        () => _errors = const ['Enter a valid amount, e.g. 250 or 99.50'],
      );
      return;
    }
    final note = _note.text.trim();
    final txn = Txn(
      id: widget.initial?.id ?? 0,
      type: _type,
      amount: amount,
      date: _date,
      category: _usesCategory ? _category : null,
      note: note.isEmpty ? null : note,
      fromAccountId: _usesFrom ? _from?.accountId : null,
      fromCardId: _usesFrom ? _from?.cardId : null,
      toAccountId: _to?.accountId,
      toCardId: _to?.cardId,
      investmentId: _usesInvestment ? _investmentId : null,
    );
    final errors = await context.store.saveTxn(txn);
    if (!mounted) return;
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _editing
              ? 'Updated'
              : '${_type.label} of ${formatRupees(amount)} saved',
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: today().add(const Duration(days: 366)),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _newCategory() async {
    final name = await promptText(
      context,
      title: 'New category',
      label: 'Name',
    );
    if (name != null && name.isNotEmpty) setState(() => _category = name);
  }

  Future<void> _newInvestment() async {
    final inv = await showAddInvestmentDialog(context);
    if (inv != null) setState(() => _investmentId = inv.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final scheme = Theme.of(context).colorScheme;

    if (l.accounts.isEmpty && l.cards.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance,
        message:
            'Add a bank account, cash or a credit card first so that '
            'RupeeTrack knows where the money comes from.',
        actionLabel: 'Add account',
        onAction: () async {
          await showAddAccountDialog(context);
          if (context.mounted) setState(() => _adjustForType());
        },
      );
    }

    final categories = _type == TxnType.income
        ? incomeCategories
        : [
            ...expenseCategories,
            if (_category != null && !expenseCategories.contains(_category))
              _category!,
          ];

    // The form scrolls; Save stays pinned below it so it is always reachable
    // on short screens and above the keyboard.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _editing ? 'Edit transaction' : 'Add transaction',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final t in TxnType.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(t.label),
                              selected: _type == t,
                              onSelected: (_) => setState(() {
                                _type = t;
                                _errors = const [];
                                _adjustForType();
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AmountField(
                    controller: _amount,
                    autofocus: !_editing && widget.amount == null,
                    large: true,
                  ),
                  if (_usesCategory) ...[
                    _Label('Category'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final c in categories)
                          ChoiceChip(
                            avatar: Icon(
                              categoryIcons[c] ?? Icons.category,
                              size: 18,
                            ),
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) => setState(() => _category = c),
                          ),
                        if (_type != TxnType.income)
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('New'),
                            onPressed: _newCategory,
                          ),
                      ],
                    ),
                  ],
                  if (_usesInvestment) ...[
                    _Label('Investment'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final inv in l.investments)
                          ChoiceChip(
                            label: Text(inv.name),
                            selected: _investmentId == inv.id,
                            onSelected: (_) =>
                                setState(() => _investmentId = inv.id),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('New investment'),
                          onPressed: _newInvestment,
                        ),
                      ],
                    ),
                  ],
                  if (_usesFrom) ...[
                    _Label(_type == TxnType.transfer ? 'From' : 'Paid from'),
                    _SourceChips(
                      selected: _from,
                      includeCards:
                          _type == TxnType.expense || _type == TxnType.invest,
                      onSelected: (s) => setState(() => _from = s),
                    ),
                  ],
                  if (_type != TxnType.expense && _type != TxnType.invest) ...[
                    _Label(switch (_type) {
                      TxnType.cardPayment => 'Card',
                      TxnType.investIncome =>
                        'Paid into (leave empty if reinvested)',
                      _ => 'To',
                    }),
                    _SourceChips(
                      selected: _to,
                      includeAccounts: _type != TxnType.cardPayment,
                      includeCards:
                          _type == TxnType.cardPayment ||
                          _type == TxnType.refund,
                      exclude: _type == TxnType.transfer ? _from : null,
                      onSelected: (s) => setState(
                        () => _to = (_type == TxnType.investIncome && s == _to)
                            ? null
                            : s,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.event, size: 18),
                        label: Text(relativeDate(_date)),
                        onPressed: _pickDate,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _note,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Note (optional), e.g. Lunch',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in _errors)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(e, style: TextStyle(color: scheme.error)),
                  ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                  label: Text(_editing ? 'Update' : 'Save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
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

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _SourceChips extends StatelessWidget {
  const _SourceChips({
    required this.selected,
    required this.onSelected,
    this.includeAccounts = true,
    this.includeCards = true,
    this.exclude,
  });

  final Source? selected;
  final ValueChanged<Source> onSelected;
  final bool includeAccounts;
  final bool includeCards;
  final Source? exclude;

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final chips = <Widget>[
      if (includeAccounts)
        for (final a in l.accounts)
          if (Source.account(a.id) != exclude)
            ChoiceChip(
              avatar: Icon(iconForAccount(a.kind), size: 18),
              label: Text(a.name),
              selected: selected == Source.account(a.id),
              onSelected: (_) => onSelected(Source.account(a.id)),
            ),
      if (includeCards)
        for (final c in l.cards)
          ChoiceChip(
            avatar: const Icon(Icons.credit_card, size: 18),
            label: Text(c.displayName),
            selected: selected == Source.card(c.id),
            onSelected: (_) => onSelected(Source.card(c.id)),
          ),
    ];
    if (chips.isEmpty) {
      return Text(
        includeAccounts ? 'Add an account first.' : 'Add a credit card first.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }
}

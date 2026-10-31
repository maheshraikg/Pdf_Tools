import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../models/models.dart';
import '../models/money.dart';
import '../widgets/common.dart';

/// Asks for a single line of text.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Add'),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}

Future<void> showAddAccountDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _AccountForm());

Future<void> showEditAccountDialog(BuildContext context, Account a) =>
    showDialog<void>(
      context: context,
      builder: (_) => _AccountForm(edit: a),
    );

Future<void> showAddCardDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _CardForm());

Future<void> showEditCardDialog(BuildContext context, CreditCard c) =>
    showDialog<void>(
      context: context,
      builder: (_) => _CardForm(edit: c),
    );

Future<Investment?> showAddInvestmentDialog(BuildContext context) =>
    showDialog<Investment>(
      context: context,
      builder: (_) => const _InvestmentForm(),
    );

Future<void> showEditInvestmentDialog(BuildContext context, Investment inv) =>
    showDialog<void>(
      context: context,
      builder: (_) => _InvestmentForm(edit: inv),
    );

Future<void> showUpdateValueDialog(BuildContext context, Investment inv) =>
    showDialog<void>(
      context: context,
      builder: (_) => _ValueForm(investment: inv),
    );

/// Shared dialog frame with Cancel / Save and an error line.
class _DialogFrame extends StatelessWidget {
  const _DialogFrame({
    required this.title,
    required this.children,
    required this.onSave,
    this.error,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children) ...[c, const SizedBox(height: 12)],
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}

/// Parses an optional amount: empty means zero.
Paise? _optionalAmount(String text) =>
    text.trim().isEmpty ? 0 : parseRupees(text);

class _AccountForm extends StatefulWidget {
  const _AccountForm({this.edit});
  final Account? edit;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  final _last4 = TextEditingController();
  AccountKind _kind = AccountKind.savings;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = widget.edit;
    if (a != null) {
      _name.text = a.name;
      _kind = a.kind;
      _last4.text = a.lastFour;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final a = widget.edit;
    if (a != null && _opening.text.isEmpty) {
      _opening.text = amountText(context.ledger.accountBalance(a.id));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    _last4.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final last4 = _last4.text.trim();
    final balance = _opening.text.trim().isEmpty
        ? 0
        : parseSignedRupees(_opening.text);
    if (name.isEmpty) return setState(() => _error = 'Enter a name');
    if (balance == null) {
      return setState(() => _error = 'Enter a valid balance');
    }
    if (last4.isNotEmpty && !RegExp(r'^\d{3,6}$').hasMatch(last4)) {
      return setState(() => _error = 'Account digits must be 3 to 6 numbers');
    }
    final a = widget.edit;
    if (a == null) {
      await context.store.addAccount(name, _kind, balance, lastFour: last4);
    } else {
      await context.store.updateAccount(
        a,
        name: name,
        kind: _kind,
        lastFour: last4,
        currentBalance: balance,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: widget.edit == null ? 'Add account' : 'Edit account',
      error: _error,
      onSave: _save,
      children: [
        SegmentedButton<AccountKind>(
          segments: [
            for (final k in AccountKind.values)
              ButtonSegment(
                value: k,
                icon: Icon(iconForAccount(k)),
                tooltip: k.label,
                label: Text(switch (k) {
                  AccountKind.savings => 'Bank',
                  AccountKind.cash => 'Cash',
                  AccountKind.wallet => 'Wallet',
                }),
              ),
          ],
          selected: {_kind},
          onSelectionChanged: (s) => setState(() => _kind = s.first),
        ),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: switch (_kind) {
              AccountKind.savings => 'e.g. SBI Savings',
              AccountKind.cash => 'e.g. Cash',
              AccountKind.wallet => 'e.g. Paytm wallet',
            },
          ),
        ),
        AmountField(controller: _opening, label: 'Current balance'),
        if (_kind == AccountKind.savings)
          TextField(
            controller: _last4,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Last 4 digits of account (optional)',
              helperText: 'Lets RupeeTrack match bank SMS to this account',
              counterText: '',
            ),
          ),
        if (widget.edit != null)
          Text(
            'Changing the balance keeps all transactions; the starting '
            'balance is adjusted so the total matches.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _CardForm extends StatefulWidget {
  const _CardForm({this.edit});
  final CreditCard? edit;

  @override
  State<_CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<_CardForm> {
  final _name = TextEditingController();
  final _last4 = TextEditingController();
  final _limit = TextEditingController();
  final _outstanding = TextEditingController();
  int _statementDay = 15;
  int _dueDay = 5;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.edit;
    if (c != null) {
      _name.text = c.name;
      _last4.text = c.lastFour;
      _limit.text = amountText(c.creditLimit);
      _statementDay = c.statementDay;
      _dueDay = c.dueDay;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = widget.edit;
    if (c != null && _outstanding.text.isEmpty) {
      _outstanding.text = amountText(context.ledger.cardOutstanding(c.id));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _last4, _limit, _outstanding]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final last4 = _last4.text.trim();
    final limit = parseRupees(_limit.text);
    final outstanding = _optionalAmount(_outstanding.text);
    if (name.isEmpty) return setState(() => _error = 'Enter the card name');
    if (last4.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(last4)) {
      return setState(() => _error = 'Last four digits must be 4 numbers');
    }
    if (limit == null || limit <= 0) {
      return setState(() => _error = 'Enter the credit limit');
    }
    if (outstanding == null) {
      return setState(() => _error = 'Enter a valid outstanding amount');
    }
    final c = widget.edit;
    if (c == null) {
      await context.store.addCard(
        name: name,
        lastFour: last4,
        creditLimit: limit,
        statementDay: _statementDay,
        dueDay: _dueDay,
        openingOutstanding: outstanding,
      );
    } else {
      await context.store.updateCard(
        c,
        name: name,
        lastFour: last4,
        creditLimit: limit,
        statementDay: _statementDay,
        dueDay: _dueDay,
        currentOutstanding: outstanding,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Widget _dayPicker(String label, int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var d = 1; d <= 31; d++)
          DropdownMenuItem(value: d, child: Text(d == 31 ? '31 / last' : '$d')),
      ],
      onChanged: (v) => setState(() => onChanged(v!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: widget.edit == null ? 'Add credit card' : 'Edit card',
      error: _error,
      onSave: _save,
      children: [
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Card name',
            hintText: 'e.g. HDFC Millennia',
          ),
        ),
        TextField(
          controller: _last4,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Last 4 digits (optional)',
            counterText: '',
          ),
        ),
        AmountField(controller: _limit, label: 'Credit limit'),
        Row(
          children: [
            Expanded(
              child: _dayPicker(
                'Statement day',
                _statementDay,
                (v) => _statementDay = v,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _dayPicker('Due day', _dueDay, (v) => _dueDay = v)),
          ],
        ),
        AmountField(
          controller: _outstanding,
          label: widget.edit == null
              ? 'Amount owed now (optional)'
              : 'Amount owed now',
        ),
      ],
    );
  }
}

class _InvestmentForm extends StatefulWidget {
  const _InvestmentForm({this.edit});
  final Investment? edit;

  @override
  State<_InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<_InvestmentForm> {
  final _name = TextEditingController();
  InvestmentType _type = InvestmentType.mutualFund;
  String? _error;

  @override
  void initState() {
    super.initState();
    final inv = widget.edit;
    if (inv != null) {
      _name.text = inv.name;
      _type = inv.type;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Enter a name');
    final edit = widget.edit;
    if (edit != null) {
      await context.store.updateInvestment(edit, name, _type);
      if (mounted) Navigator.pop(context);
      return;
    }
    final inv = await context.store.addInvestment(name, _type);
    if (mounted) Navigator.pop(context, inv);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: widget.edit == null ? 'Add investment' : 'Edit investment',
      error: _error,
      onSave: _save,
      children: [
        DropdownButtonFormField<InvestmentType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: [
            for (final t in InvestmentType.values)
              DropdownMenuItem(value: t, child: Text(t.label)),
          ],
          onChanged: (v) => setState(() => _type = v!),
        ),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Nifty 50 index fund',
          ),
        ),
        Text(
          'Record money you put in with “Invest” in the add screen. It is kept '
          'out of your spending.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ValueForm extends StatefulWidget {
  const _ValueForm({required this.investment});
  final Investment investment;

  @override
  State<_ValueForm> createState() => _ValueFormState();
}

class _ValueFormState extends State<_ValueForm> {
  final _value = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = widget.investment.currentValue;
    if (v != null) {
      _value.text = (v / 100).toStringAsFixed(v % 100 == 0 ? 0 : 2);
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = parseRupees(_value.text);
    if (value == null) return setState(() => _error = 'Enter a valid value');
    await context.store.updateInvestmentValue(
      widget.investment,
      value,
      today(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: 'Current value',
      error: _error,
      onSave: _save,
      children: [
        Text(
          widget.investment.name,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        AmountField(controller: _value, label: 'Value today', autofocus: true),
        Text(
          'Check your fund statement, broker app or passbook. This is your '
          'own figure, not a live market price.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

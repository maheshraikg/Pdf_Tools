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

Future<void> showAddCardDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _CardForm());

Future<Investment?> showAddInvestmentDialog(BuildContext context) =>
    showDialog<Investment>(
      context: context,
      builder: (_) => const _InvestmentForm(),
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
  const _AccountForm();

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _name = TextEditingController();
  final _opening = TextEditingController();
  AccountKind _kind = AccountKind.savings;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final opening = _optionalAmount(_opening.text);
    if (name.isEmpty) return setState(() => _error = 'Enter a name');
    if (opening == null) {
      return setState(() => _error = 'Enter a valid balance');
    }
    await context.store.addAccount(name, _kind, opening);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: 'Add account',
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
            border: const OutlineInputBorder(),
          ),
        ),
        AmountField(controller: _opening, label: 'Current balance'),
      ],
    );
  }
}

class _CardForm extends StatefulWidget {
  const _CardForm();

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
    await context.store.addCard(
      name: name,
      lastFour: last4,
      creditLimit: limit,
      statementDay: _statementDay,
      dueDay: _dueDay,
      openingOutstanding: outstanding,
    );
    if (mounted) Navigator.pop(context);
  }

  Widget _dayPicker(String label, int value, ValueChanged<int> onChanged) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
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
      title: 'Add credit card',
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
            border: OutlineInputBorder(),
          ),
        ),
        TextField(
          controller: _last4,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'Last 4 digits (optional)',
            border: OutlineInputBorder(),
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
          label: 'Amount owed now (optional)',
        ),
      ],
    );
  }
}

class _InvestmentForm extends StatefulWidget {
  const _InvestmentForm();

  @override
  State<_InvestmentForm> createState() => _InvestmentFormState();
}

class _InvestmentFormState extends State<_InvestmentForm> {
  final _name = TextEditingController();
  InvestmentType _type = InvestmentType.mutualFund;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Enter a name');
    final inv = await context.store.addInvestment(name, _type);
    if (mounted) Navigator.pop(context, inv);
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: 'Add investment',
      error: _error,
      onSave: _save,
      children: [
        DropdownButtonFormField<InvestmentType>(
          initialValue: _type,
          decoration: const InputDecoration(
            labelText: 'Type',
            border: OutlineInputBorder(),
          ),
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
            border: OutlineInputBorder(),
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

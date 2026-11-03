import 'package:flutter/material.dart';

import '../app/scope.dart';
import '../models/goals.dart';
import '../models/money.dart';
import '../widgets/common.dart';
import '../widgets/design.dart';
import 'loans_screen.dart';

/// Things to save up for, with progress and how much to put aside monthly.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.ledger;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final goals = [...l.goals]
      ..sort((a, b) => a.reached == b.reached ? 0 : (a.reached ? 1 : -1));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings goals'),
        actions: [
          if (goals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add goal',
              onPressed: () => showGoalForm(context),
            ),
        ],
      ),
      body: goals.isEmpty
          ? IntroState(
              title: 'Save first,',
              accent: 'then buy.',
              accentColor: scheme.moneyIn,
              points: const [
                'Emergency fund',
                'New phone or laptop',
                'Bike, trip or wedding',
              ],
              note:
                  'Set a target and a date. RupeeTrack tells you how much '
                  'to put aside each month.',
              actionLabel: 'Add a goal',
              onAction: () => showGoalForm(context),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 40),
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Saved so far',
                    style: t.titleMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    formatRupees(l.goalsSaved),
                    style: t.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.moneyIn,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'of ${formatRupees(goals.fold(0, (a, g) => a + g.target))}',
                    style: t.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                for (final g in goals) _GoalCard(goal: g),
              ],
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = t.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final monthly = g.monthlyNeeded(today());
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(g.name, style: t.titleMedium)),
              Text(
                '${(g.progress * 100).round()}%',
                style: t.titleMedium?.copyWith(color: scheme.moneyIn),
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  final store = context.store;
                  switch (v) {
                    case 'edit':
                      await showGoalForm(context, edit: g);
                    case 'withdraw':
                      await showGoalMoney(context, g, withdraw: true);
                    case 'delete':
                      final ok = await confirmDelete(
                        context,
                        'Delete ${g.name}?',
                        'Your accounts are not changed.',
                      );
                      if (ok) await store.deleteGoal(g.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'withdraw',
                    child: Text('Take money out'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Meter(value: g.progress, color: scheme.moneyIn, height: 8),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatRupees(g.saved)} of ${formatRupees(g.target)}',
                  style: muted,
                ),
              ),
              if (g.targetDate != null)
                Text('By ${monthYear(g.targetDate!)}', style: muted),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: g.reached
                    ? Text(
                        'Goal reached',
                        style: t.titleSmall?.copyWith(color: scheme.moneyIn),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            monthly == null ? 'Still needed' : 'Put aside',
                            style: muted,
                          ),
                          Text(
                            monthly == null
                                ? formatRupees(g.remaining)
                                : '${formatRupees(monthly)} / month',
                            style: t.titleSmall,
                          ),
                        ],
                      ),
              ),
              if (!g.reached)
                FilledButton.tonal(
                  onPressed: () => showGoalMoney(context, g),
                  child: const Text('Add money'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showGoalMoney(
  BuildContext context,
  SavingsGoal goal, {
  bool withdraw = false,
}) async {
  final c = TextEditingController();
  String? error;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(withdraw ? 'Take money out' : 'Add to ${goal.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountField(controller: c, autofocus: true),
            if (error != null) ...[
              const SizedBox(height: 10),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final v = parseRupees(c.text);
              if (v == null || v <= 0) {
                return setState(() => error = 'Enter a valid amount');
              }
              if (withdraw && v > goal.saved) {
                return setState(() => error = 'More than what is saved');
              }
              await context.store.addToGoal(goal, withdraw ? -v : v, today());
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  c.dispose();
}

Future<void> showGoalForm(BuildContext context, {SavingsGoal? edit}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _GoalForm(edit: edit),
    );

class _GoalForm extends StatefulWidget {
  const _GoalForm({this.edit});
  final SavingsGoal? edit;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _saved = TextEditingController();
  DateTime? _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      _name.text = e.name;
      _target.text = amountText(e.target);
      _date = e.targetDate;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = parseRupees(_target.text);
    final saved = _saved.text.trim().isEmpty ? 0 : parseRupees(_saved.text);
    if (name.isEmpty) return setState(() => _error = 'Enter a name');
    if (target == null || target <= 0) {
      return setState(() => _error = 'Enter the target amount');
    }
    if (saved == null || saved < 0) {
      return setState(() => _error = 'Enter a valid amount saved');
    }
    final e = widget.edit;
    await context.store.saveGoal(
      e == null
          ? SavingsGoal(
              id: 0,
              name: name,
              target: target,
              targetDate: _date,
              entries: [if (saved > 0) GoalEntry(today(), saved)],
            )
          : e.copyWith(
              name: name,
              target: target,
              targetDate: _date,
              clearDate: _date == null,
            ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.edit == null ? 'Add goal' : 'Edit goal'),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            autofocus: widget.edit == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Goal',
              hintText: 'e.g. Emergency fund',
            ),
          ),
          const SizedBox(height: 12),
          AmountField(controller: _target, label: 'Target amount'),
          if (widget.edit == null) ...[
            const SizedBox(height: 12),
            AmountField(controller: _saved, label: 'Already saved (optional)'),
          ],
          const SizedBox(height: 12),
          DateButton(
            label: 'Target date (optional)',
            date: _date,
            optional: true,
            onChanged: (d) => setState(() => _date = d),
          ),
          if (_date != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _date = null),
                child: const Text('Remove date'),
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

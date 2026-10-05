import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/engine/closure.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../../widgets/schedule_table.dart';
import '../../widgets/share_card.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.result,
    this.girlAge,
    this.saved = false,
  });

  final CalcResult result;

  /// SSY: the girl's age at opening (for the withdrawal year).
  final int? girlAge;

  /// Opened from My accounts (hides "Save account").
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, scheme = r.scheme;
    final payout = scheme.payout;
    final fyRows = r.interestByFy;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.schemeName(scheme)),
        actions: [
          IconButton(
            tooltip: s.share,
            icon: const Icon(Icons.share),
            onPressed: () => showShareCard(context, r),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (scheme == Scheme.sb)
                    ValueTile(
                      s.yearlyInterestSb,
                      rupee(r.totalInterest),
                      emphasis: true,
                    )
                  else ...[
                    ValueTile(
                      payout == null ? s.maturityValue : s.totalReceived,
                      rupee(r.maturityValue),
                      emphasis: true,
                    ),
                    if (payout != null && r.periodicPayout != null)
                      ValueTile(s.payout(payout), rupee(r.periodicPayout!)),
                    ValueTile(s.totalDeposit, rupee(r.totalDeposit)),
                    ValueTile(s.totalInterest, rupee(r.totalInterest)),
                    ValueTile(s.maturityDate, dmy(r.maturityDate)),
                  ],
                ],
              ),
            ),
          ),
          Note(
            s.rateUsed(
              pct(r.input.rate),
              r.input.rateFrom == null ? null : dmy(r.input.rateFrom!),
            ),
            icon: Icons.percent,
          ),
          if (scheme.rateFloats) Note(s.rateFloats),
          Note(s.estimateOnly, icon: Icons.warning_amber),
          if (!saved) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _save(context),
              icon: const Icon(Icons.bookmark_add),
              label: Text(s.saveAccount),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => showShareCard(context, r),
              icon: const Icon(Icons.share),
              label: Text(s.share),
            ),
          ],
          if (scheme != Scheme.sb) ...[
            SectionTitle(s.yearWise),
            ScheduleTable(rows: r.schedule),
          ],
          if (scheme.showsTaxableInterest && fyRows.isNotEmpty) ...[
            SectionTitle(s.fyInterest),
            PairTable(
              head1: s.fy,
              head2: s.interest,
              rows: [for (final e in fyRows.entries) (e.key, rupee(e.value))],
            ),
            if (scheme == Scheme.nsc) Note(s.nscTaxNote),
          ],
          if (scheme != Scheme.sb) _ClosureSection(result: r),
          ..._extensions(context),
          ..._withdrawals(context),
          const SizedBox(height: 16),
          Note(s.notAffiliated),
        ],
      ),
    );
  }

  List<Widget> _extensions(BuildContext context) {
    final s = context.s;
    final opts = extensions(result, context.rates.current(result.scheme).rate);
    if (opts.isEmpty) return const [];
    return [
      SectionTitle(s.extension),
      for (final o in opts)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.extensionKind(o.kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (o.result.periodicPayout != null &&
                    o.result.scheme.payout != null)
                  ValueTile(
                    s.payout(o.result.scheme.payout!),
                    rupee(o.result.periodicPayout!),
                  ),
                ValueTile(s.maturityValue, rupee(o.result.maturityValue)),
                ValueTile(s.maturityDate, dmy(o.result.maturityDate)),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _withdrawals(BuildContext context) {
    final s = context.s;
    if (result.scheme == Scheme.ppf) {
      final limits = ppfWithdrawals(result);
      return [
        SectionTitle(s.withdrawals),
        Note(s.ppfWithdrawalNote),
        PairTable(
          head1: s.year,
          head2: s.limit,
          rows: [for (final l in limits) ('${l.year}', rupee(l.limit))],
        ),
      ];
    }
    if (result.scheme == Scheme.ssy) {
      final w = girlAge == null ? null : ssyWithdrawal(result, girlAge!);
      return [
        SectionTitle(s.withdrawals),
        Note(s.ssyWithdrawalNote),
        if (w != null) ValueTile('${s.year} ${w.year}', rupee(w.limit)),
      ];
    }
    return const [];
  }

  Future<void> _save(BuildContext context) async {
    final s = context.s;
    final accounts = context.accounts;
    final messenger = ScaffoldMessenger.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: s.schemeName(result.scheme)),
    );
    if (name == null || name.isEmpty) return;
    await accounts.add(name, result.input);
    messenger.showSnackBar(SnackBar(content: Text(s.saved)));
  }
}

/// Asks for a name for the saved account; pops with the trimmed name.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return AlertDialog(
      title: Text(s.saveAccount),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: InputDecoration(
          labelText: s.accountName,
          hintText: s.accountNameHint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ctrl.text.trim()),
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _ClosureSection extends StatefulWidget {
  const _ClosureSection({required this.result});
  final CalcResult result;

  @override
  State<_ClosureSection> createState() => _ClosureSectionState();
}

class _ClosureSectionState extends State<_ClosureSection> {
  DateTime? _closeOn;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = widget.result, rates = context.rates;
    final closeOn = _closeOn ?? DateUtils.dateOnly(DateTime.now());
    final c = prematureClosure(
      r,
      closeOn,
      sbRate: rates.current(Scheme.sb).rate,
      td3Rate: rates.entryOn(Scheme.td3, r.input.opening)?.rate,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(s.prematureClosure),
        if (c.rule != ClosureRule.useWithdrawal &&
            c.rule != ClosureRule.notAllowed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_busy),
            title: Text(s.closingDate),
            subtitle: Text(
              dmy(closeOn),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: const Icon(Icons.edit_calendar),
            onTap: () async {
              final d = await pickDate(
                context,
                closeOn,
                first: r.input.opening,
                last: r.maturityDate,
              );
              if (d != null) setState(() => _closeOn = d);
            },
          ),
        Note(
          s.closureRule(
            c.rule,
            months: c.minMonths,
            rate: c.rateUsed == null ? null : pct(c.rateUsed!),
          ),
          icon: Icons.rule,
        ),
        if (c.allowed)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ValueTile(s.payable, rupee(c.payable!), emphasis: true),
                  if (c.interest != null)
                    ValueTile(s.interestAllowed, rupee(c.interest!)),
                  if (c.alreadyPaid != null && c.alreadyPaid! > Decimal.zero)
                    ValueTile(s.alreadyPaid, rupee(c.alreadyPaid!)),
                  if (c.deduction != null)
                    ValueTile(s.deduction, rupee(c.deduction!)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

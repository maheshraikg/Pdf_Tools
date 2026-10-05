import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/engine/closure.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/charts.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
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
    final fyRows = r.interestByFy;
    final c = scheme.color;
    var i = 0;
    Widget step(Widget w) => Appear(delay: Appear.step(i++, ms: 70), child: w);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(result: r),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (scheme != Scheme.sb) step(_Breakup(result: r)),
                if (!saved)
                  step(
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: c,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _save(context),
                            icon: const Icon(Icons.bookmark_add_rounded),
                            label: Text(
                              s.saveAccount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          tooltip: s.share,
                          iconSize: 26,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(56, 56),
                            backgroundColor: Brand.yellowSoft,
                            foregroundColor: Brand.ink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => showShareCard(context, r),
                          icon: const Icon(Icons.share_rounded),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                if (scheme != Scheme.sb && r.schedule.length > 1)
                  step(
                    SectionCard(
                      icon: Icons.insights_rounded,
                      title: s.growth,
                      color: c,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GrowthBars(rows: r.schedule, color: c),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            children: [
                              LegendDot(c, s.deposit),
                              LegendDot(Brand.yellow, s.interest),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (scheme != Scheme.sb)
                  step(
                    SectionCard(
                      icon: Icons.table_chart_rounded,
                      title: s.yearWise,
                      color: c,
                      child: ScheduleTable(rows: r.schedule),
                    ),
                  ),
                if (scheme.showsTaxableInterest && fyRows.isNotEmpty)
                  step(
                    SectionCard(
                      icon: Icons.receipt_long_rounded,
                      title: s.fyInterest,
                      color: c,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PairTable(
                            head1: s.fy,
                            head2: s.interest,
                            rows: [
                              for (final e in fyRows.entries)
                                (e.key, rupee(e.value)),
                            ],
                          ),
                          if (scheme == Scheme.nsc) Note(s.nscTaxNote),
                        ],
                      ),
                    ),
                  ),
                if (scheme != Scheme.sb) step(_ClosureSection(result: r)),
                ..._extensions(context).map(step),
                ..._withdrawals(context).map(step),
                const SizedBox(height: 8),
                Note(
                  s.rateUsed(
                    pct(r.input.rate),
                    r.input.rateFrom == null ? null : dmy(r.input.rateFrom!),
                  ),
                  icon: Icons.percent_rounded,
                ),
                if (scheme.rateFloats) Note(s.rateFloats),
                Note(s.estimateOnly, icon: Icons.warning_amber_rounded),
                Note(s.notAffiliated, icon: Icons.gpp_maybe_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _extensions(BuildContext context) {
    final s = context.s;
    final opts = extensions(result, context.rates.current(result.scheme).rate);
    if (opts.isEmpty) return const [];
    return [
      SectionCard(
        icon: Icons.update_rounded,
        title: s.extension,
        color: result.scheme.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (n, o) in opts.indexed) ...[
              if (n > 0) const Divider(height: 20),
              Text(
                s.extensionKind(o.kind),
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
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
          ],
        ),
      ),
    ];
  }

  List<Widget> _withdrawals(BuildContext context) {
    final s = context.s;
    final c = result.scheme.color;
    if (result.scheme == Scheme.ppf) {
      final limits = ppfWithdrawals(result);
      return [
        SectionCard(
          icon: Icons.savings_rounded,
          title: s.withdrawals,
          color: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Note(s.ppfWithdrawalNote),
              PairTable(
                head1: s.year,
                head2: s.limit,
                rows: [for (final l in limits) ('${l.year}', rupee(l.limit))],
              ),
            ],
          ),
        ),
      ];
    }
    if (result.scheme == Scheme.ssy) {
      final w = girlAge == null ? null : ssyWithdrawal(result, girlAge!);
      return [
        SectionCard(
          icon: Icons.school_rounded,
          title: s.withdrawals,
          color: c,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Note(s.ssyWithdrawalNote),
              if (w != null) ValueTile('${s.year} ${w.year}', rupee(w.limit)),
            ],
          ),
        ),
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
    final col = r.scheme.color;
    return SectionCard(
      icon: Icons.lock_open_rounded,
      title: s.prematureClosure,
      color: col,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (c.rule != ClosureRule.useWithdrawal &&
              c.rule != ClosureRule.notAllowed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_busy_rounded, color: col),
              title: Text(s.closingDate),
              subtitle: Text(
                dmy(closeOn),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              trailing: Icon(Icons.edit_calendar_rounded, color: col),
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
            icon: Icons.rule_rounded,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: !c.allowed
                ? const SizedBox(width: double.infinity)
                : Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: col.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        ValueTile(s.payable, rupee(c.payable!), emphasis: true),
                        if (c.interest != null)
                          ValueTile(s.interestAllowed, rupee(c.interest!)),
                        if (c.alreadyPaid != null &&
                            c.alreadyPaid! > Decimal.zero)
                          ValueTile(s.alreadyPaid, rupee(c.alreadyPaid!)),
                        if (c.deduction != null)
                          ValueTile(s.deduction, rupee(c.deduction!)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Gradient header: total counting up, maturity date, rate and payout pills.
class _Hero extends StatelessWidget {
  const _Hero({required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, scheme = r.scheme;
    final t = Theme.of(context).textTheme;
    final payout = scheme.payout;
    final white = Colors.white.withValues(alpha: 0.85);
    final title = scheme == Scheme.sb
        ? s.yearlyInterestSb
        : payout == null
        ? s.maturityValue
        : s.totalReceived;
    return GradientHeader(
      gradient: scheme.gradient,
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 26),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BackButton(color: Colors.white),
                Hero(
                  tag: 'scheme-${scheme.code}',
                  child: Icon(scheme.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.schemeName(scheme),
                    style: t.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.bodyLarge?.copyWith(color: white)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AnimatedRupee(
                      scheme == Scheme.sb ? r.totalInterest : r.maturityValue,
                      style: t.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (scheme != Scheme.sb)
                        Pill(
                          '${s.maturityDate}: ${dmy(r.maturityDate)}',
                          icon: Icons.event_available_rounded,
                          background: Brand.yellow,
                          foreground: Brand.ink,
                        ),
                      Pill(
                        s.perYear(pct(r.input.rate)),
                        icon: Icons.percent_rounded,
                        background: Colors.white.withValues(alpha: 0.18),
                        foreground: Colors.white,
                      ),
                      if (payout != null && r.periodicPayout != null)
                        Pill(
                          '${s.payout(payout)}: ${rupee(r.periodicPayout!)}',
                          icon: Icons.payments_rounded,
                          background: Colors.white.withValues(alpha: 0.18),
                          foreground: Colors.white,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Donut of deposit vs interest with the amounts beside it.
class _Breakup extends StatelessWidget {
  const _Breakup({required this.result});
  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, c = r.scheme.color;
    final t = Theme.of(context).textTheme;
    final growth = r.totalDeposit == Decimal.zero
        ? Decimal.zero
        : (r.totalInterest * Decimal.fromInt(100) / r.totalDeposit).toDecimal(
            scaleOnInfinitePrecision: 4,
          );
    Widget amount(Color dot, String label, Decimal v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegendDot(dot, label),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedRupee(
              v,
              style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DonutChart(
              deposit: r.totalDeposit,
              interest: r.totalInterest,
              color: c,
              size: 128,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.growthPct(growth.round(scale: 1).toString()),
                    style: t.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: r.scheme.textColor(context),
                    ),
                  ),
                  Text(s.interest, style: t.labelSmall),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  amount(c, s.yourMoney, r.totalDeposit),
                  amount(Brand.yellow, s.interestEarned, r.totalInterest),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

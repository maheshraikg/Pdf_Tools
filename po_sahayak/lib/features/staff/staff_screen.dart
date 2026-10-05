import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/engine/eligibility.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../../widgets/share_card.dart';
import '../result/result_screen.dart';

/// Counter / agent tools: eligibility, document checklist, quick calc.
class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  Scheme _scheme = Scheme.td5;
  Holding _holding = Holding.single;
  final _amount = TextEditingController(text: '100000');
  final _age = TextEditingController();
  List<Issue>? _issues;

  @override
  void dispose() {
    _amount.dispose();
    _age.dispose();
    super.dispose();
  }

  Decimal? get _amt => Decimal.tryParse(_amount.text);

  void _check() {
    final a = _amt;
    if (a == null) return;
    setState(
      () => _issues = checkEligibility(
        EligibilityInput(
          scheme: _scheme,
          amount: a,
          age: int.tryParse(_age.text),
          holding: _holding,
          opening: DateUtils.dateOnly(DateTime.now()),
        ),
      ),
    );
  }

  CalcResult? _quick(BuildContext context) {
    final a = _amt;
    if (a == null || a < _scheme.min || _scheme == Scheme.mssc) return null;
    return calculate(
      CalcInput(
        scheme: _scheme,
        amount: a,
        opening: DateUtils.dateOnly(DateTime.now()),
        rate: context.rates.current(_scheme).rate,
        rateFrom: context.rates.current(_scheme).from,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, t = Theme.of(context).textTheme;
    final quick = _quick(context);
    final max = _scheme.maxAmount == null
        ? null
        : rupee(maxFor(_scheme, _holding));
    return Scaffold(
      appBar: AppBar(title: Text(s.staff), actions: const [LanguageToggle()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<Scheme>(
            initialValue: _scheme,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.scheme),
            items: [
              for (final sc in Scheme.values)
                DropdownMenuItem(
                  value: sc,
                  child: Text(
                    '${sc.code} – ${s.schemeName(sc)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() {
              _scheme = v ?? _scheme;
              _issues = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: s.amountLabel(_scheme.amountKind),
                  ),
                  onChanged: (_) => setState(() => _issues = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _scheme == Scheme.ssy ? s.girlAge : s.age,
                  ),
                  onChanged: (_) => setState(() => _issues = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<Holding>(
            segments: [
              for (final h in Holding.values)
                ButtonSegment(value: h, label: Text(s.holding(h))),
            ],
            selected: {_holding},
            onSelectionChanged: (v) => setState(() {
              _holding = v.first;
              _issues = null;
            }),
          ),
          SectionTitle(s.eligibility),
          FilledButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.fact_check),
            label: Text(s.check),
          ),
          if (_issues != null) ...[
            const SizedBox(height: 8),
            if (_issues!.isEmpty)
              Note(s.eligible, icon: Icons.check_circle)
            else
              for (final i in _issues!)
                Note(s.issue(i, _scheme, max: max), icon: Icons.error_outline),
          ],
          SectionTitle(s.documents),
          for (final d in documentsFor(_scheme, h: _holding))
            Note(s.doc(d), icon: Icons.check_box_outline_blank),
          Note(s.documentsNote),
          SectionTitle(s.quickCalc),
          if (quick != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (quick.scheme.payout != null &&
                        quick.periodicPayout != null)
                      ValueTile(
                        s.payout(quick.scheme.payout!),
                        rupee(quick.periodicPayout!),
                      ),
                    ValueTile(s.totalInterest, rupee(quick.totalInterest)),
                    ValueTile(
                      s.maturityValue,
                      rupee(quick.maturityValue),
                      emphasis: true,
                    ),
                    ValueTile(s.maturityDate, dmy(quick.maturityDate)),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => showShareCard(context, quick),
                      icon: const Icon(Icons.share),
                      label: Text(s.share),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ResultScreen(result: quick),
                        ),
                      ),
                      child: Text(s.result),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(s.enterAmount, style: t.bodyMedium),
          const SizedBox(height: 8),
          Note(s.estimateOnly),
        ],
      ),
    );
  }
}

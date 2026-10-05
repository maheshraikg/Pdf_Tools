import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../result/result_screen.dart';

/// Results for the same amount across [Scheme.compared], at today's rates.
List<CalcResult> compareAll(
  Decimal amount,
  DateTime opening,
  Decimal Function(Scheme) rateOf,
) {
  final out = <CalcResult>[];
  for (final s in Scheme.compared) {
    var a = amount;
    if (s == Scheme.rd) {
      // The amount spread over 60 instalments, in multiples of ₹10.
      a =
          (amount / Decimal.fromInt(600)).floor().toDecimal() *
          Decimal.fromInt(10);
      if (a < s.min) continue;
    }
    if (s == Scheme.mis && a > Decimal.fromInt(Scheme.misJointMax)) continue;
    out.add(
      calculate(
        CalcInput(scheme: s, amount: a, opening: opening, rate: rateOf(s)),
      ),
    );
  }
  return out;
}

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final _amount = TextEditingController(text: '100000');

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s, rates = context.rates;
    final amount = Decimal.tryParse(_amount.text);
    final results = amount == null || amount < Decimal.fromInt(1000)
        ? const <CalcResult>[]
        : compareAll(
            amount,
            DateUtils.dateOnly(DateTime.now()),
            (sc) => rates.current(sc).rate,
          );
    return Scaffold(
      appBar: AppBar(title: Text(s.compare), actions: const [LanguageToggle()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.compareTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.titleLarge,
            decoration: InputDecoration(labelText: s.amount, prefixText: '₹ '),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          for (final r in results)
            Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ResultScreen(result: r),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${s.schemeName(r.scheme)} · ${pct(r.input.rate)}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (r.scheme == Scheme.rd)
                        ValueTile(
                          s.amountLabel(AmountKind.monthly),
                          rupee(r.input.amount),
                        ),
                      if (r.scheme.payout != null && r.periodicPayout != null)
                        ValueTile(
                          s.payout(r.scheme.payout!),
                          rupee(r.periodicPayout!),
                        ),
                      ValueTile(s.totalInterest, rupee(r.totalInterest)),
                      ValueTile(
                        s.maturityValue,
                        rupee(r.maturityValue),
                        emphasis: true,
                      ),
                      ValueTile(
                        s.period,
                        s.months(
                          r.scheme == Scheme.kvp
                              ? kvpMonths(r.input.rate)
                              : r.scheme.tenureMonths,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Note(s.compareNote),
          Note(s.estimateOnly),
        ],
      ),
    );
  }
}

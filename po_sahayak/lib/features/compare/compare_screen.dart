import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/format.dart';
import '../../app/scope.dart';
import '../../app/theme.dart';
import '../../domain/engine/calculators.dart';
import '../../domain/models/result.dart';
import '../../domain/models/scheme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
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
    final t = Theme.of(context).textTheme;
    final amount = Decimal.tryParse(_amount.text);
    final results =
        amount == null || amount < Decimal.fromInt(1000)
              ? <CalcResult>[]
              : compareAll(
                  amount,
                  DateUtils.dateOnly(DateTime.now()),
                  (sc) => rates.current(sc).rate,
                )
          // 5-year schemes ranked by value; KVP (115 months) last, so the
          // "highest return" badge compares like with like.
          ..sort((a, b) {
            final ka = a.scheme == Scheme.kvp ? 1 : 0;
            final kb = b.scheme == Scheme.kvp ? 1 : 0;
            if (ka != kb) return ka - kb;
            return b.maturityValue.compareTo(a.maturityValue);
          });
    final best = results.isEmpty
        ? null
        : results.map((r) => r.maturityValue).reduce((a, b) => a > b ? a : b);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.compare,
                          style: t.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const LanguageToggle(onDark: true),
                    ],
                  ),
                  Text(
                    s.compareTitle,
                    style: t.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Brand.ink,
                    ),
                    decoration: InputDecoration(
                      hintText: s.amount,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.currency_rupee_rounded,
                        color: Brand.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in const [50000, 100000, 500000, 1000000])
                        ActionChip(
                          label: Text(rupee(Decimal.fromInt(a))),
                          backgroundColor: amount == Decimal.fromInt(a)
                              ? Brand.yellow
                              : Colors.white.withValues(alpha: 0.9),
                          labelStyle: const TextStyle(
                            color: Brand.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide.none,
                          onPressed: () =>
                              setState(() => _amount.text = a.toString()),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, r) in results.indexed)
                  Appear(
                    key: ValueKey('${r.scheme.code}-${amount ?? ''}'),
                    delay: Appear.step(i, ms: 80),
                    child: _CompareCard(result: r, best: best!, isBest: i == 0),
                  ),
                const SizedBox(height: 8),
                Note(s.compareNote),
                Note(s.estimateOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    required this.result,
    required this.best,
    required this.isBest,
  });

  final CalcResult result;
  final Decimal best;
  final bool isBest;

  @override
  Widget build(BuildContext context) {
    final s = context.s, r = result, c = r.scheme.color;
    final t = Theme.of(context).textTheme;
    final share = best == Decimal.zero
        ? 0.0
        : (r.maturityValue / best).toDouble().clamp(0.05, 1.0);
    final months = r.scheme == Scheme.kvp
        ? kvpMonths(r.input.rate)
        : r.scheme.tenureMonths;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isBest
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Brand.yellow, width: 2),
            )
          : null,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ResultScreen(result: r)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // On its own line so it never squeezes the name.
              if (isBest) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Pill(
                    s.highestReturn,
                    icon: Icons.emoji_events_rounded,
                    background: Brand.yellow,
                    foreground: Brand.ink,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  IconBadge(r.scheme.icon, c, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.schemeName(r.scheme),
                          style: t.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${pct(r.input.rate)}% · ${s.months(months)}',
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: share),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 14,
                          color: c,
                          backgroundColor: c.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRupee(
                    r.maturityValue,
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                children: [
                  Text(
                    '${s.totalInterest}: ${rupee(r.totalInterest)}',
                    style: t.bodySmall,
                  ),
                  if (r.scheme.payout != null && r.periodicPayout != null)
                    Text(
                      '${s.payout(r.scheme.payout!)}: ${rupee(r.periodicPayout!)}',
                      style: t.bodySmall,
                    ),
                  if (r.scheme == Scheme.rd)
                    Text(
                      '${s.amountLabel(AmountKind.monthly)}: ${rupee(r.input.amount)}',
                      style: t.bodySmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

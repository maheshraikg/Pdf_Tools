/// Premature closure, extensions and partial withdrawals (rules table in
/// PLAN.md; rules marked "verify" there are estimates until confirmed).
library;

import 'package:decimal/decimal.dart';

import '../models/result.dart';
import '../models/scheme.dart';
import 'calculators.dart';
import 'dates.dart';
import 'money.dart';

/// Why closure is not allowed, or which rule applied.
enum ClosureRule {
  notYet, // minimum period not completed
  notAllowed, // scheme does not allow premature closure (NSC)
  useWithdrawal, // PPF / SSY / SB: see withdrawal rules
  afterMaturity, // closing on or after maturity: full value
  tdSbRate, // TD 6–12 months: SB rate
  tdMinus2, // TD after 1 year: TD rate − 2%
  td5NewSbRate, // 5-yr TD opened on/after 9 Nov 2023, after 4 years: SB rate
  td5OldMinus2, // 5-yr TD opened earlier: 3-yr TD rate − 2%
  rdSbRate, // RD after 3 years: SB rate
  misDeduct, // MIS: 2% (1–3 yrs) or 1% (after 3 yrs) of deposit
  scssRecover, // SCSS before 1 yr: interest paid is recovered
  scssDeduct, // SCSS: 1.5% (1–2 yrs) or 1% (after 2 yrs) of deposit
  kvpTable, // KVP after 2½ yrs: official table (estimated here)
  msscMinus2, // MSSC after 6 months: rate − 2%
}

class ClosureResult {
  const ClosureResult({
    required this.rule,
    this.minMonths,
    this.payable,
    this.interest,
    this.alreadyPaid,
    this.deduction,
    this.rateUsed,
  });

  final ClosureRule rule;

  /// Minimum months before closure (for [ClosureRule.notYet]).
  final int? minMonths;

  /// Amount paid on closure.
  final Decimal? payable;

  /// Interest allowed for the period held.
  final Decimal? interest;

  /// Interest already paid out, adjusted on closure.
  final Decimal? alreadyPaid;

  /// Deduction from the deposit.
  final Decimal? deduction;

  /// Rate (% p.a.) applied.
  final Decimal? rateUsed;

  bool get allowed => payable != null;
}

/// Date the 2023 TD amendment (G.S.R. 830(E)) took effect.
final DateTime kTd5RuleChange = DateTime(2023, 11, 9);

/// Interest paid out (MIS, SCSS, TD) on or before [on]; zero for schemes
/// whose interest is only accrued.
Decimal _paidBy(CalcResult r, DateTime on) => r.scheme.payout == null
    ? Decimal.zero
    : r.interestEvents
          .where((e) => !e.date.isAfter(on))
          .fold(Decimal.zero, (a, e) => a + e.amount);

/// Premature closure of [r] on [closeOn]. [sbRate] is the current savings
/// rate; [td3Rate] the 3-year TD rate (for 5-year TDs opened before the
/// 2023 change).
ClosureResult prematureClosure(
  CalcResult r,
  DateTime closeOn, {
  required Decimal sbRate,
  Decimal? td3Rate,
}) {
  final s = r.scheme, i = r.input, p = r.totalDeposit;
  final m = monthsBetween(i.opening, closeOn);
  if (!closeOn.isBefore(r.maturityDate)) {
    return ClosureResult(
      rule: ClosureRule.afterMaturity,
      payable: r.maturityValue - _paidBy(r, closeOn),
      interest: r.totalInterest,
      alreadyPaid: _paidBy(r, closeOn),
    );
  }
  ClosureResult notYet(int months) =>
      ClosureResult(rule: ClosureRule.notYet, minMonths: months);
  final two = Decimal.fromInt(2);

  switch (s) {
    case Scheme.sb || Scheme.ppf || Scheme.ssy:
      return const ClosureResult(rule: ClosureRule.useWithdrawal);
    case Scheme.nsc:
      return const ClosureResult(rule: ClosureRule.notAllowed);
    case Scheme.td1 || Scheme.td2 || Scheme.td3 || Scheme.td5:
      final newTd5 = s == Scheme.td5 && !i.opening.isBefore(kTd5RuleChange);
      if (newTd5 && m < 48) return notYet(48);
      if (m < 6) return notYet(6);
      final ClosureRule rule;
      final Decimal rate;
      final Decimal interest;
      if (m < 12) {
        rule = ClosureRule.tdSbRate;
        rate = sbRate;
        interest = rupees(div(p * rate * Decimal.fromInt(m), k1200));
      } else {
        if (newTd5) {
          rule = ClosureRule.td5NewSbRate;
          rate = sbRate;
        } else if (s == Scheme.td5 && td3Rate != null) {
          rule = ClosureRule.td5OldMinus2;
          rate = td3Rate - two;
        } else {
          rule = ClosureRule.tdMinus2;
          rate = i.rate - two;
        }
        // Compounded quarterly for completed quarters.
        interest = rupees(
          p * (pw(Decimal.one + div(rate, k400), m ~/ 3) - Decimal.one),
        );
      }
      final paid = _paidBy(r, closeOn);
      return ClosureResult(
        rule: rule,
        payable: p + interest - paid,
        interest: interest,
        alreadyPaid: paid,
        rateUsed: rate,
      );
    case Scheme.rd:
      if (m < 36) return notYet(36);
      final value = rupees(rdValue(i.amount, rdMonthlyFactor(sbRate), m));
      final deposits = i.amount * Decimal.fromInt(m);
      return ClosureResult(
        rule: ClosureRule.rdSbRate,
        payable: value,
        interest: value - deposits,
        rateUsed: sbRate,
      );
    case Scheme.mis:
      if (m < 12) return notYet(12);
      final pct = Decimal.fromInt(m < 36 ? 2 : 1);
      final ded = rupees(percentOf(p, pct));
      return ClosureResult(
        rule: ClosureRule.misDeduct,
        payable: p - ded,
        deduction: ded,
        alreadyPaid: _paidBy(r, closeOn),
      );
    case Scheme.scss:
      final paid = _paidBy(r, closeOn);
      if (m < 12) {
        return ClosureResult(
          rule: ClosureRule.scssRecover,
          payable: p - paid,
          deduction: paid,
          alreadyPaid: paid,
        );
      }
      final pct = m < 24 ? Decimal.parse('1.5') : Decimal.one;
      final ded = rupees(percentOf(p, pct));
      return ClosureResult(
        rule: ClosureRule.scssDeduct,
        payable: p - ded,
        deduction: ded,
        alreadyPaid: paid,
      );
    case Scheme.kvp:
      if (m < 30) return notYet(30);
      // Estimate: compounded yearly, counted in completed half-years.
      final half = nthRoot(Decimal.one + div(i.rate, kHundred), 2);
      final value = rupees(p * pw(half, m ~/ 6));
      return ClosureResult(
        rule: ClosureRule.kvpTable,
        payable: value,
        interest: value - p,
        rateUsed: i.rate,
      );
    case Scheme.mssc:
      if (m < 6) return notYet(6);
      final rate = i.rate - two;
      final value = rupees(p * pw(Decimal.one + div(rate, k400), m ~/ 3));
      return ClosureResult(
        rule: ClosureRule.msscMinus2,
        payable: value,
        interest: value - p,
        rateUsed: rate,
      );
  }
}

/// One way to continue an account after maturity.
class ExtensionOption {
  const ExtensionOption(this.kind, this.result);
  final ExtensionKind kind;
  final CalcResult result;
}

enum ExtensionKind { ppfWithDeposits, ppfWithoutDeposits, scss3Years, rd5Years }

/// Extension options for [r]. [currentRate] is today's rate for the scheme
/// (SCSS extensions take the rate on the maturity date).
List<ExtensionOption> extensions(CalcResult r, Decimal currentRate) {
  final i = r.input;
  switch (r.scheme) {
    case Scheme.ppf:
      return [
        ExtensionOption(
          ExtensionKind.ppfWithDeposits,
          ppfProjection(i, years: 20, depositYears: 20),
        ),
        ExtensionOption(
          ExtensionKind.ppfWithoutDeposits,
          ppfProjection(i, years: 20, depositYears: 15),
        ),
      ];
    case Scheme.scss:
      return [
        ExtensionOption(
          ExtensionKind.scss3Years,
          scssExtension(r, currentRate),
        ),
      ];
    case Scheme.rd:
      return [ExtensionOption(ExtensionKind.rd5Years, rdExtended(i))];
    default:
      return const [];
  }
}

/// A withdrawal allowed in an account year.
class WithdrawalLimit {
  const WithdrawalLimit(this.year, this.limit);
  final int year;
  final Decimal limit;
}

/// PPF partial withdrawal: once a year from the 7th year, up to 50% of the
/// lower of the balance at the end of the 4th preceding year or of the
/// preceding year.
List<WithdrawalLimit> ppfWithdrawals(CalcResult r) {
  final b = r.schedule;
  final half = Decimal.parse('0.5');
  return [
    for (var y = 7; y <= b.length; y++)
      WithdrawalLimit(
        y,
        rupeesDown(
          (b[y - 5].balance < b[y - 2].balance
                  ? b[y - 5].balance
                  : b[y - 2].balance) *
              half,
        ),
      ),
  ];
}

/// SSY: up to 50% of the balance at the end of the preceding year, once the
/// girl turns 18 (or passes 10th standard). [girlAge] is her age at opening.
WithdrawalLimit? ssyWithdrawal(CalcResult r, int girlAge) {
  final year = 18 - girlAge + 1; // first account year after she turns 18
  if (year < 2 || year > r.schedule.length) return null;
  return WithdrawalLimit(
    year,
    rupeesDown(r.schedule[year - 2].balance * Decimal.parse('0.5')),
  );
}

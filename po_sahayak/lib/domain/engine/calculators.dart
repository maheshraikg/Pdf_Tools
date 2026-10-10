/// One calculator per scheme, following the rules table in PLAN.md.
library;

import 'dart:math' as math;

import 'package:decimal/decimal.dart';

import '../models/result.dart';
import '../models/scheme.dart';
import 'dates.dart';
import 'money.dart';

CalcResult calculate(CalcInput input) => switch (input.scheme) {
  Scheme.sb => _sb(input),
  Scheme.rd => _rd(input),
  Scheme.td1 || Scheme.td2 || Scheme.td3 || Scheme.td5 => _td(input),
  Scheme.mis => _payout(input, months: 1),
  Scheme.scss => _payout(input, months: 3),
  Scheme.nsc => _nsc(input),
  Scheme.kvp => _kvp(input),
  Scheme.ppf => _ppf(input),
  Scheme.ssy => _ssy(input),
  Scheme.mssc => _mssc(input),
};

/// TD term in years.
int tdYears(Scheme s) => s.tenureMonths ~/ 12;

/// TD yearly interest: compounded quarterly, paid yearly,
/// `P × ((1 + r/400)^4 − 1)`, rounded to the rupee.
Decimal tdYearlyInterest(Decimal p, Decimal rate) =>
    rupees(p * (pw(Decimal.one + div(rate, k400), 4) - Decimal.one));

/// Monthly growth factor for RD: the cube root of the quarterly factor.
Decimal rdMonthlyFactor(Decimal rate) =>
    nthRoot(Decimal.one + div(rate, k400), 3);

/// Value at the end of month [m] of [m] monthly instalments of [r] paid at the
/// start of each month, compounded quarterly: `R·q·(q^m − 1)/(q − 1)`.
Decimal rdValue(Decimal r, Decimal q, int m) =>
    div(r * q * (pw(q, m) - Decimal.one), q - Decimal.one);

/// KVP doubling period in months at [rate] (115 at 7.5%).
int kvpMonths(Decimal rate) {
  final years = math.log(2) / math.log(1 + rate.toDouble() / 100);
  return (years * 12).round();
}

/// PPF maturity: after 15 full financial years counted from the end of the
/// financial year of opening.
DateTime ppfMaturity(DateTime opening) =>
    DateTime(fyStartYear(opening) + 1 + 15, 4, 1);

CalcResult _sb(CalcInput i) {
  final interest = rupees(percentOf(i.amount, i.rate));
  final end = addMonths(i.opening, 12);
  return CalcResult(
    input: i,
    maturityDate: end,
    totalDeposit: i.amount,
    totalInterest: interest,
    schedule: [
      ScheduleRow(
        year: 1,
        date: end,
        deposit: i.amount,
        interest: interest,
        balance: i.amount + interest,
      ),
    ],
  );
}

CalcResult _td(CalcInput i) {
  final years = tdYears(i.scheme);
  final yearly = tdYearlyInterest(i.amount, i.rate);
  final rows = <ScheduleRow>[];
  final events = <InterestEvent>[];
  for (var y = 1; y <= years; y++) {
    final date = addMonths(i.opening, 12 * y);
    rows.add(
      ScheduleRow(
        year: y,
        date: date,
        deposit: y == 1 ? i.amount : Decimal.zero,
        interest: yearly,
        balance: i.amount,
      ),
    );
    events.add(InterestEvent(date, yearly));
  }
  return CalcResult(
    input: i,
    maturityDate: addMonths(i.opening, i.scheme.tenureMonths),
    totalDeposit: i.amount,
    totalInterest: yearly * Decimal.fromInt(years),
    schedule: rows,
    periodicPayout: yearly,
    interestEvents: events,
  );
}

CalcResult _rd(CalcInput i, {int months = 60}) {
  final q = rdMonthlyFactor(i.rate);
  final rows = <ScheduleRow>[];
  final events = <InterestEvent>[];
  var prevValue = Decimal.zero;
  for (var y = 1; y <= months ~/ 12; y++) {
    final value = rupees(rdValue(i.amount, q, 12 * y));
    final deposit = i.amount * Decimal.fromInt(12);
    rows.add(
      ScheduleRow(
        year: y,
        date: addMonths(i.opening, 12 * y),
        deposit: deposit,
        interest: value - prevValue - deposit,
        balance: value,
      ),
    );
    prevValue = value;
  }
  // Interest is credited each quarter.
  var prev = Decimal.zero;
  for (var k = 1; k <= months ~/ 3; k++) {
    final accrued =
        rupees(rdValue(i.amount, q, 3 * k)) - i.amount * Decimal.fromInt(3 * k);
    events.add(InterestEvent(addMonths(i.opening, 3 * k), accrued - prev));
    prev = accrued;
  }
  final total = i.amount * Decimal.fromInt(months);
  return CalcResult(
    input: i,
    maturityDate: addMonths(i.opening, months),
    totalDeposit: total,
    totalInterest: prevValue - total,
    schedule: rows,
    interestEvents: events,
  );
}

/// RD continued for a further 5 years (120 instalments in all).
CalcResult rdExtended(CalcInput i) => _rd(i, months: 120);

/// MIS (monthly) and SCSS (quarterly): simple interest paid every [months].
CalcResult _payout(CalcInput i, {required int months}) {
  final perYear = 12 ~/ months;
  final each = rupees(
    div(i.amount * i.rate, kHundred * Decimal.fromInt(perYear)),
  );
  final tenure = i.scheme.tenureMonths;
  final events = <InterestEvent>[
    for (var k = 1; k <= tenure ~/ months; k++)
      InterestEvent(addMonths(i.opening, k * months), each),
  ];
  final rows = <ScheduleRow>[
    for (var y = 1; y <= tenure ~/ 12; y++)
      ScheduleRow(
        year: y,
        date: addMonths(i.opening, 12 * y),
        deposit: y == 1 ? i.amount : Decimal.zero,
        interest: each * Decimal.fromInt(perYear),
        balance: i.amount,
      ),
  ];
  return CalcResult(
    input: i,
    maturityDate: addMonths(i.opening, tenure),
    totalDeposit: i.amount,
    totalInterest: each * Decimal.fromInt(events.length),
    schedule: rows,
    periodicPayout: each,
    interestEvents: events,
  );
}

/// SCSS extended for one 3-year block at [rate] (the rate on the maturity
/// date), simple interest paid quarterly.
CalcResult scssExtension(CalcResult r, Decimal rate) {
  final start = r.maturityDate;
  final each = rupees(div(r.totalDeposit * rate, k400));
  final events = [
    for (var k = 1; k <= 12; k++) InterestEvent(addMonths(start, 3 * k), each),
  ];
  return CalcResult(
    input: CalcInput(
      scheme: Scheme.scss,
      amount: r.totalDeposit,
      opening: start,
      rate: rate,
    ),
    maturityDate: addMonths(start, 36),
    totalDeposit: r.totalDeposit,
    totalInterest: each * Decimal.fromInt(12),
    schedule: [
      for (var y = 1; y <= 3; y++)
        ScheduleRow(
          year: y,
          date: addMonths(start, 12 * y),
          deposit: Decimal.zero,
          interest: each * Decimal.fromInt(4),
          balance: r.totalDeposit,
        ),
    ],
    periodicPayout: each,
    interestEvents: events,
  );
}

/// Balances compounded yearly for [years] full years, rounded per year.
List<ScheduleRow> _yearlyCompound(CalcInput i, int years) {
  final f = Decimal.one + div(i.rate, kHundred);
  final rows = <ScheduleRow>[];
  var prev = i.amount;
  for (var y = 1; y <= years; y++) {
    final bal = rupees(i.amount * pw(f, y));
    rows.add(
      ScheduleRow(
        year: y,
        date: addMonths(i.opening, 12 * y),
        deposit: y == 1 ? i.amount : Decimal.zero,
        interest: bal - prev,
        balance: bal,
      ),
    );
    prev = bal;
  }
  return rows;
}

CalcResult _nsc(CalcInput i) {
  final rows = _yearlyCompound(i, 5);
  return CalcResult(
    input: i,
    maturityDate: addMonths(i.opening, 60),
    totalDeposit: i.amount,
    totalInterest: rows.last.balance - i.amount,
    schedule: rows,
    // Accrued interest is taxable (years 1–4 count as reinvested for 80C).
    interestEvents: [for (final r in rows) InterestEvent(r.date, r.interest)],
  );
}

CalcResult _kvp(CalcInput i) {
  final months = kvpMonths(i.rate);
  final maturity = addMonths(i.opening, months);
  final rows = _yearlyCompound(i, months ~/ 12);
  final doubled = i.amount * Decimal.fromInt(2);
  rows.add(
    ScheduleRow(
      year: rows.length + 1,
      date: maturity,
      deposit: Decimal.zero,
      interest: doubled - (rows.isEmpty ? i.amount : rows.last.balance),
      balance: doubled,
    ),
  );
  return CalcResult(
    input: i,
    maturityDate: maturity,
    totalDeposit: i.amount,
    totalInterest: i.amount,
    schedule: rows,
  );
}

/// Yearly deposit [i.amount] made by the 5th of April for [depositYears],
/// interest compounded yearly for [years], rounded to the rupee each year.
List<ScheduleRow> _yearlyDeposits(
  CalcInput i, {
  required int years,
  required int depositYears,
  required DateTime Function(int year) dateOf,
}) {
  final rows = <ScheduleRow>[];
  var bal = Decimal.zero;
  for (var y = 1; y <= years; y++) {
    final dep = y <= depositYears ? i.amount : Decimal.zero;
    final interest = rupees(percentOf(bal + dep, i.rate));
    bal = bal + dep + interest;
    rows.add(
      ScheduleRow(
        year: y,
        date: dateOf(y),
        deposit: dep,
        interest: interest,
        balance: bal,
      ),
    );
  }
  return rows;
}

CalcResult _ppf(CalcInput i) => ppfProjection(i, years: 15, depositYears: 15);

/// PPF over [years] (15, or 20/25 with extensions), with deposits in the
/// first [depositYears].
CalcResult ppfProjection(
  CalcInput i, {
  required int years,
  required int depositYears,
}) {
  final fy = fyStartYear(i.opening);
  final rows = _yearlyDeposits(
    i,
    years: years,
    depositYears: depositYears,
    dateOf: (y) => DateTime(fy + y, 3, 31),
  );
  final deposits = rows.fold(Decimal.zero, (a, r) => a + r.deposit);
  return CalcResult(
    input: i,
    maturityDate: DateTime(fy + 1 + years, 4, 1),
    totalDeposit: deposits,
    totalInterest: rows.last.balance - deposits,
    schedule: rows,
  );
}

CalcResult _ssy(CalcInput i) {
  final rows = _yearlyDeposits(
    i,
    years: 21,
    depositYears: 15,
    dateOf: (y) => addMonths(i.opening, 12 * y),
  );
  final deposits = i.amount * Decimal.fromInt(15);
  return CalcResult(
    input: i,
    maturityDate: addMonths(i.opening, 252),
    totalDeposit: deposits,
    totalInterest: rows.last.balance - deposits,
    schedule: rows,
  );
}

CalcResult _mssc(CalcInput i) {
  final f = Decimal.one + div(i.rate, k400);
  final y1 = rupees(i.amount * pw(f, 4));
  final y2 = rupees(i.amount * pw(f, 8));
  return CalcResult(
    input: i,
    maturityDate: addMonths(i.opening, 24),
    totalDeposit: i.amount,
    totalInterest: y2 - i.amount,
    schedule: [
      ScheduleRow(
        year: 1,
        date: addMonths(i.opening, 12),
        deposit: i.amount,
        interest: y1 - i.amount,
        balance: y1,
      ),
      ScheduleRow(
        year: 2,
        date: addMonths(i.opening, 24),
        deposit: Decimal.zero,
        interest: y2 - y1,
        balance: y2,
      ),
    ],
  );
}

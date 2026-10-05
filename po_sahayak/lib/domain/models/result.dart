/// Calculation inputs and results.
library;

import 'package:decimal/decimal.dart';

import '../engine/dates.dart';
import 'scheme.dart';

class CalcInput {
  const CalcInput({
    required this.scheme,
    required this.amount,
    required this.opening,
    required this.rate,
    this.rateFrom,
  });

  final Scheme scheme;

  /// Deposit, instalment, yearly deposit or balance (see [AmountKind]).
  final Decimal amount;
  final DateTime opening;

  /// % p.a.
  final Decimal rate;

  /// When [rate] took effect (null if typed by the user).
  final DateTime? rateFrom;
}

/// One row of the year-wise table.
class ScheduleRow {
  const ScheduleRow({
    required this.year,
    required this.date,
    required this.deposit,
    required this.interest,
    required this.balance,
  });

  /// 1-based account year.
  final int year;

  /// End of that year.
  final DateTime date;

  /// Deposited during the year.
  final Decimal deposit;

  /// Interest earned during the year (paid out or added).
  final Decimal interest;

  /// Balance at the end of the year (payout schemes: the principal).
  final Decimal balance;
}

/// Interest paid or accrued on [date], for the per-FY tax table.
class InterestEvent {
  const InterestEvent(this.date, this.amount);
  final DateTime date;
  final Decimal amount;
}

class CalcResult {
  CalcResult({
    required this.input,
    required this.maturityDate,
    required this.totalDeposit,
    required this.totalInterest,
    required this.schedule,
    this.periodicPayout,
    this.interestEvents = const [],
  });

  final CalcInput input;
  final DateTime maturityDate;
  final Decimal totalDeposit;
  final Decimal totalInterest;
  final List<ScheduleRow> schedule;

  /// Monthly / quarterly / yearly interest for payout schemes.
  final Decimal? periodicPayout;

  /// Taxable interest events (TD, RD, MIS, SCSS, NSC only).
  final List<InterestEvent> interestEvents;

  Scheme get scheme => input.scheme;

  /// Everything received: deposits back plus all interest.
  Decimal get maturityValue => totalDeposit + totalInterest;

  /// Interest per financial year, oldest first, keyed "2026-27".
  Map<String, Decimal> get interestByFy {
    final out = <int, Decimal>{};
    for (final e in interestEvents) {
      final fy = fyStartYear(e.date);
      out[fy] = (out[fy] ?? Decimal.zero) + e.amount;
    }
    final keys = out.keys.toList()..sort();
    return {for (final k in keys) fyLabel(k): out[k]!};
  }
}

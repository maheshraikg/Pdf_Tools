/// The Post Office small savings schemes and their fixed limits.
library;

import 'package:decimal/decimal.dart';

/// What the amount entered for a scheme means.
enum AmountKind {
  /// Account balance (SB).
  balance,

  /// One-time deposit.
  lumpSum,

  /// Monthly instalment (RD).
  monthly,

  /// Yearly deposit (PPF, SSY).
  yearly,
}

/// How often interest is paid out (null: added to the balance).
enum Payout { monthly, quarterly, yearly }

enum Scheme {
  sb('SB', AmountKind.balance, 12, 500, null, 1),
  rd('RD', AmountKind.monthly, 60, 100, null, 10),
  td1('TD1', AmountKind.lumpSum, 12, 1000, null, 100),
  td2('TD2', AmountKind.lumpSum, 24, 1000, null, 100),
  td3('TD3', AmountKind.lumpSum, 36, 1000, null, 100),
  td5('TD5', AmountKind.lumpSum, 60, 1000, null, 100),
  mis('MIS', AmountKind.lumpSum, 60, 1000, 900000, 1000),
  scss('SCSS', AmountKind.lumpSum, 60, 1000, 3000000, 1000),
  nsc('NSC', AmountKind.lumpSum, 60, 1000, null, 100),
  kvp('KVP', AmountKind.lumpSum, 115, 1000, null, 100),
  ppf('PPF', AmountKind.yearly, 180, 500, 150000, 50),
  ssy('SSY', AmountKind.yearly, 252, 250, 150000, 50),
  mssc('MSSC', AmountKind.lumpSum, 24, 1000, 200000, 100);

  const Scheme(
    this.code,
    this.amountKind,
    this.tenureMonths,
    this.minAmount,
    this.maxAmount,
    this.multipleOf,
  );

  /// Key in rates.json.
  final String code;
  final AmountKind amountKind;

  /// Normal tenure in months (KVP: at the current rate; PPF: approximate,
  /// the real maturity follows the financial-year rule).
  final int tenureMonths;
  final int minAmount;

  /// Upper limit (MIS: single account; PPF/SSY: per financial year).
  final int? maxAmount;
  final int multipleOf;

  /// MIS joint-account limit.
  static const int misJointMax = 1500000;

  /// Last date MSSC accepted deposits.
  static final DateTime msscLastOpening = DateTime(2025, 3, 31);

  /// Rate changes each quarter for existing accounts (otherwise locked at
  /// opening).
  bool get rateFloats => this == sb || this == ppf || this == ssy;

  bool get isTd => this == td1 || this == td2 || this == td3 || this == td5;

  Payout? get payout => switch (this) {
    mis => Payout.monthly,
    scss => Payout.quarterly,
    td1 || td2 || td3 || td5 => Payout.yearly,
    _ => null,
  };

  /// Interest is taxable each year (the result shows interest per FY).
  bool get showsTaxableInterest =>
      isTd || this == rd || this == mis || this == scss || this == nsc;

  /// Schemes on the Compare screen (lump sum over about 5 years).
  static const compared = [td5, nsc, kvp, mis, rd];

  /// Schemes a new account can be opened in (MSSC is closed).
  static List<Scheme> get openable => values.where((s) => s != mssc).toList();

  static Scheme? fromCode(String code) {
    for (final s in values) {
      if (s.code == code) return s;
    }
    return null;
  }

  Decimal get min => Decimal.fromInt(minAmount);
}

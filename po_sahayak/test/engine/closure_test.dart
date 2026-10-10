import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/closure.dart';
import 'package:po_sahayak/domain/models/result.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  final sb = d('4.0');
  final jan26 = DateTime(2026, 1, 1);
  ClosureResult close(CalcResult r, DateTime on, {String? td3}) =>
      prematureClosure(r, on, sbRate: sb, td3Rate: td3 == null ? null : d(td3));

  group('TD', () {
    test('no closure before 6 months', () {
      final r = calc(Scheme.td1, 100000, '6.9', opening: jan26);
      final c = close(r, DateTime(2026, 4, 1));
      expect(c.rule, ClosureRule.notYet);
      expect(c.minMonths, 6);
      expect(c.allowed, isFalse);
    });

    test('6–12 months at SB rate, simple', () {
      final r = calc(Scheme.td1, 100000, '6.9', opening: jan26);
      final c = close(r, DateTime(2026, 9, 1)); // 8 months
      expect(c.rule, ClosureRule.tdSbRate);
      expect(c.interest, d(2667));
      expect(c.payable, d(102667));
    });

    test('after 1 year: TD rate − 2%, less interest already paid', () {
      final r = calc(Scheme.td3, 100000, '7.1', opening: jan26);
      final c = close(r, DateTime(2027, 7, 1)); // 18 months
      expect(c.rule, ClosureRule.tdMinus2);
      expect(c.rateUsed, d('5.1'));
      expect(c.alreadyPaid, d(7291)); // payout on 01-01-2027
      // 6 quarters at 5.1%: 1,00,000 × (1.01275^6 − 1) = 7,898.
      expect(c.interest, d(7898));
      expect(c.payable, d(100000 + 7898 - 7291));
    });

    test(
      '5-year TD opened on/after 09-11-2023: not before 4 years, then SB',
      () {
        final r = calc(Scheme.td5, 100000, '7.5', opening: jan26);
        expect(close(r, DateTime(2028, 1, 1)).rule, ClosureRule.notYet);
        expect(close(r, DateTime(2028, 1, 1)).minMonths, 48);
        final c = close(r, DateTime(2030, 3, 1));
        expect(c.rule, ClosureRule.td5NewSbRate);
        expect(c.rateUsed, sb);
      },
    );

    test('5-year TD opened before 09-11-2023: 3-year rate − 2%', () {
      final r = calc(Scheme.td5, 100000, '7.5', opening: DateTime(2023, 6, 1));
      final c = close(r, DateTime(2025, 6, 1), td3: '7.0');
      expect(c.rule, ClosureRule.td5OldMinus2);
      expect(c.rateUsed, d('5.0'));
    });
  });

  test('RD: only after 3 years, at SB rate', () {
    final r = calc(Scheme.rd, 1000, '6.7', opening: jan26);
    expect(close(r, DateTime(2028, 1, 1)).rule, ClosureRule.notYet);
    final c = close(r, DateTime(2029, 2, 1)); // 37 months
    expect(c.rule, ClosureRule.rdSbRate);
    expect(c.payable! > d(37000), isTrue);
    expect(c.payable! < d(37000 * 1.07), isTrue);
  });

  group('MIS', () {
    final r = calc(Scheme.mis, 900000, '7.4', opening: jan26);
    test('not before 1 year', () {
      expect(close(r, DateTime(2026, 7, 1)).rule, ClosureRule.notYet);
    });
    test('1–3 years: 2% deducted', () {
      final c = close(r, DateTime(2027, 7, 1));
      expect(c.deduction, d(18000));
      expect(c.payable, d(882000));
    });
    test('after 3 years: 1% deducted', () {
      expect(close(r, DateTime(2029, 5, 1)).payable, d(891000));
    });
  });

  group('SCSS', () {
    final r = calc(Scheme.scss, 3000000, '8.2', opening: jan26);
    test('before 1 year: interest paid is recovered', () {
      final c = close(r, DateTime(2026, 7, 15)); // 2 payouts made
      expect(c.rule, ClosureRule.scssRecover);
      expect(c.payable, d(3000000 - 2 * 61500));
    });
    test('1–2 years: 1.5%; after 2 years: 1%', () {
      expect(close(r, DateTime(2027, 7, 1)).payable, d(2955000));
      expect(close(r, DateTime(2028, 7, 1)).payable, d(2970000));
    });
  });

  test('NSC: not allowed; PPF/SSY: withdrawal rules', () {
    expect(
      close(calc(Scheme.nsc, 1000, '7.7'), DateTime(2028, 1, 1)).rule,
      ClosureRule.notAllowed,
    );
    expect(
      close(calc(Scheme.ppf, 1000, '7.1'), DateTime(2030, 1, 1)).rule,
      ClosureRule.useWithdrawal,
    );
  });

  test('KVP: matches the official 7.2% and 6.9% encashment tables', () {
    // Per ₹1,000 after 2½, 3, 3½ and 4 years (G.S.R. 52(E), 2023).
    final r72 = calc(Scheme.kvp, 1000, '7.2', opening: jan26);
    expect(close(r72, DateTime(2028, 1, 1)).rule, ClosureRule.notYet);
    expect(close(r72, DateTime(2028, 7, 1)).payable, d(1162)); // 2½ years
    expect(close(r72, DateTime(2029, 1, 1)).payable, d(1198)); // 3 years
    expect(close(r72, DateTime(2029, 7, 1)).payable, d(1234)); // 3½ years
    expect(close(r72, DateTime(2030, 1, 1)).payable, d(1272)); // 4 years
    // 6.9% certificates (2020–2022): 1154 and 1188.
    final r69 = calc(Scheme.kvp, 1000, '6.9', opening: jan26);
    expect(close(r69, DateTime(2028, 7, 1)).payable, d(1154));
    expect(close(r69, DateTime(2029, 1, 1)).payable, d(1188));
    // Larger amounts scale the per-₹1,000 value.
    final big = calc(Scheme.kvp, 100000, '7.2', opening: jan26);
    final c = close(big, DateTime(2029, 1, 1));
    expect(c.rule, ClosureRule.kvpTable);
    expect(c.payable, d(119800));
  });

  test('on or after maturity: full value', () {
    final r = calc(Scheme.nsc, 1000, '7.7', opening: jan26);
    final c = close(r, DateTime(2031, 1, 1));
    expect(c.rule, ClosureRule.afterMaturity);
    expect(c.payable, r.maturityValue);
  });
}

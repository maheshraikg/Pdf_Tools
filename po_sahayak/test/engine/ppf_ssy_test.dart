import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/engine/closure.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  group('PPF', () {
    test('₹1,50,000 a year for 15 years at 7.1% → about ₹40,68,209', () {
      final r = calc(Scheme.ppf, 150000, '7.1');
      expect(
        (r.maturityValue - d(4068209)).abs() <= d(2),
        isTrue,
        reason: 'got ${r.maturityValue}',
      );
      expect(r.totalDeposit, d(2250000));
    });

    test('matures after 15 full FYs from the end of the opening FY', () {
      // Opened in FY 2026-27 → FY ends 31-03-2027 → matures 01-04-2042,
      // not 10-10-2041.
      expect(ppfMaturity(DateTime(2026, 10, 10)), DateTime(2042, 4, 1));
      expect(ppfMaturity(DateTime(2027, 3, 31)), DateTime(2042, 4, 1));
      expect(ppfMaturity(DateTime(2027, 4, 1)), DateTime(2043, 4, 1));
      expect(calc(Scheme.ppf, 1000, '7.1').maturityDate, DateTime(2042, 4, 1));
    });

    test('extension with and without deposits', () {
      final r = calc(Scheme.ppf, 100000, '7.1');
      final opts = extensions(r, d('7.1'));
      final withDep = opts.firstWhere(
        (o) => o.kind == ExtensionKind.ppfWithDeposits,
      );
      final without = opts.firstWhere(
        (o) => o.kind == ExtensionKind.ppfWithoutDeposits,
      );
      expect(withDep.result.totalDeposit, d(2000000));
      expect(without.result.totalDeposit, d(1500000));
      expect(withDep.result.maturityDate, DateTime(2047, 4, 1));
      expect(without.result.maturityValue > r.maturityValue, isTrue);
    });

    test('partial withdrawal from year 7: 50% of the lower balance', () {
      final r = calc(Scheme.ppf, 100000, '7.1');
      final w = ppfWithdrawals(r);
      expect(w.first.year, 7);
      // Balance at end of year 3 (4th preceding year) is lower than year 6.
      expect(w.first.limit, (r.schedule[2].balance * d('0.5')).floor());
    });
  });

  group('SSY', () {
    test('deposits for 15 years, matures at 21 years', () {
      final r = calc(Scheme.ssy, 150000, '8.2');
      expect(r.totalDeposit, d(150000 * 15));
      expect(r.maturityDate, DateTime(2047, 10, 10));
      expect(r.schedule, hasLength(21));
      expect(r.schedule[15].deposit, d(0));
      // Years 16–21 only earn interest.
      final y16 = r.schedule[15];
      expect(y16.interest, (r.schedule[14].balance * d('0.082')).round());
    });

    test('50% withdrawal after the girl turns 18', () {
      final r = calc(Scheme.ssy, 10000, '8.2');
      final w = ssyWithdrawal(r, 5)!;
      expect(w.year, 14);
      expect(w.limit, (r.schedule[12].balance * d('0.5')).floor());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/engine/money.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  group('Recurring Deposit', () {
    test('₹10,000/month at 6.7% → about ₹7,13,659 (PLAN.md)', () {
      final r = calc(Scheme.rd, 10000, '6.7');
      // Formula value is ₹7,13,658.29; PLAN.md says "about ₹7,13,659".
      expect(
        (r.maturityValue - d(713659)).abs() <= d(2),
        isTrue,
        reason: 'got ${r.maturityValue}',
      );
      expect(r.totalDeposit, d(600000));
      expect(r.maturityDate, DateTime(2031, 10, 10));
    });

    test('monthly factor cubed equals the quarterly factor', () {
      final q = rdMonthlyFactor(d('6.7'));
      final cube = pw(q, 3);
      expect((cube - d('1.01675')).abs() < d('1e-20'), isTrue);
    });

    test('year-wise table adds up', () {
      final r = calc(Scheme.rd, 500, '6.7');
      final interest = r.schedule.fold(d(0), (a, row) => a + row.interest);
      expect(interest, r.totalInterest);
      expect(r.schedule.last.balance, r.maturityValue);
    });

    test('quarterly interest events add up to the total', () {
      final r = calc(Scheme.rd, 10000, '6.7');
      expect(r.interestEvents, hasLength(20));
      final sum = r.interestEvents.fold(d(0), (a, e) => a + e.amount);
      expect(sum, r.totalInterest);
    });

    test('5-year extension continues to 120 instalments', () {
      final r = rdExtended(calc(Scheme.rd, 1000, '6.7').input);
      expect(r.totalDeposit, d(120000));
      expect(r.maturityValue > d(120000), isTrue);
    });
  });
}

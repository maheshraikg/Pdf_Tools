import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  group('NSC', () {
    test('₹1,000 at 7.7% → about ₹1,449 (PLAN.md)', () {
      final r = calc(Scheme.nsc, 1000, '7.7');
      expect(r.maturityValue, d(1449));
      expect(r.maturityDate, DateTime(2031, 10, 10));
    });

    test('₹1,00,000 at 7.7% → ₹1,44,903, accrued yearly', () {
      final r = calc(Scheme.nsc, 100000, '7.7');
      expect(r.maturityValue, d(144903));
      expect(r.schedule.first.interest, d(7700));
      final sum = r.interestEvents.fold(d(0), (a, e) => a + e.amount);
      expect(sum, r.totalInterest);
    });
  });

  group('KVP', () {
    test('doubles in 115 months at 7.5%', () {
      expect(kvpMonths(d('7.5')), 115);
      final r = calc(Scheme.kvp, 100000, '7.5');
      expect(r.maturityValue, d(200000));
      expect(r.maturityDate, DateTime(2036, 5, 10));
    });
  });

  group('MSSC', () {
    test('₹2,00,000 at 7.5% → ₹2,32,044 in 2 years', () {
      final r = calc(
        Scheme.mssc,
        200000,
        '7.5',
        opening: DateTime(2025, 3, 31),
      );
      expect(r.maturityValue, d(232044));
      expect(r.maturityDate, DateTime(2027, 3, 31));
    });
  });

  group('SB', () {
    test('₹10,000 at 4% earns ₹400 a year', () {
      expect(calc(Scheme.sb, 10000, '4.0').totalInterest, d(400));
    });
  });
}

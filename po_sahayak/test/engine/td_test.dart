import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  group('Time Deposit', () {
    test('5-year TD ₹1,00,000 at 7.5% pays ₹7,714 a year (PLAN.md)', () {
      final r = calc(Scheme.td5, 100000, '7.5');
      expect(r.periodicPayout, d(7714));
      expect(r.totalInterest, d(7714 * 5));
      expect(r.maturityValue, d(100000 + 7714 * 5));
      expect(r.maturityDate, DateTime(2031, 10, 10));
      expect(r.schedule, hasLength(5));
    });

    test('1, 2 and 3-year yearly interest', () {
      expect(calc(Scheme.td1, 100000, '6.9').periodicPayout, d(7081));
      expect(calc(Scheme.td2, 100000, '7.0').periodicPayout, d(7186));
      expect(calc(Scheme.td3, 100000, '7.1').periodicPayout, d(7291));
    });

    test('interest is grouped by financial year (Apr–Mar)', () {
      final r = calc(Scheme.td2, 100000, '7.0', opening: DateTime(2026, 3, 15));
      // Payouts on 15-03-2027 (FY 2026-27) and 15-03-2028 (FY 2027-28).
      expect(r.interestByFy, {'2026-27': d(7186), '2027-28': d(7186)});
    });
  });
}

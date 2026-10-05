import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/calculators.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  test('MIS ₹9,00,000 at 7.4% pays ₹5,550 a month', () {
    final r = calc(Scheme.mis, 900000, '7.4');
    expect(r.periodicPayout, d(5550));
    expect(r.interestEvents, hasLength(60));
    expect(r.totalInterest, d(5550 * 60));
    expect(r.maturityValue, d(900000 + 5550 * 60));
  });

  test('MIS joint ₹15,00,000 at 7.4% pays ₹9,250 a month', () {
    expect(calc(Scheme.mis, 1500000, '7.4').periodicPayout, d(9250));
  });

  test('SCSS ₹30,00,000 at 8.2% pays ₹61,500 a quarter', () {
    final r = calc(Scheme.scss, 3000000, '8.2');
    expect(r.periodicPayout, d(61500));
    expect(r.interestEvents, hasLength(20));
    expect(r.totalInterest, d(61500 * 20));
    expect(r.maturityDate, DateTime(2031, 10, 10));
  });

  test('SCSS 3-year extension uses the rate on the maturity date', () {
    final r = calc(Scheme.scss, 1000000, '8.2');
    final ext = scssExtension(r, d('7.4'));
    expect(ext.input.opening, r.maturityDate);
    expect(ext.periodicPayout, d(18500));
    expect(ext.maturityDate, DateTime(2034, 10, 10));
  });
}

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/data/local_rates.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/domain/rates/rate_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/helpers.dart';

RateRepository table(String validFrom) => RateRepository.fromJson('''
{"version": "x", "validFrom": "$validFrom",
 "schemes": {"TD5": [{"from": "$validFrom", "rate": 7.5}],
             "PPF": [{"from": "$validFrom", "rate": 7.1}]}}''');

void main() {
  test('typed rates apply from their date and survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final bundled = loadRates();
    final local = await LocalRates.load(bundled);
    final from = DateTime(
      bundled.validFrom.year,
      bundled.validFrom.month + 3,
      1,
    );
    await local.save(from, {Scheme.td5: Decimal.parse('7.6')});
    final repo = local.repo;
    expect(repo.local, isTrue);
    expect(repo.current(Scheme.td5).rate, Decimal.parse('7.6'));
    expect(repo.entryOn(Scheme.td5, from)!.rate, Decimal.parse('7.6'));
    // Accounts opened before the new quarter keep the old rate.
    final before = from.subtract(const Duration(days: 1));
    expect(repo.entryOn(Scheme.td5, before)!.rate, Decimal.parse('7.5'));
    // Schemes not typed in keep the built-in rate.
    expect(repo.current(Scheme.ppf).rate, Decimal.parse('7.1'));

    final again = await LocalRates.load(bundled);
    expect(again.repo.current(Scheme.td5).rate, Decimal.parse('7.6'));
    await again.clear();
    expect(again.repo.local, isFalse);
  });

  test('an app update with official rates replaces typed ones', () async {
    SharedPreferences.setMockInitialValues({});
    final local = await LocalRates.load(table('2027-01-01'));
    await local.save(DateTime(2027, 1, 1), {Scheme.td5: Decimal.parse('9')});
    expect(local.repo.local, isFalse);
    expect(local.repo.current(Scheme.td5).rate, Decimal.parse('7.5'));
  });
}

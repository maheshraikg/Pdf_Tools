import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/domain/engine/dates.dart';
import 'package:po_sahayak/domain/engine/eligibility.dart';
import 'package:po_sahayak/domain/models/scheme.dart';

import 'helpers.dart';

void main() {
  group('rates.json', () {
    final rates = loadRates();

    test('has every scheme with the Q3 FY 2026-27 rates', () {
      expect(rates.version, '2026-Q3');
      final expected = {
        Scheme.sb: '4',
        Scheme.rd: '6.7',
        Scheme.td1: '6.9',
        Scheme.td2: '7',
        Scheme.td3: '7.1',
        Scheme.td5: '7.5',
        Scheme.mis: '7.4',
        Scheme.scss: '8.2',
        Scheme.nsc: '7.7',
        Scheme.kvp: '7.5',
        Scheme.ppf: '7.1',
        Scheme.ssy: '8.2',
        Scheme.mssc: '7.5',
      };
      for (final e in expected.entries) {
        expect(rates.current(e.key).rate, d(e.value), reason: e.key.code);
      }
    });

    test('no rate before the first entry (history is entered by hand)', () {
      expect(rates.entryOn(Scheme.td5, DateTime(2019, 1, 1)), isNull);
      expect(rates.rateFor(Scheme.td5, DateTime(2019, 1, 1)), isNull);
      // Floating-rate schemes always project at today's rate.
      expect(rates.rateFor(Scheme.ppf, DateTime(2019, 1, 1)), isNotNull);
    });
  });

  group('dates', () {
    test('addMonths clamps to month end', () {
      expect(addMonths(DateTime(2024, 1, 31), 1), DateTime(2024, 2, 29));
      expect(addMonths(DateTime(2026, 10, 10), 115), DateTime(2036, 5, 10));
    });
    test('monthsBetween counts completed months', () {
      expect(monthsBetween(DateTime(2026, 1, 15), DateTime(2026, 7, 14)), 5);
      expect(monthsBetween(DateTime(2026, 1, 15), DateTime(2026, 7, 15)), 6);
    });
    test('financial year labels', () {
      expect(fyLabel(fyStartYear(DateTime(2027, 3, 31))), '2026-27');
      expect(fyLabel(fyStartYear(DateTime(2099, 4, 1))), '2099-00');
    });
  });

  group('eligibility', () {
    List<Issue> check(
      Scheme s,
      int amount, {
      int? age,
      Holding h = Holding.single,
      DateTime? opening,
    }) => checkEligibility(
      EligibilityInput(
        scheme: s,
        amount: d(amount),
        age: age,
        holding: h,
        opening: opening ?? DateTime(2026, 10, 5),
      ),
    );

    test('limits and multiples', () {
      expect(check(Scheme.td5, 500), [Issue.belowMin]);
      expect(check(Scheme.td5, 1050), [Issue.notMultiple]);
      expect(check(Scheme.mis, 1000000), [Issue.aboveMax]);
      expect(check(Scheme.mis, 1000000, h: Holding.joint), isEmpty);
      expect(check(Scheme.ppf, 160000), [Issue.aboveMax]);
    });
    test('SCSS age', () {
      expect(check(Scheme.scss, 100000, age: 45), contains(Issue.scssAge));
      expect(
        check(Scheme.scss, 100000, age: 57),
        contains(Issue.scssEarlyRetiree),
      );
      expect(check(Scheme.scss, 100000, age: 62), isEmpty);
      expect(
        check(Scheme.scss, 100000, age: 62, h: Holding.minor),
        contains(Issue.noMinor),
      );
    });
    test('SSY girl below 10, no joint', () {
      expect(check(Scheme.ssy, 1000, age: 11), [Issue.ssyGirlAge]);
      expect(check(Scheme.ssy, 1000, age: 4), isEmpty);
      expect(check(Scheme.ppf, 1000, h: Holding.joint), [Issue.noJoint]);
    });
    test('MSSC closed after 31-03-2025', () {
      expect(check(Scheme.mssc, 10000), contains(Issue.msscClosed));
      expect(check(Scheme.mssc, 10000, opening: DateTime(2025, 3, 1)), isEmpty);
    });
    test('documents', () {
      final ssy = documentsFor(Scheme.ssy);
      expect(ssy, containsAll([Doc.birthCert, Doc.guardianKyc]));
      expect(documentsFor(Scheme.scss), contains(Doc.ageProof));
      expect(
        documentsFor(Scheme.td1, h: Holding.joint),
        contains(Doc.jointKyc),
      );
    });
  });
}

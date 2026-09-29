import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/directory_builder.dart';
import 'package:sorting_sahayak/data/directory_repo.dart';
import 'package:sorting_sahayak/data/mismatch.dart';

import 'helpers/fixture.dart';

void main() {
  group('CSV cleaning', () {
    test('detects columns in both data.gov.in layouts', () {
      final a = detectDirectoryColumns(['circlename', 'regionname', 'divisionname', 'officename', 'pincode', 'officetype', 'delivery', 'district', 'statename', 'latitude', 'longitude']);
      expect(a['office'], 3);
      expect(a['pincode'], 4);
      expect(a['longitude'], 10);
      final b = detectDirectoryColumns(['officename', 'pincode', 'officeType', 'Deliverystatus', 'divisionname', 'regionname', 'circlename', 'Taluk', 'Districtname', 'statename']);
      expect(b['delivery'], 3);
      expect(b['taluk'], 7);
      expect(b['district'], 8);
      expect(() => detectDirectoryColumns(['foo', 'bar']), throwsFormatException);
    });

    test('splits office type suffixes and title-cases', () {
      expect(splitOfficeType('Puttur S.O'), ('Puttur', 'SO'));
      expect(splitOfficeType('Darbe B.O'), ('Darbe', 'BO'));
      expect(splitOfficeType('Mangalore H.O'), ('Mangalore', 'HO'));
      expect(splitOfficeType('Bangalore G.P.O.'), ('Bangalore', 'HO'));
      expect(splitOfficeType('Kaso'), ('Kaso', ''));
      expect(titleCase('DAKSHINA  KANNADA'), 'Dakshina Kannada');
      expect(titleCase('N.I.T.K surathkal'), 'N.I.T.K Surathkal');
    });

    test('dedupes, normalises NA coordinates and filters by state', () {
      final csv = File('test/fixtures/directory.csv').readAsStringSync();
      final all = parseDirectoryCsv(csv);
      expect(all.length, 27); // one exact duplicate dropped
      final darbe = all.firstWhere((r) => r.officeName == 'Darbe');
      expect(darbe.latitude, isNull);
      expect(darbe.officeType, 'BO');
      expect(darbe.district, 'Dakshina Kannada');
      expect(darbe.state, 'Karnataka');
      final ka = parseDirectoryCsv(csv, stateFilter: 'karnataka');
      expect(ka.every((r) => r.state == 'Karnataka'), isTrue);
      expect(ka.length, 21);
    });
  });

  for (final fts in [true, false]) {
    group('search (${fts ? 'FTS5' : 'LIKE fallback'})', () {
      late DirectoryRepo repo;
      setUpAll(() async => repo = await fixtureRepo(fts: fts));

      test('lookup by PIN', () async {
        final o = await repo.officesForPin(574201);
        expect(o.single.officeName, 'Puttur');
        expect(o.single.officeType, 'SO');
        expect(await repo.officesForPin(999999), isEmpty);
      });

      test('prefix summary', () async {
        final s = await repo.prefixSummary('574');
        expect(s.districts, containsAll(['Dakshina Kannada', 'Udupi']));
        expect(s.states, ['Karnataka']);
      });

      test('spelling variants and scripts all find Puttur', () async {
        for (final q in ['Puttur', 'puttoor', 'Putur', 'ಪುತ್ತೂರು', 'पुत्तूर', 'PUTTUR S.O', 'putt']) {
          final hits = await repo.search(q);
          expect(hits.map((h) => h.office.pincode), contains(574201), reason: q);
          expect(hits.first.office.officeName, 'Puttur', reason: q);
        }
      });

      test('filters', () async {
        final kerala = await repo.search('Puttur', filter: const SearchFilter(state: 'Kerala'));
        expect(kerala.map((h) => h.office.pincode).toSet(), {671543});
        final udupi = await repo.search('Puttur', filter: const SearchFilter(district: 'Udupi'));
        expect(udupi.single.office.pincode, 576105);
        final deliv = await repo.search('Kodialbail', filter: const SearchFilter(deliveryOnly: true));
        expect(deliv.where((h) => h.office.officeName == 'Kodialbail'), isEmpty);
      });

      test('aliases, districts and multi-word names', () async {
        final b = await repo.search('Bengaluru');
        expect(b.map((h) => h.office.pincode), contains(560001));
        final m = await repo.search('Mysuru');
        expect(m.first.office.pincode, 570001);
        final d = await repo.search('Udupi');
        expect(d.map((h) => h.office.pincode), containsAll([576101, 576104]));
        final nd = await repo.search('new delhi');
        expect(nd.first.office.pincode, 110001);
        final pin = await repo.search('575001');
        expect(pin.single.office.officeName, 'Mangalore');
      });

      test('states, districts, meta', () async {
        expect(await repo.states(), contains('Kerala'));
        expect(await repo.districts(state: 'Karnataka'), contains('Udupi'));
        final meta = await repo.meta();
        expect(meta.rowCount, 27);
        expect(meta.hasFts, fts);
      });
    });
  }

  group('mismatch checker', () {
    late MismatchChecker checker;
    setUpAll(() async => checker = MismatchChecker(await fixtureRepo()));

    test('match', () async {
      expect((await checker.check('574201', 'Puttur')).level, MismatchLevel.match);
      expect((await checker.check('574201', 'ಪುತ್ತೂರು')).level, MismatchLevel.match);
      expect((await checker.check('576101', 'Udupi')).level, MismatchLevel.match);
    });
    test('same district, different PIN', () async {
      final r = await checker.check('574202', 'Puttur');
      expect(r.level, MismatchLevel.sameDistrict);
      expect(r.suggestions.map((o) => o.pincode), contains(574201));
      expect(r.suggestions.map((o) => o.pincode), isNot(contains(671543)));
    });
    test('different district', () async {
      final r = await checker.check('574201', 'Manipal');
      expect(r.level, MismatchLevel.different);
      expect(r.suggestions.first.pincode, 576104);
      expect((await checker.check('560001', 'Mysuru')).level, MismatchLevel.different);
    });
    test('unknown place / bad PIN', () async {
      expect((await checker.check('574201', 'Xyzzyqwv')).level, MismatchLevel.unknownPlace);
      expect((await checker.check('999999', 'Puttur')).level, MismatchLevel.pinNotFound);
      expect((await checker.check('07420', 'Puttur')).level, MismatchLevel.invalidPin);
    });
  });
}

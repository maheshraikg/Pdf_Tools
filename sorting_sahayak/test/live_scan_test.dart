import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/scheme_repo.dart';
import 'package:sorting_sahayak/data/sort_engine.dart';
import 'package:sorting_sahayak/features/scan/address_parser.dart';
import 'package:sorting_sahayak/features/scan/live_scan.dart';

import 'helpers/fixture.dart';

void main() {
  test('a PIN is accepted only when read on two frames in a row', () {
    final s = PinStabilizer();
    expect(s.add('575001'), isFalse);
    expect(s.stable, isNull);
    // A misread frame in between restarts the count.
    expect(s.add('575007'), isFalse);
    expect(s.add('575001'), isFalse);
    expect(s.add('575001'), isTrue);
    expect(s.stable, '575001');
    // Same PIN again: no change reported.
    expect(s.add('575001'), isFalse);
    // No PIN on a frame keeps the last stable one.
    expect(s.add(null), isFalse);
    expect(s.stable, '575001');
    // A captured photo is trusted at once.
    expect(s.force('574239'), isTrue);
    expect(s.stable, '574239');
    s.reset();
    expect(s.stable, isNull);
  });

  test('offices on the address: PIN match first, then same area, then best match', () async {
    final dir = await fixtureRepo();
    final repo = SchemeRepo(await memoryUserDb());
    await installDefaultScheme(repo, (p) async => File(p).readAsBytesSync());
    final engine = SortEngine(dir, await repo.loadActive());

    // The line with the PIN (Sullia) is the most likely office line.
    final cand = parseAddress('Sri Ramesh\nPuttur\nSullia 574239');
    final withPin = await officesOnAddress(dir, engine, cand.places, category: kCatTD, pin: cand.pins.first);
    expect(withPin.first.office.officeName, 'Sullia');
    expect(withPin.first.samePin, isTrue);
    expect(withPin.first.result.bag, isNotNull);
    expect(withPin.map((h) => h.office.officeName), contains('Puttur'));
    expect(withPin.firstWhere((h) => h.office.officeName == 'Puttur').sameArea, isTrue);

    // No PIN: exact names come before near-miss spellings.
    final noPin = await officesOnAddress(dir, engine, parseAddress('Puttur').places, category: kCatTD);
    expect(noPin.first.office.officeName, 'Puttur');
    expect(noPin.first.score, greaterThanOrEqualTo(0.99));
  });

  test('the scanned Mangaluru address gives its PIN and office', () async {
    final dir = await fixtureRepo();
    final cand = parseAddress('School Book Company\nCar Street & K.S. Rao Road\nMANGALURU-575 001');
    expect(cand.pins, ['575001']);
    final hits = await officesOnAddress(dir, SortEngine(dir, null), cand.places, category: kCatTD, pin: '575001');
    expect(hits.first.office.officeName, 'Mangalore');
    expect(hits.first.samePin, isTrue);
  });

  test('names on other lines of the address back up the same area', () async {
    final dir = await fixtureRepo();
    final hits = await officesOnAddress(dir, SortEngine(dir, null), parseAddress('Kodialbail\nMangalore').places, category: kCatTD);
    final top = hits.take(2).map((h) => h.office.officeName).toSet();
    expect(top, {'Mangalore', 'Kodialbail'});
    expect(hits.first.support, 1);
  });

  test('Hindi address keeps its vowel signs', () {
    final c = parseAddress('श्री राम\nकरोल बाग\nनई दिल्ली ११०००५');
    expect(c.pins, ['110005']);
    expect(c.places, containsAll(['नई दिल्ली', 'करोल बाग']));
  });

  group('PIN ↔ post office check', () {
    Future<(List<ScanOfficeHit>, SortResult)> scan(String text) async {
      final dir = await fixtureRepo();
      final engine = SortEngine(dir, null);
      final c = parseAddress(text);
      final pin = c.pins.first;
      final hits = await officesOnAddress(dir, engine, c.places, category: kCatTD, pin: pin);
      return (hits, await engine.resolvePin(pin, category: kCatTD));
    }

    test('match', () async {
      final (hits, r) = await scan('Sri Ramesh\nSullia 574239');
      final chk = checkAddress('574239', r.offices, hits)!;
      expect(chk.level, AddressCheckLevel.match);
      expect(chk.bestPin, '574239');
    });

    test('same district: office named on the address is suggested', () async {
      final (hits, r) = await scan('Sri Ramesh\nKabaka post\n574201');
      final chk = checkAddress('574201', r.offices, hits)!;
      expect(chk.level, AddressCheckLevel.sameArea);
      expect(chk.named.office.officeName, 'Kabaka');
      expect(chk.bestPin, '574220');
      expect(chk.pinOffice!.officeName, 'Puttur');
    });

    test('different district', () async {
      final (hits, r) = await scan('Sri Ramesh\nSullia\n575001');
      final chk = checkAddress('575001', r.offices, hits)!;
      expect(chk.level, AddressCheckLevel.mismatch);
      expect(chk.bestPin, '574239');
    });

    test('city head office in the same district is not a conflict', () async {
      final (hits, r) = await scan('Car Street\nMangalore 575003');
      expect(checkAddress('575003', r.offices, hits), isNull);
    });
  
    test('office written with "post" wins over a taluk town with the PIN', () async {
      final dir = await fixtureRepo();
      final engine = SortEngine(dir, null);
      final c = parseAddress('Sri Ramesh\nKabaka post\nPuttur 574201');
      final hits = await officesOnAddress(dir, engine, c.places, category: kCatTD, pin: '574201');
      final r = await engine.resolvePin('574201', category: kCatTD);
      final chk = checkAddress('574201', r.offices, hits, postNames: c.postNames)!;
      expect(chk.level, AddressCheckLevel.sameArea);
      expect(chk.bestPin, '574220');
    });
  });
}

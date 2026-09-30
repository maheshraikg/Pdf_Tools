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
    s.reset();
    expect(s.stable, isNull);
  });

  test('offices on the address: PIN match first, then nearest from the sorting office', () async {
    final dir = await fixtureRepo();
    final repo = SchemeRepo(await memoryUserDb());
    await installDefaultScheme(repo, (p) async => File(p).readAsBytesSync());
    final engine = SortEngine(dir, await repo.loadActive());

    final home = await homePoint(dir, 'Mangaluru');
    expect(home, isNotNull);
    expect(home!.lat, closeTo(12.87, 0.01));

    // Sullia is farther from Mangaluru than Puttur.
    final cand = parseAddress('Sri Ramesh\nSullia\nPuttur');
    final hits = await officesOnAddress(dir, engine, cand.places, category: kCatTD, home: home);
    final names = hits.map((h) => h.office.officeName).toList();
    expect(names.indexOf('Puttur'), lessThan(names.indexOf('Sullia')));
    expect(hits.first.km, isNotNull);

    // With the PIN of Sullia read on the address, Sullia comes first.
    final withPin = await officesOnAddress(dir, engine, cand.places, category: kCatTD, home: home, pin: '574239');
    expect(withPin.first.office.officeName, 'Sullia');
    expect(withPin.first.samePin, isTrue);
    expect(withPin.first.result.bag, isNotNull);
  });

  test('the scanned Mangaluru address gives its PIN and office', () async {
    final dir = await fixtureRepo();
    final cand = parseAddress('School Book Company\nCar Street & K.S. Rao Road\nMANGALURU-575 001');
    expect(cand.pins, ['575001']);
    final hits = await officesOnAddress(dir, SortEngine(dir, null), cand.places, category: kCatTD, pin: '575001');
    expect(hits.first.office.officeName, 'Mangalore');
    expect(hits.first.samePin, isTrue);
  });
}

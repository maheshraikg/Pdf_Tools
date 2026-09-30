import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/core/constants.dart';
import 'package:sorting_sahayak/data/dmsl_diff.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/models/scheme.dart';
import 'package:sorting_sahayak/data/scheme_repo.dart';
import 'package:sorting_sahayak/data/sort_engine.dart';

import 'helpers/fixture.dart';

void main() {
  late SchemeRepo repo;
  late SortEngine engine;

  setUp(() async {
    repo = SchemeRepo(await memoryUserDb());
    await installSampleScheme(repo, (p) async => File(p).readAsBytesSync(), withParcelExtras: true);
    engine = SortEngine(await fixtureRepo(), await repo.loadActive());
  });

  test('sample scheme is stored and active', () async {
    final s = await repo.schemes();
    expect(s.single.isSample, isTrue);
    expect(s.single.name, contains(kSampleMarker));
    expect((await repo.airCodes(s.single.id!)).length, 12);
    expect((await repo.dmslVersions(s.single.id!)).single.active, isTrue);
  });

  test('sort engine: TD / Non-TD', () async {
    final r = await engine.resolvePin('574201', category: kCatTD);
    expect(r.bag!.code, 'Bag 12');
    expect(r.bag!.colour, '#D32F2F');
    expect(r.bagLevel, RuleType.exact);
    expect(r.offices.single.officeName, 'Puttur');
    expect(r.connectivity, isNull);
    expect((await engine.resolvePin('574215', category: kCatTD)).bag!.code, 'Bag 15');
    expect((await engine.resolvePin('671121', category: kCatNonTD)).bag!.code, 'NT-61');
    expect((await engine.resolvePin('110001', category: kCatNonTD)).bag!.code, 'NT-11');
    expect((await engine.resolvePin('999999', category: kCatNonTD)).bag!.code, 'NT-99');
    // A Non-TD PIN typed in TD mode: no TD bag, but the other mode is named.
    final other = await engine.resolvePin('560001', category: kCatTD);
    expect(other.bag, isNull);
    expect(other.otherBag!.code, 'NT-40');
    expect(other.otherCategory, kCatNonTD);
    // A PIN only the Non-TD default covers points to its TD bag instead.
    final back = await engine.resolvePin('576101', category: kCatNonTD);
    expect(back.bag!.code, 'NT-30'); // prefix 57
    expect(back.otherBag, isNull);
    final dflt = await engine.resolvePin('900001', category: kCatNonTD);
    expect(dflt.bag!.code, 'NT-99');
    final nf = await engine.resolvePin('574999', category: kCatTD);
    expect(nf.notInDirectory, isTrue);
  });

  test('sort engine: partial PIN gives likely bag', () async {
    final r = await engine.resolvePin('576', category: kCatTD);
    expect(r.likelyBag!.code, 'Bag 20');
    expect(r.prefixSummary!.districts, contains('Udupi'));
    expect(r.possibleBags.map((b) => b.code), containsAll(['Bag 21', 'Bag 22', 'Bag 24']));
  });

  test('air parcel: air code, hub route and yellow AIR badge', () async {
    final r = await engine.resolvePin('560001', category: kCatAirParcel);
    expect(r.air!.rule.airCode, 'BLR');
    expect(r.hub!.rule.directClosure, isTrue);
    expect(r.hub!.rule.l1Hub, contains('Bengaluru L1'));
    expect(r.connectivity, Connectivity.air);
    expect(r.connectivityDefaulted, isFalse);
    final noAir = await engine.resolvePin('574201', category: kCatAirParcel);
    expect(noAir.air, isNull);
  });

  test('parcel surface: blue badge, L2 → L1, default Surface warning', () async {
    final r = await engine.resolvePin('574201', category: kCatParcel);
    expect(r.connectivity, Connectivity.surface);
    expect(r.hub!.rule.l2Hub, contains('Puttur L2'));
    final dflt = await engine.resolvePin('400001', category: kCatParcel);
    expect(dflt.connectivityDefaulted, isTrue);
    expect(dflt.connectivity, Connectivity.surface);
    final office = await engine.resolvePin('574239', category: kCatSpeedPost);
    expect(office.hub!.rule.directClosure, isTrue);
  });

  test('resolveOffice for articles without PIN', () async {
    final dir = await fixtureRepo();
    final hits = await dir.search('Sullia');
    final r = engine.resolveOffice(hits.first.office, category: kCatTD);
    expect(r.bag!.code, 'Bag 14');
  });

  test('DMSL diff between versions', () async {
    final id = (await repo.schemes()).single.id!;
    final v1 = (await repo.dmslVersions(id)).single;
    final oldRules = await repo.hubRules(v1.id!);
    final newRules = [
      ...oldRules.where((r) => r.match.key != 'prefix:576'),
      const HubRule(match: MatchSpec.prefix('576'), l2Hub: 'Udupi L2 (demo)', l1Hub: 'Bengaluru L1 (demo)', connectivity: Connectivity.surface),
      const HubRule(match: MatchSpec.exact(580020), l2Hub: 'Hubballi L2 (demo)', l1Hub: 'Hubballi L1 (demo)'),
    ];
    final changes = diffDmsl(oldRules, newRules, universe: [574201, 576101, 576104, 580020, 560001]);
    final pins = changes.map((c) => c.pin).toSet();
    expect(pins, containsAll([576101, 576104, 580020]));
    expect(pins, isNot(contains(574201)));
    expect(pins, isNot(contains(560001)));
    expect(changes.firstWhere((c) => c.pin == 576101).after!.l1Hub, 'Bengaluru L1 (demo)');
    await repo.addDmslVersion(id, 'v2', DateTime(2026, 10, 7), newRules);
    final versions = await repo.dmslVersions(id);
    expect(versions.first.active, isTrue);
    expect(versions.first.versionName, 'v2');
    expect(versions.last.active, isFalse);
  });

  test('manual editing and export', () async {
    final id = await repo.createScheme(const Scheme(name: 'My office'));
    await repo.upsertBag(id, const Bag(code: 'B1', name: 'One', colour: '#1565C0'));
    final ruleId = await repo.upsertRule(id, const BagRule(match: MatchSpec.prefix('57'), bagCode: 'B1'));
    await repo.upsertRule(id, BagRule(id: ruleId, match: const MatchSpec.prefix('58'), bagCode: 'B1'));
    expect((await repo.rules(id)).single.match.prefix, '58');
    await repo.setActive(id);
    expect((await repo.loadActive())!.scheme.name, 'My office');
    final files = await exportScheme(repo, (await repo.scheme(id))!, xlsx: false);
    expect(files.keys.single, 'My_office_Rules.csv');
    expect(files.values.single as String, contains('58'));
    final xl = await exportScheme(repo, (await repo.schemes()).firstWhere((s) => s.isSample), xlsx: true);
    expect(xl.keys.single, endsWith('.xlsx'));
    await repo.deleteBag(id, 'B1');
    expect(await repo.rules(id), isEmpty);
    await repo.deleteScheme(id);
    expect((await repo.schemes()).length, 1);
  });

  test('move rules to another bag (office changes line)', () async {
    final id = await repo.createScheme(const Scheme(name: 'Lines'));
    await repo.upsertBag(id, const Bag(code: 'Puttur Line'));
    await repo.upsertBag(id, const Bag(code: 'Karkala Line'));
    await repo.upsertRule(id, const BagRule(match: MatchSpec.exact(574201), bagCode: 'Puttur Line'));
    await repo.upsertRule(id, const BagRule(match: MatchSpec.exact(574202), bagCode: 'Puttur Line'));
    await repo.upsertRule(id, const BagRule(match: MatchSpec.exact(574104), bagCode: 'Karkala Line'));
    expect(await repo.moveRules(id, 'Puttur Line', const Bag(code: 'Udupi Line', name: 'Udupi')), 2);
    final rules = await repo.rules(id);
    expect(rules.where((r) => r.bagCode == 'Udupi Line').length, 2);
    expect(rules.where((r) => r.bagCode == 'Udupi Line').every((r) => r.bagName == 'Udupi'), isTrue);
    expect((await repo.bags(id)).map((b) => b.code), unorderedEquals(['Karkala Line', 'Udupi Line']));
    // Keep the old bag when asked.
    expect(await repo.moveRules(id, 'Karkala Line', const Bag(code: 'Udupi Line'), removeOld: false), 1);
    expect((await repo.bags(id)).map((b) => b.code), contains('Karkala Line'));
  });

  test('bundled default Mangaluru scheme', () async {
    final id = await installDefaultScheme(repo, (p) async => File(p).readAsBytesSync());
    final rules = await repo.rules(id);
    expect(rules.length, greaterThan(700));
    expect(rules.where((r) => r.category == kCatTD), isNotEmpty);
    expect(rules.where((r) => r.category == kCatNonTD), isNotEmpty);
    await repo.setActive(id);
    final e = SortEngine(await fixtureRepo(), await repo.loadActive());
    final td = await e.resolvePin('574239', category: kCatTD);
    expect(td.bag?.code, 'Puttur Line');
    final ntd = await e.resolvePin('560001', category: kCatNonTD);
    expect(ntd.bag?.code, 'BANGALORE');
    // Deletable like any other scheme.
    await repo.deleteScheme(id);
    expect((await repo.schemes()).any((s) => s.name == kDefaultSchemeName), isFalse);
  });

  test('categories', () async {
    await repo.addCategory('Registered');
    expect(await repo.categories(), [...kBuiltInCategories, 'Registered']);
    await repo.deleteCategory('Registered');
    expect(await repo.categories(), kBuiltInCategories);
  });
}

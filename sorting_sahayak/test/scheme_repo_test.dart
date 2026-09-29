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
    await installSampleScheme(repo, (p) async => File(p).readAsBytesSync());
    engine = SortEngine(await fixtureRepo(), await repo.loadActive());
  });

  test('sample scheme is stored and active', () async {
    final s = await repo.schemes();
    expect(s.single.isSample, isTrue);
    expect(s.single.name, contains(kSampleMarker));
    expect((await repo.airCodes(s.single.id!)).length, 12);
    expect((await repo.dmslVersions(s.single.id!)).single.active, isTrue);
  });

  test('sort engine: letters', () async {
    final r = await engine.resolvePin('574201', category: kCatLetters);
    expect(r.bag!.code, 'Bag 12');
    expect(r.bag!.colour, '#D32F2F');
    expect(r.bagLevel, RuleType.exact);
    expect(r.offices.single.officeName, 'Puttur');
    expect(r.connectivity, isNull);
    expect((await engine.resolvePin('574215', category: kCatLetters)).bag!.code, 'Bag 15');
    expect((await engine.resolvePin('671121', category: kCatLetters)).bag!.code, 'Bag 60');
    expect((await engine.resolvePin('110001', category: kCatLetters)).bag!.code, 'Bag 99');
    final nf = await engine.resolvePin('574999', category: kCatLetters);
    expect(nf.notInDirectory, isTrue);
  });

  test('sort engine: partial PIN gives likely bag', () async {
    final r = await engine.resolvePin('576', category: kCatLetters);
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
    expect(r.bag!.code, 'AP-01');
    final noAir = await engine.resolvePin('574201', category: kCatAirParcel);
    expect(noAir.air, isNull);
  });

  test('parcel surface: blue badge, L2 → L1, default Surface warning', () async {
    final r = await engine.resolvePin('574201', category: kCatParcel);
    expect(r.connectivity, Connectivity.surface);
    expect(r.hub!.rule.l2Hub, contains('Puttur L2'));
    expect(r.bag!.code, 'Bag 12'); // exact letters rule beats the parcel prefix rule
    final p = await engine.resolvePin('574220', category: kCatParcel);
    expect(p.bag!.code, 'Bag 12'); // range 574201–574299
    final dflt = await engine.resolvePin('400001', category: kCatParcel);
    expect(dflt.connectivityDefaulted, isTrue);
    expect(dflt.connectivity, Connectivity.surface);
    final office = await engine.resolvePin('574239', category: kCatSpeedPost);
    expect(office.hub!.rule.directClosure, isTrue);
  });

  test('resolveOffice for articles without PIN', () async {
    final dir = await fixtureRepo();
    final hits = await dir.search('Sullia');
    final r = engine.resolveOffice(hits.first.office, category: kCatLetters);
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

  test('categories', () async {
    await repo.addCategory('Registered');
    expect(await repo.categories(), [...kBuiltInCategories, 'Registered']);
    await repo.deleteCategory('Registered');
    expect(await repo.categories(), kBuiltInCategories);
  });
}

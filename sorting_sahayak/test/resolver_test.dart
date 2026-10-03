import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/models/scheme.dart';
import 'package:sorting_sahayak/data/resolver.dart';

BagRule r(MatchSpec m, String bag, {String? cat}) => BagRule(match: m, bagCode: bag, category: cat);
MatchSpec office(String n) => MatchSpec(type: RuleType.office, officeNorm: n);
MatchSpec district(String n) => MatchSpec(type: RuleType.district, districtNorm: n);
MatchSpec state(String n) => MatchSpec(type: RuleType.state, stateNorm: n);

void main() {
  final rules = [
    r(const MatchSpec.fallback(), 'DEFAULT'),
    r(state('karnataka'), 'STATE'),
    r(district('dakshinakannada'), 'DISTRICT'),
    r(office('puttur'), 'OFFICE'),
    r(const MatchSpec.prefix('5'), 'P1'),
    r(const MatchSpec.prefix('57'), 'P2'),
    r(const MatchSpec.prefix('574'), 'P3'),
    r(const MatchSpec.prefix('5742'), 'P4'),
    r(const MatchSpec.range(574000, 574999), 'R-WIDE'),
    r(const MatchSpec.range(574200, 574299), 'R-NARROW'),
    r(const MatchSpec.exact(574201), 'EXACT'),
  ];
  final res = RuleResolver(rules);
  String? bag(ResolveQuery q) => res.resolve(q)?.rule.bagCode;

  test('exact beats everything', () {
    final x = res.resolve(const ResolveQuery(pin: 574201, officeNorms: ['puttur']))!;
    expect(x.rule.bagCode, 'EXACT');
    expect(x.level, RuleType.exact);
  });
  test('smallest range beats wider range and prefixes', () {
    expect(bag(const ResolveQuery(pin: 574250)), 'R-NARROW');
    expect(bag(const ResolveQuery(pin: 574500)), 'R-WIDE');
  });
  test('longest prefix wins', () {
    expect(bag(const ResolveQuery(pin: 575001)), 'P2');
    expect(bag(const ResolveQuery(pin: 560001)), 'P1');
    final noRanges = RuleResolver(rules.where((x) => x.match.type != RuleType.range && x.match.type != RuleType.exact));
    expect(noRanges.resolve(const ResolveQuery(pin: 574201))!.rule.bagCode, 'P4');
    expect(noRanges.resolve(const ResolveQuery(pin: 574301))!.rule.bagCode, 'P3');
  });
  test('office > district > state > default when no PIN rule matches', () {
    expect(bag(const ResolveQuery(pin: 110001, officeNorms: ['puttur'], districtNorms: ['dakshinakannada'])), 'OFFICE');
    expect(bag(const ResolveQuery(officeNorms: ['x'], districtNorms: ['dakshinakannada'], stateNorms: ['karnataka'])), 'DISTRICT');
    expect(bag(const ResolveQuery(districtNorms: ['udupi'], stateNorms: ['karnataka'])), 'STATE');
    expect(bag(const ResolveQuery(pin: 110001)), 'DEFAULT');
    expect(RuleResolver<BagRule>([]).resolve(const ResolveQuery(pin: 110001)), isNull);
  });
  test('category-specific rules', () {
    final c = RuleResolver([
      r(const MatchSpec.prefix('574'), 'LETTERS'),
      r(const MatchSpec.prefix('574'), 'PARCEL', cat: 'Parcel (surface)'),
      r(const MatchSpec.prefix('56'), 'AIR-ONLY', cat: 'Air Parcel'),
      r(const MatchSpec.fallback(), 'DEF'),
    ]);
    expect(c.resolve(const ResolveQuery(pin: 574201, category: 'Ordinary/Letters'))!.rule.bagCode, 'LETTERS');
    expect(c.resolve(const ResolveQuery(pin: 574201, category: 'Parcel (surface)'))!.rule.bagCode, 'PARCEL');
    expect(c.resolve(const ResolveQuery(pin: 560001, category: 'Air Parcel'))!.rule.bagCode, 'AIR-ONLY');
    expect(c.resolve(const ResolveQuery(pin: 560001, category: 'Ordinary/Letters'))!.rule.bagCode, 'DEF');
  });
  test('partial PIN helpers', () {
    expect(res.resolvePartial('574')!.rule.bagCode, 'P3');
    expect(res.resolvePartial('57')!.rule.bagCode, 'P2');
    expect(res.resolvePartial('8'), isNull);
    final cands = res.candidatesForPartial('5742').map((x) => x.bagCode).toSet();
    expect(cands, containsAll(['EXACT', 'R-NARROW', 'R-WIDE', 'P4', 'P3']));
  });
  test('air codes use the same priority incl. state', () {
    final air = RuleResolver([
      const AirCodeRule(match: MatchSpec.prefix('56'), airCode: 'BLR'),
      AirCodeRule(match: state('kerala'), airCode: 'TRV'),
      AirCodeRule(match: district('mysuru'), airCode: 'MYQ'),
      const AirCodeRule(match: MatchSpec.exact(570001), airCode: 'EXACT'),
    ]);
    expect(air.resolve(const ResolveQuery(pin: 560038))!.rule.airCode, 'BLR');
    expect(air.resolve(const ResolveQuery(pin: 570001, districtNorms: ['mysuru']))!.rule.airCode, 'EXACT');
    expect(air.resolve(const ResolveQuery(pin: 570010, districtNorms: ['mysuru'], stateNorms: ['karnataka']))!.rule.airCode, 'MYQ');
    expect(air.resolve(const ResolveQuery(pin: 682001, stateNorms: ['kerala']))!.level, RuleType.state);
    expect(air.resolve(const ResolveQuery(pin: 110001)), isNull);
  });
}

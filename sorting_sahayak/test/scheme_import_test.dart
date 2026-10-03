import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sorting_sahayak/data/import/scheme_import.dart';
import 'package:sorting_sahayak/data/import/scheme_io.dart';
import 'package:sorting_sahayak/data/import/table_reader.dart';
import 'package:sorting_sahayak/data/models/scheme.dart';

List<List<String>> table(String csv) => readTable(Uint8List.fromList(csv.codeUnits), 'x.csv').sheets['CSV']!;

void main() {
  group('column auto-detection', () {
    test('English headers', () {
      final m = autoDetectColumns(['PIN', 'PIN From', 'PIN To', 'Prefix', 'Office', 'District', 'Bag No.', 'Bag Name', 'Section', 'Remarks'], ImportKind.bagRules);
      expect(m[ImportField.pin], 0);
      expect(m[ImportField.pinFrom], 1);
      expect(m[ImportField.pinTo], 2);
      expect(m[ImportField.prefix], 3);
      expect(m[ImportField.office], 4);
      expect(m[ImportField.district], 5);
      expect(m[ImportField.bagCode], 6);
      expect(m[ImportField.bagName], 7);
      expect(m[ImportField.section], 8);
      expect(m[ImportField.remarks], 9);
    });
    test('Kannada and Hindi headers', () {
      final kn = autoDetectColumns(['ಪಿನ್', 'ಕಚೇರಿ', 'ಜಿಲ್ಲೆ', 'ಚೀಲ ಸಂಖ್ಯೆ', 'ಷರಾ'], ImportKind.bagRules);
      expect(kn[ImportField.pin], 0);
      expect(kn[ImportField.office], 1);
      expect(kn[ImportField.district], 2);
      expect(kn[ImportField.bagCode], 3);
      expect(kn[ImportField.remarks], 4);
      final hi = autoDetectColumns(['पिन कोड', 'डाकघर', 'जिला', 'थैला संख्या', 'टिप्पणी'], ImportKind.bagRules);
      expect(hi[ImportField.pin], 0);
      expect(hi[ImportField.office], 1);
      expect(hi[ImportField.bagCode], 3);
    });
    test('variants and header row below a title', () {
      final m = autoDetectColumns(['Pincode From', 'Pincode To', 'Bag Number', 'Connectivity (Air/Surface)'], ImportKind.bagRules);
      expect(m[ImportField.pinFrom], 0);
      expect(m[ImportField.pinTo], 1);
      expect(m[ImportField.bagCode], 2);
      expect(m[ImportField.connectivity], 3);
      final rows = [['Sorting scheme of XYZ office'], [''], ['PIN', 'Bag'], ['574201', '12']];
      expect(detectHeaderRow(rows, ImportKind.bagRules), 2);
      final air = autoDetectColumns(['Prefix', 'State', 'Air Code', 'Station', 'Via'], ImportKind.airCodes);
      expect(air[ImportField.airCode], 2);
      expect(air[ImportField.station], 3);
      expect(air[ImportField.via], 4);
      final d = autoDetectColumns(['PIN', 'L2 Hub', 'L1 Hub', 'Direct closure (Y/N)', 'Connectivity'], ImportKind.dmsl);
      expect(d[ImportField.l2Hub], 1);
      expect(d[ImportField.l1Hub], 2);
      expect(d[ImportField.direct], 3);
    });
  });

  group('row parsing', () {
    test('infers rule types from filled cells', () {
      final res = autoImport<BagRule>(table('''PIN,PIN From,PIN To,Prefix,Office,District,Bag
574201,,,,,,12
,574201,574299,,,,12
574 xxx,,,,,,10
,,,575,,,02
574201-574210,,,,,,13
,,,,Puttur,,12
,,,,,Udupi,20
All other,,,,,,99
,,,,,,98
'''), ImportKind.bagRules);
      final types = res.rules.map((r) => r.match.type).toList();
      expect(types, [RuleType.exact, RuleType.range, RuleType.prefix, RuleType.prefix, RuleType.range, RuleType.office, RuleType.district, RuleType.fallback, RuleType.fallback]);
      expect(res.rules[2].match.prefix, '574');
      expect(res.rules[5].match.officeNorm, 'puttur');
      expect(res.count(IssueKind.treatedAsDefault), 1);
      expect(res.count(IssueKind.duplicate) + res.count(IssueKind.conflict), 1); // two defaults
    });
    test('validation report: bad PINs, no bag, overlaps, duplicates', () {
      final res = autoImport<BagRule>(table('''PIN,PIN From,PIN To,Bag
07420,,,1
574201,,,
,574299,574201,3
,574200,574300,4
,574250,574350,5
,574210,574220,6
574201,,,7
574201,,,7
574201,,,8
'''), ImportKind.bagRules);
      expect(res.count(IssueKind.badPin), 2);
      expect(res.count(IssueKind.noBag), 1);
      expect(res.count(IssueKind.overlap), 1);
      expect(res.count(IssueKind.nested), 1);
      expect(res.count(IssueKind.duplicate), 1);
      expect(res.count(IssueKind.conflict), 1);
      expect(res.rules.length, 6);
      final overlap = res.issues.firstWhere((i) => i.kind == IssueKind.overlap);
      expect(overlap.row, 6);
      expect(overlap.otherRow, 5);
    });
    test('air codes warn on unknown airport codes but keep them', () {
      final res = autoImport<AirCodeRule>(table('Prefix,Air Code\n56,BLR\n79,ZZQ\n60,\n'), ImportKind.airCodes);
      expect(res.rules.map((r) => r.airCode), ['BLR', 'ZZQ']);
      expect(res.count(IssueKind.unknownAirCode), 1);
      expect(res.count(IssueKind.noBag), 1);
    });
    test('DMSL rows: direct closure and connectivity', () {
      final res = autoImport<HubRule>(table('PIN,L2 Hub,L1 Hub,Direct,Connectivity\n574201,Puttur L2,Mangaluru L1,N,Surface\n560001,,Bengaluru L1,Y,Air\n575001,Mng L2,Mng L1,,\n'), ImportKind.dmsl);
      expect(res.rules[0].directClosure, isFalse);
      expect(res.rules[1].directClosure, isTrue);
      expect(res.rules[1].connectivity, Connectivity.air);
      expect(res.count(IssueKind.noConnectivity), 1);
    });
  });

  test('bundled SAMPLE files import cleanly and cover every rule type', () {
    List<List<String>> load(String n) {
      final t = readTable(File('assets/samples/$n').readAsBytesSync(), n);
      return t.sheets[t.defaultSheet]!;
    }

    for (final ext in ['csv', 'xlsx']) {
      final s = autoImport<BagRule>(load('sample_scheme.$ext'), ImportKind.bagRules);
      expect(s.errors, isEmpty, reason: s.errors.map((e) => e.message).join('; '));
      expect(s.rules.length, greaterThanOrEqualTo(30));
      expect(s.rules.map((r) => r.match.type).toSet(), RuleType.values.toSet());
      final a = autoImport<AirCodeRule>(load('sample_air_codes.$ext'), ImportKind.airCodes);
      expect(a.errors, isEmpty);
      expect(a.count(IssueKind.unknownAirCode), 1);
      final d = autoImport<HubRule>(load('sample_dmsl.$ext'), ImportKind.dmsl);
      expect(d.errors, isEmpty);
      expect(d.rules.any((r) => r.directClosure), isTrue);
    }
    expect(File('assets/samples/sample_scheme.csv').readAsStringSync(), contains('SAMPLE – not real'));
  });

  test('export tables round-trip through import', () {
    final rules = [
      const BagRule(match: MatchSpec.exact(574201), bagCode: 'B12', bagName: 'Puttur', connectivity: Connectivity.air),
      const BagRule(match: MatchSpec.range(575001, 575030), bagCode: 'B01'),
      const BagRule(match: MatchSpec.fallback(), bagCode: 'B99', category: 'Speed Post'),
    ];
    final t = bagRulesTable(rules, {'B12': const Bag(code: 'B12', name: 'Puttur', colour: '#D32F2F')});
    final back = autoImport<BagRule>(table(writeCsv(t).substring(1)), ImportKind.bagRules);
    expect(back.errors, isEmpty);
    expect(back.rules.map((r) => r.match.key), rules.map((r) => r.match.key));
    expect(back.rules[0].connectivity, Connectivity.air);
    expect(back.rules[2].category, 'Speed Post');
    expect(back.bags.first.colour, '#D32F2F');
    final x = readTable(writeXlsx({'Rules': t}), 'a.xlsx');
    expect(x.sheets['Rules']![1][1], '574201');
  });
}

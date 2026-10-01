/// High-level import/export helpers: turning files into saved schemes and
/// schemes back into shareable .xlsx / .csv files.
library;

import 'dart:typed_data';

import '../../core/constants.dart';
import '../../core/theme.dart' show kBagPalette, colourToHex;
import '../models/scheme.dart';
import '../scheme_repo.dart';
import 'scheme_import.dart';
import 'table_reader.dart';

/// Parses one sheet with auto-detected header and columns.
ImportResult<T> autoImport<T extends Matchable>(List<List<String>> rows, ImportKind kind) {
  final h = detectHeaderRow(rows, kind);
  final mapping = autoDetectColumns(rows.isEmpty ? const [] : rows[h], kind);
  return parseRows<T>(rows: rows, headerRow: h, mapping: mapping, kind: kind);
}

List<String> get _palette => kBagPalette.map(colourToHex).toList();

/// Bundled default scheme (Mangaluru TD / Non-TD lines), installed on first
/// launch. Users can edit or delete it and restore it from Schemes.
const String kDefaultSchemeAsset = 'assets/schemes/mangaluru_default.csv';
const String kDefaultSchemeName = 'Mangaluru – default (TD / Non-TD)';

/// Air codes per destination PH, from the MR PH sorting sheet. "NIL" marks
/// PIN series the sheet sends without an air code (surface).
const String kDefaultAirAsset = 'assets/schemes/mangaluru_air_codes.csv';

Future<List<AirCodeRule>> _defaultAirCodes(Future<Uint8List> Function(String path) loadAsset) async {
  final t = readTable(await loadAsset(kDefaultAirAsset), 'x.csv');
  return autoImport<AirCodeRule>(t.sheets[t.defaultSheet]!, ImportKind.airCodes).rules;
}

/// Adds the sheet's air codes to an installed default scheme that has none
/// (installs from before the air codes were bundled). Returns true if added.
Future<bool> addDefaultAirCodes(SchemeRepo repo, Future<Uint8List> Function(String path) loadAsset) async {
  var added = false;
  for (final s in await repo.schemes()) {
    if (s.name != kDefaultSchemeName || s.id == null) continue;
    if ((await repo.airCodes(s.id!)).isNotEmpty) continue;
    await repo.replaceAirCodes(s.id!, await _defaultAirCodes(loadAsset));
    added = true;
  }
  return added;
}

/// Installs the bundled default scheme and makes it active. Returns its id.
Future<int> installDefaultScheme(SchemeRepo repo, Future<Uint8List> Function(String path) loadAsset) async {
  final t = readTable(await loadAsset(kDefaultSchemeAsset), 'x.csv');
  final res = autoImport<BagRule>(t.sheets[t.defaultSheet]!, ImportKind.bagRules);
  final id = await repo.saveScheme(
    const Scheme(
      name: kDefaultSchemeName,
      office: 'Mangaluru',
      notes: 'Built-in default. Edit it when sorting changes, or delete it and import your own file.',
    ),
    res.rules,
    completeBags(res.rules, res.bags, _palette),
  );
  await repo.replaceAirCodes(id, await _defaultAirCodes(loadAsset));
  return id;
}

/// Installs the bundled SAMPLE scheme (bag rules, air codes, DMSL).
/// [loadAsset] returns the bytes of an asset path.
/// [withParcelExtras] also installs the SAMPLE air code sheet and DMSL
/// (only useful with custom parcel / air categories).
Future<int> installSampleScheme(
  SchemeRepo repo,
  Future<Uint8List> Function(String path) loadAsset, {
  bool withParcelExtras = false,
}) async {
  List<List<String>> sheet(Uint8List b, String name) {
    final t = readTable(b, name);
    return t.sheets[t.defaultSheet]!;
  }

  final scheme = autoImport<BagRule>(sheet(await loadAsset('assets/samples/sample_scheme.csv'), 'x.csv'), ImportKind.bagRules);
  final id = await repo.saveScheme(
    const Scheme(
      name: '$kSampleMarker – demo scheme',
      office: 'Demo office (SAMPLE)',
      notes: 'Fake rules for practice. Import your own office scheme for real sorting.',
      isSample: true,
    ),
    scheme.rules,
    completeBags(scheme.rules, scheme.bags, _palette),
  );
  if (withParcelExtras) {
    final air = autoImport<AirCodeRule>(sheet(await loadAsset('assets/samples/sample_air_codes.csv'), 'x.csv'), ImportKind.airCodes);
    final dmsl = autoImport<HubRule>(sheet(await loadAsset('assets/samples/sample_dmsl.csv'), 'x.csv'), ImportKind.dmsl);
    await repo.replaceAirCodes(id, air.rules);
    await repo.addDmslVersion(id, 'SAMPLE-2026-10', DateTime(2026, 10, 7), dmsl.rules);
  }
  return id;
}

String _s(Object? v) => v == null ? '' : '$v';

String _typeLabel(RuleType t) => switch (t) {
  RuleType.exact => 'PIN',
  RuleType.range => 'Range',
  RuleType.prefix => 'Prefix',
  RuleType.office => 'Office',
  RuleType.district => 'District',
  RuleType.state => 'State',
  RuleType.fallback => 'Default',
};

const kSchemeHeader = ['Type', 'PIN', 'PIN From', 'PIN To', 'Prefix', 'Office', 'District', 'State', 'Bag No', 'Bag Name', 'Section', 'Remarks', 'Category', 'Connectivity', 'Colour'];
const kAirHeader = ['Type', 'PIN', 'PIN From', 'PIN To', 'Prefix', 'District', 'State', 'Air Code', 'Station', 'Via', 'Remarks'];
const kDmslHeader = ['Type', 'PIN', 'PIN From', 'PIN To', 'Prefix', 'Office', 'District', 'State', 'L2 Hub', 'L1 Hub', 'Direct closure (Y/N)', 'Connectivity', 'Remarks'];

List<List<String>> bagRulesTable(List<BagRule> rules, Map<String, Bag> bags) {
  final coloured = <String>{};
  return [
    kSchemeHeader,
    for (final r in rules)
      [
        _typeLabel(r.match.type), _s(r.match.pin), _s(r.match.pinFrom), _s(r.match.pinTo), _s(r.match.prefix), //
        _s(r.officeName), _s(r.district), _s(r.state), r.bagCode, r.bagName.isEmpty ? bags[r.bagCode]?.name ?? '' : r.bagName, //
        r.section, r.remarks, _s(r.category), _s(r.connectivity?.label),
        coloured.add(r.bagCode) ? bags[r.bagCode]?.colour ?? '' : '',
      ],
  ];
}

List<List<String>> airCodesTable(List<AirCodeRule> rules) => [
  kAirHeader,
  for (final r in rules)
    [
      _typeLabel(r.match.type), _s(r.match.pin), _s(r.match.pinFrom), _s(r.match.pinTo), _s(r.match.prefix), //
      _s(r.district), _s(r.state), r.airCode, r.stationName, r.viaHub, r.remarks,
    ],
];

List<List<String>> dmslTable(List<HubRule> rules) => [
  kDmslHeader,
  for (final r in rules)
    [
      _typeLabel(r.match.type), _s(r.match.pin), _s(r.match.pinFrom), _s(r.match.pinTo), _s(r.match.prefix), //
      _s(r.officeName), _s(r.district), _s(r.state), r.l2Hub, r.l1Hub, r.directClosure ? 'Y' : 'N', //
      _s(r.connectivity?.label), r.remarks,
    ],
];

/// A scheme as export files: one .xlsx with a sheet per table, or one .csv
/// per table. Returns file name → bytes / text.
Future<Map<String, Object>> exportScheme(SchemeRepo repo, Scheme s, {required bool xlsx}) async {
  final active = await repo.load(s);
  final rules = active.bagResolver.rules;
  final air = active.airResolver.rules;
  final hubs = active.hubResolver.rules;
  final base = s.name.replaceAll(RegExp(r'[^A-Za-z0-9ಀ-೿ऀ-ॿ]+'), '_').replaceAll(RegExp(r'_+$'), '');
  final sheets = <String, List<List<String>>>{
    'Rules': [
      if (s.isSample) [kSampleMarker],
      ...bagRulesTable(rules, active.bags),
    ],
    if (air.isNotEmpty) 'AirCodes': airCodesTable(air),
    if (hubs.isNotEmpty) 'DMSL': dmslTable(hubs),
  };
  if (xlsx) return {'$base.xlsx': writeXlsx(sheets)};
  return {for (final e in sheets.entries) '${base}_${e.key}.csv': writeCsv(e.value)};
}

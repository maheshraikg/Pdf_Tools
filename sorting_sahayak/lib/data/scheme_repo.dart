/// Storage of user-imported sorting schemes, bags, air codes, DMSL versions
/// and mail categories.
library;

import 'package:sqflite_common/sqlite_api.dart';

import '../core/constants.dart';
import 'models/scheme.dart';
import 'resolver.dart';

/// Everything the Sort screen needs about the active scheme, cached in memory.
class ActiveScheme {
  ActiveScheme({
    required this.scheme,
    required List<Bag> bags,
    required this.rules,
    required List<AirCodeRule> airCodes,
    this.dmsl,
    List<HubRule> hubRules = const [],
  }) : bags = {for (final b in bags) b.code: b},
       bagOrder = bags.map((b) => b.code).toList(),
       bagResolver = RuleResolver(rules),
       airResolver = RuleResolver(airCodes),
       hubResolver = RuleResolver(hubRules);

  final Scheme scheme;
  final List<BagRule> rules;
  final Map<String, Bag> bags;
  final List<String> bagOrder;
  final RuleResolver<BagRule> bagResolver;
  final RuleResolver<AirCodeRule> airResolver;
  final DmslVersion? dmsl;
  final RuleResolver<HubRule> hubResolver;

  Bag bagFor(BagRule r) => bags[r.bagCode] ?? Bag(code: r.bagCode, name: r.bagName);
}

class SchemeRepo {
  SchemeRepo(this.db);

  final Database db;

  // ---------------------------------------------------------------- schemes

  Future<List<Scheme>> schemes() async =>
      (await db.query('schemes', orderBy: 'active DESC, imported_at DESC')).map(Scheme.fromRow).toList();

  Future<Scheme?> scheme(int id) async {
    final r = await db.query('schemes', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Scheme.fromRow(r.first);
  }

  Future<int> createScheme(Scheme s) => db.insert('schemes', s.toRow());

  Future<void> updateScheme(int id, {String? name, String? office, String? notes}) =>
      db.update('schemes', {'name': ?name, 'office': ?office, 'notes': ?notes}, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteScheme(int id) => db.delete('schemes', where: 'id = ?', whereArgs: [id]);

  Future<void> setActive(int? id) => db.transaction((t) async {
    await t.update('schemes', {'active': 0});
    if (id != null) await t.update('schemes', {'active': 1}, where: 'id = ?', whereArgs: [id]);
  });

  /// Saves a complete imported scheme in one transaction; returns its id.
  Future<int> saveScheme(Scheme s, List<BagRule> rules, List<Bag> bags, {bool activate = true}) => db.transaction((t) async {
    if (activate) await t.update('schemes', {'active': 0});
    final id = await t.insert(
      'schemes',
      Scheme(name: s.name, office: s.office, notes: s.notes, importedAt: DateTime.now(), active: activate, isSample: s.isSample).toRow(),
    );
    final b = t.batch();
    for (final r in rules) {
      b.insert('rules', r.toRow(id));
    }
    for (final bag in bags) {
      b.insert('bags', _bagRow(id, bag), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await b.commit(noResult: true);
    return id;
  });

  // ------------------------------------------------------------------ rules

  Future<List<BagRule>> rules(int schemeId) async =>
      (await db.query('rules', where: 'scheme_id = ?', whereArgs: [schemeId], orderBy: 'id')).map(BagRule.fromRow).toList();

  Future<int> upsertRule(int schemeId, BagRule r) async {
    if (r.id == null) return db.insert('rules', r.toRow(schemeId));
    await db.update('rules', r.toRow(schemeId), where: 'id = ?', whereArgs: [r.id]);
    return r.id!;
  }

  Future<void> deleteRule(int id) => db.delete('rules', where: 'id = ?', whereArgs: [id]);

  /// Replaces all bag rules of a scheme (used by "merge import").
  Future<void> addRules(int schemeId, List<BagRule> rules, List<Bag> bags) => db.transaction((t) async {
    final b = t.batch();
    for (final r in rules) {
      b.insert('rules', r.toRow(schemeId));
    }
    for (final bag in bags) {
      b.insert('bags', _bagRow(schemeId, bag), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await b.commit(noResult: true);
  });

  // ------------------------------------------------------------------- bags

  Map<String, Object?> _bagRow(int schemeId, Bag b) => {
    'scheme_id': schemeId,
    'bag_code': b.code,
    'bag_name': b.name,
    'colour': b.colour,
    'sort_order': b.order,
  };

  Future<List<Bag>> bags(int schemeId) async =>
      (await db.query('bags', where: 'scheme_id = ?', whereArgs: [schemeId], orderBy: 'sort_order, bag_code')).map(Bag.fromRow).toList();

  Future<void> upsertBag(int schemeId, Bag b) => db.insert('bags', _bagRow(schemeId, b), conflictAlgorithm: ConflictAlgorithm.replace);

  /// Points every rule of bag [from] at bag [to] (created if missing), e.g.
  /// when an office moves to another line. Returns the number of rules moved.
  Future<int> moveRules(int schemeId, String from, Bag to, {bool removeOld = true}) => db.transaction((t) async {
    await t.insert('bags', _bagRow(schemeId, to), conflictAlgorithm: ConflictAlgorithm.ignore);
    final n = await t.update(
      'rules',
      {'bag_code': to.code, if (to.name.isNotEmpty) 'bag_name': to.name},
      where: 'scheme_id = ? AND bag_code = ?',
      whereArgs: [schemeId, from],
    );
    if (removeOld && from != to.code) {
      await t.delete('bags', where: 'scheme_id = ? AND bag_code = ?', whereArgs: [schemeId, from]);
    }
    return n;
  });

  /// Deletes a bag; rules pointing at it are deleted too.
  Future<void> deleteBag(int schemeId, String code) => db.transaction((t) async {
    await t.delete('bags', where: 'scheme_id = ? AND bag_code = ?', whereArgs: [schemeId, code]);
    await t.delete('rules', where: 'scheme_id = ? AND bag_code = ?', whereArgs: [schemeId, code]);
  });

  // -------------------------------------------------------------- air codes

  Future<List<AirCodeRule>> airCodes(int schemeId) async =>
      (await db.query('air_codes', where: 'scheme_id = ?', whereArgs: [schemeId], orderBy: 'id')).map(AirCodeRule.fromRow).toList();

  /// Replaces the air code table of a scheme.
  Future<void> replaceAirCodes(int schemeId, List<AirCodeRule> rules) => db.transaction((t) async {
    await t.delete('air_codes', where: 'scheme_id = ?', whereArgs: [schemeId]);
    final b = t.batch();
    for (final r in rules) {
      b.insert('air_codes', r.toRow(schemeId));
    }
    await b.commit(noResult: true);
  });

  // ------------------------------------------------------------------- DMSL

  Future<List<DmslVersion>> dmslVersions(int schemeId) async => (await db.query(
    'dmsl_versions',
    where: 'scheme_id = ?',
    whereArgs: [schemeId],
    orderBy: 'id DESC',
  )).map(DmslVersion.fromRow).toList();

  Future<List<HubRule>> hubRules(int versionId) async =>
      (await db.query('hub_rules', where: 'version_id = ?', whereArgs: [versionId], orderBy: 'id')).map(HubRule.fromRow).toList();

  /// Stores a new DMSL version and makes it the active one.
  Future<int> addDmslVersion(int schemeId, String name, DateTime? validFrom, List<HubRule> rules) => db.transaction((t) async {
    await t.update('dmsl_versions', {'active': 0}, where: 'scheme_id = ?', whereArgs: [schemeId]);
    final id = await t.insert('dmsl_versions', {
      'scheme_id': schemeId,
      'version_name': name,
      'valid_from': validFrom?.toIso8601String().substring(0, 10),
      'imported_at': DateTime.now().toIso8601String(),
      'active': 1,
    });
    final b = t.batch();
    for (final r in rules) {
      b.insert('hub_rules', r.toRow(id));
    }
    await b.commit(noResult: true);
    return id;
  });

  Future<void> setActiveDmsl(int schemeId, int versionId) => db.transaction((t) async {
    await t.update('dmsl_versions', {'active': 0}, where: 'scheme_id = ?', whereArgs: [schemeId]);
    await t.update('dmsl_versions', {'active': 1}, where: 'id = ?', whereArgs: [versionId]);
  });

  Future<void> deleteDmslVersion(int versionId) => db.delete('dmsl_versions', where: 'id = ?', whereArgs: [versionId]);

  // ------------------------------------------------------------- categories

  Future<List<String>> categories() async {
    final rows = await db.query('categories', orderBy: 'sort_order, name');
    final custom = rows.map((r) => r['name'] as String).where((c) => !kBuiltInCategories.contains(c));
    return [...kBuiltInCategories, ...custom];
  }

  Future<void> addCategory(String name) async {
    final n = name.trim();
    if (n.isEmpty || kBuiltInCategories.contains(n)) return;
    await db.insert('categories', {'name': n, 'sort_order': 100}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteCategory(String name) => db.delete('categories', where: 'name = ?', whereArgs: [name]);

  // ------------------------------------------------------------ active load

  Future<ActiveScheme?> loadActive() async {
    final rows = await db.query('schemes', where: 'active = 1', limit: 1);
    if (rows.isEmpty) return null;
    return load(Scheme.fromRow(rows.first));
  }

  Future<ActiveScheme> load(Scheme s) async {
    final versions = await dmslVersions(s.id!);
    final active = versions.where((v) => v.active).firstOrNull;
    return ActiveScheme(
      scheme: s,
      bags: await bags(s.id!),
      rules: await rules(s.id!),
      airCodes: await airCodes(s.id!),
      dmsl: active,
      hubRules: active == null ? const [] : await hubRules(active.id!),
    );
  }
}

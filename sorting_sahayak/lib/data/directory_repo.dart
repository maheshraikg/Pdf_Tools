/// Read access to the offline PIN directory: lookup by PIN, fuzzy search by
/// place name (English / Kannada / Hindi), district lists.
library;

import 'package:sqflite_common/sqlite_api.dart';

import '../core/fuzzy.dart';
import 'directory_builder.dart' show kOfficeFrom, kOfficeSelect;
import 'models/office.dart';

class SearchHit {
  const SearchHit(this.office, this.score);

  final Office office;

  /// 0..1 similarity of the query to this office (name, taluk or district).
  final double score;
}

class SearchFilter {
  const SearchFilter({this.state, this.district, this.deliveryOnly = false});

  final String? state;
  final String? district;
  final bool deliveryOnly;

  bool get isEmpty => state == null && district == null && !deliveryOnly;
}

/// Summary of offices sharing a PIN prefix (e.g. the sorting district "574").
class PrefixSummary {
  const PrefixSummary({required this.districts, required this.states, required this.officeCount});

  final List<String> districts;
  final List<String> states;
  final int officeCount;
}

abstract class DirectorySource {
  Future<List<Office>> officesForPin(int pin);
  Future<PrefixSummary> prefixSummary(String prefix);
  Future<List<SearchHit>> search(String query, {SearchFilter filter = const SearchFilter(), int limit = 50});
  Future<List<String>> states();
  Future<List<String>> districts({String? state});
  Future<DirectoryMeta> meta();
  Future<List<Office>> randomOffices(int n, {String? state});
}

class DirectoryRepo implements DirectorySource {
  DirectoryRepo(this.db, {bool? useFts}) : _forceFts = useFts;

  final Database db;
  final bool? _forceFts;
  bool? _fts;
  Map<String, List<String>>? _keyBuckets;


  bool? _taluk;

  /// Taluk is only indexed when the source CSV had a taluk column.
  Future<bool> get _hasTaluk async => _taluk ??= (await db.rawQuery(
    "SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = 'idx_offices_taluk_norm'",
  )).isNotEmpty;

  Future<bool> get ftsAvailable async {
    if (_fts != null) return _fts!;
    if (_forceFts == false) return _fts = false;
    try {
      await db.rawQuery('SELECT rowid FROM offices_fts LIMIT 1');
      _fts = true;
    } on Object {
      _fts = false;
    }
    return _fts!;
  }

  @override
  Future<List<Office>> officesForPin(int pin) async {
    final rows = await db.rawQuery(
      'SELECT $kOfficeSelect FROM $kOfficeFrom WHERE o.pincode = ? '
      "ORDER BY CASE o.office_type WHEN 'HO' THEN 0 WHEN 'SO' THEN 1 WHEN 'PO' THEN 2 ELSE 3 END, o.office_name",
      [pin],
    );
    return rows.map(Office.fromRow).toList();
  }

  @override
  Future<PrefixSummary> prefixSummary(String prefix) async {
    final p = prefix.replaceAll(RegExp(r'\D'), '');
    if (p.isEmpty || p.length > 6) return const PrefixSummary(districts: [], states: [], officeCount: 0);
    final lo = int.parse(p.padRight(6, '0'));
    final hi = int.parse(p.padRight(6, '9'));
    final rows = await db.rawQuery(
      'SELECT district, state, COUNT(*) AS n FROM offices WHERE pincode BETWEEN ? AND ? '
      'GROUP BY district, state ORDER BY n DESC',
      [lo, hi],
    );
    final districts = <String>[];
    final states = <String>[];
    var count = 0;
    for (final r in rows) {
      final d = r['district'] as String? ?? '';
      final s = r['state'] as String? ?? '';
      if (d.isNotEmpty && !districts.contains(d)) districts.add(d);
      if (s.isNotEmpty && !states.contains(s)) states.add(s);
      count += r['n'] as int;
    }
    return PrefixSummary(districts: districts, states: states, officeCount: count);
  }

  (String, List<Object?>) _filterSql(SearchFilter f) {
    final parts = <String>[];
    final args = <Object?>[];
    if (f.state != null) {
      parts.add('o.state = ?');
      args.add(f.state);
    }
    if (f.district != null) {
      parts.add('o.district = ?');
      args.add(f.district);
    }
    if (f.deliveryOnly) parts.add("o.delivery = 'Delivery'");
    return (parts.isEmpty ? '' : ' AND ${parts.join(' AND ')}', args);
  }

  @override
  Future<List<SearchHit>> search(String query, {SearchFilter filter = const SearchFilter(), int limit = 50}) async {
    final qn = normalizePlace(query);
    if (qn.isEmpty) return [];
    // A PIN typed into the search box: list its offices.
    final digits = qn.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 6 && digits == qn) {
      final offs = await officesForPin(int.parse(digits));
      return offs.map((o) => SearchHit(o, 1)).toList();
    }
    final words = placeWords(query);
    final qk = phoneticKey(qn);
    final (fSql, fArgs) = _filterSql(filter);
    final variants = aliasVariants(qn);
    final byId = <int, Map<String, Object?>>{};

    Future<void> add(String where, List<Object?> args, {int lim = 150}) async {
      final rows = await db.rawQuery(
        'SELECT $kOfficeSelect, o.office_name_norm AS office_name_norm, o.name_key AS name_key, '
        'o.district_norm AS district_norm, o.taluk_norm AS taluk_norm FROM $kOfficeFrom '
        'WHERE ($where)$fSql LIMIT $lim',
        [...args, ...fArgs],
      );
      for (final r in rows) {
        byId[r['id'] as int] = r;
      }
    }

    String upper(String s) => s.substring(0, s.length - 1) + String.fromCharCode(s.codeUnitAt(s.length - 1) + 1);

    // 1. Exact / prefix on the normalised name (index range scans).
    for (final v in variants) {
      await add('o.office_name_norm >= ? AND o.office_name_norm < ?', [v, upper(v)]);
    }
    // 2. Same phonetic key.
    if (qk.length >= 2) await add('o.name_key = ?', [qk]);
    // 3. Word / substring match via FTS5, or LIKE when FTS5 is unavailable.
    if (words.isNotEmpty && words.join().length >= 3) {
      if (await ftsAvailable) {
        final match = words.map((w) => '"${w.replaceAll('"', '')}"*').join(' ');
        await add('o.id IN (SELECT rowid FROM offices_fts WHERE offices_fts MATCH ?)', [match]);
      } else {
        await add(words.map((_) => 'o.office_words LIKE ?').join(' AND '), [for (final w in words) '%$w%']);
      }
    }
    // 4. District / taluk names ("Udupi", "Puttur taluk").
    for (final v in variants) {
      await add('o.district_norm = ?', [v], lim: 100);
      if (await _hasTaluk) await add('o.taluk_norm = ?', [v], lim: 100);
    }
    // 5. Typos: edit distance on phonetic keys (in-memory bucket scan).
    if (byId.length < 20 && qk.length >= 3) {
      final keys = await _fuzzyKeys(qk);
      if (keys.isNotEmpty) {
        await add('o.name_key IN (${List.filled(keys.length, '?').join(',')})', keys, lim: 200);
      }
    }

    final hits = <SearchHit>[];
    for (final r in byId.values) {
      final nameNorm = r['office_name_norm'] as String;
      var s = 0.0;
      for (final v in variants) {
        final vk = v == qn ? qk : phoneticKey(v);
        s = _max(s, placeSimilarity(v, nameNorm, queryKey: vk, candidateKey: r['name_key'] as String));
        final d = r['district_norm'] as String? ?? '';
        if (d.isNotEmpty) s = _max(s, 0.9 * placeSimilarity(v, d, queryKey: vk));
        final t = r['taluk_norm'] as String? ?? '';
        if (t.isNotEmpty) s = _max(s, 0.92 * placeSimilarity(v, t, queryKey: vk));
      }
      if (s < 0.5) continue;
      final o = Office.fromRow(r);
      // Tie-breakers: delivery offices and head/sub offices first.
      if (o.delivery) s += 0.004;
      if (o.officeType == 'HO') s += 0.003;
      if (o.officeType == 'SO') s += 0.002;
      hits.add(SearchHit(o, s > 1 ? 1 : s));
    }
    hits.sort((a, b) {
      final c = b.score.compareTo(a.score);
      return c != 0 ? c : a.office.officeName.compareTo(b.office.officeName);
    });
    return hits.length > limit ? hits.sublist(0, limit) : hits;
  }

  double _max(double a, double b) => a > b ? a : b;

  /// Loads distinct phonetic keys once, bucketed by first letter, and
  /// returns keys within the tolerated edit distance of [qk].
  Future<List<String>> _fuzzyKeys(String qk) async {
    if (_keyBuckets == null) {
      final rows = await db.rawQuery('SELECT DISTINCT name_key FROM offices');
      final b = <String, List<String>>{};
      for (final r in rows) {
        final k = r['name_key'] as String;
        if (k.isEmpty) continue;
        (b[k[0]] ??= []).add(k);
      }
      _keyBuckets = b;
    }
    final maxD = maxEditsFor(qk.length);
    if (maxD == 0) return const [];
    final out = <String>[];
    for (final k in _keyBuckets![qk[0]] ?? const <String>[]) {
      if ((k.length - qk.length).abs() > maxD) continue;
      if (levenshtein(qk, k, max: maxD) <= maxD) {
        out.add(k);
        if (out.length >= 60) break;
      }
    }
    return out;
  }

  /// Warms the fuzzy key cache (call once after startup).
  Future<void> warmUp() => _fuzzyKeys('xxxx');

  @override
  Future<List<String>> states() async {
    final rows = await db.rawQuery("SELECT DISTINCT state FROM offices WHERE state <> '' ORDER BY state");
    return rows.map((r) => r['state'] as String).toList();
  }

  @override
  Future<List<String>> districts({String? state}) async {
    final rows = await db.rawQuery(
      "SELECT DISTINCT district FROM offices WHERE district <> ''${state != null ? ' AND state = ?' : ''} ORDER BY district",
      [?state],
    );
    return rows.map((r) => r['district'] as String).toList();
  }

  @override
  Future<DirectoryMeta> meta() async {
    try {
      final rows = await db.rawQuery('SELECT key, value FROM meta');
      return DirectoryMeta({for (final r in rows) r['key'] as String: '${r['value']}'});
    } on Object {
      return const DirectoryMeta({});
    }
  }

  @override
  Future<List<Office>> randomOffices(int n, {String? state}) async {
    final rows = await db.rawQuery(
      "SELECT $kOfficeSelect FROM $kOfficeFrom WHERE o.delivery = 'Delivery'${state != null ? ' AND o.state = ?' : ''} "
      'ORDER BY RANDOM() LIMIT ?',
      [?state, n],
    );
    return rows.map(Office.fromRow).toList();
  }

  /// Every PIN with its normalised district(s) and state(s), for DMSL diffs.
  Future<Map<int, ({List<String> districts, List<String> states})>> pinRegions() async {
    final rows = await db.rawQuery('SELECT DISTINCT pincode, district_norm, state FROM offices');
    final out = <int, ({List<String> districts, List<String> states})>{};
    for (final r in rows) {
      final e = out.putIfAbsent(r['pincode'] as int, () => (districts: <String>[], states: <String>[]));
      final d = r['district_norm'] as String? ?? '';
      final st = normalizePlace(r['state'] as String? ?? '');
      if (d.isNotEmpty && !e.districts.contains(d)) e.districts.add(d);
      if (st.isNotEmpty && !e.states.contains(st)) e.states.add(st);
    }
    return out;
  }

  /// Offices (distinct PINs) in a normalised district.
  Future<List<Office>> officesInDistrict(String districtNorm, {int limit = 200}) async {
    final rows = await db.rawQuery(
      'SELECT $kOfficeSelect FROM $kOfficeFrom WHERE o.district_norm = ? GROUP BY o.pincode ORDER BY o.pincode LIMIT ?',
      [districtNorm, limit],
    );
    return rows.map(Office.fromRow).toList();
  }
}

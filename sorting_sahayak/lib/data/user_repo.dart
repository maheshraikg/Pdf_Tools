/// Local-only personal data: recent lookups, favourites, bulk sessions and
/// learning progress.
library;

import 'package:sqflite_common/sqlite_api.dart';

import '../core/constants.dart';
import 'models/office.dart';

class Favourite {
  const Favourite({this.id, required this.pin, this.officeName = '', this.district = '', this.state = '', this.note = ''});

  final int? id;
  final int pin;
  final String officeName;
  final String district;
  final String state;
  final String note;

  factory Favourite.fromRow(Map<String, Object?> r) => Favourite(
    id: r['id'] as int,
    pin: r['pin'] as int,
    officeName: r['office_name'] as String? ?? '',
    district: r['district'] as String? ?? '',
    state: r['state'] as String? ?? '',
    note: r['note'] as String? ?? '',
  );
}

class BulkSession {
  const BulkSession({
    required this.id,
    required this.name,
    required this.date,
    this.schemeId,
    this.schemeName = '',
    this.category = kCatTD,
    required this.createdAt,
    this.endedAt,
    this.count = 0,
  });

  final int id;
  final String name;
  final String date;
  final int? schemeId;
  final String schemeName;
  final String category;
  final DateTime createdAt;
  final DateTime? endedAt;
  final int count;

  bool get ended => endedAt != null;

  factory BulkSession.fromRow(Map<String, Object?> r) => BulkSession(
    id: r['id'] as int,
    name: r['name'] as String,
    date: r['date'] as String,
    schemeId: r['scheme_id'] as int?,
    schemeName: r['scheme_name'] as String? ?? '',
    category: r['category'] as String? ?? kCatTD,
    createdAt: DateTime.parse(r['created_at'] as String),
    endedAt: DateTime.tryParse(r['ended_at'] as String? ?? ''),
    count: r['n'] as int? ?? 0,
  );
}

class BulkEntry {
  const BulkEntry({
    this.id,
    required this.raw,
    this.pin,
    this.bagCode,
    this.bagName,
    this.airCode,
    this.l2Hub,
    this.l1Hub,
    this.connectivity,
    required this.ts,
  });

  final int? id;
  final String raw;
  final int? pin;
  final String? bagCode;
  final String? bagName;
  final String? airCode;
  final String? l2Hub;
  final String? l1Hub;
  final String? connectivity;
  final int ts;

  /// Resolved to a bag (invalid / unknown entries are listed for fixing).
  bool get resolved => pin != null && bagCode != null && bagCode!.isNotEmpty;

  Map<String, Object?> toRow(int sessionId) => {
    'session_id': sessionId,
    'raw': raw,
    'pin': pin,
    'bag_code': bagCode,
    'bag_name': bagName,
    'air_code': airCode,
    'l2_hub': l2Hub,
    'l1_hub': l1Hub,
    'connectivity': connectivity,
    'ts': ts,
  };

  factory BulkEntry.fromRow(Map<String, Object?> r) => BulkEntry(
    id: r['id'] as int,
    raw: r['raw'] as String,
    pin: r['pin'] as int?,
    bagCode: r['bag_code'] as String?,
    bagName: r['bag_name'] as String?,
    airCode: r['air_code'] as String?,
    l2Hub: r['l2_hub'] as String?,
    l1Hub: r['l1_hub'] as String?,
    connectivity: r['connectivity'] as String?,
    ts: r['ts'] as int,
  );
}

class QuizRecord {
  const QuizRecord({required this.ts, required this.kind, required this.score, required this.total, required this.durationMs});

  final DateTime ts;
  final String kind;
  final int score;
  final int total;
  final int durationMs;

  double get perMinute => durationMs <= 0 ? 0 : total / (durationMs / 60000);
  double get percent => total == 0 ? 0 : score * 100 / total;
}

class WeakArea {
  const WeakArea(this.label, this.wrong, this.kind);

  final String label;
  final int wrong;

  /// 'bag' or 'prefix'
  final String kind;
}

class UserRepo {
  UserRepo(this.db);

  final Database db;

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---------------------------------------------------------------- recents

  Future<void> addRecent(int pin) async {
    await db.insert('recents', {'pin': pin, 'ts': _now}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.execute(
      'DELETE FROM recents WHERE pin NOT IN (SELECT pin FROM recents ORDER BY ts DESC LIMIT $kRecentLimit)',
    );
  }

  Future<List<int>> recents() async =>
      (await db.query('recents', orderBy: 'ts DESC', limit: kRecentLimit)).map((r) => r['pin'] as int).toList();

  Future<void> clearRecents() => db.delete('recents');

  // ------------------------------------------------------------- favourites

  Future<void> addFavourite(Office o, {String note = ''}) => db.insert('favourites', {
    'pin': o.pincode,
    'office_name': o.officeName,
    'district': o.district,
    'state': o.state,
    'note': note,
    'ts': _now,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> addFavouritePin(int pin, {String note = ''}) =>
      db.insert('favourites', {'pin': pin, 'office_name': '', 'note': note, 'ts': _now}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<List<Favourite>> favourites() async =>
      (await db.query('favourites', orderBy: 'ts DESC')).map(Favourite.fromRow).toList();

  Future<bool> isFavourite(int pin, String officeName) async =>
      (await db.query('favourites', where: 'pin = ? AND office_name = ?', whereArgs: [pin, officeName])).isNotEmpty;

  Future<void> removeFavourite(int id) => db.delete('favourites', where: 'id = ?', whereArgs: [id]);

  Future<void> removeFavouriteBy(int pin, String officeName) =>
      db.delete('favourites', where: 'pin = ? AND office_name = ?', whereArgs: [pin, officeName]);

  // ------------------------------------------------------------------- bulk

  Future<int> startSession({required String name, required String date, int? schemeId, String schemeName = '', required String category}) =>
      db.insert('bulk_sessions', {
        'name': name,
        'date': date,
        'scheme_id': schemeId,
        'scheme_name': schemeName,
        'category': category,
        'created_at': DateTime.now().toIso8601String(),
      });

  Future<List<BulkSession>> sessions() async => (await db.rawQuery(
    'SELECT s.*, (SELECT COUNT(*) FROM bulk_entries e WHERE e.session_id = s.id) AS n '
    'FROM bulk_sessions s ORDER BY s.created_at DESC',
  )).map(BulkSession.fromRow).toList();

  Future<BulkSession?> session(int id) async {
    final r = await db.rawQuery(
      'SELECT s.*, (SELECT COUNT(*) FROM bulk_entries e WHERE e.session_id = s.id) AS n FROM bulk_sessions s WHERE id = ?',
      [id],
    );
    return r.isEmpty ? null : BulkSession.fromRow(r.first);
  }

  Future<void> endSession(int id) =>
      db.update('bulk_sessions', {'ended_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);

  Future<void> reopenSession(int id) => db.update('bulk_sessions', {'ended_at': null}, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteSession(int id) => db.delete('bulk_sessions', where: 'id = ?', whereArgs: [id]);

  Future<int> addEntry(int sessionId, BulkEntry e) => db.insert('bulk_entries', e.toRow(sessionId));

  Future<void> updateEntry(int sessionId, int id, BulkEntry e) =>
      db.update('bulk_entries', e.toRow(sessionId), where: 'id = ?', whereArgs: [id]);

  Future<void> deleteEntry(int id) => db.delete('bulk_entries', where: 'id = ?', whereArgs: [id]);

  Future<List<BulkEntry>> entries(int sessionId) async =>
      (await db.query('bulk_entries', where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'id'))
          .map(BulkEntry.fromRow)
          .toList();

  // ---------------------------------------------------------------- learning

  /// Leitner box (1–5) and due time for each card key.
  Future<Map<String, ({int box, int due})>> leitner(int schemeId) async => {
    for (final r in await db.query('leitner', where: 'scheme_id = ?', whereArgs: [schemeId]))
      r['card_key'] as String: (box: r['box'] as int, due: r['due'] as int),
  };

  Future<void> setLeitner(int schemeId, String key, int box, int due) => db.insert(
    'leitner',
    {'card_key': key, 'scheme_id': schemeId, 'box': box, 'due': due},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> resetLeitner(int schemeId) => db.delete('leitner', where: 'scheme_id = ?', whereArgs: [schemeId]);

  Future<void> addQuiz(int? schemeId, String kind, int score, int total, int durationMs) => db.insert('quiz_history', {
    'ts': _now,
    'scheme_id': schemeId,
    'kind': kind,
    'score': score,
    'total': total,
    'duration_ms': durationMs,
  });

  Future<List<QuizRecord>> quizHistory({int? schemeId, int limit = 30}) async => (await db.query(
    'quiz_history',
    where: schemeId == null ? null : 'scheme_id = ?',
    whereArgs: schemeId == null ? null : [schemeId],
    orderBy: 'ts DESC',
    limit: limit,
  ))
      .map((r) => QuizRecord(
            ts: DateTime.fromMillisecondsSinceEpoch(r['ts'] as int),
            kind: r['kind'] as String,
            score: r['score'] as int,
            total: r['total'] as int,
            durationMs: r['duration_ms'] as int,
          ))
      .toList()
      .reversed
      .toList();

  Future<void> addMistake(int? schemeId, String kind, String question, String? prefix, String correct, String? chosen) =>
      db.insert('quiz_mistakes', {
        'ts': _now,
        'scheme_id': schemeId,
        'kind': kind,
        'question': question,
        'prefix': prefix,
        'correct': correct,
        'chosen': chosen,
      });

  /// Bags and 3-digit prefixes answered wrongly most often.
  Future<List<WeakArea>> weakAreas(int? schemeId, {int limit = 8}) async {
    final where = schemeId == null ? '' : 'WHERE scheme_id = $schemeId';
    final bags = await db.rawQuery(
      'SELECT correct AS label, COUNT(*) AS n FROM quiz_mistakes $where GROUP BY correct ORDER BY n DESC LIMIT $limit',
    );
    final prefixes = await db.rawQuery(
      "SELECT prefix AS label, COUNT(*) AS n FROM quiz_mistakes ${where.isEmpty ? 'WHERE' : '$where AND'} prefix IS NOT NULL AND prefix <> '' "
      'GROUP BY prefix ORDER BY n DESC LIMIT $limit',
    );
    return [
      for (final r in bags) WeakArea(r['label'] as String, r['n'] as int, 'bag'),
      for (final r in prefixes) WeakArea(r['label'] as String, r['n'] as int, 'prefix'),
    ];
  }

  Future<void> clearLearning(int? schemeId) async {
    await db.delete('quiz_mistakes');
    await db.delete('quiz_history');
    if (schemeId != null) await resetLeitner(schemeId);
  }
}

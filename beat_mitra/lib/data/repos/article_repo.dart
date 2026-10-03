import 'package:sqflite_common/sqlite_api.dart';

import '../models.dart';

/// Reasons after which the postman normally tries again the next day.
const Set<String> reattemptReasons = {'doorLocked', 'addresseeAbsent', 'other'};

class ArticleRepo {
  ArticleRepo(this.db);
  final Database db;

  Future<int> save(Article a) async {
    final m = a.toMap()..remove('id');
    if (a.id == null) return db.insert('articles', m);
    await db.update('articles', m, where: 'id = ?', whereArgs: [a.id]);
    return a.id!;
  }

  Future<void> delete(int id) => db.delete('articles', where: 'id = ?', whereArgs: [id]);

  Future<List<Article>> forDate(String date) async =>
      (await db.query('articles', where: 'date = ?', whereArgs: [date], orderBy: 'id')).map(Article.fromMap).toList();

  Future<Article?> article(int id) async {
    final r = await db.query('articles', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Article.fromMap(r.first);
  }

  /// Dates that have articles, newest first, with counts.
  Future<Map<String, int>> history() async {
    final rows = await db.rawQuery('SELECT date, COUNT(*) AS c FROM articles GROUP BY date ORDER BY date DESC');
    return {for (final r in rows) r['date'] as String: r['c'] as int};
  }

  /// True if the same article number already exists on [date].
  Future<bool> existsOn(String date, String articleNo) async {
    if (articleNo.isEmpty) return false;
    final r = await db.query('articles', where: 'date = ? AND article_no = ?', whereArgs: [date, articleNo], limit: 1);
    return r.isNotEmpty;
  }

  /// Copies the re-attempt articles of [fromDate] into [toDate] as pending.
  /// Safe to call more than once.
  Future<int> carryForward(String fromDate, String toDate) async {
    final from = await forDate(fromDate);
    final existing = await forDate(toDate);
    var n = 0;
    for (final a in from) {
      if (a.status != ArticleStatus.notDelivered || !reattemptReasons.contains(a.reason)) continue;
      final dup = existing.any(
        (e) =>
            e.carriedFrom == fromDate &&
            e.articleNo == a.articleNo &&
            e.rawAddress == a.rawAddress &&
            e.placeId == a.placeId,
      );
      if (dup) continue;
      await db.insert('articles', {
        ...a.toMap()..remove('id'),
        'date': toDate,
        'status': 'pending',
        'reason': null,
        'delivered_at': null,
        'lat': null,
        'lng': null,
        'carried_from': fromDate,
      });
      n++;
    }
    return n;
  }

  /// Deletes history older than [days] days. Returns the number of rows.
  Future<int> deleteOlderThan(int days, {DateTime? now}) async {
    final cutoff = dayKey((now ?? DateTime.now()).subtract(Duration(days: days)));
    final n = await db.delete('articles', where: 'date < ?', whereArgs: [cutoff]);
    await db.delete('day_log', where: 'date < ?', whereArgs: [cutoff]);
    return n;
  }

  Future<void> setDayDistance(String date, double meters) async {
    await db.rawInsert(
      'INSERT INTO day_log(date, distance_m) VALUES(?, ?) ON CONFLICT(date) DO UPDATE SET distance_m = excluded.distance_m',
      [date, meters],
    );
  }

  Future<double> dayDistance(String date) async {
    final r = await db.query('day_log', where: 'date = ?', whereArgs: [date]);
    return r.isEmpty ? 0 : (r.first['distance_m'] as num).toDouble();
  }
}

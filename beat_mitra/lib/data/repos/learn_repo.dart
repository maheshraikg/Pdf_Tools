import 'package:sqflite_common/sqlite_api.dart';

class StreetProgress {
  StreetProgress(this.streetId, this.streetName, this.learned, this.total);
  final int? streetId;
  final String streetName;
  final int learned;
  final int total;
  double get ratio => total == 0 ? 0 : learned / total;
}

class LearnProgress {
  LearnProgress(this.learned, this.total, this.streets);
  final int learned;
  final int total;
  final List<StreetProgress> streets;
  double get percent => total == 0 ? 0 : 100 * learned / total;

  /// Streets with the lowest share of learned places first.
  List<StreetProgress> get weakStreets =>
      (streets.where((s) => s.total > 0 && s.ratio < 1).toList()..sort((a, b) => a.ratio.compareTo(b.ratio)));
}

/// A place counts as "learned" after 2+ correct answers and more correct
/// than wrong.
class LearnRepo {
  LearnRepo(this.db);
  final Database db;

  Future<void> record(int placeId, bool correct) async {
    await db.rawInsert(
      '''
INSERT INTO learn_progress(place_id, correct, wrong, last_seen) VALUES(?, ?, ?, ?)
ON CONFLICT(place_id) DO UPDATE SET
  correct = correct + excluded.correct,
  wrong = wrong + excluded.wrong,
  last_seen = excluded.last_seen''',
      [placeId, correct ? 1 : 0, correct ? 0 : 1, DateTime.now().millisecondsSinceEpoch],
    );
  }

  Future<LearnProgress> progress(int beatId) async {
    final rows = await db.rawQuery(
      '''
SELECT p.id, p.street_id, s.name AS street_name, COALESCE(l.correct, 0) AS correct, COALESCE(l.wrong, 0) AS wrong
FROM places p
LEFT JOIN streets s ON s.id = p.street_id
LEFT JOIN learn_progress l ON l.place_id = p.id
WHERE p.beat_id = ?''',
      [beatId],
    );
    var learned = 0;
    final byStreet = <int?, List<int>>{};
    final names = <int?, String>{};
    for (final r in rows) {
      final ok = (r['correct'] as int) >= 2 && (r['correct'] as int) > (r['wrong'] as int);
      if (ok) learned++;
      final sid = r['street_id'] as int?;
      names[sid] = r['street_name'] as String? ?? '';
      byStreet.putIfAbsent(sid, () => [0, 0]);
      byStreet[sid]![1]++;
      if (ok) byStreet[sid]![0]++;
    }
    return LearnProgress(learned, rows.length, [
      for (final e in byStreet.entries) StreetProgress(e.key, names[e.key] ?? '', e.value[0], e.value[1]),
    ]);
  }

  /// Weight for picking quiz questions: unseen / weak places come first.
  Future<Map<int, int>> weights(int beatId) async {
    final rows = await db.rawQuery(
      '''
SELECT p.id, COALESCE(l.correct, 0) AS correct, COALESCE(l.wrong, 0) AS wrong
FROM places p LEFT JOIN learn_progress l ON l.place_id = p.id WHERE p.beat_id = ?''',
      [beatId],
    );
    return {for (final r in rows) r['id'] as int: (1 + 3 * (r['wrong'] as int) - (r['correct'] as int)).clamp(1, 10)};
  }

  Future<void> reset(int beatId) =>
      db.rawDelete('DELETE FROM learn_progress WHERE place_id IN (SELECT id FROM places WHERE beat_id = ?)', [beatId]);
}

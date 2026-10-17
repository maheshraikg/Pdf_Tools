import 'package:sqflite_common/sqlite_api.dart';

import '../models.dart';

class BeatRepo {
  BeatRepo(this.db);
  final Database db;

  Future<List<Beat>> beats() async =>
      (await db.query('beats', orderBy: 'name COLLATE NOCASE')).map(Beat.fromMap).toList();

  Future<Beat?> beat(int id) async {
    final r = await db.query('beats', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Beat.fromMap(r.first);
  }

  Future<int> saveBeat(Beat b) async {
    final m = b.toMap()..remove('id');
    if (b.id == null) return db.insert('beats', m);
    await db.update('beats', m, where: 'id = ?', whereArgs: [b.id]);
    return b.id!;
  }

  Future<void> deleteBeat(int id) => db.delete('beats', where: 'id = ?', whereArgs: [id]);

  Future<List<Street>> streets(int beatId) async => (await db.query(
    'streets',
    where: 'beat_id = ?',
    whereArgs: [beatId],
    orderBy: 'order_index, name COLLATE NOCASE',
  )).map(Street.fromMap).toList();

  Future<Street?> street(int id) async {
    final r = await db.query('streets', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : Street.fromMap(r.first);
  }

  Future<int> saveStreet(Street s) async {
    final m = s.toMap()..remove('id');
    if (s.id == null) {
      final max =
          (await db.rawQuery('SELECT COALESCE(MAX(order_index), -1) AS m FROM streets WHERE beat_id = ?', [
                s.beatId,
              ])).first['m']
              as int;
      m['order_index'] = max + 1;
      return db.insert('streets', m);
    }
    await db.update('streets', m, where: 'id = ?', whereArgs: [s.id]);
    return s.id!;
  }

  Future<void> deleteStreet(int id) => db.delete('streets', where: 'id = ?', whereArgs: [id]);

  /// Saves the walking order after a drag-reorder.
  Future<void> reorderStreets(List<int> idsInOrder) async {
    final b = db.batch();
    for (var i = 0; i < idsInOrder.length; i++) {
      b.update('streets', {'order_index': i}, where: 'id = ?', whereArgs: [idsInOrder[i]]);
    }
    await b.commit(noResult: true);
  }

  Future<List<AreaNote>> areaNotes(int beatId) async => (await db.query(
    'area_notes',
    where: 'beat_id = ?',
    whereArgs: [beatId],
    orderBy: 'id',
  )).map(AreaNote.fromMap).toList();

  Future<int> saveAreaNote(AreaNote n) async {
    final m = n.toMap()..remove('id');
    if (n.id == null) return db.insert('area_notes', m);
    await db.update('area_notes', m, where: 'id = ?', whereArgs: [n.id]);
    return n.id!;
  }

  Future<void> deleteAreaNote(int id) => db.delete('area_notes', where: 'id = ?', whereArgs: [id]);
}

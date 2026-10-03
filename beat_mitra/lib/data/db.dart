import 'package:sqflite_common/sqlite_api.dart';

/// Schema of the on-device database. On the phone it is opened with
/// SQLCipher (AES-256, see [openEncryptedDatabase] in db_open.dart);
/// tests use an in-memory sqflite_common_ffi database.
class AppDatabase {
  AppDatabase(this.db);
  final Database db;

  static const int version = 1;

  static Future<void> onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> onCreate(Database db, int version) async {
    final b = db.batch();
    b.execute('''
CREATE TABLE beats(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  office TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  created_at INTEGER NOT NULL
)''');
    b.execute('''
CREATE TABLE streets(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  beat_id INTEGER NOT NULL REFERENCES beats(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_norm TEXT NOT NULL DEFAULT '',
  area TEXT NOT NULL DEFAULT '',
  cross_main_note TEXT NOT NULL DEFAULT '',
  order_index INTEGER NOT NULL DEFAULT 0
)''');
    b.execute('''
CREATE TABLE places(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  beat_id INTEGER NOT NULL REFERENCES beats(id) ON DELETE CASCADE,
  street_id INTEGER REFERENCES streets(id) ON DELETE SET NULL,
  door_no TEXT NOT NULL DEFAULT '',
  door_no_norm TEXT NOT NULL DEFAULT '',
  building TEXT NOT NULL DEFAULT '',
  floor_flat TEXT NOT NULL DEFAULT '',
  area TEXT NOT NULL DEFAULT '',
  pin TEXT NOT NULL DEFAULT '',
  landmark TEXT NOT NULL DEFAULT '',
  lat REAL,
  lng REAL,
  gps_accuracy_m REAL,
  type TEXT NOT NULL DEFAULT 'house',
  notes TEXT NOT NULL DEFAULT '',
  delivery_pref TEXT NOT NULL DEFAULT '',
  walk_order INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
    b.execute('''
CREATE TABLE place_photos(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  created_at INTEGER NOT NULL
)''');
    b.execute('''
CREATE TABLE addressees(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  place_id INTEGER NOT NULL REFERENCES places(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_norm TEXT NOT NULL DEFAULT '',
  aliases TEXT NOT NULL DEFAULT '',
  phone_optional TEXT NOT NULL DEFAULT '',
  note TEXT NOT NULL DEFAULT ''
)''');
    b.execute('''
CREATE TABLE articles(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL,
  article_no TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL DEFAULT 'letter',
  raw_address TEXT NOT NULL DEFAULT '',
  place_id INTEGER REFERENCES places(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  reason TEXT,
  attempts INTEGER NOT NULL DEFAULT 0,
  delivered_at INTEGER,
  lat REAL,
  lng REAL,
  note TEXT NOT NULL DEFAULT '',
  carried_from TEXT
)''');
    b.execute('''
CREATE TABLE area_notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  beat_id INTEGER NOT NULL REFERENCES beats(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  text TEXT NOT NULL DEFAULT ''
)''');
    b.execute('''
CREATE TABLE learn_progress(
  place_id INTEGER PRIMARY KEY REFERENCES places(id) ON DELETE CASCADE,
  correct INTEGER NOT NULL DEFAULT 0,
  wrong INTEGER NOT NULL DEFAULT 0,
  last_seen INTEGER
)''');
    b.execute('''
CREATE TABLE day_log(
  date TEXT PRIMARY KEY,
  distance_m REAL NOT NULL DEFAULT 0,
  started_at INTEGER,
  finished_at INTEGER
)''');
    b.execute('CREATE INDEX idx_streets_beat ON streets(beat_id, order_index)');
    b.execute('CREATE INDEX idx_streets_name_norm ON streets(name_norm)');
    b.execute('CREATE INDEX idx_places_beat ON places(beat_id)');
    b.execute('CREATE INDEX idx_places_street ON places(street_id)');
    b.execute('CREATE INDEX idx_places_door_norm ON places(door_no_norm)');
    b.execute('CREATE INDEX idx_addressees_place ON addressees(place_id)');
    b.execute('CREATE INDEX idx_addressees_name_norm ON addressees(name_norm)');
    b.execute('CREATE INDEX idx_photos_place ON place_photos(place_id)');
    b.execute('CREATE INDEX idx_articles_date ON articles(date)');
    b.execute('CREATE INDEX idx_articles_place ON articles(place_id)');
    await b.commit(noResult: true);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {}

  /// Removes every row (used by "Delete all data").
  Future<void> wipe() async {
    await db.transaction((t) async {
      for (final table in [
        'learn_progress',
        'day_log',
        'articles',
        'place_photos',
        'addressees',
        'places',
        'streets',
        'area_notes',
        'beats',
      ]) {
        await t.delete(table);
      }
    });
  }
}

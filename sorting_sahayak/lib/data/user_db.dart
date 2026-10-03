/// Schema of the local user database. Pure sqflite_common so tests can open
/// it with sqflite_common_ffi.
library;

import 'package:sqflite_common/sqlite_api.dart';

const int kUserDbVersion = 1;

const List<String> _schemaV1 = [
  '''CREATE TABLE schemes(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    office TEXT,
    notes TEXT,
    imported_at TEXT,
    active INTEGER NOT NULL DEFAULT 0,
    is_sample INTEGER NOT NULL DEFAULT 0
  )''',
  '''CREATE TABLE rules(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scheme_id INTEGER NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    pin INTEGER,
    pin_from INTEGER,
    pin_to INTEGER,
    prefix TEXT,
    office_name TEXT,
    office_name_norm TEXT,
    district TEXT,
    district_norm TEXT,
    state TEXT,
    state_norm TEXT,
    bag_code TEXT,
    bag_name TEXT,
    section TEXT,
    remarks TEXT,
    category TEXT,
    connectivity TEXT
  )''',
  'CREATE INDEX idx_rules_scheme ON rules(scheme_id)',
  '''CREATE TABLE bags(
    scheme_id INTEGER NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    bag_code TEXT NOT NULL,
    bag_name TEXT,
    colour TEXT,
    sort_order INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(scheme_id, bag_code)
  )''',
  '''CREATE TABLE air_codes(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scheme_id INTEGER NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    rule_type TEXT NOT NULL,
    pin INTEGER,
    pin_from INTEGER,
    pin_to INTEGER,
    prefix TEXT,
    district TEXT,
    district_norm TEXT,
    state TEXT,
    state_norm TEXT,
    air_code TEXT NOT NULL,
    air_station_name TEXT,
    via_hub TEXT,
    remarks TEXT
  )''',
  'CREATE INDEX idx_air_scheme ON air_codes(scheme_id)',
  '''CREATE TABLE dmsl_versions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scheme_id INTEGER NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    version_name TEXT NOT NULL,
    valid_from TEXT,
    imported_at TEXT,
    active INTEGER NOT NULL DEFAULT 0
  )''',
  '''CREATE TABLE hub_rules(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    version_id INTEGER NOT NULL REFERENCES dmsl_versions(id) ON DELETE CASCADE,
    rule_type TEXT NOT NULL,
    pin INTEGER,
    pin_from INTEGER,
    pin_to INTEGER,
    prefix TEXT,
    office_name TEXT,
    office_name_norm TEXT,
    district TEXT,
    district_norm TEXT,
    state TEXT,
    state_norm TEXT,
    l2_hub TEXT,
    l1_hub TEXT,
    direct_closure INTEGER NOT NULL DEFAULT 0,
    connectivity TEXT,
    remarks TEXT
  )''',
  'CREATE INDEX idx_hub_version ON hub_rules(version_id)',
  '''CREATE TABLE categories(
    name TEXT PRIMARY KEY,
    sort_order INTEGER NOT NULL DEFAULT 0
  )''',
  '''CREATE TABLE bulk_sessions(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    date TEXT NOT NULL,
    scheme_id INTEGER,
    scheme_name TEXT,
    category TEXT,
    created_at TEXT NOT NULL,
    ended_at TEXT
  )''',
  '''CREATE TABLE bulk_entries(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL REFERENCES bulk_sessions(id) ON DELETE CASCADE,
    raw TEXT NOT NULL,
    pin INTEGER,
    bag_code TEXT,
    bag_name TEXT,
    air_code TEXT,
    l2_hub TEXT,
    l1_hub TEXT,
    connectivity TEXT,
    ts INTEGER NOT NULL
  )''',
  'CREATE INDEX idx_entries_session ON bulk_entries(session_id)',
  '''CREATE TABLE recents(
    pin INTEGER PRIMARY KEY,
    ts INTEGER NOT NULL
  )''',
  '''CREATE TABLE favourites(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pin INTEGER NOT NULL,
    office_name TEXT,
    district TEXT,
    state TEXT,
    note TEXT,
    ts INTEGER NOT NULL,
    UNIQUE(pin, office_name)
  )''',
  '''CREATE TABLE leitner(
    card_key TEXT NOT NULL,
    scheme_id INTEGER NOT NULL,
    box INTEGER NOT NULL DEFAULT 1,
    due INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY(card_key, scheme_id)
  )''',
  '''CREATE TABLE quiz_history(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts INTEGER NOT NULL,
    scheme_id INTEGER,
    kind TEXT NOT NULL,
    score INTEGER NOT NULL,
    total INTEGER NOT NULL,
    duration_ms INTEGER NOT NULL
  )''',
  '''CREATE TABLE quiz_mistakes(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ts INTEGER NOT NULL,
    scheme_id INTEGER,
    kind TEXT NOT NULL,
    question TEXT NOT NULL,
    prefix TEXT,
    correct TEXT NOT NULL,
    chosen TEXT
  )''',
];

Future<void> _onConfigure(Database db) => db.execute('PRAGMA foreign_keys = ON');

Future<void> _onCreate(Database db, int version) async {
  final b = db.batch();
  for (final s in _schemaV1) {
    b.execute(s);
  }
  await b.commit(noResult: true);
}

Future<Database> openUserDb(DatabaseFactory factory, String path) => factory.openDatabase(
  path,
  options: OpenDatabaseOptions(version: kUserDbVersion, onConfigure: _onConfigure, onCreate: _onCreate),
);

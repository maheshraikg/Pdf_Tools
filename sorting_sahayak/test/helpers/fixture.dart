import 'dart:io';

import 'package:sorting_sahayak/data/directory_builder.dart';
import 'package:sorting_sahayak/data/directory_repo.dart';
import 'package:sorting_sahayak/data/user_db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _init = false;

DatabaseFactory ffiFactory() {
  if (!_init) {
    sqfliteFfiInit();
    _init = true;
  }
  return databaseFactoryFfi;
}

/// In-memory directory DB built from test/fixtures/directory.csv.
Future<Database> fixtureDirectoryDb({bool fts = true}) async {
  final db = await ffiFactory().openDatabase(inMemoryDatabasePath, options: OpenDatabaseOptions(singleInstance: false));
  final records = parseDirectoryCsv(File('test/fixtures/directory.csv').readAsStringSync());
  await writeDirectoryDb(db, records, tryFts: fts, meta: {'source': 'fixture'});
  return db;
}

Future<DirectoryRepo> fixtureRepo({bool fts = true}) async =>
    DirectoryRepo(await fixtureDirectoryDb(fts: fts), useFts: fts);

Future<Database> memoryUserDb() => openUserDb(ffiFactory(), inMemoryDatabasePath);

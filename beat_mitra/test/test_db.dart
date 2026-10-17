import 'package:beat_mitra/data/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Fresh in-memory database with the app schema.
Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: AppDatabase.version,
      onConfigure: AppDatabase.onConfigure,
      onCreate: AppDatabase.onCreate,
      singleInstance: false,
    ),
  );
  return AppDatabase(db);
}

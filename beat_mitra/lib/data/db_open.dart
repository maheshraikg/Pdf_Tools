import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

import '../core/crypto.dart';
import 'db.dart';

const _dbKeyName = 'beat_mitra_db_key_v1';
const _storage = FlutterSecureStorage();

/// Random 256-bit key generated once and kept in Android Keystore-backed
/// secure storage. Never leaves the device.
Future<String> _dbKey() async {
  var key = await _storage.read(key: _dbKeyName);
  if (key == null) {
    key = base64Encode(randomBytes(32));
    await _storage.write(key: _dbKeyName, value: key);
  }
  return key;
}

/// Opens the SQLCipher-encrypted database in app-private storage.
Future<AppDatabase> openEncryptedDatabase() async {
  final dir = await cipher.getDatabasesPath();
  final db = await cipher.openDatabase(
    p.join(dir, 'beat_mitra.db'),
    password: await _dbKey(),
    version: AppDatabase.version,
    onConfigure: AppDatabase.onConfigure,
    onCreate: AppDatabase.onCreate,
    onUpgrade: AppDatabase.onUpgrade,
  );
  return AppDatabase(db);
}

/// Deletes the database file and its key ("Delete all data").
Future<void> deleteEncryptedDatabase() async {
  final dir = await cipher.getDatabasesPath();
  await cipher.deleteDatabase(p.join(dir, 'beat_mitra.db'));
  await _storage.delete(key: _dbKeyName);
}

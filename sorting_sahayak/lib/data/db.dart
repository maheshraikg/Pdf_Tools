/// Opening the two local databases:
/// * the PIN directory (copied from the bundled asset on first launch, or
///   rebuilt by the user from a newer CSV), read-mostly;
/// * the user database (schemes, rules, sessions, learning progress).
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'user_db.dart';

/// Bump when a newer bundled directory DB ships, so it replaces the copy in
/// app storage (unless the user imported their own CSV).
const int kBundledDirectoryVersion = 1;
const String kDirectoryAsset = 'assets/db/pincode_directory.db';
const String kDirectoryFile = 'pincode_directory.db';
const String kUserDbFile = 'sorting_sahayak.db';

class AppDatabases {
  AppDatabases(this.directory, this.user);

  final Database directory;
  final Database user;

  static Future<String> directoryPath() async => p.join(await getDatabasesPath(), kDirectoryFile);

  static Future<AppDatabases> open() async {
    final dir = await openDirectory();
    final user = await openUserDb(databaseFactory, p.join(await getDatabasesPath(), kUserDbFile));
    return AppDatabases(dir, user);
  }

  /// Copies the bundled directory to app storage when missing or outdated.
  static Future<Database> openDirectory() async {
    final path = await directoryPath();
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getBool('dirCustom') ?? false;
    final copied = prefs.getInt('dirAssetVersion') ?? 0;
    final file = File(path);
    if (!file.existsSync() || (!custom && copied < kBundledDirectoryVersion)) {
      await file.parent.create(recursive: true);
      final data = await rootBundle.load(kDirectoryAsset);
      final tmp = File('$path.tmp');
      await tmp.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes), flush: true);
      await tmp.rename(path);
      await prefs.setInt('dirAssetVersion', kBundledDirectoryVersion);
      await prefs.setBool('dirCustom', false);
    }
    return openDatabase(path, readOnly: false, singleInstance: false);
  }
}

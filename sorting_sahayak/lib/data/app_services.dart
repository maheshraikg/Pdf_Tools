/// Wires repositories together and caches the active scheme in memory.
library;

import 'package:flutter/foundation.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'directory_repo.dart';
import 'mismatch.dart';
import 'scheme_repo.dart';
import 'sort_engine.dart';
import 'user_repo.dart';

class AppServices extends ChangeNotifier {
  AppServices({required Database directoryDb, required Database userDb})
    : _directoryDb = directoryDb,
      directory = DirectoryRepo(directoryDb),
      schemes = SchemeRepo(userDb),
      user = UserRepo(userDb);

  Database _directoryDb;
  DirectoryRepo directory;
  final SchemeRepo schemes;
  final UserRepo user;

  ActiveScheme? _active;
  List<String> _categories = const [];
  int _recentsVersion = 0;

  ActiveScheme? get active => _active;
  List<String> get categories => _categories;

  /// Bumped whenever recents / favourites change so lists can refresh.
  int get recentsVersion => _recentsVersion;

  Map<int, ({List<String> districts, List<String> states})>? _regions;

  /// All directory PINs with districts/states (cached; for Learn and DMSL diffs).
  Future<Map<int, ({List<String> districts, List<String> states})>> pinRegions() async =>
      _regions ??= await directory.pinRegions();

  SortEngine get engine => SortEngine(directory, _active);
  MismatchChecker get mismatch => MismatchChecker(directory);

  Future<void> init() async {
    await reloadActive();
    // Load the fuzzy-search key cache in the background.
    directory.warmUp().ignore();
  }

  Future<void> reloadActive() async {
    _active = await schemes.loadActive();
    _categories = await schemes.categories();
    notifyListeners();
  }

  void touchRecents() {
    _recentsVersion++;
    notifyListeners();
  }

  /// Swaps in a rebuilt directory database.
  Future<void> replaceDirectory(Database db) async {
    final old = _directoryDb;
    _directoryDb = db;
    directory = DirectoryRepo(db);
    _regions = null;
    notifyListeners();
    await old.close();
    directory.warmUp().ignore();
  }
}

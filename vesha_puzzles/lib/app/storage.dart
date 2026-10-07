/// Tiny key-value store abstraction (SharedPreferences in the app, memory
/// in tests).
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
  Iterable<String> get keys;
}

class PrefsStore implements KeyValueStore {
  PrefsStore(this._p);
  final SharedPreferences _p;

  static Future<PrefsStore> open() async =>
      PrefsStore(await SharedPreferences.getInstance());

  @override
  String? getString(String key) => _p.getString(key);
  @override
  Future<void> setString(String key, String value) => _p.setString(key, value);
  @override
  Future<void> remove(String key) => _p.remove(key);
  @override
  Iterable<String> get keys => _p.getKeys();
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> data = {};
  @override
  String? getString(String key) => data[key];
  @override
  Future<void> setString(String key, String value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
  @override
  Iterable<String> get keys => data.keys;
}

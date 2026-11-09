import 'dart:convert';

import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/profile.dart';
import '../models/stats.dart';
import 'progress_store.dart';

/// Settings and profiles storage. [HiveAppStore] keeps everything on the
/// device; [MemoryAppStore] is for tests.
abstract class AppStore implements ProgressStore {
  Map<String, dynamic> loadSettings();
  void saveSetting(String key, Object? value);
  List<Profile> loadProfiles();
  void saveProfile(Profile p);
  Future<void> deleteProfile(String id);
}

class MemoryAppStore extends MemoryProgressStore implements AppStore {
  final settings = <String, dynamic>{};
  final profiles = <String, Profile>{};

  @override
  Map<String, dynamic> loadSettings() => Map.of(settings);
  @override
  void saveSetting(String key, Object? value) => settings[key] = value;
  @override
  List<Profile> loadProfiles() => profiles.values.map((p) => Profile.fromJson(p.toJson())).toList();
  @override
  void saveProfile(Profile p) => profiles[p.id] = Profile.fromJson(p.toJson());
  @override
  Future<void> deleteProfile(String id) async {
    profiles.remove(id);
    await clear(id);
  }
}

/// Hive storage. Values are JSON strings; keys of the stats and log boxes
/// start with `<profileId>|` so one child's data can be cleared on its own.
class HiveAppStore implements AppStore {
  HiveAppStore._(this._settings, this._profiles, this._stats, this._log);

  static const _maxLogPerProfile = 5000;

  final Box<String> _settings;
  final Box<String> _profiles;
  final Box<String> _stats;
  final LazyBox<String> _log;
  int _logCounter = 0;

  static Future<HiveAppStore> open() async {
    await Hive.initFlutter('ganita_aata');
    return HiveAppStore._(
      await Hive.openBox<String>('settings'),
      await Hive.openBox<String>('profiles'),
      await Hive.openBox<String>('stats'),
      await Hive.openLazyBox<String>('answer_log'),
    );
  }

  Map<String, dynamic> _decode(String s) => (jsonDecode(s) as Map).cast<String, dynamic>();

  @override
  Map<String, dynamic> loadSettings() => {for (final k in _settings.keys) k as String: jsonDecode(_settings.get(k)!)};

  @override
  void saveSetting(String key, Object? value) => _settings.put(key, jsonEncode(value));

  @override
  List<Profile> loadProfiles() => [for (final v in _profiles.values) Profile.fromJson(_decode(v))];

  @override
  void saveProfile(Profile p) => _profiles.put(p.id, jsonEncode(p.toJson()));

  @override
  Future<void> deleteProfile(String id) async {
    await _profiles.delete(id);
    await clear(id);
  }

  Map<String, T> _load<T>(String profileId, String kind, T Function(Map<String, dynamic>) f, String Function(T) key) {
    final prefix = '$profileId|$kind|';
    final out = <String, T>{};
    for (final k in _stats.keys) {
      if ((k as String).startsWith(prefix)) {
        final v = f(_decode(_stats.get(k)!));
        out[key(v)] = v;
      }
    }
    return out;
  }

  @override
  Map<String, FactStat> loadFacts(String p) => _load(p, 'f', FactStat.fromJson, (v) => v.key);
  @override
  Map<String, TopicStat> loadTopics(String p) => _load(p, 't', TopicStat.fromJson, (v) => v.topicId);
  @override
  Map<String, DayStat> loadDays(String p) => _load(p, 'd', DayStat.fromJson, (v) => v.date);

  @override
  void saveFact(String p, FactStat f) => _stats.put('$p|f|${f.key}', jsonEncode(f.toJson()));
  @override
  void saveTopic(String p, TopicStat t) => _stats.put('$p|t|${t.topicId}', jsonEncode(t.toJson()));
  @override
  void saveDay(String p, DayStat d) => _stats.put('$p|d|${d.date}', jsonEncode(d.toJson()));

  @override
  void appendLog(String p, AnswerRecord r) {
    final ms = r.at.millisecondsSinceEpoch.toString().padLeft(14, '0');
    final n = (_logCounter++ % 1000).toString().padLeft(3, '0');
    _log.put('$p|$ms$n', jsonEncode(r.toJson()));
    _pruneLog(p);
  }

  void _pruneLog(String p) {
    if (_logCounter % 200 != 0) return; // check now and then
    final mine = _log.keys.where((k) => (k as String).startsWith('$p|')).toList()..sort();
    final extra = mine.length - _maxLogPerProfile;
    if (extra > 0) _log.deleteAll(mine.take(extra));
  }

  @override
  Future<void> clear(String p) async {
    await _stats.deleteAll(_stats.keys.where((k) => (k as String).startsWith('$p|')).toList());
    await _log.deleteAll(_log.keys.where((k) => (k as String).startsWith('$p|')).toList());
  }
}

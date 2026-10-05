import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';

/// Minimal persistent key → JSON store. Backed by Hive in the app and by a
/// map in tests. Values are stored as JSON strings so no adapters are needed.
abstract class KvBox {
  Object? get(String key);
  Future<void> put(String key, Object? value);
  Future<void> delete(String key);
  Future<void> clear();
  Iterable<String> get keys;
  Iterable<Object?> get values => keys.map(get);
}

class MemoryBox extends KvBox {
  final _m = <String, String>{};

  @override
  Object? get(String key) => _m[key] == null ? null : jsonDecode(_m[key]!);

  @override
  Future<void> put(String key, Object? value) async => _m[key] = jsonEncode(value);

  @override
  Future<void> delete(String key) async => _m.remove(key);

  @override
  Future<void> clear() async => _m.clear();

  @override
  Iterable<String> get keys => _m.keys.toList();
}

class HiveKvBox extends KvBox {
  HiveKvBox(this._box);

  final Box<String> _box;

  @override
  Object? get(String key) {
    final s = _box.get(key);
    if (s == null) return null;
    try {
      return jsonDecode(s);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> put(String key, Object? value) => _box.put(key, jsonEncode(value));

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear().then((_) {});

  @override
  Iterable<String> get keys => _box.keys.cast<String>();
}

/// All boxes the app uses.
class Stores {
  Stores({
    required this.http,
    required this.prefs,
    required this.bookmarks,
    required this.downloads,
    required this.history,
    required this.inbox,
  });

  /// URL-keyed API responses with timestamps.
  final KvBox http;
  final KvBox prefs;

  /// post id → full post JSON (readable offline).
  final KvBox bookmarks;

  /// file key → [DownloadRecord] JSON.
  final KvBox downloads;

  /// post id → {post, at} for "Continue reading".
  final KvBox history;

  /// notification id → payload.
  final KvBox inbox;

  static Future<Stores> openHive() async {
    await Hive.initFlutter('kspstadk');
    Future<KvBox> open(String name) async => HiveKvBox(await Hive.openBox<String>(name));
    return Stores(
      http: await open('http_cache'),
      prefs: await open('prefs'),
      bookmarks: await open('bookmarks'),
      downloads: await open('downloads'),
      history: await open('history'),
      inbox: await open('inbox'),
    );
  }

  factory Stores.memory() => Stores(
        http: MemoryBox(),
        prefs: MemoryBox(),
        bookmarks: MemoryBox(),
        downloads: MemoryBox(),
        history: MemoryBox(),
        inbox: MemoryBox(),
      );
}

/// A cached value with the time it was stored.
class Cached<T> {
  const Cached(this.value, this.savedAt);

  final T value;
  final DateTime savedAt;

  bool isFresh(Duration maxAge, [DateTime? now]) =>
      (now ?? DateTime.now()).difference(savedAt) < maxAge;
}

/// Timestamped JSON cache on top of a [KvBox].
class ResponseCache {
  ResponseCache(this.box, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final KvBox box;
  final DateTime Function() _now;

  Cached<Object?>? read(String key) {
    final e = box.get(key);
    if (e is! Map) return null;
    final t = e['t'];
    if (t is! int) return null;
    return Cached(e['v'], DateTime.fromMillisecondsSinceEpoch(t));
  }

  Future<void> write(String key, Object? value) =>
      box.put(key, {'t': _now().millisecondsSinceEpoch, 'v': value});

  /// Drops entries older than [maxAge] (bookmarks live in their own box).
  Future<int> prune(Duration maxAge) async {
    final cutoff = _now().subtract(maxAge).millisecondsSinceEpoch;
    var n = 0;
    for (final k in box.keys.toList()) {
      final e = box.get(k);
      if (e is! Map || (e['t'] is int && (e['t'] as int) < cutoff)) {
        await box.delete(k);
        n++;
      }
    }
    return n;
  }
}

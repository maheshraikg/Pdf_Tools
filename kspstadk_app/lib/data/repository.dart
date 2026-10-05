import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../config.dart';
import 'models.dart';
import 'store.dart';
import 'wp_api.dart';

/// One emission of a stale-while-revalidate stream.
class Swr<T> {
  const Swr({this.data, this.error, this.loading = false, this.fromCache = false, this.savedAt});

  final T? data;
  final Object? error;

  /// A network request is still running.
  final bool loading;
  final bool fromCache;
  final DateTime? savedAt;

  bool get hasData => data != null;
}

/// Reads the site through [WpApi] and keeps everything in the local cache.
///
/// Every read emits the cached copy first (instant first paint, works
/// offline) and then, if the copy is missing or stale, the fresh one.
class Repository {
  Repository(this.api, this.stores) : cache = ResponseCache(stores.http);

  final WpApi api;
  final Stores stores;
  final ResponseCache cache;

  static String _key(String path, Map<String, dynamic> q) {
    final keys = q.keys.toList()..sort();
    return '$path?${keys.map((k) => '$k=${q[k]}').join('&')}';
  }

  Stream<Swr<T>> _swr<T>({
    required String key,
    required Duration freshFor,
    required Future<T> Function() fetch,
    required Object? Function(T) encode,
    required T Function(Object?) decode,
    bool force = false,
  }) async* {
    final cached = cache.read(key);
    T? data;
    if (cached != null) {
      try {
        data = decode(cached.value);
      } catch (_) {
        data = null;
      }
    }
    final fresh = cached != null && data != null && cached.isFresh(freshFor);
    if (data != null) {
      yield Swr(data: data, fromCache: true, savedAt: cached!.savedAt, loading: !fresh || force);
      if (fresh && !force) return;
    } else {
      yield Swr<T>(loading: true);
    }
    try {
      final value = await fetch();
      await cache.write(key, encode(value));
      yield Swr(data: value, savedAt: DateTime.now());
    } catch (e) {
      yield Swr(data: data, error: e, fromCache: data != null, savedAt: cached?.savedAt);
    }
  }

  // ---------- Posts ----------

  Stream<Swr<PostPage>> postPage(Map<String, dynamic> query, {bool force = false}) => _swr(
        key: _key('/posts', query),
        freshFor: AppConfig.listFreshFor,
        force: force,
        fetch: () => api.posts(query),
        encode: (p) => p.toJson(),
        decode: (v) => PostPage.fromJson(Map<String, dynamic>.from(v as Map)),
      );

  /// One-shot fetch (used by infinite scroll for page 2+). Falls back to cache.
  Future<PostPage> loadPage(Map<String, dynamic> query) async {
    final key = _key('/posts', query);
    try {
      final page = await api.posts(query);
      await cache.write(key, page.toJson());
      return page;
    } catch (e) {
      final c = cache.read(key);
      if (c != null) return PostPage.fromJson(Map<String, dynamic>.from(c.value as Map));
      rethrow;
    }
  }

  /// Full post. A bookmarked copy counts as cache too.
  Stream<Swr<Post>> post(int id, {bool force = false, Post? preview}) async* {
    final key = '/posts/$id';
    if (cache.read(key) == null) {
      final b = stores.bookmarks.get('$id');
      if (b != null) {
        await cache.write(key, b);
      } else if (preview != null) {
        // Show the list card data (title, image) while the body loads.
        yield Swr(data: preview, loading: true);
      }
    }
    yield* _swr<Post>(
      key: key,
      freshFor: AppConfig.postFreshFor,
      force: force,
      fetch: () => api.post(id),
      encode: (p) => p.toJson(),
      decode: (v) => Post.fromJson(Map<String, dynamic>.from(v as Map)),
    )
        // Keep showing the preview instead of an empty loading state.
        .where((s) => preview == null || s.hasData || s.error != null)
        .map((s) => s.hasData || preview == null ? s : Swr(data: preview, error: s.error));
  }

  /// Resolves an internal link (`https://kspstadk.com/<slug>/`) to a post id.
  Future<int?> postIdForSlug(String slug) async {
    final key = '/slug/$slug';
    final c = cache.read(key);
    if (c?.value is int) return c!.value as int;
    final post = await api.postBySlug(slug);
    if (post == null) return null;
    await cache.write(key, post.id);
    await cache.write('/posts/${post.id}', post.toJson());
    return post.id;
  }

  Future<Post?> page(String slug) async {
    final key = '/pages/$slug';
    try {
      final p = await api.pageBySlug(slug);
      if (p != null) await cache.write(key, p.toJson());
      return p;
    } catch (_) {
      final c = cache.read(key);
      return c == null ? null : Post.fromJson(Map<String, dynamic>.from(c.value as Map));
    }
  }

  // ---------- Categories ----------

  Stream<Swr<List<Category>>> categories({bool force = false}) => _swr(
        key: '/categories',
        freshFor: AppConfig.categoriesFreshFor,
        force: force,
        fetch: api.categories,
        encode: (l) => [for (final c in l) c.toJson()],
        decode: (v) => [for (final c in v as List) Category.fromJson(Map<String, dynamic>.from(c as Map))],
      );

  /// Every post of a (small) category set in one lite request — used for the
  /// Class → Subject → Medium drill-down, which is computed on the device.
  Stream<Swr<List<Post>>> allPostsLite(List<int> categoryIds, {bool force = false}) {
    final q = WpApi.postsQuery(categories: categoryIds, perPage: 100, lite: true);
    return _swr(
      key: _key('/posts-lite', q),
      freshFor: AppConfig.listFreshFor,
      force: force,
      fetch: () async {
        final first = await api.posts(q);
        final all = [...first.posts];
        for (var p = 2; p <= first.totalPages && p <= 5; p++) {
          all.addAll((await api.posts({...q, 'page': p})).posts);
        }
        return all;
      },
      encode: (l) => [for (final p in l) p.toJson()],
      decode: (v) => [for (final p in v as List) Post.fromJson(Map<String, dynamic>.from(p as Map))],
    );
  }

  // ---------- Housekeeping ----------

  /// Approximate size of the response cache in bytes.
  int cacheBytes() {
    var n = 0;
    for (final k in stores.http.keys) {
      n += k.length + utf8.encode(jsonEncode(stores.http.get(k))).length;
    }
    return n;
  }

  Future<void> clearCache() => stores.http.clear();
}

/// True for errors caused by having no connection (as opposed to the server
/// answering with an error).
bool isOfflineError(Object? e) =>
    e is DioException &&
    (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        (e.type == DioExceptionType.unknown && e.response == null));

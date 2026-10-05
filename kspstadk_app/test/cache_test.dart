import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kspstadk_app/data/models.dart';
import 'package:kspstadk_app/data/repository.dart';
import 'package:kspstadk_app/data/store.dart';
import 'package:kspstadk_app/data/wp_api.dart';

import 'helpers/fixtures.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late Stores stores;
  late Repository repo;
  final posts = fixture('posts_embed_20.json') as List;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://kspstadk.com/wp-json/wp/v2'));
    adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    stores = Stores.memory();
    repo = Repository(WpApi(dio), stores);
  });

  final query = WpApi.postsQuery(page: 1, perPage: 20);

  test('network → cache; second read is served from fresh cache without network', () async {
    adapter.onGet('/posts', (s) => s.reply(200, posts, headers: {
          'x-wp-totalpages': ['93'],
          'x-wp-total': ['1853'],
          'content-type': ['application/json'],
        }));
    final first = await repo.postPage(query).toList();
    expect(first.first.loading, isTrue);
    expect(first.first.hasData, isFalse);
    expect(first.last.error, isNull);
    expect(first.last.data!.posts, hasLength(20));
    expect(first.last.data!.totalPages, 93);
    expect(first.last.data!.hasMore, isTrue);

    adapter.onGet('/posts', (s) => s.throws(500, DioException(requestOptions: RequestOptions())));
    final second = await repo.postPage(query).toList();
    expect(second, hasLength(1));
    expect(second.single.fromCache, isTrue);
    expect(second.single.loading, isFalse);
    expect(second.single.data!.posts.first.id, 58077);
  });

  test('stale cache is shown first, then refreshed; errors keep the cached data', () async {
    final old = DateTime.now().subtract(const Duration(days: 1));
    final cache = ResponseCache(stores.http, clock: () => old);
    final page = PostPage(posts: [Post.fromJson(Map<String, dynamic>.from(posts[1] as Map))], page: 1, totalPages: 1);
    final keys = query.keys.toList()..sort();
    await cache.write('/posts?${keys.map((k) => '$k=${query[k]}').join('&')}', page.toJson());

    adapter.onGet('/posts', (s) => s.throws(0, DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline')));
    final events = await repo.postPage(query).toList();
    expect(events.first.fromCache, isTrue);
    expect(events.first.loading, isTrue);
    expect(events.last.error, isNotNull);
    expect(isOfflineError(events.last.error), isTrue);
    expect(events.last.data!.posts.single.id, 58069, reason: 'cached data survives the failed refresh');
  });

  test('bookmarked post is readable offline', () async {
    final p = Post.fromJson(Map<String, dynamic>.from(posts[0] as Map));
    await stores.bookmarks.put('${p.id}', p.toJson());
    adapter.onGet('/posts/${p.id}', (s) => s.throws(0, DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline')));
    final events = await repo.post(p.id).toList();
    expect(events.first.data!.content, isNotEmpty);
    expect(events.last.data!.title, p.title);
  });

  test('page past the end returns an empty last page', () async {
    adapter.onGet('/posts', (s) => s.reply(400, {'code': 'rest_post_invalid_page_number'}));
    final page = await WpApi(dio).posts(WpApi.postsQuery(page: 99));
    expect(page.posts, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('ResponseCache.prune drops old entries', () async {
    var now = DateTime(2026, 1, 1);
    final cache = ResponseCache(stores.http, clock: () => now);
    await cache.write('a', 1);
    now = DateTime(2026, 3, 1);
    await cache.write('b', 2);
    expect(await cache.prune(const Duration(days: 30)), 1);
    expect(cache.read('a'), isNull);
    expect(cache.read('b')!.value, 2);
  });
}

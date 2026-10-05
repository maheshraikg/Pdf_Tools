import 'package:dio/dio.dart';

import '../config.dart';
import 'models.dart';

/// Thin client for the public WordPress REST API (`/wp-json/wp/v2`).
/// Read-only: the app never authenticates or writes.
class WpApi {
  WpApi([Dio? dio])
      : dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBase,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
              responseType: ResponseType.json,
            ));

  final Dio dio;

  static const embed = 'wp:featuredmedia,wp:term';
  static const listFields =
      'id,date,modified,slug,link,title,excerpt,categories,tags,featured_media,featured_image_src,author_info,_links,_embedded';
  static const postFields = '$listFields,content';
  static const liteFields = 'id,date,modified,slug,link,title,categories,tags,featured_image_src';

  /// Query string used both for the request and as the cache key.
  static Map<String, dynamic> postsQuery({
    int page = 1,
    int perPage = AppConfig.pageSize,
    List<int>? categories,
    List<int>? include,
    List<int>? exclude,
    String? search,
    String? after,
    bool lite = false,
  }) =>
      {
        'page': page,
        'per_page': perPage,
        if (categories != null && categories.isNotEmpty) 'categories': categories.join(','),
        if (include != null && include.isNotEmpty) 'include': include.join(','),
        if (exclude != null && exclude.isNotEmpty) 'exclude': exclude.join(','),
        if (search != null && search.isNotEmpty) 'search': search,
        'after': ?after,
        if (include != null && include.isNotEmpty) 'orderby': 'include',
        if (lite) '_fields': liteFields else ...{'_embed': embed, '_fields': listFields},
      };

  Future<PostPage> posts(Map<String, dynamic> query, {CancelToken? cancel}) async {
    try {
      final r = await dio.get<List<dynamic>>('/posts', queryParameters: query, cancelToken: cancel);
      final page = query['page'] as int? ?? 1;
      final totalPages = int.tryParse(r.headers.value('x-wp-totalpages') ?? '') ?? page;
      final total = int.tryParse(r.headers.value('x-wp-total') ?? '') ?? 0;
      return PostPage(
        posts: [for (final p in r.data ?? const []) Post.fromJson(Map<String, dynamic>.from(p as Map))],
        page: page,
        totalPages: totalPages,
        total: total,
      );
    } on DioException catch (e) {
      // WordPress answers 400 `rest_post_invalid_page_number` past the end.
      if (e.response?.statusCode == 400 && (query['page'] as int? ?? 1) > 1) {
        final page = query['page'] as int;
        return PostPage(posts: const [], page: page, totalPages: page - 1);
      }
      rethrow;
    }
  }

  Future<Post> post(int id, {CancelToken? cancel}) async {
    final r = await dio.get<Map<String, dynamic>>('/posts/$id',
        queryParameters: {'_embed': embed, '_fields': postFields}, cancelToken: cancel);
    return Post.fromJson(r.data!);
  }

  Future<Post?> postBySlug(String slug, {CancelToken? cancel}) async {
    final r = await dio.get<List<dynamic>>('/posts',
        queryParameters: {'slug': slug, '_embed': embed, '_fields': postFields}, cancelToken: cancel);
    final list = r.data ?? const [];
    return list.isEmpty ? null : Post.fromJson(Map<String, dynamic>.from(list.first as Map));
  }

  /// A WordPress page (About, Privacy policy …) rendered as a [Post].
  Future<Post?> pageBySlug(String slug) async {
    final r = await dio.get<List<dynamic>>('/pages',
        queryParameters: {'slug': slug, '_fields': 'id,date,modified,slug,link,title,content'});
    final list = r.data ?? const [];
    return list.isEmpty ? null : Post.fromJson(Map<String, dynamic>.from(list.first as Map));
  }

  /// All non-empty categories (the site has ~94, so at most one or two pages).
  Future<List<Category>> categories() async {
    final out = <Category>[];
    var page = 1;
    while (true) {
      final r = await dio.get<List<dynamic>>('/categories', queryParameters: {
        'per_page': 100,
        'page': page,
        'hide_empty': true,
        '_fields': 'id,name,slug,parent,count',
      });
      out.addAll([for (final c in r.data ?? const []) Category.fromJson(Map<String, dynamic>.from(c as Map))]);
      final totalPages = int.tryParse(r.headers.value('x-wp-totalpages') ?? '') ?? 1;
      if (page >= totalPages) break;
      page++;
    }
    return out;
  }
}

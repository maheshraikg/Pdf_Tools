import '../core/text_utils.dart';

/// A term attached to a post via `_embedded['wp:term']`.
class TermRef {
  const TermRef({required this.id, required this.name, required this.slug, required this.taxonomy});

  final int id;
  final String name;
  final String slug;
  final String taxonomy;

  factory TermRef.fromJson(Map<String, dynamic> j) => TermRef(
        id: j['id'] as int,
        name: plainText(j['name'] as String?),
        slug: j['slug'] as String? ?? '',
        taxonomy: j['taxonomy'] as String? ?? 'category',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug, 'taxonomy': taxonomy};
}

/// A WordPress post as the app needs it. Built from the REST JSON (with or
/// without `_embed`) and round-trips through [toJson] for the offline cache.
class Post {
  const Post({
    required this.id,
    required this.date,
    required this.modified,
    required this.slug,
    required this.link,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.categoryIds,
    required this.tagIds,
    required this.terms,
    this.imageUrl,
    this.thumbUrl,
    this.author,
  });

  final int id;
  final DateTime date;
  final DateTime modified;
  final String slug;
  final String link;

  /// Plain text, entities decoded.
  final String title;

  /// Plain text, without the "Read more" button.
  final String excerpt;

  /// Rendered HTML. Empty when the list request didn't ask for content.
  final String content;
  final List<int> categoryIds;
  final List<int> tagIds;
  final List<TermRef> terms;

  /// Card-sized image (`medium_large` → `large` → full).
  final String? imageUrl;

  /// Small thumbnail (`medium` → `thumbnail`).
  final String? thumbUrl;
  final String? author;

  bool get hasContent => content.isNotEmpty;
  List<TermRef> get categories => terms.where((t) => t.taxonomy == 'category').toList();
  List<TermRef> get tags => terms.where((t) => t.taxonomy == 'post_tag').toList();

  factory Post.fromJson(Map<String, dynamic> j) {
    final embedded = j['_embedded'] as Map<String, dynamic>?;
    String? image;
    String? thumb;
    final media = embedded?['wp:featuredmedia'];
    if (media is List && media.isNotEmpty && media.first is Map) {
      final m = media.first as Map<String, dynamic>;
      final sizes = (m['media_details'] as Map?)?['sizes'] as Map?;
      String? size(String name) => (sizes?[name] as Map?)?['source_url'] as String?;
      image = size('medium_large') ?? size('large') ?? m['source_url'] as String?;
      thumb = size('medium') ?? size('thumbnail') ?? image;
    }
    image ??= _nonEmpty(j['featured_image_src']);
    thumb ??= image;

    final terms = <TermRef>[];
    final termGroups = embedded?['wp:term'];
    if (termGroups is List) {
      for (final group in termGroups) {
        if (group is List) {
          for (final t in group) {
            if (t is Map<String, dynamic> && t['id'] is int) terms.add(TermRef.fromJson(t));
          }
        }
      }
    } else if (j['terms'] is List) {
      for (final t in j['terms'] as List) {
        terms.add(TermRef.fromJson(Map<String, dynamic>.from(t as Map)));
      }
    }

    String rendered(String key) {
      final v = j[key];
      if (v is Map) return v['rendered'] as String? ?? '';
      return v as String? ?? '';
    }

    final authorInfo = j['author_info'];
    return Post(
      id: j['id'] as int,
      date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
      modified: DateTime.tryParse(j['modified'] as String? ?? j['date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      slug: j['slug'] as String? ?? '',
      link: j['link'] as String? ?? '',
      title: plainText(rendered('title')),
      excerpt: j['excerpt_plain'] as String? ?? cleanExcerpt(rendered('excerpt')),
      content: rendered('content'),
      categoryIds: _ints(j['categories']),
      tagIds: _ints(j['tags']),
      terms: terms,
      imageUrl: image ?? _nonEmpty(j['image']),
      thumbUrl: thumb ?? _nonEmpty(j['thumb']),
      author: authorInfo is Map ? authorInfo['display_name'] as String? : j['author_name'] as String?,
    );
  }

  /// Compact JSON for the cache (not the WordPress shape, but [Post.fromJson]
  /// reads both).
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'modified': modified.toIso8601String(),
        'slug': slug,
        'link': link,
        'title': title,
        'excerpt_plain': excerpt,
        'content': content,
        'categories': categoryIds,
        'tags': tagIds,
        'terms': [for (final t in terms) t.toJson()],
        'image': imageUrl,
        'thumb': thumbUrl,
        'author_name': author,
      };

  /// Same post without the (large) body, for list caches.
  Post withoutContent() => Post(
        id: id,
        date: date,
        modified: modified,
        slug: slug,
        link: link,
        title: title,
        excerpt: excerpt,
        content: '',
        categoryIds: categoryIds,
        tagIds: tagIds,
        terms: terms,
        imageUrl: imageUrl,
        thumbUrl: thumbUrl,
        author: author,
      );
}

class Category {
  const Category({required this.id, required this.name, required this.slug, required this.parent, required this.count});

  final int id;
  final String name;
  final String slug;
  final int parent;
  final int count;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: plainText(j['name'] as String?),
        slug: j['slug'] as String? ?? '',
        parent: j['parent'] as int? ?? 0,
        count: j['count'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug, 'parent': parent, 'count': count};

  /// True when the name is written in Kannada script.
  bool get isKannada => RegExp(r'[ಀ-೿]').hasMatch(name);
}

/// One page of a paginated list.
class PostPage {
  const PostPage({required this.posts, required this.page, required this.totalPages, this.total = 0});

  final List<Post> posts;
  final int page;
  final int totalPages;
  final int total;

  bool get hasMore => page < totalPages;

  Map<String, dynamic> toJson() => {
        'posts': [for (final p in posts) p.toJson()],
        'page': page,
        'totalPages': totalPages,
        'total': total,
      };

  factory PostPage.fromJson(Map<String, dynamic> j) => PostPage(
        posts: [for (final p in j['posts'] as List) Post.fromJson(Map<String, dynamic>.from(p as Map))],
        page: j['page'] as int,
        totalPages: j['totalPages'] as int,
        total: j['total'] as int? ?? 0,
      );
}

String? _nonEmpty(Object? v) => v is String && v.isNotEmpty ? v : null;

List<int> _ints(Object? v) => v is List ? [for (final e in v) if (e is int) e] : const [];

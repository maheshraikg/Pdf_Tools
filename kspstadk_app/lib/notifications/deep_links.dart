import '../config.dart';

/// Where a deep link, App Link or notification should take the user.
sealed class LinkTarget {
  const LinkTarget();
}

class PostTarget extends LinkTarget {
  const PostTarget(this.id);
  final int id;
}

/// A kspstadk.com URL to resolve (post slug, category, page).
class UrlTarget extends LinkTarget {
  const UrlTarget(this.url);
  final String url;
}

class HomeTarget extends LinkTarget {
  const HomeTarget();
}

/// Parses `https://kspstadk.com/<slug>/`, `https://kspstadk.com/?p=123`,
/// `kspstadk://post/123`.
LinkTarget? parseDeepLink(Uri uri) {
  if (uri.scheme == 'kspstadk') {
    final segs = [uri.host, ...uri.pathSegments].where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && segs[0] == 'post') {
      final id = int.tryParse(segs[1]);
      if (id != null) return PostTarget(id);
    }
    return const HomeTarget();
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') && AppConfig.siteHosts.contains(uri.host)) {
    final p = int.tryParse(uri.queryParameters['p'] ?? '');
    if (p != null) return PostTarget(p);
    if (uri.pathSegments.where((s) => s.isNotEmpty).isEmpty) return const HomeTarget();
    return UrlTarget(uri.replace(scheme: 'https').toString());
  }
  return null;
}

/// Target for an FCM data payload: `{post_id, url}` (as sent by
/// tool/notify.py).
LinkTarget? notificationTarget(Map<String, dynamic> data) {
  final id = int.tryParse('${data['post_id'] ?? ''}');
  if (id != null) return PostTarget(id);
  final url = data['url'];
  if (url is String) return parseDeepLink(Uri.parse(url));
  return null;
}

/// FCM topic names the app subscribes to. Keep in sync with tool/notify.py.
class Topics {
  Topics._();

  static const all = 'all';
  static const lba = 'lba';
  static const info = 'info';
  static const study = 'study';
  static const quiz = 'quiz';
  static String forClass(int n) => 'class_$n';

  static const general = [all, lba, info, study, quiz];
}

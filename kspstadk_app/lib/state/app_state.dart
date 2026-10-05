import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../data/site_config.dart';
import '../data/store.dart';
import '../downloads/download_manager.dart';

/// User preferences (persisted in the `prefs` box).
class Settings extends ChangeNotifier {
  Settings(this._box);

  final KvBox _box;

  Locale get locale => Locale(_box.get('locale') as String? ?? 'kn');
  ThemeMode get themeMode => ThemeMode.values.firstWhere(
        (m) => m.name == _box.get('theme'),
        orElse: () => ThemeMode.system,
      );

  /// FCM topics the user subscribed to. Defaults: everything new + LBA.
  Set<String> get topics =>
      {for (final t in (_box.get('topics') as List? ?? const ['all', 'lba'])) t as String};

  List<String> get recentSearches => [for (final s in _box.get('recent_searches') as List? ?? const []) s as String];

  bool get pdfNightMode => _box.get('pdf_night') == true;

  int get downloadsCompleted => _box.get('downloads_completed') as int? ?? 0;
  bool get reviewAsked => _box.get('review_asked') == true;

  Future<void> setLocale(Locale l) async {
    await _box.put('locale', l.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    await _box.put('theme', m.name);
    notifyListeners();
  }

  Future<void> setTopics(Set<String> t) async {
    await _box.put('topics', t.toList()..sort());
    notifyListeners();
  }

  Future<void> addRecentSearch(String q) async {
    final query = q.trim();
    if (query.length < 2) return;
    final list = [query, ...recentSearches.where((s) => s.toLowerCase() != query.toLowerCase())].take(10).toList();
    await _box.put('recent_searches', list);
    notifyListeners();
  }

  Future<void> clearRecentSearches() async {
    await _box.put('recent_searches', const <String>[]);
    notifyListeners();
  }

  Future<void> setPdfNightMode(bool v) async {
    await _box.put('pdf_night', v);
    notifyListeners();
  }

  Future<int> incrementDownloads() async {
    final n = downloadsCompleted + 1;
    await _box.put('downloads_completed', n);
    return n;
  }

  Future<void> markReviewAsked() => _box.put('review_asked', true);
}

/// Saved posts with their full content (readable offline).
class Bookmarks extends ChangeNotifier {
  Bookmarks(this._box);

  final KvBox _box;

  bool contains(int id) => _box.get('$id') != null;

  List<Post> get all {
    final list = [
      for (final v in _box.values)
        if (v is Map) Post.fromJson(Map<String, dynamic>.from(v)),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<bool> toggle(Post p) async {
    if (contains(p.id)) {
      await _box.delete('${p.id}');
      notifyListeners();
      return false;
    }
    await _box.put('${p.id}', p.toJson());
    notifyListeners();
    return true;
  }

  /// Keeps a bookmarked copy in sync when a fresher version is loaded.
  Future<void> refresh(Post p) async {
    if (contains(p.id) && p.hasContent) await _box.put('${p.id}', p.toJson());
  }
}

/// "Continue reading": the last posts the user opened.
class History extends ChangeNotifier {
  History(this._box);

  final KvBox _box;

  List<Post> recent([int n = 5]) {
    final entries = [
      for (final v in _box.values)
        if (v is Map) v,
    ]..sort((a, b) => (b['at'] as int).compareTo(a['at'] as int));
    return [for (final e in entries.take(n)) Post.fromJson(Map<String, dynamic>.from(e['post'] as Map))];
  }

  Future<void> add(Post p) async {
    await _box.put('${p.id}', {'at': DateTime.now().millisecondsSinceEpoch, 'post': p.withoutContent().toJson()});
    final keys = _box.keys.toList();
    if (keys.length > 30) {
      final sorted = [for (final k in keys) MapEntry(k, (_box.get(k) as Map)['at'] as int)]
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final e in sorted.take(keys.length - 30)) {
        await _box.delete(e.key);
      }
    }
    notifyListeners();
  }
}

/// A received push notification.
class InboxItem {
  InboxItem({required this.id, required this.title, required this.body, required this.postId, required this.at, this.read = false});

  final String id;
  final String title;
  final String body;
  final int? postId;
  final DateTime at;
  final bool read;

  factory InboxItem.fromJson(Map<String, dynamic> j) => InboxItem(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        postId: j['post_id'] as int?,
        at: DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
        read: j['read'] == true,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'body': body, 'post_id': postId, 'at': at.millisecondsSinceEpoch, 'read': read};
}

class Inbox extends ChangeNotifier {
  Inbox(this._box);

  final KvBox _box;

  List<InboxItem> get items => [
        for (final v in _box.values)
          if (v is Map) InboxItem.fromJson(Map<String, dynamic>.from(v)),
      ]..sort((a, b) => b.at.compareTo(a.at));

  int get unread => items.where((i) => !i.read).length;

  Future<void> add(InboxItem item) async {
    await _box.put(item.id, item.toJson());
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final v = _box.get(id);
    if (v is Map) {
      await _box.put(id, {...Map<String, dynamic>.from(v), 'read': true});
      notifyListeners();
    }
  }

  Future<void> clear() async {
    await _box.clear();
    notifyListeners();
  }
}

/// Everything screens need, created once in `main()`.
class AppServices {
  AppServices({
    required this.stores,
    required this.repo,
    required this.config,
    required this.settings,
    required this.bookmarks,
    required this.history,
    required this.inbox,
    required this.downloads,
  });

  final Stores stores;
  final Repository repo;
  final SiteConfig config;
  final Settings settings;
  final Bookmarks bookmarks;
  final History history;
  final Inbox inbox;
  final DownloadManager downloads;
}

class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.services, required super.child});

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing');
    return scope!.services;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => services != oldWidget.services;
}

extension AppContext on BuildContext {
  AppServices get app => AppScope.of(this);
}

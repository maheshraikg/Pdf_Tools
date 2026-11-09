import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import 'models.dart';
import 'store.dart';

/// A labelled group of category ids (twins merged), e.g. "Science" =
/// ವಿಜ್ಞಾನ (469) + SCIENCE (468).
class Concept {
  const Concept({required this.key, required this.kn, required this.en, required this.ids, this.color, this.icon});

  final String key;
  final String kn;
  final String en;
  final List<int> ids;
  final Color? color;
  final String? icon;

  String label(Locale locale) => locale.languageCode == 'en' ? en : kn;

  factory Concept.fromJson(Map<String, dynamic> j) => Concept(
        key: j['key'] as String? ?? '${j['n'] ?? j['en']}',
        kn: j['kn'] as String? ?? '${j['n']} ನೇ ತರಗತಿ',
        en: j['en'] as String? ?? 'Class ${j['n']}',
        ids: [for (final i in j['ids'] as List? ?? const []) i as int],
        color: parseHexColor(j['color'] as String?),
        icon: j['icon'] as String?,
      );
}

class HomeSection {
  const HomeSection({required this.type, this.kn, this.en, this.ids = const [], this.count = 6});

  /// latest | tiles | classes | continue | popular | category | join
  final String type;
  final String? kn;
  final String? en;
  final List<int> ids;
  final int count;

  factory HomeSection.fromJson(Map<String, dynamic> j) => HomeSection(
        type: j['type'] as String,
        kn: j['kn'] as String?,
        en: j['en'] as String?,
        ids: [for (final i in j['ids'] as List? ?? const []) i as int],
        count: j['count'] as int? ?? 6,
      );
}

/// Parsed `assets/config/home_sections.json`.
class SiteConfig {
  const SiteConfig({
    required this.classes,
    required this.subjects,
    required this.mediums,
    required this.tiles,
    required this.sections,
    required this.popularPostIds,
    required this.whatsappUrl,
    required this.telegramUrl,
    required this.toolsUrl,
    required this.quizIds,
    this.twins = const [],
  });

  final List<Concept> classes;
  final List<Concept> subjects;
  final List<Concept> mediums;
  final List<Concept> tiles;
  final List<HomeSection> sections;
  final List<int> popularPostIds;
  final String? whatsappUrl;
  final String? telegramUrl;
  final String? toolsUrl;

  /// Categories whose posts are quizzes.
  final List<int> quizIds;

  /// Extra Kannada/English twin categories to show as one entry.
  final List<List<int>> twins;

  factory SiteConfig.fromJson(Map<String, dynamic> j) {
    List<Concept> concepts(String k) =>
        [for (final c in j[k] as List? ?? const []) Concept.fromJson(Map<String, dynamic>.from(c as Map))];
    final join = j['join'] as Map? ?? const {};
    final tiles = concepts('tiles');
    return SiteConfig(
      classes: concepts('classes'),
      subjects: concepts('subjects'),
      mediums: concepts('mediums'),
      tiles: tiles,
      sections: [for (final s in j['sections'] as List? ?? const []) HomeSection.fromJson(Map<String, dynamic>.from(s as Map))],
      popularPostIds: [for (final p in j['popular'] as List? ?? const []) (p as Map)['post'] as int],
      whatsappUrl: join['whatsapp'] as String?,
      telegramUrl: join['telegram'] as String?,
      toolsUrl: j['tools_url'] as String?,
      twins: [for (final t in j['twins'] as List? ?? const []) [for (final i in t as List) i as int]],
      quizIds: tiles.firstWhere((t) => t.key == 'quiz', orElse: () => const Concept(key: 'quiz', kn: '', en: '', ids: [444, 490])).ids,
    );
  }

  static SiteConfig parse(String source) => SiteConfig.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Bundled config, replaced by a cached remote copy when one is available.
  static Future<SiteConfig> load(KvBox prefs) async {
    final bundled = await rootBundle.loadString(AppConfig.homeConfigAsset);
    final remote = prefs.get('remote_home_config');
    if (remote is String) {
      try {
        return parse(remote);
      } catch (_) {/* fall back to bundled */}
    }
    return parse(bundled);
  }

  /// Fetches the latest config from GitHub in the background. Applied on the
  /// next start so the home screen never jumps under the user's finger.
  static Future<void> refreshRemote(KvBox prefs, {Dio? dio}) async {
    if (!AppConfig.remoteHomeConfig) return;
    try {
      final r = await (dio ?? Dio()).get<String>(AppConfig.remoteHomeConfigUrl,
          options: Options(responseType: ResponseType.plain, receiveTimeout: const Duration(seconds: 10)));
      final body = r.data;
      if (body != null) {
        parse(body); // validate before storing
        await prefs.put('remote_home_config', body);
      }
    } catch (_) {/* offline or not published yet: keep what we have */}
  }

  Concept? subjectOf(Post p) => _first(subjects, p);
  Concept? mediumOf(Post p) => _first(mediums, p);
  Concept? classOf(Post p) => _first(classes, p);

  static Concept? _first(List<Concept> list, Post p) {
    for (final c in list) {
      if (c.ids.any(p.categoryIds.contains)) return c;
    }
    return null;
  }
}

/// Merges Kannada/English twin categories that aren't in the config, so the
/// "All categories" list shows each topic once.
class CategoryGroup {
  CategoryGroup(this.members);

  final List<Category> members;

  List<int> get ids => [for (final c in members) c.id];
  int get count => members.map((c) => c.count).fold(0, (a, b) => a > b ? a : b);

  String label(Locale locale) {
    final kn = members.where((c) => c.isKannada);
    final en = members.where((c) => !c.isKannada);
    final pick = locale.languageCode == 'en'
        ? (en.isNotEmpty ? en.first : kn.first)
        : (kn.isNotEmpty ? kn.first : en.first);
    return _title(pick.name);
  }

  static String _title(String s) {
    if (RegExp(r'[ಀ-೿]').hasMatch(s) || s != s.toUpperCase()) return s.trim();
    return s.trim().split(RegExp(r'\s+')).map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase()).join(' ');
  }
}

/// Categories not covered by any configured concept (tiles, classes,
/// subjects, mediums), with the twins listed under `twins` in the config
/// merged into one entry. New categories created on the site show up here
/// automatically.
List<CategoryGroup> otherCategories(List<Category> all, SiteConfig cfg) {
  final used = <int>{
    for (final c in [...cfg.tiles, ...cfg.classes, ...cfg.subjects, ...cfg.mediums]) ...c.ids,
  };
  final byId = {for (final c in all) c.id: c};
  final groups = <CategoryGroup>[];
  for (final twin in cfg.twins) {
    final members = [for (final id in twin) if (byId[id] != null && !used.contains(id)) byId[id]!];
    if (members.isEmpty) continue;
    used.addAll(members.map((c) => c.id));
    if (members.any((c) => c.count > 0)) groups.add(CategoryGroup(members));
  }
  for (final c in all) {
    if (!used.contains(c.id) && c.count > 0) groups.add(CategoryGroup([c]));
  }
  groups.sort((a, b) => b.count.compareTo(a.count));
  return groups;
}

Color? parseHexColor(String? hex) {
  if (hex == null || !hex.startsWith('#') || hex.length != 7) return null;
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}

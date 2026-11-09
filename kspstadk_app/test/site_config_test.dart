import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/data/models.dart';
import 'package:kspstadk_app/data/site_config.dart';

import 'helpers/fixtures.dart';

void main() {
  final cfg = SiteConfig.parse(File('assets/config/home_sections.json').readAsStringSync());
  final cats = [for (final c in fixture('categories.json') as List) Category.fromJson(Map<String, dynamic>.from(c as Map))];
  final byId = {for (final c in cats) c.id: c};

  test('every configured category id exists on the site', () {
    for (final concept in [...cfg.classes, ...cfg.subjects, ...cfg.mediums, ...cfg.tiles]) {
      for (final id in concept.ids) {
        expect(byId.containsKey(id), isTrue, reason: '${concept.en} → $id');
      }
    }
    for (final twin in cfg.twins) {
      for (final id in twin) {
        expect(byId.containsKey(id), isTrue, reason: 'twin $id');
      }
    }
  });

  test('home config has the expected shape', () {
    expect(cfg.classes, hasLength(10));
    expect(cfg.classes[3].label(const Locale('kn')), '4 ನೇ ತರಗತಿ');
    expect(cfg.classes[3].label(const Locale('en')), 'Class 4');
    expect(cfg.subjects.map((s) => s.key), contains('science'));
    expect(cfg.sections.first.type, 'latest');
    expect(cfg.popularPostIds, isNotEmpty);
    expect(cfg.quizIds, contains(444));
  });

  test('class / subject / medium are derived from a post\'s categories', () {
    final raw = fixture('posts_embed_20.json') as List;
    final p = Post.fromJson(Map<String, dynamic>.from(raw.firstWhere((p) => p['id'] == 57951) as Map));
    expect(cfg.classOf(p)!.key, '4');
    expect(cfg.subjectOf(p), isNull);
  });

  test('otherCategories merges configured twins and hides configured concepts', () {
    final others = otherCategories(cats, cfg);
    final ids = others.expand((g) => g.ids).toSet();
    expect(ids.contains(1341), isFalse, reason: 'LBA is a tile');
    expect(ids.contains(469), isFalse, reason: 'Science is a subject');
    final odu = others.firstWhere((g) => g.ids.contains(413));
    expect(odu.ids, containsAll([413, 412]));
    expect(odu.label(const Locale('kn')), 'ಓದು ಕರ್ನಾಟಕ');
    expect(odu.label(const Locale('en')), 'Odu Karnataka');
    expect(others.every((g) => g.count > 0), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/content/links.dart';
import 'package:kspstadk_app/content/post_content.dart';

import 'helpers/fixtures.dart';

String postBody(int id) {
  final raw = fixture('posts_embed_20.json') as List;
  return (raw.firstWhere((p) => p['id'] == id) as Map)['content']['rendered'] as String;
}

void main() {
  test('LBA kl-grid → lesson cards with Questions/Answers Drive files', () {
    final c = parsePostContent(fixtureContent('deep_57911.json'));
    final grid = c.blocks.whereType<LessonGridBlock>().single;
    expect(grid.lessons, hasLength(33));
    expect(grid.title, contains('10ನೇ ತರಗತಿ ಸಮಾಜ ವಿಜ್ಞಾನ'));
    final first = grid.lessons.first;
    expect(first.number, '01');
    expect(first.title, 'The Advent of Europeans to India');
    expect(first.files, hasLength(2));
    expect(first.files[0].label, 'ಪ್ರಶ್ನೆಗಳು');
    expect(first.files[0].isAnswer, isFalse);
    expect(first.files[1].isAnswer, isTrue);
    expect(first.files[0].link.kind, LinkKind.drive);
    expect(first.files[0].link.fileId, '1KI2Awx4EdeHdb98YM4iBQzg6pF_v22RQ');
    expect(c.files, hasLength(66));
  });

  test('kspstadk-related → rainbow related items', () {
    final c = parsePostContent(fixtureContent('deep_57911.json'));
    final rel = c.related!;
    expect(rel.title, 'ಇವುಗಳನ್ನೂ ಓದಿ');
    expect(rel.items.first.title, '10ನೇ ತರಗತಿ ಸಮಾಜ ವಿಜ್ಞಾನ (ಕನ್ನಡ ಮಾಧ್ಯಮ) LBA ಪ್ರಶ್ನಾ ಕೋಶ – ಅಧ್ಯಾಯವಾರು');
    expect(rel.items.first.url, 'https://kspstadk.com/class-10-social-science-kannada-medium-lba-question-bank/');
    expect(rel.items.first.badge, 'SS');
  });

  test('table before the grid becomes a native table', () {
    final c = parsePostContent(fixtureContent('deep_57911.json'));
    final t = c.blocks.whereType<TableBlock>().first;
    expect(t.rows.length, greaterThan(30));
    expect(t.rows.last, contains('Consumer Education and Protection'));
  });

  test('ksp-hub → hero + grouped subject tiles linking to posts', () {
    final c = parsePostContent(postBody(57951));
    final hero = c.blocks.whereType<HeroBlock>().single;
    expect(hero.title, contains('4ನೇ ತರಗತಿ LBA ಪ್ರಶ್ನಾ ಕೋಶ'));
    expect(hero.stats.first, ('10', 'ಪ್ರಶ್ನಾ ಕೋಶಗಳು'));
    final hub = c.blocks.whereType<HubBlock>().single;
    expect(hub.groups.first.title, 'ಭಾಷಾ ವಿಷಯಗಳು');
    expect(hub.groups.first.colorKey, 'g-lang');
    final card = hub.groups.first.cards.first;
    expect(card.name, 'ಕನ್ನಡ');
    expect(card.url, 'https://kspstadk.com/class-4-kannada-lba-question-bank/');
    expect(card.chip, '17 ಪಾಠಗಳು');
  });

  test('Ultimate Blocks Drive buttons → download lists under their headings', () {
    final c = parsePostContent(fixtureContent('deep_34226.json'));
    final lists = c.blocks.whereType<DownloadListBlock>().toList();
    expect(lists, isNotEmpty);
    expect(lists.first.heading, '4 ನೇ ತರಗತಿ');
    expect(lists.first.files.first.label, 'ಕನ್ನಡ ನೋಟ್ಸ್ 1');
    expect(lists.first.files.first.link.fileId, '1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1');
    expect(c.files.length, 81);
  });

  test('WhatsApp group button → join block', () {
    final c = parsePostContent(fixtureContent('deep_31730.json'));
    final joins = c.blocks.whereType<JoinBlock>().toList();
    expect(joins.map((j) => j.link.kind), contains(LinkKind.whatsappGroup));
    expect(joins.first.label, contains('ವಾಟ್ಸಾಪ್'));
  });

  test('YouTube iframe → video block', () {
    final c = parsePostContent(fixtureContent('deep_24121.json'));
    expect(c.blocks.whereType<YoutubeBlock>().map((b) => b.videoId), contains('ovjQExoi6Z4'));
  });

  test('"sec rel" related variant and share widget removal', () {
    final c = parsePostContent(postBody(58008));
    final rel = c.related!;
    expect(rel.items.map((i) => i.url), contains('https://kspstadk.com/lba-login/'));
    expect(rel.items.first.title, 'LBA ಲಾಗಿನ್‌ನಲ್ಲಿ ಸೇತುಬಂಧ ಪ್ರೀ-ಟೆಸ್ಟ್ ಗ್ರೇಡ್ ಎಂಟ್ರಿ ಮಾಡುವ ಸರಳ ಹಂತಗಳು');
    final html = c.blocks.whereType<HtmlBlock>().map((b) => b.html).join();
    expect(html, isNot(contains('wa.me/?text')));
    expect(html, isNot(contains('<script')));
    expect(html, isNot(contains('<style')));
    expect(c.blocks.whereType<AccordionBlock>(), isNotEmpty, reason: 'FAQ <details>');
  });

  test('"also-read" related variant', () {
    final c = parsePostContent(fixtureContent('deep_56294.json'));
    final rel = c.related!;
    expect(rel.title, contains('ಇದನ್ನೂ ಓದಿ'));
    expect(rel.items.first.url, 'https://kspstadk.com/ssp-pre-matric-scholarship-2026-27/');
    expect(rel.items.first.title, isNot(startsWith('📌')));
  });

  test('interactive calculator post is flagged', () {
    final c = parsePostContent(fixtureContent('deep_55546.json'));
    expect(c.blocks.first, isA<InteractiveToolBlock>());
    final plain = parsePostContent(fixtureContent('deep_57911.json'));
    expect(plain.blocks.whereType<InteractiveToolBlock>(), isEmpty);
  });

  test('shortcodes and comments are stripped, entities stay escaped', () {
    final c = parsePostContent('<p>A [ad id="3"] &amp; B</p><!-- x -->text &lt;b&gt;');
    final html = c.blocks.whereType<HtmlBlock>().map((b) => b.html).join();
    expect(html, isNot(contains('[ad')));
    expect(html, isNot(contains('<!--')));
    expect(html, contains('&amp;'));
    expect(html, contains('&lt;b&gt;'));
  });

  test('every sampled real post parses without throwing', () {
    for (final p in fixture('posts_embed_20.json') as List) {
      parsePostContent(p['content']['rendered'] as String);
    }
    for (final f in ['deep_19447.json', 'deep_2687.json', 'deep_55613.json', 'deep_57915.json']) {
      final c = parsePostContent(fixtureContent(f));
      expect(c.blocks, isNotEmpty, reason: f);
    }
    // Direct .pdf links in old DSERT posts become download rows.
    expect(parsePostContent(fixtureContent('deep_2687.json')).files.where((f) => f.link.kind == LinkKind.file), isNotEmpty);
  });
}

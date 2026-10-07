import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/core/text_utils.dart';
import 'package:kspstadk_app/data/models.dart';

import 'helpers/fixtures.dart';

void main() {
  group('Post.fromJson (real /posts?_embed response)', () {
    final raw = fixture('posts_embed_20.json') as List;
    final posts = [for (final p in raw) Post.fromJson(Map<String, dynamic>.from(p as Map))];

    test('parses all 20 posts', () {
      expect(posts, hasLength(20));
      expect(posts.every((p) => p.id > 0 && p.link.startsWith('https://kspstadk.com/')), isTrue);
    });

    test('decodes HTML entities in titles and keeps Kannada intact', () {
      for (final p in posts) {
        expect(p.title, isNot(contains('&#')));
        expect(p.title, isNot(contains('&amp;')));
      }
      final lba = posts.firstWhere((p) => p.id == 57951);
      expect(lba.title, startsWith('4ನೇ ತರಗತಿ ಎಲ್ಲಾ ವಿಷಯಗಳ LBA ಪ್ರಶ್ನಾ ಕೋಶ'));
      expect(lba.title, contains('–')); // &#8211; decoded
    });

    test('reads embedded terms and a medium-sized image', () {
      final p = posts.firstWhere((p) => p.id == 57951);
      expect(p.categories.map((c) => c.name), containsAll(['4 TH STANDARD', '4 ನೇ ತರಗತಿ', 'LBA']));
      expect(p.categoryIds, containsAll([408, 409, 1341]));
      final first = posts.first;
      expect(first.imageUrl, contains('768x432')); // medium_large
      expect(first.thumbUrl, isNotNull);
    });

    test('excerpt drops the "Read more" button', () {
      expect(posts.first.excerpt, isNot(contains('Read more')));
      expect(posts.first.excerpt, isNotEmpty);
    });

    test('round-trips through the cache JSON', () {
      for (final p in posts) {
        final back = Post.fromJson(p.toJson());
        expect(back.id, p.id);
        expect(back.title, p.title);
        expect(back.content, p.content);
        expect(back.imageUrl, p.imageUrl);
        expect(back.categoryIds, p.categoryIds);
        expect(back.terms.length, p.terms.length);
        expect(back.date, p.date);
      }
    });
  });

  test('Post.fromJson handles the lite _fields response', () {
    final raw = fixture('posts_list_fields.json') as List;
    final p = Post.fromJson(Map<String, dynamic>.from(raw.first as Map));
    expect(p.content, isEmpty);
    expect(p.title, isNotEmpty);
    expect(p.terms, isEmpty);
  });

  test('Category.fromJson and Kannada detection', () {
    final cats = [for (final c in fixture('categories.json') as List) Category.fromJson(Map<String, dynamic>.from(c as Map))];
    expect(cats, hasLength(94));
    final kn = cats.firstWhere((c) => c.id == 469);
    expect(kn.name, 'ವಿಜ್ಞಾನ');
    expect(kn.isKannada, isTrue);
    expect(cats.firstWhere((c) => c.id == 468).isKannada, isFalse);
    expect(cats.every((c) => c.parent == 0), isTrue, reason: 'site uses flat categories');
  });

  group('text utils', () {
    test('plainText decodes entities and collapses whitespace', () {
      expect(plainText('<p>A&nbsp;&amp;  B &#8211; ಕನ್ನಡ</p>'), 'A & B – ಕನ್ನಡ');
    });
    test('readingMinutes is at least 1', () {
      expect(readingMinutes('<p>ಒಂದು</p>'), 1);
      expect(readingMinutes('<p>${List.filled(900, 'ಪದ').join(' ')}</p>'), 5);
    });
    test('formatBytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    });
  });
}

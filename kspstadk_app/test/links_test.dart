import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/content/links.dart';

void main() {
  group('driveFileId', () {
    test('uc?export=download&id= (LBA kl-grid links, HTML-escaped)', () {
      expect(driveFileId('https://drive.google.com/uc?export=download&#038;id=1KI2Awx4EdeHdb98YM4iBQzg6pF_v22RQ'),
          '1KI2Awx4EdeHdb98YM4iBQzg6pF_v22RQ');
      expect(driveFileId('https://drive.google.com/uc?export=download&amp;id=1wPSixjL09UcdD8LITkrUDqj8jyASqcUk'),
          '1wPSixjL09UcdD8LITkrUDqj8jyASqcUk');
      expect(driveFileId('https://drive.google.com/uc?id=1abcDEFghiJKL-_x&export=download'), '1abcDEFghiJKL-_x');
    });
    test('/file/d/ID/view', () {
      expect(driveFileId('https://drive.google.com/file/d/1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1/view?usp=sharing'),
          '1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1');
      expect(driveFileId('https://drive.google.com/file/d/1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1/preview'),
          '1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1');
    });
    test('open?id=', () {
      expect(driveFileId('https://drive.google.com/open?id=1QwErTyUiOp_asdfgh'), '1QwErTyUiOp_asdfgh');
    });
    test('usercontent and docs', () {
      expect(driveFileId('https://drive.usercontent.google.com/download?id=1ZZZZZZZZZZZZ&export=download'), '1ZZZZZZZZZZZZ');
      expect(driveFileId('https://docs.google.com/document/d/1DocIdDocIdDocId/edit'), '1DocIdDocIdDocId');
    });
    test('non-drive links', () {
      expect(driveFileId('https://kspstadk.com/lba/'), isNull);
      expect(driveFileId('https://drive.google.com/drive/folders/1FolderFolder'), isNull);
    });
  });

  group('classifyLink', () {
    test('drive → direct usercontent download url', () {
      final l = classifyLink('https://drive.google.com/file/d/1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1/view?usp=sharing');
      expect(l.kind, LinkKind.drive);
      expect(l.isDownload, isTrue);
      expect(l.downloadUrl,
          'https://drive.usercontent.google.com/download?id=1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1&export=download&confirm=t');
      expect(l.key, 'gd_1xxPXsD9TZAXNcuHgxb0SoVBI3K8_vzt1');
    });
    test('google docs export as pdf', () {
      final l = classifyLink('https://docs.google.com/document/d/1DocIdDocIdDocId/edit?usp=sharing');
      expect(l.downloadUrl, 'https://docs.google.com/document/d/1DocIdDocIdDocId/export?format=pdf');
    });
    test('direct pdf and zip', () {
      expect(classifyLink('https://kspstadk.com/wp-content/uploads/2020/06/book.pdf').kind, LinkKind.file);
      final zip = classifyLink('https://example.org/files/all-lessons.ZIP?x=1');
      expect(zip.kind, LinkKind.file);
      expect(zip.extension, 'zip');
    });
    test('internal post link → slug (incl. Kannada percent-encoded slugs)', () {
      final l = classifyLink('https://kspstadk.com/class-4-kannada-lba-question-bank/');
      expect(l.kind, LinkKind.internal);
      expect(l.slug, 'class-4-kannada-lba-question-bank');
      final kn = classifyLink('https://kspstadk.com/%e0%b2%97%e0%b3%81%e0%b2%b0%e0%b3%81%e0%b2%b8%e0%b3%87%e0%b2%b5%e0%b3%86/');
      expect(kn.slug, 'ಗುರುಸೇವೆ');
      expect(classifyLink('https://kspstadk.com/category/lba/').slug, 'category/lba');
      expect(classifyLink('https://kspstadk.com/wp-content/uploads/x.png').kind, LinkKind.external);
      expect(classifyLink('https://tools.kspstadk.com/').kind, LinkKind.external);
    });
    test('youtube, whatsapp, telegram', () {
      expect(classifyLink('https://www.youtube.com/embed/ovjQExoi6Z4?feature=oembed').videoId, 'ovjQExoi6Z4');
      expect(classifyLink('https://youtu.be/ovjQExoi6Z4').videoId, 'ovjQExoi6Z4');
      expect(classifyLink('https://chat.whatsapp.com/BylYTwTrzpB1IDHJ7HR8wV').kind, LinkKind.whatsappGroup);
      expect(classifyLink('https://t.me/joinchat/T0UhHpW1').kind, LinkKind.telegramGroup);
      expect(classifyLink('https://t.me/share/url?url=x').kind, LinkKind.external);
      expect(classifyLink('https://wa.me/?text=hi').kind, LinkKind.external);
    });
  });

  test('cleanLinkLabel removes filler', () {
    expect(cleanLinkLabel('ಕನ್ನಡ ನೋಟ್ಸ್ 1 ಇಲ್ಲಿ ಕ್ಲಿಕ್ ಮಾಡಿ '), 'ಕನ್ನಡ ನೋಟ್ಸ್ 1');
    expect(cleanLinkLabel('Unit 3 Click here to download'), 'Unit 3');
    expect(cleanLinkLabel('ಪಾಠ 2 -'), 'ಪಾಠ 2');
  });
}

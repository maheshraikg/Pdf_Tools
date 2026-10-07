import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/content/links.dart';
import 'package:kspstadk_app/data/store.dart';
import 'package:kspstadk_app/downloads/download_manager.dart';

/// Serves canned responses by URL and records what was requested.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);

  final Map<bool Function(Uri), ResponseBody Function()> routes;
  final requested = <Uri>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requested.add(options.uri);
    for (final e in routes.entries) {
      if (e.key(options.uri)) return e.value();
    }
    return ResponseBody.fromString('not found', 404);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody pdf({String name = 'Lesson 1.pdf'}) => ResponseBody.fromBytes(
      utf8.encode('%PDF-1.4\n1 0 obj<<>>endobj\ntrailer<<>>\n%%EOF'),
      200,
      headers: {
        'content-type': ['application/pdf'],
        'content-disposition': ['attachment; filename="$name"'],
      },
    );

ResponseBody html(String body) => ResponseBody.fromString(body, 200, headers: {
      'content-type': ['text/html; charset=utf-8'],
    });

const virusScanPage = '''<!DOCTYPE html><html><head><title>Google Drive - Virus scan warning</title></head><body>
<form id="download-form" action="https://drive.usercontent.google.com/download" method="get">
<input type="submit" value="Download anyway"/>
<input type="hidden" name="id" value="1BIGFILEBIGFILE"><input type="hidden" name="export" value="download">
<input type="hidden" name="confirm" value="t"><input type="hidden" name="uuid" value="abc-123">
</form></body></html>''';

void main() {
  late Directory dir;
  late MemoryBox box;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('dl');
    box = MemoryBox();
  });
  tearDown(() => dir.delete(recursive: true));

  DownloadManager manager(FakeAdapter a) =>
      DownloadManager(box, dio: Dio()..httpClientAdapter = a, baseDir: () async => dir);

  const meta = DownloadMeta(title: 'The Advent of Europeans · ಪ್ರಶ್ನೆಗಳು', postId: 57911, group: '10 ನೇ ತರಗತಿ', subgroup: 'ಸಮಾಜ ವಿಜ್ಞಾನ');

  test('downloads a public Drive file via the usercontent URL and records it', () async {
    final a = FakeAdapter({(u) => u.host == 'drive.usercontent.google.com' && u.queryParameters['id'] == '1KI2Awx4EdeHdb98YM4iBQzg6pF_v22RQ': pdf});
    final dm = manager(a);
    final link = classifyLink('https://drive.google.com/uc?export=download&#038;id=1KI2Awx4EdeHdb98YM4iBQzg6pF_v22RQ');
    final rec = await dm.download(link, meta);

    expect(a.requested.single.queryParameters['confirm'], 't');
    expect(rec.isPdf, isTrue);
    expect(File(rec.path).readAsStringSync(), startsWith('%PDF'));
    expect(rec.group, '10 ನೇ ತರಗತಿ');
    expect(dm.record(link.key), isNotNull);
    expect(dm.state(link.key).value.status, DownloadStatus.done);
    expect(dm.totalBytes, greaterThan(0));

    // Second call is a no-op (already saved offline).
    await dm.download(link, meta);
    expect(a.requested, hasLength(1));
  });

  test('follows the Drive virus-scan confirmation form for big files', () async {
    final a = FakeAdapter({
      (u) => u.queryParameters['uuid'] == 'abc-123': () => pdf(name: 'big.pdf'),
      (u) => u.host == 'drive.usercontent.google.com': () => html(virusScanPage),
    });
    final dm = manager(a);
    final rec = await dm.download(classifyLink('https://drive.google.com/file/d/1BIGFILEBIGFILE/view?usp=sharing'), meta);
    expect(a.requested, hasLength(2));
    expect(a.requested.last.queryParameters, containsPair('confirm', 't'));
    expect(File(rec.path).readAsStringSync(), startsWith('%PDF'));
  });

  test('a private file (HTML login page) fails with notPublic and leaves nothing behind', () async {
    final a = FakeAdapter({(u) => true: () => html('<!doctype html><html><body>Sign in</body></html>')});
    final dm = manager(a);
    final link = classifyLink('https://drive.google.com/file/d/1PRIVATEPRIVATE/view');
    await expectLater(
      dm.download(link, meta),
      throwsA(isA<DownloadException>().having((e) => e.error, 'error', DownloadError.notPublic)),
    );
    expect(dm.record(link.key), isNull);
    expect(dm.state(link.key).value.status, DownloadStatus.failed);
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);
  });

  test('direct pdf/zip links keep their extension; delete removes the file', () async {
    final a = FakeAdapter({
      (u) => u.path.endsWith('.zip'): () => ResponseBody.fromBytes(utf8.encode('PK\x03\x04zip'), 200, headers: {
            'content-type': ['application/zip'],
          }),
    });
    final dm = manager(a);
    final link = classifyLink('https://kspstadk.com/wp-content/uploads/2026/09/all-lessons.zip');
    final rec = await dm.download(link, const DownloadMeta(title: 'All lessons'));
    expect(rec.extension, 'zip');
    expect(rec.isPdf, isFalse);
    await dm.delete(link.key);
    expect(File(rec.path).existsSync(), isFalse);
    expect(dm.all, isEmpty);
  });
}

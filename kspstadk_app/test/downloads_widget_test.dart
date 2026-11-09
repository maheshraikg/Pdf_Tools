import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/data/store.dart';
import 'package:kspstadk_app/downloads/download_manager.dart';
import 'package:kspstadk_app/ui/screens/downloads_screen.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('empty library shows the friendly empty state', (tester) async {
    await pumpApp(tester, testServices(), home: const DownloadsScreen());
    expect(find.text('ಇನ್ನೂ ಯಾವುದೇ ಡೌನ್‌ಲೋಡ್ ಇಲ್ಲ'), findsOneWidget);
  });

  testWidgets('library groups by class → subject, searches and deletes (offline)', (tester) async {
    final stores = Stores.memory();
    final dir = Directory.systemTemp.createTempSync('lib');
    addTearDown(() => dir.deleteSync(recursive: true));
    Future<void> add(String key, String title, String group, String subgroup, int bytes) async {
      final f = File('${dir.path}/$key.pdf')..writeAsBytesSync(List.filled(bytes, 1));
      await stores.downloads.put(key, DownloadRecord(
        key: key, url: 'https://drive.google.com/file/d/$key/view', title: title, path: f.path,
        bytes: bytes, savedAt: DateTime(2026, 9, 1), postId: 1, postTitle: 'Post', group: group, subgroup: subgroup,
      ).toJson());
    }

    await tester.runAsync(() async {
      await add('a', 'Lesson 1 · ಪ್ರಶ್ನೆಗಳು', '10 ನೇ ತರಗತಿ', 'ಸಮಾಜ ವಿಜ್ಞಾನ', 2048);
      await add('b', 'Lesson 1 · ಉತ್ತರಗಳು', '10 ನೇ ತರಗತಿ', 'ಸಮಾಜ ವಿಜ್ಞಾನ', 1024);
      await add('c', 'ಕನ್ನಡ ನೋಟ್ಸ್ 1', '4 ನೇ ತರಗತಿ', 'ಕನ್ನಡ', 1024);
    });
    final services = testServices(stores: stores, downloads: DownloadManager(stores.downloads, baseDir: () async => dir));
    services.network.online = false;
    await pumpApp(tester, services, home: const DownloadsScreen());

    expect(find.text('3 ಫೈಲ್‌ಗಳು'), findsOneWidget);
    expect(find.text('ಬಳಸಿದ ಸ್ಥಳ: 4.0 KB'), findsOneWidget);
    // Class 4 sorts before class 10.
    final y4 = tester.getTopLeft(find.text('4 ನೇ ತರಗತಿ')).dy;
    final y10 = tester.getTopLeft(find.text('10 ನೇ ತರಗತಿ')).dy;
    expect(y4, lessThan(y10));
    expect(find.text('ಸಮಾಜ ವಿಜ್ಞಾನ'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ನೋಟ್ಸ್');
    await tester.pump();
    expect(find.text('ಕನ್ನಡ ನೋಟ್ಸ್ 1'), findsOneWidget);
    expect(find.text('Lesson 1 · ಪ್ರಶ್ನೆಗಳು'), findsNothing);

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.tap(find.text('ಅಳಿಸಿ').last);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('"ಕನ್ನಡ ನೋಟ್ಸ್ 1" ಅಳಿಸಬೇಕೇ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'ಅಳಿಸಿ'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    }
    await tester.pump();
    expect(services.downloads.all.map((r) => r.key), isNot(contains('c')));
  });
}

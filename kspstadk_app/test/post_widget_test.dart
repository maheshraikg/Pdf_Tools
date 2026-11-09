import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:kspstadk_app/ui/post/blocks.dart';
import 'package:kspstadk_app/ui/screens/post_screen.dart';

import 'helpers/fixtures.dart';
import 'helpers/test_app.dart';

void main() {
  testWidgets('Class hub post renders hero, subject tiles and actions natively', (tester) async {
    final services = testServices();
    await pumpApp(tester, services, home: const PostScreen(postId: 57951));

    expect(find.textContaining('4ನೇ ತರಗತಿ ಎಲ್ಲಾ ವಿಷಯಗಳ LBA ಪ್ರಶ್ನಾ ಕೋಶ'), findsWidgets);
    expect(find.text('LBA ಪ್ರಶ್ನಾ ಕೋಶ'), findsWidgets); // category chip (twins merged)
    expect(find.text('4 ನೇ ತರಗತಿ'), findsWidgets);
    expect(find.byTooltip('ಹಂಚಿಕೊಳ್ಳಿ'), findsWidgets);
    expect(find.byTooltip('ಉಳಿಸಿ'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ಭಾಷಾ ವಿಷಯಗಳು'), 500, scrollable: find.byType(Scrollable).first);
    expect(find.text('17 ಪಾಠಗಳು'), findsOneWidget);
    expect(find.textContaining('<style'), findsNothing);
  });

  testWidgets('LBA download grid becomes native lesson cards + rainbow related chips', (tester) async {
    final deep = fixture('deep_57911.json') as Map<String, dynamic>;
    final services = testServices(configure: (dio) {
      final a = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      a.onGet('/posts/57911', (s) => s.reply(200, {...deep, 'date': '2026-09-20T10:00:00', 'modified': '2026-09-20T10:00:00'}, headers: json));
      a.onGet('/posts', (s) => s.reply(200, <Object>[], headers: json));
      return a;
    });
    await pumpApp(tester, services, home: const PostScreen(postId: 57911));

    final scroll = find.byType(Scrollable).first;
    // The lesson table near the top also lists lesson names; scroll to the cards.
    await tester.scrollUntilVisible(find.text('01'), 500, scrollable: scroll, maxScrolls: 100); // lesson badge
    expect(find.text('The Advent of Europeans to India'), findsWidgets);
    expect(find.text('ಪ್ರಶ್ನೆಗಳು'), findsWidgets);
    expect(find.text('ಉತ್ತರಗಳು'), findsWidgets);
    expect(find.byType(FileRow), findsWidgets);
    expect(find.text('ತೆರೆಯಿರಿ'), findsWidgets);

    await tester.scrollUntilVisible(find.byType(RelatedView), 2000, scrollable: scroll, maxScrolls: 200);
    expect(find.text('ಇವುಗಳನ್ನೂ ಓದಿ'), findsOneWidget);
  });

  testWidgets('Bookmark toggle saves the post for offline reading', (tester) async {
    final services = testServices();
    await pumpApp(tester, services, home: const PostScreen(postId: 58008));
    await tester.tap(find.byTooltip('ಉಳಿಸಿ'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(services.bookmarks.contains(58008), isTrue);
    expect(services.bookmarks.all.single.content, isNotEmpty);
    expect(find.byTooltip('ಉಳಿಸಲಾಗಿದೆ'), findsOneWidget);
  });
}

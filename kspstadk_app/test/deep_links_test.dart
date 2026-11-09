import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/notifications/deep_links.dart';
import 'package:kspstadk_app/ui/link_router.dart';
import 'package:kspstadk_app/ui/screens/post_screen.dart';
import 'package:kspstadk_app/ui/shell.dart';

import 'helpers/test_app.dart';

void main() {
  group('parseDeepLink', () {
    test('post slug App Link', () {
      final t = parseDeepLink(Uri.parse('https://kspstadk.com/class-4-kannada-lba-question-bank/'));
      expect(t, isA<UrlTarget>());
      expect((t! as UrlTarget).url, 'https://kspstadk.com/class-4-kannada-lba-question-bank/');
    });
    test('www and http are normalised', () {
      expect((parseDeepLink(Uri.parse('http://www.kspstadk.com/lba-login/'))! as UrlTarget).url, 'https://www.kspstadk.com/lba-login/');
    });
    test('?p= shortlinks and custom scheme', () {
      expect((parseDeepLink(Uri.parse('https://kspstadk.com/?p=58008'))! as PostTarget).id, 58008);
      expect((parseDeepLink(Uri.parse('kspstadk://post/57951'))! as PostTarget).id, 57951);
      expect(parseDeepLink(Uri.parse('https://kspstadk.com/')), isA<HomeTarget>());
    });
    test('foreign hosts are ignored', () {
      expect(parseDeepLink(Uri.parse('https://example.com/x/')), isNull);
    });
  });

  group('notificationTarget (FCM data from tool/notify.py)', () {
    test('post_id wins', () {
      expect((notificationTarget({'post_id': '58077', 'url': 'https://kspstadk.com/x/'})! as PostTarget).id, 58077);
    });
    test('falls back to url', () {
      expect(notificationTarget({'url': 'https://kspstadk.com/x/'}), isA<UrlTarget>());
      expect(notificationTarget({}), isNull);
    });
  });

  test('topic names match the notifier script', () {
    expect(Topics.general, ['all', 'lba', 'info', 'study', 'quiz']);
    expect(Topics.forClass(10), 'class_10');
  });

  testWidgets('tapping a notification opens the post screen', (tester) async {
    final services = testServices();
    await pumpApp(tester, services, home: const AppShell(showSplash: false));
    routeTarget(notificationTarget({'post_id': '58008'})!);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PostScreen), findsOneWidget);
    expect(find.textContaining('LBA 2026-27 ಶಿಕ್ಷಕರ ವೈಯಕ್ತಿಕ ಅಂಕಪಟ್ಟಿ'), findsWidgets);
    // Back returns to the shell.
    Navigator.of(tester.element(find.byType(PostScreen))).pop();
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PostScreen), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}

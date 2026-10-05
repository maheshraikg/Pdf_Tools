import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/ui/shell.dart';
import 'package:kspstadk_app/ui/widgets/post_card.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('Home shows header, latest carousel, tiles, classes and sections (Kannada)', (tester) async {
    final services = testServices();
    await pumpApp(tester, services, home: const AppShell(showSplash: false));

    expect(find.text('ನಮಸ್ಕಾರ, ಶಿಕ್ಷಕರೇ 🙏'), findsOneWidget);
    expect(find.text('ಇತ್ತೀಚಿನವು'), findsOneWidget);
    expect(find.byType(PostHeroCard), findsWidgets);
    expect(find.text('ತ್ವರಿತ ಪ್ರವೇಶ'), findsOneWidget);
    expect(find.text('LBA ಪ್ರಶ್ನಾ ಕೋಶ'), findsWidgets);
    expect(find.text('ಮುಖಪುಟ'), findsOneWidget); // bottom nav

    // Scroll to the category sections and join card.
    await tester.scrollUntilVisible(find.text('ಶಿಕ್ಷಕರ ಗುಂಪಿಗೆ ಸೇರಿ'), 400, scrollable: find.byType(Scrollable).first);
    expect(find.text('WhatsApp ಗುಂಪು'), findsOneWidget);
    expect(find.byType(PostCard), findsWidgets);
  });

  testWidgets('English toggle switches the UI language', (tester) async {
    final services = testServices(locale: 'en');
    await pumpApp(tester, services, home: const AppShell(showSplash: false));
    expect(find.text('Namaskara, teachers 🙏'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('LBA Question Bank'), findsWidgets);
  });

  testWidgets('Offline with an empty cache shows a friendly error with retry', (tester) async {
    final services = testServices(configure: (dio) {
      final offline = DioException.connectionError(requestOptions: RequestOptions(), reason: 'offline');
      return DioAdapter(dio: dio, matcher: const UrlRequestMatcher())
        ..onGet('/posts', (s) => s.throws(0, offline))
        ..onGet('/categories', (s) => s.throws(0, offline));
    });
    services.network.online = false;
    await pumpApp(tester, services, home: const AppShell(showSplash: false));
    expect(find.text('ಇಂಟರ್ನೆಟ್ ಇಲ್ಲ — ಉಳಿಸಿದ ವಿಷಯ ತೋರಿಸಲಾಗುತ್ತಿದೆ'), findsOneWidget);
    expect(find.text('ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ'), findsWidgets);
  });
}


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kspstadk_app/ui/screens/downloads_screen.dart';
import 'package:kspstadk_app/ui/screens/post_screen.dart';
import 'package:kspstadk_app/ui/shell.dart';

import 'helpers/test_app.dart';

/// Large text (1.6×) + dark mode must lay out without overflow errors.
Widget scaled(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.6)),
        child: child,
      ),
    );

void main() {
  for (final (name, screen) in [
    ('home', const AppShell(showSplash: false)),
    ('post', const PostScreen(postId: 57951)),
    ('downloads', const DownloadsScreen()),
  ]) {
    testWidgets('$name: dark mode + 1.6× text has no layout errors', (tester) async {
      final services = testServices();
      await services.settings.setThemeMode(ThemeMode.dark);
      await pumpApp(tester, services, home: scaled(screen));
      expect(tester.takeException(), isNull);
      // Scroll through the first screenful of content as well.
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        await tester.drag(scrollables.first, const Offset(0, -1500));
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('key controls have screen-reader labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, testServices(), home: const PostScreen(postId: 58008));
    // Icon buttons expose their tooltip to TalkBack.
    expect(tester.getSemantics(find.byTooltip('ಉಳಿಸಿ')), isSemantics(tooltip: 'ಉಳಿಸಿ', isButton: true, hasTapAction: true));
    expect(tester.getSemantics(find.byTooltip('ಹಂಚಿಕೊಳ್ಳಿ').first), isSemantics(tooltip: 'ಹಂಚಿಕೊಳ್ಳಿ', isButton: true));
    // The post title is announced as a heading.
    expect(find.bySemanticsLabel(RegExp('LBA 2026-27')), findsWidgets);
    handle.dispose();
  });
}

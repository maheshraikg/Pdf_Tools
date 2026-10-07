import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/app/settings.dart';
import 'package:po_sahayak/data/saved_account_repository.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/features/result/result_screen.dart';
import 'package:po_sahayak/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/helpers.dart';

Future<void> pumpApp(WidgetTester tester, {String lang = 'en'}) async {
  SharedPreferences.setMockInitialValues({'lang': lang});
  final settings = await AppSettings.load();
  final accounts = await SavedAccountRepository.load();
  await tester.pumpWidget(
    PoSahayakApp(
      settings: settings,
      rates: loadRates(),
      accounts: accounts,
      background: false,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home shows scheme tiles and switches language', (tester) async {
    await pumpApp(tester);
    expect(find.text('Deposits'), findsOneWidget);
    expect(find.text('Highest rate now'), findsOneWidget);
    await tester.tap(find.text('ಕನ್ನಡ'));
    await tester.pumpAndSettle();
    expect(find.text('ಠೇವಣಿಗಳು'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('TD5'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TD5'), findsOneWidget);
  });

  testWidgets('TD5 calculation, save and My accounts', (tester) async {
    await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.text('TD5'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('TD5'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '100000');
    await tester.ensureVisible(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.textContaining('₹7,714'), findsWidgets);
    expect(find.text('₹1,38,570'), findsWidgets);

    await tester.ensureVisible(find.text('Save account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Amma TD');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accounts').last);
    await tester.pumpAndSettle();
    expect(find.text('Amma TD'), findsWidgets);
  });

  testWidgets('every tab opens in Kannada', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, lang: 'kn');
    for (final label in ['ಹೋಲಿಕೆ', 'ಖಾತೆಗಳು', 'ಸಿಬ್ಬಂದಿ', 'ಸೆಟ್ಟಿಂಗ್ಸ್']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('result screen of every scheme fits a small phone in Kannada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, lang: 'kn');
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final scheme in Scheme.values) {
      final r = calc(
        scheme,
        scheme.amountKind == AmountKind.monthly ? 5000 : 150000,
        '7.5',
        opening: DateTime(2024, 3, 1),
      );
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(result: r, girlAge: 5),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
      await tester.pumpAndSettle();
      final err = tester.takeException();
      expect(err, isNull, reason: scheme.code);
      nav.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('large phone font: home and every tab lay out without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final lang in ['en', 'kn']) {
      await pumpApp(tester, lang: lang);
      expect(tester.takeException(), isNull, reason: '$lang home');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$lang home scrolled');
      for (final icon in [
        Icons.leaderboard_outlined,
        Icons.savings_outlined,
        Icons.support_agent_outlined,
        Icons.settings_outlined,
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lang $icon');
      }
    }
  });
}

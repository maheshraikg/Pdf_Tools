import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:po_sahayak/app/settings.dart';
import 'package:po_sahayak/app/strings.dart';
import 'package:po_sahayak/data/saved_account_repository.dart';
import 'package:po_sahayak/domain/models/scheme.dart';
import 'package:po_sahayak/features/result/result_screen.dart';
import 'package:po_sahayak/features/schemes/scheme_details_screen.dart';
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
    await tester.tap(find.text('English').first);
    await tester.pumpAndSettle();
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
        Icons.account_balance_wallet_outlined,
        Icons.support_agent_outlined,
        Icons.settings_outlined,
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$lang $icon');
      }
    }
  });

  testWidgets('share sends the card image and the text', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    await pumpApp(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(result: calc(Scheme.mssc, 1000, '7.5')),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.share_rounded));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Share'));
      for (var i = 0; i < 50 && calls.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    final args = calls.single.arguments as Map;
    expect(args['text'], contains('₹1,160'));
    final path = (args['paths'] as List).single as String;
    expect(File(path).lengthSync(), greaterThan(1000));
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('settings shares the download link', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    // Tall screen so the whole Settings page fits above the tab bar.
    tester.view.physicalSize = const Size(400 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share this app'));
    await tester.pumpAndSettle();
    expect(calls, hasLength(1));
    expect(
      (calls.single.arguments as Map)['text'],
      contains('po-sahayak-keep-latest/po_sahayak.apk'),
    );
  });

  testWidgets('staff tab shows the account opening steps', (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final lang in ['en', 'kn']) {
      await pumpApp(tester, lang: lang);
      await tester.tap(find.text(lang == 'en' ? 'Staff' : 'ಸಿಬ್ಬಂದಿ').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lang);
      expect(
        find.text(
          lang == 'en' ? 'How to open the account' : 'ಖಾತೆ ತೆರೆಯುವ ವಿಧಾನ',
        ),
        findsOneWidget,
      );
    }
    expect(find.textContaining('Only the 5-year TD'), findsNothing);
  });

  testWidgets('scheme details open from Staff and share the text', (
    tester,
  ) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        calls.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    tester.view.physicalSize = const Size(400 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full scheme details'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Who can open'), findsOneWidget);
    await tester.tap(find.text('Share details with customer'));
    await tester.pumpAndSettle();
    final text = (calls.single.arguments as Map)['text'] as String;
    expect(text, contains('Time Deposit 5 years (TD5)'));
    expect(text, contains('Early closure:'));
    expect(text, contains('Documents needed:'));
  });

  testWidgets('details page of every scheme lays out in Kannada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, lang: 'kn');
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    for (final scheme in Scheme.values) {
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => SchemeDetailsScreen(scheme: scheme),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: scheme.code);
      nav.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('every language: all tabs, a result and scheme details', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final lang in Lang.values) {
      await pumpApp(tester, lang: lang.name);
      final s = S(lang);
      expect(find.text(s.appTitle), findsWidgets, reason: lang.name);
      for (final icon in [
        Icons.leaderboard_outlined,
        Icons.account_balance_wallet_outlined,
        Icons.support_agent_outlined,
        Icons.settings_outlined,
        Icons.home_outlined,
      ]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${lang.name} $icon');
      }
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ResultScreen(result: calc(Scheme.scss, 500000, '8.2')),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -4000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${lang.name} result');
      nav.pop();
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const SchemeDetailsScreen(scheme: Scheme.ppf),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '${lang.name} details');
      nav.pop();
      await tester.pumpAndSettle();
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganita_aata/data/app_store.dart';
import 'package:ganita_aata/main.dart';
import 'package:ganita_aata/screens/home_screen.dart';
import 'package:ganita_aata/screens/progress_screen.dart';
import 'package:ganita_aata/screens/result_screen.dart';
import 'package:ganita_aata/services/app_state.dart';
import 'package:ganita_aata/services/audio_service.dart';
import 'package:ganita_aata/services/notification_service.dart';
import 'package:ganita_aata/widgets/answer_grid.dart';

final today = DateTime(2026, 11, 9, 10);

AppState newApp({String? lang = 'en', int? schoolClass = 2, String topic = 'add1'}) {
  final app = AppState(
    store: MemoryAppStore(),
    audio: SilentAudioService(),
    notifications: NoopNotificationService(),
    clock: () => today,
  );
  if (lang != null) app.setLanguage(lang);
  if (schoolClass != null) {
    app.createProfile(name: 'Asha', schoolClass: schoolClass, avatar: 'av_tiger');
    app.active!.unlocked.add(topic);
    app.setCurrentTopic(topic);
  }
  return app;
}

Future<void> pumpApp(WidgetTester tester, AppState app, {Widget? home}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(GanitaAataApp(state: app, home: home));
  await tester.pump();
}

/// Reads "a op b = ?" from the question card and works out the answer.
int solveShown(WidgetTester tester) {
  final text = tester.widget<Text>(find.byKey(const ValueKey('question_text'))).data!;
  final m = RegExp(r'^(\d+) ([+−×÷]) (\d+) = \?$').firstMatch(text);
  expect(m, isNotNull, reason: 'unexpected question "$text"');
  final a = int.parse(m!.group(1)!), b = int.parse(m.group(3)!);
  return switch (m.group(2)) {
    '+' => a + b,
    '−' => a - b,
    '×' => a * b,
    _ => a ~/ b,
  };
}

Future<void> tapAnswer(WidgetTester tester, String answer) async {
  await tester.tap(find.descendant(of: find.byType(AnswerGrid), matching: find.text(answer)));
  await tester.pump();
}

Future<void> wrongAnswer(WidgetTester tester, int correct) async {
  final texts = tester
      .widgetList<Text>(find.descendant(of: find.byType(AnswerGrid), matching: find.byType(Text)))
      .map((t) => t.data!)
      .where((d) => d != '$correct')
      .toList();
  await tapAnswer(tester, texts.first);
}

/// Scrolls a lazily built list until [key] is on screen, then taps it.
Future<void> tapKey(WidgetTester tester, String key) async {
  final f = find.byKey(ValueKey(key));
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

Future<void> pumpSeconds(WidgetTester tester, int s) async {
  for (var i = 0; i < s * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('first launch: language (Kannada default) → profile → home', (tester) async {
    final app = newApp(lang: null, schoolClass: null);
    expect(app.lang, 'kn');
    await pumpApp(tester, app);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('ಕನ್ನಡ'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lang_en')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lang_continue')));
    await tester.pumpAndSettle();
    expect(find.text('Who is playing?'), findsOneWidget);

    // Name is required.
    await tester.tap(find.byKey(const ValueKey('save_profile')));
    await tester.pump();
    expect(find.text('Please type a name'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('name_field')), 'Asha');
    await tester.tap(find.byKey(const ValueKey('class_4')));
    await tester.tap(find.byKey(const ValueKey('avatar_av_elephant')));
    await tester.tap(find.byKey(const ValueKey('save_profile')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hello, Asha!'), findsOneWidget);
    expect(find.text('Topic: Tables 6–10'), findsOneWidget);
    expect(app.active!.avatar, 'av_elephant');
    expect(app.languageChosen, isTrue);
  });

  testWidgets('home in Kannada', (tester) async {
    final app = newApp(lang: 'kn');
    await pumpApp(tester, app, home: const HomeScreen());
    expect(find.text('ನಮಸ್ಕಾರ, Asha!'), findsOneWidget);
    expect(find.text('ಇಂದಿನ ಸವಾಲು'), findsOneWidget);
    expect(find.text('ಬಲೂನ್ ಒಡೆಯಿರಿ'), findsOneWidget);
  });

  testWidgets('Speed Challenge: type answers, 60 s, result and personal best', (tester) async {
    final app = newApp();
    await pumpApp(tester, app, home: const HomeScreen());
    await tapKey(tester, 'mode_speed');
    await tester.pumpAndSettle();
    expect(find.text('Best: 0'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      final ans = i == 3 ? solveShown(tester) + 1 : solveShown(tester);
      for (final d in '$ans'.split('')) {
        await tester.tap(find.byKey(ValueKey('key_$d')));
      }
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('key_ok')));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await pumpSeconds(tester, 61);
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('3/4'), findsOneWidget);
    expect(find.text('New personal best!'), findsOneWidget);
    expect(app.active!.speedBest['add1'], 3);
    expect(app.active!.coins, 3);
    expect(app.engine.totalSums, 4);
    // The wrong sum is listed with its answer.
    expect(find.text("Let's practise these"), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home_btn')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Balloon Pop: pop the right balloon, wrong shows the answer', (tester) async {
    final app = newApp();
    await pumpApp(tester, app, home: const HomeScreen());
    await tapKey(tester, 'mode_balloon');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3)); // let the balloons rise
    final ans = solveShown(tester);
    await tester.tap(find.text('$ans'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.engine.totalCorrect, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 3));
    final ans2 = solveShown(tester);
    final other = tester
        .widgetList<GestureDetector>(
          find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('balloon_')),
        )
        .toList();
    expect(other.length, 4);
    // Tap a balloon that is not the answer.
    for (var i = 0; i < 4; i++) {
      final label = find.descendant(of: find.byKey(ValueKey('balloon_$i')), matching: find.byType(Text));
      if (tester.widget<Text>(label).data != '$ans2') {
        await tester.tap(find.byKey(ValueKey('balloon_$i')));
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(app.engine.totalSums, 2);
    expect(app.engine.totalCorrect, 1);
    // Finish the round.
    await pumpSeconds(tester, 121);
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
  });

  testWidgets('Daily Challenge: 10 fixed sums, streak and home card', (tester) async {
    final app = newApp(schoolClass: 3);
    final qs = app.dailyQuestions;
    await pumpApp(tester, app, home: const HomeScreen());
    await tester.tap(find.byKey(const ValueKey('daily_card')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      expect(find.text('${i + 1} / 10'), findsOneWidget);
      await tapAnswer(tester, '${qs[i].answer.value}');
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('Daily streak: 1 day'), findsOneWidget);
    expect(app.active!.coins, 20);
    await tester.tap(find.byKey(const ValueKey('home_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Done for today! Come back tomorrow.'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
  });

  testWidgets('Race Car and Treasure Hunt play and can be stopped', (tester) async {
    final app = newApp();
    await pumpApp(tester, app, home: const HomeScreen());
    await tapKey(tester, 'mode_race');
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 1),
    );
    expect(find.text('Get ready!'), findsOneWidget);
    await pumpSeconds(tester, 4);
    for (var i = 0; i < 3; i++) {
      await tapAnswer(tester, '${solveShown(tester)}');
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(app.engine.totalCorrect, 3);
    await tester.tap(find.byKey(const ValueKey('close_game')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Stop this round?'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(app.active!.coins, 0); // stopped rounds give no coins

    await tapKey(tester, 'mode_treasure');
    await pumpSeconds(tester, 1);
    for (var i = 0; i < 5; i++) {
      await tapAnswer(tester, '${solveShown(tester)}');
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(find.text('Chest opened! +5 coins'), findsOneWidget);
    await pumpSeconds(tester, 2);
    final c = solveShown(tester);
    await wrongAnswer(tester, c);
    await pumpSeconds(tester, 150);
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('1 chest opened'), findsOneWidget);
    expect(app.active!.coins, 5 + 5);
  });

  testWidgets('Tables Master: learn and quiz', (tester) async {
    final app = newApp(schoolClass: 4);
    await pumpApp(tester, app, home: const HomeScreen());
    await tapKey(tester, 'mode_tables');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('table_7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('learn_btn')));
    await tester.pumpAndSettle();
    expect(find.text('7 × 8 = 56'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('listen_btn')));
    await pumpSeconds(tester, 3);
    await tester.tap(find.byKey(const ValueKey('listen_btn'))); // pause
    await tester.pump();
    await tester.tap(find.text('Start quiz'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await tapAnswer(tester, '${solveShown(tester)}');
      await tester.pump(const Duration(milliseconds: 800));
    }
    await tester.pumpAndSettle();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.textContaining('All correct!'), findsOneWidget);
  });

  testWidgets('Level map: locked level, topic pick and game choice', (tester) async {
    final app = newApp(schoolClass: 1, topic: 'num100');
    await pumpApp(tester, app, home: const HomeScreen());
    await tester.tap(find.byKey(const ValueKey('play_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('level_2')));
    await tester.pump();
    expect(find.text('Keep practising to open this level!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('level_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('topic_sub1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('topic_sub1'))); // locked
    await tester.pump();
    expect(app.active!.currentTopic, 'num100');
    await tester.tap(find.byKey(const ValueKey('topic_num100')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a game'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pick_speed')));
    await tester.pumpAndSettle();
    expect(find.text('Best: 0'), findsOneWidget);
  });

  testWidgets('Parent PIN guards settings; language switch; reset', (tester) async {
    final app = newApp();
    app.active!.coins = 42;
    await pumpApp(tester, app, home: const HomeScreen());
    Future<void> enter(String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.byKey(ValueKey('pin_$d')));
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const ValueKey('parents_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Create a 4-digit parent PIN'), findsOneWidget);
    await enter('1234');
    expect(find.text('Enter the same PIN again'), findsOneWidget);
    await enter('1299');
    expect(find.text('The PINs were different. Please try again.'), findsOneWidget);
    await enter('1234');
    await enter('1234');
    expect(find.text('Settings'), findsOneWidget);
    expect(app.checkPin('1234'), isTrue);

    await tester.tap(find.text('ಕನ್ನಡ'));
    await tester.pumpAndSettle();
    expect(find.text('ಸೆಟ್ಟಿಂಗ್‌ಗಳು'), findsOneWidget);
    expect(app.lang, 'kn');

    await tester.tap(find.byKey(const ValueKey('reset_progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm_yes')));
    await tester.pumpAndSettle();
    expect(app.active!.coins, 0);

    // Back home, then a wrong PIN keeps Progress locked.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('parents_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open_progress')));
    await tester.pumpAndSettle();
    await enter('0000');
    expect(find.text('ಪಿನ್ ಸರಿಯಿಲ್ಲ. ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.'), findsOneWidget);
    await enter('1234');
    expect(find.text('ಪ್ರಗತಿ'), findsOneWidget);
  });

  testWidgets('Progress screen shows stats, weak facts and calendar', (tester) async {
    final app = newApp(schoolClass: 4, topic: 'tab6_10');
    final q = app.nextQuestion('tab6_10');
    app.recordAnswer(q, false, 4000);
    app.recordAnswer(q, false, 4000);
    for (var i = 0; i < 5; i++) {
      app.recordAnswer(app.nextQuestion('tab6_10'), true, 2000);
    }
    await pumpApp(tester, app, home: const HomeScreen());
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const ProgressScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Sums solved'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
    expect(find.text('Tables 6–10'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Facts to practise'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('${q.a} × ${q.b} = ${q.answer.value}'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('November 2026'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('November 2026'), findsOneWidget);
  });

  testWidgets('Shop: buy and use items; profile switcher adds a child', (tester) async {
    final app = newApp();
    app.active!.coins = 60;
    await pumpApp(tester, app, home: const HomeScreen());
    await tapKey(tester, 'shop_button');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy_av_lion')));
    await tester.pump();
    expect(app.active!.coins, 30);
    expect(app.active!.avatar, 'av_lion');
    await tester.tap(find.byKey(const ValueKey('buy_av_unicorn')));
    await tester.pump();
    expect(find.text('Play more to earn 30 more coins!'), findsOneWidget);
    await tester.tap(find.text('Car colours'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('buy_car_blue')));
    await tester.pump();
    expect(app.active!.carColor, 'car_blue');
    await tester.tap(find.byKey(const ValueKey('use_car_red')));
    await tester.pump();
    expect(app.active!.carColor, 'car_red');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    await tester.fling(find.byType(Scrollable).first, const Offset(0, 3000), 4000);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('avatar_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_child')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('name_field')), 'Ravi');
    await tester.tap(find.byKey(const ValueKey('class_7')));
    await tester.tap(find.byKey(const ValueKey('save_profile')));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Ravi!'), findsOneWidget);
    expect(app.profiles.length, 2);
    await tester.tap(find.byKey(const ValueKey('avatar_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile_Asha')));
    await tester.pumpAndSettle();
    expect(find.text('Hello, Asha!'), findsOneWidget);
    expect(app.active!.coins, 60 - 30 - 20);
  });
}

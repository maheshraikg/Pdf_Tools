import 'package:beat_mitra/app_state.dart';
import 'package:beat_mitra/core/article_number.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/features/backup/backup_screen.dart';
import 'package:beat_mitra/features/beat/beat_detail_screen.dart';
import 'package:beat_mitra/features/beat/beats_screen.dart';
import 'package:beat_mitra/features/home/home_screen.dart';
import 'package:beat_mitra/features/learn/learn_screen.dart';
import 'package:beat_mitra/features/learn/quiz.dart';
import 'package:beat_mitra/features/places/nearby_screen.dart';
import 'package:beat_mitra/features/places/place_detail_screen.dart';
import 'package:beat_mitra/features/places/place_edit_screen.dart';
import 'package:beat_mitra/features/run/route_screen.dart';
import 'package:beat_mitra/features/search/navigate_screen.dart';
import 'package:beat_mitra/features/settings/about_screen.dart';
import 'package:beat_mitra/features/settings/help_screen.dart';
import 'package:beat_mitra/features/settings/lock_screen.dart';
import 'package:beat_mitra/features/settings/onboarding_screen.dart';
import 'package:beat_mitra/features/settings/settings_screen.dart';
import 'package:beat_mitra/features/summary/summary_screen.dart';
import 'package:beat_mitra/features/today/article_editor.dart';
import 'package:beat_mitra/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  late AppState state;
  late int beatId, placeId;
  final today = dayKey(DateTime.now());

  Future<void> seed(WidgetTester tester, {String? locale}) async {
    await tester.runAsync(() async {
      final s = await testServices();
      if (locale != null) s.settings.localeCode = locale;
      beatId = await s.beats.saveBeat(Beat(name: 'Beat 7 HAL', office: 'HAL II Stage SO'));
      final st = await s.beats.saveStreet(Street(beatId: beatId, name: '4th Cross, 2nd Main, HAL 2nd Stage'));
      await s.beats.saveAreaNote(
        AreaNote(beatId: beatId, title: 'Numbering', text: 'Cross numbers increase towards the lake'),
      );
      for (var i = 0; i < 6; i++) {
        final id = await s.places.savePlace(
          Place(
            beatId: beatId,
            streetId: st,
            doorNo: '${10 + i}/3',
            landmark: 'Opposite Sri Ganesha Temple and the big banyan tree',
            lat: 12.9716 + i * 0.0003,
            lng: 77.6412,
            notes: 'Big dog, ring bell twice, upstairs',
            deliveryPref: 'Leave with security',
          ),
        );
        await s.places.setAddressees(id, [
          Addressee(placeId: id, name: 'Ramesh Kumar $i', phone: '98765432$i$i'),
          Addressee(placeId: id, name: 'ಲಕ್ಷ್ಮಿ ದೇವಿ'),
        ]);
        if (i == 0) placeId = id;
        await s.articles.save(
          Article(date: today, articleNo: 'EK123456785IN', type: ArticleType.speedPost, placeId: id),
        );
      }
      await s.articles.save(
        Article(date: today, rawAddress: 'Unknown Person\n99 Nowhere Road', type: ArticleType.parcel),
      );
      await s.articles.save(
        Article(
          date: today,
          type: ArticleType.registered,
          status: ArticleStatus.notDelivered,
          reason: 'doorLocked',
          placeId: placeId,
        ),
      );
      state = AppState(s);
      await state.init();
    });
  }

  Future<void> show(WidgetTester tester, Widget screen) async {
    await pumpApp(tester, state.s, state, screen);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'beats': () => const BeatsScreen(),
    'beat detail': () => BeatDetailScreen(beatId: beatId),
    'place detail': () => PlaceDetailScreen(placeId: placeId),
    'place edit': () => PlaceEditScreen(beatId: beatId, placeId: placeId),
    'nearby': () => const NearbyScreen(),
    'navigate': () => NavigateScreen(placeId: placeId),
    'today': () => const TodayScreen(),
    'article editor': () => ArticleEditorScreen(date: today, ocrText: 'Ramesh Kumar 0\n10/3 4th Cross\n560038'),
    'route': () => const RouteScreen(),
    'summary': () => const SummaryScreen(),
    'learn': () => const LearnScreen(),
    'flashcards': () => const FlashcardScreen(mode: QuizMode.nameToDoor),
    'walk': () => const WalkModeScreen(),
    'backup': () => const BackupScreen(),
    'settings': () => const SettingsScreen(),
    'help': () => const HelpScreen(),
    'about': () => const AboutScreen(),
    'onboarding': () => const OnboardingScreen(),
    'lock': () => const LockScreen(),
  };

  for (final locale in ['en', 'kn', 'hi']) {
    for (final e in screens.entries) {
      testWidgets('$locale: ${e.key} renders without errors', (tester) async {
        await seed(tester, locale: locale);
        await show(tester, e.value());
      });
    }
  }

  testWidgets('article editor suggests the matching place', (tester) async {
    await seed(tester);
    await show(
      tester,
      ArticleEditorScreen(date: today, ocrText: 'Shri Ramesh Kumar 0\nNo. 10/3, 4th Cross\nBengaluru 560038'),
    );
    await tester.scrollUntilVisible(
      find.text('Suggestions — tap the right one'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('This one'), findsWidgets);
    expect(find.textContaining('10/3, 4th Cross'), findsWidgets);
  });
}

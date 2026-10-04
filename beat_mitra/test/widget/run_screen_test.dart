import 'package:beat_mitra/app_state.dart';
import 'package:beat_mitra/core/article_number.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/features/run/run_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('run: deliver first stop, not-deliver second with reason, then finished', (tester) async {
    late AppState state;
    late int p1, p2;
    final today = dayKey(DateTime.now());
    await tester.runAsync(() async {
      final s = await testServices();
      final b = await s.beats.saveBeat(Beat(name: 'Beat 7'));
      final st = await s.beats.saveStreet(Street(beatId: b, name: '4th Cross'));
      p1 = await s.places.savePlace(
        Place(beatId: b, streetId: st, doorNo: '12', landmark: 'Temple', lat: 12.972, lng: 77.6412, notes: 'Dog'),
      );
      p2 = await s.places.savePlace(Place(beatId: b, streetId: st, doorNo: '14', lat: 12.973, lng: 77.6412));
      await s.places.setAddressees(p1, [Addressee(placeId: p1, name: 'Ramesh')]);
      await s.articles.save(Article(date: today, articleNo: 'EK123456785IN', type: ArticleType.speedPost, placeId: p1));
      await s.articles.save(Article(date: today, type: ArticleType.letter, placeId: p2));
      state = AppState(s);
      await state.init();
    });
    await pumpApp(tester, state.s, state, RunScreen(order: [p1, p2]));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(find.text('NEXT STOP'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('⚠ Dog'), findsOneWidget);
    expect(find.text('Needs signature / OTP'), findsOneWidget);
    expect(find.text('0 of 2 stops'), findsOneWidget);

    await tester.tap(find.text('Delivered'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('14'), findsOneWidget);
    expect(find.text('1 of 2 stops'), findsOneWidget);

    await tester.tap(find.text('Not delivered'));
    await tester.pumpAndSettle();
    expect(find.text('Why not delivered?'), findsOneWidget);
    await tester.tap(find.text('Door locked'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.textContaining('All stops done'), findsOneWidget);

    late List<Article> saved;
    await tester.runAsync(() async => saved = await state.s.articles.forDate(today));
    final a1 = saved.firstWhere((a) => a.placeId == p1);
    final a2 = saved.firstWhere((a) => a.placeId == p2);
    expect(a1.status, ArticleStatus.delivered);
    expect(a1.lat, isNotNull); // GPS recorded
    expect(a1.deliveredAt, isNotNull);
    expect(a2.status, ArticleStatus.notDelivered);
    expect(a2.reason, 'doorLocked');
    expect(a2.attempts, 1);
  });
}

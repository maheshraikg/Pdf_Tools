import 'package:beat_mitra/app_state.dart';
import 'package:beat_mitra/data/models.dart';
import 'package:beat_mitra/features/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

void main() {
  testWidgets('search finds a place by Kannada name, door number and landmark', (tester) async {
    late AppState state;
    await tester.runAsync(() async {
      final s = await testServices();
      final b = await s.beats.saveBeat(Beat(name: 'Beat 7'));
      final st = await s.beats.saveStreet(Street(beatId: b, name: '4th Cross'));
      final p1 = await s.places.savePlace(
        Place(
          beatId: b,
          streetId: st,
          doorNo: '12/3',
          landmark: 'Ganesha Temple',
          lat: 12.9720,
          lng: 77.6412,
          notes: 'Dog',
        ),
      );
      await s.places.setAddressees(p1, [Addressee(placeId: p1, name: 'Ramesh Kumar', phone: '9876543210')]);
      final p2 = await s.places.savePlace(Place(beatId: b, streetId: st, doorNo: '40', landmark: 'School'));
      await s.places.setAddressees(p2, [Addressee(placeId: p2, name: 'Suresh')]);
      state = AppState(s);
      await state.init();
    });
    await pumpApp(tester, state.s, state, const SearchScreen());

    // Empty query shows tips.
    expect(find.textContaining('Kannada, Hindi and English'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ರಮೇಶ್');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('12/3'), findsOneWidget);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Suresh'), findsNothing);
    // Distance + buttons on the card.
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('44 m'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12-3');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('12/3'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'school');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('40'), findsOneWidget);
    expect(find.text('12/3'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzzqq');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing found'), findsOneWidget);
  });
}

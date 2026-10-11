import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tulu_panchanga/app/strings.dart';
import 'package:tulu_panchanga/app/summary.dart';
import 'package:tulu_panchanga/art/festival_art.dart';
import 'package:tulu_panchanga/art/tulunadu_scene.dart';
import 'package:tulu_panchanga/panchanga/engine.dart';
import 'package:tulu_panchanga/panchanga/festivals.dart';
import 'package:tulu_panchanga/panchanga/names.dart';
import 'package:tulu_panchanga/panchanga/place.dart';

void main() {
  test('every festival has an illustration; key ones are specific', () {
    for (final f in allFestivals) {
      expect(ArtKind.values, contains(artFor(f)));
    }
    Festival byId(String id) => allFestivals.firstWhere((f) => f.id == id);
    expect(artFor(byId('deepavali_amavasya')), ArtKind.diya);
    expect(artFor(byId('ganesh_chaturthi')), ArtKind.ganesha);
    expect(artFor(byId('nagara_panchami')), ArtKind.naga);
    expect(artFor(byId('vijayadashami')), ArtKind.yakshagana);
    expect(artFor(byId('aati_amavasye')), ArtKind.rain);
    expect(artFor(byId('amavasya')), ArtKind.newMoon);
  });

  testWidgets('all illustrations and the scene paint without errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            Wrap(
              children: [
                for (final k in ArtKind.values) FestivalArt(kind: k, size: 40),
              ],
            ),
            for (final night in [false, true])
              for (final e in [10.0, 100.0, 180.0, 260.0, 350.0])
                TulunaduScene(
                  dayFraction: 0.3,
                  isNight: night,
                  moonElongation: e,
                  festive: night,
                  height: 120,
                ),
          ],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  test('read-aloud text has the date, tithi, nakshatra and festivals', () {
    final e = PanchangaEngine(placeById('mangaluru'));
    final d = e.day(DateTime.utc(2026, 9, 14));
    final f = FestivalCalculator(e).on(d.date);
    final en = daySpeech(const S(Lang.en), Lang.en, e, d, f);
    expect(en, contains('September'));
    expect(en, contains('Ganesha Chaturthi'));
    expect(en, contains('Tithi'));
    expect(en, contains('Rahu kaala'));
    expect(en, isNot(contains('→')));
    final kn = daySpeech(const S(Lang.kn), Lang.kn, e, d, f);
    expect(kn, contains('ಗಣೇಶ ಚತುರ್ಥಿ'));
    expect(kn, contains('ತಿಥಿ'));
  });
}
